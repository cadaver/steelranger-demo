SFX_FOOTSTEP    = $01
SFX_JUMP        = $02
SFX_JETPACK     = $03
SFX_LIFT        = $04
SFX_SELECT      = $05
SFX_OPERATE     = $06
SFX_PICKUP      = $07
SFX_WHEELBEGIN  = $08
SFX_WHEELEND    = $09
SFX_SPLASH      = $0a
SFX_DAMAGE      = $0b
SFX_FLAMER      = $0c
SFX_SMG         = $0d
SFX_WHEELMINE   = $0e
SFX_TREEMINE    = $0f
SFX_LASER       = $10
SFX_BOUNCE      = $11
SFX_ARCGUN      = $12
SFX_GRENADE     = $13
SFX_DEATH       = $14
SFX_HEAVYPLASMA = $15
SFX_MISSILE     = $16
SFX_EXPLOSION   = $17
SFX_RADIO       = $18
SFX_RADIOMACHINES = $19

        ; Sound effect data

sfxTblLo:       dc.b <sfxFootstep
                dc.b <sfxJump
                dc.b <sfxJetpack
                dc.b <sfxLift
                dc.b <sfxSelect
                dc.b <sfxOperate
                dc.b <sfxPickup
                dc.b <sfxWheelBegin
                dc.b <sfxWheelEnd
                dc.b <sfxSplash
                dc.b <sfxDamage
                dc.b <sfxFlamer
                dc.b <sfxSMG
                dc.b <sfxWheelMine
                dc.b <sfxTreeMine
                dc.b <sfxLaser
                dc.b <sfxBounce
                dc.b <sfxArcGun
                dc.b <sfxGrenade
                dc.b <sfxDeath
                dc.b <sfxHeavyPlasma
                dc.b <sfxMissile
                dc.b <sfxExplosion
                dc.b <sfxRadio
                dc.b <sfxRadioMachines

sfxTblHi:       dc.b >sfxFootstep
                dc.b >sfxJump
                dc.b >sfxJetpack
                dc.b >sfxLift
                dc.b >sfxSelect
                dc.b >sfxOperate
                dc.b >sfxPickup
                dc.b >sfxWheelBegin
                dc.b >sfxWheelEnd
                dc.b >sfxSplash
                dc.b >sfxDamage
                dc.b >sfxFlamer
                dc.b >sfxSMG
                dc.b >sfxWheelMine
                dc.b >sfxTreeMine
                dc.b >sfxLaser
                dc.b >sfxBounce
                dc.b >sfxArcGun
                dc.b >sfxGrenade
                dc.b >sfxDeath
                dc.b >sfxHeavyPlasma
                dc.b >sfxMissile
                dc.b >sfxExplosion
                dc.b >sfxRadio
                dc.b >sfxRadioMachines

sfxFootstep:    include sfx/footstep.sfx
sfxJump:        include sfx/jump.sfx
sfxJetpack:     include sfx/jetpack.sfx
sfxLift:        include sfx/lift.sfx
sfxSelect:      include sfx/select.sfx
sfxOperate:     include sfx/operate.sfx
sfxPickup:      include sfx/pickup.sfx
sfxWheelBegin:  include sfx/wheelbegin.sfx
sfxWheelEnd:    include sfx/wheelend.sfx
sfxSplash:      include sfx/splash.sfx
sfxDamage:      include sfx/damage.sfx
sfxFlamer:      include sfx/flamer.sfx
sfxSMG:         include sfx/smg.sfx
sfxWheelMine:   include sfx/mine.sfx
sfxTreeMine:    include sfx/treemine.sfx
sfxLaser:       include sfx/laser.sfx
sfxBounce:      include sfx/bounce.sfx
sfxArcGun:      include sfx/arcgun.sfx
sfxGrenade:     include sfx/grenade.sfx
sfxDeath:       include sfx/death.sfx
sfxHeavyPlasma: include sfx/heavyplasma.sfx
sfxMissile:     include sfx/missile.sfx
sfxExplosion:   include sfx/explosion.sfx
sfxRadio:       include sfx/radio.sfx
sfxRadioMachines:
                include sfx/radiomachines.sfx