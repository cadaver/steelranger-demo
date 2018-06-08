REDRAW_SCORE    = $01
REDRAW_PARTS    = $02
REDRAW_WEAPONS  = $04
REDRAW_WEAPONSELECT = $08
REDRAW_ALL      = $0f

PANELROW        = SCROLLROWS+1

ITEM_TEXT_DURATION = 50

TEXTJUMP        = $80

MAPDISPLAYCENTERY = 9
MAPDISPLAYCENTERX = 20

MENU_MOVEDELAY   = 3
MENU_FIRSTMOVEDELAY = 5

ANALYZER_XPOS   = 28
ANALYZER_MAX    = 11

zoneIndices       = screen2
zoneColors        = screen2+$100
mdRowTblLo        = screen2+$200
mdRowTblHi        = screen2+$200+20

        ; Play the operate sound
        ;
        ; Parameters: -
        ; Returns: -
        ; Modifies: A,X,Y

MenuActionSound:lda #SFX_OPERATE
                jmp QueueSfx

        ; Clear menu display and return to normal status bar operation. Also redraw panel immediately
        ;
        ; Parameters: -
        ; Returns: -
        ; Modifies: various

ClearMenu:      jsr PrepareMenuWithSound        ;Easiest way to clear old texts
ClearMenuNoSound:
                jsr SetRedrawPanelFull

        ; Update score panel either fully (each 2nd frame)
        ; or health bars (each frame)
        ;
        ; Parameters: -
        ; Returns: -
        ; Modifies: various

UpdatePanel:    lda dialogueHi                  ;If in dialogue, update bars only
                beq UP_NoDialogue
                jmp UpdatePanelBars
UP_NoDialogue:  lda panelTextDelay
                beq UP_NoText
                dec panelTextDelay
                bne UP_TextDelayOngoing
                lda #REDRAW_SCORE|REDRAW_PARTS  ;Redraw parts & score after text should be cleared
                jsr SetPanelRedraw
                bne UP_NoText
UP_TextDelayOngoing:
                lsr panelUpdateFlags
                lsr panelUpdateFlags
                bpl UP_SkipParts
UP_NoText:      lsr panelUpdateFlags
                bcc UP_SkipScore
UP_ScoreUpdateOK:
                ldy #2                          ;Redraw divider in case it was erased by dialogue
                sty panelScreen+PANELROW*40-40+26
                ldy #5
                sty panelScreen+PANELROW*40+26
                ldy #8
                sty panelScreen+PANELROW*40+40+26
                iny
                sty colors+PANELROW*40+26
                lda score
                ldx score+1
                ldy score+2
                jsr ConvertToBCD24
                ldx #32
                jsr GetPanelRowAddress
                lda temp8
                jsr PrintBCDDigits
                lda temp7
                jsr PrintBCDDigits
                jsr PrintBCDDigitsLSB
                lda #"0"                        ;The final 0 is fixed, ie. score is internally stored
                jsr PrintChar                   ;as divided by 10
UP_SkipScore:   lsr panelUpdateFlags
                bcc UP_SkipParts
                lda parts
                ldy parts+1
                jsr ConvertToBCD16
                ldx #28
                jsr GetPanelRowAddress
                lda #10                         ;Print the parts symbol
                sta panelScreen+PANELROW*40+27
                lda #7
                sta colors+PANELROW*40+27
                jsr Print3BCDDigits
                jsr PrintSpace
UP_SkipParts:   lsr panelUpdateFlags
                bcc UP_SkipWeapons
UP_DrawWeapons: lda weapons
                sta temp5
                lda #$00
                sta temp6
                sta temp7                       ;Last weapon-flag
UP_WeaponLoop:  lda temp6
                asl
                adc temp6
                tax
                lsr temp5
                bcs UP_HasWeapon
                lda #7
                ldy temp7
                beq UP_NoLastWeapon
                lda #29
UP_NoLastWeapon:sta panelScreen+PANELROW*40+41,x
                lda #7                          ;No weapon: clear the ammo bar
                sta panelScreen+PANELROW*40+42,x
                sta panelScreen+PANELROW*40+43,x
                ldy temp6
                lda #$ff                        ;Force redraw of ammo bar when the weapon is displayed next time
                sta displayedAmmo,y
                lda #$00
                sta temp7
                lda #$20
                sta panelScreen+PANELROW*40+2,x
                bne UP_NextWeapon
UP_HasWeapon:   lda #27
                ldy temp7
                beq UP_HasWeaponNoLastWeapon
                lda #28
UP_HasWeaponNoLastWeapon:
                sta panelScreen+PANELROW*40+41,x
                inc temp7
                ldy temp6
                lda ammoLo,y
                ora ammoHi,y
                bne UP_HasAmmo
                tya
                beq UP_HasAmmo                  ;Weapon 0 always has ammo (slowfire mode)
                lda #2                          ;Draw weapon red if no ammo
                skip2
UP_HasAmmo:     lda #1
                sta colors+PANELROW*40+2,x
                sta colors+PANELROW*40+3,x
                tya
                asl
                adc #11
                sta panelScreen+PANELROW*40+2,x
                adc #1
UP_NextWeapon:  sta panelScreen+PANELROW*40+3,x
                inc temp6
                cpx #3*(MAX_WEAPONS-1)
                bcc UP_WeaponLoop
                lda #7
                ldy temp7
                beq UP_NoFinalWeapon
                lda #29
UP_NoFinalWeapon:sta panelScreen+PANELROW*40+44,x ;Draw last ammo bar right border
UP_SkipWeapons: lsr panelUpdateFlags
                bcc UP_SkipWeaponSelect
UP_OldWeaponSelect:
                ldx #$00
                lda #32
                sta panelScreen+PANELROW*40+1,x
                sta panelScreen+PANELROW*40+4,x
                lda wpnIndex
                asl
                adc wpnIndex
                sta UP_OldWeaponSelect+1
                tax
                lda #">"
                sta panelScreen+PANELROW*40+1,x
                lda #"<"
                sta panelScreen+PANELROW*40+4,x
                lda wpnMenuMode
                jsr GetWeaponFlashColor
                sta colors+PANELROW*40+1,x
                sta colors+PANELROW*40+4,x
UP_SkipWeaponSelect:
UP_AFlash:      lda #$ff
                bmi UpdatePanelBars
                lsr
                bne UP_DrawAnalyzer
                sta UP_AMax+1
                beq UP_ClearAnalyzer
UP_DrawAnalyzer:tax
                lda analyzerColorTbl-1,x
                sta UP_AColor+1
UP_ClearAnalyzer:
                ldx #ANALYZER_MAX-1
UP_DrawAnalyzerLoop:
                lda #36
UP_AMax:        cpx #$00
                bcc UP_ANoClear
                lda #1
UP_ANoClear:    sta panelScreen+SCROLLROWS*40+ANALYZER_XPOS,x
UP_AColor:      lda #$0f
UP_ACurrent:    cpx #$00
                bcc UP_AColorOK
                lda #$08
UP_AColorOK:    sta colors+SCROLLROWS*40+ANALYZER_XPOS,x
                dex
                bpl UP_DrawAnalyzerLoop
UP_UpdateAnalyzerCounter:
                dec UP_AFlash+1
UpdatePanelBars:lda actHp+ACTI_PLAYER
                lsr
UPB_DisplayedHealth:
                cmp #$00
                beq UPB_SkipHealthBar
                tay
                lda #38
                sta temp8
                lda UPB_DisplayedHealth+1
                ldx #32
                jsr AnimateHealthBar
                sta UPB_DisplayedHealth+1
UPB_SkipHealthBar:
                lda fuel
UPB_LastFuel:   cmp #$00                        ;Dividing the fuel is slow, so cache value
                beq UPB_LastDividedFuel         ;when unchanged
                sta UPB_LastFuel+1
                ldy #20
                ldx #<temp6
                jsr DivU
                lda temp6
                sta UPB_LastDividedFuel+1
UPB_LastDividedFuel:
                ldy #$00
UPB_DisplayedFuel:
                cpy #$00
                beq UPB_SkipFuelBar
                lda #31
                sta temp8
                lda UPB_DisplayedFuel+1
                ldx #28
                jsr AnimateHealthBar
                sta UPB_DisplayedFuel+1
UPB_SkipFuelBar:lda weapons
                sta temp5
                ldy #$00
UPB_AmmoLoop:   lsr temp5
                bcc UPB_SkipWeapon
                jsr GetAmmoBarLength
                cmp displayedAmmo,y
                beq UPB_SkipWeapon
                sta temp7
                sty temp6
                tya
                asl
                adc temp6
                adc #$02
                tax
                adc #$02
                sta temp8
                lda displayedAmmo,y             ;Negative display value = redraw from current value
                bpl UPB_DisplayedAmmoOK
                lda temp7
UPB_DisplayedAmmoOK:
                jsr AHB_Shortcut
                ldy temp6
                sta displayedAmmo,y
UPB_SkipWeapon: iny
                cpy #MAX_WEAPONS
                bcc UPB_AmmoLoop
                rts

        ; Get length of ammo bar for weapon
        ;
        ; Parameters: Y weapon index (0-7)
        ; Returns: A bar length (0-8)
        ; Modifies: A

GetAmmoBarLength:
                lda ammoLo,y
                cmp #$01
                lda ammoHi,y
                adc #$00
                rts

        ; Status display. Falls through to map display when exited
        ;
        ; Parameters: -
        ; Returns: -
        ; Modifies: various

StatusDisplay:  jsr BeginTextDisplay
                ldy #$0b
                sty Irq1_Bg2+1
                iny
                sty Irq1_Bg3+1
                lda weapons
                sta temp1
                stx temp2                       ;X=0 from BeginTextDisplay
                txa
                jsr SD_BeginColumn
                lda #<txtStatusHeader
                ldx #>txtStatusHeader
                jsr PrintTextAX
SD_Weapons:     lsr temp1
                bcc SD_NoWeapon
                jsr SD_PrintNextWeapon
                lda #$0f
                sta textColor
                lda #30
                jsr PrintChar
                ldy temp2
                jsr GetAmmoBarLength
                ldy #$00
                cmp #MAX_AMMO/2
                bcc SD_NoFullChar
                pha
                lda #99
                jsr PrintChar
                pla
                adc #95-1-4
                bne SD_AmmoBarDone
SD_NoFullChar:  adc #95
                jsr PrintChar
                lda #95
SD_AmmoBarDone: jsr PrintChar
                lda #31
                jsr PrintChar
                lda #$01
                sta textColor
SD_NoWeapon:    inc temp2
                lda temp2
                cmp #MAX_WEAPONS
                bcc SD_Weapons
                lda upgrade
                sta temp1
                lda #$00
                sta temp2
                lda #19
                jsr SD_BeginColumn
SD_Abilities:   lsr temp1
                bcc SD_NoAbility
                jsr SD_PrintNextUpgrade
                jsr PrintSpace
SD_NoAbility:   inc temp2
                lda temp2
                cmp #3
                bcc SD_Abilities
SD_Upgrades:    lsr temp1
                bcc SD_NoUpgrade1
                jsr SD_PrintNextUpgradeRow
SD_NoUpgrade1:  inc temp2
                lda temp2
                cmp #7
                bcc SD_Upgrades
                lda upgrade2
                sta temp1
SD_Upgrades2:   lsr temp1
                bcc SD_NoUpgrade2
                ldx temp2
                lda upgrade2
                and upgradeDisregardTbl-7,x
                bne SD_NoUpgrade2
                jsr SD_PrintNextUpgradeRow
SD_NoUpgrade2:  inc temp2
                lda temp2
                cmp #MAX_UPGRADES
                bcc SD_Upgrades2
SD_Loop:        jsr TextDisplayFrame
                bpl PM_ExitToGame
                bcs MapDisplay
                bcc SD_Loop

        ; Pan map with joystick
        ;
        ; Parameters: -
        ; Returns: -
        ; Modifies: various

PanMap:
PM_Loop:        lda joystick
                and #$0f
                jsr MD_Redraw
PM_SkipRedraw:  jsr TextDisplayFrame
PM_ExitToGame:  bpl MD_ExitToGame
                bcc PM_Loop
PM_ExitToMap:   bcs MD_ExitPan

        ; Map display
        ;
        ; Parameters: -
        ; Returns: -
        ; Modifies: various

MapDisplay:     jsr BeginTextDisplay
                jsr BlankScreen
                dec MD_LastOffset+1             ;Force redraw
                jsr GetTopLeftAddress
                lda #<rangerName                ;Ranger name to the left
                ldx #>rangerName
                jsr PrintTextAX
                ldx #15
                jsr GetTopRowAddress
                ldy levelNum
                lda lvlNameTblLo,y              ;Level name to the center
                ldx lvlNameTblHi,y
                jsr PrintTextAX
                ldx #32
                jsr GetTopRowAddress
                jsr MD_PrintTime                ;Time to the right
