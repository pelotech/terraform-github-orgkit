output "members" {
  description = "Map of username => username: the managed membership's username when membership is managed (so team memberships are ordered after organization membership), the raw username otherwise. Passed to the teams module."
  value = {
    for m in var.members : m =>
    !var.manage_membership ? m :
    var.remove_unlisted_members ? github_membership.removable[m].username : github_membership.internal[m].username
  }
}
