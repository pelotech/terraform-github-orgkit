output "members" {
  description = "Map of username => managed membership username. Passed to the teams module so team memberships are ordered after organization membership."
  value = {
    for m in var.members : m =>
    var.remove_unlisted_members ? github_membership.removable[m].username : github_membership.internal[m].username
  }
}
