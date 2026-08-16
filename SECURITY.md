# Security Policy

## Reporting a vulnerability

Please report security issues **privately** via GitHub's
[private vulnerability reporting](https://docs.github.com/en/code-security/security-advisories/guidance-on-reporting-and-writing-information-about-vulnerabilities/privately-reporting-a-security-vulnerability)
on this repository's **Security** tab ("Report a vulnerability"). Do not open a
public issue for security problems.

We will acknowledge your report and keep you updated on remediation.

## Supported versions

This module is pre-1.0; only the latest minor release receives fixes.

## A note on secrets

orgkit **never decrypts secrets**. Callers pass already-decrypted values via the
`secrets` input; decryption is a consumer concern. Do not commit plaintext secrets
to configurations that use this module — pass them from a secure source at apply time.
