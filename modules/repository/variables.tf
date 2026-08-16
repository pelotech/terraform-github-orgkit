variable "repositories" {
  description = <<-EOT
    Repositories to manage and which teams may access them. `readers`, `writers`
    and `admins` reference team names from `var.teams`. A team listed at more than
    one level gets the highest permission (admin > write > read). Set
    `restricted = true` to withhold the default all-members read grant.
  EOT
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

  validation {
    condition = alltrue([
      for r in var.repositories :
      contains(["private", "internal", "public"], r.visibility)
    ])
    error_message = "Invalid visibility (must be private, internal, or public) on: ${join(", ", [for r in var.repositories : r.name if !contains(["private", "internal", "public"], r.visibility)])}."
  }

  validation {
    condition = alltrue([
      for r in var.repositories :
      !r.restricted || r.visibility == "private"
    ])
    error_message = "Restricted repositories must be private, since internal/public repos are readable by members regardless: ${join(", ", [for r in var.repositories : r.name if r.restricted && r.visibility != "private"])}."
  }

  validation {
    condition = alltrue([
      for r in var.repositories :
      alltrue([for t in concat(r.readers, r.writers, r.admins) : contains(keys(var.teams), t)])
    ])
    error_message = "Repositories grant access to teams not present in var.teams: ${join(", ", distinct(flatten([for r in var.repositories : [for t in concat(r.readers, r.writers, r.admins) : "${r.name}:${t}" if !contains(keys(var.teams), t)]])))}."
  }

  validation {
    condition = alltrue(flatten([
      for r in var.repositories : [
        for env, cfg in r.environments : [
          for t in cfg.reviewers : contains(keys(var.teams), t)
        ]
      ]
    ]))
    error_message = "Environment reviewers must be teams present in var.teams."
  }

  validation {
    condition = alltrue(flatten([
      for r in var.repositories : [
        for env, cfg in r.environments :
        cfg.deployment_branch_policy == null ? true :
        cfg.deployment_branch_policy.protected_branches != (length(cfg.deployment_branch_policy.custom_branch_policies) > 0)
      ]
    ]))
    error_message = "Each environment's deployment_branch_policy must set exactly one of: protected_branches = true, or a non-empty custom_branch_policies (not both, not neither)."
  }

  validation {
    condition = alltrue([
      for r in var.repositories :
      r.allow_merge_commit || r.allow_squash_merge || r.allow_rebase_merge
    ])
    error_message = "At least one merge method (allow_merge_commit, allow_squash_merge, allow_rebase_merge) must be enabled on: ${join(", ", [for r in var.repositories : r.name if !(r.allow_merge_commit || r.allow_squash_merge || r.allow_rebase_merge)])}."
  }

  validation {
    condition = alltrue(flatten([
      for r in var.repositories : [
        for rs in values(r.rulesets) : [
          for b in rs.bypass_actors :
          b.actor_type != "Team" || b.team == null || contains(keys(var.teams), b.team)
        ]
      ]
    ]))
    error_message = "Ruleset bypass_actors reference a team not present in var.teams."
  }
}

variable "teams" {
  description = "Map of team name => { id, slug } for teams that may be granted repository access or set as environment reviewers. Supplied by the teams module."
  type = map(object({
    id   = string
    slug = string
  }))
  default = {}
}

variable "all_members_team_id" {
  description = "ID of the all-members team that receives default read access on non-restricted repositories. null disables the default read grant."
  type        = string
  default     = null
}

variable "repository_secrets" {
  description = <<-EOT
    Per-repository Actions and environment secret values (plaintext), keyed by
    repository name. Supplied already-decrypted by the caller; this module never
    performs decryption.
  EOT
  type = map(object({
    actions      = optional(map(string), {})
    environments = optional(map(map(string)), {})
  }))
  default   = {}
  sensitive = true
}
