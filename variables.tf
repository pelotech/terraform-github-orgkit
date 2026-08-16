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
    archive_on_destroy = optional(bool, false)
    default_branch     = optional(string, null)
    enable_pages       = optional(bool, false)
    signed_commits     = optional(bool, true)

    allow_merge_commit     = optional(bool, true)
    allow_squash_merge     = optional(bool, false)
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

variable "baseline_ruleset" {
  description = "Baseline org-wide branch-protection ruleset. See the organization submodule for the object schema; set enabled = false to disable."
  type = object({
    enabled                           = optional(bool, true)
    block_deletion                    = optional(bool, true)
    block_force_pushes                = optional(bool, false)
    required_approving_review_count   = optional(number, 1)
    require_code_owner_review         = optional(bool, true)
    require_last_push_approval        = optional(bool, false)
    dismiss_stale_reviews_on_push     = optional(bool, false)
    required_review_thread_resolution = optional(bool, true)
  })
  default = {}
}

variable "require_signed_commits" {
  description = "Require signed commits on all branches of all repositories (except repositories with signed_commits = false)."
  type        = bool
  default     = true
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
