variable "teams" {
  description = <<-EOT
    Teams and their membership. A team may hold predefined organization-level
    GitHub roles via `org_roles` (one assignment per role), resolved by name
    against the organization's predefined roles (e.g. `security_manager`,
    `app_manager`, `cicd_admin`). Unknown role names fail at plan time.
  EOT
  type = list(object({
    name        = string
    description = string
    members     = optional(list(string), [])
    org_roles   = optional(list(string), [])
  }))
  default = []
}

variable "owners" {
  description = <<-EOT
    Organization owner usernames. GitHub force-assigns owners the `maintainer`
    role in any team they join, so the module assigns that role to them (and
    `member` to everyone else) to avoid perpetual drift.
  EOT
  type        = set(string)
  default     = []
}

variable "members" {
  description = <<-EOT
    Map of org member username => username, from the organization module. Used to
    order team membership after organization membership. Falls back to the raw
    username when a member is not present (standalone use).
  EOT
  type        = map(string)
  default     = {}
}

variable "create_all_members_team" {
  description = "Create a team containing every organization member, used to grant default read access to non-restricted repositories."
  type        = bool
  default     = true
}

variable "all_members_team_name" {
  description = "Name of the all-members team."
  type        = string
  default     = "everyone"
}

variable "all_members_team_description" {
  description = "Description of the all-members team."
  type        = string
  default     = "All organization members. Grants default read access to non-restricted repositories."
}
