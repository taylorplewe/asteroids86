GAMENAME="asteroids86"

asmArgs=(
  src/main.asm
  -f elf64
  -o bin/asteroids86.o
)

# linkerArgs=(
#   bin/asteroids86.o
#   SDL3.lib
# )

# echo ${asmArgs[*]}

nasm ${asmArgs[*]}

# $gameName = "asteroids86"

# $asmArgs = @(
#     "src/main.asm",
#     "-f win64",
#     "-o bin/asteroids86.obj"
# )
# $linkerArgs = @(
#     "bin\asteroids86.obj",
#     "SDL3.lib",
#     "/out:bin\asteroids86.exe",
#     "/entry:main"
# )
# if (!$args.Contains("release")) {
#     $asmArgs += @("-g")
#     $linkerArgs += @("/debug:full")
# }
# if ($args.Contains("w")) {
#     $asmArgs += @("-werror")
# }

# nasm $asmArgs

# if ($LASTEXITCODE -ne 0) { return }

# link $linkerArgs

# if (Test-Path 'mllink$.lnk') {
#     Remove-Item 'mllink$.lnk'
# }

# if ($args.Contains("run")) {
#     & ".\bin\$gameName.exe"
# }
