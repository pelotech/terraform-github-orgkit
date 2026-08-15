#
# Teams and their memberships.
#

resource "github_team" "internal" {
  for_each = { for t in var.teams : t.name => t }

  name        = each.key
  description = each.value.description
  privacy     = "closed"
}

#
# Reformat teams into team_name => { username => role }. Org owners are
# force-assigned "maintainer" by GitHub in any team they join, so we derive that
# role for owners (rather than tracking a separate maintainers list) to avoid
# perpetual drift; everyone else is a "member". Teams with no members are
# omitted, since github_team_members requires at least one entry.
#

locals {
  people = {
    for t in var.teams : t.name => {
      for person in t.members :
      person => contains(var.owners, person) ? "maintainer" : "member"
    } if length(t.members) > 0
  }
}

#
# The username is looked up through var.members (rather than used directly) to
# express the dependency on organization membership for resource ordering.
#

resource "github_team_members" "internal" {
  for_each = local.people

  team_id = github_team.internal[each.key].id

  dynamic "members" {
    for_each = each.value
    content {
      username = lookup(var.members, members.key, members.key)
      role     = members.value
    }
  }
}

#
# The all-members team: contains every organization member and provides the
# default read access that non-restricted repositories grant (see the repository
# module). Membership is derived from var.members so it stays in sync.
#

resource "github_team" "everyone" {
  count = var.create_all_members_team ? 1 : 0

  name        = var.all_members_team_name
  description = var.all_members_team_description
  privacy     = "closed"
}

resource "github_team_members" "everyone" {
  count = var.create_all_members_team ? 1 : 0

  team_id = github_team.everyone[0].id

  dynamic "members" {
    for_each = var.members
    content {
      username = members.value
      role     = contains(var.owners, members.key) ? "maintainer" : "member"
    }
  }
}

#
# Teams can hold predefined organization roles, declared per-team via `org_roles`
# and resolved by name from the org's predefined roles. Unknown names fail via
# the precondition, validated against the roles that actually exist.
#

data "github_organization_roles" "internal" {}

locals {
  # lowercased predefined role name => role_id
  predefined_role_ids = {
    for role in data.github_organization_roles.internal.roles :
    lower(role.name) => role.role_id
    if role.source == "Predefined"
  }

  # "<team>:<role>" => { team, role }
  team_org_roles = merge([
    for t in var.teams : {
      for role in t.org_roles :
      "${t.name}:${lower(role)}" => { team = t.name, role = lower(role) }
    }
  ]...)
}

resource "github_organization_role_team" "internal" {
  for_each = local.team_org_roles

  team_slug = github_team.internal[each.value.team].slug
  role_id   = local.predefined_role_ids[each.value.role]

  lifecycle {
    precondition {
      condition     = contains(keys(local.predefined_role_ids), each.value.role)
      error_message = "Team '${each.value.team}' requests unknown predefined org role '${each.value.role}'. Valid: ${join(", ", sort(keys(local.predefined_role_ids)))}."
    }
  }
}
