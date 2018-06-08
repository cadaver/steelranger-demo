SHOW_SCREENSCROLL_TIME  = 0
SHOW_COLORSCROLL_TIME   = 0
SHOW_ADDACTOR_TIME      = 0
SHOW_UPDATEACTOR_TIME   = 0
SHOW_DRAWACTOR_TIME     = 0
SHOW_INTERPOLATEACTOR_TIME = 0
SHOW_OBJECTSCAN_TIME    = 0
SHOW_LINECHECK_TIME     = 0
SHOW_SPRITESORT_TIME    = 0
SHOW_PLAYROUTINE_TIME   = 0
SHOW_CHARANIM_TIME      = 0
SHOW_SPRITEIRQ_TIME     = 0
SHOW_NUM_ACTORS         = 0
SHOW_NUM_SPRITES        = 0
SHOW_HEALTHRECHARGE     = 0 ;Note: destroys parts proper value!
CHECK_RESPAWN_OVERFLOW  = 0 ;Disable only after testing the whole game and making no more modifications
CHECK_GLOBALACT_NOTFOUND = 1 ;Same as above
CHECK_ACTINDEX          = 0

STARTPOS_CHEAT          = 0
HEALTH_CHEAT            = 0
FUEL_CHEAT              = 0
WEAPON_CHEAT            = 0
PARTS_CHEAT             = 0
ANALYZER_CHEAT          = 0
WHEEL_CHEAT             = 0
HIGHJUMP_CHEAT          = 0
HEATSHIELD_CHEAT        = 0
JETPACK_CHEAT           = 0
HALFUPGRADE_CHEAT       = 0
UPGRADE_CHEAT           = 0
SECURITY_CHEAT          = 0
PLOTBIT_CHEAT           = 0 ;$80 for SROfficer saved, $1000 for bomb defused, $8000 for Grunt saved
MAP_CHEAT               = 0
BOSSHEALTH_CHEAT        = 0
SKIP_CHARACTER          = 0
SKIP_VR                 = 0
SKIP_ESCAPE             = 0
TEST_ENDING             = 0 ;Use 1 or 2 to see either end first, startpos cheat also needed

DEATH_KEY               = 0
DAMAGE_KEY              = 0

        ; Test startlocations

TEST_WORLD_STARTX       = 4   ;Surface, no intro
TEST_WORLD_STARTY       = 14
TEST_PLAYER_STARTX      = 4
TEST_PLAYER_STARTY      = 19

;TEST_WORLD_STARTX       = 20    ;First machine encounter
;TEST_WORLD_STARTY       = 14
;TEST_PLAYER_STARTX      = 2
;TEST_PLAYER_STARTY      = 10

;TEST_WORLD_STARTX       = 27    ;Machine city
;TEST_WORLD_STARTY       = 14
;TEST_PLAYER_STARTX      = 0
;TEST_PLAYER_STARTY      = 7

;TEST_WORLD_STARTX       = 37    ;Upgrade install room in city
;TEST_WORLD_STARTY       = 13
;TEST_PLAYER_STARTX      = 4
;TEST_PLAYER_STARTY      = 7

        ; Main part

                include memory.s
                include loadsym.s
                include script.s

                org loaderCodeEnd

randomAreaStart:
                include raster.s
                include sound.s
                include input.s
                include screen.s
                include sprite.s
                include math.s
                include file.s
                include actor.s
                include physics.s
                include player.s
                include weapon.s
                include bullet.s
                include enemy.s
                include item.s
                include panel.s
                include plot.s
                include level.s

randomAreaEnd:

                include aligneddata.s
                include var.s
                include paneldata.s
                include itemdata.s
                include actordata.s
                include leveldata.s
                include weapondata.s
                include sounddata.s
                include text.s

        ; Preloaded spritefiles that will never be purged

sprCommon:      incbin sprcommon.dat
sprPlayer:      incbin sprplayer.dat

        ; Dynamic allocation area begin

fileAreaStart:
                include init.s