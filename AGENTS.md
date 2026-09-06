# server-installer

This file adds project-only rules.

- CLI / bash server bootstrap wizard (not a hosting control panel)
- Production support target: Debian/Ubuntu and RHEL-family Linux on amd64/arm64
- Rebuild feature-by-feature from archive; do not bulk-copy
- Default PHP target for JOOservices hosts: `8.5`
- Secrets never committed (credentials, reports with secrets)
