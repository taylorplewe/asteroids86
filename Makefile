SRC=src\* src\data\* src\fx\* src\sdl\* src\windows\* Makefile

bin/asteroids86.exe: bin bin/asteroids86.obj resources/resources.res
	link bin\asteroids86.obj resources\resources.res user32.lib gdi32.lib kernel32.lib /entry:main /subsystem:windows /out:bin\asteroids86.exe

bin/asteroids86.obj: bin $(SRC)
	ml64 /c /Cp /Fo bin\asteroids86.obj src\main.s

bin:
    if not exist bin mkdir bin

resources/resources.res:
	rc resources\resources.rc

clean:
	del /Q bin\*
	del resources\resources.res

run: bin/asteroids86.exe
	.\bin\asteroids86.exe

.PHONY: clean run