MD_ExitPan:     lda #MENU_MAP
                jsr DrawMenu
MD_Loop:        lda #$00
                jsr MD_Redraw                   ;No offset
                lda #$08
                jsr BTD_SetScroll               ;Screen on
                jsr MenuFrame
                bcc MD_Loop
MD_ExitToGame:  jsr ClearMenu
                jmp ExitTextDisplay

MD_PrintTime:   lda time
                jsr MD_PrintTimeSub2
                lda time+1
                jsr MD_PrintTimeSub
                lda time+2
MD_PrintTimeSub:pha
                lda #":"
                jsr PrintChar
                pla
MD_PrintTimeSub2:
                jsr ConvertToBCD8
                jmp PrintBCDDigitsLSB

MD_SameOffset:  jmp MD_RedrawPlayerPos
MD_Redraw:
MD_LastOffset:  cmp #$00
                beq MD_SameOffset
                sta MD_LastOffset+1
                pha
                lsr
                lsr
                tax
                lda mapDisplayXTbl,x
                sta wpnLo
                pla
                and #$03
                tax
                lda mapDisplayYTbl,x
                sta wpnHi
                jsr DividePlayerYPos
                lda temp1
                clc
                adc worldY
                sec
                sbc wpnHi
                sta temp4                       ;Map Y displacement in screens - centering
                lda actXH+ACTI_PLAYER
                ldy #SCREENSIZEX
                jsr DivU                        ;X already set to temp1
                lda temp1
                clc
                adc worldX                      ;Map X displacement in screens - centering
                sec
                sbc wpnLo
                sta temp3
                ldx #$00
                stx zpLenLo                     ;Level number - start from 0
                stx zpSrcLo
                stx wpnBits                     ;Amount of zones found
                lda #>screen1
                sta zpSrcHi
MD_MakeRowTbl:  lda zpSrcLo
                sta mdRowTblLo,x
                clc
                adc #40
                sta zpSrcLo
                lda zpSrcHi
                sta mdRowTblHi,x
                adc #$00
                sta zpSrcHi
                inx
                cpx #20
                bcc MD_MakeRowTbl
                ldx #$00
MD_ZoneLoop:    ldy zpLenLo
                txa
                cmp lvlZoneStart+1,y
                bcc MD_NoNextLevel
                inc zpLenLo
                iny
MD_NoNextLevel: lda lvlMapColorTbl,y            ;Color for level's zones
                sta zoneColors,x
                txa
                jsr DecodeBit
                and zoneBits,y
                if MAP_CHEAT = 0
                beq MD_NextZone
                endif
                jsr MD_CheckZoneVisible
                bcs MD_NextZone
                ldy wpnBits
                txa
                sta zoneIndices,y
                inc wpnBits
MD_NextZone:    inx
                cpx lvlZoneStart+NUMLEVELS
                bcc MD_ZoneLoop
                ldy #$00
                lda #$20
MD_Clear:       sta screen1+1*40,y              ;Clear map rows for drawing
                sta screen1+1*40+$100,y
                sta screen1+1*40+$200,y
                dey
                bne MD_Clear
MD_ZoneRenderLoop:
                sty temp8
                ldx zoneIndices,y
                lda zoneColors,x
                sta MD_ZoneColor+1
                jsr MD_CheckZoneVisible
                ldy temp6
MD_RowLoop:     cpy #19
                bcs MD_NextRow
MD_LastRowCmp:  cpy #$00
                bne MD_NotLast
                ldx #102
                skip2
MD_NotLast:     ldx #100
MD_StoreChars:  stx MD_LeftChar+1
                inx
                stx MD_RightChar+1
                sty temp6
                lda mdRowTblLo+1,y
                sta zpDestLo
                lda mdRowTblHi+1,y
                sta zpDestHi
                jsr GRCA_SetAddress
                ldy temp5
MD_ColumnLoop:  cpy #40
                bcs MD_NextColumn
MD_LeftChar:    lda #$00
                sta (zpDestLo),y
MD_ZoneColor:   lda #$00
                sta (zpBitsLo),y
MD_NextColumn:
MD_RightChar:   lda #$00
                sta MD_LeftChar+1
                iny
MD_ColumnCmp:   cpy #$00
                bne MD_ColumnLoop
MD_RowDone:     ldy temp6
MD_NextRow:     iny
MD_RowCmp:      cpy #$00
                bne MD_RowLoop
                ldy temp8
                iny
                cpy wpnBits
                bcc MD_ZoneRenderLoop
MD_RedrawPlayerPos:
                ldx wpnLo
                ldy wpnHi
                iny
                jsr GetRowColAddress
                lda #94
                sta (zpDestLo),y
MD_FlashColor:  lda #$00
                jsr GetWeaponFlashColor
                ldy #$00
                sta (zpBitsLo),y
                inc MD_FlashColor+1
MD_RenderOutside2:
                sec
MD_RenderOutside:
                rts

MD_CheckZoneVisible:
                lda zoneX,x
                sec
                sbc temp3
                bmi MD_NoXCheck
                cmp #40
                bcs MD_RenderOutside            ;Can't possibly render
MD_NoXCheck:    sta temp5                       ;Left coordinate of zone
                lda zoneSize,x                  ;Add X-size
                and #$0f
                adc temp5                       ;C=0
                bmi MD_RenderOutside2           ;Can't possibly render
                sta MD_ColumnCmp+1
                lda zoneY,x
                sec
                sbc temp4
                bmi MD_NoYCheck
                cmp #19                         ;Can't possibly render
                bcs MD_RenderOutside
MD_NoYCheck:    sta temp6                       ;Top coordinate of zone
                lda zoneSize,x                  ;Add Y-size
                lsr
                lsr
                lsr
                lsr
                adc temp6                       ;C=0
                bmi MD_RenderOutside2           ;Can't possibly render
                sta MD_RowCmp+1
                tay
                dey
                sty MD_LastRowCmp+1
                clc
                rts

        ; Draw the menu in its current mode
        ;
        ; Parameters: A: Menu mode
        ; Returns: -
        ; Modifies: A,X,Y,temp vars

DrawMenu:       sta menuMode
                jsr PrepareMenuWithSound
RedrawMenu:     lda #$00
                sta temp1
                ldy menuMode
                ldx menuItemTbl,y               ;Start column
                jsr GetPanelRowAddress
RM_Loop:        lda temp1
                clc
                adc menuMode
                tax
                ldy menuItemTbl+1,x
                cpy #MENUITEM_SAVE              ;This is always last
                php
                lda menuItemTxtLo,y
                sta zpSrcLo
                lda menuItemTxtHi,y
                sta zpSrcHi
                lda #$20
                ldx temp1
                cpx menuPos
                bne RM_NoArrow
                sty MF_ActionItem+1
                lda #">"
RM_NoArrow:     ldy #$00
                jsr PrintChar
                jsr PrintTextContinue
                inc temp1
                plp
                beq RM_Done
                jmp RM_Loop
RM_Done:        rts

        ; Clear weapons for menu display. Also play the menu entry sound
        ;
        ; Parameters: A: Menu mode
        ; Returns: Y=0
        ; Modifies: A,Y

PrepareMenuWithSound:
                jsr MenuActionSound
PrepareMenu:    lda #$00
                sta panelUpdateFlags
                ldy #25
                lda dialogueHi                  ;Use the full space in dialogue + remove divider
                beq PM_NoDialogue
                ldy #38
                lda #2
                sta panelScreen+PANELROW*40-40+26
                lda #7
                sta panelScreen+PANELROW*40+40+26
PM_NoDialogue:
DM_Loop:        lda #32
                sta panelScreen+PANELROW*40,y
                lda #1
                sta panelScreen+PANELROW*40-40,y
                dey
                bne DM_Loop
                rts

        ; Execute one frame of current menu. In case of action such as changing to map or status,
        ; may not return to caller. Should be called from UpdateLevelObjects, so that control returns
        ; to main loop eventually
        ;
        ; Parameters: -
        ; Returns: C=1 should exit, C=0 not
        ; Modifies: A,X,Y,various

MenuFrame:      jsr TextDisplayFrame
MenuFrameCustom:jsr TDF_CheckControls
                bpl MF_Exit
                bcs MF_ActionItem
                lda joystick
                and #JOY_LEFT|JOY_RIGHT
                beq MF_NoControl
MF_MoveDelay:   ldy #$00
                beq MF_MoveOK
                dec MF_MoveDelay+1
                bpl MF_NoExit
MF_MoveOK:      cmp #JOY_LEFT
                beq MF_MoveLeft
MF_MoveRight:   lda MF_ActionItem+1             ;Save is always on the right and can not move past it
                cmp #MENUITEM_SAVE
                beq MF_NoExit
                inc menuPos
                bne MF_MoveCommon
MF_MoveLeft:    lda menuPos
                beq MF_NoExit
                dec menuPos
MF_MoveCommon:  lda #SFX_SELECT
                jsr QueueSfx
                jsr RedrawMenu
                lda #MENU_MOVEDELAY-1
                ldx prevJoy
                bne MF_RepeatDelay
                lda #MENU_FIRSTMOVEDELAY-1
MF_RepeatDelay:
MF_NoControl:   sta MF_MoveDelay+1
MF_NoExit:      clc
                rts
MF_ActionItem:  lda #$00
                tay
                bne MF_NoResume                 ;Resume
MF_Exit:        sec
                rts
MF_NoResume:    dey
                bne MF_NoRetry
                jsr ClearMenu
                jmp RestartAfterDeath
MF_NoRetry:     pla
                pla                             ;Other actions do not return to caller
                dey
                bne MF_NoSave
                jsr ClearMenu                   ;Save & end, back to title screen
LoadTitleScreen:jsr FadeSong
                jsr BlankScreen                 ;Titlescreen itself doesn't blank screen. Do blanking here
                lda #F_TITLE
                sta fileNumber
                lda #<titleStart
                ldx #>titleStart
                jsr LoadFileHandleError
                jmp titleStart
MF_NoSave:      jsr MenuActionSound
                dey
                bne MF_NoStatus
                jmp StatusDisplay
MF_NoStatus:    jmp PanMap

        ; Clear gamescreen and begin text display
        ;
        ; Parameters: -
        ; Returns: X=0, C=1
        ; Modifies: A,X,Y

BeginTextDisplay:
                lda #$18
BeginTextDisplayCustom:
                pha
                jsr BlankScreen
                sta Irq1_Bg1+1
                tax
                lda #$20
BTD_ClearLoop:  sta screen1,x
                sta screen1+$100,x
                sta screen1+$200,x
                sta screen1+21*40-$100,x
                inx
                bne BTD_ClearLoop
                lda #TEXTSCR_D018
                sta Irq1_D018+1
                pla
BTD_SetScroll:  sta Irq1_ScrollX+1
                lda #$17
                sta Irq1_ScrollY+1
TDF_HasKey:     sec
                rts

        ; Perform frame update & get controls while in text display
        ;
        ; Parameters: -
        ; Returns: N=0 key pressed, C=1 fire clicked
        ; Modifies: A,X,Y,various

TextDisplayFrame:
                jsr StartIrq
                jsr WaitBottom
                jsr UpdatePanel
                jsr WaitBottom
                jsr UpdatePanelBars
                jsr GetControls
TDF_CheckControls:
                jsr GetFireClick
                lda keyType
TDF_NoKey:      rts

SD_PrintNextWeapon:
                jsr SD_GetRowColAndMove
                ldy temp2
                lda itemNameTblLo,y
                ldx itemNameTblHi,y
                bne PrintTextAX

SD_PrintNextUpgradeRow:
                jsr SD_GetRowColAndMove
SD_PrintNextUpgrade:
                ldy temp2
                lda upgradeNameTblLo,y
                ldx upgradeNameTblHi,y
                bne PrintTextAX

        ; Print text to arbitrary position
        ;
        ; Parameters: X column, Y row, zpSrcLo/Hi null-terminated text
        ; Returns:
        ; Modifies: A,X,Y,loader temp vars

PrintTextAX:    sta zpSrcLo
                stx zpSrcHi
                ldy #$00
                beq PrintTextContinue
PrintText:      jsr GetRowColAddress
PrintTextContinue:
PT_JumpDone:    ldy #$00
PT_Loop:        lda (zpSrcLo),y
                php
                inc zpSrcLo
                bne PT_NotOver
                inc zpSrcHi
PT_NotOver:     plp
                beq PT_End
                bmi PT_TextJump
                jsr PrintChar
                jmp PT_Loop
PT_TextJump:    and #$7f
                pha
                lda (zpSrcLo),y
                sta zpSrcLo
                pla
                sta zpSrcHi
                bne PT_JumpDone

        ; Print a short null-terminated game status string to the score/parts display
        ;
        ; Parameters: A,X pointer, Y text duration in logic frames (25Hz)
        ; Returns: -
        ; Modifies: A,X,Y,zpSrcLo/Hi,zpDestLo/Hi

PrintPanelTextItemDur:
                ldy #ITEM_TEXT_DURATION
PrintPanelText: sta zpSrcLo
                stx zpSrcHi
                lda dialogueHi                  ;Skip if in dialogue at the same time
                bne PT_End
                sty panelTextDelay
                ldx #27
                ldy #PANELROW
                jsr PrintText
PPT_Empty:      lda zpDestLo
                cmp #<(PANELROW*40+39)
                bcs PPT_Done
                lda #$20
                jsr PrintChar
                bne PPT_Empty
PT_End:
PPT_Done:       rts

        ; Get address of text row/column
        ;
        ; Parameters: X column, Y row
        ; Returns: zpDestLo-zpDestHi address, zpBitsLo-zpBitsHi color address, A address lowbyte, Y 0
        ; Modifies: A,X,Y

GetTopLeftAddress:
                ldx #0
GetTopRowAddress:
                ldy #0
                beq GetRowColAddress
GetPanelRowAddress:
                ldy #PANELROW
                bne GetRowColAddress

SD_BeginColumn: sta temp3
                lda #0
                sta temp4

SD_GetRowColAndMove:
                ldx temp3
SD_GetRowColAndMoveXSet:
                ldy temp4
                inc temp4
                inc temp4

GetRowColAddress:
                stx GRCA_Col+1
                lda #40
                ldx #zpDestLo
                jsr MulU
GRCA_Col:       lda #$00
                jsr Add8
GRCA_Screen:    ldy #$00
                lda zpDestHi
                ora screenBaseTbl,y
                sta zpDestHi
                ldy #$00
GRCA_SetAddress:
                and #$03
                ora #>colors
                sta zpBitsHi
                lda zpDestLo
                sta zpBitsLo
                rts

        ; Print a 3-digit BCD value to screen
        ;
        ; Parameters: temp6-temp7 value, dest address in zpDestLo, Y=0
        ; Returns: screen position incremented
        ; Modifies: A

Print3BCDDigits:lda temp7
                jsr PrintBCDDigit
PrintBCDDigitsLSB:
                lda temp6

        ; Print a BCD value to screen
        ;
        ; Parameters: A value, dest address in zpDestLo, Y=0
        ; Returns: screen position incremented
        ; Modifies: A

PrintBCDDigits: pha
                jsr ConvertBCDHigh
                jsr PrintChar
                pla
PrintBCDDigit:  jsr ConvertBCDLow

        ; Print char to destination position
        ;
        ; Parameters: A char, zpDest/zpBits screen and color address, Y=0
        ; Returns:
        ; Modifies: A

PrintChar:      pha
                lda textColor
                sta (zpBitsLo),y
                pla
                sta (zpDestLo),y
                inc zpDestLo
                inc zpBitsLo
                bne PC_NotOver
                inc zpDestHi
                inc zpBitsHi
PC_NotOver:     rts

PrintSpace:     lda #$20
                bne PrintChar

        ; Convert a 8-bit value to BCD
        ;
        ; Parameters: A value
        ; Returns: temp6-temp8 BCD value
        ; Modifies: A,Y,temp3-temp8

ConvertToBCD8:  sta temp5
                ldy #$08
CTB_Common:     lda #$00
                sta temp6
                sta temp7
                sta temp8
                sed
CTB_Loop:       asl temp3
                rol temp4
                rol temp5
                lda temp6
                adc temp6
                sta temp6
                lda temp7
                adc temp7
                sta temp7
                lda temp8
                adc temp8
                sta temp8
                dey
                bne CTB_Loop
                cld
                rts

        ; Convert a 16-bit value to BCD
        ;
        ; Parameters: A,Y value
        ; Returns: temp6-temp8 BCD value
        ; Modifies: A,Y,temp3-temp8

ConvertToBCD16: sta temp4
                sty temp5
                ldy #$10
                bne CTB_Common

        ; Convert a 24-bit value to BCD
        ;
        ; Parameters: A,X,Y value
        ; Returns: temp6-temp8 BCD value
        ; Modifies: A,Y,temp3-temp8

ConvertToBCD24: sta temp3
                stx temp4
                sty temp5
                ldy #$18
                bne CTB_Common

ConvertBCDHigh: lsr
                lsr
                lsr
                lsr
ConvertBCDLow:  and #$0f
                ora #$30
                rts

        ; Draw a health bar with animation
        ;
        ; Parameters: A current display value, X position, Y actual value, temp8 end pos
        ; Returns: A new display value
        ; Modifies: A,X,Y,temp7-temp8

AnimateHealthBar:
                sty temp7
AHB_Shortcut:   cmp temp7
                beq AHB_Same
                bcs AHB_Decrease
AHB_Increase:   adc #$01
                skip2
AHB_Decrease:   sbc #$01
AHB_Same:       pha
AHB_FullChars:  cmp #$04
                bcc AHB_FullCharsDone
                sbc #$04
                tay
                lda #99
                sta panelScreen+PANELROW*40+40,x
                tya
                inx
                bne AHB_FullChars
AHB_FullCharsDone:
                adc #95
AHB_EmptyChar:  cpx temp8
                bcs AHB_Done
                sta panelScreen+PANELROW*40+40,x
                inx
                lda #95
                bne AHB_EmptyChar
AHB_Done:       pla
                rts

        ; Trigger the enemy health analyzer
        ;
        ; Parameters: X actor index & actLo/Hi
        ; Returns: -
        ; Modifies: A,Y,temp8

SetRedrawAnalyzer:
                lda actHp,x
                lsr
                adc #$00
                lsr
                adc #$00
                sta temp8
                ldy #AL_INITIALHP
                lda (actLo),y
                lsr
                lsr
                beq SRA_TooSmall
SRA_LimitLoop:  cmp #ANALYZER_MAX+1
                bcc SRA_LimitOK
                lsr
                lsr temp8
                bpl SRA_LimitLoop
SRA_LimitOK:    sta UP_AMax+1
                lda temp8
                sta UP_ACurrent+1
                lda #10
                sta UP_AFlash+1
SRA_TooSmall:   rts

        ; Print multiline text to screen with fadein / out.
        ; Fire speeds up text and exits once done. Should not be called from actor scripts
        ;
        ; Parameters: A start row, srcLo-Hi
        ; Returns: -
        ; Modifies: A,X,Y,several ZP vars

ShowMultiLineText:
                jsr PrintMultiLineText
SMLT_Wait:      jsr TextDisplayFrame
                bcc SMLT_Wait

        ; Fade whole textscreen out
        ;
        ; Parameters: -
        ; Returns: -
        ; Modifies: A,X,Y,several ZP vars

FadeGameTextOut:lda #5
                sta temp1
FGT_Loop:       jsr TextDisplayFrame
                lda temp1
                lsr
                tay
                lda gameTextFadeTbl,y
                ldx #$00
FGT_ScreenLoop: sta colors,x
                sta colors+$100,x
                sta colors+$200,x
                inx
                bne FGT_ScreenLoop
                dec temp1
                bpl FGT_Loop
                rts

        ; Print multiline text and return after printing
        ;
        ; Parameters: A start row, srcLo-Hi
        ; Returns: -
        ; Modifies: A,X,Y,several ZP vars

PrintMultiLineText:
                sta temp4
                sta wpnHi
                dec textColor
PMLT_PrintRowLoop:                      ;Print all rows first
                ldx #$00
                stx PMLT_SpeedUp+1
                jsr SD_GetRowColAndMoveXSet
                jsr PrintTextContinue
                lda (zpSrcLo),y
                bne PMLT_PrintRowLoop
                lda temp4
                sta PMLT_EndCmp+1       ;End row
                inc textColor
PMLT_FadeRowsInLoop:
                lda #$00                ;Reset column counter
                sta wpnLo
PMLT_FadeColumnInLoop:
PMLT_SpeedUp:   lda #$00
                bne PMLT_FadeColumnInFast
                jsr TextDisplayFrame
                bcc PMLT_NoClick
                inc PMLT_SpeedUp+1      ;Remove delay if fire pressed
PMLT_NoClick:
PMLT_FadeColumnInFast:
                ldx wpnLo               ;Reused in ending code
                ldy wpnHi
                jsr GetRowColAddress
                lda #1
                sta (zpBitsLo),y
                iny
                lda #3
                sta (zpBitsLo),y
                iny
                lda #6
                sta (zpBitsLo),y
                inc wpnLo
                lda wpnLo
                lsr
                bcs PMLT_FadeColumnInFast
                cmp #40/2
                bne PMLT_FadeColumnInLoop
                lda wpnHi
                adc #2-1                ;C=1
                sta wpnHi
PMLT_EndCmp:    cmp #$00
                bcc PMLT_FadeRowsInLoop
                rts
