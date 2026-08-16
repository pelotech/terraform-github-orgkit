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
  owner = "acme-org"
}

# A comprehensive sample that exercises the full orgkit interface: members,
# owners-by-team, teams with an org role, repositories across every access level
# (including a restricted repo, Pages, and merge/signed-commit opt-outs),
# per-repo and environment Actions variables & secrets, environments with both
# deployment-branch-policy styles, and org-level secrets & variables.
#
# All values are illustrative. Secrets here are placeholders; a real caller
# supplies already-decrypted values via var.secrets.
module "orgkit" {
  source = "../../"

  users = [
    { username = "alice", fullname = "Alice Admin", email = "alice@acme.example" },
    { username = "bob", fullname = "Bob Builder", email = "bob@acme.example" },
    { username = "carol", fullname = "Carol Coder", email = "carol@acme.example" },
    { username = "dave", fullname = "Dave Dev", email = "dave@acme.example" },
    { username = "erin", fullname = "Erin External", email = "erin@acme.example" },
  ]

  # Owners are derived from a team the consumer chooses — no hardcoded owners team.
  owners_team = "owners"

  teams = [
    { name = "owners", description = "Organization owners", members = ["alice"] },
    { name = "platform", description = "Platform & security", members = ["bob", "carol"], org_roles = ["security_manager"] },
    { name = "developers", description = "Delivery team", members = ["carol", "dave", "erin"] },
    { name = "contractors", description = "External contributors", members = ["erin"] },
  ]

  repositories = [
    {
      name        = "web-app"
      description = "Customer-facing web application"
      visibility  = "private"
      writers     = ["developers"]
      admins      = ["owners"]
      variables   = { NODE_ENV = "production" }
      rulesets = {
        "Protect main" = {
          include_refs  = ["~DEFAULT_BRANCH"]
          bypass_actors = [{ actor_type = "Team", team = "owners" }]
          rules         = { required_linear_history = true }
        }
      }
      environments = {
        # protected_branches style: only protected branches may deploy.
        production = {
          reviewers                = ["owners"]
          wait_timer               = 10
          deployment_branch_policy = { protected_branches = true }
        }
        # custom_branch_policies style: named branch patterns may deploy.
        staging = {
          deployment_branch_policy = { custom_branch_policies = ["release/*", "main"] }
        }
      }
    },
    {
      name        = "api"
      description = "Backend API service"
      visibility  = "internal"
      writers     = ["developers", "platform"]
      admins      = ["owners"]
    },
    {
      name        = "infra"
      description = "Infrastructure as code (restricted)"
      visibility  = "private"
      restricted  = true # withholds the default all-members read grant
      admins      = ["platform", "owners"]
    },
    {
      name               = "sandbox"
      description        = "Experiments; relaxed rules"
      visibility         = "private"
      admins             = ["owners"]
      allow_squash_merge = true  # allow squash merges
      allow_rebase_merge = true  # allow rebase merges
      signed_commits     = false # opt out of the required-signed-commits ruleset
    },
    {
      name         = "docs-site"
      description  = "Public documentation site"
      visibility   = "public"
      enable_pages = true
      writers      = ["developers"]
      admins       = ["owners"]
    },
  ]

  # Org-level Actions variables (plaintext) with visibility.
  organization_variables = {
    ORG_CI_FLAG    = { value = "enabled" }
    ORG_DEPLOY_ENV = { value = "prod", visibility = "selected", repositories = ["web-app", "api"] }
  }

  # Visibility config for org-level secrets; values come from var.secrets.org.
  organization_secrets = {
    GLOBAL_TOKEN = { visibility = "all" }
    NPM_TOKEN    = { visibility = "selected", repositories = ["web-app"] }
  }

  # Decrypted secret values, supplied by the caller. Placeholders shown here.
  secrets = {
    org = {
      GLOBAL_TOKEN = "example-global-token"
      NPM_TOKEN    = "example-npm-token"
    }
    repos = {
      web-app = {
        actions      = { DEPLOY_KEY = "example-deploy-key" }
        environments = { production = { PROD_TOKEN = "example-prod-token" } }
      }
    }
  }

  # Enable a curated subset of built-in ruleset presets.
  enabled_presets = ["require_pull_request_reviews", "restrict_deletions", "require_signed_commits", "block_force_pushes"]

  # A custom org ruleset alongside the presets.
  organization_rulesets = {
    "No Tag Deletes" = {
      target        = "tag"
      bypass_actors = [{ actor_type = "OrganizationAdmin" }]
      rules         = { deletion = true }
    }
  }
}
