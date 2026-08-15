output "repository_ids" {
  description = "Managed repositories (name => repo_id)."
  value       = module.repositories.repository_ids
}
