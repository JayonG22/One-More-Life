# Development guide

## Run and inspect

Use Godot 4.4.1 as the reproducible engine target. Import `project.godot` and run
the main scene with F5. Other engine versions need their own verification.

| Directory | Purpose |
| --- | --- |
| `autoload/` | Simulation, actions, finance, relationships, saves and audio |
| `scenes/` | Main interface, panels and minigames |
| `data/` | Events, jobs, education and other content |
| `tools/` | Simulation, interface, migration and minigame checks |
| `tools/content/` | Content generation and review helpers |
| `fonts/`, `art/`, `audio/` | Resources and asset-related material |
| `docs/` | Player, developer, art, publishing and historical documentation |

## Checks

The existing shell tools run in Bash, for example Linux or WSL:

```sh
tools/run_gates.sh /path/to/godot
tools/mig_check.sh /path/to/godot
python3 tools/content/thin.py
```

Set `OML_USER_DIR` to a disposable directory when running tests. Confirm each
test's output and exit status; historical pass counts do not certify new changes.
Some interface checks require rendering, so a headless pass alone is insufficient.

## Content

Events are JSON under `data/events/`. Inspect an existing event and the loader
before adding a new category. For generated content, update the generator and
follow the [documented run order](../tools/content/README.md). Keep event IDs
unique, provide meaningful choices, and verify eligibility and delayed outcomes.
Use recurring people and consequences where possible. Put costs in the choice
label; `{money:250}` is formatted in the player's currency, and `requires.money`
keeps an unaffordable choice disabled. Avoid new scenes that ignore a character's
age, place, health, job or past decisions.
Set `remember_relationship: true` on a choice event when even a modest bond change
should become a saved relationship memory and a Life Thread tied to that person.
Major bond changes already create a Life Thread automatically.

## Exporting

Install the matching Godot export templates, then use `export_presets.cfg` or:

```sh
tools/build_release.sh /path/to/godot /absolute/path/to/output
```

Windows metadata/icon setup also requires rcedit. Keep JSON resources in the
export filters. The script contains export presets for Windows, macOS and Linux;
presets alone do not establish successful builds or real-device compatibility.
Inspect the exported files and launch each packaged build before publishing it.
Unsigned builds must be described honestly, with platform-specific instructions.

Package the [credits](../CREDITS.md), relevant third-party licence notices and
version history alongside binaries. See [release readiness](RELEASE-READINESS.md).
