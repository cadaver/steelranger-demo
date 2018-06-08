MB_LANDED       = $01
MB_STARTFALLING = $02
MB_HITWALL      = $04
MB_HITCEILING   = $08
MB_PREVENTFALL  = $10
MB_ONLIFT       = $40
MB_GROUNDED     = $80

BI_GROUND       = 1
BI_WALL         = 2
BI_CLIMB        = 4
BI_WATER        = 8
BI_LIFTSHAFT    = 16
BI_NOZONECHANGE = 16
BI_LIFTSTOP     = 128
BI_SLOPE        = 32+64+128
BI_CONVEYOR     = 16+32+64+128

COMMON_ACCEL   = 4
COMMON_MAX_YSPEED = 8*8

        ; Accelerate flying enemy
        ;
        ; Parameters: X actor index
        ; Returns: temp5 last blockinfo (after X-move, after backing out of wall if necessary)
        ; Modifies: A,Y,temp vars,loader temp vars

AccelerateFlyer:ldy #AL_ACCELERATION
                lda (actLo),y
                sta temp1
                lda actMoveCtrl,x
                and #JOY_LEFT|JOY_RIGHT
                beq AF_NoHorizAccel
                cmp #JOY_LEFT
                beq AF_AccelLeft
                clc
AF_AccelLeft:   ldy #AL_MAXSPEED
                lda (actLo),y
                tay
                lda temp1
                jsr AccActorXNegOrPos
AF_NoHorizAccel:lda actMoveCtrl,x
                and #JOY_UP|JOY_DOWN
                beq AF_NoVertAccel
                cmp #JOY_UP
                beq AF_AccelUp                 ;C=1 accelerate up (negative)
                clc
AF_AccelUp:     ldy #AL_MAXSPEEDVERT
                lda (actLo),y
                tay
                lda temp1
                jsr AccActorYNegOrPos
AF_NoVertAccel: rts

        ; Move flying enemy, but not into walls
        ;
        ; Parameters: X actor index
        ; Returns: temp5 last blockinfo (after X-move, after backing out of wall if necessary)
        ; Modifies: A,Y,temp vars,loader temp vars

MoveFlyer:      lda actSY,x
                beq MF_NoVertMove
                jsr MoveActorY
                jsr GetBlockInfo
                and #BI_WALL
                beq MF_NoHitWallVertical
                lda actSY,x
                jsr MoveActorYNeg
                lda #MB_HITCEILING
                skip2
MF_NoHitWallVertical:
MF_NoVertMove:
                lda #$00
                sta actMB,x
                lda actSX,x
                beq MF_NoHorizMove
                jsr MoveActorX
                jsr GetBlockInfo
                sta temp5
                and #BI_WALL
                beq MF_NoHitWallHorizontal
                lda actSX,x
                jsr MoveActorXNeg
                lda actMB,x
                ora #MB_HITWALL
                sta actMB,x
                jsr GetBlockInfo
                sta temp5
MF_NoHitWallHorizontal:
MF_NoHorizMove:
                rts

MWG_HitWall:    lda actXL,x
                sec
                sbc actSX,x
                bpl MWG_HitWallCommon
                ldy actSX,X
                bpl MWG_HitWallRight
                inc actXH,x
                lda #$00
                beq MWG_HitWallCommon
MWG_HitWallRight:
                dec actXH,x
                lda #$7f
MWG_HitWallCommon:
                sta actXL,x                     ;Check for backing away into a sloped wall
                lda actMB,x                     ;(special case landing)
                bmi MWG_HitWallNoLanding
                jsr GetBlockInfo
                tay
                and #BI_WALL
                beq MWG_HitWallNoLanding
                tya
                lsr
                and #BI_SLOPE/2
                beq MWG_HitWallNoLanding
                sta temp6
                lda actXL,x
                lsr
                lsr
                lsr
                ora temp6
                tay
MWG_Landed2:    lda slopeTbl,y                  ;Special case landing: X-move already performed
                sta actYL,x
                lda #$00
                sta actSY,x
                lda #MB_GROUNDED|MB_LANDED
                bne MWG_HitWallStoreMB
MWG_HitWallNoLanding:
                lda actMB,x
                ora #MB_HITWALL
MWG_HitWallStoreMB:
                sta actMB,x
                rts

MWG_InAirNoXSpeed:
                jsr GetBlockInfo                ;If no X-speed, nevertheless get blockinfo at feet
                sta temp5                       ;for UpdateInWater etc.
                rts

MWG_InAirUp:    jsr MoveActorY
                lda temp7
                jsr GetBlockInfoOffset
                and #BI_WALL
                beq MWG_InAirXMove
                lda actSY,x                     ;If hit ceiling, move back & clear speed
                jsr MoveActorYNeg
                lda #$00
                sta actSY,x
                lda #MB_HITCEILING
                skip2
MWG_InAirXMove: lda #$00
                sta actMB,x
                lda actSX,x
                beq MWG_InAirNoXSpeed
                jsr MoveActorX
                lda temp7                       ;Check for high wall while in the air
                jsr CheckHighWall
                lda temp5
                lsr                             ;Check slope before hitting wall
                and #BI_SLOPE/2
                beq MWG_InAirNoSlope
                sta temp6
                lda actXL,x
                lsr
                lsr
                lsr
                ora temp6
                tay
                lda actYL,x
                cmp slopeTbl,y
                bcc MWG_InAirXMoveDone
MWG_InAirCheckSlopeDir:
                lda actSY,x
                bmi MWG_InAirNoSlope
                lda temp5                       ;Check that is going "into" the slope
                and #BI_SLOPE                   ;and land in that case
                cmp #$80
                beq MWG_InAirNoSlope            ;The half height block cannot be landed into
                eor actSX,x
                bpl MWG_Landed2
MWG_InAirNoSlope:
                lda temp5
                and #BI_WALL
                beq MWG_InAirXMoveDone
                jmp MWG_HitWall
MWG_InAirXMoveDone:
                rts

        ; Move actor with common gravity & assume it's only one tile tall
        ;
        ; Parameters: X actor index
        ; Returns: temp5 last blockinfo, either from position (when in air) or above feet (when on ground)
        ; Modifies: A,Y,temp vars,loader temp vars

FallingMotionCommon:
                ldy #0                         ;Ceiling check offset
                lda #COMMON_ACCEL

        ; Move actor with gravity / collisions
        ;
        ; Parameters: X actor index, A acceleration, Y head bump height (should be negative = up)
        ; Returns: temp5 last blockinfo, either from position (when in air) or above feet (when on ground)
        ; Modifies: A,Y,temp vars,loader temp vars

MoveWithGravity:sty temp7
                ldy actMB,x
                bpl MWG_InAir
                jmp MWG_Grounded
MWG_InAir:      ldy #COMMON_MAX_YSPEED          ;Gravity acceleration
                jsr AccActorY
                lda actSY,x
                bmi MWG_InAirUp
MWG_InAirDown:  clc
                adc actYL,x                     ;Check for block crossing first
                bpl MWG_InAirDownNoCross
                jsr GetBlockInfo
                sta temp5
                lsr
                and #BI_SLOPE/2
                beq MWG_InAirDownNoCross        ;Not necessary for slope0
                sta temp6
                lda actXL,x
                lsr
                lsr
                lsr
                ora temp6
                tay
                lda slopeTbl,y
                cmp actYL,x
                bcs MWG_Landed                  ;If is above or at the slope before Y-move, would land
MWG_InAirDownNoCross:
                lda actSY,x
                jsr MoveActorY
                jsr GetBlockInfo
                lsr
                bcc MWG_NoLanding
                and #BI_SLOPE/2
                beq MWG_Slope0                  ;Optimization for slope0
                sta temp6
                lda actXL,x
                lsr
                lsr
                lsr
                ora temp6
                tay
                asl
                eor actSX,x                     ;Check if going into the slope, and add X-speed
                bmi MWG_NotIntoSlope            ;to prevent through blocks diagonally
                lda actSX,x
                bpl MWG_GoingRight
                sec
                eor #$ff                        ;Add one more for proper two's complement
MWG_GoingRight: adc actYL,x
                jmp MWG_IntoSlope
MWG_Slope0:     tay
MWG_NotIntoSlope:
                lda actYL,x
MWG_IntoSlope:  cmp slopeTbl,y
                bcc MWG_NoLanding
MWG_BelowSlope: lda actYL,x
                sbc actSY,x                     ;Verify that was above or at the slope first
                bcc MWG_Landed
                cmp slopeTbl,y
                beq MWG_Landed
                bcs MWG_NoLanding
MWG_Landed:     lda slopeTbl,y
                sta actYL,x
                lda #$00
                sta actSY,x
                lda #MB_GROUNDED|MB_LANDED
                bne MWG_GroundedStoreMB
MWG_NoLanding:  jmp MWG_InAirXMove

MWG_GroundedNoXSpeed:
                lda #-1                         ;When not moving, nevertheless get blockinfo to temp5
                jsr GetBlockInfoOffset          ;for UpdateInWater etc.
                sta temp5
                jmp MWG_GroundedNoWall          ;Be prepared to fall even if not moving (ground blown up directly underneath..)
MWG_GroundedOnLift:
                lda actYL,x                     ;If riding a lift, and not at the top of a tile,
                beq MWG_GroundedOnLiftNoWall    ;check collision also at feet to avoid falling
                jsr GetBlockInfo
                and #BI_WALL
                beq MWG_GroundedOnLiftNoWall
                jmp MWG_HitWall
MWG_GroundedOnLiftNoWall
                rts

MWG_Grounded:   sty MWG_GroundedOldMB+1
                lda #MB_GROUNDED
MWG_GroundedStoreMB:
                sta actMB,x
                lda actSX,x
                beq MWG_GroundedNoXSpeed
                jsr MoveActorX
                lda temp7                       ;Check for running into a wall that is only
                cmp #-2                         ;passable in wheel form
                bne MWG_NoHighWallCheck
                jsr GetBlockInfoOffset
                and #BI_WALL
                bne MWG_GroundedWall
MWG_NoHighWallCheck:
                lda #-1
                jsr GetBlockInfoOffset
                sta temp5
                and #BI_WALL
                beq MWG_GroundedNoWall
                lda temp5
                and #BI_SLOPE
                beq MWG_GroundedWall2
                cmp #$80                        ;Half-slope not considered as an obstacle
                beq MWG_GroundedNoWall
                eor actSX,x
                bpl MWG_GroundedNoWall          ;Going "into" the slope = no wallhit
MWG_GroundedWall2:
                lda #BI_WALL
MWG_GroundedWall:
                sta temp5
                jsr MWG_HitWall                 ;Back out of wall
MWG_GroundedNoWall:
MWG_GroundedOldMB:
                lda #$00                        ;Check if was standing on a lift last frame
                asl
                bmi MWG_GroundedOnLift
                jsr GetBlockInfo                ;Check if has ground
                lsr
                bcc MWG_GroundedNotLevel
                and #BI_SLOPE/2
                bne MWG_GroundedSlopeCommon2
MWG_GroundedLevelSlope0:
                ldy actYL,x                     ;If significantly below, do not climb to slope0
                cpy #$41                        ;on the same level
                bcc MWG_GroundedSlope0
                bcs MWG_GroundedNotLevel
MWG_GroundedSlopeCommon:
                and #BI_SLOPE/2
                beq MWG_GroundedSlope0
MWG_GroundedSlopeCommon2:
                sta temp6
                lda actXL,x
                lsr
                lsr
                lsr
                ora temp6
                tay
                lda slopeTbl,y
MWG_GroundedSlope0:
                sta actYL,x
                rts
MWG_GroundedNotLevel:
                lda actYL,x
                cmp #$40
                bcc MWG_GroundedNotBelow
                lda #1
                jsr GetBlockInfoOffset
                lsr
                bcc MWG_GroundedNotBelow
                inc actYH,x
                bcs MWG_GroundedSlopeCommon
MWG_GroundedNotBelow:
                lda actMB,x                     ;If didn't hit wall, we already have blockinfo from above
                and #MB_HITWALL
                beq MWG_GroundedNoRecheck
                lda #-1
                jsr GetBlockInfoOffset
                skip2
MWG_GroundedNoRecheck:
                lda temp5
MWG_GroundedRecheckDone:
                lsr
                bcc MWG_GroundedStartFalling
                and #BI_SLOPE/2                 ;If the ground above is not sloped, do not climb to it
                beq MWG_GroundedStartFalling
                dec actYH,x
                bcs MWG_GroundedSlopeCommon2
MWG_GroundedStartFalling:
                lda #MB_STARTFALLING
                sta actMB,x
                lda MWG_GroundedOldMB+1
                and #MB_PREVENTFALL
                bne MWG_PreventFall
MWG_GroundedDone:
                rts
MWG_PreventFall:lda actSX,x
                jsr MoveActorXNeg
                lda actMB,x
                ora #MB_GROUNDED
                sta actMB,x
                rts

        ; Move actor with common gravity & assume it's only one tile tall, allow to go outside level
        ;
        ; Parameters: X actor index
        ; Returns: temp5 last blockinfo, either from position (when in air) or above feet (when on ground)
        ; Modifies: A,Y,temp vars,loader temp vars

FallingMotionCommon_GoOutside:
                lda #$00
                sta GBI_Outside+1
                jsr FallingMotionCommon
                lda #BI_WALL
                sta GBI_Outside+1
                rts

        ; Negate and halve X-speed
        ;
        ; Parameters: X actor index
        ; Returns: -
        ; Modifies: A
        
BounceXSpeed:   lda actSX,x
                jsr Negate8Asr8
                sta actSX,x
                rts

        ; Update whether actor is in water, and create splash if possible/necessary
        ;
        ; Parameters: X actor index, temp5 blockinfo from MoveWithGravity
        ; Returns: -
        ; Modifies: A,Y

MoveAndUpdateInWater:
                jsr MoveWithGravity
                lda actMB,x
                and #MB_HITWALL+MB_LANDED       ;Hit wall (and didn't land at the same time)?
                cmp #MB_HITWALL
                bne UIW_NoStopSpeed
                jsr StopXSpeed
UIW_NoStopSpeed:
UpdateInWater:  lda temp5                       ;Check for entering water & creating splash
                and #BI_WALL
                bne UIW_DoNothing               ;Do nothing if last result is inside wall
                lda temp5
                and #BI_WATER
                beq UIW_NotInWater
                cmp actInWater,x
                beq UIW_NoSplash
                jsr GetFreePersistentActor
                bcc UIW_NoSplash
                lda #ACT_LARGESPLASH
                jsr SpawnActor
                tya
                tax
                jsr SetSplashPosition
                ldx actIndex
                lda #BI_WATER
UIW_NotInWater: sta actInWater,x
UIW_DoNothing:
UIW_NoSplash:   lda actMB,x                     ;Special case: moving on conveyor
                bpl UIW_NoConveyor
                lda temp5
                cmp #BI_CONVEYOR
                bne UIW_NoConveyor
                lda #-1*8
                jsr MoveActorX
UIW_NoConveyor: rts

        ; Water braking
        ;
        ; Parameters: X actor index
        ; Returns: -
        ; Modifies: A,y

DoWaterBraking: lda #WATER_YBRAKING
                jsr BrakeActorY
                lda #WATER_XBRAKING
                jsr BrakeActorX
                lda actSX,x
                bpl DWB_WaterSpeedPos
                cmp #-WATER_MAX_XSPEED
                bcs DWB_WaterBrakeDone
                lda #-WATER_MAX_XSPEED
DWB_WaterBrakeStoreX:
                sta actSX,x
DWB_WaterBrakeDone:
                rts
DWB_WaterSpeedPos:
                cmp #WATER_MAX_XSPEED
                bcc DWB_WaterBrakeDone
                lda #WATER_MAX_XSPEED
                bne DWB_WaterBrakeStoreX

        ; Set splash actor position at water top edge. If the actor is a large splash, play sound
        ;
        ; Parameters: X actor index
        ; Returns: -
        ; Modifies: A,y

SetSplashPosition:
                lda #-1
                jsr GetBlockInfoOffset
                and #BI_WATER
                beq SSP_WaterTopFound
                dec actYH,x
                bne SetSplashPosition
SSP_WaterTopFound:
                sta actYL,x
                lda waterColorOverride
                sta actFlash,x
                lda actT,x
                cmp #ACT_LARGESPLASH
                bne SSP_NoSound
                lda #SFX_SPLASH
                jmp QueueSfx
SSP_NoSound:    rts

        ; Return blockinfo from actor's position with both X & Y offsets
        ;
        ; Parameters: X actor index, A signed Y offset, Y signed X offset

GetBlockInfoOffsetXY:
                sty GBIOXY_XOffset+1
                clc
                adc actYH,x
                tay
                cpy mapSizeY
                bcs GBI_Outside
                lda mapTblLo,y
                sta zpSrcLo
                lda mapTblHi,y
                sta zpSrcHi
                lda actXH,x
GBIOXY_XOffset: adc #$00                        ;C always 0
                tay
                jmp GBI_Common2

        ; Return blockinfo from actor's position with offset
        ;
        ; Parameters: X actor index, A signed Y offset
        ; Returns: A block info
        ; Modifies: Y, loader temp regs

GetBlockInfoOffset:
                clc
                adc actYH,x
                tay
                jmp GBI_Common

        ; Return blockinfo from actor's position
        ;
        ; Parameters: X actor index
        ; Returns: A block info
        ; Modifies: Y, loader temp regs

GetBlockInfo:   ldy actYH,x
GBI_Common:     cpy mapSizeY
                bcs GBI_Outside
                lda mapTblLo,y
                sta zpSrcLo
                lda mapTblHi,y
                sta zpSrcHi
                ldy actXH,x
GBI_Common2:    cpy mapSizeX
                bcs GBI_Outside
                lda (zpSrcLo),y
                tay
                lda blkInfo,y
                rts
GBI_Outside:    lda #BI_WALL
                rts

        ; Check for high wall until reach offset zero
        ;
        ; Parameters: X actor index, A starting offset
        ; Returns: Z=1 if no wallhit, temp5 last blockinfo (if detected above offset 0, has slopebits removed)
        ; Modifies: Y, loader temp regs, temp5 temp8

CheckHighWall:  sta temp8
                clc
                adc actYH,x
                cmp mapSizeY
                bcs CHW_Outside
                tay
                lda mapTblLo,y
                sta zpSrcLo
                lda mapTblHi,y
                sta zpSrcHi
                ldy actXH,x
                cpy mapSizeX
                bcs CHW_Outside
CHW_Loop:       lda (zpSrcLo),y
                tay
                lda blkInfo,y
                ldy temp8
                beq CHW_Done
                and #BI_WALL
                bne CHW_Done
                inc temp8
                lda zpSrcLo
                adc mapSizeX
                sta zpSrcLo
                ldy actXH,x
                bcc CHW_Loop
                inc zpSrcHi
                clc
                bcc CHW_Loop
CHW_Outside:    lda GBI_Outside+1
CHW_Done:       sta temp5                       ;Store last blockinfo to temp5,
                and #BI_WALL                    ;without slopebits if was from higher
                rts

        ; Check whether actor is inside (below) slope
        ;
        ; Parameters: X actor index, A blockinfo from slope block
        ; Returns: C=1 if inside
        ; Modifies: Y, temp6

CheckInsideSlope:
                lsr
                sta temp6
                lda actXL,x
                lsr
                lsr
                lsr
                ora temp6
                tay
                lda actYL,x
                cmp slopeTbl,y
                rts
