
## 1.1.0

* chore: update revere dependency to ^1.1.0.
* chore: upgrade `sentry_flutter` from `^8.0.0` to `^9.16.0`.
* chore: expand `description` in `pubspec.yaml` to meet pub.dev requirements.
* ci: add `workflow_dispatch` trigger for manual execution; add `run_integration_tests` input (default: `false`) — integration tests are skipped on pull request and push.

## 1.0.0

* Initial release.
* `SentryTransport`: routes `error`/`fatal` to `captureException`, others to `addBreadcrumb`.
* `SentryTrackerMixin`: breadcrumb tracking, error reporting, and global Flutter error hooks.
