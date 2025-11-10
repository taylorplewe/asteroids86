# asteroids~86~

My implementation of the classic Asteroids arcade game, written in pure x86 assembly (the x stands for asteroids)

The whole game compiles to an executable binary just under __40KB__ in size.

![asteroids86-title](https://github.com/user-attachments/assets/f0a38147-d8a0-4584-8845-d3942374e168)

> [!NOTE]
> This is the main branch targeting **Windows.** For other operating systems running on x86 like **Mac** or **Linux**, see the [`nasm-sdl`](https://github.com/taylorplewe/asteroids86/tree/nasm-sdl) branch.

## Controls
Controllers & rumble are supported!
### Keyboard
| Key | Action |
| - | - |
| `w` or up arrow | Boost |
| `s` or down arrow | Hyperspace |
| `a`/`d` or left/right arrow | Turn |
| `l` or spacebar | Fire |
| `Esc` | Pause |

### Controller
| Xbox/PlayStation | Action |
| - | - |
| __A__/✕ | Fire |
| __B__/○ | Fire |
| __X__/□ | Hyperspace |
| __Y__/△ | Hyperspace |
| D-pad up | Boost |
| D-pad down | Hyperspace |
| D-pad left/right | Turn |
| RT/R2 | Boost |
| LT/L2 | Hyperspace |
| Start | Pause |

## Building
> [!IMPORTANT]
> Currently, it depends on and dynamically links to SDL3. I plan on removing this dependency in the future, only calling Win32 functions for creating a window and displaying my pixel buffer, etc.

### Requirements
- [SDL3](https://github.com/libsdl-org/SDL/releases). Make sure `SDL3.lib` can be accessed from your `LIB` environment variable.
- MSVC toolchain. The required binaries are:
  - `ml64.exe`. The actual assembler, which itself invokes the linker afterwards.
  - `link.exe`, the linker.
  - (optional) `rc.exe`, for compiling binary resources in the `resources\` directory.
- There is only a Powershell build script. If you're not running PowerShell, just look at the build script and run whatever command you need manually.

Once the above requirements are met, run any one of the following commands in the root directory:
```powershell
.\build             # build a debug executable
.\build run         # build and run a debug executable
.\build release     # build an executable with no debug information
.\build release run
.\build res         # compile the resources in the resources directory and build an executable
```