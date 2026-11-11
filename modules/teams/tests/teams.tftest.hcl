mock_provider "github" {
  mock_data "github_organization_roles" {
    defaults = {
      roles = [{ name = "Reader", role_id = 1, source = "Predefined" }]
    }
  }
}

run "owner_gets_maintainer_role_in_team" {
  command = plan

  variables {
    owners  = ["alice"]
    members = { alice = "alice", bob = "bob" }
    teams = [{
      name        = "core"
      description = ""
      members     = ["alice", "bob"]
    }]
  }

  assert {
    condition = anytrue([
      for m in github_team_members.internal["core"].members :
      m.username == "alice" && m.role == "maintainer"
    ])
    error_message = "Organization owners must hold the maintainer role within a team."
  }

  assert {
    condition = anytrue([
      for m in github_team_members.internal["core"].members :
      m.username == "bob" && m.role == "member"
    ])
    error_message = "Non-owners must hold the member role within a team."
  }
}

run "rejects_unknown_org_role" {
  command = plan

  variables {
    create_all_members_team = false
    teams = [{
      name        = "core"
      description = ""
      org_roles   = ["nonexistent_role"]
    }]
  }

  expect_failures = [github_organization_role_team.internal]
}

run "all_members_team_skips_membership_when_empty" {
  command = plan

  variables {
    members = {}
    teams   = []
  }

  assert {
    condition     = length(github_team.everyone) == 1
    error_message = "The all-members team itself must still be created."
  }
  assert {
    condition     = length(github_team_members.everyone) == 0
    error_message = "An empty member set must not plan a github_team_members with no members."
  }
}

run "team_members_reference_teams_by_slug" {
  command = plan

  override_resource {
    target          = github_team.internal["core"]
    override_during = plan
    values          = { id = "1", slug = "core" }
  }
  override_resource {
    target          = github_team.everyone[0]
    override_during = plan
    values          = { id = "2", slug = "everyone" }
  }

  variables {
    members = { alice = "alice" }
    teams = [{
      name        = "core"
      description = ""
      members     = ["alice"]
    }]
  }

  assert {
    condition     = github_team_members.internal["core"].team_slug == "core"
    error_message = "Team membership must reference its team by slug (team_id is deprecated)."
  }
  assert {
    condition     = github_team_members.everyone[0].team_slug == "everyone"
    error_message = "All-members team membership must reference its team by slug (team_id is deprecated)."
  }
}
