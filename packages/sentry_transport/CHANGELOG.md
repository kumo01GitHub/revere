## 1.0.0

* Initial release.
* `SentryTransport`: routes `error`/`fatal` to `captureException`, others to `addBreadcrumb`.
* `SentryTrackerMixin`: breadcrumb tracking, error reporting, and global Flutter error hooks.
