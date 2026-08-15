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
# Baseline branch-protection ruleset: applied to the default branch of every
# repository. Organization admins may bypass. Tunable via var.baseline_ruleset.
#

resource "github_organization_ruleset" "baseline" {
  count = var.baseline_ruleset.enabled ? 1 : 0

  name        = "Baseline"
  enforcement = "active"
  target      = "branch"

  conditions {
    ref_name {
      exclude = []
      include = ["~DEFAULT_BRANCH"]
    }

    repository_name {
      exclude = []
      include = ["~ALL"]
    }
  }

  bypass_actors {
    actor_id    = 0
    actor_type  = "OrganizationAdmin"
    bypass_mode = "always"
  }

  rules {
    deletion         = var.baseline_ruleset.block_deletion
    non_fast_forward = var.baseline_ruleset.block_force_pushes

    pull_request {
      dismiss_stale_reviews_on_push     = var.baseline_ruleset.dismiss_stale_reviews_on_push
      require_code_owner_review         = var.baseline_ruleset.require_code_owner_review
      require_last_push_approval        = var.baseline_ruleset.require_last_push_approval
      required_approving_review_count   = var.baseline_ruleset.required_approving_review_count
      required_review_thread_resolution = var.baseline_ruleset.required_review_thread_resolution
    }
  }
}

#
# Signed commits required on all branches of every repository by default. A
# repository opts out by being listed in signed_commits_excluded_repositories.
# Separate from Baseline so opting out does not weaken the other rules. No
# bypass_actors deliberately: org admins are bound too.
#

resource "github_organization_ruleset" "signed_commits" {
  count = var.require_signed_commits ? 1 : 0

  name        = "Signed Commits"
  enforcement = "active"
  target      = "branch"

  conditions {
    ref_name {
      exclude = []
      include = ["~ALL"]
    }

    repository_name {
      include = ["~ALL"]
      exclude = var.signed_commits_excluded_repositories
    }
  }

  rules {
    required_signatures = true
  }
}
