output "teams" {
  description = "Map of team name => { id, slug } for every managed team. Consumed by the repository module for team↔repo grants and environment reviewers."
  value = {
    for name, team in github_team.internal :
    name => { id = team.id, slug = team.slug }
  }
}

output "all_members_team_id" {
  description = "ID of the all-members team, or null when create_all_members_team = false."
  value       = var.create_all_members_team ? github_team.everyone[0].id : null
}
