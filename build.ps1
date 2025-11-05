if (-not (Test-Path 'bin')) {
    Write-Output "'bin' directory not found, I will create it"
    New-Item -ItemType Directory -Path "bin"
}

if (-not (Get-Command "SDL3.dll" -ErrorAction SilentlyContinue)) {
    Write-Error "SDL3.dll not found. Is it in your PATH?"
    Write-Output "`nIf SDL3 isn't installed on your system, you can download it from: https://github.com/libsdl-org/SDL/releases"
    return
}

if (-not (Get-Command "nasm" -ErrorAction SilentlyContinue)) {
    Write-Error "`"nasm.exe`" was not found. Is it in your PATH?"
    Write-Output "Since you are on the `"nasm-sdl`" branch, this project is to be assembled with Netwide Assembler (NASM). It can be downloaded from the official website: https://www.nasm.us/"
    return
}

if ($args.Contains("res")) {
    Push-Location .\resources
    rc resources.rc
    if ($LASTEXITCODE -ne 0) {
        Pop-Location
        return
    }
    Pop-Location
}

$gameName = "asteroids86"

$asmArgs = @(
    src/main.s
)
# $linkerArgs = @(
#     "SDL3.lib"
# )
if (!$args.Contains("release")) {
    # $asmArgs += @("-g")
}
if ($args.Contains("w")) {
    $asmArgs += @("-Werror")
}

nasm $asmArgs

if ($LASTEXITCODE -ne 0) { return }

if (Test-Path 'mllink$.lnk') {
    Remove-Item 'mllink$.lnk'
}

if ($args.Contains("run")) {
    & ".\bin\$gameName.exe"
}
