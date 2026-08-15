mock_provider "github" {}

variables {
  teams = {
    platform = { id = "1", slug = "platform" }
    security = { id = "2", slug = "security" }
  }
  all_members_team_id = "999"
}

run "rejects_invalid_visibility" {
  command = plan

  variables {
    repositories = [{ name = "app", description = "", visibility = "internet" }]
  }

  expect_failures = [var.repositories]
}

run "rejects_restricted_non_private_repo" {
  command = plan

  variables {
    repositories = [{ name = "app", description = "", visibility = "public", restricted = true }]
  }

  expect_failures = [var.repositories]
}

run "rejects_grant_to_unknown_team" {
  command = plan

  variables {
    repositories = [{ name = "app", description = "", readers = ["ghost"] }]
  }

  expect_failures = [var.repositories]
}

run "rejects_env_reviewer_unknown_team" {
  command = plan

  variables {
    repositories = [{
      name         = "app"
      description  = ""
      environments = { staging = { reviewers = ["ghost"] } }
    }]
  }

  expect_failures = [var.repositories]
}

run "highest_permission_wins_when_team_listed_twice" {
  command = plan

  variables {
    repositories = [{
      name        = "app"
      description = ""
      readers     = ["platform"]
      writers     = ["platform"]
    }]
  }

  assert {
    condition     = github_team_repository.internal["app_platform"].permission == "push"
    error_message = "A team listed as reader and writer should get the higher push permission."
  }
}

run "all_members_read_skips_restricted_repos" {
  command = plan

  variables {
    repositories = [
      { name = "open", description = "" },
      { name = "secret", description = "", restricted = true },
    ]
  }

  assert {
    condition     = github_team_repository.everyone["open"].permission == "pull"
    error_message = "Non-restricted repositories should grant the all-members team pull access."
  }

  assert {
    condition     = !contains(keys(github_team_repository.everyone), "secret")
    error_message = "Restricted repositories must not grant all-members read access."
  }
}

run "rejects_env_branch_policy_without_exactly_one_setting" {
  command = plan

  variables {
    repositories = [{
      name        = "app"
      description = ""
      environments = {
        staging = {
          deployment_branch_policy = {
            protected_branches     = false
            custom_branch_policies = []
          }
        }
      }
    }]
  }

  expect_failures = [var.repositories]
}

run "rejects_secret_for_undeclared_repo" {
  command = plan

  variables {
    repositories       = []
    repository_secrets = { ghost = { actions = { TOKEN = "x" } } }
  }

  expect_failures = [github_actions_secret.repo]
}

run "rejects_env_secret_for_undeclared_environment" {
  command = plan

  variables {
    repositories       = [{ name = "app", description = "" }]
    repository_secrets = { app = { environments = { staging = { TOKEN = "x" } } } }
  }

  expect_failures = [github_actions_environment_secret.internal]
}
