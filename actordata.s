NPC_JROFFICER   = 0
NPC_PILOT       = 1
NPC_SROFFICER   = 2
NPC_GRUNT       = 3
NPC_MEDIC       = 4

ACT_NONE         = 0
ACT_PLAYER       = 1
ACT_ROBOTSOLDIER = 2
ACT_INTROSOLDIER = 3
ACT_ELITESOLDIER = 4
ACT_HEAVYSOLDIER = 5
ACT_LARGEROBOT   = 6
ACT_ROBOTPRIEST  = 7
ACT_LARGETANK    = 8
ACT_LARGEDRILLTANK = 9
ACT_LARGEWORM    = 10
ACT_SLIMEBOSS    = 11
ACT_JROFFICER_NOARMOR = 12
ACT_JROFFICER    = 13
ACT_PILOT       = 14
ACT_SROFFICER   = 15
ACT_GRUNT_NOARMOR = 16
ACT_GRUNT       = 17
ACT_MEDIC       = 18
ACT_JROFFICER_TRAPPED = 19
ACT_PILOT_SITTING = 20
ACT_SROFFICER_WOUNDED = 21
ACT_GRUNT_WOUNDED = 22
ACT_GRUNT_WHEEL = 23
ACT_PLAYERWHEEL = 24
ACT_PLAYER_NOARMOR = 25
ACT_ITEM        = 26
ACT_OBJECTMARKER = 27
ACT_LIFT         = 28
ACT_FLY          = 29
ACT_SPITFLY      = 30
ACT_SPITBALL     = 31
ACT_ARMADILLO    = 32
ACT_TREEMINE     = 33
ACT_CEILINGMINE  = 34
ACT_FLOORMINE    = 35
ACT_SPIKE        = 36
ACT_SPIDER       = 37
ACT_SPITSPIDER   = 38
ACT_TURRET       = 39
ACT_CEILINGTURRET = 40
ACT_DROID        = 41
ACT_ROBOTMINE    = 42
ACT_FLYINGCRAFT  = 43
ACT_ELITEFLYINGCRAFT = 44
ACT_ROBOTSPIDER  = 45
ACT_SPEECHBUBBLE = 46
ACT_CREATOR      = 47
ACT_METALPIECE   = 48
ACT_SMALLWALKER  = 49
ACT_BARREL       = 50
ACT_SMALLTANK    = 51
ACT_DRILLTANK    = 52
ACT_DRILLMELEEHIT = 53
ACT_WORKERTANK   = 54
ACT_WORKERMELEEHIT = 55
ACT_CANNONH      = 56
ACT_CANNONV      = 57
ACT_CPUINVISIBLE = 58
ACT_CPU          = 59
ACT_SQUID        = 60
ACT_LARGEDRILLMELEEHIT = 61
ACT_SLIME        = 62
ACT_SLIMELAUNCHER = 63
ACT_SLIMESHOT    = 64
ACT_WORMHEAD     = 65
ACT_WORMPART     = 66
ACT_WORMBOMB     = 67
ACT_MUSHROOMINVISIBLE = 68
ACT_MUSHROOM     = 69
ACT_ROCKINVISIBLE = 70
ACT_ROCK         = 71
ACT_FIREBALLSPAWNER = 72
ACT_FIREBALL     = 73
ACT_LARGEFLY     = 74
ACT_LARGESPIDER  = 75
ACT_ENEMYCHUNK   = 76
ACT_DECONTAMINATOR = 77
ACT_SPRAY        = 78
ACT_SCREENSAVER  = 79
ACT_DROIDBOSSINVISIBLE = 80
ACT_DROIDBOSS    = 81
ACT_BOMBBOSSINVISIBLE = 82
ACT_BOMBBOSS     = 83
ACT_FIGHTERBOSSINVISIBLE = 84
ACT_FIGHTERBOSS  = 85
ACT_BRIDGEEXPLOSION = 86
ACT_DISTILLERBOSSINVISIBLE = 87
ACT_DISTILLERBOSS = 88
ACT_FINALBOSSINVISIBLE = 89
ACT_FINALBOSS    = 90
ACT_FINALBOSSBOMB = 91
ACT_FINALBOSSBOMBEXPLOSION = 92
ACT_FINALBOSSBRAIN = 93
ACT_FINALBOSSLASER = 94
ACT_WORMBOSS     = 95
ACT_WORMBOSSHEAD = 96
ACT_WORMBOSSPART = 97
ACT_WORMBOSSBOMB = 98
ACT_SPIDERBOSS   = 99
ACT_BULLET       = 100
ACT_BOUNCE       = 101
ACT_LASER        = 102
ACT_FLAME        = 103
ACT_ELECTRICITY  = 104
ACT_GRENADE      = 105
ACT_MISSILE      = 106
ACT_HEAVYPLASMA  = 107
ACT_SMOKETRAIL   = 108
ACT_EXPLOSION    = 109
ACT_WHEELMINE    = 110
ACT_SMALLSPLASH  = 111
ACT_LARGESPLASH  = 112
ACT_RANGERSUIT   = 113
ACT_ESCAPEFIGHTERJET = 114
ACT_SMALLFIGHTERJET = 115

ACT_FIRSTNPC    = ACT_JROFFICER_NOARMOR
ACT_LASTNPC     = ACT_GRUNT_WHEEL
ACT_LASTBOTTOMADJUST = ACT_MEDIC

HP_FLY          = 2
HP_BARREL       = 2
HP_BARRELONFIRE = 4
HP_SPITFLY      = 4
HP_SPIDER       = 4
HP_SPITSPIDER   = 6
HP_ARMADILLO    = 6
HP_ROBOTSPIDER  = 6
HP_MINE         = 8
HP_ROBOTMINE    = 8
HP_ROCK         = 8
HP_SLIME        = 8
HP_DROID        = 10
HP_ROBOTSOLDIER = 10
HP_FLYINGCRAFT  = 10
HP_SMALLWALKER  = 10
HP_LARGEFLY     = 10
HP_MUSHROOM     = 12
HP_ELITESOLDIER = 12
HP_LARGESPIDER  = 14
HP_SMALLTANK    = 14
HP_ELITEFLYINGCRAFT = 14
HP_TURRET       = 16
HP_HEAVYSOLDIER = 16
HP_SQUID        = 20
HP_CANNON       = 20
HP_CPU          = 20
HP_SLIMELAUNCHER = 24
HP_LARGEROBOT   = 24    ;Heavyenemy
HP_ROBOTPRIEST  = 32    ;-||-
HP_LARGEDRILL   = 32    ;-||-
HP_LARGEWORM    = 38    ;-||-
HP_LARGETANK    = 42    ;-||-
HP_PLAYER       = 48

                if BOSSHEALTH_CHEAT > 0
HP_BOSS         = 1
                else
HP_BOSS         = 180
                endif

HEAVYENEMY_MODIFY  = 6

SMALLBOSS_MODIFY  = 10
MEDIUMBOSS_MODIFY = 8
LARGEBOSS_MODIFY  = 6
STRONGLARGEBOSS_MODIFY = 5
ALMOSTSUPERBOSS_MODIFY = 4
SUPERBOSS_MODIFY  = 3

        ; Human Y-size reduce table based on animation

humanSizeModTbl:dc.b 0, 0,0,0,0,0,0,0,0, -1,-1,-1, 0,0, -3,-7, 0, 0,-1,-2,-1,0,-1,-2,-1, 0,-3,-8

        ; Human actor upper part framenumbers

humanUpperFrTbl:dc.b 1, 0,1,1,2,2,1,1,0, 0,0,0, 0,0, 0,0, 3, 15,14,13,14,15,16,17,16, 10,11,12, 4,5,6,7,8,9
                dc.b $80+1, $80+0,$80+1,$80+1,$80+2,$80+2,$80+1,$80+1,$80+0, $80+0,$80+0,$80+0, $80+0,$80+0, $80+0,$80+0, 3, 15,14,13,14,15,16,17,16, $80+10,$80+11,$80+12, $80+4,$80+5,$80+6,$80+7,$80+8,$80+9
               ;68
                dc.b 0,1,2,3,4,5
                dc.b $80+0,$80+1,$80+2,$80+3,$80+4,$80+5

        ; Human actor lower part framenumbers

humanLowerFrTbl:dc.b $80+0, $80+1,$80+2,$80+3,$80+4,$80+5,$80+6,$80+7,$80+8, $80+11,$80+12,$80+13, $80+21,$80+22, $80+9,$80+10, 18, 18,17,16,17,18,19,20,19, $80+11,$80+14,$80+15
                dc.b 0, 1,2,3,4,5,6,7,8, 11,12,13, 21,22, 9,10, 18, 18,17,16,17,18,19,20,19, 11,14,15
               ;56
                dc.b 0,1,2,3

        ; Explosion generator tables

EXPL_FF_7F      = 0
EXPL_7F_7F_UP   = 1
EXPL_7F_7F      = 2
EXPL_FF_FF_UP   = 3
EXPL_7F_1FF_UP  = 4
EXPL_1FF_FF_UP  = 5
EXPL_FF_FF      = 6
EXPL_1FF_FF_HEAVY_UP = 7

explProbability:dc.b $7f,$4f,$4f,$7f,$7f,$7f,$7f,$ff
explXRangeHi:   dc.b $01,$00,$00,$01,$00,$03,$01,$03
explYRangeHi:   dc.b $00,$00,$00,$01,$03,$01,$01,$01
explXAddLo:     dc.b 0,64,64,0,64,0,0,0
explXAddHi:     dc.b -1,-1,-1,-1,-1,-2,-1,-2
explYAddLo:     dc.b 64,0,0,0,0,0,0,0
explYAddHi:     dc.b -1,-1,0,-2,-4,-2,-1,-2

        ; Related actor table for precaching (e.g. actors spawned by enemy)

relatedActorTbl:dc.b 0

        ; Difficulty tables

regenDiffTbl:   dc.b 5
                dc.b 7
                dc.b 9
                dc.b 11

damageDiffTbl:  dc.b 5
                dc.b 6
                dc.b 8
                dc.b 12

enemyAmmoPickupDiffTbl:
                dc.b MAX_AMMO*$10/3+1
                dc.b MAX_AMMO*$10/4
                dc.b MAX_AMMO*$10/6+1
                dc.b MAX_AMMO*$10/8

healthDropTbl:  dc.b $04,$05,$06,$07,$07,$08 ;Must be adjacent, 8 is last entry in healthDropTbl
healthUpgradeTbl:
                dc.b 8,6,4,4

wpnDamageUpgradeTbl:
                dc.b 8,10,12,12

        ; Enemy scoring table

wpnScoreTbl:    dc.b 0,2,2,2,4,4,4,6,0,0
scoreTbl:       dc.w 10,15,20,25,35,50,75,85,100,115,125,135,150,175,200,225,250,300,325,350,400,500
scoreTblEnd:

MAX_SCORE_INDEX = (scoreTblEnd - scoreTbl - 2)


        ; Player Y-scroll speed adjust table

yScrollSpdTbl:  dc.b -32,-30,-29,-27,-25,-24,-22,-21,-19,-17,-16,-14,-13,-11,-10,-9,-8,-7,-6,-5,-4,-3,-2,-1
                dc.b 0,1,2,3,4,5,6,7,8,9,10,11,13,14,16,17,19,21,22,24,25,27,29,30,32

        ; Actor display data

adDrillMeleeHit = $0000
adWorkerMeleeHit = $0000
adLargeDrillMeleeHit = $0000
adCPUInvisible = $0000
adLargeWorm     = $0000
adMushroomInvisible = $0000
adRockInvisible = $0000
adFireballSpawner = $0000
adDecontaminator = $0000
adScreenSaver = $0000
adDroidBossInvisible = $0000
adFighterBossInvisible = $0000
adBridgeExplosion = $0000
adDistillerBossInvisible = $0000
adFinalBossInvisible = $0000
adWormBoss      = $0000

