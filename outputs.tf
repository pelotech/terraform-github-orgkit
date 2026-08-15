output "members" {
  description = "Map of organization member username => managed membership username."
  value       = module.organization.members
}

output "teams" {
  description = "Map of team name => { id, slug }."
  value       = module.teams.teams
}

output "all_members_team_id" {
  description = "ID of the all-members team, or null when create_all_members_team = false."
  value       = module.teams.all_members_team_id
}

output "repository_ids" {
  description = "Map of repository name => numeric repo_id."
  value       = module.repository.repository_ids
}
