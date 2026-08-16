# Contributing

Thanks for contributing to **terraform-github-orgkit**!

## Development workflow

- Work on a feature branch — never commit directly to `main`.
- Use [Conventional Commits](https://www.conventionalcommits.org/). PR titles are
  linted, and `release-please` derives the changelog and version from them.
- Before opening a PR:

  ```sh
  terraform fmt -recursive
  pre-commit run --all-files
  # run tests for any submodule you touched
  cd modules/<name> && terraform init && terraform test
  ```

- When you change inputs, outputs, or resources, the `terraform_docs` pre-commit
  hook regenerates each README — commit the result.

## Testing

Tests use `terraform test` with a mocked provider (`command = plan`), so they need
**no GitHub credentials**. Add coverage for new validations and behavior; keep test
output pristine (warnings are treated as failures).

## Design & scope

Read [`docs/DESIGN.md`](docs/DESIGN.md) for the architecture, the composition DAG,
the feature roadmap, and the design principles that must not be violated — notably:
no hardcoded organization policy, and **secrets are never decrypted here** (callers
pass already-decrypted values).

## Pre-1.0

The input interface may still change between minor releases (see the README
"Stability" section). Call out any breaking input changes in your PR description.