adFly           = USESCRIPT+EP_ADFly
adSpitBall      = USESCRIPT+EP_ADSpitBall
adArmadillo     = USESCRIPT+EP_ADArmadillo
adTreeMine      = USESCRIPT+EP_ADTreeMine
adCeilingMine   = USESCRIPT+EP_ADCeilingMine
adFloorMine     = USESCRIPT+EP_ADFloorMine
adSpike         = USESCRIPT+EP_ADSpike
adSpider        = USESCRIPT+EP_ADSpider
adRobotSoldier  = USESCRIPT+EP_ADRobotSoldier
adHeavySoldier  = USESCRIPT+EP_ADHeavySoldier
adTurret        = USESCRIPT+EP_ADTurret
adCeilingTurret = USESCRIPT+EP_ADCeilingTurret
adDroid         = USESCRIPT+EP_ADDroid
adRobotMine     = USESCRIPT+EP_ADRobotMine
adFlyingCraft   = USESCRIPT+EP_ADFlyingCraft
adSquid         = USESCRIPT+EP_ADSquid
adCreator       = USESCRIPT+EP_ADCreator
adLift          = USESCRIPT+EP_ADLift
adRobotSpider   = USESCRIPT ;Entrypoint not in preview
adSmallWalker   = USESCRIPT+EP_ADSmallWalker
adLargeRobot    = USESCRIPT ;Entrypoint not in preview
adBarrel        = USESCRIPT ;Entrypoint not in preview
adSmallTank     = USESCRIPT ;Entrypoint not in preview
adDrillTank     = USESCRIPT ;Entrypoint not in preview
adWorkerTank    = USESCRIPT ;Entrypoint not in preview
adRobotPriest   = USESCRIPT ;Entrypoint not in preview
adLargeTank     = USESCRIPT ;Entrypoint not in preview
adLargeDrillTank = USESCRIPT ;Entrypoint not in preview
adCannonH       = USESCRIPT ;Entrypoint not in preview
adCannonV       = USESCRIPT ;Entrypoint not in preview
adCPU           = USESCRIPT ;Entrypoint not in preview
adSlime         = USESCRIPT ;Entrypoint not in preview
adSlimeLauncher = USESCRIPT ;Entrypoint not in preview
adSlimeShot     = USESCRIPT ;Entrypoint not in preview
adWormHead      = USESCRIPT ;Entrypoint not in preview
adWormPart      = USESCRIPT ;Entrypoint not in preview
adWormBomb      = USESCRIPT ;Entrypoint not in preview
adMushroom      = USESCRIPT ;Entrypoint not in preview
adRock          = USESCRIPT ;Entrypoint not in preview
adFireball      = USESCRIPT ;Entrypoint not in preview
adLargeFly      = USESCRIPT ;Entrypoint not in preview
adLargeSpider   = USESCRIPT ;Entrypoint not in preview
adEnemyChunk    = USESCRIPT ;Entrypoint not in preview
adDroidBoss     = USESCRIPT+EP_ADDroidBoss
adFighterBoss   = USESCRIPT ;Entrypoint not in preview
adDistillerBoss = USESCRIPT ;Entrypoint not in preview
adSlimeBoss     = USESCRIPT ;Entrypoint not in preview
adFinalBoss     = USESCRIPT ;Entrypoint not in preview
adFinalBossBomb = USESCRIPT ;Entrypoint not in preview
adFinalBossBrain = USESCRIPT ;Entrypoint not in preview
adFinalBossLaser = USESCRIPT ;Entrypoint not in preview
adWormBossHead  = USESCRIPT ;Entrypoint not in preview
adWormBossPart  = USESCRIPT ;Entrypoint not in preview
adWormBossBomb  = USESCRIPT ;Entrypoint not in preview
adSpiderBoss    = USESCRIPT ;Entrypoint not in preview
adRangerSuit    = USESCRIPT ;Entrypoint not in preview
adSROfficerWounded = USESCRIPT+EP_ADSROfficerWounded
adGruntWounded = USESCRIPT ;Entrypoint not in preview
adSmallFighterJet = USESCRIPT ;Entrypoint not in preview

actDispTblLo:   dc.b <adPlayer
                dc.b <adRobotSoldier
                dc.b <adRobotSoldier
                dc.b <adRobotSoldier
                dc.b <adHeavySoldier
                dc.b <adLargeRobot
                dc.b <adRobotPriest
                dc.b <adLargeTank
                dc.b <adLargeDrillTank
                dc.b <adLargeWorm
                dc.b <adSlimeBoss
                dc.b <adJROfficerNoArmor
                dc.b <adPlayer
                dc.b <adPilot
                dc.b <adSROfficer
                dc.b <adGruntNoArmor
                dc.b <adPlayer
                dc.b <adMedic
                dc.b <adJROfficerTrapped
                dc.b <adPilotSitting
                dc.b <adSROfficerWounded
                dc.b <adGruntWounded
                dc.b <adPlayerWheel
                dc.b <adPlayerWheel
                dc.b <adPlayerNoArmor
                dc.b <adItem
                dc.b <adObjectMarker
                dc.b <adLift
                dc.b <adFly
                dc.b <adFly
                dc.b <adSpitBall
                dc.b <adArmadillo
                dc.b <adTreeMine
                dc.b <adCeilingMine
                dc.b <adFloorMine
                dc.b <adSpike
                dc.b <adSpider
                dc.b <adSpider
                dc.b <adTurret
                dc.b <adCeilingTurret
                dc.b <adDroid
                dc.b <adRobotMine
                dc.b <adFlyingCraft
                dc.b <adFlyingCraft
                dc.b <adRobotSpider
                dc.b <adSpeechBubble
                dc.b <adCreator
                dc.b <adMetalPiece
                dc.b <adSmallWalker
                dc.b <adBarrel
                dc.b <adSmallTank
                dc.b <adDrillTank
                dc.b <adDrillMeleeHit
                dc.b <adWorkerTank
                dc.b <adWorkerMeleeHit
                dc.b <adCannonH
                dc.b <adCannonV
                dc.b <adCPUInvisible
                dc.b <adCPU
                dc.b <adSquid
                dc.b <adLargeDrillMeleeHit
                dc.b <adSlime
                dc.b <adSlimeLauncher
                dc.b <adSlimeShot
                dc.b <adWormHead
                dc.b <adWormPart
                dc.b <adWormBomb
                dc.b <adMushroomInvisible
                dc.b <adMushroom
                dc.b <adRockInvisible
                dc.b <adRock
                dc.b <adFireballSpawner
                dc.b <adFireball
                dc.b <adLargeFly
                dc.b <adLargeSpider
                dc.b <adEnemyChunk
                dc.b <adDecontaminator
                dc.b <adSmokeTrail
                dc.b <adScreenSaver
                dc.b <adDroidBossInvisible
                dc.b <adDroidBoss
                dc.b <adDroidBossInvisible
                dc.b <adDroidBoss
                dc.b <adFighterBossInvisible
                dc.b <adFighterBoss
                dc.b <adBridgeExplosion
                dc.b <adDistillerBossInvisible
                dc.b <adDistillerBoss
                dc.b <adFinalBossInvisible
                dc.b <adFinalBoss
                dc.b <adFinalBossBomb
                dc.b <adExplosion
                dc.b <adFinalBossBrain
                dc.b <adFinalBossLaser
                dc.b <adWormBoss
                dc.b <adWormBossHead
                dc.b <adWormBossPart
                dc.b <adWormBossBomb
                dc.b <adSpiderBoss
                dc.b <adBullet
                dc.b <adBounce
                dc.b <adLaser
                dc.b <adFlame
                dc.b <adElectricity
                dc.b <adGrenade
                dc.b <adMissile
                dc.b <adHeavyPlasma
                dc.b <adSmokeTrail
                dc.b <adExplosion
                dc.b <adWheelMine
                dc.b <adSmallSplash
                dc.b <adLargeSplash
                dc.b <adRangerSuit
                dc.b <adFighterBoss
                dc.b <adSmallFighterJet

