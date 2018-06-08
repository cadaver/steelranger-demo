                org $0000

                include macros.s
                include memory.s
                include mainsym.s

        ; Note! Code must be unambiguous! Relocated code cannot have skip1/skip2 -macros!

                dc.w scriptEnd-scriptStart  ;Chunk data size
                dc.b 20                     ;Number of objects

scriptStart:
                rorg scriptCodeRelocStart   ;Initial relocation address when loaded

                dc.w MoveRobotSoldier       ;$0200
                dc.w DestroyRobotSoldier    ;$0201
                dc.w MoveSmallWalker        ;$0202
                dc.w DestroySmallWalker     ;$0203
                dc.w MoveTurret             ;$0204
                dc.w DestroyTurret          ;$0205
                dc.w ADTurret               ;$0206
                dc.w ADCeilingTurret        ;$0207
                dc.w ALIntroSoldier         ;$0208
                dc.w ALRobotSoldier         ;$0209
                dc.w ALEliteSoldier         ;$020a
                dc.w ALHeavySoldier         ;$020b
                dc.w ALSmallWalker          ;$020c
                dc.w ALTurret               ;$020d
                dc.w ALCeilingTurret        ;$020e
                dc.w ADRobotSoldier         ;$020f
                dc.w ADHeavySoldier         ;$0210
                dc.w ADSmallWalker          ;$0211
                dc.w MoveCeilingTurret      ;$0212
                dc.w DestroyCeilingTurret   ;$0213

        ; Robot soldier movement routine
        ;
        ; Parameters: X:Actor index
        ; Returns: -
        ; Modifies: A,Y,temp vars

MoveRobotSoldier:
                lda actHp,x
                bne MoveRobotSoldier_NotDead

MoveRobotSoldier_Dead:
                lda #5
                ldy #FR_DIE+1
                jsr OneShotAnimation
                lda actF1,x
                sta actF2,x
MoveRobotSoldier_DeadCommon:
                lda #4
                ldy #5*8
                jsr AccActorY
                lda actSX,x
                jsr MoveActorX
                lda actSY,x
                jsr MoveActorY
                ldy #EXPL_7F_7F_UP
                jmp GenerateExplosionsAndFlicker

MoveRobotSoldier_NotDead:
                lda actMB,x
                ora #MB_PREVENTFALL
                sta actMB,x
                lda actCtrl,x                   ;Was attacking?
                and #JOY_FIRE
                beq MoveRobotSoldier_NoPreviousAttack
                lda actAttackD,x                ;And has attack delay?
                cmp #3
                bcc MoveRobotSoldier_NoPreviousAttack
                lda #-13                        ;In that case set a cooldown
                sta actTime,x                   ;and lock down the attack
                bne MoveRobotSoldier_AttackLocked
MoveRobotSoldier_NoPreviousAttack:
                lda #$00
                sta actCtrl,x
                lda actTime,x
                bmi MoveRobotSoldier_FreeMoveAfterAttack
                beq MoveRobotSoldier_FireOK
                dec actTime,x
                cmp #21                         ;If hit wall or ledge, do not re-attack
                bcs MoveRobotSoldier_ContinueFreeMove
MoveRobotSoldier_FireOK:
                jsr GetFireDir
                bmi MoveRobotSoldier_FreeMove
                beq MoveRobotSoldier_PathFind
MoveRobotSoldier_Attack:
                sta actCtrl,x
MoveRobotSoldier_AttackLocked:
                lda actT,x                      ;When elite attacks horizontally, duck always
                cmp #ACT_ELITESOLDIER
                bne MoveRobotSoldier_NoDuck
                lda actCtrl,x
                and #JOY_UP|JOY_DOWN
                bne MoveRobotSoldier_NoDuck
MoveRobotSoldier_Duck:
                lda #JOY_DOWN
                bne MoveRobotSoldier_StoreMoveCtrl
MoveRobotSoldier_NoDuck:
                lda #$00                        ;Stop when attacking
MoveRobotSoldier_StoreMoveCtrl:
                sta actMoveCtrl,x
MoveRobotSoldier_ContinueDucking:
                jmp MoveHuman
MoveRobotSoldier_PathFind:
                lda temp8                       ;If Y-distance substantial, freemove instead
                cmp #2
                bcs MoveRobotSoldier_FreeMove
                lda actTime,x
                bne MoveRobotSoldier_ContinueFreeMove
MoveRobotSoldier_PathFindOK:
                ldy temp5
MoveRobotSoldier_PathFindHasDir:
                lda actMB,x
                and #MB_HITWALL|MB_STARTFALLING
                beq MoveRobotSoldier_PathFindNoWall
                lda #40
                sta actTime,x                   ;If reach wall or edge, turn
                lda actSX,x                     ;and don't retry actual pathfinding for some time
                bne MoveRobotSoldier_HasSpeed
                lda actD,x
MoveRobotSoldier_HasSpeed:
                eor #$80
                tay
MoveRobotSoldier_PathFindNoWall:
                lda #JOY_RIGHT
                cpy #$80
                bcc MoveRobotSoldier_StoreMoveCtrl
                lda #JOY_LEFT
                bne MoveRobotSoldier_StoreMoveCtrl
MoveRobotSoldier_FreeMove:
                jsr Random
                and #$07
                adc #20-3                       ;C=0, Keep freemove for some time if started
                sta actTime,x
                jmp MoveRobotSoldier_ContinueFreeMove
MoveRobotSoldier_FreeMoveAfterAttack:
                inc actTime,x
                lda actMoveCtrl,x               ;If ducking after attack, random chance to stand up
                cmp #JOY_DOWN
                bne MoveRobotSoldier_ContinueFreeMove
                jsr Random
                cmp #$20
                bcs MoveRobotSoldier_ContinueDucking
MoveRobotSoldier_ContinueFreeMove:
                ldy actD,x
                jmp MoveRobotSoldier_PathFindHasDir

        ; Robot soldier destroy routine
        ;
        ; Parameters: X:Actor index
        ; Returns: -
        ; Modifies: A,Y,temp vars

DestroyRobotSoldier:
                jsr HumanoidDeathCommon
DestroySmallWalker:
                jsr DropItem
                jsr ApplyDeathImpulse
                lda #-5*8
                sta actSY,x
                lda #20
                sta actTime,x
                ldy #EXPL_7F_7F_UP              ;Guarantee initial explosion
                jmp GenerateExplosion

        ; Small walker update routine
        ;
        ; Parameters: X:Actor index
        ; Returns: -
        ; Modifies: A,Y,temp vars

MoveSmallWalker:lda actHp,x
                bne MoveSmallWalker_Alive
                jmp MoveRobotSoldier_DeadCommon
MoveSmallWalker_Alive:
                lda #$00                        ;No forced ducking
                sta actFall,x
                sta actCtrl,x
                jsr GetFireDir
                bmi MoveSmallWalker_FreeMove
                sta actCtrl,x                   ;Store firing control
MoveSmallWalker_HomeToPlayer:
                lda temp8                       ;If Y-distance substantial and not firing, freemove instead
                cmp #2
                bcs MoveSmallWalker_FreeMove
                lda actTime,x
                bne MoveSmallWalker_ContinueFreeMove
MoveSmallWalker_PathFindOK:
                ldy temp5
MoveSmallWalker_HasDir:
                lda actMB,x
                and #MB_HITWALL+MB_STARTFALLING+$80
                cmp #MB_STARTFALLING
                bne MoveSmallWalker_NoJump
MoveSmallWalker_BeginJump:
                lda #-7*8
                sta actSY,x
                lda #$00
                sta actMB,x
                beq MoveSmallWalker_Done
MoveSmallWalker_NoJump:
                cmp #MB_HITWALL+$80             ;If hit wall and have a low obstacle, jump
                bne MoveSmallWalker_PathFindNoWall
                ldy #1
                lda actD,x
                bpl MoveSmallWalker_CheckLowObstacleRight
                ldy #-1
MoveSmallWalker_CheckLowObstacleRight:
                lda #-2
                jsr GetBlockInfoOffsetXY
                and #BI_WALL
                beq MoveSmallWalker_BeginJump
MoveSmallWalker_NoJump2:
                lda #30
                sta actTime,x                   ;If reach wall, turn
                lda actSX,x                     ;and don't retry actual pathfinding for some time
                bne MoveSmallWalker_HasSpeed
                lda actD,x
MoveSmallWalker_HasSpeed:
                eor #$80
                tay
MoveSmallWalker_PathFindNoWall:
                lda #JOY_RIGHT
                cpy #$80
                bcc MoveSmallWalker_Done
                lda #JOY_LEFT
                bne MoveSmallWalker_Done
MoveSmallWalker_FreeMove:
                jsr Random
                and #$0f
                adc #20-8                      ;C=0, Keep freemove for some time if started
                sta actTime,x
MoveSmallWalker_ContinueFreeMove:
                dec actTime,x
                ldy actD,x
                jmp MoveSmallWalker_HasDir
MoveSmallWalker_Done:
                and #JOY_LEFT|JOY_RIGHT
                sta actMoveCtrl,x
MoveSmallWalker_NoControlChange:
                jmp MoveHuman

        ; Turret move routine
        ;
        ; Parameters: X:Actor index
        ; Returns: -
        ; Modifies: A,Y,temp vars

MoveTurret:     lda actHp,x
                beq MoveTurret_Destroying
                lda actFall,x
                bne MoveTurret_Initialized
                ldy #ACTI_PLAYER
                jsr GetActorDistance
                lda temp5
                bpl MoveTurret_InitRight
                lda #$04
                sta actF1,x                     ;Start from left if player left
MoveTurret_InitRight:
                inc actFall,x
                lda #MB_GROUNDED                ;Mark grounded for linecheck
                sta actMB,x
MoveTurret_Initialized:
                ldy actF1,x
                lda turretDelayTbl,y
                ldy #7
                jsr LoopingAnimation
                lda #$00                        ;Assume: no firing
                sta actCtrl,x
                jsr GetFireDirNoRank
                bmi MoveTurret_NoAttack
                tay
                eor actF1,x                     ;No attack when turning or facing the wrong way
                and #$07
                bne MoveTurret_NoAttack
                tya
MoveTurret_StoreCtrlAndAttack:
                sta actCtrl,x
MoveTurret_NoAttack:
                jmp AttackCommon

MoveTurret_Destroying:
                ldy #EXPL_7F_7F_UP
                jmp GenerateExplosionsAndFlicker

MoveCeilingTurret_Destroying:
                ldy #EXPL_7F_7F
                jmp GenerateExplosionsAndFlicker

        ; Turret destroy routine
        ;
        ; Parameters: X:Actor index
        ; Returns: -
        ; Modifies: A,Y,temp vars

DestroyTurret:  ldy #EXPL_7F_7F_UP
DestroyTurretCommon:
                jsr GenerateExplosion       ;Guarantee initial explosion
                lda #15
                sta actTime,x
                jmp DropItem

        ; Ceiling turret destroy routine
        ;
        ; Parameters: X:Actor index
        ; Returns: -
        ; Modifies: A,Y,temp vars

DestroyCeilingTurret:
                ldy #EXPL_7F_7F
                bpl DestroyTurretCommon

        ; Ceiling turret move routine
        ;
        ; Parameters: X:Actor index
        ; Returns: -
        ; Modifies: A,Y,temp vars

MoveCeilingTurret:
                lda actHp,x
                beq MoveCeilingTurret_Destroying
                lda actFall,x
                bne MoveCeilingTurret_Initialized
                inc actFall,x
                lda #4                          ;Center initially
                sta actF1,x
MoveCeilingTurret_Initialized:
                lda #$00                        ;Assume: no attack
                sta actCtrl,x
                jsr GetFireDirNoRank
                bmi MoveCeilingTurret_NoAttack
                sta temp1
                ldy #4
MoveCeilingTurret_FindFrame:
                cmp ceilingTurretFrameTbl,y
                beq MoveCeilingTurret_FrameFound
                dey
                bpl MoveCeilingTurret_FindFrame
                bmi MoveCeilingTurret_NoAttack
MoveCeilingTurret_FrameFound:
                tya
                asl
                cmp actF1,x                     ;Must have rotated right before firing
                bne MoveCeilingTurret_Animate
                lda temp1
                bcs MoveTurret_StoreCtrlAndAttack
MoveCeilingTurret_Animate:
                lda actFd,x
                eor #$01
                sta actFd,x
                bne MoveCeilingTurret_AnimateDelay
                bcc MoveCeilingTurret_AnimateDown
                inc actF1,x
MoveCeilingTurret_AnimateDelay:
MoveCeilingTurret_NoAttack:
                jmp AttackCommon
MoveCeilingTurret_AnimateDown:
                dec actF1,x
                bpl MoveCeilingTurret_NoAttack

                brk

turretDelayTbl: dc.b 44,2,2,2,44,2,2,2

ceilingTurretFrameTbl:
                dc.b JOY_FIRE+JOY_RIGHT
                dc.b JOY_FIRE+JOY_RIGHT+JOY_DOWN
                dc.b JOY_FIRE+JOY_DOWN
                dc.b JOY_FIRE+JOY_LEFT+JOY_DOWN
                dc.b JOY_FIRE+JOY_LEFT

ALIntroSoldier: dc.w USESCRIPT+EP_MoveRobotSoldier;Update routine
                dc.b GRP_ENEMIES|AF_GROUNDBASED|AF_TAKEDAMAGE|AF_LINECHECK  ;Actor flags
                dc.b 5                          ;Horizontal size
                dc.b 21                         ;Size up
                dc.b 0                          ;Size down
                dc.b HP_ROBOTSOLDIER            ;Initial health
                dc.b NO_MODIFY                  ;Damage modifier
                dc.w USESCRIPT+EP_DestroyRobotSoldier ;Destroy routine
                dc.b 2*8+4                      ;Max movement speed
                dc.b AB_HORIZONTAL              ;Valid attack dirs
                dc.b 8                          ;Max attack distance
                dc.b 6                          ;Max attack distance vert
                dc.b 0                          ;Aim Y-adjust

ALRobotSoldier: dc.w USESCRIPT+EP_MoveRobotSoldier;Update routine
                dc.b GRP_ENEMIES|AF_GROUNDBASED|AF_TAKEDAMAGE|AF_LINECHECK  ;Actor flags
                dc.b 5                          ;Horizontal size
                dc.b 21                         ;Size up
                dc.b 0                          ;Size down
                dc.b HP_ROBOTSOLDIER            ;Initial health
                dc.b NO_MODIFY                  ;Damage modifier
                dc.w USESCRIPT+EP_DestroyRobotSoldier ;Destroy routine
                dc.b 2*8+4                      ;Max movement speed
                dc.b AB_HORIZONTAL|AB_DIAGONALUP|AB_DIAGONALDOWN ;Valid attack dirs
                dc.b 8                          ;Max attack distance
                dc.b 6                          ;Max attack distance vert
                dc.b 0                          ;Aim Y-adjust

ALEliteSoldier: dc.w USESCRIPT+EP_MoveRobotSoldier ;Update routine
                dc.b GRP_ENEMIES|AF_GROUNDBASED|AF_TAKEDAMAGE|AF_LINECHECK  ;Actor flags
                dc.b 5                          ;Horizontal size
                dc.b 21                         ;Size up
                dc.b 0                          ;Size down
                dc.b HP_ELITESOLDIER            ;Initial health
                dc.b NO_MODIFY                  ;Damage modifier
                dc.w USESCRIPT+EP_DestroyRobotSoldier ;Destroy routine
                dc.b 3*8                        ;Max movement speed
                dc.b AB_ALL                     ;Valid attack dirs
                dc.b 9                          ;Max attack distance
                dc.b 7                          ;Max attack distance vert
                dc.b 0                          ;Aim Y-adjust

ALHeavySoldier: dc.w USESCRIPT+EP_MoveRobotSoldier ;Update routine
                dc.b GRP_ENEMIES|AF_GROUNDBASED|AF_TAKEDAMAGE|AF_LINECHECK  ;Actor flags
                dc.b 5                          ;Horizontal size
                dc.b 20                         ;Size up
                dc.b 0                          ;Size down
                dc.b HP_HEAVYSOLDIER            ;Initial health
                dc.b NO_MODIFY                  ;Damage modifier
                dc.w USESCRIPT+EP_DestroyRobotSoldier ;Destroy routine
                dc.b 2*8                        ;Max movement speed
                dc.b AB_ALL                     ;Valid attack dirs
                dc.b 9                          ;Max attack distance
                dc.b 7                          ;Max attack distance vert
                dc.b 0                          ;Aim Y-adjust

ALSmallWalker:  dc.w USESCRIPT+EP_MoveSmallWalker ;Update routine
                dc.b GRP_ENEMIES|AF_GROUNDBASED|AF_TAKEDAMAGE|AF_LINECHECK  ;Actor flags
                dc.b 6                          ;Horizontal size
                dc.b 10                         ;Size up
                dc.b 0                          ;Size down
                dc.b HP_SMALLWALKER             ;Initial health
                dc.b NO_MODIFY                  ;Damage modifier
                dc.w USESCRIPT+EP_DestroySmallWalker ;Destroy routine
                dc.b 3*8                        ;Max movement speed
                dc.b AB_HORIZONTAL              ;Valid attack dirs
                dc.b 7                          ;Max attack distance
                dc.b 3                          ;Max attack distance vert
                dc.b 0                          ;Aim Y-adjust

ALTurret:       dc.w USESCRIPT+EP_MoveTurret    ;Update routine
                dc.b GRP_ENEMIES|AF_TAKEDAMAGE|AF_LINECHECK  ;Actor flags
                dc.b 5                          ;Horizontal size
                dc.b 10                         ;Size up
                dc.b 0                          ;Size down
                dc.b HP_TURRET                  ;Initial health
                dc.b NO_MODIFY                  ;Damage modifier
                dc.w USESCRIPT+EP_DestroyTurret ;Destroy routine
                dc.b 0                          ;Max movement speed
                dc.b AB_HORIZONTAL              ;Valid attack dirs
                dc.b 9                          ;Max attack distance
                dc.b 8                          ;Max attack distance vert
                dc.b -1                         ;Aim Y-adjust

ALCeilingTurret:dc.w USESCRIPT+EP_MoveCeilingTurret ;Update routine
                dc.b GRP_ENEMIES|AF_TAKEDAMAGE|AF_LINECHECK  ;Actor flags
                dc.b 4                          ;Horizontal size
                dc.b 0                          ;Size up
                dc.b 6                          ;Size down
                dc.b HP_TURRET                  ;Initial health
                dc.b NO_MODIFY                  ;Damage modifier
                dc.w USESCRIPT+EP_DestroyCeilingTurret ;Destroy routine
                dc.b 0                          ;Max movement speed
                dc.b AB_DOWN|AB_DIAGONALDOWN|AB_HORIZONTAL              ;Valid attack dirs
                dc.b 9                          ;Max attack distance
                dc.b 9                          ;Max attack distance vert
                dc.b -1                         ;Aim Y-adjust

ADRobotSoldier: dc.b HUMANOID                   ;Number of sprites
                dc.b C_ENEMIES1                 ;Lower part spritefile number
                dc.b 12                         ;Lower part base spritenumber
                dc.b 0                          ;Lower part base index into the frametable
                dc.b 28                         ;Lower part left frame add
                dc.b C_ENEMIES1                 ;Upper part spritefile number
                dc.b 0                          ;Upper part base spritenumber
                dc.b 0                          ;Upper part base index into the frametable
                dc.b 34                         ;Upper part left frame add

ADHeavySoldier:
                dc.b HUMANOID                   ;Number of sprites
                dc.b C_ENEMIES1                 ;Lower part spritefile number
                dc.b 12                         ;Lower part base spritenumber
                dc.b 0                          ;Lower part base index into the frametable
                dc.b 28                         ;Lower part left frame add
                dc.b C_ENEMIES1                 ;Upper part spritefile number
                dc.b 27                         ;Upper part base spritenumber
                dc.b 0                          ;Upper part base index into the frametable
                dc.b 34                         ;Upper part left frame add

ADSmallWalker:  dc.b ONESPRITE                  ;Number of sprites
                dc.b C_ENEMIES3                 ;Spritefile number
                dc.b 16                         ;Left frame add
                dc.b 32                         ;Number of frames
                dc.b 9,9,10,11,12,9,10,11,12,13,14,14,9,9,10,11
                dc.b 9+$80,9+$80,10+$80,11+$80,12+$80,9+$80,10+$80,11+$80,12+$80,13+$80,14+$80,14+$80,9+$80,9+$80,10+$80,11+$80

ADTurret:       dc.b ONESPRITE                  ;Number of sprites
                dc.b C_ENEMIES2                 ;Spritefile number
                dc.b 0                          ;Left frame add
                dc.b 8                          ;Number of frames
                dc.b 14,15,16,$80+17,$80+18,$80+17,16,15

ADCeilingTurret:dc.b ONESPRITE                  ;Number of sprites
                dc.b C_ENEMIES2                 ;Spritefile number
                dc.b 0                          ;Left frame add
                dc.b 9                          ;Number of frames
                dc.b 0,1,2,3,4,5,6,7,8
                
                rend

scriptEnd: