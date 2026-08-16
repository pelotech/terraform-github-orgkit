# Changelog

## [0.2.0](https://github.com/pelotech/terraform-github-orgkit/compare/v0.1.0...v0.2.0) (2026-08-16)


### ⚠ BREAKING CHANGES

* baseline_ruleset and require_signed_commits are removed. Use enabled_presets (defaults reproduce prior behavior) and organization_rulesets; per-repo rulesets via repositories[].rulesets.
* `unsafe_merges` is removed. Replace `unsafe_merges = true` with `allow_squash_merge = true` and/or `allow_rebase_merge = true`.

### Features

* default repository squash and pre-release release-please config ([#10](https://github.com/pelotech/terraform-github-orgkit/issues/10)) ([2679dc6](https://github.com/pelotech/terraform-github-orgkit/commit/2679dc66f5d97a18190278ee00da64a28281e942))
* expose repository settings and merge controls  ([#8](https://github.com/pelotech/terraform-github-orgkit/issues/8)) ([586dda8](https://github.com/pelotech/terraform-github-orgkit/commit/586dda8df7dd1a4f205fdf13f919b36175d0506c))
* generic rulesets interface with presets (org + per-repo)   ([#9](https://github.com/pelotech/terraform-github-orgkit/issues/9)) ([900c1e9](https://github.com/pelotech/terraform-github-orgkit/commit/900c1e989c27dcdd9e931a9881dadfd4b27ecfdf))
* initial GitHub org management module suite ([a3198ab](https://github.com/pelotech/terraform-github-orgkit/commit/a3198ab6a83a0d4c1843e84d875b3f4453b0428e))


### Chores

* **deps:** update actions/cache action to v6 ([#6](https://github.com/pelotech/terraform-github-orgkit/issues/6)) ([0ca6efb](https://github.com/pelotech/terraform-github-orgkit/commit/0ca6efb047a7a7ecb8710c669648ae002f0d824d))
* **deps:** update actions/checkout action to v7 ([#7](https://github.com/pelotech/terraform-github-orgkit/issues/7)) ([1fdb8e9](https://github.com/pelotech/terraform-github-orgkit/commit/1fdb8e9c47211c47b493a7ffd98dcf8e45e1d373))
