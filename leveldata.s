LEVEL_SHIP      = 0
LEVEL_SURFACE   = 1
LEVEL_CAVES     = 2
LEVEL_SECURITY  = 3
LEVEL_CITYLEFT  = 4
LEVEL_DEMOEND   = 5

lvlMapColorTbl: dc.b 14                 ;Ship
                dc.b 6                  ;Surface
                dc.b 4                  ;Caves
                dc.b 12                 ;Security
                dc.b 3                  ;City left
                dc.b 3                  ;City right
                dc.b 7                  ;Research
                dc.b 5                  ;Computer

lvlSongTbl:     dc.b SONG_INGAME1       ;Ship
                dc.b SONG_INGAME1       ;Surface
                dc.b SONG_INGAME2       ;Caves
                dc.b SONG_INGAME3       ;Security
                dc.b SONG_INGAME4       ;City left
                dc.b SONG_INGAME4       ;City right
                dc.b SONG_INGAME3       ;Research
                dc.b SONG_INGAME4       ;Computer

lvlNameTblLo:   dc.b <txtShip           ;Ship
                dc.b <txtSurface        ;Surface
                dc.b <txtSurfaceCaves   ;Caves
                dc.b <txtSecurityTower  ;Security
                dc.b <txtCity           ;City left
                dc.b <txtCity           ;City right
                dc.b <txtResearch       ;Research
                dc.b <txtComputer       ;Computer

lvlNameTblHi:   dc.b >txtShip           ;Ship
                dc.b >txtSurface        ;Surface
                dc.b >txtSurfaceCaves   ;Caves
                dc.b >txtSecurityTower  ;Security
                dc.b >txtCity           ;City left
                dc.b >txtCity           ;City right
                dc.b >txtResearch       ;Research
                dc.b >txtComputer       ;Computer

weaponSetStartTbl:
                dc.b weaponSet0-weaponSetData
                dc.b weaponSet1-weaponSetData
                dc.b weaponSet2-weaponSetData
                dc.b weaponSet3-weaponSetData
                dc.b weaponSet4-weaponSetData
                dc.b weaponSet5-weaponSetData
                dc.b weaponSet6-weaponSetData
                dc.b weaponSet7-weaponSetData
                dc.b weaponSet8-weaponSetData
                dc.b weaponSet9-weaponSetData
                dc.b weaponSet10-weaponSetData
                dc.b weaponSet11-weaponSetData
                dc.b weaponSet12-weaponSetData

                if weaponSetEnd - weaponSet0 > $100
                   err
                endif

weaponSetData:
weaponSet0:     dc.b ACT_ROBOTSOLDIER,WPN_BOUNCE
                dc.b ACT_INTROSOLDIER,WPN_BOUNCE
                dc.b ACT_ELITESOLDIER,WPN_LASER+$b0
                dc.b ACT_ELITEFLYINGCRAFT,WPN_SMG+$b0
                dc.b ACT_DROID,WPN_SMG_NOAMMO
                dc.b ACT_CPU,WPN_ARCGUN
                dc.b ACT_LARGEFLY,WPN_FLAMER
                dc.b ACT_LARGESPIDER,WPN_FLAMER
                dc.b ACT_WORKERTANK,WPN_NONE
                dc.b ACT_DRILLTANK,WPN_NONE
                dc.b ACT_LARGEDRILLTANK,WPN_NONE
                dc.b 0

weaponSet1:     dc.b ACT_DROID,WPN_BOUNCE
                dc.b 0

weaponSet2:     dc.b ACT_DROID,WPN_BOUNCE
                dc.b ACT_CEILINGTURRET,WPN_LASER
                dc.b ACT_ROBOTSOLDIER,WPN_LASER
                dc.b 0

weaponSet3:     dc.b ACT_DROID,WPN_LASER+$b0
                dc.b ACT_CEILINGTURRET,WPN_LASER
                dc.b ACT_ROBOTSOLDIER,WPN_LASER
                dc.b ACT_HEAVYSOLDIER,WPN_MISSILE+$b0
                dc.b ACT_ROBOTSPIDER,WPN_SMG_NOAMMO
                dc.b 0

weaponSet4:     dc.b ACT_ROBOTSPIDER,WPN_FLAMER+$90
                dc.b ACT_CEILINGTURRET,WPN_MISSILE+$90
                dc.b ACT_DROID,WPN_FLAMER+$90
                dc.b 0

weaponSet5:     dc.b ACT_ELITEFLYINGCRAFT,WPN_BOUNCE+$50
                dc.b ACT_DROID,WPN_HEAVYPLASMA+$50
                dc.b ACT_ROBOTPRIEST,WPN_BOUNCE+$50
                dc.b ACT_ROBOTSPIDER,WPN_ARCGUN+$50
                dc.b ACT_HEAVYSOLDIER,WPN_HEAVYPLASMA+$50
                dc.b 0

weaponSet6:     dc.b ACT_ELITESOLDIER,WPN_BOUNCE+$b0
                dc.b ACT_DROID,WPN_FLAMER+$b0
                dc.b ACT_CEILINGTURRET,WPN_LASER
                dc.b 0

weaponSet7:     dc.b ACT_SMALLTANK,WPN_FLAMER
                dc.b ACT_DROID,WPN_FLAMER+$b0
                dc.b ACT_CANNONH,WPN_BOUNCE
                dc.b ACT_CANNONV,WPN_BOUNCE
                dc.b 0

weaponSet8:     dc.b ACT_ELITEFLYINGCRAFT,WPN_SMG+$c0
                dc.b ACT_TURRET,WPN_FLAMER
                dc.b ACT_LARGEROBOT,WPN_GRENADE
                dc.b 0

weaponSet9:     dc.b ACT_LARGEROBOT,WPN_GRENADE+$b0
                dc.b ACT_SQUID,WPN_FLAMER+$b0
                dc.b ACT_CEILINGTURRET,WPN_LASER
                dc.b ACT_SMALLTANK,WPN_LASER
                dc.b ACT_CANNONV,WPN_MISSILE+$b0
                dc.b ACT_ROBOTSPIDER,WPN_SMG+$b0
                dc.b ACT_ELITEFLYINGCRAFT,WPN_MISSILE+$b0
                dc.b 0

weaponSet10:    dc.b ACT_LARGESPIDER,WPN_FLAMER+$20
                dc.b ACT_DROID,WPN_BOUNCE+$20
                dc.b ACT_SQUID,WPN_ARCGUN+$20
                dc.b ACT_CANNONV,WPN_MISSILE+$20
                dc.b ACT_LARGEROBOT,WPN_MISSILE+$20
                dc.b ACT_SMALLWALKER,WPN_BOUNCE+$20
                dc.b 0

weaponSet11:    dc.b ACT_ROBOTSPIDER,WPN_ARCGUN
                dc.b ACT_LARGEROBOT,WPN_GRENADE
                dc.b ACT_CANNONV,WPN_MISSILE
                dc.b ACT_CANNONH,WPN_MISSILE
                dc.b ACT_HEAVYSOLDIER,WPN_MISSILE+$b0
                dc.b ACT_ELITEFLYINGCRAFT,WPN_LASER+$b0
                dc.b ACT_SMALLTANK,WPN_LASER

weaponSet12:    dc.b ACT_SMALLWALKER,WPN_LASER
                dc.b ACT_SQUID,WPN_HEAVYPLASMA
                dc.b ACT_ROBOTSPIDER,WPN_ARCGUN
                dc.b ACT_LARGEROBOT,WPN_MISSILE
                dc.b ACT_CANNONV,WPN_MISSILE
                dc.b ACT_CANNONH,WPN_MISSILE
                dc.b ACT_ROBOTPRIEST,WPN_BOUNCE
                dc.b ACT_CPUINVISIBLE,WPN_ARCGUN
                dc.b ACT_CPU,WPN_ARCGUN
                dc.b 0

weaponSetEnd:

                include bg/worldlevel.s
                include bg/worldzone.s