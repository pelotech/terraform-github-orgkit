output "teams" {
  description = "Managed teams (name => { id, slug })."
  value       = module.orgkit.teams
}

output "repository_ids" {
  description = "Managed repositories (name => repo_id)."
  value       = module.orgkit.repository_ids
}
