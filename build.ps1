if (-not (Test-Path 'bin')) {
    Write-Output "'bin' directory not found, I will create it"
    New-Item -ItemType Directory -Path "bin"
}

if (-not (Get-Command "SDL3.dll" -ErrorAction SilentlyContinue)) {
    Write-Error "SDL3.dll not found. Is it in your PATH?"
    Write-Output "`nIf SDL3 isn't installed on your system, you can download it from: https://github.com/libsdl-org/SDL/releases"
    return
}

if (
    -not (Get-Command "ml64" -ErrorAction SilentlyContinue) -or
    -not (Get-Command "link" -ErrorAction SilentlyContinue) -or
    -not (Get-Command "rc" -ErrorAction SilentlyContinue)
) {
    Write-Error "`"ml64.exe`", `"link.exe`" and/or `"rc.exe`" were not found. Are they in your PATH?"
    Write-Output "`nYou can open a Developer PowerShell for VS 20xx from Windows Terminal to get access to the build tools."
    Write-Output "`nIf you do not have the build tools installed, you can get them from the Visual Studio Installer, which can be downloaded here: https://visualstudio.microsoft.com/downloads/"
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
    "/Cp",                    # preserve case of user identifiers
    "/Fo.\bin\$gameName.obj", # name .obj output file
    "src\main.s"
)
$linkerArgs = @(
    "SDL3.lib",
    "kernel32.lib",
    ".\resources\resources.res",
    "/entry:main",
    "/out:.\bin\$gameName.exe"
)
if (!$args.Contains("release")) {
    $asmArgs += @("/Zd", "/Zi")
    $linkerArgs += "/debug:full"
}
if ($args.Contains("w")) {
    $asmArgs += @("/w")
}

ml64 $asmArgs /link $linkerArgs

if ($LASTEXITCODE -ne 0) { return }

if (Test-Path 'mllink$.lnk') {
    Remove-Item 'mllink$.lnk'
}

if ($args.Contains("run")) {
    & ".\bin\$gameName.exe"
}
