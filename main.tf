#
# terraform-github-orgkit — root ("everything") module.
#
# Resolves org-wide inputs, then composes the three submodules as a one-directional
# pipeline (organization -> teams -> repository) and wires their outputs together.
# The consumer configures the `github` provider; this module inherits it.
#

locals {
  usernames = toset(var.users[*].username)

  # Owners are either explicit (var.owners) or derived from a named team's members
  # (var.owners_team). No owners team is hardcoded.
  owners = var.owners_team != null ? toset(flatten([
    for t in var.teams : t.members if t.name == var.owners_team
  ])) : var.owners

  # Repositories that opt out of the required-signed-commits ruleset.
  signed_commits_excluded = [for r in var.repositories : r.name if !r.signed_commits]
}

module "organization" {
  source = "./modules/organization"

  members                              = local.usernames
  owners                               = local.owners
  organization_rulesets                = var.organization_rulesets
  enabled_presets                      = var.enabled_presets
  signed_commits_excluded_repositories = local.signed_commits_excluded
}

module "teams" {
  source = "./modules/teams"

  teams                   = var.teams
  owners                  = local.owners
  members                 = module.organization.members
  create_all_members_team = var.create_all_members_team
  all_members_team_name   = var.all_members_team_name
}

module "repository" {
  source = "./modules/repository"

  repositories        = var.repositories
  repository_secrets  = var.secrets.repos
  teams               = module.teams.teams
  all_members_team_id = module.teams.all_members_team_id
}

#
# Org-level Actions secrets and variables live at the root because they need both
# the decrypted secret values (var.secrets) and repository ids (from the
# repository module) to resolve "selected" visibility — placing them upstream of
# the repository module would create a dependency cycle.
#

locals {
  # secret name => { visibility, repositories }. Non-secret index for for_each;
  # the secret value is read from var.secrets.org in the resource.
  org_secrets = {
    for name, value in var.secrets.org : name => {
      visibility   = try(var.organization_secrets[name].visibility, "private")
      repositories = try(var.organization_secrets[name].repositories, [])
    }
  }
}

resource "github_actions_organization_secret" "internal" {
  for_each = try(nonsensitive(local.org_secrets), local.org_secrets)

  secret_name     = each.key
  visibility      = each.value.visibility
  plaintext_value = var.secrets.org[each.key]

  selected_repository_ids = each.value.visibility == "selected" ? [
    for name in each.value.repositories : module.repository.repository_ids[name]
  ] : null

  lifecycle {
    precondition {
      condition     = each.value.visibility != "selected" || length(each.value.repositories) > 0
      error_message = "Org secret '${each.key}' has visibility 'selected' but lists no repositories."
    }
  }
}

resource "github_actions_organization_variable" "internal" {
  for_each = var.organization_variables

  variable_name = each.key
  value         = each.value.value
  visibility    = each.value.visibility

  selected_repository_ids = each.value.visibility == "selected" ? [
    for name in each.value.repositories : module.repository.repository_ids[name]
  ] : null

  lifecycle {
    precondition {
      condition     = each.value.visibility != "selected" || length(each.value.repositories) > 0
      error_message = "Org variable '${each.key}' has visibility 'selected' but lists no repositories."
    }
  }
}
