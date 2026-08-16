#
# Repositories
#

locals {
  repositories = {
    for o in var.repositories : o.name => o
  }
}

resource "github_repository" "internal" {
  for_each = local.repositories

  name        = each.key
  description = each.value.description
  visibility  = each.value.visibility

  topics             = each.value.topics
  homepage_url       = each.value.homepage_url
  has_issues         = each.value.has_issues
  has_wiki           = each.value.has_wiki
  has_projects       = each.value.has_projects
  has_downloads      = each.value.has_downloads
  is_template        = each.value.is_template
  gitignore_template = each.value.gitignore_template
  license_template   = each.value.license_template
  archived           = each.value.archived
  archive_on_destroy = each.value.archive_on_destroy

  auto_init              = false
  allow_auto_merge       = each.value.allow_auto_merge
  allow_merge_commit     = each.value.allow_merge_commit
  allow_rebase_merge     = each.value.allow_rebase_merge
  allow_squash_merge     = each.value.allow_squash_merge
  delete_branch_on_merge = each.value.delete_branch_on_merge
  merge_commit_message   = each.value.merge_commit_message
  merge_commit_title     = each.value.merge_commit_title

  dynamic "template" {
    for_each = each.value.template != null ? [each.value.template] : []

    content {
      owner                = template.value.owner
      repository           = template.value.repository
      include_all_branches = template.value.include_all_branches
    }
  }

  dynamic "pages" {
    for_each = each.value.enable_pages ? [1] : []

    content {
      build_type = "workflow"

      source {
        branch = "main"
        path   = "/"
      }
    }
  }

  lifecycle {
    ignore_changes = [
      pages,
      vulnerability_alerts,
    ]
  }
}

#
# Vulnerability (Dependabot) alerts, enabled for every managed repository.
# Managed as a dedicated resource because github_repository.vulnerability_alerts
# is deprecated.
#

resource "github_repository_vulnerability_alerts" "internal" {
  for_each = github_repository.internal

  repository = each.value.name
  enabled    = true
}

#
# Default branch, managed as a dedicated resource because setting it on the
# repository is deprecated. Only created for repositories that name one.
#

resource "github_branch_default" "internal" {
  for_each = {
    for name, r in local.repositories : name => r.default_branch
    if r.default_branch != null
  }

  repository = github_repository.internal[each.key].name
  branch     = each.value
}

#
# Per-repository rulesets, with team-name bypass resolution via var.teams.
#

locals {
  # "<repo>:<ruleset>" => { repository, name, config }
  repository_rulesets = merge([
    for r in var.repositories : {
      for name, cfg in r.rulesets :
      "${r.name}:${name}" => { repository = r.name, name = name, config = cfg }
    }
  ]...)
}

resource "github_repository_ruleset" "internal" {
  for_each = local.repository_rulesets

  name        = each.value.name
  repository  = github_repository.internal[each.value.repository].name
  enforcement = each.value.config.enforcement
  target      = each.value.config.target

  conditions {
    ref_name {
      include = each.value.config.include_refs
      exclude = each.value.config.exclude_refs
    }
  }

  dynamic "bypass_actors" {
    for_each = each.value.config.bypass_actors
    content {
      actor_id = (
        bypass_actors.value.actor_type == "OrganizationAdmin" ? 1 :
        bypass_actors.value.actor_type == "Team" && bypass_actors.value.team != null ?
        tonumber(var.teams[bypass_actors.value.team].id) :
        bypass_actors.value.actor_id
      )
      actor_type  = bypass_actors.value.actor_type
      bypass_mode = bypass_actors.value.bypass_mode
    }
  }

  rules {
    creation                = each.value.config.rules.creation
    update                  = each.value.config.rules.update
    deletion                = each.value.config.rules.deletion
    non_fast_forward        = each.value.config.rules.non_fast_forward
    required_signatures     = each.value.config.rules.required_signatures
    required_linear_history = each.value.config.rules.required_linear_history

    dynamic "pull_request" {
      for_each = each.value.config.rules.pull_request != null ? [each.value.config.rules.pull_request] : []
      content {
        required_approving_review_count   = pull_request.value.required_approving_review_count
        require_code_owner_review         = pull_request.value.require_code_owner_review
        require_last_push_approval        = pull_request.value.require_last_push_approval
        dismiss_stale_reviews_on_push     = pull_request.value.dismiss_stale_reviews_on_push
        required_review_thread_resolution = pull_request.value.required_review_thread_resolution
      }
    }
  }
}

#
# One team-repository grant per repository-team pair. A team listed at more than
# one level gets the highest permission (merge order: admins > writers > readers).
#

locals {
  privileges = merge([
    for r in var.repositories : {
      for team, permission in merge(
        { for t in r.readers : t => "pull" },
        { for t in r.writers : t => "push" },
        { for t in r.admins : t => "admin" },
      ) :
      "${r.name}_${team}" => {
        repository = r.name
        team       = team
        permission = permission
      }
    }
  ]...)
}

resource "github_team_repository" "internal" {
  for_each = local.privileges

  team_id    = var.teams[each.value.team].id
  repository = github_repository.internal[each.value.repository].name
  permission = each.value.permission
}

#
# Default read access: every non-restricted repository grants the all-members
# team pull access, so all organization members can read it. Set
# `restricted = true` on a repository to opt out. Skipped entirely when no
# all-members team is provided.
#

