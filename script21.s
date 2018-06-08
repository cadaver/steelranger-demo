                org $0000

                include macros.s
                include memory.s
                include mainsym.s

        ; Note! Code must be unambiguous! Relocated code cannot have skip1/skip2 -macros!
        ; There also must be no code before the first entrypoint, or it won't get relocated!

                dc.w scriptEnd-scriptStart  ;Chunk data size
                dc.b 4                      ;Number of objects

scriptStart:
                rorg scriptCodeRelocStart   ;Initial relocation address when loaded

                dc.w BetaLockTrigger        ;$1500
                dc.w UpgradeStationTrigger  ;$1501
                dc.w BetaLockTriggerText    ;$1502
                dc.w UpgradeStationTriggerText ;$1503

        ; Trigger at Beta pass lock

BetaLockTrigger:lda security                ;Skip if already have the pass
                and #$02
                bne BLT_Skip
                lda #<EP_BetaLockTriggerText
BLT_RadioMsgCommon:
                sta radioMsgEP
                lda #>EP_BetaLockTriggerText
                sta radioMsgF
                lda #20
                sta radioMsgDelay
UST_Skip:
BLT_Skip:       rts

        ; Trigger near first upgrade stations
        
UpgradeStationTrigger:
                lda #PLOT_TECHANALYZER      ;Skip if has already given the analyzer without
                jsr GetPlotBit              ;visiting the early upgrade stations
                bne UST_Skip
                lda #PLOT_UPGRADESTATIONMSG ;Two triggers, skip if already done
                jsr GetPlotBit
                bne UST_Skip
                lda #PLOT_UPGRADESTATIONMSG
                jsr SetPlotBit
                lda #<EP_UpgradeStationTriggerText
                bpl BLT_RadioMsgCommon

        ; Subroutines

GetTextAddress:
                ldy #>EP_BetaLockTriggerText + C_FIRSTSCRIPT
                jmp LoadChunkFile               ;Get text object address

                brk

BetaLockTriggerText:
                     ;01234567890123456789012345678901234567
                dc.b "KARA: ANOTHER LOCK? YOU COULD TRY",0
                dc.b "HEADING BELOW. DATA TRAFFIC SUGGESTS",0
                dc.b "A COMPUTER CENTER THERE.",0,0

UpgradeStationTriggerText:
                     ;01234567890123456789012345678901234567
                dc.b "DIANE: ABOUT THE UPGRADE STATIONS -",0
                dc.b "MAYBE THERE'S SOMETHING THAT'D HELP TO",0
                dc.b "FIX THE MED EQUIPMENT? I'M STILL HERE",0
                dc.b "AT THE SHIP.",0,0

                rend

scriptEnd: