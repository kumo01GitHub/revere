## 2.0.0

* feat: remove flutter dependency.
* chore: cleanup pubspec.

## 1.1.0

* feat: add `LogLevel.silent` — a threshold-only sentinel that suppresses all output from a transport when set as its minimum level.
* feat: add `SamplingTransport` decorator and `withSampling` extension.
* docs: unified package listing order (file → firebase → android → swift → notification) in README.
* docs: remove redundant Directory Structure section from root README.
* ci: unified package listing order in CI and bump workflows.
* ci: pin dart-lang/setup-dart to commit hash instead of mutable v1 tag.
* ci: add `workflow_dispatch` trigger for manual execution; add `run_integration_tests` input (default: `false`) — integration tests are skipped on pull request and push.
* chore: update example pubspec.lock.
* chore: improve test coverage.
* chore: remove affected packages checklist from PR template.

## 1.0.0

* Initial release.