actDispTblHi:   dc.b >adPlayer
                dc.b >adRobotSoldier
                dc.b >adRobotSoldier
                dc.b >adRobotSoldier
                dc.b >adHeavySoldier
                dc.b >adLargeRobot
                dc.b >adRobotPriest
                dc.b >adLargeTank
                dc.b >adLargeDrillTank
                dc.b >adLargeWorm
                dc.b >adSlimeBoss
                dc.b >adJROfficerNoArmor
                dc.b >adPlayer
                dc.b >adPilot
                dc.b >adSROfficer
                dc.b >adGruntNoArmor
                dc.b >adPlayer
                dc.b >adMedic
                dc.b >adJROfficerTrapped
                dc.b >adPilotSitting
                dc.b >adSROfficerWounded
                dc.b >adGruntWounded
                dc.b >adPlayerWheel
                dc.b >adPlayerWheel
                dc.b >adPlayerNoArmor
                dc.b >adItem
                dc.b >adObjectMarker
                dc.b >adLift
                dc.b >adFly
                dc.b >adFly
                dc.b >adSpitBall
                dc.b >adArmadillo
                dc.b >adTreeMine
                dc.b >adCeilingMine
                dc.b >adFloorMine
                dc.b >adSpike
                dc.b >adSpider
                dc.b >adSpider
                dc.b >adTurret
                dc.b >adCeilingTurret
                dc.b >adDroid
                dc.b >adRobotMine
                dc.b >adFlyingCraft
                dc.b >adFlyingCraft
                dc.b >adRobotSpider
                dc.b >adSpeechBubble
                dc.b >adCreator
                dc.b >adMetalPiece
                dc.b >adSmallWalker
                dc.b >adBarrel
                dc.b >adSmallTank
                dc.b >adDrillTank
                dc.b >adDrillMeleeHit
                dc.b >adWorkerTank
                dc.b >adWorkerMeleeHit
                dc.b >adCannonH
                dc.b >adCannonV
                dc.b >adCPUInvisible
                dc.b >adCPU
                dc.b >adSquid
                dc.b >adLargeDrillMeleeHit
                dc.b >adSlime
                dc.b >adSlimeLauncher
                dc.b >adSlimeShot
                dc.b >adWormHead
                dc.b >adWormPart
                dc.b >adWormBomb
                dc.b >adMushroomInvisible
                dc.b >adMushroom
                dc.b >adRockInvisible
                dc.b >adRock
                dc.b >adFireballSpawner
                dc.b >adFireball
                dc.b >adLargeFly
                dc.b >adLargeSpider
                dc.b >adEnemyChunk
                dc.b >adDecontaminator
                dc.b >adSmokeTrail
                dc.b >adScreenSaver
                dc.b >adDroidBossInvisible
                dc.b >adDroidBoss
                dc.b >adDroidBossInvisible
                dc.b >adDroidBoss
                dc.b >adFighterBossInvisible
                dc.b >adFighterBoss
                dc.b >adBridgeExplosion
                dc.b >adDistillerBossInvisible
                dc.b >adDistillerBoss
                dc.b >adFinalBossInvisible
                dc.b >adFinalBoss
                dc.b >adFinalBossBomb
                dc.b >adExplosion
                dc.b >adFinalBossBrain
                dc.b >adFinalBossLaser
                dc.b >adWormBoss
                dc.b >adWormBossHead
                dc.b >adWormBossPart
                dc.b >adWormBossBomb
                dc.b >adSpiderBoss
                dc.b >adBullet
                dc.b >adBounce
                dc.b >adLaser
                dc.b >adFlame
                dc.b >adElectricity
                dc.b >adGrenade
                dc.b >adMissile
                dc.b >adHeavyPlasma
                dc.b >adSmokeTrail
                dc.b >adExplosion
                dc.b >adWheelMine
                dc.b >adSmallSplash
                dc.b >adLargeSplash
                dc.b >adRangerSuit
                dc.b >adFighterBoss
                dc.b >adSmallFighterJet

adPlayerWheel:  dc.b ONESPRITE                  ;Number of sprites
                dc.b C_PLAYER                   ;Spritefile number
                dc.b 4                          ;Left frame add
                dc.b 8                          ;Number of frames
                dc.b 41,42,43,44                ;Frametable (first all frames of sprite1, then sprite2)
                dc.b 41,43,42,$80+44

adBullet:       dc.b ONESPRITE                  ;Number of sprites
                dc.b C_COMMON                   ;Spritefile number
                dc.b 0                          ;Left frame add
                dc.b 20                         ;Number of frames
                dc.b 5,6,7,8,9                  ;Frametable (first all frames of sprite1, then sprite2)
                dc.b 5,$80+6,$80+7,$80+8,9
                dc.b 10,11,12,$80+11,10
                dc.b 10,$80+11,$80+12,11,10

adBounce:       dc.b ONESPRITE                  ;Number of sprites
                dc.b C_COMMON                   ;Spritefile number
                dc.b 0                          ;Left frame add
                dc.b 2                          ;Number of frames
                dc.b 30,31                      ;Frametable (first all frames of sprite1, then sprite2)

adLaser:        dc.b ONESPRITE                  ;Number of sprites
                dc.b C_COMMON                   ;Spritefile number
                dc.b 0                          ;Left frame add
                dc.b 10                         ;Number of frames
                dc.b 23,24,25,$80+24,23         ;Frametable (first all frames of sprite1, then sprite2)
                dc.b 23,$80+24,25,24,23

adSmokeTrail:   dc.b ONESPRITE                  ;Number of sprites
                dc.b C_COMMON                   ;Spritefile number
                dc.b 0                          ;Left frame add
                dc.b 2                          ;Number of frames
                dc.b 21,22                      ;Frametable (first all frames of sprite1, then sprite2)

adExplosion:    dc.b ONESPRITE                  ;Number of sprites
                dc.b C_COMMON                   ;Spritefile number
                dc.b 0                          ;Left frame add
                dc.b 5                          ;Number of frames
                dc.b 0,1,2,3,4                  ;Frametable (first all frames of sprite1, then sprite2)

adFlame:        dc.b ONESPRITE                  ;Number of sprites
                dc.b C_COMMON                   ;Spritefile number
                dc.b 0                          ;Left frame add
                dc.b 4                          ;Number of frames
                dc.b 32,33,34,35                ;Frametable (first all frames of sprite1, then sprite2)

adGrenade:      dc.b ONESPRITE                  ;Number of sprites
                dc.b C_COMMON                   ;Spritefile number
                dc.b 0                          ;Left frame add
                dc.b 3                          ;Number of frames
                dc.b 13,14,15                   ;Frametable (first all frames of sprite1, then sprite2)

adMissile:      dc.b ONESPRITE                  ;Number of sprites
                dc.b C_COMMON                   ;Spritefile number
                dc.b 0                          ;Left frame add
                dc.b 10                         ;Number of frames
                dc.b 16,17,18,19,20             ;Frametable (first all frames of sprite1, then sprite2)
                dc.b 16,$80+17,$80+18,$80+19,20

adElectricity:  dc.b ONESPRITE                  ;Number of sprites
                dc.b C_COMMON                   ;Spritefile number
                dc.b 0                          ;Left frame add
                dc.b 10                         ;Number of frames
                dc.b 27,28,29,$80+28,27         ;Frametable (first all frames of sprite1, then sprite2)
                dc.b 27,$80+28,$80+29,28,27

adSmallSplash:  dc.b ONESPRITE                  ;Number of sprites
                dc.b C_COMMON                   ;Spritefile number
                dc.b 0                          ;Left frame add
                dc.b 4                          ;Number of frames
                dc.b 42,43,44,45                ;Frametable (first all frames of sprite1, then sprite2)

adLargeSplash:  dc.b ONESPRITE                  ;Number of sprites
                dc.b C_COMMON                   ;Spritefile number
                dc.b 0                          ;Left frame add
                dc.b 5                          ;Number of frames
                dc.b 37,38,39,40,41             ;Frametable (first all frames of sprite1, then sprite2)

adItem:         dc.b ONESPRITE                  ;Number of sprites
                dc.b C_COMMON                   ;Spritefile number
                dc.b 0                          ;Left frame add
                dc.b 19                         ;Number of frames
itemFrames:     dc.b 46,47,48,49,50,51,52,53    ;Frametable (first all frames of sprite1, then sprite2)
                dc.b 54,55,56,56,56,56,57,58
                dc.b 59,60,61,62

adMetalPiece:   dc.b ONESPRITE                  ;Number of sprites
                dc.b C_COMMON                   ;Spritefile number
                dc.b 0                          ;Left frame add
                dc.b 4                          ;Number of frames
                dc.b 66,67,68,69

adHeavyPlasma:  dc.b ONESPRITE                  ;Number of sprites
                dc.b C_COMMON                   ;Spritefile number
                dc.b 0                          ;Left frame add
                dc.b 1                          ;Number of frames
                dc.b 26                         ;Frametable (first all frames of sprite1, then sprite2)

adWheelMine:    dc.b ONESPRITE                  ;Number of sprites
                dc.b C_COMMON                   ;Spritefile number
                dc.b 0                          ;Left frame add
                dc.b 1                          ;Number of frames
                dc.b 36                         ;Frametable (first all frames of sprite1, then sprite2)

adObjectMarker: dc.b ONESPRITE                  ;Number of sprites
                dc.b C_COMMON                   ;Spritefile number
                dc.b 0                          ;Left frame add
                dc.b 1                          ;Number of frames
                dc.b 63

adSpeechBubble: dc.b ONESPRITE                  ;Number of sprites
                dc.b C_COMMON                   ;Spritefile number
                dc.b 0                          ;Left frame add
                dc.b 1                          ;Number of frames
                dc.b 70

adPlayer:       dc.b HUMANOID                   ;Number of sprites
                dc.b C_PLAYER                   ;Lower part spritefile number
                dc.b 18                         ;Lower part base spritenumber
                dc.b 0                          ;Lower part base index into the frametable
                dc.b 28                         ;Lower part left frame add
                dc.b C_PLAYER                   ;Upper part spritefile number
                dc.b 0                          ;Upper part base spritenumber
                dc.b 0                          ;Upper part base index into the frametable
                dc.b 34                         ;Upper part left frame add

adPlayerNoArmor:dc.b HUMANOID                   ;Number of sprites
                dc.b C_PLAYER                   ;Lower part spritefile number
                dc.b 18                         ;Lower part base spritenumber
                dc.b 0                          ;Lower part base index into the frametable
                dc.b 28                         ;Lower part left frame add
                dc.b C_CREW                     ;Upper part spritefile number
plrNoArmorUpperBaseFrame:
                dc.b 0                          ;Upper part base spritenumber
                dc.b 0                          ;Upper part base index into the frametable
                dc.b 34                         ;Upper part left frame add

adJROfficerNoArmor:
                dc.b HUMANOID                   ;Number of sprites
                dc.b C_PLAYER                   ;Lower part spritefile number
                dc.b 18                         ;Lower part base spritenumber
                dc.b 0                          ;Lower part base index into the frametable
                dc.b 28                         ;Lower part left frame add
                dc.b C_CREW                     ;Upper part spritefile number
                dc.b 27                         ;Upper part base spritenumber
                dc.b 0                          ;Upper part base index into the frametable
                dc.b 34                         ;Upper part left frame add

adSROfficer:    dc.b HUMANOID                   ;Number of sprites
                dc.b C_PLAYER                   ;Lower part spritefile number
                dc.b 18                         ;Lower part base spritenumber
                dc.b 0                          ;Lower part base index into the frametable
                dc.b 28                         ;Lower part left frame add
                dc.b C_CREW                     ;Upper part spritefile number
                dc.b 24                         ;Upper part base spritenumber
                dc.b 0                          ;Upper part base index into the frametable
                dc.b 34                         ;Upper part left frame add

adMedic:        dc.b HUMANOID                   ;Number of sprites
                dc.b C_PLAYER                   ;Lower part spritefile number
                dc.b 18                         ;Lower part base spritenumber
                dc.b 0                          ;Lower part base index into the frametable
                dc.b 28                         ;Lower part left frame add
                dc.b C_CREW                     ;Upper part spritefile number
                dc.b 8                          ;Upper part base spritenumber
                dc.b 0                          ;Upper part base index into the frametable
                dc.b 34                         ;Upper part left frame add

adPilot:        dc.b HUMANOID                   ;Number of sprites
                dc.b C_PLAYER                   ;Lower part spritefile number
                dc.b 18                         ;Lower part base spritenumber
                dc.b 0                          ;Lower part base index into the frametable
                dc.b 28                         ;Lower part left frame add
                dc.b C_CREW                     ;Upper part spritefile number
                dc.b 30                         ;Upper part base spritenumber
                dc.b 0                          ;Upper part base index into the frametable
                dc.b 34                         ;Upper part left frame add

adGruntNoArmor: dc.b HUMANOID                   ;Number of sprites
                dc.b C_PLAYER                   ;Lower part spritefile number
                dc.b 18                         ;Lower part base spritenumber
                dc.b 0                          ;Lower part base index into the frametable
                dc.b 28                         ;Lower part left frame add
                dc.b C_CREW                     ;Upper part spritefile number
                dc.b 16                         ;Upper part base spritenumber
                dc.b 0                          ;Upper part base index into the frametable
                dc.b 34                         ;Upper part left frame add

adPilotSitting: dc.b HUMANOID                   ;Number of sprites
                dc.b C_CREW                     ;Lower part spritefile number
                dc.b 23                         ;Lower part base spritenumber
                dc.b 0                          ;Lower part base index into the frametable
                dc.b 28                         ;Lower part left frame add
                dc.b C_CREW                     ;Upper part spritefile number
                dc.b 30                         ;Upper part base spritenumber
                dc.b 0                          ;Upper part base index into the frametable
                dc.b 34                         ;Upper part left frame add

adJROfficerTrapped:
                dc.b HUMANOID                   ;Number of sprites
                dc.b C_CREW2                    ;Lower part spritefile number
                dc.b 3                          ;Lower part base spritenumber
                dc.b 0                          ;Lower part base index into the frametable
                dc.b 0                          ;Lower part left frame add
                dc.b C_CREW2                    ;Upper part spritefile number
                dc.b 1                          ;Upper part base spritenumber
                dc.b 1                          ;Upper part base index into the frametable
                dc.b 0                          ;Upper part left frame add

        ; Actor logic data

