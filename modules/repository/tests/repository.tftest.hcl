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

run "defaults_preserve_current_behavior" {
  command = plan

  variables {
    repositories = [{ name = "app", description = "" }]
  }

  assert {
    condition = alltrue([
      github_repository.internal["app"].has_issues,
      github_repository.internal["app"].allow_merge_commit,
      github_repository.internal["app"].allow_auto_merge,
      github_repository.internal["app"].delete_branch_on_merge,
      !github_repository.internal["app"].has_wiki,
      !github_repository.internal["app"].allow_squash_merge,
      !github_repository.internal["app"].allow_rebase_merge,
      github_repository.internal["app"].merge_commit_message == "PR_BODY",
    ])
    error_message = "Repository defaults must reproduce the previous hardcoded behavior."
  }
}

run "exposes_repository_settings" {
  command = plan

  variables {
    repositories = [{
      name         = "app"
      description  = ""
      topics       = ["platform", "go"]
      homepage_url = "https://example.com"
      has_wiki     = true
      is_template  = true
      archived     = true
    }]
  }

  assert {
    condition = alltrue([
      contains(github_repository.internal["app"].topics, "platform"),
      github_repository.internal["app"].homepage_url == "https://example.com",
      github_repository.internal["app"].has_wiki,
      github_repository.internal["app"].is_template,
      github_repository.internal["app"].archived,
    ])
    error_message = "Exposed repository settings must pass through to the repository resource."
  }
}

run "default_branch_creates_branch_default_only_when_set" {
  command = plan

  variables {
    repositories = [
      { name = "app", description = "", default_branch = "develop" },
      { name = "other", description = "" },
    ]
  }

  assert {
    condition     = github_branch_default.internal["app"].branch == "develop"
    error_message = "A repository with default_branch set must get a github_branch_default resource."
  }

  assert {
    condition     = !contains(keys(github_branch_default.internal), "other")
    error_message = "Repositories without default_branch must not get a github_branch_default resource."
  }
}

run "rejects_disabling_all_merge_methods" {
  command = plan

  variables {
    repositories = [{
      name               = "app"
      description        = ""
      allow_merge_commit = false
      allow_squash_merge = false
      allow_rebase_merge = false
    }]
  }

  expect_failures = [var.repositories]
}
