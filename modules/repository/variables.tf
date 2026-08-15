variable "repositories" {
  description = <<-EOT
    Repositories to manage and which teams may access them. `readers`, `writers`
    and `admins` reference team names from `var.teams`. A team listed at more than
    one level gets the highest permission (admin > write > read). Set
    `restricted = true` to withhold the default all-members read grant.
  EOT
  type = list(object({
    name           = string
    description    = string
    visibility     = optional(string, "private")
    readers        = optional(list(string), [])
    writers        = optional(list(string), [])
    admins         = optional(list(string), [])
    restricted     = optional(bool, false)
    enable_pages   = optional(bool, false)
    unsafe_merges  = optional(bool, false)
    signed_commits = optional(bool, true)
    variables      = optional(map(string), {})
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
