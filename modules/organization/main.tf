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
# Generic organization rulesets: one for_each resource driven by the
# organization_rulesets map. Presets (Task 2) populate local.all_rulesets on
# top of var.organization_rulesets; for now they are the same thing.
#

locals {
  all_rulesets = var.organization_rulesets
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
