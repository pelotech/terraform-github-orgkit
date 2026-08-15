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
