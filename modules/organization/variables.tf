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

variable "baseline_ruleset" {
  description = <<-EOT
    Baseline org-wide branch-protection ruleset applied to the default branch of
    every repository. Set `enabled = false` to disable it entirely. Defaults
    reproduce a require-review + code-owner-review + thread-resolution policy.
  EOT
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
  description = "Require signed commits on all branches of all repositories (except those excluded)."
  type        = bool
  default     = true
}

variable "signed_commits_excluded_repositories" {
  description = "Repository names excluded from the required-signed-commits ruleset."
  type        = list(string)
  default     = []
}