alFly           = USESCRIPT+EP_ALFly
alSpitFly       = USESCRIPT+EP_ALSpitFly
alSpitBall      = USESCRIPT+EP_ALSpitBall
alArmadillo     = USESCRIPT+EP_ALArmadillo
alMine          = USESCRIPT+EP_ALMine
alSpike         = USESCRIPT+EP_ALSpike
alSpider        = USESCRIPT+EP_ALSpider
alSpitSpider    = USESCRIPT+EP_ALSpitSpider
alRobotSoldier  = USESCRIPT+EP_ALRobotSoldier
alEliteSoldier  = USESCRIPT+EP_ALEliteSoldier
alHeavySoldier  = USESCRIPT+EP_ALHeavySoldier
alTurret        = USESCRIPT+EP_ALTurret
alCeilingTurret = USESCRIPT+EP_ALCeilingTurret
alDroid         = USESCRIPT+EP_ALDroid
alRobotMine     = USESCRIPT+EP_ALRobotMine
alFlyingCraft   = USESCRIPT+EP_ALFlyingCraft
alEliteFlyingCraft = USESCRIPT+EP_ALEliteFlyingCraft
alSquid         = USESCRIPT+EP_ALSquid
alCreator       = USESCRIPT+EP_ALCreator
alLift          = USESCRIPT+EP_ALLift
alRobotSpider   = USESCRIPT ;Entrypoint not in preview
alSmallWalker   = USESCRIPT ;Entrypoint not in preview
alLargeRobot    = USESCRIPT ;Entrypoint not in preview
alBarrel        = USESCRIPT ;Entrypoint not in preview
alSmallTank     = USESCRIPT ;Entrypoint not in preview
alDrillTank     = USESCRIPT ;Entrypoint not in preview
alDrillMeleeHit = USESCRIPT ;Entrypoint not in preview
alWorkerTank    = USESCRIPT ;Entrypoint not in preview
alWorkerMeleeHit = USESCRIPT ;Entrypoint not in preview
alRobotPriest   = USESCRIPT ;Entrypoint not in preview
alLargeTank     = USESCRIPT ;Entrypoint not in preview
alLargeDrillTank = USESCRIPT ;Entrypoint not in preview
alLargeDrillMeleeHit = USESCRIPT ;Entrypoint not in preview
alCannonH       = USESCRIPT ;Entrypoint not in preview
alCannonV       = USESCRIPT ;Entrypoint not in preview
alCPUInvisible  = USESCRIPT ;Entrypoint not in preview
alCPU           = USESCRIPT ;Entrypoint not in preview
alSlime         = USESCRIPT ;Entrypoint not in preview
alSlimeLauncher = USESCRIPT ;Entrypoint not in preview
alSlimeShot     = USESCRIPT ;Entrypoint not in preview
alLargeWorm     = USESCRIPT ;Entrypoint not in preview
alWormHead      = USESCRIPT ;Entrypoint not in preview
alWormPart      = USESCRIPT ;Entrypoint not in preview
alWormBomb      = USESCRIPT ;Entrypoint not in preview
alMushroomInvisible = USESCRIPT ;Entrypoint not in preview
alMushroom      = USESCRIPT ;Entrypoint not in preview
alRockInvisible = USESCRIPT ;Entrypoint not in preview
alRock          = USESCRIPT ;Entrypoint not in preview
alFireballSpawner = USESCRIPT ;Entrypoint not in preview
alFireball      = USESCRIPT ;Entrypoint not in preview
alLargeFly      = USESCRIPT ;Entrypoint not in preview
alLargeSpider   = USESCRIPT ;Entrypoint not in preview
alEnemyChunk    = alMetalPiece
alIntroSoldier  = USESCRIPT+EP_ALIntroSoldier
alDecontaminator = USESCRIPT ;Entrypoint not in preview
alSpray         = USESCRIPT ;Entrypoint not in preview
alScreenSaver   = USESCRIPT ;Entrypoint not in preview
alDroidBossInvisible = USESCRIPT+EP_ALDroidBossInvisible
alDroidBoss     = USESCRIPT+EP_ALDroidBoss
alBombBossInvisible = USESCRIPT+EP_ALBombBossInvisible
alBombBoss     = USESCRIPT+EP_ALBombBoss
alFighterBossInvisible = USESCRIPT ;Entrypoint not in preview
alFighterBoss   = USESCRIPT ;Entrypoint not in preview
alBridgeExplosion = USESCRIPT ;Entrypoint not in preview
alDistillerBossInvisible = USESCRIPT ;Entrypoint not in preview
alDistillerBoss = USESCRIPT ;Entrypoint not in preview
alSlimeBoss     = USESCRIPT ;Entrypoint not in preview
alFinalBossInvisible = USESCRIPT ;Entrypoint not in preview
alFinalBoss     = USESCRIPT ;Entrypoint not in preview
alFinalBossBomb      = USESCRIPT ;Entrypoint not in preview
alFinalBossBombExplosion = USESCRIPT ;Entrypoint not in preview
alFinalBossBrain = USESCRIPT ;Entrypoint not in preview
alWormBoss      = USESCRIPT ;Entrypoint not in preview
alWormBossHead  = USESCRIPT ;Entrypoint not in preview
alWormBossPart  = USESCRIPT ;Entrypoint not in preview
alSpiderBoss    = USESCRIPT ;Entrypoint not in preview
alRangerSuit    = USESCRIPT ;Entrypoint not in preview
alEscapeFighterJet = USESCRIPT ;Entrypoint not in preview
alSmallFighterJet = USESCRIPT ;Entrypoint not in preview

actLogicTblLo:  dc.b <alPlayer
                dc.b <alRobotSoldier
                dc.b <alIntroSoldier
                dc.b <alEliteSoldier
                dc.b <alHeavySoldier
                dc.b <alLargeRobot
                dc.b <alRobotPriest
                dc.b <alLargeTank
                dc.b <alLargeDrillTank
                dc.b <alLargeWorm
                dc.b <alSlimeBoss
                dc.b <alNPC
                dc.b <alNPC
                dc.b <alNPC
                dc.b <alNPC
                dc.b <alNPC
                dc.b <alNPC
                dc.b <alNPC
                dc.b <alNPCStationary
                dc.b <alNPCStationary
                dc.b <alNPCStationary
                dc.b <alNPCStationary
                dc.b <alNPCWheel
                dc.b <alPlayerWheel
                dc.b <alPlayer
                dc.b <alItem
                dc.b <alObjectMarker
                dc.b <alLift
                dc.b <alFly
                dc.b <alSpitFly
                dc.b <alSpitBall
                dc.b <alArmadillo
                dc.b <alMine
                dc.b <alMine
                dc.b <alMine
                dc.b <alSpike
                dc.b <alSpider
                dc.b <alSpitSpider
                dc.b <alTurret
                dc.b <alCeilingTurret
                dc.b <alDroid
                dc.b <alRobotMine
                dc.b <alFlyingCraft
                dc.b <alEliteFlyingCraft
                dc.b <alRobotSpider
                dc.b <alSpeechBubble
                dc.b <alCreator
                dc.b <alMetalPiece
                dc.b <alSmallWalker
                dc.b <alBarrel
                dc.b <alSmallTank
                dc.b <alDrillTank
                dc.b <alDrillMeleeHit
                dc.b <alWorkerTank
                dc.b <alWorkerMeleeHit
                dc.b <alCannonH
                dc.b <alCannonV
                dc.b <alCPUInvisible
                dc.b <alCPU
                dc.b <alSquid
                dc.b <alLargeDrillMeleeHit
                dc.b <alSlime
                dc.b <alSlimeLauncher
                dc.b <alSlimeShot
                dc.b <alWormHead
                dc.b <alWormPart
                dc.b <alWormBomb
                dc.b <alMushroomInvisible
                dc.b <alMushroom
                dc.b <alRockInvisible
                dc.b <alRock
                dc.b <alFireballSpawner
                dc.b <alFireball
                dc.b <alLargeFly
                dc.b <alLargeSpider
                dc.b <alEnemyChunk
                dc.b <alDecontaminator
                dc.b <alSpray
                dc.b <alScreenSaver
                dc.b <alDroidBossInvisible
                dc.b <alDroidBoss
                dc.b <alBombBossInvisible
                dc.b <alBombBoss
                dc.b <alFighterBossInvisible
                dc.b <alFighterBoss
                dc.b <alBridgeExplosion
                dc.b <alDistillerBossInvisible
                dc.b <alDistillerBoss
                dc.b <alFinalBossInvisible
                dc.b <alFinalBoss
                dc.b <alFinalBossBomb
                dc.b <alFinalBossBombExplosion
                dc.b <alFinalBossBrain
                dc.b <alLaser
                dc.b <alWormBoss
                dc.b <alWormBossHead
                dc.b <alWormBossPart
                dc.b <alWormBomb
                dc.b <alSpiderBoss
                dc.b <alBullet
                dc.b <alBounce
                dc.b <alLaser
                dc.b <alFlame
                dc.b <alElectricity
                dc.b <alGrenade
                dc.b <alMissile
                dc.b <alHeavyPlasma
                dc.b <alSmokeTrail
                dc.b <alExplosion
                dc.b <alWheelMine
                dc.b <alSmallSplash
                dc.b <alLargeSplash
                dc.b <alRangerSuit
                dc.b <alEscapeFighterJet
                dc.b <alSmallFighterJet

actLogicTblHi:  dc.b >alPlayer
                dc.b >alRobotSoldier
                dc.b >alIntroSoldier
                dc.b >alEliteSoldier
                dc.b >alHeavySoldier
                dc.b >alLargeRobot
                dc.b >alRobotPriest
                dc.b >alLargeTank
                dc.b >alLargeDrillTank
                dc.b >alLargeWorm
                dc.b >alSlimeBoss
                dc.b >alNPC
                dc.b >alNPC
                dc.b >alNPC
                dc.b >alNPC
                dc.b >alNPC
                dc.b >alNPC
                dc.b >alNPC
                dc.b >alNPCStationary
                dc.b >alNPCStationary
                dc.b >alNPCStationary
                dc.b >alNPCStationary
                dc.b >alNPCWheel
                dc.b >alPlayerWheel
                dc.b >alPlayer
                dc.b >alItem
                dc.b >alObjectMarker
                dc.b >alLift
                dc.b >alFly
                dc.b >alSpitFly
                dc.b >alSpitBall
                dc.b >alArmadillo
                dc.b >alMine
                dc.b >alMine
                dc.b >alMine
                dc.b >alSpike
                dc.b >alSpider
                dc.b >alSpitSpider
                dc.b >alTurret
                dc.b >alCeilingTurret
                dc.b >alDroid
                dc.b >alRobotMine
                dc.b >alFlyingCraft
                dc.b >alEliteFlyingCraft
                dc.b >alRobotSpider
                dc.b >alSpeechBubble
                dc.b >alCreator
                dc.b >alMetalPiece
                dc.b >alSmallWalker
                dc.b >alBarrel
                dc.b >alSmallTank
                dc.b >alDrillTank
                dc.b >alDrillMeleeHit
                dc.b >alWorkerTank
                dc.b >alWorkerMeleeHit
                dc.b >alCannonH
                dc.b >alCannonV
                dc.b >alCPUInvisible
                dc.b >alCPU
                dc.b >alSquid
                dc.b >alLargeDrillMeleeHit
                dc.b >alSlime
                dc.b >alSlimeLauncher
                dc.b >alSlimeShot
                dc.b >alWormHead
                dc.b >alWormPart
                dc.b >alWormBomb
                dc.b >alMushroomInvisible
                dc.b >alMushroom
                dc.b >alRockInvisible
                dc.b >alRock
                dc.b >alFireballSpawner
                dc.b >alFireball
                dc.b >alLargeFly
                dc.b >alLargeSpider
                dc.b >alEnemyChunk
                dc.b >alDecontaminator
                dc.b >alSpray
                dc.b >alScreenSaver
                dc.b >alDroidBossInvisible
                dc.b >alDroidBoss
                dc.b >alBombBossInvisible
                dc.b >alBombBoss
                dc.b >alFighterBossInvisible
                dc.b >alFighterBoss
                dc.b >alBridgeExplosion
                dc.b >alDistillerBossInvisible
                dc.b >alDistillerBoss
                dc.b >alFinalBossInvisible
                dc.b >alFinalBoss
                dc.b >alFinalBossBomb
                dc.b >alFinalBossBombExplosion
                dc.b >alFinalBossBrain
                dc.b >alLaser
                dc.b >alWormBoss
                dc.b >alWormBossHead
                dc.b >alWormBossPart
                dc.b >alWormBomb
                dc.b >alSpiderBoss
                dc.b >alBullet
                dc.b >alBounce
                dc.b >alLaser
                dc.b >alFlame
                dc.b >alElectricity
                dc.b >alGrenade
                dc.b >alMissile
                dc.b >alHeavyPlasma
                dc.b >alSmokeTrail
                dc.b >alExplosion
                dc.b >alWheelMine
                dc.b >alSmallSplash
                dc.b >alLargeSplash
                dc.b >alRangerSuit
                dc.b >alEscapeFighterJet
                dc.b >alSmallFighterJet

        ;Note: collision sizes are all at 2 pixel accuracy!
        ;Horizontal size is half (to both left & right)

alPlayer:       dc.w MovePlayer                 ;Update routine
                dc.b GRP_HEROES|AF_TAKEDAMAGE|AF_GROUNDBASED|AF_NOREMOVECHECK ;Actor flags
                dc.b 3                          ;Horizontal size
                dc.b 18                         ;Size up
                dc.b 0                          ;Size down
                dc.b HP_PLAYER                  ;Initial health
plrDmgModify:   dc.b NO_MODIFY
                dc.w PlayerDeath                ;Destroy routine
                dc.b PLAYER_SIDESPEED           ;Max movement speed

alPlayerWheel:  dc.w MovePlayerWheel            ;Update routine
                dc.b GRP_HEROES|AF_TAKEDAMAGE|AF_GROUNDBASED|AF_NOREMOVECHECK ;Actor flags
                dc.b 4                          ;Horizontal size
                dc.b 7                          ;Size up
                dc.b 0                          ;Size down
                dc.b HP_PLAYER                  ;Initial health
wheelDmgModify: dc.b 7                          ;Damage modifier, wheel takes reduced damage
                dc.w PlayerDeath                ;Destroy routine

alBullet:       dc.w MoveBulletMuzzleFlash      ;Update routine
                dc.b AF_INITONLYSIZE            ;Actor flags
                dc.b 2                          ;Horizontal size
                dc.b 1                          ;Size up
                dc.b 1                          ;Size down

alBounce:       dc.w MoveBullet                 ;Update routine
                dc.b AF_INITONLYSIZE            ;Actor flags
                dc.b 3                          ;Horizontal size
                dc.b 3                          ;Size up
                dc.b 3                          ;Size down

alLaser:        dc.w MoveLaser                  ;Update routine
                dc.b AF_INITONLYSIZE            ;Actor flags
                dc.b 4                          ;Horizontal size
                dc.b 4                          ;Size up
                dc.b 4                          ;Size down

alFlame:        dc.w MoveFlame                  ;Update routine
                dc.b AF_INITONLYSIZE            ;Actor flags
                dc.b 3                          ;Horizontal size
                dc.b 3                          ;Size up
                dc.b 2                          ;Size down

alGrenade:      dc.w MoveLauncherGrenade        ;Update routine
                dc.b AF_INITONLYSIZE            ;Actor flags
                dc.b 2                          ;Horizontal size
                dc.b 1                          ;Size up
                dc.b 1                          ;Size down

alMissile:      dc.w MoveMissile                ;Update routine
                dc.b AF_INITONLYSIZE            ;Actor flags
                dc.b 2                          ;Horizontal size
                dc.b 2                          ;Size up
                dc.b 2                          ;Size down

alElectricity:  dc.w MoveElectricity            ;Update routine
                dc.b AF_INITONLYSIZE            ;Actor flags
                dc.b 4                          ;Horizontal size
                dc.b 4                          ;Size up
                dc.b 4                          ;Size down

alHeavyPlasma:  dc.w MoveBullet                 ;Update routine
                dc.b AF_INITONLYSIZE            ;Actor flags
                dc.b 4                          ;Horizontal size
                dc.b 4                          ;Size up
                dc.b 4                          ;Size down

alSmokeTrail:   dc.w MoveSmokeTrail             ;Update routine
                dc.b AF_INITONLYSIZE            ;Actor flags

alExplosion:    dc.w MoveExplosion              ;Update routine
                dc.b AF_INITONLYSIZE            ;Actor flags

alWheelMine:    dc.w MoveWheelMine              ;Update routine
                dc.b AF_INITONLYSIZE|AF_GROUNDBASED ;Actor flags
                dc.b 3                          ;Horizontal size
                dc.b 2                          ;Size up
                dc.b 0                          ;Size down

alSmallSplash:  dc.w MoveSmallSplash            ;Update routine
                dc.b AF_INITONLYSIZE            ;Actor flags

alLargeSplash:  dc.w MoveLargeSplash            ;Update routine
                dc.b AF_INITONLYSIZE            ;Actor flags

alItem:         dc.w MoveItem                   ;Update routine
                dc.b AF_INITONLYSIZE|AF_GROUNDBASED ;Actor flags
                dc.b 4                          ;Horizontal size
                dc.b 3                          ;Size up
                dc.b 3                          ;Size down

alMetalPiece:   dc.w MoveMetalPiece             ;Update routine
                dc.b AF_INITONLYSIZE            ;Actor flags

alObjectMarker: dc.w MoveObjectMarker           ;Update routine
                dc.b AF_INITONLYSIZE|AF_NOREMOVECHECK ;Actor flags

alSpeechBubble: dc.w MoveSpeechBubble           ;Update routine
                dc.b AF_INITONLYSIZE|AF_NOREMOVECHECK ;Actor flags

alNPC:          dc.w MoveNPC                    ;Update routine
                dc.b GRP_HEROES|AF_GROUNDBASED  ;Actor flags
                dc.b 3                          ;Horizontal size
                dc.b 18                         ;Size up
                dc.b 0                          ;Size down
                dc.b HP_PLAYER                  ;Initial health
                dc.b NO_MODIFY
                dc.w PlayerDeath                ;Destroy routine
                dc.b PLAYER_SIDESPEED           ;Max movement speed

alNPCStationary:dc.w MoveNPCStationary          ;Update routine
                dc.b GRP_HEROES|AF_GROUNDBASED  ;Actor flags
                dc.b 3                          ;Horizontal size
                dc.b 18                         ;Size up
                dc.b 0                          ;Size down
                dc.b HP_PLAYER                  ;Initial health

alNPCWheel:     dc.w MoveNPCWheel               ;Update routine
                dc.b GRP_HEROES|AF_GROUNDBASED  ;Actor flags
                dc.b 4                          ;Horizontal size
                dc.b 7                          ;Size up
                dc.b 0                          ;Size down
                dc.b HP_PLAYER                  ;Initial health

actBottomAdjustTbl:
                dc.b -1 ;ACT_PLAYER
                dc.b -1 ;ACT_ROBOTSOLDIER
                dc.b -1 ;ACT_INTROSOLDIER
                dc.b -1 ;ACT_ELITESOLDIER
                dc.b -1 ;ACT_HEAVYSOLDIER
                dc.b -1 ;ACT_LARGEROBOT
                dc.b -2 ;ACT_ROBOTPRIEST
                dc.b -1 ;ACT_LARGETANK
                dc.b -1 ;ACT_LARGEDRILLTANK
                dc.b -2 ;ACT_LARGEWORM
                dc.b -1 ;ACT_SLIMEBOSS
                dc.b -1 ;ACT_JROFFICER_NOARMOR
                dc.b -1 ;ACT_JROFFICER
                dc.b -1 ;ACT_PILOT_SITTING
                dc.b -1 ;ACT_PILOT
                dc.b -1 ;ACT_GRUNT_NOARMOR
                dc.b -1 ;ACT_GRUNT
                dc.b -1 ;ACT_MEDIC
                dc.b -1 ;ACT_SROFFICER

npcIndexTbl:    dc.b NPC_JROFFICER
                dc.b NPC_JROFFICER
                dc.b NPC_PILOT
                dc.b NPC_SROFFICER
                dc.b NPC_GRUNT
                dc.b NPC_GRUNT
                dc.b NPC_MEDIC
                dc.b NPC_JROFFICER
                dc.b NPC_PILOT
                dc.b NPC_SROFFICER
                dc.b NPC_GRUNT
                dc.b NPC_GRUNT

npcColorTbl:    dc.b $3e ;JROfficer no armor
                dc.b $0e ;JROfficer armor
                dc.b $33 ;Pilot no armor
                dc.b $2e ;SROfficer no armor
                dc.b $2b ;Grunt no armor
                dc.b $0b ;Grunt armor
                dc.b $12 ;Medic no armor
                dc.b $3e ;JROfficer trapped
                dc.b $33 ;Pilot sitting
                dc.b $2e ;SROfficer wounded
                dc.b $0b ;Grunt wounded
                dc.b $0b ;Grunt wheel mode