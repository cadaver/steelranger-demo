                org $0000

                include macros.s
                include memory.s
                include mainsym.s

        ; Note! Code must be unambiguous! Relocated code cannot have skip1/skip2 -macros!

                dc.w scriptEnd-scriptStart  ;Chunk data size
                dc.b 22                     ;Number of objects

scriptStart:
                rorg scriptCodeRelocStart   ;Initial relocation address when loaded

                dc.w MoveDroid              ;$0300
                dc.w DestroyDroid           ;$0301
                dc.w MoveRobotMine          ;$0302
                dc.w DestroyRobotMine       ;$0303
                dc.w MoveFlyingCraft        ;$0304
                dc.w DestroyFlyingCraft     ;$0305
                dc.w MoveSquid              ;$0306
                dc.w MoveCreator            ;$0307
                dc.w MoveLift               ;$0308
                dc.w ALDroid                ;$0309
                dc.w ALRobotMine            ;$030a
                dc.w ALFlyingCraft          ;$030b
                dc.w ALEliteFlyingCraft     ;$030c
                dc.w ALSquid                ;$030d
                dc.w ALCreator              ;$030e
                dc.w ALLift                 ;$030f
                dc.w ADDroid                ;$0310
                dc.w ADRobotMine            ;$0311
                dc.w ADFlyingCraft          ;$0312
                dc.w ADSquid                ;$0313
                dc.w ADLift                 ;$0314
                dc.w ADCreator              ;$0315

        ; Security droid update routine
        ;
        ; Parameters: X:Actor index
        ; Returns: -
        ; Modifies: A,Y,temp vars

MoveDroid_Destroying:
                lda actSX,x                 ;Move droid in straight line without BG collisions when exploding
                jsr MoveActorX
                lda actSY,x
                jsr MoveActorY
                ldy #EXPL_7F_7F
                jmp GenerateExplosionsAndFlicker

MoveDroid:      lda actHp,x
                beq MoveDroid_Destroying
                lda #1
                ldy #7
                jsr LoopingAnimation
                jsr CommonFlyingAI
                jmp AttackCommon

        ; Security droid destroy routine
        ;
        ; Parameters: X:Actor index
        ; Returns: -
        ; Modifies: A,Y,temp vars

DestroyDroid:   lda #15
DestroyDroid_Common:
                sta actTime,x
                jsr DropItem
                ldy #EXPL_7F_7F
                jmp GenerateExplosion       ;Guarantee initial explosion

        ; Homing robot mine update routine
        ;
        ; Parameters: X:Actor index
        ; Returns: -
        ; Modifies: A,Y,temp vars

MoveRobotMine:  lda #3
                ldy #3
                jsr LoopingAnimation
                jsr CheckPlayerCollision
                lda actOrg,x
                bcs MoveRobotMine_Explode
MoveRobotMine_NoCollision:
                jmp CommonFlyingAI

DestroyRobotMine:
                lda temp1                       ;If spawned by enemy and not in level, do not drop parts
                bmi MoveRobotMine_Explode       ;to not overwhelm the game
                ldy #ITEM_PARTS
                jsr DropExplicitItem
MoveRobotMine_Explode:
                lda #DMG_ROBOTMINE
                sta actHp,x
                jmp ExplodeActorBreakWall

        ; Squid / flying craft update routine
        ;
        ; Parameters: X:Actor index
        ; Returns: -
        ; Modifies: A,Y,temp vars

MoveSquid:      ldy actWpn,x
                lda squidFireDistTbl-WPN_LASER,y
                sta ALSquidHAttackDist
                lda squidTopLimitTbl-WPN_LASER,y
                bne MoveFlyingCraft_StoreTopLimit
MoveFlyingCraft_Explode:
                jmp ExplodeActor
MoveFlyingCraft_Destroying:
                lda actTime,x
                beq MoveFlyingCraft_Explode
                jsr FallingMotionCommon
                lda actMB,x
                and #MB_HITWALL|MB_HITCEILING|MB_LANDED
                bne MoveFlyingCraft_Explode
                ldy #EXPL_7F_7F
                jmp GenerateExplosionsAndFlicker
MoveFlyingCraft:lda #1
                ldy actWpn,x
                beq MoveFlyingCraft_StoreTopLimit
                lda #3
MoveFlyingCraft_StoreTopLimit:
                sta MoveFlyingCraft_TopLimit+1
                lda actHp,x
                beq MoveFlyingCraft_Destroying
                jsr GetFireDir
                bpl MoveFlyingCraft_HasAttackDir
                jmp MoveFlyingCraft_FlyIdle
