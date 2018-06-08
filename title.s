                processor 6502

                include memory.s
                include mainsym.s

                org titleStart

PAGE_MAIN       = 0
PAGE_OPTIONS    = 1
PAGE_CREATE     = 2
PAGE_LOAD       = 3
PAGE_SAVE       = 4
TEXT_EMPTY      = 5
TEXT_CASUAL     = 6
TEXT_EASY       = 7
TEXT_NORMAL     = 8
TEXT_HARD       = 9
TEXT_OFF        = 10
TEXT_ON         = 11
TEXT_CREDITS    = 12

NUM_OPTIONS     = 4
NUM_APPEARANCES = 15
NUM_LETTERS     = 38
NUM_CREDITSTEXTS = 11
CREDITSROW      = 9

CREDITSTEXT_DELAY = 144

logoScreenData  = chars
firstSaveDesc   = gameOptions+4
saveDescEnd     = firstSaveDesc+MAX_SAVES*SAVEDESCSIZE

        ; Title screen entrypoint
        ;
        ; Parameters: -
        ; Returns: -
        ; Modifies: various

TitleScreen:    ldx #MAX_ACT-1
                lda #$00
TS_ClearAllActors:
                sta actT,x
                dex
                bpl TS_ClearAllActors
                lda #$ff
                sta CZ_LoadedCharset+1
                jsr InitScroll
                sta mapX
                sta mapY
                sta blockX
                sta blockY
                sta screen
                sta Irq1_Bg1+1
                sta scrollY
                lda #$78
                sta scrollX
                jsr SL_CalcSprSub               ;Predictable position for sprites
                lda #SONG_TITLE
                jsr PrepareSong
                lda #F_OPTIONS
                sta fileNumber
                lda #<gameOptions
                ldx #>gameOptions
                jsr LoadUncompressedFile
                jsr ApplyOptions
                ldx #MAX_NAMELENGTH-1
                lda #$00
                sta menuPos
TS_ClearName:   sta rangerName,x                ;Clear the new ranger's name
                dex
                bpl TS_ClearName
                jsr SetLogoColor                ;Logo initially invisible (black)
                ldx #39
                lda #$20
ClearFirstLastRow:
                sta screen1,x
                sta screen1+19*40,x
                dex
                bpl ClearFirstLastRow
                ldx #6*40
DrawLogo:       lda logoScreenData-1,x
                sta screen1+40-1,x
                dex
                bne DrawLogo
CopyPanelChars: lda panelChars,x                ;Copy panel chars to the game charset
                sta chars,x
                lda panelChars+$100,x
                sta chars+$100,x
                lda panelChars+$200,x
                sta chars+$200,x
                inx
                bne CopyPanelChars
                jsr BlankScreen                 ;Make sure we blank screen & wait for bottom before $d011 manipulation
                txa
                sta $d011                       ;Set $d011 also directly as raster interrupts might not be on yet
                ldy #C_CREW                     ;Ensure sprites needed by character creation
                jsr LoadChunkFile
                lda saveState+rangerName-playerStateStart
                beq FirstTimeInit               ;If has a filled name, exited the game and should save
                jmp SaveGame                    ;Else start with title

cheatCode:
FirstTimeInit:  lda #HP_PLAYER                  ;Give something to show on the panel
                sta actHp+ACTI_PLAYER           ;(also doubles as the cheat modification for player)
cheatCodeEnd:

        ; Main menu page

MainMenu:       lda #PAGE_MAIN
                jsr PrintPage
                jsr PrintNextCreditsText
                jsr DrawArrow
MainMenuLoop:   jsr WaitBottom
                lda creditsTextDelay
                cmp #6
                bcc MML_CreditsFadeOut
                cmp #CREDITSTEXT_DELAY-6
                bcc MML_NoCreditsFade
MML_CreditsFadeIn:
                lda #CREDITSTEXT_DELAY
                sbc creditsTextDelay
MML_CreditsFadeOut:
                tay
                lda creditsFadeTbl,y
                ldx #39
MML_SetCreditsColors:
                sta colors+CREDITSROW*40,x
                dex
                bpl MML_SetCreditsColors
MML_NoCreditsFade:
                dec creditsTextDelay
                bne MML_NoCreditsText
                jsr PrintNextCreditsText
MML_NoCreditsText:
                jsr TitleMenuFrame_NoWait
                bcc MainMenuLoop
                tay
                beq StartGame
                dey
                bne OptionsMenu
                jmp LoadGame

        ; Options page

OptionsMenu:    lda #PAGE_OPTIONS
                jsr PrintPage
                lda #$00
                sta menuPos
                jsr DrawArrow
RedrawOptions:  lda #$00
                sta temp1
                lda firstRowTbl+PAGE_OPTIONS
                sta temp2
RO_Loop:        ldx #25
                ldy temp2
                jsr GetRowColAddress
                ldx temp1
                lda gameOptions,x
                clc
                adc optionTextTbl,x
                jsr PrintTitleText
                inc temp2
                inc temp2
                inc temp1
                lda temp1
                cmp #NUM_OPTIONS
                bcc RO_Loop
OptionsMenuLoop:jsr TitleMenuFrame
                bcc OptionsMenuLoop
                cmp #NUM_OPTIONS
                beq BackToMain
                tax
                inc gameOptions,x
                lda gameOptions,x
                cmp optionMaxTbl,x
                bcc OptionOK
                lda #$00
                sta gameOptions,x
OptionOK:       jsr ApplyOptions
                lda #$01
                sta optionsModified
NoMusicToggle:  jmp RedrawOptions
BackToMain:     lda #$02
BackToMainCustom:
                sta menuPos
                jmp MainMenu

        ; Start new game / character creation

StartGame:      if SKIP_CHARACTER > 0
                lda #"A"
                sta rangerName
                jmp DoStartGame
                else
                lda #PAGE_CREATE
                jsr PrintPage
                lda #$00
                sta menuPos
                sta letterEntryIndex
                endif
                jsr DrawCharacter
                jsr DrawCharacterBackground
SG_UpdatePos:   jsr DrawArrow
                jsr UpdateFrame
StartGameLoop:  jsr RefreshAppearance
                jsr PrintRangerName
                ldx nameErrorFlash
                cpx #7
                bcs SG_NoNameErrorFlash
                lda creditsFadeTbl,x
                inx
                stx nameErrorFlash
                ldy #3
SG_NameErrorColor:
                sta colors+10*40+13,y
                dey
                bpl SG_NameErrorColor
SG_NoNameErrorFlash:
                jsr TitleMenuFrame
                bcc SG_NoAction
                jmp SG_Action
SG_NoAction:    lda keyType
                bmi SG_NoKeyType
                cmp #KEY_RETURN                  ;Enter = shortcut to starting game
                bne SG_NoEnter
                jsr MenuActionSound
                lda #3
                sta menuPos
                bne SG_UpdatePos
SG_NoEnter:     jsr SG_NameEntryKeyboard
                jmp StartGameLoop
SG_NoKeyType:   lda joystick
                and #JOY_LEFT|JOY_RIGHT
                bne SG_LeftRight
                sta menuLeftRightDelay
                beq StartGameLoop

SG_LeftRight:   ldy menuPos
                cpy #3                          ;Name, appearance, armor color have left/right controls
                bcs StartGameLoop
                ldx menuLeftRightDelay
                beq SG_LeftRightNoDelay
                dec menuLeftRightDelay
                bpl StartGameLoop
SG_LeftRightNoDelay:
                pha
                lda #MENU_MOVEDELAY-1
                ldx prevJoy
                bne SG_RepeatDelay
                lda #MENU_FIRSTMOVEDELAY-1
SG_RepeatDelay: sta menuLeftRightDelay
                lda #SFX_SELECT
                jsr QueueSfx
                pla
                cpy #$00
                bne SG_NoLetterSelect
                cmp #JOY_RIGHT
                beq SG_NextLetter
SG_PrevLetter:  dec letterEntryIndex
                bpl SG_LetterNotOver
                lda #NUM_LETTERS-1
SG_SetLetter:   sta letterEntryIndex
SG_LetterNotOver:
                jmp StartGameLoop
SG_NextLetter:  inc letterEntryIndex
                lda letterEntryIndex
                cmp #NUM_LETTERS
                bcc SG_LetterNotOver
                lda #$00
                beq SG_SetLetter

SG_NoLetterSelect:
                dey
                bne SG_NoAppearanceSelect
                cmp #JOY_RIGHT
                beq SG_NextAppearance
SG_PrevAppearance:
                dec appearanceIndex
                bpl SG_AppearanceNotOver
                lda #NUM_APPEARANCES-1
                bne SG_SetAppearance
SG_NextAppearance:
                inc appearanceIndex
                lda appearanceIndex
                cmp #NUM_APPEARANCES
                bcc SG_AppearanceNotOver
                lda #0
SG_SetAppearance:
                sta appearanceIndex
SG_AppearanceNotOver:
                jmp StartGameLoop

SG_NoAppearanceSelect:
                cmp #JOY_RIGHT
                beq SG_NextArmorColor
                dec armorColorIndex
                jmp StartGameLoop
SG_NextArmorColor:
                inc armorColorIndex
                jmp StartGameLoop

SG_Action:      tay
                beq SG_EnterLetterJoystick
                dey
                beq SG_NextAppearance
                dey
                beq SG_NextArmorColor
                dey
                beq DoStartGame
SG_Back:        lda #$00
                jmp BackToMainCustom
SG_EnterLetterJoystick:
                ldx letterEntryIndex
                jsr SG_EnterKey
                jmp StartGameLoop

        ; Actually start the game

DoStartGame:    jsr SG_GetNameLength            ;Must be something in the name
                cpy #$01
                bcs DSG_NameOK
                lda #2
                sta nameErrorFlash
                jsr SG_NameEditFail
                jmp StartGameLoop
DSG_NameOK:     jsr StartGameCommon
                lda #<EP_StartGame              ;Init state + play intro
                ldx #>EP_StartGame
                jmp ExecScript

StartGameCommon:lda pageNum
                cmp #PAGE_CREATE
                beq SGC_HideCharacter
                lda fastLoadMode                ;If loading game and using safe loading, no fade, as it just looks stupid to blank then fade
                beq SGC_NoLogoFade
                bne SGC_DoFade
SGC_HideCharacter:
                jsr HideCharacterBackground     ;Hide character only on the create screen
                jsr HideCharacter
                inc fileAge+C_CREW              ;Increment the age of the crew sprites to help purging it if needed
SGC_DoFade:     lda #$85
                sta logoFade
                sta textFade
                jsr FadeSong
SGC_FadeLogoOut:jsr TitleMenuFrame
                lda logoFade
                cmp #$80
                bne SGC_FadeLogoOut
SGC_NoLogoFade: jmp SaveModifiedOptions

SG_GetNameLength:
                ldy #$00
SG_GNLLoop:     lda rangerName,y
                beq SG_GNLDone
                iny
                bne SG_GNLLoop
SG_GNLDone:     rts

SG_NameEntryKeyboard:
                jsr RecognizeLetter
                bmi SG_GNLDone
                jsr MenuActionSound
SG_EnterKey:    jsr SG_GetNameLength
                lda letterTbl,x
                cmp #"]"
                beq SG_EraseLetter
                cpy #MAX_NAMELENGTH
                bcs SG_NameEditFail
                cmp #$20
                bne SG_NotSpace
                cpy #$00                        ;Do not put space to beginning
                beq SG_NameEditFail
SG_NotSpace:    sta rangerName,y
SG_NameEditDone:rts
SG_EraseLetter: tya
                beq SG_NameEditFail
                lda #$00
                sta rangerName-1,y
                rts
SG_NameEditFail:lda #SFX_DAMAGE                 ;Different sound if fails
                jmp QueueSfx

RecognizeLetter:
                ldx #NUM_LETTERS-1
RL_Loop:        cmp keyTbl,x
                beq RL_Found
                dex
                bpl RL_Loop
RL_Found:       rts

        ; Load game menu

SaveGame:       lda #PAGE_SAVE
                bne LG_Common
LoadGame:       lda #PAGE_LOAD
LG_Common:      jsr PrintPage
                jsr PrintSaveDescs
                lda lastSaveSlot
                sta menuPos
                jsr DrawArrow
LoadGameLoop:   jsr TitleMenuFrame
                bcc LoadGameLoop
                cmp #MAX_SAVES
                bcc DoLoadGame
LG_Exit:        lda #$01
                jmp BackToMainCustom

        ; Actually load the game

DoLoadGame:     sta lastSaveSlot
                ldx #F_SAVE
                jsr MakeFileName
                lda pageNum
                cmp #PAGE_SAVE
                beq DoSaveGame
                lda #<saveStart
                ldx #>saveStart
                jsr LoadUncompressedFile
                lda saveState+rangerName-playerStateStart
                beq LoadGameLoop                ;No name, game was empty
                jsr StartGameCommon             ;Save is valid, continue
                jmp RestoreState

        ; Actually save the game

DoSaveGame:     lda #SFX_PICKUP                 ;Different sound
                jsr QueueSfx
                lda #<(saveEnd-saveStart)
                sta zpBitsLo
                lda #>(saveEnd-saveStart)
                sta zpBitsHi
                lda #<saveStart
                ldx #>saveStart
                jsr SaveFile
                lda menuPos                     ;Get address for writing savedesc
                ldy #SAVEDESCSIZE
                ldx #<zpDestLo
                jsr MulU
                lda #<firstSaveDesc
                jsr Add8
                lda #>firstSaveDesc
                sta zpDestHi
                ldy #MAX_NAMELENGTH
DSG_CopyName:   lda saveState+rangerName-playerStateStart,y
                sta (zpDestLo),y
                dey
                bpl DSG_CopyName
                ldy #MAX_NAMELENGTH+1
                lda saveLevel
                sta (zpDestLo),y                ;Levelnumber
                ldx #$00
DSG_TimeLoop:   iny
                lda saveState+time-playerStateStart-MAX_NAMELENGTH-2,y
                sta (zpDestLo),y
                cpy #MAX_NAMELENGTH+4
                bcc DSG_TimeLoop
                jsr SaveOptions                 ;Unconditionally save options / savedescs now
                jmp LG_Exit                     ;Back to mainmenu

        ; Print savedescs to screen

PrintSaveDescs: lda #<firstSaveDesc
                sta temp1
                lda #>firstSaveDesc
                sta temp2
                lda #10
                sta PSD_Row+1
PSD_Loop:       ldx #1
                jsr PSD_GetColumn
                ldy #$00
                lda (temp1),y                   ;Check if contains a game (non-empty name)
                beq PSD_Empty
                lda temp1
                ldx temp2
                jsr PrintTextAX                 ;Print ranger name
                ldx #1+MAX_NAMELENGTH+2
                jsr PSD_GetColumn
                ldy #MAX_NAMELENGTH+1           ;Print level name
                lda (temp1),y
                tay
                lda lvlNameTblLo,y
                ldx lvlNameTblHi,y
                jsr PrintTextAX
                ldx #1+MAX_NAMELENGTH+14+4
                jsr PSD_GetColumn
                ldy #MAX_NAMELENGTH+2           ;Print elapsed game time
                lda (temp1),y
                ldy #$00
                jsr MD_PrintTimeSub2
                ldy #MAX_NAMELENGTH+3
                jsr PSD_PrintTimeSub
                ldy #MAX_NAMELENGTH+4
                jsr PSD_PrintTimeSub
PSD_Next:       ldx #<temp1
                lda #SAVEDESCSIZE
                jsr Add8
                lda PSD_Row+1
                cmp #10+(MAX_SAVES-1)*2
                bcs PSD_Done
                adc #2
                sta PSD_Row+1
                bne PSD_Loop
PSD_Empty:      ldx #15
                jsr PSD_GetColumn
                lda #TEXT_EMPTY
                jsr PrintTitleText
                jmp PSD_Next

PSD_GetColumn:
PSD_Row:        ldy #$00
                jmp GetRowColAddress

PSD_PrintTimeSub:
                lda (temp1),y
                ldy #$00
                jmp MD_PrintTimeSub

        ; Load an uncompressed file

LoadUncompressedFile:
                sta zpDestLo
                stx zpDestHi
                jsr OpenFile
                ldy #$00
LUF_Loop:       jsr GetByte
                bcs LUF_Done
                sta (zpDestLo),y
                iny
                bne LUF_Loop
                inc zpDestHi
                bne LUF_Loop
PSD_Done:
LUF_Done:       rts

        ; Apply the options to actual game code

ApplyOptions:   lda gameOptions
                sta AD_Difficulty+1
                lda gameOptions+1
                sta Irq4_SoundMode+1
                lda gameOptions+2
                sta PS_MusicMode+1
                lda gameOptions+3
                sta MP_DoubleClickOption+1
                sta AH_DoubleClickOption+1
SMO_NotModified:rts

        ; Save options / savedescs if modified

SaveModifiedOptions:
                lda optionsModified             ;Save options / savedescs now
                beq SMO_NotModified
SaveOptions:    lda #$00
                sta optionsModified
                lda #<(MAX_SAVES*SAVEDESCSIZE+4)
                sta zpBitsLo
                lda #>(MAX_SAVES*SAVEDESCSIZE+4)
                sta zpBitsHi
                lda #F_OPTIONS
                sta fileNumber
                lda #<gameOptions
                ldx #>gameOptions
                jmp SaveFile

        ; Frame / menu move subroutine

TitleMenuFrame: jsr WaitBottom
TitleMenuFrame_NoWait:
                jsr Random                      ;Run random so each game is different
                lda keyType
                bmi TMF_CheatStringDone2
                ldy cheatStringIndex
                cmp cheatString,y
                bne TMF_CheatStringWrongLetter
                iny
                cpy #cheatStringEnd-cheatString
                bcc TMF_CheatStringDone
                lda #$07                        ;Flash logo and apply cheat to player damage response
                sta logoFade                    ;(not reversible)
                ldx #cheatCodeEnd-cheatCode-1
TMF_CopyCheatCode:
                lda cheatCode,x
                sta UA_PlayerDamageCode,x
                dex
                bpl TMF_CopyCheatCode
TMF_CheatStringWrongLetter:
                ldy #$00
TMF_CheatStringDone:
                sty cheatStringIndex
TMF_CheatStringDone2:
                lda logoFade
                cmp #19
                beq TMF_NoLogoFade
                pha
                and #$7f
                lsr
                tay
                pla
                bmi TMF_LogoFadeOut
                inc logoFade
                bpl TMF_LogoFadeCommon
TMF_LogoFadeOut:and #$7f
                dec logoFade
                bmi TMF_LogoFadeCommon
                lda #$80
                sta logoFade
TMF_LogoFadeCommon:
                lda logoFadeBg2Tbl,y
                sta Irq1_Bg2+1
                lda logoFadeBg3Tbl,y
                sta Irq1_Bg3+1
                lda logoFadeCharTbl,y
                jsr SetLogoColor
TMF_NoLogoFade: lda textFade
                cmp #7
                beq TMF_NoTextFade
                and #$7f
                lsr
                tay
                lda textFadeTbl,y
                sta PP_FadeColor+1
                ldy pageNum                     ;Do not fade the top rows in main menu (with credits)
                beq TMF_SkipCreditsRow
                ldx #40-1
TMF_SetCreditsColors:
                sta colors+8*40,x
                dex
                bpl TMF_SetCreditsColors
TMF_SkipCreditsRow:
                ldx #6*40
TMF_SetTextColors:
                sta colors+9*40-1,x
                sta colors+15*40-1,x
                dex
                bne TMF_SetTextColors
                lda textFade
                bmi TMF_TextFadeOut
                inc textFade
                bpl TMF_NoTextFade
TMF_TextFadeOut:dec textFade
                bmi TMF_NoTextFade
                lda #$80
                sta textFade
TMF_NoTextFade: lda #$01                        ;Restore text color for panel update
                sta textColor
                jsr UpdatePanel
                jsr UpdateFrame
                jsr UpdatePanelBars
                jsr GetControls
                jsr UpdateFrame
                ldx pageNum
                lda textFade                    ;If text is not fully faded in, wait with no controls
                cmp #7                          ;(prevent messed-up transitions)
                bne TMF_NoControl
                jsr GetFireClick
                bcs TMF_Action
                lda joystick
                and #JOY_UP|JOY_DOWN
                beq TMF_NoControl
                ldy menuMoveDelay
                beq TMF_NoDelay
                dec menuMoveDelay
                bpl TMF_NoAction
TMF_NoDelay:    lsr
                bcc TMF_MoveDown
TMF_MoveUp:     cpx #PAGE_LOAD
                lda menuPos
                bne TMF_MoveUpOK
                bcs TMF_NoAction                ;No wrap on load/save pages
                lda lastRowTbl,x
TMF_MoveSetPos: sta menuPos
                bpl TMF_MoveCommon
TMF_MoveUpOK:   dec menuPos
                bpl TMF_MoveCommon
TMF_MoveDown:   lda menuPos
                cmp lastRowTbl,x
                bne TMF_MoveDownOK
                cpx #PAGE_LOAD
                bcs TMF_NoAction
                lda #$00
                bcc TMF_MoveSetPos
TMF_MoveDownOK: inc menuPos
TMF_MoveCommon: lda #SFX_SELECT
                jsr QueueSfx
                jsr DrawArrow
                lda #MENU_MOVEDELAY-1
                ldx prevJoy
                bne TMF_RepeatDelay
                lda #MENU_FIRSTMOVEDELAY-1
TMF_RepeatDelay:
TMF_NoControl:  sta menuMoveDelay
TMF_NoAction:   clc
                rts
TMF_Action:     jsr MenuActionSound
                lda menuPos
                sec
                rts

        ; Draw player character

DrawCharacter:  lda #ACT_PLAYER_NOARMOR
                sta actT
                lda #$00
                sta actF1
                sta actF2
                sta actD
                lda #$20
                sta actXL
                lda #$50
                sta actYL
                lda #$0d
                sta actXH
                lda #$08
                sta actYH
RefreshAppearance:
                lda appearanceIndex
                ldy #3
                ldx #<temp1
                jsr DivU
                sta temp2
                lda armorColorIndex
                and #$07
                tax
                lda armorColorTbl,x
                ldy temp2
                ora upperColorTbl,y
                sta rangerColor
                sta actFlash
                lda temp1
                asl
                asl
                sta rangerNoArmorBaseFrame
                sta plrNoArmorUpperBaseFrame
                jmp DrawActors

        ; Hide character

HideCharacter:  lda #ACT_NONE
                sta actT
                jmp DrawActors

        ; Draw/hide background for character

HideCharacterBackground:
                lda #$20
                skip2
DrawCharacterBackground:
                lda #96+128
DCB_Common:     sta temp1
                ldy #12
DCB_RowLoop:    ldx #25
                sty temp2
                jsr GetRowColAddress
                ldy #$02
DCB_ColLoop:    lda temp1
                sta (zpDestLo),y
                lda #6
                sta (zpBitsLo),y
                dey
                bpl DCB_ColLoop
                ldy temp2
                iny
                cpy #18
                bcc DCB_RowLoop
                rts

        ; Print character's name + joystick edit letter

PrintRangerName:lda #<rangerName
                sta zpSrcLo
                lda #>rangerName
                sta zpSrcHi
                ldx #18
                ldy #10
                jsr PrintText
                lda #$07
                sta textColor
                lda #$20
                ldx menuPos
                bne DRN_NoJoystickLetter
                ldx letterEntryIndex
                lda letterTbl,x
DRN_NoJoystickLetter:
                jsr PrintChar
                jmp PrintSpace                  ;Print space in case last letter was just erased

        ; Draw menu arrow

DrawArrow:      ldy pageNum
DA_OldColumn:   ldx #$00
DA_OldRow:      ldy #$00
                bmi DA_NoErase
                jsr GetRowColAddress
                lda #$20
                jsr PrintChar
DA_NoErase:     ldy pageNum
                lda menuPos
                asl
                adc firstRowTbl,y
                sta DA_OldRow+1
                ldx #$00
                tay
                jsr GetRowColAddress
DA_FindFirstLetter:
                lda (zpDestLo),y
                cmp #$20
                bne DA_LetterFound
                iny
                bne DA_FindFirstLetter
DA_LetterFound: dey
                sty DA_OldColumn+1
                lda PP_FadeColor+1
                sta textColor
                lda #">"
                jmp PrintChar

        ; Print multi-row page with centered text

PrintPage:      sta pageNum
                lda #SONG_TITLE
                jsr ForcePlaySong
                jsr WaitBottom
                jsr HideCharacter
                jsr ClearTextScreen
                lda pageNum
                tay
                jsr GetTitleTextAddress
                lda pageRowTbl,y
                sta temp1
PP_FadeColor:   lda #$00
PP_SetColor:    sta textColor
PP_RowLoop:     jsr CountRowLength
                beq PP_RowsDone
                lsr
                eor #$ff
                clc
                adc #20+1
                tax
                ldy temp1
                jsr GetRowColAddress
                jsr PrintTextContinue
                inc temp1
                inc temp1
                bne PP_RowLoop

        ; Print next credits texts

PrintNextCreditsText:
                lda creditsTextIndex
                tay
                clc
                adc #TEXT_CREDITS
                jsr GetTitleTextAddress
                iny
                cpy #NUM_CREDITSTEXTS
                bne PNCT_NotOver
                ldy #$00
PNCT_NotOver:   sty creditsTextIndex
                lda #CREDITSTEXT_DELAY
                sta creditsTextDelay
                lda #$20
                ldx #39
PNCT_Clear:     sta screen1+CREDITSROW*40,x
                dex
                bpl PNCT_Clear
                lda #CREDITSROW
                sta temp1
                lda #$00
                beq PP_SetColor

        ; Print a text resource

PrintTitleText: jsr GetTitleTextAddress
                ldy #$00
                jmp PrintTextContinue

        ; Get title text resource address to zpSrc

GetTitleTextAddress:
                tax
                lda titleTextsTblLo,x
                sta zpSrcLo
                lda titleTextsTblHi,x
                sta zpSrcHi
PP_RowsDone:    rts

        ; Count the row length for centering, returned in A

CountRowLength: ldy #$00
CRL_Loop:       lda (zpSrcLo),y
                bmi CRL_Explicit
                beq CRL_End
                iny
                bne CRL_Loop
CRL_End:        tya
CRL_End2:       php
                ldy #$00
                plp
                rts
CRL_Explicit:   inc zpSrcLo
                bne CRL_ExplicitNotOver
                inc zpSrcHi
CRL_ExplicitNotOver:
                and #$7f
                bpl CRL_End2

        ; Clear the text area

ClearTextScreen:ldx #3*40-1
                lda #$20
CTS_Loop:       sta screen1+7*40,x
                sta screen1+10*40,x
                sta screen1+13*40,x
                sta screen1+16*40,x
                dex
                bpl CTS_Loop
                lda #$ff
                sta DA_OldRow+1
                rts

        ; Set logo color (in A)

SetLogoColor:   ldx #6*40
SLC_Loop:       sta colors+40-1,x
                dex
                bne SLC_Loop
                rts

        ; Vars

pageNum:        dc.b 0
creditsTextIndex:dc.b 0
creditsTextDelay:dc.b 0
textFade:       dc.b 0
logoFade:       dc.b 0
menuMoveDelay:  dc.b 0
menuLeftRightDelay:
                dc.b 0
letterEntryIndex:
                dc.b 0
cheatStringIndex:
                dc.b 0
armorColorIndex:dc.b 0
appearanceIndex:dc.b 1
nameErrorFlash: dc.b $ff
optionsModified:dc.b 0

        ; Data

armorColorTbl:  dc.b 12,5,10,8,2,11,4,14
upperColorTbl:  dc.b $10,$20,$30
pageRowTbl:     dc.b 13,9,8,8,8,13
firstRowTbl:    dc.b 13,9,10,10,10
lastRowTbl:     dc.b 2,4,4,4,4
creditsFadeTbl: dc.b 0,0,2,2,7,7,1
textFadeTbl:    dc.b 0,6,3,1
logoFadeBg2Tbl: dc.b 0, 0, 0, 6, 2, 8, 10, 8, 2, 6
logoFadeBg3Tbl: dc.b 0, 0, 6, 14,15,7, 1, 7, 15,14
logoFadeCharTbl:dc.b 0, 14,11,9, 9, 9, 9, 9, 9, 9

optionTextTbl:  dc.b TEXT_CASUAL,TEXT_OFF,TEXT_OFF,TEXT_OFF
optionMaxTbl:   dc.b 4,2,2,2

letterTbl:      dc.b "]ABCDEFGHIJKLMNOPQRSTUVWXYZ 0123456789"
keyTbl:         dc.b KEY_DEL
                dc.b KEY_A
                dc.b KEY_B
                dc.b KEY_C
                dc.b KEY_D
                dc.b KEY_E
                dc.b KEY_F
                dc.b KEY_G
                dc.b KEY_H
                dc.b KEY_I
                dc.b KEY_J
                dc.b KEY_K
                dc.b KEY_L
                dc.b KEY_M
                dc.b KEY_N
                dc.b KEY_O
                dc.b KEY_P
                dc.b KEY_Q
                dc.b KEY_R
                dc.b KEY_S
                dc.b KEY_T
                dc.b KEY_U
                dc.b KEY_V
                dc.b KEY_W
                dc.b KEY_X
                dc.b KEY_Y
                dc.b KEY_Z
                dc.b KEY_SPACE
                dc.b KEY_0
                dc.b KEY_1
                dc.b KEY_2
                dc.b KEY_3
                dc.b KEY_4
                dc.b KEY_5
                dc.b KEY_6
                dc.b KEY_7
                dc.b KEY_8
                dc.b KEY_9

cheatString:    dc.b KEY_V
                dc.b KEY_O
                dc.b KEY_L
                dc.b KEY_O
                dc.s KEY_S
cheatStringEnd:

titleTextsTblLo:dc.b <mainMenuText
                dc.b <optionsText
                dc.b <createText
                dc.b <loadGameText
                dc.b <saveGameText
                dc.b <emptyText
                dc.b <casualText
                dc.b <easyText
                dc.b <normalText
                dc.b <hardText
                dc.b <offText
                dc.b <onText
                dc.b <creditsText0a
                dc.b <creditsText0b
                dc.b <creditsText1
                dc.b <creditsText2
                dc.b <creditsText3
                dc.b <creditsText4
                dc.b <creditsText5
                dc.b <creditsText6
                dc.b <creditsText7
                dc.b <creditsText8
                dc.b <creditsText9

titleTextsTblHi:dc.b >mainMenuText
                dc.b >optionsText
                dc.b >createText
                dc.b >loadGameText
                dc.b >saveGameText
                dc.b >emptyText
                dc.b >casualText
                dc.b >easyText
                dc.b >normalText
                dc.b >hardText
                dc.b >offText
                dc.b >onText
                dc.b >creditsText0a
                dc.b >creditsText0b
                dc.b >creditsText1
                dc.b >creditsText2
                dc.b >creditsText3
                dc.b >creditsText4
                dc.b >creditsText5
                dc.b >creditsText6
                dc.b >creditsText7
                dc.b >creditsText8
                dc.b >creditsText9

mainMenuText:   dc.b "NEW GAME",0
                dc.b "CONTINUE",0
                dc.b "OPTIONS ",0
                dc.b 0

optionsText:    dc.b $95,"DIFFICULTY",0
                dc.b $95,"SOUND FX",0
                dc.b $95,"MUSIC",0
                dc.b $95,"DBL-CLICK MENU",0
                dc.b $95,"BACK",0
                dc.b 0

createText:     dc.b "RANGER PROFILE DATA",0
                dc.b $8f,"NAME",0
                dc.b $8f,"APPEARANCE",0
                dc.b $8f,"ARMOR COLOR",0
                dc.b $8f,"CONFIRM",0
                dc.b $8f,"CANCEL",0

                dc.b 0

loadGameText:   dc.b "CONTINUE GAME FROM",0
                dc.b " ",0
                dc.b " ",0
                dc.b " ",0
                dc.b " ",0
                dc.b "CANCEL",0
                dc.b 0

saveGameText:   dc.b "SAVE GAME TO",0
                dc.b " ",0
                dc.b " ",0
                dc.b " ",0
                dc.b " ",0
                dc.b "END WITHOUT SAVING",0
                dc.b 0

soundTestText:  dc.b "A-Z FOR SONGS  RUNSTOP EXITS",0,0

emptyText:      dc.b "EMPTY SLOT",0
casualText:     dc.b "CASUAL",0
easyText:       dc.b "EASY  ",0
normalText:     dc.b "NORMAL",0
hardText:       dc.b "HARD  ",0
offText:        dc.b "OFF",0
onText:         dc.b "ON ",0

                     ;0123456789012345678901234567890123456789
creditsText0a:  dc.b "STEEL RANGER DEMO - FULL GAME AT",0,0
creditsText0b:  dc.b "WWW.PSYTRONIK.NET  PSYTRONIK.ITCH.IO",0,0
creditsText1:   dc.b "CODE, GFX & MUSIC: LASSE \\RNI",0,0
creditsText2:   dc.b "PACKAGING ARTWORK: TREVOR STOREY",0,0
creditsText3:   dc.b "PACKAGING: JASON MACKENZIE",0,0
creditsText4:   dc.b "ADDIT.CODE: PER OLOFSSON, WOLFRAM SANG",0,0
creditsText5:   dc.b "CHRISTOPH THELEN & MAGNUS LIND",0,0
creditsText6:   dc.b "SPACE, 1-8 OR ,. TO SELECT WEAPON",0,0
creditsText7:   dc.b "OR DBL-CLICK, HOLD FIRE & LEFT/RIGHT",0,0
creditsText8:   dc.b "RUNSTOP FOR PAUSE MENU, MAP & STATUS",0,0
creditsText9:   dc.b "OR DBL-CLICK & HOLD FIRE 2 SECONDS",0,0

                org chars
                incbin title.scr
                org chars+$300
                incbin title.chr
                ds.b 8,$ff                      ;Background for character

                if * > $fffa
                    err
                endif

