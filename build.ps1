ml64 /Cp /Fo.\bin\asteroids86.obj src\main.s /link SDL3.lib /entry:main /out:.\bin\asteroids86.exe

if (Test-Path 'mllink$.lnk') {
    Remove-Item 'mllink$.lnk'
}
