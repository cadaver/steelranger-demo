                org $0000

                include macros.s
                include memory.s
                include mainsym.s

        ; Note! Code must be unambiguous! Relocated code cannot have skip1/skip2 -macros!

                dc.w scriptEnd-scriptStart  ;Chunk data size
                dc.b 27                     ;Number of objects

scriptStart:
                rorg scriptCodeRelocStart   ;Initial relocation address when loaded

                dc.w MoveFly            ;$0100
                dc.w DestroyFly         ;$0101
                dc.w MoveSpitFly        ;$0102
                dc.w MoveSpitBall       ;$0103
                dc.w DestroySpitBall    ;$0104
                dc.w MoveArmadillo      ;$0105
                dc.w MoveMine           ;$0106
                dc.w DestroyMine        ;$0107
                dc.w MoveSpike          ;$0108
                dc.w MoveSpider         ;$0109
                dc.w MoveSpitSpider     ;$010a
                dc.w ALFly              ;$010b
                dc.w ALSpitFly          ;$010c
                dc.w ALSpitBall         ;$010d
                dc.w ALArmadillo        ;$010e
                dc.w ALMine             ;$010f
                dc.w ALSpike            ;$0110
                dc.w ALSpider           ;$0111
                dc.w ALSpitSpider       ;$0112
                dc.w ADFly              ;$0113
                dc.w ADSpitBall         ;$0114
                dc.w ADArmadillo        ;$0115
                dc.w ADTreeMine         ;$0116
                dc.w ADCeilingMine      ;$0117
                dc.w ADFloorMine        ;$0118
                dc.w ADSpike            ;$0119
                dc.w ADSpider           ;$011a

        ; Fly enemy movement routine
        ;
        ; Parameters: X:Actor index
        ; Returns: -
        ; Modifies: A,Y,temp vars
        
MoveFly:        lda actHp,x
                beq MoveFly_Dead
                lda actFall,x
                beq MoveFly_Initialize
MoveFly_MoveCommon:
                inc actTime,x
                lda actTime,x
                lsr
                and #$07
                tay
                lda flyYSpdTbl,y
                sta actSY,x
                jsr MoveFlyer
                lda actMB,x
                and #MB_HITWALL
                beq MoveFly_NoWall
                lda actSX,x
                jsr Negate8
                sta actSX,x
                sta actD,x
MoveFly_NoWall: lda actF1,x
                eor #$01
                sta actF1,x
                jsr CheckPlayerCollision
                bcc MoveFly_NoCollision
                lda #DMG_FLY
                jmp AddStrobedDamage
MoveFly_NoCollision:
MoveFly_NoRemove:
                rts

MoveFly_Dead:   jsr FallingMotionCommon_GoOutside
                lda temp5
                and #BI_WATER
                bne MoveFly_LandedInWater
                lda actMB,x
                and #MB_HITWALL
                beq MoveFly_DeadNoWall
                jsr StopXSpeed
MoveFly_DeadNoWall:
                lda actMB,x
                and #MB_LANDED
                bne MoveFly_LandedDead
                dec actTime,x
                bne MoveFly_NoRemove
                jmp RemoveActor
MoveFly_LandedDead:
                lda actSizeU,x
                asl
                asl
                eor #$ff
                jsr MoveActorY
                lda #$00
                sta actFlash,x
                jmp ExplodeActor
MoveFly_LandedInWater:
                lda #ACT_LARGESPLASH
                jsr TransformActor
                jmp SetSplashPosition

MoveFly_Initialize:
                ldy #3*8+4                      ;Always face player when added on screen
MoveFly_InitCommon:
                jsr GetPlayerFaceDirection
                sta actD,x
                asl
                tya
                bcc MoveFly_InitRight
                eor #$ff
                adc #$00                        ;C=1 here
MoveFly_InitRight:
                sta actSX,x
                jsr Random                      ;Initialize random downward phase for Y-movement
                and #$07
                sta actTime,x
                inc actFall,x
                rts

GetPlayerFaceDirection:
                lda actXH+ACTI_PLAYER
                sec
                sbc actXH,x
                rts

        ; Fly / armadillo destroy routine
        ;
        ; Parameters: X:Actor index
        ; Returns: -
        ; Modifies: A,Y,temp vars

DestroyArmadillo:
DestroyFly:     jsr DropItem
                lda #SFX_DEATH
                jsr QueueSfx
                lda #50
                sta actTime,x
                lda actFlash,x
                ora #COLOR_FLICKER
                sta actFlash,x
                lda #-4*8
                sta actSY,x
                lda #$00
                sta actMB,x
                jmp ApplyDeathImpulse

        ; Spitfly enemy move routine
        ;
        ; Parameters: X:Actor index
        ; Returns: -
        ; Modifies: A,Y,temp vars

MoveSpitFly_Dead:jmp MoveFly_Dead
MoveSpitFly:    lda actHp,x
                beq MoveSpitFly_Dead
                lda actTime,x
                beq MoveSpitFly_Initialize
                lda actAttackD,x
                beq MoveSpitFly_CanShoot
                dec actAttackD,x
                bpl MoveSpitFly_NoShoot
MoveSpitFly_CanShoot:
                ldy #ACTI_PLAYER
                jsr GetActorDistance_LeadTarget
                lda temp7                       ;Must be above and facing player
                bmi MoveSpitFly_NoShoot
                lda temp5
                eor actD,x
                bmi MoveSpitFly_NoShoot
                lda temp8                       ;X & Y distance should be roughly same
                clc
                sbc temp6
                beq MoveSpitFly_DistanceOK
                cmp #$fe
                bcc MoveSpitFly_NoShoot
MoveSpitFly_DistanceOK:
                lda #5*8
                jsr SpawnSpitBall
                lda #-1*8
                sta actSY,x
                ldx actIndex
MoveSpitFly_NoShoot:
                lda actTime,x
                jmp MoveFly_MoveCommon

MoveSpitFly_Initialize:
                jsr MoveSpitSpider_InitCommon
                ldy #3*8                    ;Slower than regular fly
                jmp MoveFly_InitCommon

SpawnSpitBall:  sta SpawnSpitBall_Speed+1
                jsr GetBulletSpawnOffset
                jsr GetFreePersistentActor
                bcc SpawnSpitBall_Fail
                lda #ACT_SPITBALL
                jsr SpawnWithOffset
                lda #50                         ;At least 2 sec. between shots
                sta actAttackD,x
                lda actD,x
                asl
SpawnSpitBall_Speed:
                lda #$00
                bcc SpawnSpitBall_ShootRight
                eor #$ff
                adc #$00                        ;C=1
SpawnSpitBall_ShootRight:
                sta actSX,y
                jsr InitSpawnedActor
                lda #SFX_ARCGUN
                jsr QueueSfx
                sec
SpawnSpitBall_Fail:
                rts

        ; Spitball move routine
        ;
        ; Parameters: X:Actor index
        ; Returns: -
        ; Modifies: A,Y,temp vars

MoveSpitBall:   lda #1
                ldy #2
                jsr LoopingAnimation
                jsr FallingMotionCommon_GoOutside
                lda actMB,x
                and #MB_LANDED|MB_HITWALL|MB_HITCEILING
                bne MoveSpitBall_Explode
                lda temp5
                and #BI_WATER
                bne MoveSpitBall_HitWater
                jsr CheckPlayerCollision
                bcc MoveSpitBall_NoCollision
                lda #DMG_SPIT
                jsr AddDamage
DestroySpitBall:
MoveSpitBall_Explode:
                lda #SFX_SPLASH
                jsr QueueSfx
                lda #5
                sta actFlash,x
                lda #ACT_EXPLOSION
                jmp TransformActor
MoveSpitBall_NoCollision:
                rts
MoveSpitBall_HitWater:
                lda #ACT_LARGESPLASH
                jsr TransformActor
                jmp SetSplashPosition

        ; Armadillo move routine
        ;
        ; Parameters: X:Actor index
        ; Returns: -
        ; Modifies: A,Y,temp vars

MoveArmadillo_Dead:
                jmp MoveFly_Dead
MoveArmadillo:  lda actHp,x
                beq MoveArmadillo_Dead
                lda actF1,x
                cmp #3
                bcs MoveArmadillo_IsWheel
MoveArmadillo_Walking:
                jsr Random
                cmp #$08
                bcc MoveArmadillo_TurnToWheel
MoveArmadillo_Walking2:
                lda #1
                ldy #2
                jsr LoopingAnimation
                ldy #2*8
MoveArmadillo_MoveCommon:
                lda actD,x
                asl
                lda #8
                jsr AccActorXNegOrPos
                lda actMB,x
                ora #MB_PREVENTFALL
                sta actMB,x
                jsr FallingMotionCommon
                lda actMB,x
                and #MB_HITWALL|MB_STARTFALLING
                beq MoveArmadillo_NoWall
                lda actSX,x
                eor #$80
                sta actD,x
                jsr StopXSpeed
MoveArmadillo_NoWall:
                rts
MoveArmadillo_TurnToWheel:
                ldy #ACTI_PLAYER
                jsr GetActorDistance
                lda temp5
                sta actD,x                      ;Turn to player when starting wheel mode
                jsr Random
                and #$3f
                adc #$20                        ;C=0
                sta actTime,x                   ;How long to stay in wheel mode
                lda #3
                sta actF1,x
                lda #$00
                sta actFd,x
                beq MoveArmadillo_IsWheel_NoAnim
MoveArmadillo_IsWheel:
                dec actTime,x
                beq MoveArmadillo_BackToWalking
                jsr CheckPlayerCollision         ;Apply damage to player when in wheel mode
                bcc MoveArmadillo_IsWheel_NoCollision
                lda #DMG_ARMADILLO
                jsr AddStrobedDamage
MoveArmadillo_IsWheel_NoCollision:
                lda actF1,x
                cmp #3
                bne MoveArmadillo_IsWheel_NoTransitionAnim
                inc actFd,x
                lda actFd,x
                cmp #$03
                bcc MoveArmadillo_IsWheel_NoAnim
MoveArmadillo_IsWheel_NoTransitionAnim:
                lda actSX,x
                clc
                adc actFd,x
                sta actFd,x
                lsr
                lsr
                lsr
                lsr
                lsr
                and #$03
                clc
                adc #$04
                sta actF1,x
                and #$01
                bne MoveArmadillo_IsWheel_NoAnim
                lda #SFX_LIFT
                jsr QueueSfx
MoveArmadillo_IsWheel_NoAnim:
                ldy #4*8
                jmp MoveArmadillo_MoveCommon
MoveArmadillo_BackToWalking:
                lda #$00
                sta actF1,x
                jmp MoveArmadillo_Walking2

        ; Spike mine move routine
        ;
        ; Parameters: X:Actor index
        ; Returns: -
        ; Modifies: A,Y,temp vars

MoveMine:       lda actFlash,x
                bne MoveMine_InitDone
                ldy zoneNum
                lda lvlZoneBg3,y                ;Copy zone color to sprite
                sta actFlash,x
                lda actT,x
                cmp #ACT_TREEMINE
                bne MoveMine_NotTree            ;Position treemine slightly to the left
                lda #$20
                sta actXL,x
                bne MoveMine_InitDone
MoveMine_NotTree:
                cmp #ACT_FLOORMINE
                bne MoveMine_InitDone
                lda #MB_GROUNDED                ;Mark floormine grounded for linecheck
                sta actMB,x
MoveMine_InitDone:
                lda actTime,x
                bne MoveMine_Prepare
                lda actFlags,x                  ;Do not explode before has line of sight
                and #AF_HASLINE
                beq MoveMine_TooFar
                ldy #ACTI_PLAYER
                jsr GetActorDistance_LeadTarget
                lda #6
                sta temp1
                lda actT,x                      ;Floor mine shouldn't explode early
                cmp #ACT_FLOORMINE
                bne MoveMine_NotFloor
                dec temp1
                lda temp7
                bmi MoveMine_NotFloor
MoveMine_NotFloor:
                lda temp6
                cmp temp1
                bcs MoveMine_TooFar
                lda temp8
                cmp temp1
                bcc MoveMine_BeginPrepare
MoveMine_TooFar:lda #2
                ldy #7
                jmp LoopingAnimation
DestroyMineWithSpawn:
                ldy #ACTI_PLAYER
                jsr GetActorDistance
                jsr GetBlockInfo
                ldy #0
                and #BI_WALL
                bne DestroyMine_FireDirOK       ;If inside floor, *must* fire up
                lda temp7
                bmi DestroyMine_FireDirOK
                iny
                iny
                cmp #3
                bcc DestroyMine_FireDirOK
                iny
                iny
DestroyMine_FireDirOK:
                jsr DestroyMine_SpawnSpike
                iny
                jsr DestroyMine_SpawnSpike
DestroyMine:    jmp ExplodeActor
MoveMine_BeginPrepare:
                lda #SFX_TREEMINE
                jsr QueueSfx
MoveMine_Prepare:
                lda #0
                ldy #3
                jsr LoopingAnimation
                inc actTime,x
                lda actTime,x
                cmp #10
                bcs DestroyMineWithSpawn
                rts

DestroyMine_SpawnSpike:
                sty wpnLo
                jsr GetFreePersistentActor
                bcc DestroyMine_SpawnSpikeFail
                lda #ACT_SPIKE
                jsr SpawnActor
                jsr InitSpawnedActor
                ldy wpnLo
                lda spikeSpdXTbl,y
                sta actSX,x
                sta actD,x
                lda spikeSpdYTbl,y
                sta actSY,x
                tya
                lsr
                sta actF1,x
                ldx actIndex
DestroyMine_SpawnSpikeFail:
                rts

        ; Spike move routine
        ;
        ; Parameters: X:Actor index
        ; Returns: -
        ; Modifies: A,Y,temp vars

MoveSpike:      lda actSX,x
                jsr MoveActorX
                lda actSY,x
                jsr MoveActorY
                lda actXH,x
                cmp mapSizeX
                bcs MoveSpike_NoWall
                jsr GetBlockInfo
                tay
                and #BI_WALL
                beq MoveSpike_NoWall
                tya
                jsr CheckInsideSlope
                bcs MoveSpike_HitWall
MoveSpike_NoWall:
                jsr CheckBulletCollision
                bcc MoveSpike_NoCollision
                lda #DMG_SPIKE
                jsr AddDamage
                jmp MoveSpike_HitWall_NoSound
MoveSpike_HitWall:
                lda #SFX_OPERATE
                jsr QueueSfx
MoveSpike_HitWall_NoSound:
                lda #ACT_SMOKETRAIL
                jmp TransformActor
MoveSpike_NoCollision:
                rts

        ; Spider move routine
        ;
        ; Parameters: X:Actor index
        ; Returns: -
        ; Modifies: A,Y,temp vars

MoveSpider_Dead:
                jmp MoveFly_Dead
MoveSpider:     lda actHp,x
                beq MoveSpider_Dead
                lda actFall,x
                bne MoveSpider_Initialized
                jsr GetPlayerFaceDirection
                sta actD,x
                inc actFall,x
MoveSpider_Initialized:
                lda actTime,x
                ora actSY,x
                bne MoveSpider_Walk
MoveSpider_Stand:
                lda #$00
                sta actF1,x
                lda #8
                jsr BrakeActorX
                jsr Random
                cmp #$0a
                bcs MoveSpider_Common
                asl
                asl
                asl
                adc #$08
                sta actTime,x               ;Walk timer
                jsr GetPlayerFaceDirection
                sta actD,x                  ;Always turn to player when start to walk
                jmp MoveSpider_Common
MoveSpider_Walk:
                lda actInWater,x                ;Water braking before movement
                beq MoveSpider_NotInWater
                jsr DoWaterBraking
MoveSpider_NotInWater:
                dec actTime,x
                lda actD,x
                asl
                lda #12
                ldy #4*8
                jsr AccActorXNegOrPos
                lda #0
                ldy #2
                jsr LoopingAnimation
                lda actMB,x
                bpl MoveSpider_Common
                jsr Random
                cmp #$04                    ;When on ground, random chance to jump
                bcs MoveSpider_Common
                jmp MoveSpider_StartJump
MoveSpider_Common:
                ldy #-1
                lda #6
                jsr MoveAndUpdateInWater
                lda actMB,x
                and #MB_HITWALL
                beq MoveSpider_NoWall
                lda actD,x
                eor #$80
                sta actD,x
                jsr StopXSpeed
MoveSpider_NoWall:
                lda actMB,x
                bmi MoveSpider_OnGround
                and #MB_STARTFALLING
                beq MoveSpider_NoStartFall
