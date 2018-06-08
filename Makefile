all: steelranger_demo.d64

clean:
	del *.bin
	del *.prg
	del *.pak
	del *.tbl
	del *sym.s
	del *.d64

steelranger_demo.d64: steelranger.seq boot.prg loader.prg main.pak \
	music00.pak music01.pak music02.pak music03.pak music04.pak \
	level00.pak level01.pak level02.pak level03.pak level04.pak \
	charset00.pak charset01.pak charset02.pak charset03.pak \
	sprcrew.pak sprenemies0.pak sprenemies1.pak sprenemies2.pak sprenemies3.pak sprboss0.pak \
	script00.pak script01.pak script02.pak script03.pak script09.pak script11.pak script17.pak script19.pak script20.pak script21.pak \
	title.pak options.bin emptysave.bin
	maked64 steelranger_demo.d64 steelranger.seq STEELRANGER_DEMO__SD_2A 10 dir

loader.prg: kernal.s loader.s loadsym.txt ldepacksym.txt ldepack.s loaderstack.s macros.s memory.s
	dasm ldepack.s -oloader.prg -sldepack.tbl -f3
	symbols ldepack.tbl ldepacksym.s ldepacksym.txt
	dasm loader.s -oloader.bin -sloader.tbl -f3
	symbols loader.tbl loadsym.s loadsym.txt
	dasm loaderstack.s -oloaderstack.bin -f3
	pack2 loader.bin loader.pak
	dasm ldepack.s -oloader.prg -sldepack.tbl -f3
	symbols ldepack.tbl ldepacksym.s ldepacksym.txt

boot.prg: boot.s loader.prg
	dasm boot.s -oboot.prg

main.pak: loadsym.s ldepacksym.s memory.s script.s main.s raster.s screen.s sound.s input.s level.s actor.s physics.s \
	player.s weapon.s bullet.s enemy.s math.s file.s panel.s sprite.s init.s item.s plot.s loadpic.s \
	actordata.s paneldata.s sounddata.s weapondata.s itemdata.s leveldata.s aligneddata.s var.s text.s \
	sfx/smg.sfx sfx/bounce.sfx sfx/laser.sfx sfx/flamer.sfx sfx/missile.sfx sfx/grenade.sfx sfx/arcgun.sfx sfx/heavyplasma.sfx \
	sfx/explosion.sfx sfx/mine.sfx sfx/splash.sfx sfx/select.sfx sfx/pickup.sfx sfx/operate.sfx sfx/lift.sfx sfx/radio.sfx sfx/radiomachines.sfx \
	sfx/damage.sfx sfx/death.sfx sfx/treemine.sfx sfx/footstep.sfx sfx/jump.sfx sfx/wheelbegin.sfx sfx/wheelend.sfx sfx/jetpack.sfx \
	bg/worldinfo.s bg/worldlevel.s bg/worldzone.s bg/scorescr.chr pics/loadpic_psytronik.iff spr/common.spr spr/player.spr
	filesplit spr/common.spr sprcommon.hdr 2 1
	filesplit spr/common.spr sprcommon.dat 3
	filesplit spr/player.spr sprplayer.hdr 2 1
	filesplit spr/player.spr sprplayer.dat 3
	dasm main.s -omain.bin -smain.tbl -f3
	symbols main.tbl mainsym.s
	symbols main.tbl >pagecross.txt
	gfxconv pics/loadpic_psytronik.iff loadpic.dat -r -b0 -o -nc -ns -p
	gfxconv pics/loadpic_psytronik.iff loadpicscr.dat -r -b0 -o -nc -nb -p
	gfxconv pics/loadpic_psytronik.iff loadpiccol.dat -r -b0 -o -nb -ns -p
	dasm loadpic.s -oloadpic.bin -f3
	pack2 loadpic.bin main_1.pak
	pack2 loadpic.dat main_2.pak
	pack2 main.bin main_3.pak
	filejoin main_1.pak+main_2.pak+main_3.pak main.pak

sfx/smg.sfx: sfx/smg.ins
	ins2nt2 sfx/smg.ins sfx/smg.sfx

sfx/bounce.sfx: sfx/bounce.ins
	ins2nt2 sfx/bounce.ins sfx/bounce.sfx

