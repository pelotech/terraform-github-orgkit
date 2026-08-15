output "members" {
  description = "Map of username => managed membership username. Passed to the teams module so team memberships are ordered after organization membership."
  value       = { for m in var.members : m => github_membership.internal[m].username }
}
