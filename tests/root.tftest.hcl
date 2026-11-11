mock_provider "github" {
  mock_data "github_organization_roles" {
    defaults = {
      roles = [{ name = "Reader", role_id = 1, source = "Predefined" }]
    }
  }
}

run "managed_members_come_from_users" {
  command = plan
  variables {
    users = [{ username = "alice" }, { username = "bob" }]
    teams = [{ name = "core", description = "", members = ["alice"] }]
  }
  assert {
    condition     = keys(output.members) == tolist(["alice", "bob"])
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
    condition     = keys(output.members) == tolist(["alice", "bob"])
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

run "empty_users_derives_members_from_teams" {
  command = plan
  variables {
    teams = [
      { name = "core", description = "", members = ["alice", "bob"] },
      { name = "ops", description = "", members = ["bob", "carol"] },
    ]
  }
  assert {
    condition     = keys(output.members) == tolist(["alice", "bob", "carol"])
    error_message = "With no `users`, the member set must be the union of all team members."
  }
}

run "empty_users_with_no_team_members_plans" {
  command = plan
  variables {
    teams = [{ name = "empty", description = "" }]
  }
  assert {
    condition     = length(output.members) == 0
    error_message = "No `users` and no team members must plan with an empty member set."
  }
}

run "new_all_members_team_plans_default_read_grant" {
  command = plan
  variables {
    users        = [{ username = "alice" }]
    repositories = [{ name = "widgets", description = "" }]
  }
  # No assertion: the all-members team id is unknown here, and the plan itself
  # failing ("Invalid for_each argument") is what this run guards against.
}
