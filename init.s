        ; Initialize registers/variables at startup. This code is called only once and can be
        ; disposed after that.
        ;
        ; Parameters: -
        ; Returns: -
        ; Modifies: A,X,Y,temp vars

InitAll:        lda ntscFlag
                beq IsPAL
                lda #30                         ;Compensate game clock speed for NTSC
                sta timeMaxTbl+3                ;(otherwise no compensation)
IsPAL:          if USETURBOMODE > 0
                lda $d030                       ;Enable extra IRQ for turbo switching for C128 & SCPU
                cmp #$ff
                bne UseTurbo
                lda $d0bc
                bmi NoTurbo
UseTurbo:       ldx #TurboCodeEnd-TurboCode
CopyTurboCode:  lda TurboCode-1,x
                sta Irq5_End-1,x
                dex
                bne CopyTurboCode
NoTurbo:
                endif

        ; Setup safe mode loader screen blanking

                ldx #$02
InitGetByteJump:lda getByteJump,x               ;EOR getbyte jump between loader and memory. This is
                eor GetByte,x                   ;later used to switch between the two
                sta getByteJump,x
                dex
                bpl InitGetByteJump
                lda fastLoadMode
                bmi IA_UseFastLoad
                bne InitZeroPage
                lda #<StopIrq                   ;Patch the loader for either fast or slowload prepare
                sta SL_StopIrqJsr+1             ;as necessary
                lda #>StopIrq
                sta SL_StopIrqJsr+2
                bne InitZeroPage
IA_UseFastLoad: lda #<ClearSprites
                sta FL_ClearSpritesJsr+1
                lda #>ClearSprites
                sta FL_ClearSpritesJsr+2

        ; Initialize other zeropage values

InitZeroPage:   lda #<fileAreaStart
                sta freeMemLo
                lda #>fileAreaStart
                sta freeMemHi
                lda #>fileAreaEnd
                sta musicDataLo
                sta zoneBufferLo
                lda #>fileAreaEnd
                sta musicDataHi
                sta zoneBufferHi
                lda #$7f
                sta ntInitSong
                jsr InitScroll                  ;Returns with A=0
                sta panelTextDelay
                sta dialogueHi
                sta joystick
                sta ntFiltPos
                sta ntFiltTime
                sta firstSortSpr

        ; SID detection from http://codebase64.org/doku.php?id=base:detecting_sid_type_-_safe_method

                sei
                jsr WaitBottom
                lda #$0b    ;Blank screen now
                sta $d011
                lda #$ff    ;Set frequency in voice 3 to $ffff
                sta $d412   ;...and set testbit (other bits doesn't matter) in $d012 to disable oscillator
                sta $d40e
                sta $d40f
                lda #$20    ;Sawtooth wave and gatebit OFF to start oscillator again.
                sta $d412
                lda $d41b   ;Accu now has different value depending on sid model (6581=3/8580=2)
                cmp #$02    ;If result out of bounds, it's fast emu or something; use 6581 code (skip filter modify)
                beq SIDDetect_8580
SIDDetect_6581: lda #$4c
                sta Play_ModifyCutoff8580
                lda #<Play_CutoffOK
                sta Play_ModifyCutoff8580+1
                lda #>Play_CutoffOK
                sta Play_ModifyCutoff8580+2
SIDDetect_8580:

        ; Initialize sprite cache variables

                dec $01
                ldx #$3f
IPRV_Loop:      lda #$00
                sta cacheSprAge,x
                sta emptySprite,x
                cpx #$10
                bcs IPRV_SkipMiscVar
                sta displayedAmmo,x
IPRV_SkipMiscVar:
                lda #$ff
                sta cacheSprFile,x
                dex
                bpl IPRV_Loop
                inc $01
                sta sprFileNum                  ;These vars to be initialized with $ff
                sta levelNum
                sta autoDeactObj
                sta wpnMenuMode
                sta menuMode
                sta panelUpdateFlags

        ; Initialize the sprite multiplexing system

InitSprites:    ldx #MAX_SPR
ISpr_Loop:      txa
                sta sprOrder,x
                lda #$ff
                sta sprY,x
                dex
                bpl ISpr_Loop

        ; Initialize preloaded sprites

                ldx #1
ISpr_Preloaded: lda preloadedLo,x
                sta fileLo+C_COMMON,x
                sta zpDestLo
                sta zpBitsLo
                lda preloadedHi,x
                sta zpDestHi
                sta zpBitsHi
                sta fileHi+C_COMMON,x
                lda preloadedNumObjects,x
                sta fileNumObjects+C_COMMON,x
                txa
                clc
                adc #C_COMMON
                tay
                stx temp1
                jsr LF_Relocate
                ldx temp1
                dex
                bpl ISpr_Preloaded

        ; Initialize video + SID registers

InitVideo:      lda #$00
                sta $d01b                       ;Sprites on top of BG
                sta $d01d                       ;Sprite X-expand off
                sta $d017                       ;Sprite Y-expand off
                sta $d026
                sta $d415                       ;Filter lowbyte for all subsequent music
                lda #$01
                sta $d025
                lda #$ff                        ;Set all sprites multicolor
                sta $d01c
                ldx #$10
IV_SpriteY:     dex
                dex
                sta $d001,x
                bne IV_SpriteY
                sta $d015                       ;All sprites on and to the bottom
                jsr WaitBottom                  ;(some C64's need to "warm up" sprites
                                                ;to avoid one frame flash when they're
                stx $d015                       ;actually used for the first time)

        ; Init text chars + scorepanel screen data

InitPanelChars: ldy #$04
IPC_Loop:       lda panelCharData,x
IPC_Sta:        sta panelChars,x
                inx
                bne IPC_Loop
                inc IPC_Loop+2
                inc IPC_Sta+2
                dey
                bne IPC_Loop
                ldx #120
IPS_Loop:       lda panelScreenData-1,x
                sta panelScreen+SCROLLROWS*40-1,x
                dex
                bne IPS_Loop
                ldx #39
IPCol_Loop:     lda #$09                        ;Init panel colors
                sta colors+SCROLLROWS*40,x
                sta colors+SCROLLROWS*40+40,x
                cpx #26
                beq IPCol_SkipYellow
                lda #$0f
IPCol_SkipYellow:
                sta colors+SCROLLROWS*40+80,x
                dex
                bpl IPCol_Loop

        ; Initialize raster IRQs
        ; Relies on loader init to have already disabled the timer interrupt

InitRaster:     lda #<RedirectIrq               ;Setup "Kernal on" IRQ redirector
                sta $0314
                lda #>RedirectIrq
                sta $0315
                lda #<Irq1                      ;Set initial IRQ vector
                sta $fffe
                lda #>Irq1
                sta $ffff
                lda #IRQ1_LINE                  ;Line where next IRQ happens
                sta $d012

        ; Initialization done

                jmp LoadTitleScreen

        ; C128 / SCPU turbo mode setup IRQ code

                if USETURBOMODE > 0
TurboCode:      lda #<Irq6
                ldx #>Irq6
                ldy #IRQ6_LINE
TurboCodeEnd:
                endif

panelCharData:  incbin bg/scorescr.chr

panelScreenData:dc.b 0
                ds.b 24,1
                dc.b 1
                dc.b 2
                ds.b 12,1
                dc.b 3
                dc.b 4
                ds.b 25,32
                dc.b 5
                ds.b 12,32
                dc.b 5
                dc.b 6
                ds.b 25,7
                dc.b 8
                dc.b 27
                ds.b 3,95
                dc.b 28
                ds.b 6,95
                dc.b 29
                dc.b 9

        ; Preloaded spritefile data

preloadedLo:    dc.b <sprCommon, <sprPlayer
preloadedHi:    dc.b >sprCommon, >sprPlayer
preloadedNumObjects:
                incbin sprcommon.hdr
                incbin sprplayer.hdr

