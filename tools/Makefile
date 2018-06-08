all: worlded2.exe spred2.exe pack2.exe pchunk2.exe maked64.exe symbols.exe filejoin.exe filesplit.exe bmeconv.exe datafile.c dat2inc.c gfxconv.exe gt2nt2.exe pic2chr.exe ins2nt2.exe d642prg.exe prg2d64.exe

clean:
	del *.exe
	del *.spr
	del editor.pal
	del editor.dat
	del editdata.c

editor.dat: bmeconv.exe datafile.exe editor.lbm editfont.lbm
	bmeconv -s -t255 -r254 -h253 editor.lbm editor.spr
	bmeconv -s -t255 -r254 -h253 editfont.lbm editfont.spr
	bmeconv -p editor.lbm editor.pal
	datafile editor.dat filelist.txt

editdata.c: dat2inc.exe editor.dat
	dat2inc editor.dat editdata.c

worlded2.exe: worlded2.cpp editdata.c stb_image_write.c
	g++ worlded2.cpp editdata.c stb_image_write.c libbme.a -oworlded2.exe -w -march=i386 -static-libstdc++ -static-libgcc -lmingw32 -lSDLmain -lSDL -Wl,-Bstatic -lstdc++ -lpthread -Wl,-Bdynamic
	strip worlded2.exe

spred2.exe: spred2.c fileio.c editdata.c
	gcc spred2.c fileio.c editdata.c libbme.a -ospred2.exe -lmingw32 -lSDLmain -lSDL
	strip spred2.exe

pack2.exe: pack2.c
	gcc pack2.c -opack2.exe

pchunk2.exe: pchunk2.c
	gcc pchunk2.c -opchunk2.exe

maked64.exe: maked64.c
	gcc maked64.c -omaked64.exe

symbols.exe: symbols.c
	gcc symbols.c -osymbols.exe

bmeconv.exe: bmeconv.c fileio.c
	gcc bmeconv.c fileio.c -obmeconv.exe

datafile.exe: datafile.c fileio.c
	gcc datafile.c fileio.c -odatafile.exe

dat2inc.exe: dat2inc.c
	gcc dat2inc.c -odat2inc.exe

gfxconv.exe: gfxconv.c fileio.c
	gcc gfxconv.c fileio.c -ogfxconv.exe

pic2chr.exe: pic2chr.c fileio.c
	gcc pic2chr.c fileio.c -opic2chr.exe
	
filejoin.exe: filejoin.c
	gcc filejoin.c -ofilejoin.exe

filesplit.exe: filesplit.c
	gcc filesplit.c -ofilesplit.exe

gt2nt2.exe: gt2nt2.c fileio.c
	gcc gt2nt2.c fileio.c -ogt2nt2.exe

ins2nt2.exe: ins2nt2.c fileio.c
	gcc ins2nt2.c fileio.c -oins2nt2.exe
	
d642prg.exe: d642prg.c
	gcc d642prg.c -od642prg.exe
	
prg2d64.exe: prg2d64.c
	gcc prg2d64.c -oprg2d64.exe
