IRQ1_LINE       = MIN_SPRY-24
IRQ3_LINE       = SCROLLROWS*8+45
IRQ5_LINE       = SCROLLROWS*8+54
IRQ6_LINE       = 248

        ; Raster interrupt 4: perform scrollwork. Note: uses stack instead of ZP for register storage
        ; to allow re-entrancy

Irq4:           pha
                txa
                pha
                tya
                pha
                lda irqSave01
                pha
                lda #$35                        ;We may be interrupted while main program has $01 value $34
                sta irqSave01
                sta $01
                cld
                cli                             ;Allow re-entrancy
Irq4_SfxNum:    lda #$00                        ;Play a new sound this frame?
                beq Irq4_SfxDone
Irq4_SoundMode: ldx #$00                        ;Check for sounds disabled
                beq Irq4_SfxDone
                tay
Irq4_MusicCheck:lda #$00
                bne Irq4_HasMusic
Irq4_NextChn:   lda #$00
                clc
                adc #$07
                cmp #7*3
                bcc Irq4_ChnNotOver
Irq4_HasMusic:  lda #$00                        ;If playing music, always use channel 1
Irq4_ChnNotOver:sta Irq4_NextChn+1
                tax
                lda ntChnSfx,x                  ;If channel not empty, check priority
                beq Irq4_SfxOk
                cmp #SOUND_OVERWRITE_DELAY
                bcs Irq4_SfxOk
                lda sfxTblLo-1,y
                cmp ntChnSfxLo,x
                lda sfxTblHi-1,y
                sbc ntChnSfxHi,x
                bmi Irq4_SfxDone
Irq4_SfxOk:     lda #$01
                sta ntChnSfx,x
                lda sfxTblLo-1,y
                sta ntChnSfxLo,x
                lda sfxTblHi-1,y
                sta ntChnSfxHi,x
Irq4_SfxDone:   ldx #$00
                stx Irq4_SfxNum+1
                if SHOW_PLAYROUTINE_TIME > 0
                dec $d020
                endif
                jsr PlayRoutine
                if SHOW_PLAYROUTINE_TIME > 0
                inc $d020
                endif
                lda newFrameFlag                ;Perform colorscroll here
                bpl Irq4_NoColorScroll
Irq4_ColorScroll:
                and #$7f                        ;Retain the new frame flag, only clear colorscroll
                sta newFrameFlag
Irq4_ColorSide: ldx #$00
                stx irqTemp
                if SHOW_COLORSCROLL_TIME > 0
                dec $d020
                endif
Irq4_ColorJump: jsr $0000
                if SHOW_COLORSCROLL_TIME > 0
                inc $d020
                endif
Irq4_NoColorScroll:
                pla
                sta irqSave01
                sta $01
                pla
                tay
                pla
                tax
                pla
                rti

        ; Raster interrupt 1. Top of gamescreen

Irq1:           cld
                sta irqSaveA
                stx irqSaveX
                sty irqSaveY
                lda #$35
                sta $01                         ;Ensure IO memory is available
                lda newFrameFlag                ;New frame?
                beq Irq1_NoNewFrame
                bmi Irq1_NoNewFrame             ;If was late from colorscroll, wait
Irq1_AnimateLevel:                              ;Animate level background now
                lda #$00
                beq Irq1_NoLevelAnimation
                if SHOW_CHARANIM_TIME > 0
                inc $d020
                endif
                jsr levelCode
                if SHOW_CHARANIM_TIME > 0
                dec $d020
                endif
Irq1_NoLevelAnimation:
                lda flashScreen                 ;Flash effect
                beq Irq1_NoScreenFlash
                dec flashScreen
                beq Irq1_ResetScreenFlash
                lda #$01
                sta Irq1_Bg3+1
                bne Irq1_NoScreenFlash
Irq1_ResetScreenFlash:
                jsr SetZoneColors
Irq1_NoScreenFlash:
Irq1_NewScrollX:lda #$00
                sta Irq1_ScrollX+1
Irq1_NewScrollY:lda #$00
                sta Irq1_ScrollY+1
Irq1_NewD018:   lda #$00
                sta Irq1_D018+1
Irq1_NewD015:   lda #$00
                sta Irq1_D015+1
Irq1_BadLineFlag:lda #$00
                sta Irq3_BadLineFlag+1
Irq1_NewFirstSortSpr:
                lda #$00
                sta Irq1_FirstSortSpr+1
Irq1_NewSprPtrHi:
                lda #$00                        ;Ensure sprite frames are loaded to the
                cmp Irq2_Spr0Frame+2            ;correct screen
                beq Irq1_NoSprPtrHiChange
                sta Irq2_Spr0Frame+2
                sta Irq2_Spr1Frame+2
                sta Irq2_Spr2Frame+2
                sta Irq2_Spr3Frame+2
                sta Irq2_Spr4Frame+2
                sta Irq2_Spr5Frame+2
                sta Irq2_Spr6Frame+2
                sta Irq2_Spr7Frame+2