resource "github_team_repository" "everyone" {
  for_each = var.all_members_team_id == null ? {} : {
    for name, r in local.repositories : name => r
    if !r.restricted
  }

  team_id    = var.all_members_team_id
  repository = github_repository.internal[each.key].name
  permission = "pull"
}

#
# Actions variables (repository scope)
#

locals {
  # "<repo>:<name>" => { repository, name, value }
  repo_variables = merge([
    for r in var.repositories : {
      for name, value in r.variables :
      "${r.name}:${name}" => { repository = r.name, name = name, value = value }
    }
  ]...)
}

resource "github_actions_variable" "repo" {
  for_each = local.repo_variables

  repository    = github_repository.internal[each.value.repository].name
  variable_name = each.value.name
  value         = each.value.value
}

#
# Actions secrets (repository scope). The non-secret index is used for for_each;
# the secret value is read from var.repository_secrets in the resource so it
# stays sensitive and never becomes a resource-instance key.
#

locals {
  # "<repo>:<name>" => { repository, name }
  repo_secrets = merge([
    for repo, cfg in var.repository_secrets : {
      for name, value in cfg.actions :
      "${repo}:${name}" => { repository = repo, name = name }
    }
  ]...)
}

resource "github_actions_secret" "repo" {
  for_each = try(nonsensitive(local.repo_secrets), local.repo_secrets)

  repository      = github_repository.internal[each.value.repository].name
  secret_name     = each.value.name
  plaintext_value = var.repository_secrets[each.value.repository].actions[each.value.name]

  lifecycle {
    precondition {
      condition     = contains(var.repositories[*].name, each.value.repository)
      error_message = "Secret '${each.value.name}' targets undeclared repository '${each.value.repository}'."
    }
  }
}

#
# Environments, their deployment branch policies, and environment-scoped Actions
# variables and secrets.
#

locals {
  # "<repo>:<env>" => { repository, environment, config }
  environments = merge([
    for r in var.repositories : {
      for env, cfg in r.environments :
      "${r.name}:${env}" => { repository = r.name, environment = env, config = cfg }
    }
  ]...)

  # "<repo>:<env>:<pattern>" => { env_key, pattern }
  environment_branch_policies = merge([
    for key, e in local.environments : {
      for pattern in try(e.config.deployment_branch_policy.custom_branch_policies, []) :
      "${key}:${pattern}" => { env_key = key, pattern = pattern }
    }
  ]...)

  # "<repo>:<env>:<name>" => { repository, environment, env_key, name, value }
  environment_variables = merge([
    for key, e in local.environments : {
      for name, value in e.config.variables :
      "${key}:${name}" => { repository = e.repository, environment = e.environment, env_key = key, name = name, value = value }
    }
  ]...)
}

resource "github_repository_environment" "internal" {
  for_each = local.environments

  repository  = github_repository.internal[each.value.repository].name
  environment = each.value.environment
  wait_timer  = each.value.config.wait_timer

  dynamic "reviewers" {
    for_each = length(each.value.config.reviewers) > 0 ? [1] : []
    content {
      teams = [for t in each.value.config.reviewers : var.teams[t].id]
    }
  }

  dynamic "deployment_branch_policy" {
    for_each = each.value.config.deployment_branch_policy != null ? [each.value.config.deployment_branch_policy] : []
    content {
      protected_branches     = deployment_branch_policy.value.protected_branches
      custom_branch_policies = length(deployment_branch_policy.value.custom_branch_policies) > 0
    }
  }
}

resource "github_repository_environment_deployment_policy" "internal" {
  for_each = local.environment_branch_policies

  repository     = github_repository_environment.internal[each.value.env_key].repository
  environment    = github_repository_environment.internal[each.value.env_key].environment
  branch_pattern = each.value.pattern
}

resource "github_actions_environment_variable" "internal" {
  for_each = local.environment_variables

  repository    = github_repository.internal[each.value.repository].name
  environment   = github_repository_environment.internal[each.value.env_key].environment
  variable_name = each.value.name
  value         = each.value.value
}

locals {
  # "<repo>:<env>:<name>" => { repository, environment, env_key, name }. Non-secret
  # index for for_each; the secret value is read from var.repository_secrets.
  environment_secrets = merge([
    for repo, cfg in var.repository_secrets : merge([
      for env, secrets in cfg.environments : {
        for name, value in secrets :
        "${repo}:${env}:${name}" => { repository = repo, environment = env, env_key = "${repo}:${env}", name = name }
      }
    ]...)
  ]...)
}

resource "github_actions_environment_secret" "internal" {
  for_each = try(nonsensitive(local.environment_secrets), local.environment_secrets)

  repository      = github_repository.internal[each.value.repository].name
  environment     = github_repository_environment.internal[each.value.env_key].environment
  secret_name     = each.value.name
  plaintext_value = var.repository_secrets[each.value.repository].environments[each.value.environment][each.value.name]

  lifecycle {
    precondition {
      condition     = contains(keys(local.environments), each.value.env_key)
      error_message = "Environment secret '${each.value.name}' references undeclared environment '${each.value.environment}' on repo '${each.value.repository}'. Declare it in the repository's environments."
    }
  }
}
