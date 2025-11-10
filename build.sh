GAMENAME="asteroids86"

asmArgs=(
  src/main.asm
  -f elf64
  -o "bin/$GAMENAME.o"
)

linkerArgs=(
  "bin/$GAMENAME.o"
  -l SDL3
  -e main
  -o "bin/$GAMENAME"
)

nasm ${asmArgs[*]}
ld ${linkerArgs[*]}