Irq1_NoSprPtrHiChange:
                lda #$00
                sta newFrameFlag
Irq1_NoNewFrame:if USETURBOMODE > 0
                lda #$00
                sta $d07a                       ;SCPU back to slow mode
                sta $d030                       ;C128 back to 1MHz
                endif
Irq1_ScrollX:   lda #$17
                sta $d016
Irq1_ScrollY:   lda #$57
                sta $d011
Irq1_D018:      ldy #GAMESCR1_D018
                sty $d018
Irq1_Bg1:       lda #$00
                sta $d021
Irq1_Bg2:       lda #$00
                sta $d022
Irq1_Bg3:       lda #$00
                sta $d023
Irq1_D015:      lda #$00
                sta $d015
                bne Irq1_HasSprites
Irq1_NoSprites: jmp Irq2_AllDone
                if USETURBOMODE = 0
                nop                             ;Padding to prevent the multiplexer from erroring
                nop
                endif
Irq1_HasSprites:lda #<Irq2                      ;Set up the sprite display IRQ
                sta $fffe
                lda #>Irq2
                sta $ffff
Irq1_FirstSortSpr:
                ldx #$00                        ;Go through the first sprite IRQ immediately
                if SHOW_SPRITEIRQ_TIME > 0
                inc $d020
                endif

        ;Raster interrupt 2. Sprite multiplexer

Irq2_Spr0:      lda sortSprY,x
                sta $d00f
                lda sortSprF,x
Irq2_Spr0Frame: sta screen1+$03ff
                lda sortSprX,x
                ldy sortSprD010,x
                sta $d00e
                sty $d010
                lda sortSprC,x
                sta $d02e
                bmi Irq2_SprIrqDone2
                inx

Irq2_Spr1:      lda sortSprY,x
                sta $d00d
                lda sortSprF,x
Irq2_Spr1Frame: sta screen1+$03fe
                lda sortSprX,x
                ldy sortSprD010,x
                sta $d00c
                sty $d010
                lda sortSprC,x
                sta $d02d
                bmi Irq2_SprIrqDone2
                inx

Irq2_Spr2:      lda sortSprY,x
                sta $d00b
                lda sortSprF,x
Irq2_Spr2Frame: sta screen1+$03fd
                lda sortSprX,x
                ldy sortSprD010,x
                sta $d00a
                sty $d010
                lda sortSprC,x
                sta $d02c
                bmi Irq2_SprIrqDone2
                inx

Irq2_Spr3:      lda sortSprY,x
                sta $d009
                lda sortSprF,x
Irq2_Spr3Frame: sta screen1+$03fc
                lda sortSprX,x
                ldy sortSprD010,x
                sta $d008
                sty $d010
                lda sortSprC,x
                sta $d02b
                bpl Irq2_ToSpr4
Irq2_SprIrqDone2:
                jmp Irq2_SprIrqDone
Irq2_ToSpr4:    inx

Irq2_Spr4:      lda sortSprY,x
                sta $d007
                lda sortSprF,x
Irq2_Spr4Frame: sta screen1+$03fb
                lda sortSprX,x
                ldy sortSprD010,x
                sta $d006
                sty $d010
                lda sortSprC,x
                sta $d02a
                bmi Irq2_SprIrqDone
                inx

Irq2_Spr5:      lda sortSprY,x
                sta $d005
                lda sortSprF,x
Irq2_Spr5Frame: sta screen1+$03fa
                lda sortSprX,x
                ldy sortSprD010,x
                sta $d004
                sty $d010
                lda sortSprC,x
                sta $d029
                bmi Irq2_SprIrqDone
                inx

Irq2_Spr6:      lda sortSprY,x
                sta $d003
                lda sortSprF,x
Irq2_Spr6Frame: sta screen1+$03f9
                lda sortSprX,x
                ldy sortSprD010,x
                sta $d002
                sty $d010
                lda sortSprC,x
                sta $d028
                bmi Irq2_SprIrqDone
                inx

Irq2_Spr7:      lda sortSprY,x
                sta $d001
                lda sortSprF,x
Irq2_Spr7Frame: sta screen1+$03f8
                lda sortSprX,x
                ldy sortSprD010,x
                sta $d000
                sty $d010
                lda sortSprC,x
                sta $d027
                bmi Irq2_SprIrqDone
                inx
Irq2_ToSpr0:    jmp Irq2_Spr0

                if (Irq2_Spr0 & $ff00) != (Irq2_Spr7 & $ff00)
                err
                endif

Irq2_SprIrqDone:
                if SHOW_SPRITEIRQ_TIME > 0
                dec $d020
                endif
                ldy sprIrqLine,x                ;Get startline of next IRQ
                beq Irq2_AllDone                ;(0 if was last)
                inx
                stx Irq2_SprIndex+1             ;Store next IRQ sprite start-index
                txa
                and #$07
                tax
                lda sprIrqJumpTbl,x             ;Get the correct jump address
                sta Irq2_SprJump+1
                tya
                sec
                sbc fileOpen
                sbc #$03                        ;Already late from the next IRQ?
                cmp $d012
                bcs SetNextIrqNoAddress
                bcc Irq2_Direct                 ;If yes, execute directly

Irq2:           cld
                sta irqSaveA
                stx irqSaveX
                sty irqSaveY
                lda #$35
                sta $01                         ;Ensure IO memory is available
Irq2_Direct:
                if SHOW_SPRITEIRQ_TIME > 0
                inc $d020
                endif
Irq2_SprIndex:  ldx #$00
Irq2_SprJump:   jmp Irq2_Spr0

Irq2_AllDone:   lda #IRQ3_LINE-1
                sec
                sbc fileOpen
                tay
                sbc #$03
                cmp $d012                       ;Late from the scorepanel IRQ?
                bcc Irq2_LatePanel
                lda #<Irq3
                ldx #>Irq3
SetNextIrq:     sta $fffe
                stx $ffff
SetNextIrqNoAddress:
                sty $d012
                dec $d019                       ;Acknowledge raster IRQ
                lda irqSave01
                sta $01                         ;Restore $01 value
                lda irqSaveA
                ldx irqSaveX
                ldy irqSaveY
                rti

Irq2_LatePanel: jmp Irq3_Direct

        ; Raster interrupt 3. Gamescreen / scorepanel split

Irq3:           sta irqSaveA
                stx irqSaveX
                sty irqSaveY
                cld
                lda #$35
                sta $01                         ;Ensure IO memory is available
Irq3_Direct:    lda $d011
                ldx #IRQ3_LINE
Irq3_Wait:      cpx $d012
                bcs Irq3_Wait
                ora #$47                        ;Blank & Y-scroll to bottom
Irq3_BadLineFlag:
                ldx #$00
                bpl Irq3_NoBadLine
                sta $d011
Irq3_NoBadLine: ldx #$00
                stx $d015
                ldx #EMPTYSPRITEFRAME
N               set 0
                repeat 8
                stx screen1+$3f8+N
N               set N+1
                repend
                nop
                sta $d011
                ldx #PANEL_D018
                stx $d018
                lda #$00
                sta $d021
                lda #PANEL_BG1
                sta $d022
                lda #PANEL_BG2
                sta $d023
                lda #>Irq4                      ;Jump to update / scrollwork IRQ after finishing this IRQ
                pha
                lda #<Irq4
                pha
                php
                lda #$18                        ;Fixed X scrolling
                sta $d016
                lda #IRQ5_LINE
                sec
                sbc fileOpen                    ;One line advance if file open
                tay
                lda #<Irq5
                ldx #>Irq5
                jmp SetNextIrq

        ; Raster interrupt 5. Show scorepanel

Irq5:           sta irqSaveA
                stx irqSaveX
                lda #$35
                sta $01                         ;Ensure IO memory is available
                lda #$17
                ldx #IRQ5_LINE+1
Irq5_Wait:      cpx $d012
                bcs Irq5_Wait
                sta $d011
                sty irqSaveY
Irq5_End:       lda #<Irq1
                ldx #>Irq1
                ldy #IRQ1_LINE
                jmp SetNextIrq

        ; Raster interrupt 6: setup SCPU / C128 turbo mode

                if USETURBOMODE > 0
Irq6:           sta irqSaveA
                stx irqSaveX
                sty irqSaveY
                lda #$35
                sta $01                         ;Ensure IO memory is available
                ldx fileOpen
                bne Irq6_NoTurbo
                inx
                stx $d07b                       ;SCPU turbo mode & C128 2MHz mode enable
                stx $d030                       ;if not loading
Irq6_NoTurbo:   lda #<Irq1                      ;Back to screen top interrupt
                ldx #>Irq1
                ldy #IRQ1_LINE
                jmp SetNextIrq
                endif

        ; IRQ redirector when Kernal is on

RedirectIrq:    ldx $01
                lda #$35                        ;Note: this will necessarily have overhead,
                sta $01                         ;which means that the sensitive IRQs like
                lda #>RI_Return                 ;the panel-split should take extra advance
                pha
                lda #<RI_Return
                pha
                php
                jmp ($fffe)
RI_Return:      stx $01
                jmp $ea81

        ; Silence SID, clear sprites, and stop raster IRQs. Used when beginning slowloading operation
        ;
        ; Parameters: -
        ; Returns: -
        ; Modifies: A

StopIrq:        jsr WaitBottom
                jsr SilenceSID
                sta $d01a                       ;Raster IRQs off
                sta $d011                       ;Blank screen completely
                rts

        ; Restart IRQs
        ;
        ; Parameters: -
        ; Returns: -
        ; Modifies: A

StartIrq:       lda #$01
                sta $d01a
                cli
                rts
