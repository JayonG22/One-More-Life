# Release readiness and rights

Checked against the public default branch on 1 October 2026. This is a practical
publishing register, not a legal opinion or a promise of zero risk.

## Current public state

- The project identifies itself as v0.25.0 and has three public game modes.
- The GitHub releases list is empty; source instructions are the available route.
- v0.26.0 was prepared separately as a local preview. It has not been published
  to this branch. Historical notes saying “shipped” are retained as history.
- Historical test totals and platform-export claims need verification against
  the exact commit and package being released.

## Licensing and provenance

No project-wide licence is present. Do not describe the repository as open source
until the owner chooses an appropriate licence and scope. The engine and fonts
retain their own licences; see [credits](../CREDITS.md). Do not adopt a permissive
licence merely as a documentation cleanup: that grants substantive reuse rights.
GitHub explains the distinction in its [licensing documentation](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/licensing-a-repository).

Record the source and permitted uses of the owner-supplied logo, contributed text,
and future assets. Preserve third-party notices in distributed packages. An art
brief or an attribution entry is not evidence of permission.

## TVLife preview

The local preview uses recognizable characters and series references. A disclaimer,
originally written summaries, or a noncommercial release does not by itself resolve
adaptation rights. The [U.S. Copyright Office overview](https://www.copyright.gov/what-is-copyright/)
describes derivative works among a copyright owner's rights; applicable rules and
exceptions depend on jurisdiction and the actual material.

Before distributing that mode, obtain suitable rights/qualified review, or develop
original characters and stories. Retain the four-category format if useful, while
giving the game its own cast, settings and story arcs. No third-party ownership or
endorsement should be implied.

## Release checklist

- Name the exact version and commit; distinguish a preview from a stable release.
- Run required gates, inspect rendered screens and test save/load and migration.
- Launch the final package on each platform claimed as supported.
- List known limitations, signing status and content themes plainly.
- Review tracked files and package contents for credentials and personal data.
- Include engine/font notices and an explicit project licensing decision.
- Upload only verified packages; do not instruct players to bypass security
  warnings as a default troubleshooting step.

A targeted text scan during this cleanup found no matches for common token,
private-key, AWS access-key or local-home-path patterns. This is not a full security
audit or a scan of the entire Git history.
