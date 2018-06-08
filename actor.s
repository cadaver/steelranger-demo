MAX_ACTX        = 25
MAX_ACTY        = 16

AD_NUMSPRITES   = 0
AD_SPRFILE      = 1
AD_LEFTFRADD    = 2
AD_NUMFRAMES    = 3                             ;For incrementing framepointer. Only significant if multiple sprites
AD_FRAMES       = 4

ADD_SPRFILE     = 1
ADD_BASEFRAME   = 2

ADH_SPRFILE     = 1
ADH_BASEFRAME   = 2
ADH_BASEINDEX   = 3                             ;Index to a static 256-byte table for humanoid actor spriteframes
ADH_LEFTFRADD   = 4
ADH_SPRFILE2    = 5
ADH_BASEFRAME2  = 6
ADH_BASEINDEX2  = 7                             ;Index to a static 256-byte table for humanoid actor framenumbers
ADH_LEFTFRADD2  = 8

AL_UPDATEROUTINE = 0
AL_ACTORFLAGS   = 2
AL_SIZEHORIZ    = 3
AL_SIZEUP       = 4
AL_SIZEDOWN     = 5
AL_INITIALHP    = 6
AL_DAMAGEMOD    = 7
AL_DESTROYROUTINE = 8
AL_MAXSPEED     = 10
AL_ATTACKDIRS   = 11
AL_MAXATTACKDISTANCE = 12
AL_MAXATTACKDISTVERT = 13
AL_AIMYADJUST   = 14
AL_MAXSPEEDVERT = 15
AL_ACCELERATION = 16

GRP_HEROES      = $00
GRP_ENEMIES     = $01
GRP_CREATURES   = $02
GRP_NEUTRAL     = $03

AF_GROUPBITS    = $03
AF_TAKEDAMAGE   = $04
AF_INITONLYSIZE = $08
AF_GROUNDBASED  = $10
AF_LINECHECK    = $20
AF_HASLINE      = $40
AF_NOREMOVECHECK = $80

ONESPRITE       = $00
TWOSPRITE       = $01
THREESPRITE     = $02
FOURSPRITE      = $03
FIVESPRITE      = $04
SIXSPRITE       = $05
SEVENSPRITE     = $06
NINESPRITE      = $08
ELEVENSPRITE    = $0a
HUMANOID        = $80

COLOR_FLICKER   = $40
COLOR_INVISIBLE = $80
COLOR_ONETIMEFLASH = $80

NODAMAGESRC     = $80

COLLISION_ADJUST = $40

NO_MODIFY       = 8

SCROLLCENTER_X  = 155
SCROLLCENTER_Y  = 147

GLOBAL          = $20
RESPAWN         = $40
NONPERSISTENT   = $80

NUMADDACT       = 12                            ;Actors to check on one frame

USESCRIPT       = $8000                         ;Use script entrypoint for actor update / destroy

        ; Draw actors as sprites
        ; Accesses the sprite cache to load/unpack new sprites as necessary
        ; Automatically followed by AddActors, though it can also be called separately to add all
        ;
        ; Parameters: -
        ; Returns: -
        ; Modifies: A,X,Y,temp vars,actor ZP temp vars

DrawActors:     lda DA_SprSubXL+1               ;Copy current spr.pos subtract for InterpolateActors
                sta IA_PrevSprSubXL+1           ;to see how scrolling has changed
                lda DA_SprSubYL+1
                sta IA_PrevSprSubYL+1
                ldx GASS_CurrentFrame+1
                stx GASS_LastFrame+1
DA_IncCacheFrame:
                inx                             ;Increment framenumber for sprite cache
                beq DA_IncCacheFrame            ;(framenumber is never 0)
                stx GASS_CurrentFrame+1
                stx GASS_CurrentFrame2+1
DA_CheckCacheAge:
                lda #MAX_CACHESPRITES-1
                and #MAX_CACHESPRITES-1
                tay
                txa
                sec                             ;If age stored in cache is older than significant, reset
                sbc cacheSprAge,y               ;to prevent overflow error (check one sprite per frame)
                cmp #$04
                bcc DA_CacheAgeOK
                lda #$00
                sta cacheSprAge,y
DA_CacheAgeOK:  dec DA_CheckCacheAge+1
                ldx #$00                        ;Reset amount of used sprites / bullet targets
                stx sprIndex
                stx numTargets

DA_Loop:        lda actT,x
                beq DA_Next
DA_ActorExists: lda actYL,x                     ;Convert actor coordinates to screen
                sta actPrevYL,x
                sec
DA_SprSubYL:    sbc #$00
                sta temp3
                lda actYH,x
                sta actPrevYH,x
DA_SprSubYH:    sbc #$00
                cmp #MAX_ACTY                   ;Skip if significantly outside the screen
                bcs DA_ActorOutside
                tay
                lda temp3
                lsr
                lsr
                lsr
                and #$0f
                ora yCoordTbl,y
                sta temp3                       ;Y pos
                lda #$00
                cpy #$0e                        ;Calculate 8-bit bounds for collision detection
                lda temp3
                ror
                clc
                adc #COLLISION_ADJUST           ;Avoid negative-to-positive overflow at left/top border
                tay
                clc
                adc actSizeD,x
                sta actBoundD,x
                tya
                sec
                sbc actSizeU,x
                sta actBoundU,x
                lda actXL,x
                sta actPrevXL,x
                ;sec                            ;The previous subtraction should not underflow
DA_SprSubXL:    sbc #$00
                sta temp1
                lda actXH,x
                sta actPrevXH,x
DA_SprSubXH:    sbc #$00
                cmp #MAX_ACTX                   ;Skip if significantly outside the screen
                bcs DA_ActorOutside
DA_ShouldDraw:  if SHOW_DRAWACTOR_TIME > 0
                dec $d020
                endif
                jsr DrawActorSub_CalcXPos
                if SHOW_DRAWACTOR_TIME > 0
                inc $d020
                endif
                stx sprIndex
                ldx actIndex
DA_Next:        inx
                cpx #MAX_ACT
                bcc DA_Loop
                bcs DA_FillSprites

DA_ActorOutside:lda #$00                        ;If actor outside visible screen, clear collision
                sta actBoundL,x
                sta actBoundR,x
                beq DA_Next

DA_FillSprites: ldx sprIndex                    ;If less sprites used than last frame, set unused Y-coords to max.
                if SHOW_NUM_SPRITES > 0
                stx $d020
                endif
                lda #$ff
DA_FillSpritesLoop:
                sta sprY,x
                inx
DA_LastSprIndex:cpx #$00
                bcc DA_FillSpritesLoop
DA_FillSpritesDone:
                ldx sprIndex
                stx DA_LastSprIndex+1
                ldy numTargets                  ;Store target list endmark
                sta targetList,y
                if SHOW_LINECHECK_TIME > 0
                inc $d020
                endif
DA_LineCheckActor:
                ldx #$00
                jsr DoLineCheck                 ;Perform linecheck for one actor
                inx
                cpx #ACTI_LASTCOMPLEX+1
                bne DLC_NotOver
                ldx #ACTI_FIRST
DLC_NotOver:    stx DA_LineCheckActor+1
                if SHOW_LINECHECK_TIME > 0
                dec $d020
                endif
                rts

        ; Add actors to screen. Also set border compare values for the remove check in UpdateActors
        ;
        ; Parameters: -
        ; Returns: -
        ; Modifies: A,X,Y,temp vars,actor ZP temp vars

AddActors:      lda mapX
                clc
                adc #22
                sta AA_RightCmp+1
                sta UA_RemoveRightCmp+1
                lda mapX
                sbc #$01                        ;C=0, subtract one more
                bcs AA_LeftLimitOK
                lda #$00
AA_LeftLimitOK: sta AA_LeftCmp+1
                sta UA_RemoveLeftCmp+1
                lda mapY
                clc
                adc #13
                sta AA_BottomCmp+1
                sta UA_RemoveBottomCmp+1
                sbc #13                         ;C=0, subtract one more
                bcs AA_TopLimitOK
                lda #$00
AA_TopLimitOK:  sta AA_TopCmp+1
                sta UA_RemoveTopCmp+1
AA_Start:       ldy #$00
                if SHOW_ADDACTOR_TIME > 0
                inc $d020
                endif
AA_Loop:        ldx zoneActIndex,y
                bmi AA_EndMark                 ;Endmark?
                lda lvlActT,x
                beq AA_Skip
                lda lvlActX,x
AA_LeftCmp:     cmp #$00
                bcc AA_Skip
AA_RightCmp:    cmp #$00
                bcs AA_Skip
                lda lvlActY,x
AA_TopCmp:      cmp #$00
                bcc AA_Skip
                sty temp1
                ldy lvlActT,x                   ;Bottom adjust only for some actors
                cpy #ACT_LASTBOTTOMADJUST+1
                bcs AA_NoBottomAdjust
                adc actBottomAdjustTbl-1,y
AA_NoBottomAdjust:
                ldy temp1
AA_BottomCmp:   cmp #$00
                bcs AA_Skip
                jsr TryAddActor
                ldy temp1
AA_Skip:        iny
AA_EndCmp:      cpy #$00
                bcc AA_Loop
AA_SetNextFrame:sty AA_Start+1
                tya
                adc #NUMADDACT-1                ;Continue on next frame
                sta AA_EndCmp+1
                if SHOW_ADDACTOR_TIME > 0
                dec $d020
                endif
                rts
AA_EndMark:     ldy #$00                        ;If reach endmark, start over on next frame
                sec
                jmp AA_SetNextFrame

        ; Call update routines of all actors
        ;
        ; Parameters: -
        ; Returns: -
        ; Modifies: A,X,Y,temp vars,actor ZP temp vars

UA_DoDamage:    lda actHp,x                     ;If hitpoints are already 0, special case for multipart enemy,
                beq UA_SkipDamage               ;let the main part handle the damage
                lda actFlags,x
                and #AF_TAKEDAMAGE
                beq UA_NoDamage2                ;If damage flag not on, just reset the accumulator
                lda actFlash,x                  ;(e.g. player during conversations)
                ora #COLOR_ONETIMEFLASH
                sta actFlash,x
                ldy #AL_DAMAGEMOD
                lda (actLo),y
                tay
                lda actDmg,x
                and #$7f
                jsr ModifyDamage
                sta temp8
                lda actHp,x
                sec
                sbc temp8
                bcs UA_NotBelowZero
                lda #$00
UA_NotBelowZero:sta actHp,x
                php
                txa
                bne UA_NotPlayer
UA_PlayerDamageCode:
                if HEALTH_CHEAT > 0
                lda #HP_PLAYER
                sta actHp+ACTI_PLAYER
                else
                lda #DAMAGE_HEALTHRECHARGE_DELAY
                jsr SetHealthRechargeDelay      ;Trashes X
                endif
                ldx #ACTI_PLAYER
UA_NotPlayer:   lda actDmg,x                    ;If player caused damage, check for firing up the analyzer upgrade
                bpl UA_NoAnalysis
                lda upgrade
                and #UPG_TECHANALYZER|UPG_BIOANALYZER
                beq UA_NoAnalysis
                cmp #UPG_TECHANALYZER           ;If have only the tech analyzer version, no HP shown for creature enemies
                bne UA_AnalysisOK
                lda actFlags,x
                and #AF_GROUPBITS
                cmp #GRP_ENEMIES
                bne UA_NoAnalysis
UA_AnalysisOK:  jsr SetRedrawAnalyzer
UA_NoAnalysis:  plp
                beq UA_Destroy
                lda #$00
UA_NoDamage2:   sta actDmg,x                    ;Reset damage accumulator for next frame
UA_SkipDamage:  jmp UA_NoDamage
UA_Destroy:     lda actFlags,x                  ;Make sure will not take part in further collision detection
                and #$ff-AF_TAKEDAMAGE
                sta actFlags,x
                lda actOrg,x                    ;Store origin to temp1 for inspection by the destroy routine
                sta temp1
                lda #NONPERSISTENT              ;Also, not persisted to leveldata any longer
                sta actOrg,x
                lda actT,x                      ;Hack for barrel: no score
                cmp #ACT_BARREL
                beq UA_DestroyNoScore
                lda actDmg,x                    ;Add score if last damage from player
                bpl UA_DestroyNoScore
                jsr AddDestroyScore
UA_DestroyNoScore:
                ldy #AL_DESTROYROUTINE+1        ;Use same system as update call, either direct or through loadable code
                jmp UA_ActorCall

UA_Remove:      jsr RemoveLevelActor
                jmp UA_Next

AddAndUpdateAllActors:
                lda #$00
                sta AH_GlobalAttackDelay+1
                sta AA_Start+1
                lda #MAX_ZONEACT
                sta AA_EndCmp+1
                jsr AddActors
                ldx #ACTI_LASTCOMPLEX
CheckAllLines:  jsr DoLineCheck
                dex
                bne CheckAllLines

UpdateActors:   jsr GetControls                 ;Get controls for this frame
                lda playerCtrl                  ;Joystick or override controls for player (dialogue / cutscenes)
                bmi UA_HasCtrlOverride
                lda joystick
                sta playerCtrl
UA_HasCtrlOverride:
                lda actSX+ACTI_PLAYER           ;Store speed before potential wallhit for zone transition
                sta ZT_PlayerXSpeed+1
                ldx #MAX_ACT-1
                stx Irq1_AnimateLevel+1         ;Allow to animate level now
                stx TryPickup+1                 ;Allow item pickup
                if SHOW_NUM_ACTORS > 0
                lda #$00
                sta UA_ActorCount+1
                endif
                lda AH_GlobalAttackDelay+1      ;Decrement global enemy attack counter now
                beq UA_Loop
                dec AH_GlobalAttackDelay+1
UA_Loop:        ldy actT,x
                beq UA_Next
                stx actIndex
                stx ES_Param+1                  ;Store always to ES_Param too for NPC scripts
                lda actFlags,x                  ;Perform remove check?
                bmi UA_NoRemoveCheck
                lda actXH,x
UA_RemoveLeftCmp:
                cmp #$00
                bcc UA_Remove
UA_RemoveRightCmp:
                cmp #$00
                bcs UA_Remove
                lda actYH,x
UA_RemoveTopCmp:
                cmp #$00
                bcc UA_Remove
                cpy #ACT_LASTBOTTOMADJUST+1
                bcs UA_RemoveBottomCmp
                adc actBottomAdjustTbl-1,y
UA_RemoveBottomCmp:
                cmp #$00
                bcs UA_Remove
UA_NoRemoveCheck:
                jsr GetActorLogicData
                lda actDmg,x                    ;Check for receiving damage
                beq UA_NoDamage
                jmp UA_DoDamage
UA_NoDamage:    ldy #AL_UPDATEROUTINE+1
                if SHOW_NUM_ACTORS > 0
                inc UA_ActorCount+1
                endif
UA_ActorCall:   if SHOW_UPDATEACTOR_TIME > 0
                inc $d020
                endif
                lda (actLo),y
                bpl UA_NoScript
UA_UseScript:   and #$7f                        ;Call updateroutine from script
                tax
                dey
                lda (actLo),y
                jsr ExecScript
                jmp UA_Next2
                if CHECK_ACTINDEX > 0
UA_Fail:        inc $d020
                jmp UA_Fail
                endif
UA_NoScript:    sta UA_Jump+2
                dey
                lda (actLo),y
                sta UA_Jump+1
UA_Jump:        jsr $1000
UA_Next2:       if SHOW_UPDATEACTOR_TIME > 0
                dec $d020
                endif
                if CHECK_ACTINDEX > 0
                cpx actIndex
                bne UA_Fail
                endif
UA_Next:        dex
                bpl UA_Loop
UA_AllDone:     if SHOW_NUM_ACTORS > 0
UA_ActorCount:  lda #$00
                sta $d020
                endif
                inc UA_ItemFlashCounter+1
UA_ItemFlashCounter:                            ;Get color override for items + object marker
                lda #$00
                lsr
                lsr
                and #$03
                tax
                lda itemFlashTbl,x
                sta FlashActor+1

        ; Scan for levelobjects at player after actor update
        ;
        ; Parameters: -
        ; Returns: -
        ; Modifies: A,X,Y,temp vars

ScanLevelObject:lda actT+ACTI_PLAYER            ;If no player actor, no scan + no scrolling change
                bne SLO_OK
                jmp SP_SkipScroll
SLO_OK:         ldx actXH+ACTI_PLAYER           ;Rescan objects if player occupies different block now
                ldy actYH+ACTI_PLAYER
SLO_LastX:      cpx #$ff
                bne SLO_Rescan
SLO_LastY:      cpy #$ff
                beq SLO_NoScan
SLO_Rescan:     if SHOW_OBJECTSCAN_TIME > 0
                inc $d020
                endif
                stx SLO_LastX+1
                sty SLO_LastY+1
                lda #<zoneObjIndex
                sta SLO_ScanLoop+1
                ldy #NO_OBJECT                  ;Assume no object found
                sty adjacentObj
SLO_At:         sty atObj
SLO_ScanLoop:   ldy zoneObjIndex
                bmi SLO_ScanDone
                inc SLO_ScanLoop+1
                jsr GetLevelObjectCenter
                sta temp7                       ;X center
                lda SLO_LastY+1
                sec
                sbc temp8
                cmp #$03                        ;Check Y range
                bcs SLO_ScanLoop
                lda actXH+ACTI_PLAYER
                sec
                sbc temp7
                beq SLO_At
                cmp #$01
                beq SLO_Adjacent
                cmp #$ff
                bne SLO_ScanLoop
SLO_Adjacent:   sty adjacentObj
                lda atObj                       ;If has both "at" and "adjacent" objects,
                bmi SLO_ScanLoop                ;can terminate search now
SLO_ScanDone:   if SHOW_OBJECTSCAN_TIME > 0
                dec $d020
                endif
SLO_NoScan:

        ; Scroll screen according to player actor position
        ;
        ; Parameters: -
        ; Returns: -
        ; Modifies: A,X,Y,temp vars

ScrollPlayer:
SP_ScrollCenterX:
                ldy #-(SCROLLCENTER_X-16)
                lda actD+ACTI_PLAYER
                bpl SP_ScrollFacingRight
SP_ScrollFacingLeft:
                cpy #-(SCROLLCENTER_X+16)
                beq SP_ScrollCenterOK
                dey
                dey
                bne SP_ScrollCenterOK
SP_ScrollFacingRight:
                cpy #-(SCROLLCENTER_X-16)
                beq SP_ScrollCenterOK
                iny
                iny
SP_ScrollCenterOK:
                sty SP_ScrollCenterX+1
                tya
                clc
                adc actBoundR+ACTI_PLAYER
                sec
                sbc actSizeH+ACTI_PLAYER
                bmi SP_ScrollLeft
SP_ScrollRight: cmp #2*8
                bcc SP_ScrollHorizOK
                lda #2*8
                bne SP_ScrollHorizOK
SP_ScrollLeft:  cmp #-2*8
                bcs SP_ScrollHorizOK
                lda #-2*8
SP_ScrollHorizOK:
                asl
                sta scrollSX
                lda actBoundD+ACTI_PLAYER
                sec
SP_ScrollCenterY:
                sbc #SCROLLCENTER_Y
                bmi SP_ScrollUp
SP_ScrollDown:  cmp #3*8
                bcc SP_ScrollVertOK
                lda #3*8
                bne SP_ScrollVertOK
SP_ScrollUp:    cmp #-3*8
                bcs SP_ScrollVertOK
                lda #-3*8
SP_ScrollVertOK:clc
                adc #3*8
                tay
                lda yScrollSpdTbl,y
SP_StoreYSpeed: sta scrollSY
SP_SkipScroll:

        ; Update radio messages, dialogue, and tick script
        ;
        ; Parameters: -
        ; Returns: -
        ; Modifies: A,X,Y,temp vars

                lda actHp+ACTI_PLAYER           ;No radio message triggering if dead
                beq ULO_NoRadioMsg
                ldx radioMsgF                   ;Radio message execution
                bmi ULO_NoRadioMsg
                lda radioMsgDelay               ;Wait delay if any (0 = always immediate, even if enemies)
                beq ULO_NoRadioMsgDelay
                lda numTargets                  ;Delay until player is free of enemies
                cmp #2
                bcs ULO_NoRadioMsg
                dec radioMsgDelay
                bcc ULO_NoRadioMsg
ULO_NoRadioMsgDelay:
                txa
                clc
                adc #C_FIRSTSCRIPT
                tay
                lda radioMsgEP
                pha
                jsr LoadChunkFile               ;Get text object address to zpSrcLo/Hi
                pla
                asl                             ;High bit to distinguish human / machine communications
                lda #SFX_RADIO
                adc #$00
                jsr QueueSfx
                ldx #$ff                        ;No actor speaking
                stx radioMsgF                   ;Do not trigger twice
                jsr UD_CopyDialoguePtr
                jsr NPCDialogue_NoBubble
ULO_NoRadioMsg: lda dialogueHi                  ;Update dialogue if running
                beq ULO_NoDialogue
                jsr UpdateDialogue
ULO_NoDialogue: ldx scriptF                     ;Exec continuous (per-tick) script
                bmi ULO_NoTickScript
                lda scriptEP
                jmp ExecScript
ULO_NoTickScript:
                rts
                
        ; Interpolate actors' movement each second frame
        ;
        ; Parameters: -
        ; Returns: -
        ; Modifies: A,X,Y,temp vars

InterpolateActors:
                if SHOW_INTERPOLATEACTOR_TIME > 0
                inc $d020
                endif
IA_PrevSprSubXL:lda #$00
                sec
                sbc DA_SprSubXL+1
                and #$7f
                lsr
                lsr
                lsr
                cmp #$08
                bcc IA_ScrollXNotNeg
                ora #$f0
IA_ScrollXNotNeg:
                sta IA_ScrollXAdjust+1
IA_PrevSprSubYL:lda #$00
                sec
                sbc DA_SprSubYL+1
                and #$7f
                lsr
                lsr
                lsr
                cmp #$08
                bcc IA_ScrollYNotNeg
                ora #$f0
IA_ScrollYNotNeg:
                sta IA_ScrollYAdjust+1
                ldx DA_LastSprIndex+1
                dex
                bpl IA_SprLoop
                jmp IA_Done
IA_SprLoop:     lda sprC,x                      ;Process flickering
                cmp #COLOR_FLICKER
                bcc IA_NoFlicker
                eor #COLOR_INVISIBLE
                sta sprC,x
IA_NoFlicker:   ldy sprAct,x                    ;Take actor number associated with sprite
                lda actPrevYH,y                 ;Offset already calculated?
                bmi IA_AddOffset
                lda actXL,y                     ;Calculate average movement
                sec                             ;of actor in X-direction
                sbc actPrevXL,y                 ;(max. 31 pixels)
                sta temp1
                lda actXH,y
                sbc actPrevXH,y
                asl temp1
                lsr
                ror temp1
                lda temp1
                lsr
                lsr
                lsr
                lsr
                bit temp1
                bpl IA_XMovePos
                ora #$f0
                adc #$00
IA_XMovePos:    clc
IA_ScrollXAdjust:
                adc #$00                        ;Add scrolling
                cmp #$80
                ror                             ;Sign expand
                sta actPrevXH,y                 ;Store offset if needed for other sprites
                lda #$00
                bcc IA_XLSBPos
                sbc #$01                        ;Becomes $ff, C becomes 0 for next adc
IA_XLSBPos:     sta actPrevXL,y
                adc sprXLSB,x                   ;Apply X offset. LSB add is either $00
                and #$01                        ;or $ff, so that overflow sets carry
                sta sprXLSB,x                   ;without having to do separate compare
                lda actPrevXH,y
                adc sprX,x
                sta sprX,x
                lda actYL,y                     ;Calculate average movement
                sec                             ;of actor in Y-direction
                sbc actPrevYL,y                 ;(max. 31 pixels)
                sta temp1
                lda actYH,y
                sbc actPrevYH,y
                asl temp1
                lsr
                ror temp1
                lda temp1
                lsr
                lsr
                lsr
                lsr
                bit temp1
                bpl IA_YMovePos
                ora #$f0
                adc #$00
IA_YMovePos:    clc
IA_ScrollYAdjust:
                adc #$00                        ;Add scrolling
                sta actPrevYL,y
                clc
                adc sprY,x
                sta sprY,x                      ;Add offset to sprite
                lda #$ff                        ;Replace the Y-coord MSB with a marker
                sta actPrevYH,y                 ;so we don't repeat this calculation
IA_Next:        dex
                bmi IA_Done
                jmp IA_SprLoop

IA_AddOffset:   lda actPrevXL,y                 ;Add already calculated offset
                clc
                adc sprXLSB,x
                and #$01
                sta sprXLSB,x
                lda actPrevXH,y
                adc sprX,x
                sta sprX,x
                lda sprY,x
                clc
                adc actPrevYL,y
                sta sprY,x
                dex
                bmi IA_Done
                jmp IA_SprLoop
IA_Done:        if SHOW_INTERPOLATEACTOR_TIME > 0
                dec $d020
                endif
                rts

        ; Draw actor-related subroutines

DA_Invisible:   ldx sprIndex                    ;DrawActors expects sprIndex in X
                rts                             ;even if no sprites were used

DA_HitFlash:    lda actFlash,x
                and #$7f
                sta actFlash,x
                lda #$01
                bpl DA_NoFlicker

        ; Complete subroutine called by DrawActors

DrawActorSub_CalcXPos:
                tay
                lda temp1
                lsr
                lsr
                lsr
                lsr
                and #$07
                ora xCoordTbl,y
                sta temp1                       ;X pos
                bcs DA_LSBOne
DA_LSBZero:     ldy #$00
                beq DA_LSBDone
DA_LSBOne:      clc
                ldy #$01
DA_LSBDone:     sty GASS_XLSB+1
                adc #COLLISION_ADJUST           ;Avoid negative-to-positive overflow at left/top border
                tay
                clc
                adc actSizeH,x
                sta actBoundR,x
                tya
                sec
                sbc actSizeH,x
                sta actBoundL,x
                lda actFlags,x                  ;Add to target list if can take damage
                and #AF_TAKEDAMAGE
                beq DrawActorSub
                ldy numTargets
                txa
                sta targetList,y
                inc numTargets

        ; Stand-alone subroutine used in fake actor drawing for bullet spawn & precache

DrawActorSub:   lda actFlash,x                  ;Get programmatic color override
                bmi DA_HitFlash                 ;including one frame hit flash
                cmp #COLOR_FLICKER
                bcc DA_NoFlicker
                txa
                lsr
                lda #$00
                ror                             ;COLOR_INVISIBLE for odd actor indices
                ora actFlash,x                  ;Add the original override if any
DA_NoFlicker:   sta GASS_ColorOr+1
                ldy #$0f
                and #$0f
                beq DA_KeepSpriteColor
                ldy #$00
DA_KeepSpriteColor:
                sty GASS_ColorAnd+1
DrawActorSub_NoColor:
                stx actIndex
DA_SprFileLoaded:
                ldy actT,x
                lda actDispTblLo-1,y
                sta actLo
                lda actDispTblHi-1,y
                beq DA_Invisible
                bpl DA_NotInScript
DA_InScript:    clc
                adc #C_FIRSTSCRIPT-$80
                tay
                lda actLo
                jsr LoadChunkFile
                ldx actIndex
                lda zpSrcLo
                sta actLo
                lda zpSrcHi
DA_NotInScript: sta actHi
                ldy #AD_SPRFILE                 ;Get spritefile
                lda (actLo),y
                cmp sprFileNum
                beq DA_SameSprFile
                tay
                lda #$00                        ;Reset age whenever accessed
                sta fileAge,y
                lda fileHi,y
                bne DA_HasSpriteFile
                jsr LoadSpriteFile              ;After loading spritefile, re-get display data address in case it was relocated just now.
                bpl DA_SprFileLoaded            ;BPL is valid since X (actor index) is always positive
DA_HasSpriteFile:
                sta sprFileHi
                lda fileLo,y
                sta sprFileLo
                sty sprFileNum
DA_SameSprFile: ldy #AD_NUMSPRITES              ;Get number of sprites / humanoid flag
                clc
                lda (actLo),y
                bmi DA_Humanoid

DA_Normal:      sta temp5
                beq DA_OneSprite                 ;Next frame not needed if one sprite only
                ldy #AD_NUMFRAMES
                lda (actLo),y
                sta DA_NormalNextFrame+1
DA_OneSprite:   lda actF1,x
                ldy actD,x
                bpl DA_NormalRight
                ldy #AD_LEFTFRADD               ;Add left frame offset if necessary
                adc (actLo),y
DA_NormalRight: adc #AD_FRAMES
                ldx sprIndex
DA_NormalLoop:  tay
                lda (actLo),y
                dec temp5                       ;Decrement actor sprite count
                bmi DA_NormalLast
                sty temp6
                jsr GetAndStoreSprite
                lda temp6
                clc
DA_NormalNextFrame:
                adc #$00
                bcc DA_NormalLoop
DA_NormalLast:  if LASTSPRITE_OPTIMIZE > 0
                cpx #MAX_SPR                    ;Last sprite connectspot needed only for bullet spawnpoint
                beq DA_NormalLastAddConnectSpot ;(fake draw)
                jmp GetAndStoreLastSprite
DA_NormalLastAddConnectSpot:
                endif
                jmp GetAndStoreSprite

DA_Humanoid:    lda actFlash,x
                and #$30
                sta DA_Part2Color+1
                lda actF2,x
                ldy actD,x
                bpl DA_HumanRight2
                ldy #ADH_LEFTFRADD2             ;Add left frame offset if necessary
                adc (actLo),y
DA_HumanRight2: ldy #ADH_BASEINDEX2
                adc (actLo),y
                tay
                lda humanUpperFrTbl,y           ;Take sprite frame from the frametable
                ldy #ADH_BASEFRAME2
                adc (actLo),y
                sta temp5
                lda actF1,x
                ldy actD,x
                bpl DA_HumanRight1
                ldy #ADH_LEFTFRADD              ;Add left frame offset if necessary
                adc (actLo),y
DA_HumanRight1: ldy #ADH_BASEINDEX
                adc (actLo),y
                tay
                lda humanLowerFrTbl,y           ;Take sprite frame from the frametable
                ldy #ADH_BASEFRAME
                adc (actLo),y
                ldx sprIndex
                jsr GetAndStoreSprite
                ldy #ADH_SPRFILE2               ;Get second part spritefile
                lda (actLo),y
                cmp sprFileNum
                beq DA_SameSprFile2
                tay
                lda #$00                        ;Reset age whenever accessed
                sta fileAge,y
                lda fileHi,y
                bne DA_SprFileLoaded2
                jsr LoadSpriteFile              ;Actor definition no longer needed at this point, so don't care
DA_SprFileLoaded2:                              ;if it moves in memory
                sta sprFileHi
                lda fileLo,y
                sta sprFileLo
                sty sprFileNum
DA_SameSprFile2:
DA_Part2Color:  ldy #$00                        ;2nd part skin color override for the armorless characters
                beq DA_NoPart2Color
                lda humanoidUpperOverride-$10,y
                sta GASS_ColorOr+1
DA_NoPart2Color:lda temp5
                if LASTSPRITE_OPTIMIZE > 0
                jmp DA_NormalLast
                else
                jmp GetAndStoreSprite
                endif

        ; Stop actor X-speed
        ;
        ; Parameters: X actor index
        ; Returns: -
        ; Modifies: A

StopXSpeed:     lda #$00
                sta actSX,x
                rts

        ; Move actor in either negated or unmodified X-direction
        ;
        ; Parameters: X actor index, A speed, C direction
        ; Returns: -
        ; Modifies: A

MoveActorXNegOrPos:
                bcc MoveActorX

        ; Move actor in negated X-direction
        ;
        ; Parameters: X actor index, A speed
        ; Returns: -
        ; Modifies: A

MoveActorXNeg:  jsr Negate8

        ; Move actor in X-direction
        ;
        ; Parameters: X actor index, A speed
        ; Returns: -
        ; Modifies: A

MoveActorX:     cmp #$80
                bcc MAX_Pos
MAX_Neg:        clc
                adc actXL,x
                bpl MAX_Done
                dec actXH,x
MAX_Over:       and #$7f
MAX_Done:       sta actXL,x
                rts
MAX_Pos:        adc actXL,x
                bpl MAX_Done
                inc actXH,x
                jmp MAX_Over

        ; Move actor in either negated or unmodified Y-direction
        ;
        ; Parameters: X actor index, A speed, C direction
        ; Returns: -
        ; Modifies: A

MoveActorYNegOrPos:
                bcc MoveActorY

        ; Move actor in negated Y-direction
        ;
        ; Parameters: X actor index, A speed
        ; Returns: -
        ; Modifies: A

MoveActorYNeg:  jsr Negate8

        ; Move actor in Y-direction
        ;
        ; Parameters: X actor index, A speed
        ; Returns: -
        ; Modifies: A

MoveActorY:     cmp #$80
                bcc MAY_Pos
MAY_Neg:        clc
                adc actYL,x
                bpl MAY_Done
                dec actYH,x
MAY_Over:       and #$7f
MAY_Done:       sta actYL,x
                rts
MAY_Pos:        adc actYL,x
                bpl MAY_Done
                inc actYH,x
                jmp MAY_Over

        ; Apply damage impulse at moment of death
        ;
        ; Parameters: X dying actor index
        ; Returns: -
        ; Modifies: A,Y,temp8

ApplyDeathImpulse:
                lda actDmgImpulse,x
                asl                             ;Dir bit to carry, multiply by 2
                php
                cmp #$3f                        ;Limit to max. sensible acceleration (upgraded missiles etc.)
                bcc ADI_OK
                lda #$3f
ADI_OK:         plp
                ldy #MAX_DEATHIMPULSE_XSPEED

        ; Accelerate actor in X-direction with either positive or negative acceleration
        ;
        ; Parameters: X actor index, A absolute acceleration, Y absolute speed limit, C direction (0 = right, 1 = left)
        ; Returns:
        ; Modifies: A,Y,temp8

AccActorXNegOrPos:
                bcc AccActorXNoClc

        ; Accelerate actor in negative X-direction
        ;
        ; Parameters: X actor index, A absolute acceleration, Y absolute speed limit
        ; Returns:
        ; Modifies: A,Y,temp8

AccActorXNeg:   sec
AccActorXNegNoSec:
                sty temp8
                sbc actSX,x
                bmi AAX_NegDone
                cmp temp8
                bcc AAX_NegDone2
                tya
AAX_NegDone:    clc
AAX_NegDone2:   eor #$ff
                adc #$01
AAX_Done:       sta actSX,x
AAX_Done2:      rts

        ; Accelerate actor in positive X-direction
        ;
        ; Parameters: X actor index, A acceleration, Y speed limit
        ; Returns: -
        ; Modifies: A,temp8

AccActorX:      clc
AccActorXNoClc: sty temp8
                adc actSX,x
                bmi AAX_Done                    ;If speed negative, can not have reached limit yet
                cmp temp8
                bcc AAX_Done
                tya
                bcs AAX_Done

        ; Brake X-speed of an actor towards zero
        ;
        ; Parameters: X Actor index, A deceleration (always positive)
        ; Returns: -
        ; Modifies: A, temp8

BrakeActorX:    sta temp8
                lda actSX,x
                beq AAX_Done2
                bmi BAct_XNeg
BAct_XPos:      sec
                sbc temp8
                bpl AAX_Done
BAct_XZero:     lda #$00
                beq AAX_Done
BAct_XNeg:      clc
                adc temp8
                bpl BAct_XZero
                bmi AAX_Done

        ; Accelerate actor in Y-direction with either positive or negative acceleration
        ;
        ; Parameters: X actor index, A absolute acceleration, Y absolute speed limit, C direction (0 = down, 1 = up)
        ; Returns:
        ; Modifies: A,Y,temp8

AccActorYNegOrPos:
                bcc AccActorYNoClc

        ; Accelerate actor in negative Y-direction
        ;
        ; Parameters: X actor index, A absolute acceleration, Y absolute speed limit
        ; Returns:
        ; Modifies: A,Y,temp8

AccActorYNeg:   sec
AccActorYNegNoSec:
                sty temp8
                sbc actSY,x
                bmi AAY_NegDone
                cmp temp8
                bcc AAY_NegDone2
                tya
AAY_NegDone:    clc
AAY_NegDone2:   eor #$ff
                adc #$01
AAY_Done:       sta actSY,x
AAY_Done2:      rts

        ; Accelerate actor in positive Y-direction
        ;
        ; Parameters: X actor index, A acceleration, Y speed limit
        ; Returns: -
        ; Modifies: A,temp8

AccActorY:      clc
AccActorYNoClc: sty temp8
                adc actSY,x
                bmi AAY_Done                    ;If speed negative, can not have reached limit yet
                cmp temp8
                bcc AAY_Done
                tya
                bcs AAY_Done

        ; Brake Y-speed of an actor towards zero
        ;
        ; Parameters: X actor index, A deceleration (always positive)
        ; Returns: -
        ; Modifies: A, temp8

BrakeActorY:    sta temp8
                lda actSY,x
                beq AAY_Done2
                bmi BAct_YNeg
BAct_YPos:      sec
                sbc temp8
                bpl AAY_Done
BAct_YZero:     lda #$00
                beq AAY_Done
BAct_YNeg:      clc
                adc temp8
                bpl BAct_YZero
                bmi AAY_Done

        ; Expand collision size of actor into all directions.
        ; Lasts only until next DrawActors call
        ;
        ; Parameters: X actor index, A how much to expand
        ; Returns: -
        ; Modifies: A, temp8

ExpandActorBounds:
                sta temp8
                lda actBoundU,x
                sec
                sbc temp8
                sta actBoundU,x
                lda actBoundD,x
                clc
                adc temp8
                sta actBoundD,x
ExpandActorBoundsHorizontal:
                lda actBoundL,x
                sec
                sbc temp8
                sta actBoundL,x
                lda actBoundR,x
                clc
                adc temp8
                sta actBoundR,x
                rts

        ; Process animation delay
        ;
        ; Parameters: X actor index, A animation speed-1 (in frames)
        ; Returns: C=1 delay exceeded, animationdelay reset
        ; Modifies: A

AnimationDelay: sta AD_Cmp+1
                lda actFd,x
AD_Cmp:         cmp #$00
                bcs AD_Over
                inc actFd,x
                rts

        ; Perform one-shot animation with delay
        ;
        ; Parameters: Y end frame, A animation speed-1 (in frames)
        ; Returns: C=1 end reached
        ; Modifies: A

OneShotAnimation:
                sta OSA_Cmp+1
                sty OSA_FrameCmp+1
                lda actFd,x
OSA_Cmp:        cmp #$00
                bcs OSA_NextFrame
                inc actFd,x
                rts
OSA_NextFrame:  lda actF1,x
OSA_FrameCmp:   cmp #$00
                bcs AD_Over
                inc actF1,x
AD_Over:        lda #$00
                sta actFd,x
                rts

        ; Perform looping animation (loop back to frame 0) with delay
        ;
        ; Parameters: Y end frame, A animation speed-1 (in frames)
        ; Returns: C=1 end reached
        ; Modifies: A

LoopingAnimation:
                jsr OneShotAnimation
                bcc LA_NotOver
                lda #$00
                sta actF1,x
LA_NotOver:     rts

        ; Remove actor and return to leveldata if applicable
        ; Note: do not call for an empty actor!
        ;
        ; Parameters: X actor index
        ; Returns: A=0
        ; Modifies: A,Y

RemoveLevelActor:
                cpx #MAX_PERSISTENTACT
                bcs RemoveActor
                ldy actOrg,x
                bmi RemoveActor
                lda actXH,x
                sta lvlActX,y
                lda actYH,x
                sta lvlActY,y
                lda actT,x
                cmp #ACT_ITEM
                bne RLA_NoItem
                lda actF1,x
                ora #$80
RLA_NoItem:     sta lvlActT,y
                lda actD,x
                asl                             ;Direction to carry
                lda lvlActZ,y
                jsr CarryToMSB
                sta lvlActZ,y                   ;Direction in zone high bit

        ; Remove actor without returning to leveldata
        ;
        ; Parameters: X actor index
        ; Returns: A=0
        ; Modifies: A

RemoveActor:    lda #ACT_NONE
                sta actT,x
                sta actFlags,x                  ;Clear groupbits to prevent add to target/collision list
AD_NoDamageSound:
RA_Done:        rts

        ; Add damage to actor
        ;
        ; Parameters: A damage amount (high bit for player-inflicted damage), X source actor, Y target actor
        ; Returns: -
        ; Modifies: A

AddDamage:      asl                             ;High bit to carry, *2
                sta AD_ImpulseAmount+1
                php                             ;Remember it
                lsr                             ;/2 without high bit, C=0
                adc actDmg,y
                bvc AD_NoOverflow
                lda #$7f
AD_NoOverflow:  asl
                plp
                ror                             ;High bit back (player damage indicator)
AD_NotPlayer:   sta actDmg,y
                cpx #$80                        ;Environment damage - no impulse
                bcs AD_NoImpulse2
                lda actSX,x                     ;Check X speed of damaging actor
                beq AD_NoImpulse
                and #$80                        ;Retain just the dir bit
AD_ImpulseAmount:ora #$00
AD_NoImpulse:   sta actDmgImpulse,y
AD_NoImpulse2:  lda actFlags,y                  ;Verify that actor actually takes damage before playing sound
                and #AF_TAKEDAMAGE
                beq AD_NoDamageSound
                lda #SFX_DAMAGE
                jmp QueueSfx

        ; Add strobed (each second frame) touch damage
        ;
        ; Parameters: A damage amount (high bit for player-inflicted damage), X source actor, Y target actor
        ; Returns: -
        ; Modifies: A,temp8

AddStrobedDamage:
                sta temp8
                lda actT,y
                cmp #ACT_PLAYERWHEEL            ;Wheel is invulnerable to normal enemy touch damage
                beq ASD_NoDamage
ASD_NoWheelCheck:
                lda UA_ItemFlashCounter+1
                lsr
ASD_Amount:     lda temp8
                bcs AddDamage
AA_Fail:
ASD_NoDamage:   rts

        ; Add environment (directionless) damage to player
        ;
        ; Parameters: A damage amount
        ; Returns: -
        ; Modifies: A,X,Y,temp8

AddPlayerEnvironmentDamage:
                sta temp8
                ldy #ACTI_PLAYER
                ldx #$ff
                bmi ASD_NoWheelCheck

        ; Try to add an actor from leveldata to screen
        ;
        ; Parameters: X: levelactor index
        ; Returns: C=1 success, actor index in X C=0 fail (no free actors)
        ; Modifies: A,X,Y,temp vars,actor ZP temp vars

TryAddActor:    lda lvlActT,x
                bpl AA_Actor
AA_Item:        jsr GetFreePersistentActor
                bcc AA_Fail
                lda #ACT_ITEM
                sta actT,y
                lda lvlActT,x
                and #$7f
                sta actF1,y
                bpl AA_Common
AA_Actor:       lda #ACTI_FIRST
                ldy #ACTI_LASTCOMPLEX
                jsr GetFreeActor
                bcc AA_Fail
                lda lvlActT,x
                sta actT,y
                lda lvlActZ,x
                and #$80
                sta actD,y
AA_Common:      lda lvlActX,x
                sta actXH,y
                lda lvlActY,x
                sta actYH,y
                lda #$40
                sta actXL,y
                lda #$00
                sta actYL,y
                sta lvlActT,x                   ;Mark removed from leveldata
                txa
                sta actOrg,y                    ;Store leveldata origin
                tya
                tax
                jsr InitActor                   ;Perform actual actor init now
                lda actT,x
                cmp #ACT_ITEM
                beq AA_SkipWeapon
                lda #$00                        ;Apply zone weaponset, first 0 (default), then zone's
                sta actWpn,x                    ;If no weaponset entry, will use SMG
                jsr AA_ApplyWeaponSet
                ldy zoneNum
                lda lvlZoneBg1,y
                lsr
                lsr
                lsr
                lsr
                beq AA_SkipWeapon
AA_ApplyWeaponSet:
                tay
                lda weaponSetStartTbl,y
                tay
AWS_Loop:       lda weaponSetData,y
                beq AWS_Done
                cmp actT,x
                beq AWS_Found
                iny
                iny
                bne AWS_Loop
AWS_Found:      lda weaponSetData+1,y
                tay
                and #$0f
                cmp #WPN_NONE
                bne AWS_NotNone
                lda #$ff                        ;None=$ff to prevent weapon drop
AWS_NotNone:    sta actWpn,x
                tya
                lsr
                lsr
                lsr
                lsr
                sta actFlash,x
AWS_Done:
AA_SkipWeapon:  sec
                rts

        ; Get actor's logic data address
        ;
        ; Parameters: X actor index
        ; Returns: -
        ; Modifies: A,Y,actLo-actHi,temp6-temp8 (if in script, and needed to load)

GetActorLogicData:
                ldy actT,x
                lda actLogicTblLo-1,y
                sta actLo
                lda actLogicTblHi-1,y
                bpl GALD_NotInScript
GALD_InScript:  clc
                adc #C_FIRSTSCRIPT-$80
                tay
                lda actLo
                stx GALD_RestX+1
                jsr LoadChunkFile
GALD_RestX:     ldx #$00
                lda zpSrcLo
                sta actLo
                lda zpSrcHi
GALD_NotInScript:
                sta actHi
                rts

        ; Get a free actor
        ;
        ; Parameters: A first actor index to check (do not pass 0 here), Y last actor index to check
        ; Returns: C=1 free actor found (returned in Y), C=0 no free actor
        ; Modifies: A,Y

GetFreePersistentActor:
                lda #ACTI_FIRST
                ldy #ACTI_LASTPERSISTENT
GetFreeActor:   sta GFA_Cmp+1
GFA_Loop:       lda actT,y
                beq GFA_Found
                dey
GFA_Cmp:        cpy #$00
                bcs GFA_Loop
                rts
GFA_Found:      lda #$00                        ;Reset most actor variables
                sta actF1,y
                sta actFd,y
                sta actSX,y
                sta actSY,y
                sta actFlash,y
                sta actMB,y
                sta actTime,y
                ;sta actBoundL,y                 ;Reset collision until actually drawn
                sta actBoundR,y
                cpy #MAX_COMPLEXACT
                bcs GFA_NotComplex
                sta actF2,y
                sta actCtrl,y
                sta actMoveCtrl,y
                sta actPrevCtrl,y
                sta actAttackD,y
                sta actFall,y
GFA_NotComplex: cpy #MAX_PERSISTENTACT
                bcs GFA_NotPersistent
                sta actInWater,y
                sta actDmg,y
                sta actDmgImpulse,y
                lda #NONPERSISTENT
                sta actOrg,y
GFA_NotPersistent:
                sec
                rts

        ; Init actor: set initial health, flags & collision size
        ;
        ; Parameters: X actor index
        ; Returns: -
        ; Modifies: A,Y,actLo-actHi,temp6-temp8

InitSpawnedActor:
                tya
                tax
InitActor:      jsr GetActorLogicData
                ldy #AL_ACTORFLAGS
                lda (actLo),y
                sta actFlags,x
                and #AF_INITONLYSIZE
                php
                iny
                lda (actLo),y
                sta actSizeH,x
                iny
                lda (actLo),y
                sta actSizeU,x
                iny
                lda (actLo),y
                sta actSizeD,x
                plp
                bne IA_SkipHealth
                ldy #AL_INITIALHP
                lda (actLo),y
                sta actHp,x
IA_SkipHealth:  rts

        ; Spawn an actor without offset
        ;
        ; Parameters: A actor type, X creating actor, Y destination actor index
        ; Returns: -
        ; Modifies: A,temp1-temp4

SpawnActor:     sta actT,y
                lda #$00
                sta temp1
                sta temp2
                sta temp3
                sta temp4
                beq SWO_SetCoords

        ; Spawn an actor with X & Y offset
        ;
        ; Parameters: A actor type, X creating actor, Y destination actor index, temp1-temp2 X offset,
        ;             temp3-temp4 Y offset
        ; Returns: -
        ; Modifies: A

SpawnWithOffset:sta actT,y
SWO_SetCoords:  lda actXL,x
                clc
                adc temp1
                cmp #$80
                and #$7f
SWO_XNotOver:   sta actXL,y
                sta actPrevXL,y
                lda actXH,x
                adc temp2
                sta actXH,y
                sta actPrevXH,y
                lda actYL,x
                clc
                adc temp3
                cmp #$80
                and #$7f
SWO_YNotOver:   sta actYL,y
                sta actPrevYL,y
                lda actYH,x
                adc temp4
                sta actYH,y
                sta actPrevYH,y
                rts

        ; Check if collided with player. If player dead, always no collision
        ;
        ; Parameters: X actor index
        ; Returns: C=1 if collided
        ; Modifies: A,temp8

CheckPlayerCollision:
                lda actHp+ACTI_PLAYER
                beq CAC_NoCollision2
                ldy #ACTI_PLAYER

        ; Check if two actors have collided.
        ;
        ; Parameters: X,Y actor numbers
        ; Returns: C=1 if collided
        ; Modifies: A,temp8

CheckActorCollision:
                lda actBoundR,y                 ;If collision uninitialized on either actor, do not collide
                beq CAC_NoCollision2
                lda actBoundR,x
                beq CAC_NoCollision2
                cmp actBoundL,y
                bcc CAC_NoCollision
                lda actBoundR,y
                cmp actBoundL,x
                bcc CAC_NoCollision
                lda actBoundD,x
                cmp actBoundU,y
                bcc CAC_NoCollision
                lda actBoundD,y
                cmp actBoundU,x
CAC_NoCollision:rts
CAC_NoCollision2:
                clc
MAG_Fail:       rts

        ; Make an actor global for persistent storage. Do not call twice!
        ;
        ; Parameters: X actor index
        ; Returns:
        ; Modifies: A,Y,temp7-temp8

MakeActorGlobal:
                ldy #MAX_LVLACT-1
MAG_Search:     lda lvlActZ,y                   ;First find an empty spot from levelactors
                ora lvlActT,y
                beq MAG_Found
                dey
                bpl MAG_Search
                bmi MAG_Fail
MAG_Found:      sty temp8
                ldy #MAX_GLOBALACT-1
MAG_SearchGlobal:
                lda globalActT,y
                beq MAG_GlobalFound
                dey
                bpl MAG_SearchGlobal
                bmi MAG_Fail
MAG_GlobalFound:sty temp7                       ;Position & type will be updated once the actor gets removed from the zone
                lda levelNum                    ;so store just zone & levelnumbers
                sta globalActL,y
                lda actD,x
                asl
                lda zoneNum
                jsr CarryToMSB
                sta globalActZ,y
                and #$80
                ora temp7
                ora #GLOBAL
                sta globalActT,y                ;Store "something" to globalActT just to mark the slot occupied. Proper type will be
                ldy temp8                       ;written when exiting zone
                sta lvlActZ,y                   ;Store global actor-index to levelactor
                ldy #$00
MAG_SearchZoneActorEnd:
                lda zoneActIndex,y
                bmi MAG_SearchZoneActorEndFound
                iny
                bne MAG_SearchZoneActorEnd
MAG_SearchZoneActorEndFound:
                lda temp8                       ;Finally store levelactor-index to current zone's actors, so that
                sta zoneActIndex,y              ;the actor can be properly readded to screen as necessary
                sta actOrg,x                    ;Also store leveldata origin to actor
                lda #$ff                        ;Make new endmark
                sta zoneActIndex+1,y
FGA_GlobalFound:rts

        ; Find a global actor in the world for editing
        ; Can handle transporting a live actor away from current zone, but not transporting to the same zone the player is in
        ; Do not call for actors that aren't global!
        ;
        ; Parameters: A actor type
        ; Returns: Y global actor table index
        ; Modifies: A,X,Y,temp8

FindGlobalActor:sta temp8
                ldx #ACTI_LASTPERSISTENT
FGA_FindLive:   lda actT,x
                cmp temp8
                beq FGA_LiveFound
                dex
                bne FGA_FindLive
                beq FGA_LiveNotFound
FGA_LiveFound:  jsr RemoveLevelActor        ;Remove from screen first if necessary
FGA_LiveNotFound:
                ldx #MAX_LVLACT-1
FGA_FindLevelAct:
                lda lvlActT,x
                cmp temp8
                beq FGA_LevelActFound
                dex
                bpl FGA_FindLevelAct
                ldy #MAX_GLOBALACT-1
FGA_FindGlobalAct:
                lda globalActT,y
                cmp temp8
                beq FGA_GlobalFound
                dey
                bpl FGA_FindGlobalAct
                if CHECK_GLOBALACT_NOTFOUND > 0
                jmp LF_Error
                endif
FGA_LevelActFound:
                jmp CZ_ProcessGlobal        ;Remove from level list, move to global. Returns Y as the index

        ; Remember / init boss health
        ; Boss destroy routine must set bossHealth var back to zero for next boss
        ;
        ; Parameters: X actor index, A current HP, actLo-Hi
        ; Returns: bossHealth & actHp set
        ; Modifies: A,Y

SetBossHealth:  ldy #AL_INITIALHP
                cmp (actLo),y
                bne SBH_NotInitial
                lda bossHealth
                bne SBH_NoReset
                lda (actLo),y
SBH_NoReset:    sta actHp,x
SBH_NotInitial: sta bossHealth
                rts
