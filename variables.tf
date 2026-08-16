variable "users" {
  description = "Organization members. `fullname`/`email` are informational; membership is keyed on `username`."
  type = list(object({
    username = string
    fullname = optional(string, "")
    email    = optional(string, "")
  }))
  default = []
}

variable "owners" {
  description = "Explicit set of owner usernames (mapped to GitHub's `admin` role). Ignored when `owners_team` is set."
  type        = set(string)
  default     = []
}

variable "owners_team" {
  description = <<-EOT
    Convenience: derive organization owners from the members of this team, by
    name. `null` (default) means use the explicit `owners` set instead. There is
    no hardcoded owners team — the consumer chooses.
  EOT
  type        = string
  default     = null

  validation {
    condition     = var.owners_team == null || contains(var.teams[*].name, coalesce(var.owners_team, ""))
    error_message = "owners_team '${coalesce(var.owners_team, "")}' is not a declared team."
  }
}

variable "teams" {
  description = <<-EOT
    Teams and their membership. A team may hold predefined organization-level
    GitHub roles via `org_roles`. Repository access is granted per repository via
    readers/writers/admins, not through org roles.
  EOT
  type = list(object({
    name        = string
    description = string
    members     = optional(list(string), [])
    org_roles   = optional(list(string), [])
  }))
  default = []

  validation {
    condition = alltrue([
      for t in var.teams :
      alltrue([for p in t.members : contains(var.users[*].username, p)])
    ])
    error_message = "Teams list undeclared users: ${join(", ", distinct(flatten([for t in var.teams : [for p in t.members : "${t.name}:${p}" if !contains(var.users[*].username, p)]])))}."
  }
}

variable "repositories" {
  description = "Repositories and which teams may access them. See the repository submodule for the full object schema and validations."
  type = list(object({
    name        = string
    description = string
    visibility  = optional(string, "private")
    readers     = optional(list(string), [])
    writers     = optional(list(string), [])
    admins      = optional(list(string), [])
    restricted  = optional(bool, false)

    topics             = optional(list(string), [])
    homepage_url       = optional(string, null)
    has_issues         = optional(bool, true)
    has_wiki           = optional(bool, false)
    has_projects       = optional(bool, false)
    has_downloads      = optional(bool, true)
    is_template        = optional(bool, false)
    gitignore_template = optional(string, null)
    license_template   = optional(string, null)
    archived           = optional(bool, false)
    archive_on_destroy = optional(bool, true)
    default_branch     = optional(string, null)
    enable_pages       = optional(bool, false)
    signed_commits     = optional(bool, true)

    allow_merge_commit     = optional(bool, false)
    allow_squash_merge     = optional(bool, true)
    allow_rebase_merge     = optional(bool, false)
    allow_auto_merge       = optional(bool, true)
    delete_branch_on_merge = optional(bool, true)
    merge_commit_message   = optional(string, "PR_BODY")
    merge_commit_title     = optional(string, "PR_TITLE")

    template = optional(object({
      owner                = string
      repository           = string
      include_all_branches = optional(bool, false)
    }))

    rulesets = optional(map(object({
      enforcement  = optional(string, "active")
      target       = optional(string, "branch")
      include_refs = optional(list(string), ["~ALL"])
      exclude_refs = optional(list(string), [])
      bypass_actors = optional(list(object({
        actor_type  = string
        actor_id    = optional(number, 0)
        team        = optional(string)
        bypass_mode = optional(string, "always")
      })), [])
      rules = object({
        creation                = optional(bool, false)
        update                  = optional(bool, false)
        deletion                = optional(bool, false)
        non_fast_forward        = optional(bool, false)
        required_signatures     = optional(bool, false)
        required_linear_history = optional(bool, false)
        pull_request = optional(object({
          required_approving_review_count   = optional(number, 0)
          require_code_owner_review         = optional(bool, false)
          require_last_push_approval        = optional(bool, false)
          dismiss_stale_reviews_on_push     = optional(bool, false)
          required_review_thread_resolution = optional(bool, false)
        }))
      })
    })), {})

    variables = optional(map(string), {})
    environments = optional(map(object({
      variables  = optional(map(string), {})
      reviewers  = optional(list(string), [])
      wait_timer = optional(number, 0)
      deployment_branch_policy = optional(object({
        protected_branches     = optional(bool, false)
        custom_branch_policies = optional(list(string), [])
      }))
    })), {})
  }))
  default = []
}

variable "secrets" {
  description = "Decrypted secret values keyed by scope. Supplied already-decrypted by the caller; this module never performs decryption."
  type = object({
    org = optional(map(string), {})
    repos = optional(map(object({
      actions      = optional(map(string), {})
      environments = optional(map(map(string)), {})
    })), {})
  })
  default   = { org = {}, repos = {} }
  sensitive = true
}

variable "organization_secrets" {
  description = "Visibility config for org-level shared secrets. Values come from var.secrets.org."
  type = map(object({
    visibility   = optional(string, "private")
    repositories = optional(list(string), [])
  }))
  default = {}

  validation {
    condition     = alltrue([for s in var.organization_secrets : contains(["all", "private", "selected"], s.visibility)])
    error_message = "Org secret visibility must be one of: all, private, selected."
  }
}

variable "organization_variables" {
  description = "Org-level shared Actions variables (plaintext value + visibility)."
  type = map(object({
    value        = string
    visibility   = optional(string, "private")
    repositories = optional(list(string), [])
  }))
  default = {}

  validation {
    condition     = alltrue([for v in var.organization_variables : contains(["all", "private", "selected"], v.visibility)])
    error_message = "Org variable visibility must be one of: all, private, selected."
  }
}

variable "organization_rulesets" {
  description = <<-EOT
    Organization rulesets, keyed by name. Merged with (and overridden by name by)
    the presets selected via enabled_presets. bypass_actors uses raw numeric
    actor_id (OrganizationAdmin needs none); team-name bypass is per-repo only.
  EOT
  type = map(object({
    enforcement          = optional(string, "active")
    target               = optional(string, "branch")
    include_refs         = optional(list(string), ["~ALL"])
    exclude_refs         = optional(list(string), [])
    include_repositories = optional(list(string), ["~ALL"])
    exclude_repositories = optional(list(string), [])
    bypass_actors = optional(list(object({
      actor_type  = string
      actor_id    = optional(number, 0)
      bypass_mode = optional(string, "always")
    })), [])
    rules = object({
      creation                = optional(bool, false)
      update                  = optional(bool, false)
      deletion                = optional(bool, false)
      non_fast_forward        = optional(bool, false)
      required_signatures     = optional(bool, false)
      required_linear_history = optional(bool, false)
      pull_request = optional(object({
        required_approving_review_count   = optional(number, 0)
        require_code_owner_review         = optional(bool, false)
        require_last_push_approval        = optional(bool, false)
        dismiss_stale_reviews_on_push     = optional(bool, false)
        required_review_thread_resolution = optional(bool, false)
      }))
    })
  }))
  default = {}

  validation {
    condition = alltrue([for r in values(var.organization_rulesets) :
    contains(["active", "evaluate", "disabled"], r.enforcement)])
    error_message = "Ruleset enforcement must be one of: active, evaluate, disabled."
  }
  validation {
    condition = alltrue([for r in values(var.organization_rulesets) :
    contains(["branch", "tag"], r.target)])
    error_message = "Ruleset target must be one of: branch, tag."
  }
  validation {
    condition = alltrue(flatten([for r in values(var.organization_rulesets) :
    [for b in r.bypass_actors : contains(["OrganizationAdmin", "RepositoryRole", "Team", "Integration", "DeployKey"], b.actor_type)]]))
    error_message = "bypass_actors.actor_type must be one of: OrganizationAdmin, RepositoryRole, Team, Integration, DeployKey."
  }
  validation {
    condition = alltrue(flatten([for r in values(var.organization_rulesets) :
    [for b in r.bypass_actors : contains(["always", "pull_request"], b.bypass_mode)]]))
    error_message = "bypass_actors.bypass_mode must be one of: always, pull_request."
  }
}

variable "enabled_presets" {
  description = "Names of built-in ruleset presets to enable. See modules/organization/main.tf local.presets."
  type        = list(string)
  default     = ["require_pull_request_reviews", "restrict_deletions", "require_signed_commits"]

  validation {
    condition = alltrue([for p in var.enabled_presets : contains([
      "require_pull_request_reviews", "restrict_deletions", "require_signed_commits",
      "block_force_pushes", "require_linear_history",
    ], p)])
    error_message = "enabled_presets entries must be known preset names."
  }
}

variable "create_all_members_team" {
  description = "Create an all-members team that grants default read access to non-restricted repositories."
  type        = bool
  default     = true
}

variable "all_members_team_name" {
  description = "Name of the all-members team."
  type        = string
  default     = "everyone"
}
