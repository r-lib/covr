# Releases

The pkgdown site uses `development: mode: auto`. The site root
(https://covr.r-lib.org/) is only rebuilt when the pkgdown workflow runs on a
commit with a release version (e.g. `3.6.5`); development versions
(e.g. `3.6.5.9000`) build to `/dev`.

When releasing:

- Push the release version commit on its own and let the pkgdown workflow run
  before pushing the `.9000` version bump. If both are pushed together, only
  the latest commit is built and the released site is never updated.
- Publish a GitHub release for the version tag (`gh release create vX.Y.Z
  --verify-tag`). This also triggers a release build of the site.

If the site root still shows the previous version, publish the missing GitHub
release, or run the pkgdown workflow manually on the release tag.
