# Security Policy

## Supported Versions

Only the latest release on the `master` branch receives security fixes. Older tagged releases are not patched.

| Version | Supported |
|---------------|-----|
| v1.0.0-beta.1 | Yes |

## Scope

This policy covers vulnerabilities **in pxSentinel itself**, for example:

- A bypass technique that allows a malicious resource to evade detection
- A false-positive class that could cause pxSentinel to stop a legitimate resource
- A logic flaw in the `onResourceFsPermissionViolation` handler that could be exploited by a backdoor to silence alerts
- Any issue with the Discord webhook dispatch that could leak the webhook URL

Reports about third-party backdoors or malicious resources found on your server are **not** security vulnerabilities in pxSentinel. Please open a standard issue or pull request to contribute new signatures to `blocked.lua` instead. See the [contribution notes in the README](../README.md#keeping-signatures-up-to-date).

## Reporting a Vulnerability

**Do not open a public GitHub issue for security vulnerabilities.** Doing so exposes the bypass technique before a fix is available and gives backdoor authors time to adapt.

Please report privately using one of the following methods:

1. **GitHub private vulnerability reporting (preferred):** Use the [Security - Report a vulnerability](../../security/advisories/new) button on the repository page. This opens a private advisory draft visible only to maintainers.

2. **Direct contact:** If you are unable to use GitHub's reporting tool, reach out via the contact details on [codemeapixel.dev](https://codemeapixel.dev).

Please include the following in your report:

- A clear description of the vulnerability and its impact
- Steps to reproduce or a minimal proof-of-concept
- The version or commit hash you tested against
- Any suggested fix, if you have one

## Response Process

| Step | Target Timeframe |
|---|---|
| Acknowledgement | Within 48 hours |
| Initial triage and severity assessment | Within 5 days |
| Fix development and testing | Depends on complexity |
| Patch release and public advisory | Coordinated with reporter |

We follow a coordinated disclosure model. Once a fix is released, a public GitHub Security Advisory will be published crediting the reporter unless anonymity is requested.

## Out of Scope

The following are **not** considered vulnerabilities in pxSentinel:

- A backdoor that pxSentinel does not currently detect. Please contribute a signature via pull request instead.
- Social engineering or phishing attacks targeting server administrators
- Vulnerabilities in FiveM, txAdmin, or third-party resources that pxSentinel cannot mitigate
- The intentional behaviour of `Config.StopResources` triggering a kill-switch. This risk is documented in the README and is a deliberate design trade-off.
