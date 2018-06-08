                org $0000

                include macros.s
                include memory.s
                include mainsym.s

        ; Note! Code must be unambiguous! Relocated code cannot have skip1/skip2 -macros!

                dc.w scriptEnd-scriptStart  ;Chunk data size
                dc.b 17                     ;Number of objects

scriptStart:
                rorg scriptCodeRelocStart   ;Initial relocation address when loaded

                dc.w SecurityTowerTrigger       ;$1400
                dc.w PostDroidBossTick          ;$1401
                dc.w AlphaPassTerminal          ;$1402
                dc.w JROfficerTower             ;$1403
                dc.w GruntTower                 ;$1404
                dc.w NPCLeaveTick               ;$1405
                dc.w JROfficerTopFloor          ;$1406
                dc.w GruntAmmoStation           ;$1407
                dc.w NPCIdle                    ;$1408
                dc.w JROfficerTerminalIdle      ;$1409
                dc.w SecurityTowerTriggerText   ;$140a
                dc.w AlphaPassText              ;$140b
                dc.w PostDroidBossText          ;$140c
                dc.w JROfficerTowerText         ;$140d
                dc.w GruntTowerText             ;$140e
                dc.w JROfficerTopFloorText      ;$140f
                dc.w GruntAmmoStationText       ;$1410

        ; Security tower trigger

SecurityTowerTrigger:
                lda #PLOT_SECURITYTOWER
                jsr GetPlotBit
                bne STT_Skip                    ;Can be entered via 2 routes, only display once
                lda #PLOT_SECURITYTOWER
                jsr SetPlotBit
                ldy #25
                lda numTargets
                cmp #2
                bcs STT_UseDelay
                ldy #0                          ;Immediate when using the enemy-free route, otherwise 1 sec delay after its destruction
STT_UseDelay:   lda #<EP_SecurityTowerTriggerText
RadioMsgWithDelay:
                sta radioMsgEP
                lda #>EP_SecurityTowerTriggerText
                sta radioMsgF
                sty radioMsgDelay
STT_Skip:       rts

        ; Terminal in droid boss room

AlphaPassTerminal:
                jsr BeginTextDisplay
                lda #<EP_AlphaPassText
                jsr GetTextAddress
                lda #7
                jsr ShowMultiLineText
                lda #PLOT_DROIDBOSS
                jsr SetPlotBit
                jmp ExitTextDisplay

        ; After fighting droid boss
        
PostDroidBossTick:
                lda #NO_SCRIPT                  ;Tick script only used once
                sta scriptF
                lda #ACT_JROFFICER
                jsr FindGlobalActor
                lda #$01
                jsr PDBT_MoveNPCCommon
                lda #ACT_GRUNT
                jsr FindGlobalActor
                lda #$00
                jsr PDBT_MoveNPCCommon
                lda #<EP_JROfficerTower
                ldy #<EP_GruntTower
                jsr SetNPCScripts
                lda #<EP_PostDroidBossText      ;Delayed radio message
                ldy #75
                bne RadioMsgWithDelay

PDBT_MoveNPCCommon:
                sta globalActX,y
                lda #$11
                sta globalActY,y
                lda #3
                sta globalActL,y
                lda #1
                sta globalActZ,y
PDBT_Wait:      rts

        ; JR officer in tower

JROfficerTower: lda #NO_SCRIPT                      ;If radio message was still pending, clear now
                sta radioMsgF
                lda #<EP_NPCLeaveTick               ;Set tick script for NPCs leaving
                sta scriptEP                        ;(dialogue is possible to skip if player just runs past)
                lda #>EP_NPCLeaveTick
                sta scriptF
                lda actXH,x
                cmp #7
                bcs JROT_Stop
NPCMoveRightCommon:
                lda actYH,x                         ;Wait for player to descend enough before moving
                cmp #16
                bcc NPCMoveWait
                lda #JOY_RIGHT
                sta actMoveCtrl,x
NPCMoveWait:    rts
JROT_Stop:      ldy #ACTI_LASTCOMPLEX
JROT_CheckTurret:
                lda actHp,y
                beq JROT_CheckTurretNext
                lda actT,y
                cmp #ACT_CEILINGTURRET
                beq JROT_FireAtTurret
JROT_CheckTurretNext:
                dey
                bne JROT_CheckTurret
                jsr StopAndFacePlayer
                lda actF2,x                         ;To not display speech bubble wrong, wait until gun at rest
                cmp #FR_ATTACK
                bcs JROT_Wait
                lda #<EP_JROfficerTowerText
                jsr SpeakText
                bcc JROT_Wait
                lda #<EP_NPCIdle
                sta npcScriptEP+NPC_JROFFICER
JROT_Wait:      rts
JROT_FireAtTurret:
                lda #$00                            ;Disregard global attack delay here
                sta AH_GlobalAttackDelay+1
                sta actMoveCtrl,x
                lda #JOY_FIRE+JOY_UP+JOY_RIGHT      ;Fire at the ceiling turret until it's history
                sta actCtrl,x
                lda #WPN_SMG
                sta actWpn,x
                rts

        ; Grunt in tower

GruntTower:     lda actXH,x
                cmp #4
                bcc NPCMoveRightCommon
                jsr StopAndFacePlayer
                lda #<EP_GruntTowerText
GruntSpeakAndGoIdle:
                jsr SpeakText
                bcc GIT_Wait
                lda #<EP_NPCIdle
                sta npcScriptEP+NPC_GRUNT
GIT_Wait:       rts

        ; JR officer at top of tower

JROfficerTopFloor:
                jsr JROfficerTerminalIdle
                lda #<EP_JROfficerTopFloorText
                jsr SpeakText
                bcc JROTF_Wait
                lda #<EP_JROfficerTerminalIdle
                sta npcScriptEP+NPC_JROFFICER
JROTF_Wait:     rts

JROfficerTerminalIdle:
                lda #FR_ENTER
                sta actF1,x
                sta actF2,x
                rts

        ; Grunt at ammo station

GruntAmmoStation:
                jsr FacePlayer
                lda #<EP_GruntAmmoStationText
                bpl GruntSpeakAndGoIdle

        ; NPCs leave as soon as player changes level

NPCLeaveTick:   lda levelNum
                cmp #LEVEL_SECURITY
                beq NLT_Wait
                lda #NO_SCRIPT
                sta scriptF
                lda #ACT_JROFFICER
                jsr FindGlobalActor
                lda #9
                sta globalActZ,y
                lda #6
                sta globalActX,y
                lda #8
                sta globalActY,y
                lda #ACT_GRUNT
                jsr FindGlobalActor
                lda #4
                sta globalActZ,y
                lda #9
                sta globalActX,y
                sta globalActY,y
                lda #<EP_JROfficerTopFloor
                ldy #<EP_GruntAmmoStation
                jsr SetNPCScripts
                lda #7
                sta globalActY                  ;Move the security tower lift to top position
                ldx #$05
NLT_DisableEnemies:
                lda level3ActIDData,x           ;Remove enemies in NPC target rooms
                jsr DecodeBit
                pha
                tya
                clc
                adc lvlActBitStart+3
                tay
                pla
                eor #$ff
                and lvlActBits,y
                sta lvlActBits,y
                dex
                bpl NLT_DisableEnemies
NLT_Wait:       rts

        ; Subroutines

GetTextAddress: ldy #(>EP_SecurityTowerTriggerText) + C_FIRSTSCRIPT
GetObjectAddress:
                jmp LoadChunkFile

SpeakText:      jsr GetTextAddress
                jmp NPCDialogue

NPCIdle:
StopAndFacePlayer:
                lda #$00
                sta actCtrl,x
                sta actMoveCtrl,x
FacePlayer:     ldy #ACTI_PLAYER
                jsr GetActorDistance
                lda temp5
                sta actD,x
                rts

SetNPCScripts:  sta npcScriptEP+NPC_JROFFICER
                sty npcScriptEP+NPC_GRUNT
                lda #>EP_JROfficerTower
                sta npcScriptF+NPC_JROFFICER
                sta npcScriptF+NPC_GRUNT
                rts

                brk                         ;Only data will follow

level3ActIDData:dc.b $07,$14,$15,$16,$17,$18

SecurityTowerTriggerText:
                     ;01234567890123456789012345678901234567
                dc.b "KARA: GOOD, YOU'RE IN. TECH HERE SEEMS",0
                dc.b "BASED ON OURS. THEY COULD HAVE UPGRADE",0
                dc.b "STATIONS COMPATIBLE WITH THE SUITS. OF",0
                dc.b "COURSE.. NOT EXACTLY SAFE TO USE.",0,0

AlphaPassText:  dc.b "ACCESSING...",0
                dc.b "UNAUTHORIZED LIFEFORM DETECTED",0
                dc.b "GUARDIAN WILL NOW ACTIVATE",0,0

PostDroidBossText:
                     ;01234567890123456789012345678901234567
                dc.b "LEO: UNAUTHORIZED LIFEFORM? ALMOST A",0
                dc.b "SENSE OF HUMOR. WE'RE ENTERING THE",0
                dc.b "TOWER NOW.",0,0

JROfficerTowerText:
                     ;01234567890123456789012345678901234567
                dc.b "KARA: I'LL SEE IF I GET ACCESS FROM",0
                dc.b "THE TOP FLOOR. SUGGEST YOU GO ON PAST",0
                dc.b "THE ALPHA LOCK TO THE CITY.",0,0

GruntTowerText:      ;01234567890123456789012345678901234567
                dc.b "LEO: ALPHA TO OMEGA.. OMEGA COULD BE",0
                dc.b "THE LAST, MACHINE-GOD SECURITY LEVEL?",0,0

JROfficerTopFloorText:
                     ;01234567890123456789012345678901234567
                dc.b "KARA: I'M IN THEIR SYSTEM. HEAVY DATA",0
                dc.b "TRAFFIC COMING FROM THE FAR SIDE OF",0
                dc.b "THE CITY.",0,0

GruntAmmoStationText:
                     ;01234567890123456789012345678901234567
                dc.b "LEO: THEY PAY FOR AMMO WITH PARTS?",0
                dc.b "LIKE, SELLING YOURSELF PIECE BY PIECE",0
                dc.b "TO KEEP FIGHTING?",0,0

                rend

scriptEnd: