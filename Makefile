SRC=src\* src\data\* src\fx\* src\sdl\* src\windows\*

bin/asteroids86.exe: bin/asteroids86.obj resources/resources.res
	link bin\asteroids86.obj resources\resources.res SDL3.lib kernel32.lib /entry:main /out:bin\asteroids86.exe

bin/asteroids86.obj: $(SRC)
	ml64 /c /Cp /Fo bin\asteroids86.obj src\main.s

resources/resources.res:
	rc resources\resources.rc

clean:
	del /Q bin\*
	del resources\resources.res

.PHONY: clean