MoveFlyingCraft_HasAttackDir:
                sta actCtrl,x
                tay
                and #JOY_LEFT
                beq MoveFlyingCraft_NoAttackLeft
                lda actSX,x                     ;Do not attack when flying dir and attack dir don't agree
                bmi MoveFlyingCraft_AttackOK
                bpl MoveFlyingCraft_NoAttack
MoveFlyingCraft_NoAttackLeft:
                tya
                and #JOY_RIGHT
                beq MoveFlyingCraft_NoAttackRight
                lda actSX,x
                bpl MoveFlyingCraft_AttackOK
MoveFlyingCraft_NoAttackRight:
MoveFlyingCraft_NoAttack:
                ldy #$00
MoveFlyingCraft_AttackOK:
                tya
                sta actCtrl,x
                lda actMoveCtrl,x               ;Turn if no control yet
                beq MoveFlyingCraft_ForcedTurn
                lda actSX+ACTI_PLAYER           ;Turn if player is chasing the craft
                beq MoveFlyingCraft_PlayerStationary
                asl temp6                       ;Farturn sooner when player is moving
                eor actSX,x
                bmi MoveFlyingCraft_PlayerStationary
                lda actSX,x
                eor temp5
                bmi MoveFlyingCraft_ForcedTurn
MoveFlyingCraft_PlayerStationary:
                lda actMB,x
                and #MB_HITWALL
                bne MoveFlyingCraft_ForcedTurn
MoveFlyingCraft_NoForcedTurn:
                lda actMoveCtrl,x
                tay
                and #JOY_UP|JOY_DOWN
                sta MoveFlyingCraft_CheckNoYDir+1
                tya
                ldy temp6                       ;Turn when distance from target too large
MoveFlyingCraft_FarLimit:
                cpy #$06
                bcc MoveFlyingCraft_NoXTurn
                pha
                jsr Random                      ;Randomize the far turn to prevent formation of exact groups
                cmp #$c0
                pla
                bcc MoveFlyingCraft_NoXTurn
MoveFlyingCraft_ForcedTurn:
                lda actMoveCtrl,x
                and #$ff-JOY_LEFT-JOY_RIGHT
                ora #JOY_LEFT
                ldy temp5
                bmi MoveFlyingCraft_TargetOnLeft
                eor #JOY_LEFT|JOY_RIGHT
MoveFlyingCraft_TargetOnLeft:
MoveFlyingCraft_NoXTurn:
                ldy temp7                       ;If player clearly above, always have to go up
                bmi MoveFlyingCraft_GoUp
                ldy actCtrl,x                   ;If already strafing horizontally, keep diving (unless too low)
                cpy #JOY_LEFT|JOY_FIRE
                beq MoveFlyingCraft_GoDown
                cpy #JOY_RIGHT|JOY_FIRE
                beq MoveFlyingCraft_GoDown
                ldy temp7
MoveFlyingCraft_TopLimit:
                cpy #$03                        ;If higher than can fire, go down
                bcs MoveFlyingCraft_GoDown
                ldy actF1,x                     ;If in the middle frame (no speed) always go down
                cpy #2                          ;as some squids seemed to trap themselves to the ceiling
                beq MoveFlyingCraft_GoDown
MoveFlyingCraft_CheckNoYDir:
                ldy #$00
                bne MoveFlyingCraft_NoTurn      ;If no Y-dir, climb initially to give player time to react
MoveFlyingCraft_GoUp:                           ;TODO: doesn't seem to work often
                and #$ff-JOY_UP-JOY_DOWN
                ora #JOY_UP
                bne MoveFlyingCraft_NoTurn
MoveFlyingCraft_GoDown:
                and #$ff-JOY_UP-JOY_DOWN
                ora #JOY_DOWN
MoveFlyingCraft_NoTurn:
                sta actMoveCtrl,x
                jsr CommonFlyingAI_DoMove
                jmp MoveFlyingCraft_MoveDone
MoveFlyingCraft_FlyIdle:
                jsr CommonFlyingAI_Idle
MoveFlyingCraft_MoveDone:
                lda actSX,x                     ;Frame from speed
                clc
                adc #2*8+4
                bpl MoveFlyingCraft_FrameOK1
                lda #0
MoveFlyingCraft_FrameOK1:
                lsr
                lsr
                lsr
                cmp #5
                bcc MoveFlyingCraft_FrameOK2
                lda #4
