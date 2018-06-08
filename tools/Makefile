all: worlded2.exe spred2.exe pchunk2.exe maked64.exe symbols.exe

clean:
	del *.exe
	del *.spr
	del editor.pal
	del editor.dat
	del editdata.c

editor.dat: editor.lbm editfont.lbm
	bmeconv -s -t255 -r254 -h253 editor.lbm editor.spr
	bmeconv -s -t255 -r254 -h253 editfont.lbm editfont.spr
	bmeconv -p editor.lbm editor.pal
	datafile editor.dat filelist.txt

editdata.c: editor.dat
	dat2inc editor.dat editdata.c

worlded2.exe: worlded2.cpp editdata.c stb_image_write.c
	g++ worlded2.cpp editdata.c stb_image_write.c libbme.a -oworlded2.exe -w -march=i386 -static-libstdc++ -static-libgcc -lmingw32 -lSDLmain -lSDL -Wl,-Bstatic -lstdc++ -lpthread -Wl,-Bdynamic
	strip worlded2.exe

spred2.exe: spred2.c fileio.c editdata.c
	gcc spred2.c fileio.c editdata.c libbme.a -ospred2.exe -lmingw32 -lSDLmain -lSDL
	strip spred2.exe

pchunk2.exe: pchunk2.c
	gcc pchunk2.c -opchunk2.exe

maked64.exe: maked64.c
	gcc maked64.c -omaked64.exe

symbols.exe: symbols.c
	gcc symbols.c -osymbols.exe