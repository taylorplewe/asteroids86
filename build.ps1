if (-not (Test-Path 'bin')) {
    Write-Output "'bin' directory not found, I will create it"
    New-Item -ItemType Directory -Path "bin"
}

if (-not (Get-Command "SDL3.dll" -ErrorAction SilentlyContinue)) {
    Write-Error "SDL3.dll not found. Is it in your PATH?"
    Write-Output "If SDL3 isn't installed on your system, you can download it from: https://github.com/libsdl-org/SDL/releases"
    return
}

if (-not (Get-Command "ml64" -ErrorAction SilentlyContinue)) {
    Write-Error "ml64.exe not found. Is it in your PATH?"
    Write-Output "You can open a Developer PowerShell for VS 20xx from Windows Terminal to get access to the build tools."
    Write-Output "If you do not have the build tools installed, you can get them from the Visual Studio Installer, which can be downloaded here: https://visualstudio.microsoft.com/downloads/"
    return
}

$gameName = "asteroids86"

ml64 `
    /Cp `
    /Zd `
    /Zi `
    "/Fo.\bin\$gameName.obj" `
    src\main.s `
    /link `
    SDL3.lib `
    /debug:full `
    /entry:main `
    "/out:.\bin\$gameName.exe"

if ($LASTEXITCODE -ne 0) { return }

if (Test-Path 'mllink$.lnk') {
    Remove-Item 'mllink$.lnk'
}

if ($args.Contains("run")) {
    & ".\bin\$gameName.exe"
}