MoveFlyingCraft_FrameOK2:
                sta actF1,x
                cmp #2                          ;Do not attack in the middle frame
                beq MoveFlyingCraft_NoAttack2
                jmp AttackCommon
MoveFlyingCraft_NoAttack2:
                rts

        ; Flying craft destroy routine
        ;
        ; Parameters: X:Actor index
        ; Returns: -
        ; Modifies: A,Y,temp vars

DestroyFlyingCraft:
                lda #25
                sta actTime,x
                jsr DropItem
                ldy #EXPL_7F_7F
                jmp GenerateExplosion       ;Guarantee initial explosion

        ; Nonhostile Creator move routine
        ;
        ; Parameters: X:Actor index
        ; Returns: -
        ; Modifies: A,Y,temp vars

MoveCreator:    lda actSY,y
                bmi MoveCreator_NotDown
                lda actMoveCtrl,y
                and #JOY_UP
                bne MoveCreator_NotDown
                lda #2                      ;Avoid hovering at floor, pick another dir instead
                jsr GetBlockInfoOffset      ;that is away from it
                and #BI_WALL
                beq MoveCreator_NotDown
                lda actMoveCtrl,x
                and #$ff-JOY_DOWN
                ora #JOY_UP
                sta actMoveCtrl,x
MoveCreator_NotDown:
                lda actTime,x
                bne MoveCreator_HasDir
                jsr Random
                and #$1f
                adc #$20                    ;C=0
                sta actTime,x
                and #$07
                tay
                lda flyerDirTbl,y
                sta actMoveCtrl,x
                lda actSY,x                 ;Avoid zero Y-speed, looks stupid
                bne MoveCreator_HasDir      ;so rather rise slowly instead
                lda actMoveCtrl,x
                and #JOY_UP|JOY_DOWN
                bne MoveCreator_HasDir
                lda #-4
                sta actSY,x
MoveCreator_HasDir:
                dec actTime,x
                jsr CommonFlyingAI_TurnAtWalls
                jmp MoveFlyingCraft_MoveDone

        ; Common flyer move/AI subroutine
        ;
        ; Parameters: X:Actor index
        ; Returns: -
        ; Modifies: A,Y,temp vars

CommonFlyingAI: lda actSX,x                 ;Consider current X speed as the "direction"
                sta actD,x
                jsr GetFireDir
                bmi CommonFlyingAI_Idle
                sta actCtrl,x
                lda temp5
                beq CommonFlyingAI_TargetXLevel
                asl
                lda #JOY_LEFT
                bcs CommonFlyingAI_StoreXMoveCtrl
                asl
CommonFlyingAI_StoreXMoveCtrl:
                sta actMoveCtrl,x
CommonFlyingAI_TargetXLevel:
                lda temp7
                bne CommonFlyingAI_TargetNotYLevel
                lda actSY,x                     ;If no Y-speed at all, choose to dive
                beq CommonFlyingAI_TargetYDown
                bne CommonFlyingAI_TargetYLevel
CommonFlyingAI_TargetNotYLevel:
                bmi CommonFlyingAI_TargetYUp
CommonFlyingAI_TargetYDown:
                lda #JOY_DOWN
                bne CommonFlyingAI_StoreYMoveCtrl
CommonFlyingAI_TargetYUp:
                lda #JOY_UP
CommonFlyingAI_StoreYMoveCtrl:
                ora actMoveCtrl,x
                sta actMoveCtrl,x
CommonFlyingAI_TargetYLevel:
CommonFlyingAI_DoMove:
                jsr AccelerateFlyer
                jsr MoveFlyer
                lda actMB,x
                tay
                and #MB_HITWALL
                beq CommonFlyingAI_NoHitWall2
                jsr StopXSpeed
CommonFlyingAI_NoHitWall2:
                tya
                and #MB_HITCEILING
                beq CommonFlyingAI_NoHitVertWall2
                lda #$00
                sta actSY,x
CommonFlyingAI_NoHitVertWall2:
                rts

CommonFlyingAI_Idle:
                lda #$00
                sta actCtrl,x
                lda actMoveCtrl,x               ;When idle, make sure is going either left or right
                tay                             ;and either up or down
                and #JOY_LEFT|JOY_RIGHT
                beq CommonFlyingAI_PickDir
                tya
                and #JOY_UP|JOY_DOWN
                beq CommonFlyingAI_PickDir
CommonFlyingAI_TurnAtWalls:
                lda actMB,x
                and #MB_HITWALL
                beq CommonFlyingAI_NoHitWall
                lda actMoveCtrl,x
                eor #JOY_LEFT|JOY_RIGHT
                sta actMoveCtrl,x
CommonFlyingAI_NoHitWall:
                lda actMB,x
                and #MB_HITCEILING
                beq CommonFlyingAI_NoHitVertWall
                lda actMoveCtrl,x
                eor #JOY_UP|JOY_DOWN
                sta actMoveCtrl,x
CommonFlyingAI_NoHitVertWall:
                jmp CommonFlyingAI_DoMove
CommonFlyingAI_PickDir:
                jsr Random
                and #$02
                tay
                lda actD,x
                bpl CommonFlyingAI_PickDirRight
                iny
CommonFlyingAI_PickDirRight:
                lda flyerDirTbl,y
                sta actMoveCtrl,x
                jmp CommonFlyingAI_DoMove

        ; Lift platform movement routine
        ;
        ; Parameters: X actor index
        ; Returns: -
        ; Modifies: A,Y,temp1-temp8,loader temp vars

MoveLift:       lda actFlash,x
                bne ML_Initialized
                ldy zoneNum                 ;Follow background color
                lda lvlZoneBg3,y
                sta actFlash,x
                jsr GetBlockInfo            ;Lift stopped somewhere outside liftstop? Move to last direction then
                and #BI_LIFTSTOP
                bne ML_Initialized
                lda actD,x
                asl
                lda #JOY_DOWN
                bcc ML_InitialDown
                lsr
ML_InitialDown: sta actMoveCtrl,x
ML_Initialized: lda actMoveCtrl,x
                beq ML_NoAcc
                lsr
ML_DoInitialAcc:lda #3
                ldy #2*8
                jsr AccActorYNegOrPos
ML_NoAcc:       lda actYL,x
                sta temp8
                lda actSY,x
                beq ML_NoMove
                pha
                sta actD,x                      ;Copy speed to direction also to remember it if lift goes off screen
                jsr MoveActorY
                lda #AF_NOREMOVECHECK           ;Do not remove while moving
                sta actFlags,x
                pla
                bmi ML_NoHardStopDown
                lda #1
                jsr GetBlockInfoOffset
                and #BI_LIFTSHAFT
                beq ML_DoHardStop
ML_NoHardStopDown:
                jsr GetBlockInfo                ;Check being at a stop / running out of shaft while going up
                and #BI_LIFTSHAFT+BI_LIFTSTOP
                bne ML_NoHardStopUp
                inc actYH,x
                bne ML_DoHardStop
ML_NoHardStopUp:bpl ML_NoStop
                lda actYL,x                     ;Only stop at the top of the block
                cmp #2*8
                bcs ML_NoStop
                lda actSY,x
                bpl ML_CheckStopDown
ML_CheckStopUp: lda temp8                       ;Must have come from below
                beq ML_NoStop
                bne ML_DoStop
ML_CheckStopDown:
                lda temp8                       ;Must have come from above
                cmp #14*8
                bcc ML_NoStop
ML_DoStop:      lda actSX,x                     ;Target position defined (activated with switch)?
                beq ML_DoHardStop               ;If yes, skip the stop unless target reached or impossible to move further
                cmp actYH,x
                bne ML_NoStop
ML_DoHardStop:  lda #$00
                sta actYL,x
                sta actSY,x
                sta actMoveCtrl,x
                sta actFlags,x                  ;Stopped: can remove
ML_NoMove:
ML_NoStop:      lda actYL,x                     ;Lift Y coords half block up for
                sec                             ;easier actor collision detection
                sbc #$40
                and #$7f
                sta temp7
                lda actYH,x
                sbc #$00
                sta temp8
                lda actSY,x                     ;Make sound when moving
                beq ML_NoSound
                lda #2
                jsr AnimationDelay
                bcc ML_NoSound
                lda #SFX_LIFT
                jsr QueueSfx
ML_NoSound:     ldy #ACTI_LAST
ML_Loop:        lda actFlags,y                  ;Only affect groundbased actors
                and #AF_GROUNDBASED
                bne ML_Found
ML_Next:        dey
                bpl ML_Loop
                rts
ML_Found:       lda actSY,y                     ;Must not be jumping up to land on the lift
                bmi ML_Next
                lda actXH,x                     ;Check X-range
                sec
                sbc actXH,y
                sta ML_XCmp2+1
                beq ML_XOK
                cmp #$ff
                beq ML_XOK
                cmp #$01
                bne ML_Next
