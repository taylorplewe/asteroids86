# asteroids86

My implementation of the classic Asteroids arcade game, written in pure x86 assembly (the x stands for asteroids)

![asteroids86-title](https://github.com/user-attachments/assets/f0a38147-d8a0-4584-8845-d3942374e168)

> [!NOTE]
> This is the main branch targeting **Windows.** For other operating systems running on x86 like **Mac** or **Linux**, see the [`nasm-sdl`](https://github.com/taylorplewe/asteroids86/tree/nasm-sdl) branch.

Note that currently, it relies on and statically links in SDL3. I plan on removing this dependency in the future, only calling Win32 functions for creating a window and displaying my pixel buffer, etc.
