![Title image](art/title.gif)

My implementation of the classic Asteroids arcade game, written in pure x86_64 assembly.

The whole game compiles to an executable binary just under __40KB__ in size.

If you want to try it out, grab the .exe from the [Releases](https://github.com/taylorplewe/asteroids86/releases) page, or see the [Building](#building) section to build from source!

> [!NOTE]
> This is the main branch targeting **Windows.** For other operating systems running on x86 like **Mac** or **Linux**, see the [`nasm-sdl`](https://github.com/taylorplewe/asteroids86/tree/nasm-sdl) branch.

## Controls
Controllers & rumble are supported!
| Action | Keyboard | Controller (Xbox/PlayStation) |
| - | - | - |
| Boost | `w`, Up arrow | RT/R2, D-pad up |
| Fire | `l`, Spacebar | A/Cross, B/Circle |
| Hyperspace | `s`, Down arrow | X/Square, Y/Triangle, D-pad down |
| Turn | `a`/`d`, Left/Right arrow | Left thumbstick, D-pad left, D-pad right |
| Pause | `Esc` | Start |

### See more gameplay 👉 [https://youtu.be/xbh1nvG8m4U](https://youtu.be/xbh1nvG8m4U)

![Gameplay](art/gameplay.gif)

## Building
> [!IMPORTANT]
> Currently, it depends on and dynamically links to SDL3. I plan on removing this dependency in the future, only calling Win32 functions for creating a window and displaying my pixel buffer, etc.

### Requirements
- [SDL3](https://github.com/libsdl-org/SDL/releases). Make sure `SDL3.lib` can be accessed from your `LIB` environment variable.
- MSVC toolchain. See the [docs](https://learn.microsoft.com/en-us/cpp/build/building-on-the-command-line) for how to acquire them. Then make sure they're on your PATH--this is easily done on Windows 11 via Windows Terminal by clicking the dropdown arrow next to the new tab button and selecting "Developer Command Prompt for VS 2022" or its PowerShell equivelant. On Windows 10, see if you have a "x64 Native Tools Command Prompt for VS 2022" shortcut in your Start menu. The required binaries are:
  - `ml64.exe`. The 64-bit MASM assembler, which itself invokes the linker afterwards.
  - `link.exe`, the linker.
  - `rc.exe`, for compiling binary resources in the `resources\` directory. I don't love this method of including binaries and referencing those binaries in the code, but MASM has no `incbin` directive like most assemblers, and this appears to be the recommended method.
  - (optional) `nmake.exe`, for building via the Makefile (recommended)

Once the above requirements are met and binaries all in your PATH, simply run `nmake` in the root directory!

Alternatively, there is a Powershell build script with more granular control, so if you're running Powershell, you can run any one of the following commands in the root directory:
```powershell
.\build             # build a debug executable
.\build run         # build and run a debug executable
.\build release     # build an executable with no debug information
.\build release run
.\build res         # compile the resources in the resources directory and build an executable
```

---

### To do
- Remove SDL dependency
- Port to DOS

### Axed because I had to scale it back
- Invincibility power-up
- Render bullets as a streak instead of a dot
- Make lines glow
- Anti-aliasing
- Sound
