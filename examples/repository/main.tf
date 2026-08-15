terraform {
  required_version = ">= 1.9"

  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}

provider "github" {
  owner = "example-org"
}

# Use only the repository submodule. Bring your own team ids (e.g. from a
# github_team data source or the teams submodule) instead of the whole suite.
data "github_team" "developers" {
  slug = "developers"
}

module "repositories" {
  source = "../../modules/repository"

  teams = {
    developers = { id = data.github_team.developers.id, slug = "developers" }
  }

  repositories = [
    {
      name        = "library"
      description = "A standalone library repository"
      visibility  = "private"
      writers     = ["developers"]
      variables   = { CI = "true" }
    },
  ]
}