sfx/laser.sfx: sfx/laser.ins
	ins2nt2 sfx/laser.ins sfx/laser.sfx

sfx/flamer.sfx: sfx/flamer.ins
	ins2nt2 sfx/flamer.ins sfx/flamer.sfx

sfx/missile.sfx: sfx/missile.ins
	ins2nt2 sfx/missile.ins sfx/missile.sfx

sfx/grenade.sfx: sfx/grenade.ins
	ins2nt2 sfx/grenade.ins sfx/grenade.sfx

sfx/arcgun.sfx: sfx/arcgun.ins
	ins2nt2 sfx/arcgun.ins sfx/arcgun.sfx

sfx/heavyplasma.sfx: sfx/heavyplasma.ins
	ins2nt2 sfx/heavyplasma.ins sfx/heavyplasma.sfx

sfx/explosion.sfx: sfx/explosion.ins
	ins2nt2 sfx/explosion.ins sfx/explosion.sfx

sfx/mine.sfx: sfx/mine.ins
	ins2nt2 sfx/mine.ins sfx/mine.sfx

sfx/splash.sfx: sfx/splash.ins
	ins2nt2 sfx/splash.ins sfx/splash.sfx

sfx/select.sfx: sfx/select.ins
	ins2nt2 sfx/select.ins sfx/select.sfx

sfx/pickup.sfx: sfx/pickup.ins
	ins2nt2 sfx/pickup.ins sfx/pickup.sfx

sfx/operate.sfx: sfx/operate.ins
	ins2nt2 sfx/operate.ins sfx/operate.sfx

sfx/lift.sfx: sfx/lift.ins
	ins2nt2 sfx/lift.ins sfx/lift.sfx

sfx/radio.sfx: sfx/radio.ins
	ins2nt2 sfx/radio.ins sfx/radio.sfx

sfx/radiomachines.sfx: sfx/radiomachines.ins
	ins2nt2 sfx/radiomachines.ins sfx/radiomachines.sfx

sfx/damage.sfx: sfx/damage.ins
	ins2nt2 sfx/damage.ins sfx/damage.sfx

sfx/death.sfx: sfx/death.ins
	ins2nt2 sfx/death.ins sfx/death.sfx

sfx/treemine.sfx: sfx/treemine.ins
	ins2nt2 sfx/treemine.ins sfx/treemine.sfx

sfx/footstep.sfx: sfx/footstep.ins
	ins2nt2 sfx/footstep.ins sfx/footstep.sfx

sfx/jump.sfx: sfx/jump.ins
	ins2nt2 sfx/jump.ins sfx/jump.sfx

sfx/wheelbegin.sfx: sfx/wheelbegin.ins
	ins2nt2 sfx/wheelbegin.ins sfx/wheelbegin.sfx

sfx/wheelend.sfx: sfx/wheelend.ins
	ins2nt2 sfx/wheelend.ins sfx/wheelend.sfx

sfx/jetpack.sfx: sfx/jetpack.ins
	ins2nt2 sfx/jetpack.ins sfx/jetpack.sfx

music00.pak: music/srmusic.d64
	d642prg music/srmusic.d64 title.bin music00.prg
	exomizer208 level -M255 -c -f -omusic00.pak music00.prg

music01.pak: music/srmusic.d64
	d642prg music/srmusic.d64 ingame1.bin music01.prg
	exomizer208 level -M255 -c -f -omusic01.pak music01.prg

music02.pak: music/srmusic.d64
	d642prg music/srmusic.d64 ingame2.bin music02.prg
	exomizer208 level -M255 -c -f -omusic02.pak music02.prg

music03.pak: music/srmusic.d64
	d642prg music/srmusic.d64 ingame3.bin music03.prg
	exomizer208 level -M255 -c -f -omusic03.pak music03.prg

music04.pak: music/srmusic.d64
	d642prg music/srmusic.d64 ingame4.bin music04.prg
	exomizer208 level -M255 -c -f -omusic04.pak music04.prg

level00.pak: bg/world00.map
	pchunk2 bg/world00.map level00.pak

level01.pak: bg/world01.map
	pchunk2 bg/world01.map level01.pak

level02.pak: bg/world02.map
	pchunk2 bg/world02.map level02.pak

level03.pak: bg/world03.map
	pchunk2 bg/world03.map level03.pak

level04.pak: bg/world04.map
	pchunk2 bg/world04.map level04.pak

charset00.pak: charset00.s mainsym.s memory.s bg/world00.blk bg/world00.bli bg/world00.chr bg/world00.chc bg/world00.oba
	dasm charset00.s -ocharset00.bin -f3
	pack2 charset00.bin charset00.pak

charset01.pak: charset01.s memory.s bg/world01.blk bg/world01.bli bg/world01.chr bg/world01.chc bg/world01.oba
	dasm charset01.s -ocharset01.bin -f3
	pack2 charset01.bin charset01.pak

charset02.pak: charset02.s memory.s bg/world02.blk bg/world02.bli bg/world02.chr bg/world02.chc bg/world02.oba
	dasm charset02.s -ocharset02.bin -f3
	pack2 charset02.bin charset02.pak

charset03.pak: charset03.s memory.s bg/world03.blk bg/world03.bli bg/world03.chr bg/world03.chc bg/world03.oba
	dasm charset03.s -ocharset03.bin -f3
	pack2 charset03.bin charset03.pak

sprcrew.pak: spr/crew.spr
	pchunk2 spr/crew.spr sprcrew.pak

sprenemies0.pak: spr/enemies0.spr
	pchunk2 spr/enemies0.spr sprenemies0.pak

sprenemies1.pak: spr/enemies1.spr
	pchunk2 spr/enemies1.spr sprenemies1.pak
	
sprenemies2.pak: spr/enemies2.spr
	pchunk2 spr/enemies2.spr sprenemies2.pak

sprenemies3.pak: spr/enemies3.spr
	pchunk2 spr/enemies3.spr sprenemies3.pak

sprboss0.pak: spr/boss0.spr
	pchunk2 spr/boss0.spr sprboss0.pak

script00.pak: script00.s mainsym.s macros.s memory.s
	dasm script00.s -oscript00.bin -f3
	pchunk2 script00.bin script00.pak

script01.pak: script01.s mainsym.s macros.s memory.s
	dasm script01.s -oscript01.bin -f3
	pchunk2 script01.bin script01.pak
	
script02.pak: script02.s mainsym.s macros.s memory.s
	dasm script02.s -oscript02.bin -f3
	pchunk2 script02.bin script02.pak
	
script03.pak: script03.s mainsym.s macros.s memory.s
	dasm script03.s -oscript03.bin -f3
	pchunk2 script03.bin script03.pak

script09.pak: script09.s mainsym.s macros.s memory.s
	dasm script09.s -oscript09.bin -f3
	pchunk2 script09.bin script09.pak

script11.pak: script11.s mainsym.s macros.s memory.s
	dasm script11.s -oscript11.bin -f3
	pchunk2 script11.bin script11.pak

script17.pak: script17.s mainsym.s macros.s memory.s bg/worldglobalact.s
	dasm script17.s -oscript17.bin -f3
	pchunk2 script17.bin script17.pak

script19.pak: script19.s mainsym.s macros.s memory.s
	dasm script19.s -oscript19.bin -f3
	pchunk2 script19.bin script19.pak

script20.pak: script20.s mainsym.s macros.s memory.s
	dasm script20.s -oscript20.bin -f3
	pchunk2 script20.bin script20.pak

script21.pak: script21.s mainsym.s macros.s memory.s
	dasm script21.s -oscript21.bin -f3
	pchunk2 script21.bin script21.pak

title.pak: pics/logo.iff title.s mainsym.s memory.s bg/scorescr.chr
	pic2chr pics/logo.iff title.chr /m6 /n14 /c /s /f96 /y6
	pic2chr pics/logo.iff title.scr /m6 /n14 /c /t /f96 /y6
	dasm title.s -otitle.bin -f3
	pack2 title.bin title.pak

options.bin: options.s memory.s
	dasm options.s -ooptions.bin -f3

emptysave.bin: emptysave.s mainsym.s
	dasm emptysave.s -oemptysave.bin -f3
