MEDIUM_ENEMY_THRESHOLD = 10
LARGE_ENEMY_THRESHOLD = 21
SUPER_ENEMY_THRESHOLD = 40
DROPPED_ITEM_TIME = 8*25
MAX_LINE_STEPS  = 19
MAX_DEATHIMPULSE_XSPEED = 5*8
HEALTH_PICKUP_INTERVAL = 4
MAX_ACTIVE_ENEMIES = 3

       ; Moving / standing NPC update routine
        ;
        ; Parameters: X actor index
        ; Returns: -
        ; Modifies: A,Y,temp1-temp8

MoveNPC:        jsr MoveHuman
MoveNPCStationary:
                ldy actT,x
                lda npcColorTbl-ACT_FIRSTNPC,y
                sta actFlash,x
                lda npcIndexTbl-ACT_FIRSTNPC,y
                tay
                lda npcScriptF,y
                bmi MNPCS_NoScript
                tax
                lda npcScriptEP,y
                jmp ExecScript
MNPCS_NoScript: rts

MoveNPCWheel:   jsr MoveWheel
                jmp MoveNPCStationary

        ; Metal piece move routine  / common bounce motion
        ;
        ; Parameters: X actor index
        ; Returns: C=1 if bounced against ground
        ; Modifies: A,Y,temp1-temp8

MMP_Remove:     jmp RemoveActor
MoveMetalPiece: dec actTime,x
                bmi MMP_Remove
BounceMotion:   lda actSY,x                     ;Store original speed for bounce
                sta temp1
                lda #$00                        ;Never stay grounded
                sta actMB,x
                jsr FallingMotionCommon
                lda actMB,x
                tay
                and #MB_HITWALL
                beq BM_NoWallCollision
                jsr BounceXSpeed
BM_NoWallCollision:
                tya
                bpl BM_NotGrounded
                lda actSX,x
                jsr Asr8
                sta actSX,x
                lda temp1
                jsr Negate8Asr8
                sta actSY,x
                sec
                rts
BM_NotGrounded: clc
                rts

        ; Common robot pathfind routine
        ;
        ; Parameters: X:Actor index, A:firing controls (negative = freemove)
        ; Returns: actMoveCtrl stored
        ; Modifies: A,Y,temp vars

RobotPathFindCommon:
                lda #$00
                sta actCtrl,x
                lda actMB,x
                ora #MB_PREVENTFALL
                sta actMB,x
                jsr GetFireDir
                bmi RobotPathFind_FreeMove
                sta actCtrl,x                   ;Store firing control
RobotPathFind_HomeToPlayer:
                cmp #JOY_FIRE+JOY_LEFT          ;If has a fire dir with turning, use it for pathfinding control
                bcc RobotPathFind_NoFiringTurn
                ldy temp6
                cpy #3
                bcc RobotPathFind_NoFiringTurn  ;Player must not be too close
                lda actCtrl,x
                and #JOY_LEFT|JOY_RIGHT
                bpl RobotPathFind_Done
RobotPathFind_NoFiringTurn:
                lda temp8                       ;If Y-distance substantial, freemove instead
                cmp #2
                bcs RobotPathFind_FreeMove
                lda actTime,x
                bne RobotPathFind_ContinueFreeMove
RobotPathFind_PathFindOK:
                ldy temp5
RobotPathFind_HasDir:
                lda actMB,x
                and #MB_HITWALL|MB_STARTFALLING
                beq RobotPathFind_PathFindNoWall
                lda #20
                sta actTime,x                   ;If reach wall or edge, turn
                lda actSX,x                     ;and don't retry actual pathfinding for some time
                bne RobotPathFind_HasSpeed
                lda actD,x
RobotPathFind_HasSpeed:
                eor #$80
                tay
RobotPathFind_PathFindNoWall:
                lda #JOY_RIGHT
                cpy #$80
                bcc RobotPathFind_Done
                lda #JOY_LEFT
                bne RobotPathFind_Done
