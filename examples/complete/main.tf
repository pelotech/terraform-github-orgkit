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
  owners_team = "leadership"

  teams = [
    { name = "leadership", description = "Organization owners", members = ["alice"] },
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
      admins      = ["leadership"]
      variables   = { NODE_ENV = "production" }
      environments = {
        # protected_branches style: only protected branches may deploy.
        production = {
          reviewers                = ["leadership"]
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
      admins      = ["leadership"]
    },
    {
      name        = "infra"
      description = "Infrastructure as code (restricted)"
      visibility  = "private"
      restricted  = true # withholds the default all-members read grant
      admins      = ["platform", "leadership"]
    },
    {
      name           = "sandbox"
      description    = "Experiments; relaxed rules"
      visibility     = "private"
      admins         = ["leadership"]
      unsafe_merges  = true  # allow rebase/squash merges
      signed_commits = false # opt out of the required-signed-commits ruleset
    },
    {
      name         = "docs-site"
      description  = "Public documentation site"
      visibility   = "public"
      enable_pages = true
      writers      = ["developers"]
      admins       = ["leadership"]
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

  # The baseline ruleset is tunable; here we require two approvals.
  baseline_ruleset = {
    required_approving_review_count = 2
  }
}
