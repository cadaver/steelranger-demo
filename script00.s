                org $0000

                include macros.s
                include memory.s
                include mainsym.s

NUM_UPGRADES    = 11

        ; Note! Code must be unambiguous! Relocated code cannot have skip1/skip2 -macros!

                dc.w scriptEnd-scriptStart  ;Chunk data size
                dc.b 13                     ;Number of objects

scriptStart:
                rorg scriptCodeRelocStart   ;Initial relocation address when loaded

                dc.w RechargeStation        ;$0000
                dc.w AmmoStation            ;$0001
                dc.w UpgradeStation         ;$0002
                dc.w CheckEnemiesAndOpen    ;$0003
                dc.w InstallTick            ;$0004
                dc.w AmmoStationText        ;$0005
                dc.w UpgradeStationText     ;$0006
                dc.w NoPartsText            ;$0007
                dc.w AmmoFullText           ;$0008
                dc.w PowerFullText          ;$0009
                dc.w ExitText               ;$000a
                dc.w UpgradeInstallingText  ;$000b
                dc.w NoArmorText            ;$000c

        ; Recharge station script

RechargeStation:jsr CheckArmor
                lda #$00
                sta temp1                       ;At least one successful fill?
Recharge_Loop:  lda actHp+ACTI_PLAYER
                cmp #HP_PLAYER
                bcs Recharge_Full
                lda #1
                jsr DecreaseParts
                bcc Recharge_NoPartsConditional
                lda TP_HealthPickup+1           ;Fill amount depends on difficulty
                jsr AddHealth
                inc temp1
                jmp Recharge_Loop
Recharge_Full:  lda #<EP_PowerFullText          ;No message if filled power at least once
                bne PrintFailMsgConditional
Recharge_NoPartsConditional:
                lda #<EP_NoPartsText
                bne PrintFailMsgConditional
Recharge_NoParts:
                lda #<EP_NoPartsText
                bne PrintFailMsgCommon
PrintFailMsgConditional:
                ldy temp1
                bne Recharge_EndOK
PrintFailMsgCommon:
                jsr ActionTextCommon
                lda #SFX_DAMAGE
                jmp QueueSfx
Recharge_EndOK: lda #2
                sta flashScreen
                lda #SFX_EXPLOSION
                jmp QueueSfx

ActionTextCommon:
                jsr GetTextAddress
                jmp PrintPanelTextItemDur
                
        ; Ammo refill station script

AmmoStation:    jsr CheckArmor
                lda #<EP_AmmoStationText
                ldx #20-24/2
                ldy #12
                jsr AS_SetRowPosAndPrintTitle
                lda weapons                     ;Check which weapons are available to buy ammo for
                sta temp1
AS_CheckWeapons:lsr temp1
                bcc AS_NextWeapon
                tya
                sta ammoRowTbl,x
                inx
AS_NextWeapon:  iny
                cpy #MAX_WEAPONS
                bcc AS_CheckWeapons
                jsr AS_InitEndMark
AS_PrintRows:   ldx temp1
                ldy ammoRowTbl,x
                bmi AS_PrintExit
                lda itemNameTblLo,y
                ldx itemNameTblHi,y
                jsr AS_PrintRow
                jsr AS_GetRowCol
                ldx #25
                jsr GetRowColAddress
                ldx temp1
                ldy ammoRowTbl,x
                lda ammoCostTbl,y
                jsr AS_PrintCost
                inc temp1
                bne AS_PrintRows
AS_PrintExit:   lda #<EP_ExitText
                jsr GetTextAddress
                jsr AS_PrintRowNoAX
AS_NewPos:      jsr AS_EraseAndPrintArrow
AS_Loop:        jsr TextDisplayFrame
                bpl AS_ExitStation
                jsr GetFireClick
                bcs AS_BuyOrExit
                jsr AS_DoControl
                bcs AS_NewPos
                bcc AS_Loop
AS_BuyOrExit:   ldx rowSelect
                ldy ammoRowTbl,x
                bmi AS_ExitStation
AS_BuyAmmo:     sty temp1
                lda ammoHi,y
                cmp #MAX_AMMO
                bcs AS_AmmoFull
                lda ammoCostTbl,y
                jsr DecreaseParts
                bcs AS_BuySuccessful
                jsr Recharge_NoParts
                jmp AS_Loop
AS_AmmoFull:    lda #<EP_AmmoFullText
                jsr PrintFailMsgCommon
                jmp AS_Loop
AS_BuySuccessful:
                ldy temp1
                lda #MAX_AMMO*$10/3+1       ;Fixed amount of ammo regardless of difficulty
                jsr AddAmmo
                lda #SFX_PICKUP
                jsr QueueSfx
                jmp AS_Loop

AS_ExitStation: lda #SFX_OPERATE
AS_ExitStationCustomSound:
                jsr QueueSfx
AS_ExitStationNoSound:
                lda #FR_STAND
                sta actF1+ACTI_PLAYER
                sta actF2+ACTI_PLAYER
                jmp ExitTextDisplay

AS_SetRowPosAndPrintTitle:
                sty AS_RowPos+1
                dey
                sty AS_ArrowPos+1
                stx AS_TitlePos+1
                pha
                jsr BeginTextDisplay
                pla
                jsr GetTextAddress
AS_TitlePos:    ldx #$00
                ldy #$00
                jsr PrintText
                ldx #$00
                ldy #$00
                rts

AS_InitEndMark: lda #$80
                sta ammoRowTbl,x                ;Endmark
                sta ctrlDelay                   ;Start with infinite delay until UP released
                stx rowMax
                stx rowSelect
                lda #$00
                sta temp1
                sta AS_OldRow+1
                rts

AS_PrintRow:    sta zpSrcLo
                stx zpSrcHi
AS_PrintRowNoAX:jsr AS_GetRowCol
                jmp PrintText

AS_PrintCost:   jsr ConvertToBCD8
                ldy #0
                jsr Print3BCDDigitsNoZeroes
                lda #$07
                sta textColor
                lda #10
                jsr PrintChar
                lda #$01
                sta textColor
                rts

AS_GetRowCol:
AS_RowPos:      ldx #13
                lda temp1
AS_GetRowCol2:  asl
                adc #2
                tay
                rts

AS_EraseAndPrintArrow:
AS_OldRow:      lda #$00
                ldx #$20
                jsr AS_PrintArrowSub
                lda rowSelect
                sta AS_OldRow+1
                ldx #">"
AS_PrintArrowSub:
                stx AS_ArrowChar+1
AS_ArrowPos:    ldx #11
                jsr AS_GetRowCol2
                jsr GetRowColAddress
AS_ArrowChar:   lda #$00
                jmp PrintChar

AS_DoControl:   ldy ctrlDelay
                beq AS_NoDelay
                bmi AS_InfiniteDelay
                dec ctrlDelay
AS_NoDelay:
AS_InfiniteDelay:
                lda joystick
                and #JOY_UP|JOY_DOWN
                bne AS_HasControl
                sta ctrlDelay
AS_NoMove:      clc
                rts
AS_HasControl:  ldy ctrlDelay
                bne AS_NoMove
                lsr
                bcc AS_NotUp
                dec rowSelect
                bpl AS_UpNotOver
                lda rowMax
                sta rowSelect
AS_UpNotOver:
AS_MoveCommon:  lda #MENU_MOVEDELAY
                ldx prevJoy
                bne AS_RepeatDelay
                lda #MENU_FIRSTMOVEDELAY
AS_RepeatDelay: sta ctrlDelay
                lda #SFX_SELECT
                jsr QueueSfx
                sec
                rts
AS_NotUp:       lda rowSelect
                cmp rowMax
                bcs AS_DownOver
                inc rowSelect
                jmp AS_MoveCommon
AS_DownOver:    lda #0
                sta rowSelect
                beq AS_MoveCommon

        ; Upgrade station script

UpgradeStation: jsr CheckArmor
                lda #<EP_UpgradeStationText
                ldx #20-23/2
                ldy #9
                jsr AS_SetRowPosAndPrintTitle
US_CheckUpgrades:
                lda upgrade
                and upgradeBitTblLo,y
                bne US_NextUpgrade              ;Already has
                lda upgrade2
                and upgradeBitTblHi,y
                bne US_NextUpgrade
                lda upgradePrereqTblLo,y
                beq US_NoPrereq1
                and upgrade
                beq US_NextUpgrade              ;No prerequisite
US_NoPrereq1:   lda upgradePrereqTblHi,y
                beq US_NoPrereq2
                and upgrade2
                beq US_NextUpgrade
US_NoPrereq2:   tya
                sta ammoRowTbl,x
                inx
US_NextUpgrade: iny
                cpy #NUM_UPGRADES
                bcc US_CheckUpgrades
                jsr AS_InitEndMark
US_PrintRows:   ldx temp1
                ldy ammoRowTbl,x
                bmi US_PrintExit
                lda upgradeNameIndexTbl,y
                tay
                lda upgradeNameTblLo,y
                ldx upgradeNameTblHi,y
                jsr AS_PrintRow
                jsr AS_GetRowCol
                ldx #29
                jsr GetRowColAddress
                ldx temp1
                ldy ammoRowTbl,x
                lda upgradeCostTbl,y
                jsr AS_PrintCost
                inc temp1
                bne US_PrintRows
US_PrintExit:   lda #<EP_ExitText
                jsr GetTextAddress
                jsr AS_PrintRow
US_NewPos:      jsr AS_EraseAndPrintArrow
US_Loop:        jsr TextDisplayFrame
                bpl US_ExitStation
                jsr GetFireClick
                bcs US_BuyOrExit
                jsr AS_DoControl
                bcs US_NewPos
                bcc US_Loop
US_BuyOrExit:   ldx rowSelect
                ldy ammoRowTbl,x
                bpl US_BuyUpgrade
US_ExitStation: jmp AS_ExitStation
US_BuyUpgrade:  sty temp1
                lda upgradeCostTbl,y
                jsr DecreaseParts
                bcs US_BuySuccessful
                jsr Recharge_NoParts
                jmp US_Loop
US_BuySuccessful:
                ldy temp1
                lda upgrade
                ora upgradeBitTblLo,y
                sta upgrade
                lda upgrade2
                ora upgradeBitTblHi,y
                sta upgrade2
                lda scriptEP                    ;If a tick script was going on (hangar bay alarm) restore it after install
                sta IT_RestoreScriptEP+1
                lda scriptF
                sta IT_RestoreScriptF+1
                lda #<EP_InstallTick
                sta scriptEP
                lda #>EP_InstallTick
                sta scriptF
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
                jsr NoInterpolation
                lda #<EP_UpgradeInstallingText
                jsr GetTextAddress
                jsr PrintPanelTextItemDur
                jmp ExitTextDisplay

        ; Door that opens only after enemies are destroyed from the whole room

CheckEnemiesAndOpen:
                stx temp1
                ldx #ACTI_LASTCOMPLEX
CEAO_Loop:      lda actT,x
                beq CEAO_Next
                lda actFlags,x
                and #AF_TAKEDAMAGE
                bne CEAO_HasEnemy
CEAO_Next:      dex
                bne CEAO_Loop
                ldy #$00
CEAO_CheckLevelData:
                ldx zoneActIndex,y
                bmi CEAO_NoEnemies
                iny
                lda lvlActT,x
                beq CEAO_CheckLevelData
                bmi CEAO_CheckLevelData
                bne CEAO_HasEnemy
CEAO_NoEnemies: ldy temp1
                iny                             ;Door object index is the next
                jmp ActivateObject
CEAO_HasEnemy:  ldy temp1                       ;No entry now; deactivate to retry
                jmp DeactivateObject

        ; Install tick script

InstallTick:    lda installTime
                cmp #50
                bcs InstallFinish
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
                rts

InstallFinish:  lda dialogueHi
                bne IT_RestoreScriptEP
                sta playerCtrl                  ;If no simultaneous dialogue, end control override
IT_RestoreScriptEP:
                lda #$00
                sta scriptEP
IT_RestoreScriptF:
                lda #NO_SCRIPT
                sta scriptF
                lda #2*8
                sta shakeScreen
                lda #SFX_EXPLOSION
                jsr QueueSfx
                jmp ApplyRangerColorAndUpgrades

        ; Armor check subroutine. Will not return if fails

CheckArmor:     lda actT+ACTI_PLAYER
                cmp #ACT_PLAYER
                bne CA_Fail
                rts
CA_Fail:        pla
                pla
                lda #<EP_NoArmorText
                jmp PrintFailMsgCommon

        ; Return script object address in A/X

GetTextAddress: ldy #(>EP_RechargeStation) + C_FIRSTSCRIPT
GetObjectAddress:
                jsr LoadChunkFile
                lda zpSrcLo
                ldx zpSrcHi
                rts

        ; Print a 3-digit BCD value to screen, without leading zeroes

Print3BCDDigitsNoZeroes:
                lda temp7
                jsr ConvertBCDLow
                cmp #$30
                bne Print3BCDDigitsOK
                lda #$20
                jsr PrintChar
                lda temp6
                jsr ConvertBCDHigh
                cmp #$30
                bne PrintBCDDigitsLSBOK
                lda #$20
                jsr PrintChar
                lda temp6
                jmp PrintBCDDigit
Print3BCDDigitsOK:
                jmp Print3BCDDigits
PrintBCDDigitsLSBOK:
                jmp PrintBCDDigitsLSB

                brk                         ;Stop code relocation, only data will follow

installTime:    dc.b 0
rowMax:         dc.b 0
rowSelect:      dc.b 0
ctrlDelay:      dc.b 0

upgradeRowTbl:
ammoRowTbl:     ds.b MAX_WEAPONS+1,0
ammoCostTbl:    dc.b 3,5,5,5,7,7,7,10
suitFlashTbl:   dc.b 11,14,15,14

upgradePrereqTblLo:
                dc.b 0
                dc.b UPG_WHEEL
                dc.b UPG_WHEEL
                dc.b UPG_JETPACK
                dc.b 0
                dc.b 0
                dc.b 0
                dc.b 0
                dc.b 0
                dc.b 0
                dc.b 0

upgradePrereqTblHi:
                dc.b 0
                dc.b 0
                dc.b 0
                dc.b 0
                dc.b 0
                dc.b 0
                dc.b 0
                dc.b 0
                dc.b UPG2_HEALTH1
                dc.b UPG2_REGEN1
                dc.b UPG2_WPNDAMAGE1

upgradeBitTblLo:
                dc.b UPG_TECHANALYZER
                dc.b UPG_WHEELFUEL
                dc.b 0
                dc.b UPG_JETPACKFUEL
                dc.b 0
                dc.b 0
                dc.b 0
                dc.b UPG_WPNCONSUMPTION
                dc.b 0
                dc.b 0
                dc.b 0

upgradeBitTblHi:
                dc.b 0
                dc.b 0
                dc.b UPG2_WHEELDAMAGE
                dc.b 0
                dc.b UPG2_HEALTH1
                dc.b UPG2_REGEN1
                dc.b UPG2_WPNDAMAGE1
                dc.b 0
                dc.b UPG2_HEALTH2
                dc.b UPG2_REGEN2
                dc.b UPG2_WPNDAMAGE2

upgradeNameIndexTbl:
                dc.b 6
                dc.b 3
                dc.b 11
                dc.b 4
                dc.b 7
                dc.b 9
                dc.b 12
                dc.b 5
                dc.b 8
                dc.b 10
                dc.b 13

upgradeCostTbl: dc.b 50
                dc.b 75
                dc.b 75
                dc.b 100
                dc.b 100
                dc.b 100
                dc.b 100
                dc.b 150
                dc.b 200
                dc.b 200
                dc.b 200

AmmoStationText:dc.b "AMMO CONSTRUCTOR STATION",0
UpgradeStationText:
                dc.b "SYSTEMS UPGRADE STATION",0
NoPartsText:    dc.b "NO PARTS",0
AmmoFullText:   dc.b "AMMO FULL",0
PowerFullText:  dc.b "POWER FULL",0
ExitText:       dc.b "EXIT",0
UpgradeInstallingText: dc.b "INSTALLING",0
NoArmorText:    dc.b "NO ARMOR",0

                rend

scriptEnd: