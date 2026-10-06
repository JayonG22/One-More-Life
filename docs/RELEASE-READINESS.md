# Release readiness and rights

Updated on 5 October 2026 during v0.92 relationship work. This register records publishing
work and asset provenance. Full release acceptance remains open. The local source
workstream is v0.92. The local v0.90 and v0.91 Windows review packages and source
archives were exported from the working tree on 5 October; v0.92 is in progress and
not packaged. They are not public releases.
No v1.0 package has been produced or published.

## Current public state

- The public repository was rechecked through GitHub on 5 October. Its default
  branch is `claude/new-session-la2mv4`; the current development work is on
  `codex/people-have-lives` locally.
- The public README still reports v0.25.0, and the GitHub releases list is empty.
  The local v0.90 source and documentation are not on that default branch. Keep
  public claims aligned with the code and package actually available there; do
  not advertise the local feature set until a reviewed delivery contains it.
- Earlier local development packages are not public GitHub releases.
  Historical notes saying “shipped” are retained as history.
- The owner reserved gameplay acceptance for personal testing. No gameplay tests,
  simulations or walkthroughs are to be run by the development agent. Any later
  build/export record must identify the exact commit and avoid implying runtime
  acceptance.

## Licensing and provenance

No project-wide licence is present. Do not describe the repository as open source
until the owner chooses an appropriate licence and scope. The engine and fonts
retain their own licences; see [credits](../CREDITS.md). Do not adopt a permissive
licence merely as a documentation cleanup: that grants substantive reuse rights.
GitHub explains the distinction in its [licensing documentation](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/licensing-a-repository).

Record the source and permitted uses of the owner-supplied logo, contributed text,
and future assets. Preserve third-party notices in distributed packages. An art
brief or an attribution entry is not evidence of permission.

## Original Story Life catalog

The owner explicitly chose to replace the older TV-based preview catalog with
six additional original campaigns. The question originally counted six previews;
inspection found four. Those four entries have been removed from the active
catalog and replaced with the six approved originals, alongside the existing six.
The current catalog contains twelve original casts, settings and branching stories.

Older owned saves retain their preview choices and logs in an archived journal.
A living reader starts the corresponding original campaign after a clear notice;
a completed preview remains completed. Migration does not award a story ending.
Archive migration is for existing user saves, not distribution of the old catalog.
Historical releases and Git history remain historical records; they have not been
rewritten. The public package and its documentation must describe the current
original catalog accurately without implying third-party endorsement.

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
