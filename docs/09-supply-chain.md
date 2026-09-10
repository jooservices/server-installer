# Supply chain

Every directly executed binary or installer script is declared in
`metadata/downloads.json`. An entry contains an exact HTTPS URL (including a
release version or source commit where the vendor supports one) and a
SHA-256 checksum. Modules request an artifact by ID; they cannot provide an
unlocked URL or bypass checksum verification.

The installer writes downloads to a `.part` file, validates the SHA-256, and
only then moves the file into place. A mismatch or missing lock entry stops
the module before extraction or execution.

## Updating an artifact

1. Obtain the checksum from the vendor's signed release manifest when one is
   available.
2. Update the artifact URL, version-specific ID, and SHA-256 in the lockfile
   in the same pull request.
3. Update the module's default version and run `make downloads-test`.

Some vendor bootstrap scripts fetch additional vendor-managed dependencies.
The first script is pinned and checked by this project; when the vendor
supports a release version, the module passes a pinned version explicitly.
Prefer a directly locked release binary when one is available.

The lockfile does not replace operating-system package signature verification.
APT, DNF, Yum, and Homebrew keep using their native signed repository model.
