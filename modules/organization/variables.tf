variable "members" {
  description = "Set of GitHub usernames that are members of the organization."
  type        = set(string)
  default     = []
}

variable "owners" {
  description = <<-EOT
    Subset of `members` that are organization owners (mapped to GitHub's `admin`
    membership role); everyone else is a plain `member`. The consumer decides who
    is an owner — there is no hardcoded owners team.
  EOT
  type        = set(string)
  default     = []
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

variable "signed_commits_excluded_repositories" {
  description = "Repository names excluded from the required-signed-commits ruleset."
  type        = list(string)
  default     = []
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
