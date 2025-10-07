if (-not (Test-Path 'bin')) {
    New-Item -ItemType Directory -Path "bin"
}

$gameName = "asteroids86"

ml64 /Cp /Zd /Zi "/Fo.\bin\$gameName.obj" src\main.s /link SDL3.lib /debug:full /entry:main "/out:.\bin\$gameName.exe"

if (Test-Path 'mllink$.lnk') {
    Remove-Item 'mllink$.lnk'
}

if ($args.Contains("run")) {
    & ".\bin\$gameName.exe"
}
