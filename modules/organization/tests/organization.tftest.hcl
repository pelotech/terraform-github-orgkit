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
