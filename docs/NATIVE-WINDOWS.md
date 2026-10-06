# Windows application build

The v0.71 package is a Windows GUI application exported with the official Godot
4.4.1 x86-64 release template. It starts by double-clicking One More Life.exe.
One More Life.pck contains its game resources and stays beside the executable.
There is no command-file launcher, separate editor binary or Runtime subfolder.
The executable carries the project icon, product name and 0.71.0.0 metadata.
The package is unsigned and still in development; the complete v1.0 scope is open.
Only Windows is verified here. No storefront account, publishing purchase or
project-wide code/content reuse licence was created by this work.

## Rebuild from source

1. Open project.godot in Godot 4.4.1 and import resources.
2. Install the matching official export templates through the editor.
3. Configure the official rcedit tool under Editor Settings → Export → Windows
   so the executable gets its icon and product details.
4. Export the Windows Desktop release preset to One More Life.exe. The preset
   disables the console wrapper and uses a separate PCK resource file.
5. Retain engine/font notices, verify launch and saves in an isolated test folder,
   and keep public descriptions aligned with the completion register.

Reference: [Godot Windows export documentation](https://docs.godotengine.org/en/4.4/tutorials/export/exporting_for_windows.html).
The template came from the official Godot 4.4.1 release; the Windows member was
extracted with ZIP CRC verification. rcedit 2.0.0 came from electron/rcedit's
official GitHub release. Neither build helper is a paid dependency.
Game saves retain their existing One More Life user-data location. Test overrides
use isolated folders; a new executable should not create a new save identity.
