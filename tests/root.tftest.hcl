mock_provider "github" {
  mock_data "github_organization_roles" {
    defaults = {
      roles = [{ name = "Reader", role_id = 1, source = "Predefined" }]
    }
  }
}

# The repository module's default-read grant keys its for_each off the
# all-members team id, which is unknown when planning a brand-new team. Give it a
# known id so these plans exercise the composed module.
override_resource {
  target          = module.teams.github_team.everyone[0]
  override_during = plan
  values          = { id = "1" }
}

run "managed_members_come_from_users" {
  command = plan
  variables {
    users = [{ username = "alice" }, { username = "bob" }]
    teams = [{ name = "core", description = "", members = ["alice"] }]
  }
  assert {
    condition     = keys(output.members) == ["alice", "bob"]
    error_message = "When managed, the member set must be exactly `users`."
  }
}

run "removal_opt_in_keeps_member_set" {
  command = plan
  variables {
    remove_unlisted_members = true
    users                   = [{ username = "alice" }, { username = "bob" }]
  }
  assert {
    condition     = keys(output.members) == ["alice", "bob"]
    error_message = "remove_unlisted_members must not change the member set."
  }
}

run "managed_rejects_team_member_missing_from_users" {
  command = plan
  variables {
    users = [{ username = "alice" }]
    teams = [{ name = "core", description = "", members = ["alice", "bob"] }]
  }
  expect_failures = [var.teams]
}

run "unmanaged_derives_members_from_teams_without_users" {
  command = plan
  variables {
    manage_membership = false
    teams = [
      { name = "core", description = "", members = ["alice", "bob"] },
      { name = "ops", description = "", members = ["bob", "carol"] },
    ]
  }
  assert {
    condition     = keys(output.members) == ["alice", "bob", "carol"]
    error_message = "When unmanaged, the member set must be the union of all team members."
  }
}

run "unmanaged_ignores_users" {
  command = plan
  variables {
    manage_membership = false
    users             = [{ username = "zed" }]
    teams             = [{ name = "core", description = "", members = ["alice"] }]
  }
  assert {
    condition     = keys(output.members) == ["alice"]
    error_message = "When unmanaged, `users` must not contribute to the member set."
  }
}

run "unmanaged_with_no_team_members_plans" {
  command = plan
  variables {
    manage_membership = false
    teams             = [{ name = "empty", description = "" }]
  }
  assert {
    condition     = length(output.members) == 0
    error_message = "An unmanaged org with no team members must plan with an empty member set."
  }
}
