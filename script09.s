                org $0000

                include macros.s
                include memory.s
                include mainsym.s

        ; Note! Code must be unambiguous! Relocated code cannot have skip1/skip2 -macros!

                dc.w scriptEnd-scriptStart  ;Chunk data size
                dc.b 14                     ;Number of objects

scriptStart:
                rorg scriptCodeRelocStart   ;Initial relocation address when loaded

                dc.w InstallWheel           ;$0900
                dc.w InstallHighJump        ;$0901
                dc.w InstallJetpack         ;$0902
                dc.w InstallHeatShield      ;$0903
                dc.w InstallWheelTick       ;$0904
                dc.w InstallHighJumpTick    ;$0905
                dc.w InstallJetpackTick     ;$0906
                dc.w InstallHeatShieldTick  ;$0907
                dc.w WheelText              ;$0908
                dc.w HighJumpText           ;$0909
                dc.w JetpackText            ;$090a
                dc.w HeatShieldText         ;$090b
                dc.w InstallingText         ;$090c
                dc.w NoArmorText2           ;$090d

        ; Wheel install script

InstallWheel:   lda #NO_SCRIPT              ;If player managed to run here without the tower radio message, cancel it now
                sta radioMsgF
                lda #<EP_WheelText
                ldx #6
                ldy #<EP_InstallWheelTick
InstallInitAndExit:
                jsr InstallInitCommon
                jmp ExitTextDisplay

InstallInitCommon:
                sty scriptEP
                stx temp1
                jsr GetTextAddress
                lda #>EP_InstallWheelTick
                sta scriptF
                jsr BeginTextDisplay
                lda temp1
                jsr ShowMultiLineText
                lda #0
                sta installTime
                ldx #ACTI_PLAYER
                stx actSX+ACTI_PLAYER
                lda #$40                        ;Stand on the station platform
                sta actXL+ACTI_PLAYER
                sta actYL+ACTI_PLAYER
                ldy atObj
                lda lvlObjY,y
                clc
                adc #$02
                sta actYH+ACTI_PLAYER
                lda #JOY_OVERRIDE+JOY_UP
                sta playerCtrl
                jmp NoInterpolation

InstallWheelTick:
                jsr InstallTickCommon
                bcc InstallWheelWait
                lda upgrade
                ora #UPG_WHEEL
                sta upgrade
                lda #MAX_FUEL
                jsr AddFuel
InstallFinishCommon:
                lda #$00                        ;End control override
                sta playerCtrl
                lda #NO_SCRIPT
                sta scriptF                     ;Stop tick script
                lda #2*8
                sta shakeScreen
                lda #SFX_EXPLOSION
                jsr QueueSfx
                jmp ApplyRangerColorAndUpgrades

InstallTickCommon:
                lda installTime
                bne InstallTickNotFirst
                lda #<EP_InstallingText
                jsr GetTextAddress
                jsr PrintPanelTextItemDur
                lda installTime
InstallTickNotFirst:
                cmp #50
                php
                pha
                inc installTime
                lsr
                and #$03
                tay
                lda suitFlashTbl,y
                sta actFlash+ACTI_PLAYER
                pla
                and #$03
                bne InstallTickNoSound
                lda #SFX_ARCGUN
                jsr QueueSfx
                lda #2
                sta flashScreen
InstallTickNoSound:
                plp
InstallWheelWait:
InstallHighJumpWait:
                rts

ActionTextCommon:
                jsr GetTextAddress
                jmp PrintPanelTextItemDur

        ; Highjump install script

InstallHighJump:lda #<EP_HighJumpText
                ldx #7
                ldy #<EP_InstallHighJumpTick
                jsr InstallInitCommon
                ;lda #<EP_GruntHideoutInit       ;Continue execution in script13 to ensure preload of script
                ;ldx #>EP_GruntHideoutInit       ;(otherwise sprites could be blanked)
                ;jmp ExecScript
                rts

InstallHighJumpTick:
                jsr InstallTickCommon
                bcc InstallHighJumpWait
                lda upgrade
                ora #UPG_HIGHJUMP
                sta upgrade
                jmp InstallFinishCommon

        ; Jetpack install script

InstallJetpack: lda actT+ACTI_PLAYER            ;Check for player wearing armor
                cmp #ACT_PLAYER
                bne InstallJetpackFail
                ldy #$11                        ;Safe to allow player out of the vault now
                jsr ActivateObject
                ldy #$12
                jsr ActivateObject
                ldy #$1a
                jsr ActivateObject
                ;ldy lvlObjBitStart+LEVEL_MINE   ;Activate the "wrong way" door in mines also
                ;lda lvlObjBits,y
                ;ora #$80                        ;Object ID 7
                ;sta lvlObjBits,y
                ;lda #<EP_VaultOpenedRadioText+$80
                ;sta radioMsgEP
                ;lda #>EP_VaultOpenedRadioText
                ;sta radioMsgF
                lda #75
                sta radioMsgDelay
                lda #<EP_JetpackText
                ldx #7
                ldy #<EP_InstallJetpackTick
                jmp InstallInitAndExit

InstallJetpackFail:
                ldy atObj                       ;Allow to retry
                jsr DeactivateObject
                lda #<EP_NoArmorText2
                jsr GetTextAddress
                jsr PrintPanelTextItemDur
                lda #SFX_DAMAGE
                jmp QueueSfx
InstallJetpackTick:
                jsr InstallTickCommon
                bcc InstallJetpackWait
                lda upgrade
                ora #UPG_JETPACK
                sta upgrade
                jmp InstallFinishCommon
InstallHeatShieldWait:
InstallJetpackWait:
                rts

        ; Heatshield install script

InstallHeatShield:
                lda #<EP_HeatShieldText
                ldx #7
                ldy #<EP_InstallHeatShieldTick
                jmp InstallInitAndExit

InstallHeatShieldTick:
                jsr InstallTickCommon
                bcc InstallHeatShieldWait
                lda upgrade2
                ora #UPG2_HEATSHIELD
                sta upgrade2
                jmp InstallFinishCommon

        ; Return script object address in A/X

GetTextAddress: ldy #(>EP_WheelText) + C_FIRSTSCRIPT
                jsr LoadChunkFile
                lda zpSrcLo
                ldx zpSrcHi
                rts

                brk                         ;Only data will follow

installTime:    dc.b 0

suitFlashTbl:   dc.b 11,14,15,14

                     ;0123456789012345678901234567890123456789
WheelText:      dc.b "WHEEL MODE",0
                dc.b "WHEN CROUCHED, PRESS DIAGONALLY DOWN TO",0
                dc.b "ACTIVATE. USES REPLENISHING FUEL. PRESS",0
                dc.b "FIRE TO LAY MINES, WHICH USES PARTS.",0,0

                     ;0123456789012345678901234567890123456789
HighJumpText:   dc.b "HIGH JUMP",0
                dc.b "FOR MAXIMUM JUMP HEIGHT, PRESS AND HOLD",0
                dc.b "UP UNTIL STARTING TO FALL.",0,0

                     ;0123456789012345678901234567890123456789
JetpackText:    dc.b "JETPACK",0
                dc.b "HOLD UP WHILE FALLING TO ACTIVATE. USES",0
                dc.b "THE SAME FUEL RESERVE AS WHEEL MODE.",0,0

                     ;0123456789012345678901234567890123456789
HeatShieldText: dc.b "HEAT SHIELD",0
                dc.b "ACTIVATES AUTOMATICALLY IN HAZARDOUS",0
                dc.b "TEMPERATURE CONDITIONS.",0,0

InstallingText: dc.b "INSTALLING",0
NoArmorText2:   dc.b "NO ARMOR",0

                rend

scriptEnd: