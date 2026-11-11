mock_provider "github" {}

run "generic_ruleset_passes_through" {
  command = plan

  variables {
    organization_rulesets = {
      "No Force Push" = {
        include_refs  = ["~DEFAULT_BRANCH"]
        bypass_actors = [{ actor_type = "OrganizationAdmin" }]
        rules         = { non_fast_forward = true }
      }
    }
  }

  assert {
    condition     = github_organization_ruleset.internal["No Force Push"].rules[0].non_fast_forward
    error_message = "A generic ruleset must pass its rules through to github_organization_ruleset."
  }
  assert {
    condition     = one(github_organization_ruleset.internal["No Force Push"].bypass_actors).actor_id == 1
    error_message = "OrganizationAdmin bypass must coerce actor_id to 1."
  }
}

run "rejects_bad_enforcement" {
  command = plan
  variables {
    organization_rulesets = {
      bad = { enforcement = "sometimes", rules = {} }
    }
  }
  expect_failures = [var.organization_rulesets]
}

run "default_presets_reproduce_prior_behavior" {
  command = plan

  assert {
    condition     = github_organization_ruleset.internal["require_signed_commits"].rules[0].required_signatures
    error_message = "require_signed_commits preset must enable required_signatures."
  }
  assert {
    condition     = github_organization_ruleset.internal["require_pull_request_reviews"].rules[0].pull_request[0].required_approving_review_count == 1
    error_message = "require_pull_request_reviews preset must require one approval."
  }
  assert {
    condition     = github_organization_ruleset.internal["restrict_deletions"].rules[0].deletion
    error_message = "restrict_deletions preset must enable deletion protection."
  }
  assert {
    condition     = length(github_organization_ruleset.internal["require_signed_commits"].bypass_actors) == 0
    error_message = "require_signed_commits must have no bypass actors."
  }
}

run "signed_commits_exclusion_feeds_preset" {
  command = plan
  variables {
    signed_commits_excluded_repositories = ["legacy-repo"]
  }
  assert {
    condition     = contains(github_organization_ruleset.internal["require_signed_commits"].conditions[0].repository_name[0].exclude, "legacy-repo")
    error_message = "signed_commits_excluded_repositories must feed the require_signed_commits preset's exclusions."
  }
}

run "custom_ruleset_overrides_preset_by_name" {
  command = plan
  variables {
    enabled_presets = ["require_signed_commits"]
    organization_rulesets = {
      require_signed_commits = {
        include_refs  = ["~ALL"]
        bypass_actors = [{ actor_type = "OrganizationAdmin" }]
        rules         = { required_signatures = true }
      }
    }
  }
  assert {
    condition     = one(github_organization_ruleset.internal["require_signed_commits"].bypass_actors).actor_id == 1
    error_message = "A custom organization_rulesets entry must override the preset of the same name."
  }
}

run "default_retains_membership" {
  command = plan
  variables {
    members = ["alice", "bob"]
    owners  = ["alice"]
  }
  assert {
    condition     = github_membership.internal["alice"].role == "admin"
    error_message = "Owners must map to the admin membership role."
  }
  assert {
    condition     = github_membership.internal["bob"].role == "member"
    error_message = "Non-owners must map to the member membership role."
  }
  assert {
    condition     = length(github_membership.removable) == 0
    error_message = "Removable memberships must only exist when remove_unlisted_members = true."
  }
}

run "removal_opt_in_uses_removable" {
  command = plan
  variables {
    remove_unlisted_members = true
    members                 = ["alice", "bob"]
    owners                  = ["alice"]
  }
  assert {
    condition     = github_membership.removable["alice"].role == "admin" && github_membership.removable["bob"].role == "member"
    error_message = "Removable memberships must carry the same roles."
  }
  assert {
    condition     = length(github_membership.internal) == 0
    error_message = "A member must never be managed by both membership resources."
  }
  assert {
    condition     = output.members == { alice = "alice", bob = "bob" }
    error_message = "The members output must list every member in removal mode."
  }
}

run "unmanaged_creates_no_membership" {
  command = plan
  variables {
    manage_membership       = false
    remove_unlisted_members = true
    members                 = ["alice", "bob"]
  }
  assert {
    condition     = length(github_membership.internal) + length(github_membership.removable) == 0
    error_message = "manage_membership = false must create no github_membership resources."
  }
  assert {
    condition     = output.members == { alice = "alice", bob = "bob" }
    error_message = "The members output must still list every member when membership is unmanaged."
  }
}
