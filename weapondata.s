WPN_SMG         = 0
WPN_BOUNCE      = 1
WPN_LASER       = 2
WPN_FLAMER      = 3
WPN_GRENADE     = 4
WPN_MISSILE     = 5
WPN_ARCGUN      = 6
WPN_HEAVYPLASMA = 7
WPN_WHEELMINE   = 8
WPN_SMG_NOAMMO  = 9
WPN_NONE        = 15

DMG_SMG         = 2
DMG_FLAMER      = 2
DMG_ARCGUN      = 3
DMG_LASER       = 4
DMG_BOUNCE      = 5
DMG_HEAVYPLASMA = 10
DMG_WHEELMINE   = 12
DMG_GRENADE     = 12
DMG_MISSILE     = 16

DMG_FLY         = 1
DMG_SPIDER      = 1
DMG_ARMADILLO   = 1
DMG_ROBOTSPIDER = 1
DMG_WHEEL       = 1
DMG_SPRAY       = 1
DMG_FIGHTER     = 2
DMG_OVERHEAT    = 2
DMG_WORM        = 2
DMG_SLIME       = 2
DMG_LAVA        = 2
DMG_DISTILLER   = 2
DMG_DRILL       = 2
DMG_ROCK        = 2
DMG_LARGEFLY    = 2
DMG_LARGESPIDER = 2
DMG_FIREBALL    = 2
DMG_SLIMEBOSS   = 3
DMG_LARGEDRILL  = 4
DMG_FINALBOSSLASER = 5
DMG_SPIT        = 6
DMG_WORKERPUNCH = 6
DMG_SPIKE       = 8
DMG_MUSHROOM    = 8
DMG_SLIMESHOT   = 8
DMG_WORMBOSS    = 8                             ;Kickback
DMG_BOSSBOMB    = 12
DMG_ROBOTMINE   = 16
DMG_BARREL      = 16
DMG_FINALBOSSBOMB = 16

AMMO_SMG        = 14
AMMO_BOUNCE     = 36
AMMO_LASER      = 30
AMMO_FLAMER     = 15
AMMO_GRENADE    = 96
AMMO_MISSILE    = 127
AMMO_ARCGUN     = 24
AMMO_HEAVYPLASMA = 80
AMMO_WHEELMINE  = $80                           ;Use parts + fuel, not ammo

WPNBIT_SMG      = 1
WPNBIT_BOUNCE   = 2
WPNBIT_LASER    = 4
WPNBIT_FLAMER   = 8
WPNBIT_GRENADE  = 16
WPNBIT_MISSILE  = 32
WPNBIT_ARCGUN   = 64
WPNBIT_HEAVYPLASMA = 128

attackTbl:      dc.b AIM_HORIZONTAL             ;None
                dc.b AIM_UP                     ;Up
                dc.b AIM_DOWN                   ;Down
                dc.b AIM_NONE                   ;Up+Down
                dc.b AIM_HORIZONTAL             ;Left
                dc.b AIM_DIAGONALUP             ;Left+Up
                dc.b AIM_DIAGONALDOWN           ;Left+Down
                dc.b AIM_NONE                   ;Left+Up+Down
                dc.b AIM_HORIZONTAL             ;Right
                dc.b AIM_DIAGONALUP             ;Right+Up
                dc.b AIM_DIAGONALDOWN           ;Right+Down
                dc.b AIM_NONE                   ;Right+Up+Down
                dc.b AIM_NONE                   ;Right+Left
                dc.b AIM_NONE                   ;Right+Left+Up
                dc.b AIM_NONE                   ;Right+Left+Down
                dc.b AIM_NONE                   ;Right+Left+Up+Down

bulletXSpdTbl:  dc.b 0,WD_BULLETSPEEDDIAG,WD_BULLETSPEED,WD_BULLETSPEEDDIAG,0
                dc.b 0,WD_BULLETSPEEDNEGDIAG,WD_BULLETSPEEDNEG,WD_BULLETSPEEDNEGDIAG,0

bulletYSpdTbl:  dc.b WD_BULLETSPEEDNEG,WD_BULLETSPEEDNEGDIAG,0,WD_BULLETSPEEDDIAG,WD_BULLETSPEED
                dc.b WD_BULLETSPEEDNEG,WD_BULLETSPEEDNEGDIAG,0,WD_BULLETSPEEDDIAG,WD_BULLETSPEED

missileAccelXTbl:
                dc.b 0,6,8,6,0
                dc.b 0,-6,-8,-6,0
missileAccelYTbl:
                dc.b -8,-6,0,6,8
                dc.b -8,-6,0,6,8

        ; Weapon data

wpnTblLo:       dc.b <wdSMG
                dc.b <wdBounce
                dc.b <wdLaser
                dc.b <wdFlamer
                dc.b <wdGrenade
                dc.b <wdMissile
                dc.b <wdArcGun
                dc.b <wdHeavyPlasma
                dc.b <wdWheelMine
                dc.b <wdSMGNoAmmo

wpnTblHi:       dc.b >wdSMG
                dc.b >wdBounce
                dc.b >wdLaser
                dc.b >wdFlamer
                dc.b >wdGrenade
                dc.b >wdMissile
                dc.b >wdArcGun
                dc.b >wdHeavyPlasma
                dc.b >wdWheelMine
                dc.b >wdSMGNoAmmo

wdSMGNoAmmo:    dc.b WDB_BULLETDIRFRAME|WDB_FLICKERBULLET|WDB_DIRSIZEREDUCE ;Weapon bits
                dc.b 7                          ;Attack delay
                dc.b 9                          ;Attack delay for enemies
                dc.b ACT_BULLET                 ;Bullet actor type
                dc.b DMG_SMG                    ;Bullet damage
                dc.b 19                         ;Bullet time duration
                dc.b 15*8,15*6,-15*8,-15*6      ;Bullet speed in pixels
                dc.b SFX_SMG                    ;Sound effect
                dc.b 0                          ;Ammo consumption

wdSMG:          dc.b WDB_BULLETDIRFRAME|WDB_FLICKERBULLET|WDB_DIRSIZEREDUCE ;Weapon bits
                dc.b 4                          ;Attack delay
                dc.b 4                          ;Attack delay for enemies
                dc.b ACT_BULLET                 ;Bullet actor type
                dc.b DMG_SMG                    ;Bullet damage
                dc.b 19                         ;Bullet time duration
                dc.b 15*8,15*6,-15*8,-15*6      ;Bullet speed in pixels
                dc.b SFX_SMG                    ;Sound effect
                dc.b AMMO_SMG                   ;Ammo consumption

wdBounce:       dc.b WDB_FLICKERBULLET|WDB_HALFPREMOVE ;Weapon bits
                dc.b 8                          ;Attack delay
                dc.b 11                         ;Attack delay for enemies
                dc.b ACT_BOUNCE                 ;Bullet actor type
                dc.b DMG_BOUNCE                 ;Bullet damage
                dc.b 20                         ;Bullet time duration
                dc.b 14*8,14*6,-14*8,-14*6      ;Bullet speed in pixels
                dc.b SFX_BOUNCE                 ;Sound effect
                dc.b AMMO_BOUNCE                ;Ammo consumption

wdLaser:        dc.b WDB_BULLETDIRFRAME|WDB_FLICKERBULLET|WDB_PREMOVE|WDB_DIRSIZEREDUCE ;Weapon bits
                dc.b 6                          ;Attack delay
                dc.b 7                          ;Attack delay for enemies
                dc.b ACT_LASER                  ;Bullet actor type
                dc.b DMG_LASER                  ;Bullet damage
                dc.b 13                         ;Bullet time duration
                dc.b 10*8,10*6,-10*8,-10*6      ;Bullet speed in pixels
                dc.b SFX_LASER                  ;Sound effect
                dc.b AMMO_LASER                 ;Ammo consumption

wdFlamer:       dc.b WDB_FLICKERBULLET|WDB_HALFPREMOVE ;Weapon bits
                dc.b 3                          ;Attack delay
                dc.b 3                          ;Attack delay for enemies
                dc.b ACT_FLAME                  ;Bullet actor type
                dc.b DMG_FLAMER                 ;Bullet damage
                dc.b 12                         ;Bullet time duration
                dc.b 11*8,11*6,-11*8,-11*6      ;Bullet speed in pixels
                dc.b SFX_FLAMER                 ;Sound effect
                dc.b AMMO_FLAMER                ;Ammo consumption

wdGrenade:      dc.b WDB_GRAVITY                ;Weapon bits
                dc.b 14                         ;Attack delay
                dc.b 16                         ;Attack delay for enemies
                dc.b ACT_GRENADE                ;Bullet actor type
                dc.b DMG_GRENADE                ;Bullet damage
                dc.b 50                         ;Bullet time duration
                dc.b 7*8,7*6,-7*8,-7*6          ;Bullet speed in pixels
                dc.b SFX_GRENADE                ;Sound effect
                dc.b AMMO_GRENADE               ;Ammo consumption

wdMissile:      dc.b WDB_BULLETDIRFRAME|WDB_DIRSIZEREDUCE|WDB_PREMOVE ;Weapon bits
                dc.b 18                         ;Attack delay
                dc.b 20                         ;Attack delay for enemies
                dc.b ACT_MISSILE                ;Bullet actor type
                dc.b DMG_MISSILE                ;Bullet damage
                dc.b 50                         ;Bullet time duration
                dc.b 6*8,6*6,-6*8,-6*6          ;Bullet speed in pixels
                dc.b SFX_MISSILE                ;Sound effect
                dc.b AMMO_MISSILE               ;Ammo consumption

wdArcGun:       dc.b WDB_BULLETDIRFRAME|WDB_FLICKERBULLET|WDB_DIRSIZEREDUCE|WDB_PREMOVE ;Weapon bits
                dc.b 3                          ;Attack delay
                dc.b 3                          ;Attack delay for enemies
                dc.b ACT_ELECTRICITY            ;Bullet actor type
                dc.b DMG_ARCGUN                 ;Bullet damage
                dc.b 4                          ;Bullet time duration
                dc.b 11*8,11*6,-11*8,-11*6      ;Bullet speed in pixels
                dc.b SFX_ARCGUN                 ;Sound effect
                dc.b AMMO_ARCGUN                ;Ammo consumption

wdHeavyPlasma:  dc.b WDB_FLICKERBULLET|WDB_HALFPREMOVE ;Weapon bits
                dc.b 11                         ;Attack delay
                dc.b 15                         ;Attack delay for enemies
                dc.b ACT_HEAVYPLASMA            ;Bullet actor type
                dc.b DMG_HEAVYPLASMA            ;Bullet damage
                dc.b 25                         ;Bullet time duration
                dc.b 14*8,14*6,-14*8,-14*6      ;Bullet speed in pixels
                dc.b SFX_HEAVYPLASMA            ;Sound effect
                dc.b AMMO_HEAVYPLASMA           ;Ammo consumption

wdWheelMine:    dc.b WDB_NOWALLCHECK            ;Weapon bits
                dc.b 14                         ;Attack delay
                dc.b 14                         ;Attack delay for enemies
                dc.b ACT_WHEELMINE              ;Bullet actor type
                dc.b DMG_WHEELMINE              ;Bullet damage
                dc.b 25                         ;Bullet time duration
                dc.b 0,0,0,0                    ;Bullet speed in pixels
                dc.b SFX_WHEELMINE              ;Sound effect
                dc.b AMMO_WHEELMINE             ;Ammo (parts) consumption