RobotPathFind_FreeMove:
                jsr Random
                and #$0f
                adc #7                          ;Returns with C=0. Keep freemove for some time if started
                sta actTime,x
RobotPathFind_ContinueFreeMove:
                dec actTime,x
                ldy actD,x
                jmp RobotPathFind_HasDir
RobotPathFind_Done:
                sta actMoveCtrl,x
                rts

        ; Common robot move routine
        ;
        ; Parameters: X:Actor index
        ; Returns: actMoveCtrl stored
        ; Modifies: A,Y,temp vars

RobotMoveCommon:ldy #AL_MAXSPEED
                lda (actLo),y
                sta temp1                       ;Maxspeed
RobotMoveCommon_CustomSpeed:
                lda actMoveCtrl,x
                and #JOY_LEFT|JOY_RIGHT
                beq RobotMoveCommon_Brake
                and #JOY_RIGHT
                bne RobotMoveCommon_TurnRight
                lda #$80
RobotMoveCommon_TurnRight:
                sta actD,x
                lda actD,x
                asl                             ;Direction to carry
                ldy temp1
                lda temp2
                jsr AccActorXNegOrPos
                jmp RobotMoveCommon_AccDone
RobotMoveCommon_Brake:
                lda temp3
                jsr BrakeActorX
RobotMoveCommon_AccDone:
                lda #PLAYER_GRAVITY
                ldy #-2
                jmp MoveWithGravity

        ; Spawn a number of metal pieces that fly up and to the sides
        ;
        ; Parameters: X actor index (must also be in actIndex), A number of pieces, Y piece duration
        ; Returns: -
        ; Modifies: A,X,Y,temp vars

SpawnMetalPieces:
                sta temp5
                lda #ACT_METALPIECE
SpawnCustomPieces:
                sta SMP_ActorType+1
                sty temp6
                lda #$00
                sta temp1
                sta temp2
                sta temp3
                lda #-1
                sta temp4
                jsr Random
                sta SMP_Frame+1
SMP_Loop:       jsr GetFreePersistentActor
                bcc SMP_Fail
SMP_ActorType:  lda #ACT_METALPIECE
                jsr SpawnWithOffset
SMP_Frame:      lda #$00
                and #$03
                sta actF1,y
                inc SMP_Frame+1
                jsr Random
                and #$1f
                sbc #6*8-1              ;C=0
                sta actSY,y
                jsr Random
                and #$3f
                sbc #$20-1              ;C=0
                sta actSX,y
                lda temp6
                sta actTime,y
                lda actFlash,x
                ora #COLOR_FLICKER
                sta actFlash,y
                jsr InitSpawnedActor
                ldx actIndex
                dec temp5
                bne SMP_Loop
SMP_Fail:       rts

        ; Calculate distance to target actor in blocks. Optionally lead by target X-speed
        ;
        ; Parameters: X actor index, Y target actor index
        ; Returns: temp5 X distance, temp6 abs X distance, temp7 Y distance, temp8 abs Y distance
        ; Modifies: A

GetActorDistance_LeadTarget:
                lda actSX,y
                beq GetActorDistance
                asl
                lda actXH,y
                bcs GAD_LeadLeft
GAD_LeadRight:  adc #$01
                bcc GAD_LeadDone
GAD_LeadLeft:   sbc #$00
                bcs GAD_LeadDone
                lda #$00
                beq GAD_LeadDone
GetActorDistance:
                lda actXH,y
GAD_LeadDone:   sec
                sbc actXH,x
                sta temp5
                bpl GAD_XDistPos
                sbc #$00
GAD_XDistNegOK: eor #$ff
GAD_XDistPos:   sta temp6
                lda actYH,y
                sec
                sbc actYH,x
                sta temp7
                bpl GAD_YDistPos
                sbc #$00
                eor #$ff
GAD_YDistPos:   sta temp8
                rts
                
        ; Perform linecheck from actor to player
        ;
        ; Parameters: X: Actor index
        ; Returns: actFlags updated
        ; Modifies: A,X,Y

DoLineCheck:    lda actFlags,x
                and #AF_LINECHECK
                bne DLC_Begin
DLC_Skip2:      jmp DLC_Skip
DLC_Begin:      lda actFlags,x                  ;Assume: no line of sight
                and #$ff-AF_HASLINE
                sta actFlags,x
                lda actXH,x
                sta temp1
                lda actXH+ACTI_PLAYER
                sta DLC_CmpX+1
                lda actMB,x
                eor #MB_GROUNDED
                asl
                lda actYH,x                     ;If grounded, check 1 block higher
                sbc #$00
                sta temp2
                lda actMB+ACTI_PLAYER
                eor #MB_GROUNDED
                asl
                lda actYH+ACTI_PLAYER
                sbc #$00
                sta DLC_CmpY+1
                sta DLC_CmpY2+1
                lda #MAX_LINE_STEPS
                sta temp3
                ldy temp2                       ;Take initial maprow
                lda mapTblLo,y
                sta zpSrcLo
                lda mapTblHi,y
                sta zpSrcHi
DLC_Loop:       ldy temp1
DLC_CmpX:       cpy #$00
                bcc DLC_MoveRight
                bne DLC_MoveLeft
                ldy temp2
DLC_CmpY:       cpy #$00
                bcc DLC_MoveDown
                bne DLC_MoveUp
                beq DLC_HasLine
DLC_MoveRight:  iny
                bcc DLC_MoveXDone
DLC_MoveLeft:   dey
DLC_MoveXDone:  sty temp1
                ldy temp2
DLC_CmpY2:      cpy #$00
                bcc DLC_MoveDown
                beq DLC_MoveYDone2
DLC_MoveUp:     dey
                bcs DLC_MoveYDone
DLC_MoveDown:   iny
DLC_MoveYDone:  sty temp2
                lda mapTblLo,y
                sta zpSrcLo
                lda mapTblHi,y
                sta zpSrcHi
DLC_MoveYDone2: dec temp3
                beq DLC_NoLine
                ldy temp1
                lda (zpSrcLo),y
                tay
                lda blkInfo,y
                and #BI_WALL
                beq DLC_Loop
                bne DLC_NoLine
DLC_HasLine:    lda actFlags,x
                ora #AF_HASLINE
                sta actFlags,x
                lda #$00                        ;When enemy has line, calculate health (danger) rank
                sta temp1                       ;to see which enemies should hunt the player
                stx temp2
                ldy #ACTI_LASTCOMPLEX
DLC_HealthRankLoop:
                cpy temp2                       ;Do not compare to self
                beq DLC_HealthRankSkip
                lda actFlags,y
                and #AF_LINECHECK|AF_HASLINE    ;Only compare to enemies which also have line-of-sight
                cmp #AF_LINECHECK|AF_HASLINE
                bne DLC_HealthRankSkip
                lda actHp,y
                cmp actHp,x
                bcc DLC_HealthRankSkip
                bne DLC_HealthRankIncrease
                cpy temp2                       ;If health same, lowest actor index (first updated)
                bcs DLC_HealthRankSkip          ;has precedence
DLC_HealthRankIncrease:
                inc temp1
DLC_HealthRankSkip:
                dey
                bne DLC_HealthRankLoop
                lda temp1
                sta actEnemyRank,x
DLC_NoLine:
DLC_Skip:       rts

        ; Get fire dir for enemies that fire into multiple dirs like player
        ; Normally checks enemy ranking for whether to attack or to freemove instead
        ; but call GetFireDirNoRank for enemies that don't actively hunt the player,
        ; to make sure they fire at each opportunity
        ;
        ; Parameters: X actor index
        ; Returns: A:fire controls, or
        ;          $00 Too far
        ;          $ff Too close (should freemove)
        ; Modifies: A,Y,temp vars

GetFireDir:     lda actEnemyRank,x
                cmp #MAX_ACTIVE_ENEMIES
                bcs GFD_TooClose                ;Freemove if too low rank to hunt the player
GetFireDirNoRank:
                lda playerCtrl                  ;If control override on, do not attack player
                bmi GFD_TooClose
                lda actFlags,x
                and #AF_HASLINE
                beq GFD_TooClose                ;If no line of sight (wall in between) freemove
                lda actHp+ACTI_PLAYER
                beq GFD_TooClose                ;If player dead, freemove
                lda actYH+ACTI_PLAYER
                ldy #AL_AIMYADJUST              ;Inlined version of GetActorDistance to eliminate JSR + distance always to player
                clc                             ;(plus aim Y-offset calculation streamlined)
                adc (actLo),y
                sec
                sbc actYH,x
                sta temp7
                bpl GFD_YDistPos
                sbc #$00
                eor #$ff
GFD_YDistPos:   sta temp8
                lda actXH+ACTI_PLAYER
                sec
                sbc actXH,x
                sta temp5
                bpl GFD_XDistPos
                sbc #$00
GFD_XDistNegOK: eor #$ff
GFD_XDistPos:   sta temp6
                bne GFD_NotTooClose             ;If X-dist zero and Y-dist very close to zero, freemove
                lda temp8
                beq GFD_TooClose
                cmp #$01
                beq GFD_TooClose
GFD_NotTooClose:ldy #AL_ATTACKDIRS
                lda (actLo),y
                sta temp1                       ;Store valid attack dirs
                lda temp7
                beq GFD_CheckHorizontal
                cmp #$ff
                beq GFD_CheckHorizontal
                lda temp6
                beq GFD_CheckVertical
GFD_CheckDiagonal:
                lda temp8
                ldy #AL_MAXATTACKDISTVERT
                cmp (actLo),y
                bcs GFD_NoDir
                lda temp6
                ldy #AL_MAXATTACKDISTANCE
                cmp (actLo),y
                bcs GFD_NoDir
                clc
                sbc temp8                       ;Allow one block different distance in X/Y
                beq GFD_DiagonalOK
                cmp #$fe
                bcs GFD_DiagonalOK
GFD_NoDir:      lda #$00
GFD_NoDir2:     rts
GFD_TooClose:   lda #$ff
                rts
GFD_DiagonalOK: lda temp7
                bmi GFD_DiagonalUp
GFD_DiagonalDown:
                lda temp1
                and #AB_DIAGONALDOWN
                beq GFD_NoDir2
GFD_DiagonalDownOK:
                lda temp5
                bmi GFD_DiagonalDownLeft
GFD_DiagonalDownRight:
                lda #JOY_FIRE+JOY_DOWN+JOY_RIGHT
                rts
GFD_DiagonalDownLeft:
                lda #JOY_FIRE+JOY_DOWN+JOY_LEFT
                rts
GFD_DiagonalUp: lda temp1
                and #AB_DIAGONALUP
                beq GFD_NoDir2
                lda temp5
                bmi GFD_DiagonalUpLeft
GFD_DiagonalUpRight:
                lda #JOY_FIRE+JOY_UP+JOY_RIGHT
                rts
GFD_DiagonalUpLeft:
                lda #JOY_FIRE+JOY_UP+JOY_LEFT
                rts
GFD_CheckVertical:
                lda temp8
                ldy #AL_MAXATTACKDISTVERT
                cmp (actLo),y
                bcs GFD_NoDir
                lda temp7
                bmi GFD_Up
GFD_Down:       lda temp1
                and #AB_DOWN
                beq GFD_NoDir2
                lda #JOY_FIRE+JOY_DOWN
                rts
GFD_Up:         lda temp1
                lsr
                bcc GFD_NoDir
                lda #JOY_FIRE+JOY_UP
                rts
GFD_CheckHorizontal:
                lda temp1
                bmi GFD_NoTooCloseCheck
                lda temp6                       ;If player is ducking close to enemy, fire diagonally down if can
                cmp #2
                bcc GFD_TooClose
                cmp #4
                bcs GFD_NoDuckCheck
                lda temp1
                and #AB_DIAGONALDOWN
                beq GFD_NoDuckCheck
                lda actF1+ACTI_PLAYER
                cmp #FR_DUCK+1
                beq GFD_DiagonalDownOK
GFD_NoDuckCheck:lda temp1
GFD_NoTooCloseCheck:
                and #AB_HORIZONTAL
                beq GFD_NoDir2
                lda temp6
                ldy #AL_MAXATTACKDISTANCE
                cmp (actLo),y
                bcs GFD_NoDir
                lda temp5
                bmi GFD_Left
                lda #JOY_FIRE+JOY_RIGHT
                rts
GFD_Left:       lda #JOY_FIRE+JOY_LEFT
                rts

        ; Flicker and generate explosions, then remove when time is expired
        ;
        ; Parameters: X dying actor index, Y index to explosion parameters
        ; Returns: C=1 if explosion generated, index in Y
        ; Modifies: A,Y,temp vars

GenerateExplosionsAndFlicker:
                lda actFlash,x
                ora #COLOR_FLICKER
                sta actFlash,x
                dec actTime,x
                bmi GEAF_Remove
GenerateExplosions:
                jsr Random
                and explProbability,y
                adc actAttackD,x
                sta actAttackD,x
                bcc GEAF_NoExplosion
GenerateExplosion:
                jsr Random
                pha
                and #$7f
                adc explXAddLo,y                ;C=0
                cmp #$80
                and #$7f
                sta temp1
                pla
                and explXRangeHi,y
                adc explXAddHi,y
                sta temp2
                jsr Random
                pha
                and #$7f
                adc explYAddLo,y                ;C=0
                cmp #$80
                and #$7f
                sta temp3
                pla
                and explYRangeHi,y
                adc explYAddHi,y
                sta temp4
                jsr GetFreePersistentActor
                bcc GEAF_NoExplosion
                lda #ACT_EXPLOSION
                jsr SpawnWithOffset
                lda #SFX_EXPLOSION
                jsr QueueSfx
                sec
GEAF_NoExplosion:
                rts
GEAF_Remove:    clc
                jmp RemoveActor

        ; Drop random item on death
        ;
        ; Parameters: X actor index
        ; Returns: -
        ; Modifies: A,Y, temp vars

DropItem:
DI_HealthInterval:lda #$00                      ;Pickups since last health
                beq DI_CanDropHealth
                dec DI_HealthInterval+1
                ldy #$06
                bne DI_NoHealthChance
DI_CanDropHealth:
                lda actHp+ACTI_PLAYER
                lsr
                lsr
                lsr
                tay
DI_NoHealthChance:
                lda healthDropTbl,y             ;Health drop probability from table
                sta temp1
                ldy #$08                        ;Compare value for fuel
                lda upgrade
                lsr
                bcc DI_NoFuelChance
                lda fuel
                cmp #MAX_FUEL*2/3
                bcs DI_NoFuelChance
                dey
                cmp #MAX_FUEL*1/3
                bcs DI_NoFuelChance
                dey
DI_NoFuelChance:sty temp2
                jsr Random
                and #$07
                cmp temp1
                bcc DI_NoHealth
                ldy #ITEM_HEALTH
                bcs DI_HealthOrFuel
DI_NoHealth:    cmp temp2
                bcc DI_WeaponOrParts
                ldy #ITEM_FUEL
DI_HealthOrFuel:lda #$01                        ;Only 1 same at a time
                jsr DI_CheckSameItem
                bcc DI_ItemTypeOK               ;Health/fuel pickup OK
DI_WeaponOrParts:
                ldy actWpn,x                    ;If "no weapon" drop parts
                bmi DI_Parts
                cpy #WPN_WHEELMINE              ;Transform enemy special weapons into SMG
                bcc DI_WpnOK
                ldy #WPN_SMG
DI_WpnOK:       cmp ammoHi,y                    ;Ammo probability from amount of ammo player has
                bcc DI_Parts
                bne DI_WpnOK2
                lda ammoLo,y                    ;If on the edge, check ammo lowpart (no drop if ammo >= $780)
                bpl DI_WpnOK2
DI_Parts:       ldy #AL_INITIALHP               ;Determine parts amount from enemy initial health
                lda (actLo),y
                ldy #ITEM_PARTS
DI_DeterminePartSizeLoop:
                cmp enemyPartsTbl-ITEM_PARTS,y  ;Table overflows into value $c1, no enemy should have that much health;
                bcc DI_DeterminePartSizeDone    ;rather use damage multiplier for bosses that need more
                iny
                bne DI_DeterminePartSizeLoop
DI_DeterminePartSizeDone:
DropExplicitItem:
DI_WpnOK2:      lda #$02                        ;Only 2 same weapons or parts at a time
                jsr DI_CheckSameItem
                bcs DI_NoDrop
DI_ItemTypeOK:  sty temp5                       ;Final item type
                lda actFlags,x
                and #AF_GROUPBITS
                cmp #GRP_CREATURES              ;Creature type enemies can only drop health
                bne DI_NotCreature
                cpy #ITEM_HEALTH
                bne DI_NoDrop
DropExplicitItemNoGroupCheck:
DI_NotCreature: jsr GetFreePersistentActor
                bcc DI_NoRoom
                lda #ACT_ITEM
                jsr SpawnActor
                jsr InitSpawnedActor
                lda actFlags,x                  ;No removecheck for dropped item, let stay on screen
                ora #AF_NOREMOVECHECK           ;until time expires
                sta actFlags,x
                lda #DROPPED_ITEM_TIME
                sta actTime,x
                lda temp5
                sta actF1,x                     ;If health pickup spawn was finally successful, set delay
                cmp #ITEM_HEALTH                ;for next appearance
                bne DI_NoHealthDelay
                lda #HEALTH_PICKUP_INTERVAL
                sta DI_HealthInterval+1
DI_NoHealthDelay:
                lda #-2*8                       ;No removecheck for dropped items, they can always get an up speed boost
                sta actSY,x                     ;for nicer trajectory
DI_XSpeed:      lda #$00                        ;If set to nonzero, must also be reset by caller
                sta actSX,x
DI_NoFlyUp:     ldy actIndex
                lda actSizeU,y
                cmp #127/8                      ;Adjust item height from actor Y-size
                bcc DI_NotTooHigh
                lda #127/8
DI_NotTooHigh:  asl
                asl
                asl
                jsr MoveActorYNeg
                lda actSizeD,y
                cmp #127/8
                bcc DI_NotTooLow
                lda #127/8
DI_NotTooLow:   asl
                asl
                asl
                jsr MoveActorY
                ldx actIndex
DI_NoDrop:
DI_NoRoom:      rts

DI_CheckSameItem:
                sta temp7
                txa
                pha
                tya
                pha
                lda itemFrames,y                ;Compare frames instead of item types,
                sta temp6                       ;so that all size parts are compared as same
                lda #$00
                sta temp8
                ldx #ACTI_LASTPERSISTENT
DI_CheckSameLoop:
                lda actT,x
                cmp #ACT_ITEM
                bne DI_CheckSameNext
                ldy actF1,x
                lda itemFrames,y
DI_CheckType:   cmp temp6
                bne DI_CheckSameNext
                inc temp8
DI_CheckSameNext:
                dex
                bne DI_CheckSameLoop
                pla
                tay
                pla
                tax
                lda temp8
                cmp temp7
                rts

        ; Spawn an item actor at a levelobject
        ;
        ; Parameters: X levelobject index
        ; Returns: C=1 if successful, actor index in X
        ; Modifies: A,X,Y,temp vars

ItemSpawnCommon:jsr GetFreePersistentActor
                bcc ItemSpawn_NoActor
ItemSpawn_HasActor:
                lda lvlObjX,x
                sta actXH,y
                lda lvlObjY,x
                sta actYH,y
                lda #$30
                sta actXL,y
                lda #$7f
                sta actYL,y
                lda #ACT_ITEM
                sta actT,y
                jsr InitSpawnedActor
                sec
ItemSpawn_NoActor:
                rts

