SPLASH_DAMAGE_RADIUS = 8
WHEELMINE_DAMAGE_RADIUS = 10

        ; Small water splash update routine
        ;
        ; Parameters: X actor index
        ; Returns: -
        ; Modifies: A,Y

MoveSmallSplash:ldy #3
                skip2

        ; Smoketrail update routine
        ;
        ; Parameters: X actor index
        ; Returns: -
        ; Modifies: A,Y

MoveSmokeTrail: ldy #1
                lda #0
                beq OneShotAnimateAndRemove

        ; Explosion / large water splash update routine
        ;
        ; Parameters: X actor index
        ; Returns: -
        ; Modifies: A,Y

MoveLargeSplash:
MoveExplosion:  ldy #4
                lda #1
OneShotAnimateAndRemove:
                jsr OneShotAnimation
                bcs MMH_Remove
                rts
MMH_Remove:     jmp RemoveActor

        ; Bullet update routine with muzzle flash as first frame
        ;
        ; Parameters: X actor index
        ; Returns: -
        ; Modifies: A,Y

MoveBulletMuzzleFlash:
                lda actF1,x
                cmp #AIM_NUMDIRS*2
                bcs MoveBullet
                adc #AIM_NUMDIRS*2
                sta actF1,x
                jsr MoveBullet
                
        ; Disable actor interpolation for the current position
        ;
        ; Parameters: X actor index
        ; Returns: -
        ; Modifies: A

NoInterpolation:lda actXL,x
                sta actPrevXL,x
                lda actXH,x
                sta actPrevXH,x
                lda actYL,x
                sta actPrevYL,x
                lda actYH,x
                sta actPrevYH,x
                rts

        ; Apply bullet damage to target and remove bullet
        ;
        ; Parameters: X actor index, Y collided actor index
        ; Returns: -
        ; Modifies: A,Y

ApplyDamageAndRemove:
                lda actHp,x
                jsr AddDamage
                jmp MProj_Remove

        ; Flame update routine
        ;
        ; Parameters: X actor index
        ; Returns: -
        ; Modifies: A,Y

MoveFlame:      lda #2
                ldy #3
                jsr OneShotAnimation            ;Intentional fall through
                bcs MProj_Remove

        ; Bullet update routine.
        ;
        ; Parameters: X actor index
        ; Returns: -
        ; Modifies: A,Y

MoveElectricity:lda actHp,x                     ;Reduce the most extremely upgraded arcgun damage to 4 pts
                cmp #$85
                bne MoveBullet
                dec actHp,x
MoveBullet:     jsr CheckBulletCollision
                bcs ApplyDamageAndRemove
MoveBullet_NoCollision:
                dec actTime,x
                bmi MProj_Remove

        ; Move projectile actor in a straight line, remove if goes outside
        ;
        ; Parameters: X actor index
        ; Returns: C=1 hit wall or was removed
        ;          C=0 no wall hit
        ; Modifies: A,Y,temp vars

MoveProjectile: lda actSX,x                     ;Replicate MoveActor / GetBlockInfo to avoid JSRs
                clc
                adc actXL,x
                bpl MProj_XMoveDone
                ldy actSX,x
                bmi MProj_XMoveLeft
                inc actXH,x
                bne MProj_XMoveMSBDone
MProj_XMoveLeft:dec actXH,x
MProj_XMoveMSBDone:
                and #$7f
MProj_XMoveDone:
                sta actXL,x
                lda actSY,x
MProj_CustomYSpeed:
                clc
                adc actYL,x
                bpl MProj_YMoveDone
                ldy actSY,x
                bmi MProj_YMoveUp
                inc actYH,x
                bne MProj_YMoveMSBDone
MProj_YMoveUp:  dec actYH,x
                bmi MProj_Remove
MProj_YMoveMSBDone:
                and #$7f
MProj_YMoveDone:
                sta actYL,x
                ldy actYH,x
                lda mapTblLo,y
                sta zpSrcLo
                lda mapTblHi,y
                sta zpSrcHi
                ldy actXH,x
                cpy mapSizeX
                bcs MProj_Remove
                lda (zpSrcLo),y
                tay
                lda blkInfo,y
                tay
                and #BI_WALL|BI_WATER
                beq MProj_NoWall
                cmp #BI_WATER
                beq MProj_HitWater
                tya
                jsr CheckInsideSlope
                bcs MProj_HitWall
MProj_NoWall:   rts                             ;C=0
MProj_Remove:   jsr RemoveActor
                sec
                rts
MProj_HitWater: cmp #ACT_GRENADE                ;Grenade,missile,heavy plasma = large splash
                lda #ACT_SMALLSPLASH
                adc #$00
                jsr MProj_Transform
                jsr SetSplashPosition
                sec
                rts
MProj_HitWall:  lda actT,x                      ;Special handling depending on actor type
                cmp #ACT_MISSILE
                beq MProj_Explode
                cmp #ACT_FLAME
                beq MProj_Flame
                cmp #ACT_BOUNCE
                bne MProj_NoBounce
                lda actF1,x
                beq MProj_DoBounce
DestroyBullet:
MProj_NoBounce: lda #COLOR_FLICKER
                sta actFlash,x
                lda #ACT_SMOKETRAIL
MProj_Transform:jsr TransformActor
                sec
                rts
MProj_Explode:  jsr ExplodeActorBreakWall
                sec
                rts
MProj_Flame:    jsr StopXSpeed                  ;Returns with A=0
                sta actSY,x
                lda #$10
                sta actFd,x
                rts                             ;C=1 here

MProj_DoBounce: inc actF1,x
                lda #2
                sta actSizeH,x
                sta actSizeU,x
                sta actSizeD,x
                dec actHp,x                     ;Damage reduced by 1 point after bounce
                lda #1                          ;For diagonal bounce, check if there's room
                ldy actSY,x                     ;in the negated Y-direction
                bmi MProj_BounceCheckBelow
                lda #-1
MProj_BounceCheckBelow:
                jsr GetBlockInfoOffset
                and #BI_WALL
                sta temp1
                lda actSX,x                     ;Back out of wall
                jsr Asr8                        ;Move only a half-step if possible
                sta temp2
                jsr MoveActorXNeg
                lda actSY,x
                jsr Asr8
                sta temp3
                jsr MoveActorYNeg
                jsr GetBlockInfo                ;Move another step if necessary
                and #BI_WALL
                beq MProj_BounceMoveOutOK
                lda temp2
                jsr MoveActorXNeg
                lda temp3
                jsr MoveActorYNeg
MProj_BounceMoveOutOK:
                lda actSY,x
                beq MProj_BounceHorizontal
                lda actSX,x
                beq MProj_BounceVertical
MProj_BounceDiagonal:
                lda temp1
                bne MProj_BounceDiagonalHorizontal
MProj_BounceDiagonalVertical:
                lda actSX,x
                jsr GetBounceSpeed
                sta actSX,x
MProj_BounceFlipVertical:
                lda actSY,x
                jsr GetBounceFlippedSpeed
                sta actSY,x
                rts
MProj_BounceDiagonalHorizontal:
                lda actSY,x
                jsr GetBounceSpeed
                sta actSY,x
MProj_BounceFlipHorizontal:
                lda actSX,x
                jsr GetBounceFlippedSpeed
                sta actSX,x
                rts
MProj_BounceHorizontal:
                jsr BounceAlternate
                sta actSY,x
                bne MProj_BounceFlipHorizontal
MProj_BounceVertical:
                jsr BounceAlternate
                sta actSX,x
                bne MProj_BounceFlipVertical

GetBounceFlippedSpeed:
                bmi GBS_Pos
                bpl GBS_Neg

BounceAlternate:lda #$00
                eor #$80
                sta BounceAlternate+1
GetBounceSpeed: bmi GBS_Neg
GBS_Pos:        lda #6*10
                rts
GBS_Neg:        lda #-6*10
                rts

        ; Laser update routine. 2 move steps
        ;
        ; Parameters: X actor index
        ; Returns: -
        ; Modifies: A,Y,temp vars

MoveLaser:      jsr CheckBulletCollision
                bcs MLaser_ApplyDamage
                jsr MoveProjectile
                bcs MLaser_Done
                jsr MoveBullet
MLaser_Done:    jmp NoInterpolation
MLaser_ApplyDamage:
                jmp ApplyDamageAndRemove

        ; Missile update routine
        ;
        ; Parameters: X actor index
        ; Returns: -
        ; Modifies: A,Y

MoveMissile:    lda actFlash,x
                eor #$08
                sta actFlash,x
                lda actTime,x
                lsr
                bcc MRckt_NoAccel
                cmp #16
                bcc MRckt_NoAccel
                ldy actF1,x
                lda missileAccelXTbl,y
                clc
                adc actSX,x
                sta actSX,x
                lda missileAccelYTbl,y
                clc
                adc actSY,x
                sta actSY,x
MRckt_NoAccel:  jsr CheckBulletCollision
                bcs ExplodeActorBreakWall
                jmp MoveBullet_NoCollision

        ; Grenade launcher grenade update routine
        ;
        ; Parameters: X actor index
        ; Returns: -
        ; Modifies: A,Y

MoveLauncherGrenade:
                lda #2
                ldy #2
                jsr LoopingAnimation
MoveGrenadeCommon:
                jsr CheckBulletCollision
                bcs ExplodeActorBreakWall
                jsr FallingMotionCommon_GoOutside
                lda actYH,x                     ;Remove if goes outside zone top border
                bmi MLG_Remove
                lda temp5
                and #BI_WATER
                bne MLG_HitWater
                lda actMB,x
                and #MB_HITWALL|MB_HITCEILING|MB_LANDED
                bne ExplodeActorBreakWall
                dec actTime,x
                bmi ExplodeActorBreakWall
                rts
MLG_HitWater:   lda #SFX_SPLASH
                jsr QueueSfx
                jmp MProj_HitWater
MLG_Remove:     jmp RemoveActor

        ; Break wall next to actor, then explode. Also do splash damage
        ;
        ; Parameters: X actor index
        ; Returns: A=0
        ; Modifies: A,Y,temp vars / loader temp vars

ExplodeActorBreakWall:
                lda #SPLASH_DAMAGE_RADIUS
EABW_CustomRadius:
                jsr ExpandActorBounds
EABW_NoExpand:  lda #<targetList
                sta EABW_Get+1
                bne EABW_Get
EABW_Next:      inc EABW_Get+1
EABW_Get:       ldy targetList
                bmi EABW_ActorsDone             ;Endmark?
                lda actFlags,x                  ;Same group = no collision
                eor actFlags,y
                and #AF_GROUPBITS
                beq EABW_Next
                jsr CheckActorCollision
                bcc EABW_Next
                lda actXL,y
                cmp actXL,x
                lda actXH,y
                sbc actXH,x
                bne EABW_ImpulseDirOK
                lda #1
EABW_ImpulseDirOK:
                sta actSX,x                     ;Get direction for impulse
                lda actHp,x
                jsr AddDamage
                jmp EABW_Next
EABW_ActorsDone:lda #<zoneObjIndex
                sta EABW_Loop+1
EABW_Loop:      ldy zoneObjIndex
                bmi EABW_Done                   ;Endmark?
                inc EABW_Loop+1
                lda lvlObjFlags,y
                cmp #OBJTYPE_WALL               ;Wall that has not been opened yet
                bne EABW_Loop
                lda lvlObjDL,y                  ;If databyte defined, check for exact X-location of hit
                beq EABW_NotExact               ;(one-sided openable doors, used in the computer vault)
                cmp actXH,x
                beq EABW_YOK
                bne EABW_Loop
EABW_NotExact:  lda lvlObjX,y
                beq EABW_XOK1
                sbc #$01                        ;C=1, remains 1
EABW_XOK1:      sta temp7                       ;X check left bound
                lda lvlObjSize,y
                and #$03
                adc lvlObjX,y
                sta temp8                       ;X check right bound
                lda actXH,x
                cmp temp7
                bcc EABW_Loop
                cmp temp8
                beq EABW_XOK2
                bcs EABW_Loop
EABW_XOK2:      jsr GetLevelObjectCenter
                lda temp8
                sbc actYH,x                     ;C=0 on return, subtract one more intentionally
                beq EABW_YOK
                cmp #$fe
                bcc EABW_Loop
EABW_YOK:       jsr ActivateObject              ;For now, only break 1 wall per explosion
                ;ldx actIndex                   ;Wall breaking should not trash X register
EABW_Done:

        ; Turn an actor into an explosion
        ;
        ; Parameters: X actor index
        ; Returns: A=0
        ; Modifies: A

ExplodeActor:   lda #SFX_EXPLOSION
                jsr QueueSfx
ExplodeActor_NoSound:
                jsr NoInterpolation
                lda #$00
                sta actFlash,x
                lda #ACT_EXPLOSION
TransformActor:
TransformBullet:sta actT,x
                lda #$00
                sta actFlags,x                  ;Whenever something is transformed, it shouldn't likely interact anymore
                sta actF1,x
                sta actFd,x
                rts

        ; Wheel mine update routine
        ;
        ; Parameters: X actor index
        ; Returns: -
        ; Modifies: A,Y

MoveWheelMine:  dec actTime,x
                bmi MWM_Explode
                lda actTime,x
                cmp #25-8
                bcs MWM_NoFlash
MWM_FlashFast:  lsr
                and #$03
                tay
                lda mineFlashTbl,y
                sta actFlash,x
                jsr CheckBulletCollision        ;Collide against enemies when waiting
                bcs MWM_Explode
MWM_NoFlash:    rts
MWM_Explode:    lda #2*8
                sta shakeScreen
                lda #WHEELMINE_DAMAGE_RADIUS
                jmp EABW_CustomRadius

        ; Check bullet collision against the target actor list (only one collision)
        ;
        ; Parameters: X bullet actor index
        ; Returns: C=1 collision occurred, actor in Y
        ; Modifies: A,Y

CheckBulletCollision:
                lda #<targetList
                sta CBC_Get+1
                clc
                bcc CBC_Get
CBC_Next:       inc CBC_Get+1
CBC_Get:        ldy targetList
                bmi CBC_AllDone                 ;Endmark?
                lda actFlags,x                  ;Same group = no collision
                eor actFlags,y
                and #AF_GROUPBITS
                beq CBC_Next
                lda actBoundR,y                 ;Skip if collision uninitialized on either actor
                beq CBC_Next
                lda actBoundR,x
                beq CBC_Next
                cmp actBoundL,y
                bcc CBC_Next
                lda actBoundR,y
                cmp actBoundL,x
                bcc CBC_Next
                lda actBoundD,x
                cmp actBoundU,y
                bcc CBC_Next
                lda actBoundD,y
                cmp actBoundU,x
                bcc CBC_Next
CBC_HasCollision:
CBC_AllDone:    rts
