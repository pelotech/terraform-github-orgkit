output "repository_ids" {
  description = "Map of repository name => numeric repo_id. Consumed at the root to scope org-level secrets/variables with 'selected' visibility."
  value       = { for name, repo in github_repository.internal : name => repo.repo_id }
}

output "repositories" {
  description = "Map of repository name => full github_repository resource attributes."
  value       = github_repository.internal
}
