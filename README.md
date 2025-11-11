![Title image](art/title.gif)

My implementation of the classic Asteroids arcade game, written in pure x86_64 assembly.

The whole game compiles to an executable binary just under __40KB__ in size.

If you want to try it out, grab the .exe from the [Releases](https://github.com/taylorplewe/asteroids86/releases) page, or see the [Building](#building) section to build from source!

> [!NOTE]
> This is the `nasm-sdl` branch targeting **multiple operating systems like Linux and macOS**, written in NASM syntax. For the original **Windows** version written in MASM syntax, see the [`main`](https://github.com/taylorplewe/asteroids86/tree/main) branch.

> [!NOTE]
> If you're on a Mac with an Apple Silicon (ARM) processor, it may be possible to get asteroids86 working via Rosetta 2, though this has not been tested.

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
> Currently, it depends on and dynamically links to SDL3. While I do plan on removing the SDL3 dependency for the *Windows* branch and only call native Windows functions, I do not plan on removing it for this branch. Using SDL is just easy to get working on other operating systems.

### Requirements
- [SDL3](https://github.com/libsdl-org/SDL/releases). (You may have to build from source.) Make sure `libSDL3.so` is in one of the directories that `ld` looks for libraries; `/lib`, `/usr/lib`, `/usr/local/lib`, etc. I recommend creating a symlink in `/usr/local/lib` that points to your SDL `build` directory. Alternatively, you can just pass the directory `libSDL3.so` is found in with the `-L` flag to `ld`. (e.g. `ld ... -L ~/SDL3/build/`)
- [nasm](https://www.nasm.us) v3.01. You *may* have to build from source if your distro isn't supported or is outdated. I did. 🤷‍♂️
- GNU `ld` linker

Once the above requirements are met, run the following command in the root directory:
```bash
./build
```
And then run the executable with:
```bash
./bin/asteroids86
```

> [!NOTE]
> I have only tested this on Windows Subsystem for Linux (WSL). If you have an x86-based Mac or Linux machine, *please let me know if you're able to build with these instructions, or if I'm missing anything!*

---

### To do
- Remove SDL dependency for Windows
- Port to DOS

### Axed because I had to scale it back
- Invincibility power-up
- Render bullets as a streak instead of a dot
- Make lines glow
- Anti-aliasing
- Sound