ML_XOK:         lda actYL,y                     ;Check Y-range
                sec
                sbc temp7
                lda actYH,y
                sbc temp8
                bne ML_Next
                tya                             ;Set control mode for player
ML_XCmp2:       ora #$00                        ;If not at center (controls), no controlling
                bne ML_NotPlayer
                txa
                ora #$80                        ;Actor index + $80 = usable lift
                sta MP_UsableObj+1
ML_NotPlayer:   lda actYL,x                     ;Align actor to lift surface
                sta actYL,y
                lda actYH,x
                sta actYH,y
                lda #MB_GROUNDED|MB_ONLIFT|MB_LANDED
                sta actMB,y
                lda #$00
                sta actSY,y
                beq ML_Next

                brk

squidTopLimitTbl:dc.b 3,1,3,3,1,3
squidFireDistTbl:dc.b 8,7,8,8,7,9
flyerDirTbl:    dc.b JOY_RIGHT|JOY_UP,JOY_LEFT|JOY_UP,JOY_RIGHT|JOY_DOWN,JOY_LEFT|JOY_DOWN
                dc.b JOY_RIGHT,JOY_LEFT,JOY_UP,JOY_DOWN

ALDroid:        dc.w USESCRIPT+EP_MoveDroid     ;Update routine
                dc.b GRP_ENEMIES|AF_TAKEDAMAGE|AF_LINECHECK  ;Actor flags
                dc.b 5                          ;Horizontal size
                dc.b 4                          ;Size up
                dc.b 5                          ;Size down
                dc.b HP_DROID                   ;Initial health
                dc.b NO_MODIFY                  ;Damage modifier
                dc.w USESCRIPT+EP_DestroyDroid  ;Destroy routine
                dc.b 3*8-2                      ;Max movement speed X
                dc.b AB_HORIZONTAL|AB_DIAGONALUP|AB_DIAGONALDOWN ;Valid attack dirs
                dc.b 7                          ;Max attack distance
                dc.b 5                          ;Max attack distance vert
                dc.b -2                         ;Aim Y-adjust
                dc.b (3*8-2)/2                  ;Max movement speed Y
                dc.b 2                          ;Acceleration

ALRobotMine:    dc.w USESCRIPT+EP_MoveRobotMine ;Update routine
                dc.b GRP_ENEMIES|AF_TAKEDAMAGE|AF_LINECHECK  ;Actor flags
                dc.b 3                          ;Horizontal size
                dc.b 3                          ;Size up
                dc.b 3                          ;Size down
                dc.b HP_ROBOTMINE               ;Initial health
                dc.b NO_MODIFY                  ;Damage modifier
                dc.w USESCRIPT+EP_DestroyRobotMine ;Destroy routine
                dc.b 2*8                        ;Max movement speed X
                dc.b AB_NONE                    ;Valid attack dirs
                dc.b 0                          ;Max attack distance
                dc.b 0                          ;Max attack distance vert
                dc.b -2                         ;Aim Y-adjust
                dc.b (2*8)/2                    ;Max movement speed Y
                dc.b 1                          ;Acceleration

ALFlyingCraft:  dc.w USESCRIPT+EP_MoveFlyingCraft ;Update routine
                dc.b GRP_ENEMIES|AF_TAKEDAMAGE|AF_LINECHECK  ;Actor flags
                dc.b 8                          ;Horizontal size
                dc.b 4                          ;Size up
                dc.b 4                          ;Size down
                dc.b HP_FLYINGCRAFT             ;Initial health
                dc.b NO_MODIFY                  ;Damage modifier
                dc.w USESCRIPT+EP_DestroyFlyingCraft ;Destroy routine
                dc.b 4*8+4                      ;Max movement speed X
                dc.b AB_HORIZONTAL|AB_DIAGONALDOWN ;Valid attack dirs
                dc.b 9                          ;Max attack distance
                dc.b 7                          ;Max attack distance vert
                dc.b -3                         ;Aim Y-adjust
                dc.b 2*8+4                      ;Max movement speed Y
                dc.b 4                          ;Acceleration

ALEliteFlyingCraft:
                dc.w USESCRIPT+EP_MoveFlyingCraft ;Update routine
                dc.b GRP_ENEMIES|AF_TAKEDAMAGE|AF_LINECHECK  ;Actor flags
                dc.b 8                          ;Horizontal size
                dc.b 4                          ;Size up
                dc.b 4                          ;Size down
                dc.b HP_ELITEFLYINGCRAFT        ;Initial health
                dc.b NO_MODIFY                  ;Damage modifier
                dc.w USESCRIPT+EP_DestroyFlyingCraft ;Destroy routine
                dc.b 4*8+4                      ;Max movement speed X
                dc.b AB_HORIZONTAL|AB_DIAGONALDOWN ;Valid attack dirs
                dc.b 10                         ;Max attack distance
                dc.b 7                          ;Max attack distance vert
                dc.b -3                         ;Aim Y-adjust
                dc.b 2*8+4                      ;Max movement speed Y
                dc.b 5                          ;Acceleration

ALSquid:        dc.w USESCRIPT+EP_MoveSquid     ;Update routine
                dc.b GRP_ENEMIES|AF_TAKEDAMAGE|AF_LINECHECK  ;Actor flags
                dc.b 4                          ;Horizontal size
                dc.b 9                          ;Size up
                dc.b 8                          ;Size down
                dc.b HP_SQUID                   ;Initial health
                dc.b NO_MODIFY                  ;Damage modifier
                dc.w USESCRIPT+EP_DestroyFlyingCraft ;Destroy routine
                dc.b 2*8+4                      ;Max movement speed X
                dc.b AB_HORIZONTAL|AB_DIAGONALDOWN ;Valid attack dirs
ALSquidHAttackDist:
                dc.b 8                          ;Max attack distance
                dc.b 6                          ;Max attack distance vert
                dc.b -3                         ;Aim Y-adjust
                dc.b 1*8+2                      ;Max movement speed Y
                dc.b 2                          ;Acceleration

ALCreator:      dc.w USESCRIPT+EP_MoveCreator   ;Update routine
                dc.b GRP_HEROES                 ;Actor flags
                dc.b 2                          ;Horizontal size
                dc.b 2                          ;Size up
                dc.b 2                          ;Size down
                dc.b HP_PLAYER                  ;Initial health
                dc.b NO_MODIFY                  ;Damage modifier
                dc.w USESCRIPT+EP_DestroyFlyingCraft ;Destroy routine
                dc.b 2*8+4                      ;Max movement speed X
                dc.b AB_HORIZONTAL|AB_DIAGONALDOWN ;Valid attack dirs
                dc.b 8                          ;Max attack distance
                dc.b 6                          ;Max attack distance vert
                dc.b -3                         ;Aim Y-adjust
                dc.b 1*8                        ;Max movement speed Y
                dc.b 1                          ;Acceleration

ALLift:         dc.w USESCRIPT+EP_MoveLift      ;Update routine
                dc.b AF_INITONLYSIZE            ;Actor flags
                dc.b 12                         ;Horizontal size
                dc.b 7                          ;Size up
                dc.b 3                          ;Size down

ADDroid:        dc.b ONESPRITE                  ;Number of sprites
                dc.b C_ENEMIES2                 ;Spritefile number
                dc.b 0                          ;Left frame add
                dc.b 8                          ;Number of frames
                dc.b 9,10,11,12,13,12,11,10

ADRobotMine:    dc.b ONESPRITE
                dc.b C_ENEMIES3                 ;Spritefile number
                dc.b 0                          ;Left frame add
                dc.b 4                          ;Number of frames
                dc.b 0,1,2,1

ADFlyingCraft:  dc.b TWOSPRITE
                dc.b C_ENEMIES3                 ;Spritefile number
                dc.b 0                          ;Left frame add
                dc.b 5                          ;Number of frames
                dc.b 3+$80,5+$80,7,5,3          ;First sprite frames
                dc.b 4,6,8,6+$80,4+$80          ;Second sprite frames

ADSquid:        dc.b TWOSPRITE                  ;Number of sprites
                dc.b C_ENEMIES4                 ;Spritefile number
                dc.b 0                          ;Left frame add
                dc.b 5                          ;Number of frames
                dc.b 15+$80,16+$80,17,16,15     ;First sprite frames
                dc.b 18+$80,19+$80,20,19,18     ;Second sprite frames

ADLift:         dc.b TWOSPRITE                  ;Number of sprites
                dc.b C_COMMON                   ;Spritefile number
                dc.b 0                          ;Left frame add
                dc.b 1                          ;Number of frames
                dc.b 64                         ;First sprite frames
                dc.b 65                         ;Second sprite frames

ADCreator:      dc.b ONESPRITE                  ;Number of sprites
                dc.b C_CREW                     ;Spritefile number
                dc.b 0                          ;Left frame add
                dc.b 5                          ;Number of frames
                dc.b 20+$80,21+$80,22,21,20     ;First sprite frames

                rend

scriptEnd: