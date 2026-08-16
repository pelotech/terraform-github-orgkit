mock_provider "github" {
  mock_data "github_organization_roles" {
    defaults = { roles = [{ name = "Reader", role_id = 1, source = "Predefined" }] }
  }
}

run "generic_ruleset_passes_through" {
  command = plan

  variables {
    create_all_members_team = false
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
    create_all_members_team = false
    organization_rulesets = {
      bad = { enforcement = "sometimes", rules = {} }
    }
  }
  expect_failures = [var.organization_rulesets]
}
