#
# Organization membership. Owners map to GitHub's `admin` role; everyone else is
# a plain `member`. Which usernames are owners is entirely the caller's choice
# (var.owners) — this module bakes in no owners-team convention.
#

resource "github_membership" "internal" {
  for_each = var.members

  username = each.value
  role     = contains(var.owners, each.value) ? "admin" : "member"
}

#
# Generic organization rulesets: one for_each resource driven by the merged
# preset + organization_rulesets map. Presets are curated, opt-in defaults
# selected via var.enabled_presets; entries in var.organization_rulesets with
# the same key override the preset of that name.
#

locals {
  # Each preset is a full ruleset spec (same shape as var.organization_rulesets
  # entries). rules objects specify every field so preset and user maps share a
  # type when merged.
  empty_rules = {
    creation            = false, update = false, deletion = false, non_fast_forward = false,
    required_signatures = false, required_linear_history = false, pull_request = null
  }
  admin_bypass = [{ actor_type = "OrganizationAdmin", actor_id = 0, bypass_mode = "always" }] # actor_id is coerced to 1 for OrganizationAdmin in the resource

  presets = {
    require_pull_request_reviews = {
      enforcement          = "active", target = "branch"
      include_refs         = ["~DEFAULT_BRANCH"], exclude_refs = []
      include_repositories = ["~ALL"], exclude_repositories = []
      bypass_actors        = local.admin_bypass
      rules = merge(local.empty_rules, { pull_request = {
        required_approving_review_count   = 1
        require_code_owner_review         = true
        require_last_push_approval        = false
        dismiss_stale_reviews_on_push     = false
        required_review_thread_resolution = true
      } })
    }
    restrict_deletions = {
      enforcement          = "active", target = "branch"
      include_refs         = ["~DEFAULT_BRANCH"], exclude_refs = []
      include_repositories = ["~ALL"], exclude_repositories = []
      bypass_actors        = local.admin_bypass
      rules                = merge(local.empty_rules, { deletion = true })
    }
    require_signed_commits = {
      enforcement          = "active", target = "branch"
      include_refs         = ["~ALL"], exclude_refs = []
      include_repositories = ["~ALL"], exclude_repositories = var.signed_commits_excluded_repositories
      bypass_actors        = []
      rules                = merge(local.empty_rules, { required_signatures = true })
    }
    block_force_pushes = {
      enforcement          = "active", target = "branch"
      include_refs         = ["~DEFAULT_BRANCH"], exclude_refs = []
      include_repositories = ["~ALL"], exclude_repositories = []
      bypass_actors        = local.admin_bypass
      rules                = merge(local.empty_rules, { non_fast_forward = true })
    }
    require_linear_history = {
      enforcement          = "active", target = "branch"
      include_refs         = ["~DEFAULT_BRANCH"], exclude_refs = []
      include_repositories = ["~ALL"], exclude_repositories = []
      bypass_actors        = local.admin_bypass
      rules                = merge(local.empty_rules, { required_linear_history = true })
    }
  }

  selected_presets = { for p in var.enabled_presets : p => local.presets[p] }
  all_rulesets     = merge(local.selected_presets, var.organization_rulesets)
}

resource "github_organization_ruleset" "internal" {
  for_each = local.all_rulesets

  name        = each.key
  enforcement = each.value.enforcement
  target      = each.value.target

  conditions {
    ref_name {
      include = each.value.include_refs
      exclude = each.value.exclude_refs
    }
    repository_name {
      include = each.value.include_repositories
      exclude = each.value.exclude_repositories
    }
  }

  dynamic "bypass_actors" {
    for_each = each.value.bypass_actors
    content {
      actor_id    = bypass_actors.value.actor_type == "OrganizationAdmin" ? 1 : bypass_actors.value.actor_id
      actor_type  = bypass_actors.value.actor_type
      bypass_mode = bypass_actors.value.bypass_mode
    }
  }

  rules {
    creation                = each.value.rules.creation
    update                  = each.value.rules.update
    deletion                = each.value.rules.deletion
    non_fast_forward        = each.value.rules.non_fast_forward
    required_signatures     = each.value.rules.required_signatures
    required_linear_history = each.value.rules.required_linear_history

    dynamic "pull_request" {
      for_each = each.value.rules.pull_request != null ? [each.value.rules.pull_request] : []
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
