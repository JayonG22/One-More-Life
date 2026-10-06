# v0.26.0 validation

Recovered from the interrupted development session and checked with Godot 4.4.1 on Windows. Tests use isolated save folders.

The new simulation gate covers saved weather, eligibility, repeated wording, pacing, timeline pools, job-board stability, qualification fit, course limits, market migration, bounded price histories, autonomous local stories and all TVLife chapters and save checkpoints. The new UI gate covers mode selection, custody and release, timeline ribbons and TVLife endings.

All **30 release gates passed**, including the existing v0.8–v0.25 checks and the two new v0.26 gates. Tests were run individually with isolated save folders on Windows; screen-dependent tests used OpenGL. The long minigame bot run completed within the repository's 1,500-second gate limit.

| Check | Result |
| --- | --- |
| New simulation gate | 204 checks, zero failures |
| New UI gate | Zero failures; title preview, custody/release, timelines and TVLife completion |
| Event outcomes | 431 definitions, 2,586 outcomes, 2,826 checks, zero failures |
| Life simulation | 79 lives, 4,516 simulated years; no script errors |
| Menu crawl | 2,050 menus and 10,915 actions; no script errors |
| Minigame bot | 39 games, no unwinnable or missing games |
| Existing layout audit | 3,173 controls, zero problems at 1920×1080 |
| Performance | 300 years, average 39 ms/year; zero failures |
| Migration, casino sessions, keyboard input, accessibility, pet/prison UI | Passed |
| Rendered screenshots | Inspected title, custody, release, timeline, TVLife chapter, investments, custom stake and Star Shop at 1600×900 |
| Windows preview pack | Exported successfully; startup smoke check passed with isolated saves |

The source archive requires Godot. The Windows preview bundles the official
Godot 4.4.1 engine and the exported game pack, and launches through `Play One More
Life.cmd`. It is a portable preview, not a signed standalone production export.
The preview ZIP and source ZIP passed archive integrity checks.

The sandbox reported a root-certificate-store warning, and some existing tests
reported shutdown resource/anchor warnings. Final functional gates had no script
errors. The duplicated prison event ID was corrected and is covered by the new
content-uniqueness check. Automated checks and screenshot inspection do not
substitute for a full manual playthrough or testing on other operating systems.
