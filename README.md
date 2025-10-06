# asteroids86

My implementation of the classic Asteroids arcade game, written in 100% pure x86 assembly (the x stands for asteroids)

Note that currently, it relies on and statically links in SDL3. I plan on removing this dependency in the future, only calling Win32 functions for creating a window and displaying my pixel buffer, etc.