MoveSpider_StartJump:
                lda #$00
                sta actMB,x
                lda #-6*8
                sta actSY,x                 ;Always jump if falling
MoveSpider_NoStartFall:
                lda #3
                sta actF1,x                 ;Jump frame
MoveSpider_OnGround:
                jsr CheckPlayerCollision
                bcc MoveSpider_NoCollision
                lda #DMG_SPIDER
                jsr AddStrobedDamage
                lda #8
                sta actTime,x               ;Always walk after hitting
MoveSpider_NoCollision:
                rts

        ; Spitting spider move routine
        ;
        ; Parameters: X:Actor index
        ; Returns: -
        ; Modifies: A,Y,temp vars

MoveSpitSpider: lda actHp,x
                bne MoveSpitSpider_Alive
                jmp MoveFly_Dead
MoveSpitSpider_Alive:
                lda actFall,x
                bne MoveSpitSpider_Initialized
                jsr GetPlayerFaceDirection
                sta actD,x
                inc actFall,x
MoveSpitSpider_InitCommon:
                lda #5
                sta actFlash,x              ;Green color override
                lda #WPN_BOUNCE             ;Give score bonus, though the weapon isn't used
                sta actWpn,x
                rts
MoveSpitSpider_Initialized:
                lda actAttackD,x
                beq MoveSpitSpider_CanShoot
                dec actAttackD,x
MoveSpitSpider_NoShoot:
                jmp MoveSpider_Initialized
MoveSpitSpider_CanShoot:
                ldy #ACTI_PLAYER
                jsr GetActorDistance
                lda temp5
                eor actD,x
                bmi MoveSpitSpider_NoShoot
                lda temp6
                beq MoveSpitSpider_NoShoot
                cmp #8
                bcs MoveSpitSpider_NoShoot
                lda temp8
                cmp #3
                bcs MoveSpitSpider_NoShoot
                lda #6*8
                jsr SpawnSpitBall
                bcc MoveSpitSpider_NoShoot
                lda #-4*8
                sta actSY,x
                ldx actIndex
                jmp MoveSpider_Initialized

                brk                         ;Stop code relocation, only data will follow

flyYSpdTbl:     dc.b 0,20,40,20,0,-20,-40,-20

spikeSpdXTbl:   dc.b -6*8,6*8,-7*8,7*8,-6*8,6*8
spikeSpdYTbl:   dc.b -6*8,-6*8,0,0,6*8,6*8

ALFly:          dc.w USESCRIPT+EP_MoveFly       ;Update routine
                dc.b GRP_CREATURES|AF_TAKEDAMAGE  ;Actor flags
                dc.b 3                          ;Horizontal size
                dc.b 5                          ;Size up
                dc.b 2                          ;Size down
                dc.b HP_FLY                     ;Initial health
                dc.b NO_MODIFY                  ;Damage modifier
                dc.w USESCRIPT+EP_DestroyFly   ;Destroy routine

ALSpitFly:      dc.w USESCRIPT+EP_MoveSpitFly   ;Update routine
                dc.b GRP_CREATURES|AF_TAKEDAMAGE  ;Actor flags
                dc.b 3                          ;Horizontal size
                dc.b 5                          ;Size up
                dc.b 2                          ;Size down
                dc.b HP_SPITFLY                 ;Initial health
                dc.b NO_MODIFY                  ;Damage modifier
                dc.w USESCRIPT+EP_DestroyFly    ;Destroy routine

ALSpitBall:     dc.w USESCRIPT+EP_MoveSpitBall  ;Update routine
                dc.b GRP_CREATURES              ;Actor flags
                dc.b 2                          ;Horizontal size
                dc.b 2                          ;Size up
                dc.b 2                          ;Size down

ALArmadillo:    dc.w USESCRIPT+EP_MoveArmadillo ;Update routine
                dc.b GRP_CREATURES|AF_GROUNDBASED|AF_TAKEDAMAGE  ;Actor flags
                dc.b 6                          ;Horizontal size
                dc.b 7                          ;Size up
                dc.b 0                          ;Size down
                dc.b HP_ARMADILLO               ;Initial health
                dc.b NO_MODIFY                  ;Damage modifier
                dc.w USESCRIPT+EP_DestroyFly    ;Destroy routine

ALMine:         dc.w USESCRIPT+EP_MoveMine      ;Update routine
                dc.b GRP_NEUTRAL|AF_TAKEDAMAGE|AF_LINECHECK  ;Actor flags
                dc.b 4                          ;Horizontal size
                dc.b 3                          ;Size up
                dc.b 3                          ;Size down
                dc.b HP_MINE                    ;Initial health
                dc.b NO_MODIFY                  ;Damage modifier
                dc.w USESCRIPT+EP_DestroyMine   ;Destroy routine

ALSpike:        dc.w USESCRIPT+EP_MoveSpike     ;Update routine
                dc.b GRP_NEUTRAL                ;Actor flags
                dc.b 2                          ;Horizontal size
                dc.b 1                          ;Size up
                dc.b 1                          ;Size down

ALSpider:       dc.w USESCRIPT+EP_MoveSpider    ;Update routine
                dc.b GRP_CREATURES|AF_GROUNDBASED|AF_TAKEDAMAGE  ;Actor flags
                dc.b 6                          ;Horizontal size
                dc.b 5                          ;Size up
                dc.b 0                          ;Size down
                dc.b HP_SPIDER                  ;Initial health
                dc.b NO_MODIFY                  ;Damage modifier
                dc.w USESCRIPT+EP_DestroyFly    ;Destroy routine

ALSpitSpider:   dc.w USESCRIPT+EP_MoveSpitSpider ;Update routine
                dc.b GRP_CREATURES|AF_GROUNDBASED|AF_TAKEDAMAGE  ;Actor flags
                dc.b 6                          ;Horizontal size
                dc.b 6                          ;Size up
                dc.b 0                          ;Size down
                dc.b HP_SPITSPIDER              ;Initial health
                dc.b NO_MODIFY                  ;Damage modifier
                dc.w USESCRIPT+EP_DestroyFly    ;Destroy routine

ADFly:          dc.b ONESPRITE                  ;Number of sprites
                dc.b C_ENEMIES0                 ;Spritefile number
                dc.b 2                          ;Left frame add
                dc.b 4                          ;Number of frames
                dc.b 0,1
                dc.b $80+0,$80+1

ADSpitBall:     dc.b ONESPRITE               ;Number of sprites
                dc.b C_ENEMIES0                 ;Spritefile number
                dc.b 0                          ;Left frame add
                dc.b 3                          ;Number of frames
                dc.b 2,3,4

ADArmadillo:    dc.b ONESPRITE               ;Number of sprites
                dc.b C_ENEMIES0                 ;Spritefile number
                dc.b 8                          ;Left frame add
                dc.b 16                         ;Number of frames
                dc.b 5,6,7,8,9,10,11,12
                dc.b $80+5,$80+6,$80+7,8,9,10,11,12

ADTreeMine:     dc.b ONESPRITE               ;Number of sprites
                dc.b C_ENEMIES0                 ;Spritefile number
                dc.b 0                          ;Left frame add
                dc.b 8                          ;Number of frames
                dc.b 13,14,15,14,13,13,13,13

ADCeilingMine:  dc.b ONESPRITE               ;Number of sprites
                dc.b C_ENEMIES0                 ;Spritefile number
                dc.b 0                          ;Left frame add
                dc.b 8                          ;Number of frames
                dc.b 16,17,18,17,16,16,16,16

ADFloorMine:    dc.b ONESPRITE               ;Number of sprites
                dc.b C_ENEMIES0                 ;Spritefile number
                dc.b 0                          ;Left frame add
                dc.b 8                          ;Number of frames
                dc.b 19,20,21,20,19,19,19,19

ADSpike:        dc.b ONESPRITE               ;Number of sprites
                dc.b C_ENEMIES0                 ;Spritefile number
                dc.b 3                          ;Left frame add
                dc.b 6                          ;Number of frames
                dc.b 22,23,24
                dc.b $80+22,$80+23,$80+24

ADSpider:       dc.b ONESPRITE                  ;Number of sprites
                dc.b C_ENEMIES0                 ;Spritefile number
                dc.b 4                          ;Left frame add
                dc.b 8                          ;Number of frames
                dc.b 25,26,27,28
                dc.b $80+25,$80+26,$80+27,$80+28

                rend

scriptEnd: