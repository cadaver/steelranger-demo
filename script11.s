                org $0000

                include macros.s
                include memory.s
                include mainsym.s

        ; Note! Code must be unambiguous! Relocated code cannot have skip1/skip2 -macros!

                dc.w scriptEnd-scriptStart  ;Chunk data size
                dc.b 10                     ;Number of objects

scriptStart:
                rorg scriptCodeRelocStart   ;Initial relocation address when loaded

                dc.w MoveDroidBossInvisible ;$0b00
                dc.w MoveDroidBoss          ;$0b01
                dc.w DestroyDroidBoss       ;$0b02
                dc.w MoveBombBossInvisible  ;$0b03
                dc.w MoveBombBoss           ;$0b04
                dc.w ALDroidBossInvisible   ;$0b05
                dc.w ALDroidBoss            ;$0b06
                dc.w ALBombBossInvisible    ;$0b07
                dc.w ALBombBoss             ;$0b08
                dc.w ADDroidBoss            ;$0b09

        ; Droid boss invisible state update routine
        ;
        ; Parameters: X:Actor index
        ; Returns: -
        ; Modifies: A,Y,temp vars

MoveDroidBossInvisible:
                lda #$00                        ;Center on the 2-block vertical tunnel
                sta actXL,x
                lda #PLOT_DROIDBOSS
                jsr GetPlotBit                  ;Wait for plotbit (accessed terminal)
                bne MDBI_Appear
                rts
MDBI_Appear:    inc actT,x
                jmp InitActor

        ; Droid boss update routine
        ;
        ; Parameters: X:Actor index
        ; Returns: -
        ; Modifies: A,Y,temp vars

MDB_Explode:    ldy actT,x
                cpy #ACT_DROIDBOSS
                bne MDB_ExplodeCommon
                ldx levelNum                    ;Return to the normal level tune
                lda lvlSongTbl,x
                jsr PlaySong
                ldx actIndex
MDB_ExplodeCommon:
                lda #4
                ldy #30
                jsr SpawnMetalPieces
                lda #3
                sta flashScreen
                lda #3*8
                sta shakeScreen
                jmp ExplodeActor                ;Finish with a self explosion

MDB_Destroying: lda actTime,x
                beq MDB_Explode
                jsr Random
                cmp #$80
                bcc MDB_NoShake
                lda #1*8
                sta shakeScreen
MDB_NoShake:    ldy #EXPL_FF_FF
                jmp GenerateExplosionsAndFlicker

MoveDroidBoss:  lda #2
                ldy #2
                jsr LoopingAnimation
                lda actHp,x
                beq MDB_Destroying
                jsr SetBossHealth
                lda actFall,x
                bne MDB_CombatState
                lda #SONG_BOSS3                 ;Will not restart if already playing
                jsr PlaySong
                ldx actIndex
                jsr DroidDescentCommon
                lda actYH,x
                cmp #3
                bcc MDB_DescentNotReady
                inc actFall,x
                lda #JOY_DOWN|JOY_RIGHT
                sta actMoveCtrl,x
MDB_DescentNotReady:
                jmp MDB_DoMove
MDB_CombatState:
                lda actMoveCtrl,x
                and #JOY_DOWN
                beq MDB_Common
                lda actYL,x
                cmp #$10
                lda actYH,x                     ;Do not go into the ladder and to the room below,
                sbc #6                          ;also give player space to dodge with the wheel
                bcc MDB_Common
                lda actMoveCtrl,x
                eor #JOY_UP|JOY_DOWN
                sta actMoveCtrl,x
MDB_Common:     ldy #ACTI_PLAYER
                jsr GetActorDistance
MDB_Common_HasDist:
                lda actHp+ACTI_PLAYER
                beq MDB_NoFire
                lda actEnemyRank,x              ;Only the healthiest boss fires
                bne MDB_NoFire
                lda temp6                       ;If stupidly far, do not fire, as player would see the bullet disappear
                cmp #15
                bcs MDB_NoFire
                lda actTime,x
                adc #$03
                sta actTime,x
                cmp #$a0
                bcs MDB_NoFire
                lda actFlags,x
                and #AF_HASLINE
                beq MDB_NoFire
                lda #JOY_RIGHT|JOY_FIRE
                ldy temp5
                bpl MDB_AttackOK
                lda #JOY_LEFT|JOY_FIRE
                bne MDB_AttackOK
MDB_NoFire:     lda #$00
MDB_AttackOK:   sta actCtrl,x
MDB_AlreadyHasAttackDir:
                lda actMB,x
                and #MB_HITCEILING
                beq MDB_NoHitVertWall
                lda #$00
                sta actSY,x
MDB_ReverseDownDir:
                lda actMoveCtrl,x
                eor #JOY_UP|JOY_DOWN
                sta actMoveCtrl,x
MDB_NoHitVertWall:
                lda actMB,x
                and #MB_HITWALL
                beq MDB_NoHitWall
                jsr StopXSpeed
                lda actMoveCtrl,x
                eor #JOY_LEFT|JOY_RIGHT
                sta actMoveCtrl,x
MDB_NoHitWall:
MDB_DoAcceleration:
                jsr AccelerateFlyer
MDB_DoMove:     lda actSY,x
                beq MDB_NoVertMove
                jsr MoveActorY
                lda #1                          ;Use offset collision check to account for boss size
                ldy actSY,x
                bpl MDB_OffsetDown
                lda #-1
MDB_OffsetDown: jsr GetBlockInfoOffset
                and #BI_WALL
                beq MDB_NoHitWallVertical
                lda actSY,x
                jsr MoveActorYNeg
                lda #MB_HITCEILING
                bne MDB_SetCeilingHit
MDB_NoHitWallVertical:
MDB_NoVertMove:
                lda #$00
MDB_SetCeilingHit:
                sta actMB,x
                lda actSX,x
                beq MDB_NoHorizMove
                jsr MoveActorX
                ldy #1
                lda actSX,x
                bpl MDB_OffsetRight
                ldy #-1
MDB_OffsetRight:lda #$00
                jsr GetBlockInfoOffsetXY
                and #BI_WALL
                beq MDB_NoHitWallHorizontal
                lda actSX,x
                jsr MoveActorXNeg
                lda actMB,x
                ora #MB_HITWALL
                sta actMB,x
MDB_NoHitWallHorizontal:
MDB_NoHorizMove:
                ldy #$ff                        ;When boss fires, adjust bullet pos to the side
                sty bulletActIndex
                lda AH_GlobalAttackDelay+1      ;Disregard global attack delay for boss attacks,
                pha                             ;in case there are still enemies alive in the room
                iny
                sty AH_GlobalAttackDelay+1
                jsr AttackCommon
                pla
                sta AH_GlobalAttackDelay+1
                lda bulletActIndex
                bmi MDB_AdjustDone
                ldy actT,x
                lda bossAttackDelayTbl-ACT_DROIDBOSS,y
                sta actAttackD,x
                ldx bulletActIndex
                lda actSX,x
                bpl MDB_AdjustBulletRight
                dec actXH,x
                lda #-8*8
                bmi MDB_AdjustCommon
MDB_AdjustBulletRight:
                inc actXH,x
                lda #8*8
MDB_AdjustCommon:
                jsr MoveActorX
MDB_AdjustDone: ldx actIndex
                rts

        ; Droid boss destroy routine
        ;
        ; Parameters: X:Actor index
        ; Returns: -
        ; Modifies: A,Y,temp vars

DestroyDroidBoss:
                lda #50
                sta actTime,x
                ldy #EXPL_7F_7F                 ;Guarantee initial explosion
                jsr GenerateExplosion
                lda actT,x
                cmp #ACT_DROIDBOSS
                bne DDB_NoPass
                jsr GetFreePersistentActor
                bcs DDB_ActorOK
                ldy #ACTI_LASTPERSISTENT        ;Forcibly spawn the alpha pass if necessary
DDB_ActorOK:    lda #ACT_ITEM
                jsr SpawnActor
                jsr InitSpawnedActor
                lda #ITEM_ALPHAPASS
                sta actF1,x
                jsr MakeActorGlobal             ;Do not forget the pass if player moves to another level
                lda #$00                        ;Reset health var for next boss
                sta bossHealth
                lda #<EP_PostDroidBossTick      ;Set a tick script to execute the post-destruction radio message trigger
                sta scriptEP
                lda #>EP_PostDroidBossTick
                sta scriptF
                ldx #2
                bne DDB_ScoreLoop
DDB_NoPass:     inc scriptVar3                  ;Killed bombboss count
                ldx #6                          ;35000 score for bomb bosses, 15000 for droid boss
DDB_ScoreLoop:  ldy #MAX_SCORE_INDEX
                jsr AddScore
                dex
                bne DDB_ScoreLoop
                ldx actIndex
MBBI_NoPlotBit: rts

        ; Bomb boss invisible state update routine
        ;
        ; Parameters: X:Actor index
        ; Returns: -
        ; Modifies: A,Y,temp vars

MoveBombBossInvisible:
                lda #PLOT_BOMBBOSS
                jsr GetPlotBit                  ;Wait for plotbit (accessed terminal)
                beq MBBI_NoPlotBit
MBBI_Appear:    inc actT,x
                jmp InitActor

        ; Bomb boss update routine
        ;
        ; Parameters: X:Actor index
        ; Returns: -
        ; Modifies: A,Y,temp vars

MBB_Destroying: jmp MDB_Destroying
MoveBombBoss:   lda actHp,x
                beq MBB_Destroying
                lda actEnemyRank,x              ;Make the droids move at slightly different speed
                and #$01                        ;The firing one is faster
                eor #$01
                asl
                asl
                adc #(2*8+4)/2
                sta ALBombBossVSpeed
                asl
                sta ALBombBossSpeed
                lda #2
                ldy #2
                jsr LoopingAnimation
                lda actFall,x
                bne MBB_CombatState
                lda #SONG_BOSS9                 ;Will not restart if already playing
                jsr PlaySong
                ldx actIndex
                jsr DroidDescentCommon
                lda actXH,x
                cmp #10
                bne MBB_DescentReady
                lda actYH,x
                cmp #9
                bcc MBB_DescentNotReady
MBB_DescentReady:
                inc actFall,x
                lda #JOY_DOWN|JOY_RIGHT
                sta actMoveCtrl,x
MBB_DescentNotReady:
                jmp MDB_DoMove
MBB_CombatState:
                ldy #ACTI_PLAYER
                jsr GetActorDistance
                lda actMoveCtrl,x
                tay
                lsr
                bcc MBB_NotUp
                lda #$80
MBB_NotUp:      sta temp2
                tya
                and #JOY_LEFT
                beq MBB_NotLeft
                lda #$80
MBB_NotLeft:    sta temp1
                lda actHp+ACTI_PLAYER
                beq MBB_HorizDirOK
                lda temp5                       ;Turn if too far from player
                eor temp1
                bpl MBB_HorizDirOK
                lda temp6
                cmp #6
                bcc MBB_HorizDirOK
                lda actMoveCtrl,x
                eor #JOY_LEFT|JOY_RIGHT
                sta actMoveCtrl,x
MBB_HorizDirOK: lda actMoveCtrl,x               ;Do not go below lava
                and #JOY_DOWN
                beq MBB_NotTooLow
                lda actYH,x
                cmp #$10
                bcs MBB_ReverseYDir
MBB_NotTooLow:  lda actHp+ACTI_PLAYER
                beq MBB_VertDirOK
                lda temp7
                eor temp2
                bpl MBB_VertDirOK
                lda temp8
                cmp #5
                bcc MBB_VertDirOK
MBB_ReverseYDir:lda actMoveCtrl,x
                eor #JOY_UP|JOY_DOWN
                sta actMoveCtrl,x
MBB_VertDirOK:  jmp MDB_Common_HasDist

DroidDescentCommon:
                ldy #AL_INITIALHP               ;Shield from damage during the initial descent
                lda (actLo),y
                sta actHp,x
                lda #WPN_BOUNCE
                sta actWpn,x
                ldy actT,x
                lda bossColorTbl-ACT_DROIDBOSS,y
                ora actFlash,x
                sta actFlash,x
                jsr StopXSpeed
                lda #8
                sta actSY,x
                rts

                brk

bossColorTbl:   dc.b 14,2,2
bossAttackDelayTbl:
                dc.b 10,9,9

ALDroidBossInvisible:
                dc.w USESCRIPT+EP_MoveDroidBossInvisible     ;Update routine
                dc.b GRP_ENEMIES|AF_INITONLYSIZE ;Actor flags

ALDroidBoss:    dc.w USESCRIPT+EP_MoveDroidBoss ;Update routine
                dc.b GRP_ENEMIES|AF_TAKEDAMAGE|AF_LINECHECK|AF_NOREMOVECHECK  ;Actor flags
                dc.b 11                         ;Horizontal size
                dc.b 10                         ;Size up
                dc.b 10                         ;Size down
                dc.b HP_BOSS                    ;Initial health
                dc.b SMALLBOSS_MODIFY           ;Damage modifier
                dc.w USESCRIPT+EP_DestroyDroidBoss ;Destroy routine
                dc.b 4*8+4                      ;Max movement speed X
                dc.b AB_HORIZONTAL              ;Valid attack dirs
                dc.b 12                         ;Max attack distance
                dc.b 5                          ;Max attack distance vert
                dc.b -3                         ;Aim Y-adjust
                dc.b 4*8/2                      ;Max movement speed Y
                dc.b 2                          ;Acceleration

ALBombBossInvisible:
                dc.w USESCRIPT+EP_MoveBombBossInvisible     ;Update routine
                dc.b GRP_ENEMIES|AF_INITONLYSIZE|AF_NOREMOVECHECK ;Actor flags

ALBombBoss:     dc.w USESCRIPT+EP_MoveBombBoss ;Update routine
                dc.b GRP_ENEMIES|AF_TAKEDAMAGE|AF_LINECHECK|AF_NOREMOVECHECK  ;Actor flags
                dc.b 11                         ;Horizontal size
                dc.b 10                         ;Size up
                dc.b 10                         ;Size down
                dc.b HP_BOSS                    ;Initial health
                dc.b LARGEBOSS_MODIFY           ;Damage modifier
                dc.w USESCRIPT+EP_DestroyDroidBoss ;Destroy routine
ALBombBossSpeed:dc.b 3*8                        ;Max movement speed X
                dc.b AB_HORIZONTAL              ;Valid attack dirs
                dc.b 10                         ;Max attack distance
                dc.b 5                          ;Max attack distance vert
                dc.b -3                         ;Aim Y-adjust
ALBombBossVSpeed:
                dc.b 3*8/2                      ;Max movement speed Y
                dc.b 2                          ;Acceleration

ADDroidBoss:    dc.b FOURSPRITE                 ;Number of sprites
                dc.b C_BOSS0                    ;Spritefile number
                dc.b 0                          ;Left frame add
                dc.b 3                          ;Number of frames
                dc.b 0,1,2                      ;First sprite
                dc.b 3,4,5                      ;Second sprite
                dc.b 6,7,8                      ;Third sprite
                dc.b 9,10,11                    ;Fourth sprite

                rend

scriptEnd: