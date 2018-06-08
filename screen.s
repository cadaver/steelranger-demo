PANEL_BG1       = $0b
PANEL_BG2       = $0c
GAMESCR1_D018   = $9e
GAMESCR2_D018   = $ae
TEXTSCR_D018    = $98
PANEL_D018      = $98

SCREEN_FLASH_LENGTH = 2

vColBuf         = colors+24*40

        ; Wait for bottom of screen
        ;
        ; Parameters: -
        ; Returns: -
        ; Modifies: A

WaitBottom:     lda $d011                       ;Wait until bottom of screen
                bmi WaitBottom
WB_Loop2:       lda $d011
                bpl WB_Loop2
                rts
                
        ; Blank the gamescreen and turn off sprites
        ; (return to normal display by calling UpdateFrame)
        ;
        ; Parameters: -
        ; Returns: A=0
        ; Modifies: A,X

BlankScreen:    jsr ClearSprites
                ldx #$17
                stx Irq1_ScrollX+1
                ldx #$57
                stx Irq1_ScrollY+1
                rts

        ; Clear sprites only and cancel frame update. Used when beginning fastloading operation
        ;
        ; Parameters: -
        ; Returns: A=0
        ; Modifies: A

ClearSprites:   jsr WaitBottom
                lda #$00
                sta newFrameFlag
                sta Irq1_D015+1
                sta Irq1_AnimateLevel+1         ;Always disable level animation while blanked / sprites off
                rts

        ; Perform scrolling logic
        ;
        ; Parameters: -
        ; Returns: -
        ; Modifies: A,X,Y

SL_ApplyPrecalc:
SL_PrecalcX:    lda #$00
                sta scrollX
SL_PrecalcY:    lda #$00
                sta scrollY
                inc scrCounter                  ;Move to colorscroll / draw phase
                lda screen
                eor #$01
                sta screen                      ;Swap screens
SL_CalcSprSub:  lda scrollX
                and #$38
                sta temp1
                lda blockX
                sta DBU_BlockX+1
                beq SL_CSSBlockXZero
                lda #$40
SL_CSSBlockXZero:
                ora temp1
                sec
                sbc #$78
                and #$7f
                sta DA_SprSubXL+1
                lda mapX
                sta DBU_MapX+1
                sbc #$02
                sta DA_SprSubXH+1
                lda scrollY                     ;Shake depending on which way is available
                cmp #$20
                bcs SL_CSSShakeNeg
                adc shakeScreen
                bcc SL_CSSShakeDone
SL_CSSShakeNeg: sbc shakeScreen
SL_CSSShakeDone:
                sta UF_FinalScrollY+1
                and #$38
                sta temp1
                lsr shakeScreen                 ;Lessen shake for next frame
                lda blockY
                sta DBU_BlockY+1
                beq SL_CSSBlockYZero
                lda #$40
SL_CSSBlockYZero:
                ora temp1
                sec
                sbc #$30
                and #$7f
                sta DA_SprSubYL+1
                lda mapY
                sta DBU_MapY+1
                sbc #$01
                sta DA_SprSubYH+1
                rts

ScrollLogic:    lda scrCounter
                bne SL_ApplyPrecalc
                lda scrollSX                    ;Check if already at right edge
                bmi SL_NoLimitXPre
                lda mapX
                clc
                adc #19
                cmp mapSizeX
                bcs SL_LimitXPre
SL_NoLimitXPre: lda scrollX                     ;Phase 0: No shifting yet -
                clc                             ;limit scrolling inside the
                adc scrollSX                    ;char (finescrolling) and
                bpl SL_LimitXOk1                ;make preparations for shifting
SL_LimitXPre:   lda #$00                        ;the screen.
SL_LimitXOk1:   cmp #$40
                bcc SL_LimitXOk2
                lda #$3f
SL_LimitXOk2:   sta scrollX
                lda scrollSY
                bmi SL_NoLimitYPre              ;Check if already at bottom edge
                if (SCROLLROWS & 1) = 0
                lda blockY
                beq SL_NoLimitYPre
                endif
                lda mapY
                clc
                adc #SCROLLROWS/2
                cmp mapSizeY
                bcs SL_LimitYPre
SL_NoLimitYPre: lda scrollY
                clc
                adc scrollSY
                bpl SL_LimitYOk1
SL_LimitYPre:   lda #$00
SL_LimitYOk1:   cmp #$40
                bcc SL_LimitYOk2
                lda #$3f
SL_LimitYOk2:   sta scrollY
                jsr SL_CalcSprSub
                ldx #$04                        ;Reset shift direction (center)
                lda scrollX
                clc
                adc scrollSX
                tay
                bmi SL_XNeg
                cmp #$40
                bcs SL_XPos
                bcc SL_XDone

SL_XPos:        lda blockX                      ;Update block & map-coords
                eor #$01
                sta blockX
                bne SL_XPosOk2
                inc mapX
SL_XPosOk2:     inx
                bpl SL_XDone
SL_XPosLimit:   ldy #$00
                beq SL_XDone

SL_XNeg:        lda blockX                      ;Are we on the edge of map?
                bne SL_XNegOk                   ;(left)
                lda mapX
                beq SL_XLimit
SL_XNegOk:      lda blockX                      ;Update block & map-coords
                eor #$01
                sta blockX
                beq SL_XNegOk2
                dec mapX
SL_XNegOk2:     dex

SL_XDone:       lda scrollSX                    ;Are we on the edge of the
                bmi SL_XDone2                   ;map (right) and going right?
                lda mapX                        ;Limit scrolling in that case
                clc
                adc #19
                cmp mapSizeX
                bcc SL_XDone2
SL_XLimit:      ldy #$00
SL_XDone2:      tya
                and #$3f
                sta SL_PrecalcX+1
                stx UF_ColorSide+1
                lda scrollY
                clc
                adc scrollSY
                tay
                bmi SL_YNeg
                cmp #$40
                bcs SL_YPos
                bcc SL_YDone

SL_YPos:        lda blockY                      ;Update block & map-coords
                eor #$01
                sta blockY
                bne SL_YPosOk2
                inc mapY
SL_YPosOk2:     inx
                inx
                inx
                bpl SL_YDone

SL_YNeg:        lda blockY                      ;Are we on the edge of map?
                bne SL_YNegOk                   ;(top)
                lda mapY
                beq SL_YLimit
SL_YNegOk:      lda blockY                      ;Update block & map-coords
                eor #$01
                sta blockY
                beq SL_YNegOk2
                dec mapY
SL_YNegOk2:     dex
                dex
                dex
                bpl SL_YDone
SL_YDone:       lda scrollSY                    ;Are we on the edge of the map
                bmi SL_YDone2                   ;(bottom) and going down? Limit
                if (SCROLLROWS & 1) = 0         ;scrolling in that case
                lda blockY
                beq SL_YDone2
                endif
                lda mapY
                clc
                adc #SCROLLROWS/2
                cmp mapSizeY
                bcc SL_YDone2
SL_YLimit:      ldy #$00
SL_YDone2:      tya
                and #$3f
                sta SL_PrecalcY+1
                cpx #$04                        ;Any screen shifting?
                beq SL_NoWork
                stx UF_ScreenShiftDir+1
                stx UF_ColorShiftDir+1
                inc scrCounter
NoScrollWork:
SL_NoWork:      rts

        ; Update frame & perform scrolling work
        ;
        ; Parameters: -
        ; Returns: -
        ; Modifies: A,X,Y

UpdateFrame:    jsr StartIrq                    ;Important to ensure IRQs, as frame update will wait for previous frame completion,
                if SHOW_SPRITESORT_TIME > 0     ;and could get stuck
                lda #$02
                sta $d020
                endif
                lda firstSortSpr                ;Switch sprite doublebuffer side
                eor #MAX_SPR
                sta firstSortSpr
                ldx #$00
                stx temp6                       ;D010 bits for first IRQ
                txa
SSpr_Loop1:     ldy sprOrder,x                  ;Check for coordinates being in order
                cmp sprY,y
                beq SSpr_NoSwap2
                bcc SSpr_NoSwap1
                stx temp1                       ;If not in order, begin insertion loop
                sty temp2
                lda sprY,y
                ldy sprOrder-1,x
                sty sprOrder,x
                dex
                beq SSpr_SwapDone1
SSpr_Swap1:     ldy sprOrder-1,x
                sty sprOrder,x
                cmp sprY,y
                bcs SSpr_SwapDone1
                dex
                bne SSpr_Swap1
SSpr_SwapDone1: ldy temp2
                sty sprOrder,x
                ldx temp1
                ldy sprOrder,x
SSpr_NoSwap1:   lda sprY,y
SSpr_NoSwap2:   inx
                cpx #MAX_SPR
                bne SSpr_Loop1
                if SHOW_SPRITESORT_TIME > 0
                lda #$00
                sta $d020
                endif
UF_Wait:        lda newFrameFlag                ;Wait until previous update is over
                beq UF_WaitDone
                bmi UF_Wait
                lda UF_ScrollWorkDoneFlag+1
                bne UF_Wait
                lda scrCounter                  ;If a colorscroll is not pending, and screen shift
                cmp #1                          ;is next, can perform it early while waiting
                bne UF_Wait
                sta UF_ScrollWorkDoneFlag+1
                if SHOW_SCREENSCROLL_TIME > 0
                dec $d020
                jsr UF_ShiftScreenEarly
                inc $d020
                else
                jsr UF_ShiftScreenEarly
                endif
                jmp UF_Wait
UF_WaitDone:    if SHOW_SPRITESORT_TIME > 0
                lda #$02
                sta $d020
                endif
                lda #<sprOrder
                sec
                sbc firstSortSpr
                sta SSpr_CopyLoop1+1
                ldy firstSortSpr
                tya
                adc #8-1                        ;C=1
                sta SSpr_CopyLoop1End+1         ;Set endpoint for first copyloop
                bpl SSpr_CopyLoop1
SSpr_CopyLoop1Skip:
                inc SSpr_CopyLoop1+1
SSpr_CopyLoop1: ldx sprOrder,y
                lda sprY,x                      ;If reach the maximum Y-coord endmark, all done
                cmp #MAX_SPRY
                bcs SSpr_CopyLoop1Done
                sta sortSprY,y
                lda sprC,x                      ;Check invisibility / flicker
                bmi SSpr_CopyLoop1Skip
                sta sortSprC,y
                lda sprF,x
                sta sortSprF,y
                lda sprX,x
                asl
                ora sprXLSB,x
                sta sortSprX,y
                bcc SSpr_CopyLoop1MsbLow
                lda temp6
                ora sprBitTbl,y
                sta temp6
SSpr_CopyLoop1MsbLow:
                iny
SSpr_CopyLoop1End:
                cpy #$00
                bcc SSpr_CopyLoop1
                lda temp6
                sta sortSprD010-1,y
                lda sortSprC-1,y                ;Make first IRQ endmark
                ora #$80
                sta sortSprC-1,y
                lda SSpr_CopyLoop1+1            ;Copy sortindex from first copyloop
                sta SSpr_CopyLoop2+1            ;to second
                bcs SSpr_CopyLoop2
SSpr_CopyLoop1Done:
                lda temp6
                sta sortSprD010-1,y
                sty temp1                       ;Store sorted sprite end index
                cpy firstSortSpr                ;Any sprites at all?
                bne SSpr_EndMark                ;Make first (and final) IRQ endmask
SSpr_NoSprites: jmp SSpr_AllDone
SSpr_CopyLoop2Skip:
                inc SSpr_CopyLoop2+1
SSpr_CopyLoop2: ldx sprOrder,y
                lda sprY,x
                cmp #MAX_SPRY
                bcs SSpr_CopyLoop2Done
                sta sortSprY,y
                sbc #21-1
                cmp sortSprY-8,y                ;Check for physical sprite overlap
                bcc SSpr_CopyLoop2Skip
                lda sprC,x                      ;Check invisibility / flicker
                bmi SSpr_CopyLoop2Skip
                sta sortSprC,y
                lda sprF,x
                sta sortSprF,y
                lda sprX,x
                asl
                ora sprXLSB,x
                sta sortSprX,y
                bcc SSpr_CopyLoop2MsbLow
                lda sortSprD010-1,y
                ora sprBitTbl,y
                bne SSpr_CopyLoop2MsbDone
SSpr_CopyLoop2MsbLow:
                lda sprBitTbl,y
                eor #$ff
                and sortSprD010-1,y
SSpr_CopyLoop2MsbDone:
                sta sortSprD010,y
                iny
                bne SSpr_CopyLoop2
SSpr_CopyLoop2Done:
                sty temp1                       ;Store sorted sprite end index
                ldy SSpr_CopyLoop1End+1         ;Go back to the second IRQ start
                cpy temp1
                beq SSpr_FinalEndMark
SSpr_IrqLoop:   sty temp2                       ;Store IRQ startindex
                lda sortSprY,y                  ;C=0 here
                sbc #21+12-1                    ;First sprite of IRQ: store the Y-coord
                sta SSpr_IrqYCmp1+1             ;compare values
                adc #21+12+6-1
                sta SSpr_IrqYCmp2+1
SSpr_IrqSprLoop:iny
                cpy temp1
                bcs SSpr_IrqDone
                lda sortSprY-8,y                ;Add next sprite to this IRQ?
SSpr_IrqYCmp1:  cmp #$00                        ;(try to add as many as possible while
                bcc SSpr_IrqSprLoop             ;avoiding glitches)
                lda sortSprY,y
SSpr_IrqYCmp2:  cmp #$00
                bcc SSpr_IrqSprLoop
SSpr_IrqDone:   tya
                sbc temp2
                tax
                lda sprIrqAdvanceTbl-1,x
                ldx temp2
                adc sortSprY,x
                sta sprIrqLine-1,x              ;Store IRQ start line (with advance)
SSpr_EndMark:   lda sortSprC-1,y                ;Make IRQ endmark
                ora #$80
                sta sortSprC-1,y
                cpy temp1                       ;Sprites left?
                bcc SSpr_IrqLoop
SSpr_FinalEndMark:
                lda #$00                        ;Make final endmark
                sta sprIrqLine-1,y
SSpr_AllDone:   tya                             ;Check which sprites are on
                sec
                sbc firstSortSpr
                cmp #$09
                bcc UF_NotMoreThan8
                lda #$08
UF_NotMoreThan8:tax
                lda d015Tbl,x
                sta Irq1_NewD015+1
                ldx firstSortSpr
                stx Irq1_NewFirstSortSpr+1
                if SHOW_SPRITESORT_TIME > 0
                lda #$00
                sta $d020
                endif
                lda scrollX
                lsr
                lsr
                lsr
                eor #$07
                ora #$10
                sta Irq1_NewScrollX+1
UF_FinalScrollY:lda #$00
                lsr
                lsr
                lsr
                eor #$07
                ora #$10
                sta Irq1_NewScrollY+1
                ldx #$ff
                cmp #$16                        ;If panel split is aligned on badline,
                beq UF_BadLine                  ;blank screen early
                inx
UF_BadLine:     stx Irq1_BadLineFlag+1
                ldy screen
                lda d018Tbl,y
                sta Irq1_NewD018+1
                lda screenBaseTbl,y
                ora #>$3f8
                sta Irq1_NewSprPtrHi+1
UF_ScrollWorkDoneFlag:
                lda #$00
                bne UF_ScrollWorkDone
                if SHOW_SCREENSCROLL_TIME > 0
                dec $d020
                jsr UF_ScrollWork
                inc $d020
                rts
                endif

UF_ScrollWork:  ldx scrCounter
                bne UF_ShiftOrColors            ;No scrollwork?
                inc newFrameFlag
                jmp DoBlockUpdates
UF_ShiftOrColors:
                dex
                beq UF_ShiftScreen              ;Shift screen?
                dex
                stx scrCounter                  ;Colorscroll & back to beginning
UF_ShiftColors:
UF_ColorSide:   lda #$00
                sta Irq4_ColorSide+1
                lda screenBaseTbl,y
                ora #>(SCROLLSPLIT*40)
                sta DrawColorsRLoop+2
                sta DrawColorsRLdx2+2
                sta DrawColorsRLdx3+2
UF_ColorShiftDir:
                ldx #$00
                lda colorJumpTblLo,x
                sta Irq4_ColorJump+1
                lda colorJumpTblHi,x
                sta Irq4_ColorJump+2
                lda #$81                        ;New frame + colorscroll in IRQ
                sta newFrameFlag
                rts

UF_ScrollWorkDone:
                dec UF_ScrollWorkDoneFlag+1     ;Can only have value 1, if we are here, change back to 0
                inc newFrameFlag                ;Trigger update
                rts

UF_ShiftScreen:
                inc newFrameFlag                ;Trigger update
UF_ShiftScreenEarly:
                jsr DoBlockUpdates              ;Block updates before screen shift
UF_ScreenShiftDir:
                ldx #$00
                lda drawJumpTblLo,x
                sta SS1_Done+1
                sta SS2_Done+1
                lda drawJumpTblHi,x
                sta SS1_Done+2
                sta SS2_Done+2
                lda shiftSrcTbl,x
                sta UF_ShiftSrc+1
                lda shiftEndTbl,x
                sta SS1_EndCmp+1
                sta SS2_EndCmp+1
                lda screen
                cmp #$01
UF_LoopOffset:  lda shiftLoopOffsetTbl,x
UF_ShiftDest:   ldy shiftDestTbl,x
UF_ShiftSrc:    ldx #$00
                bcs UF_ShiftScreen2
                adc #<SS1_Loop
                sta SS1_Jump+1
                lda #>SS1_Loop
                adc #$00
                sta SS1_Jump+2
                jmp SS1_Jump
UF_ShiftScreen2:clc
                adc #<SS2_Loop
                sta SS2_Jump+1
                lda #>SS2_Loop
                adc #$00
                sta SS2_Jump+2
                jmp SS2_Jump

        ; Screen shifting routines

SS1_Loop:
N               set 0
                repeat SCROLLROWS
                lda screen1+N*40-40,x
                sta screen2+N*40-40,y
N               set N+1
                repend
                iny
                inx
SS1_EndCmp:     cpx #$00
                bcs SS1_Done
SS1_Jump:       jmp SS1_Loop
SS1_Done:       jmp DrawUp

SS2_Loop:
N               set 0
                repeat SCROLLROWS
                lda screen2+N*40-40,x
                sta screen1+N*40-40,y
N               set N+1
                repend
                iny
                inx
SS2_EndCmp:     cpx #$00
                bcs SS2_Done
SS2_Jump:       jmp SS2_Loop
SS2_Done:       jmp DrawUp

        ; Color scrolling routines

ScrollColorsUp:
                lda colorYTbl-3,x
                sta ScrollColorsUpTopIny
                sta ScrollColorsUpBottomIny
                lda colorXTbl-3,x
                sta ScrollColorsUpTopInx
                sta ScrollColorsUpBottomInx
                lda colorEndTbl-3,x
                sta ScrollColorsUpTopCpx+1
                sta ScrollColorsUpBottomCpx+1
                ldy colorDestTbl-3,x
                lda colorSrcTbl-3,x
                tax
ScrollColorsUpTopLoop:
N               set SCROLLSPLIT-1
                repeat SCROLLSPLIT
                lda colors+N*40,x
                sta colors+40+N*40,y
N               set N-1
                repend
                lda vColBuf,y
                sta colors,y
ScrollColorsUpTopIny:
                iny
ScrollColorsUpTopInx:
                inx
ScrollColorsUpTopCpx:
                cpx #$00
                bne ScrollColorsUpTopLoop
                ldx irqTemp
                ldy colorSideTbl-3,x
                bmi DrawColorsUpTopSkip
                jsr DrawColorsHorizTop
DrawColorsUpTopSkip:
                ldx irqTemp
                ldy colorDestTbl-3,x
                lda colorSrcTbl-3,x
                tax
ScrollColorsUpBottomLoop:
N               set SCROLLROWS-2
                repeat SCROLLROWS-SCROLLSPLIT-2
                lda colors+N*40,x
                sta colors+40+N*40,y
N               set N-1
                repend
ScrollColorsUpBottomIny:
                iny
ScrollColorsUpBottomInx:
                inx
ScrollColorsUpBottomCpx:
                cpx #$00
                bne ScrollColorsUpBottomLoop
                ldy #12                         ;Reconstruct the colors that are lost at
DrawColorsRLoop:                                ;the scroll split
                ldx screen1+SCROLLSPLIT*40+40,y
                lda charColors,x
                sta colors+SCROLLSPLIT*40+40,y
DrawColorsRLdx2:
                ldx screen1+SCROLLSPLIT*40+40+13,y
                lda charColors,x
                sta colors+SCROLLSPLIT*40+40+13,y
DrawColorsRLdx3:
                ldx screen1+SCROLLSPLIT*40+40+26,y
                lda charColors,x
                sta colors+SCROLLSPLIT*40+40+26,y
                dey
                bpl DrawColorsRLoop
                ldx irqTemp
                ldy colorSideTbl-3,x
                bmi ScrollColorsUpBottomSkip
DrawColorsHorizBottom:
                clc
                lda screen
                bne DCHB2
DCHB1:          ldx screen1+SCROLLSPLIT*40,y
                lda charColors,x
                sta colors+SCROLLSPLIT*40,y
                ldx screen1+SCROLLSPLIT*40+5*40,y
                lda charColors,x
                sta colors+SCROLLSPLIT*40+5*40,y
                tya
                adc #40
                tay
                cpy #5*40
                bcc DCHB1
                if SCROLLROWS > 21 || (SCROLLROWS = 21 && SCROLLSPLIT = 10)
                ldx screen1+SCROLLSPLIT*40+5*40,y
                lda charColors,x
                sta colors+SCROLLSPLIT*40+5*40,y
                endif
ScrollColorsUpBottomSkip:
                rts
DCHB2:          ldx screen2+SCROLLSPLIT*40,y
                lda charColors,x
                sta colors+SCROLLSPLIT*40,y
                ldx screen2+SCROLLSPLIT*40+5*40,y
                lda charColors,x
                sta colors+SCROLLSPLIT*40+5*40,y
                tya
                adc #40
                tay
                cpy #5*40
                bcc DCHB2
                if SCROLLROWS > 21 || (SCROLLROWS = 21 && SCROLLSPLIT = 10)
                ldx screen2+SCROLLSPLIT*40+5*40,y
                lda charColors,x
                sta colors+SCROLLSPLIT*40+5*40,y
                endif
                rts

ScrollColorsHoriz:
                lda colorYTbl-3,x
                sta ScrollColorsHorizTopIny
                sta ScrollColorsHorizBottomIny
                lda colorXTbl-3,x
                sta ScrollColorsHorizTopInx
                sta ScrollColorsHorizBottomInx
                lda colorEndTbl-3,x
                sta ScrollColorsHorizTopCpx+1
                sta ScrollColorsHorizBottomCpx+1
                ldy colorDestTbl-3,x
                lda colorSrcTbl-3,x
                tax
ScrollColorsHorizTopLoop:
N               set 0
                repeat SCROLLSPLIT
                lda colors+N*40,x
                sta colors+N*40,y
N               set N+1
                repend
ScrollColorsHorizTopIny:
                iny
ScrollColorsHorizTopInx:
                inx
ScrollColorsHorizTopCpx:
                cpx #$00
                bne ScrollColorsHorizTopLoop
                ldx irqTemp
                ldy colorSideTbl-3,x
                bmi ScrollColorsHorizTopSkip
                jsr DrawColorsHorizTop
ScrollColorsHorizTopSkip:
                ldx irqTemp
                ldy colorDestTbl-3,x
                lda colorSrcTbl-3,x
                tax
ScrollColorsHorizBottomLoop:
N               set SCROLLSPLIT
                repeat SCROLLROWS-SCROLLSPLIT
                lda colors+N*40,x
                sta colors+N*40,y
N               set N+1
                repend
ScrollColorsHorizBottomIny:
                iny
ScrollColorsHorizBottomInx:
                inx
ScrollColorsHorizBottomCpx:
                cpx #$00
                bne ScrollColorsHorizBottomLoop
                ldx irqTemp
                ldy colorSideTbl-3,x
                bmi ScrollColorsHorizBottomSkip
                jmp DrawColorsHorizBottom
ScrollColorsHorizBottomSkip:
                rts

ScrollColorsDown:
                lda colorYTbl-3,x
                sta ScrollColorsDownTopIny
                sta ScrollColorsDownBottomIny
                lda colorXTbl-3,x
                sta ScrollColorsDownTopInx
                sta ScrollColorsDownBottomInx
                lda colorEndTbl-3,x
                sta ScrollColorsDownTopCpx+1
                sta ScrollColorsDownBottomCpx+1
                ldy colorDestTbl-3,x
                lda colorSrcTbl-3,x
                tax
ScrollColorsDownTopLoop:
N               set 0
                repeat SCROLLSPLIT
                lda colors+40+N*40,x
                sta colors+N*40,y
N               set N+1
                repend
ScrollColorsDownTopIny:
                iny
ScrollColorsDownTopInx:
                inx
ScrollColorsDownTopCpx:
                cpx #$00
                bne ScrollColorsDownTopLoop
                ldx irqTemp
                ldy colorSideTbl-3,x
                bmi ScrollColorsDownTopSkip
                jsr DrawColorsHorizTop
ScrollColorsDownTopSkip:
                ldx irqTemp
                ldy colorDestTbl-3,x
                lda colorSrcTbl-3,x
                tax
ScrollColorsDownBottomLoop:
N               set SCROLLSPLIT
                repeat SCROLLROWS-SCROLLSPLIT-1
                lda colors+40+N*40,x
                sta colors+N*40,y
N               set N+1
                repend
                lda vColBuf,y
                sta colors+SCROLLROWS*40-40,y
ScrollColorsDownBottomIny:
                iny
ScrollColorsDownBottomInx:
                inx
ScrollColorsDownBottomCpx:
                cpx #$00
                bne ScrollColorsDownBottomLoop
                ldx irqTemp
                ldy colorSideTbl-3,x
                bmi ScrollColorsDownBottomSkip
                jsr DrawColorsHorizBottom
ScrollColorsDownBottomSkip:
DCHT_Skip:      rts

DrawColorsHorizTop:
                clc
                lda screen
                beq DCHT1
                jmp DCHT2
DCHT1:          ldx screen1,y
                lda charColors,x
                sta colors,y
                ldx screen1+5*40,y
                lda charColors,x
                sta colors+5*40,y
                tya
                adc #40
                tay
                cpy #5*40
                bcc DCHT1
                if SCROLLSPLIT = 11
                ldx screen1+5*40,y
                lda charColors,x
                sta colors+5*40,y
                endif
                rts
DCHT2:          ldx screen2,y
                lda charColors,x
                sta colors,y
                ldx screen2+5*40,y
                lda charColors,x
                sta colors+5*40,y
                tya
                adc #40
                tay
                cpy #5*40
                bcc DCHT2
                if SCROLLSPLIT = 11
                ldx screen2+5*40,y
                lda charColors,x
                sta colors+5*40,y
                endif
                rts


        ; New block drawing routines

DrawUpLeft:     jsr DrawLeft
DrawUp:         lda #$00
                sta temp1
                ldy screen
                lda screenBaseTbl+1,y
                sta temp2
                if (SCROLLROWS & 1) = 0
                lda blockY
                sta DV_BlockY+1
                endif
                ldy mapY
                jmp DrawVertical

DrawDownRight:  jsr DrawRight
DrawDown:       lda #<(SCROLLROWS*40-40)
                sta temp1
                ldy screen
                lda screenBaseTbl+1,y
                ora #>(SCROLLROWS*40-40)
                sta temp2
                if (SCROLLROWS & 1) = 0
                lda blockY
                lsr
                lda blockY
                eor #$01
                sta DV_BlockY+1
                else
                clc
                endif
                lda mapY
                adc #(SCROLLROWS-1)/2
                tay
DrawVertical:   lda mapTblLo,y
                clc
                adc mapX
                sta DV_GetBlock+1
                sta DV_GetBlock2+1
                lda mapTblHi,y
                adc #$00
                sta DV_GetBlock+2
                sta DV_GetBlock2+2
                if (SCROLLROWS & 1) = 0
DV_BlockY:      lda #$00
                else
                lda blockY
                endif
                beq DV_TopSide
                ldx #>blkBL
                ldy #>blkBR
                bne DV_Begin
DV_TopSide:     ldx #>blkTL
                ldy #>blkTR
DV_Begin:       stx DV_BlockL+2
                sty DV_BlockR+2
                ldy #$00
                lda blockX
                beq DV_GetBlock2
DV_GetBlock:    ldx $1000
                inc DV_GetBlock2+1
                bne DV_Loop
                inc DV_GetBlock2+2
DV_Loop:
DV_BlockR:      lda blkTR,x
                sta (temp1),y
                sta DV_CharNumR+1
DV_CharNumR:    lda charColors
                sta vColBuf,y
                iny
                ;cpy #39
                ;beq DV_Done
DV_GetBlock2:   ldx $1000
                inc DV_GetBlock2+1
                bne DV_BlockL
                inc DV_GetBlock2+2
DV_BlockL:      lda blkTL,x
                sta (temp1),y
                sta DV_CharNumL+1
DV_CharNumL:    lda charColors
                sta vColBuf,y
                iny
                cpy #39
                bcc DV_Loop
DV_Done:        rts

DrawDownLeft:   jsr DrawDown
DrawLeft:       ldx #0
                lda #0
                beq DrawHorizontal

DrawUpRight:    jsr DrawUp
DrawRight:      ldx #38
                lda #19

DrawHorizontal: stx temp1
                ldy screen
                ldx screenBaseTbl+1,y
                stx temp2
DrawHorizontal_CustomDest:
                ldy mapY
                clc
                adc mapX
                adc mapTblLo,y
                sta DH_GetBlock+1
                sta DH_GetBlock2+1
                lda mapTblHi,y
                adc #$00
                sta DH_GetBlock+2
                sta DH_GetBlock2+2
                lda blockX
                beq DH_LeftSide
                ldx #>blkTR
                ldy #>blkBR
                bne DH_Begin
DH_LeftSide:    ldx #>blkTL
                ldy #>blkBL
DH_Begin:       stx DH_BlockT+2
                sty DH_BlockB+2
                ldy #$00
                lda blockY
                beq DH_GetBlock2
DH_GetBlock:    ldx $1000
                lda DH_GetBlock2+1
                clc
                adc mapSizeX
                sta DH_GetBlock2+1
                bcc DH_Loop
                inc DH_GetBlock2+2
DH_Loop:
DH_BlockB:      lda blkBL,x
                sta (temp1),y
                cpy #<(SCROLLROWS*40-40)
                beq DH_Done
                tya
                clc
                adc #40
                tay
                bcc DH_GetBlock2
                inc temp2
DH_GetBlock2:   ldx $1000
                lda DH_GetBlock2+1
                clc
                adc mapSizeX
                sta DH_GetBlock2+1
                bcc DH_BlockT
                inc DH_GetBlock2+2
DH_BlockT:      lda blkTL,x
                sta (temp1),y
                cpy #<(SCROLLROWS*40-40)
                beq DH_Done
                tya
                clc
                adc #40
                tay
                bcc DH_Loop
                inc temp2
                bcs DH_Loop
DH_Done:        rts

        ; Redraw gamescreen
        ;
        ; Parameters: -
        ; Returns: -
        ; Modifies: A,X,Y,temp regs

RedrawScreen:   jsr BlankScreen
                sta screen                      ;Returns with A=0
                sta temp6
                tay
                lda #>screen1
                sta RS_DestHi+1
RS_Loop:        sty temp1
RS_DestHi:      lda #$00
                sta temp2
                lda temp6
                jsr DrawHorizontal_CustomDest
                ldy temp1
                jsr DrawColorsHorizTop
                ldy temp1
                jsr DrawColorsHorizBottom
                ldx blockX
                beq RS_NotOver
                ldx #$ff                        ;Becomes 0 below
                inc temp6
RS_NotOver:     inx
                stx blockX
                ldy temp1
                iny
                cpy #40
                bcc RS_Loop
                jsr SetZoneColors

        ; Reset scrolling
        ;
        ; Parameters: -
        ; Returns: A=0
        ; Modifies: A

InitScroll:     lda #$00
                sta scrollSX
                sta scrollSY
                sta scrCounter
                sta flashScreen
                sta shakeScreen
                sta blockUpdates
                rts

        ; Update a block on the map. Will queue for later to make sure the screen isn't corrupted during scrolling
        ;
        ; Parameters: A new block, Y horizontal map coordinate, X vertical map coordinate
        ; Returns: -
        ; Modifies: A,zpDestLo-zpDestHi

UpdateBlock:    pha
                lda mapTblLo,x
                sta zpDestLo
                lda mapTblHi,x
                sta zpDestHi
                pla
                sta (zpDestLo),y
                stx zpDestLo
                ldx blockUpdates
                cpx #MAX_BLOCKUPDATES
                bcs UB_BufferFull
                sta blkUpdB,x
                tya
                sta blkUpdX,x
                lda zpDestLo
                sta blkUpdY,x
                inc blockUpdates
UB_BufferFull:  ldx zpDestLo
DBU_AllDone:    rts

        ; Actually perform block updates. Called by ScrollLogic
        ;
        ; Parameters: -
        ; Returns: -
        ; Modifies: A,X,Y,temp vars, loader temp vars

DoBlockUpdates: ldx blockUpdates
                lda #$00
                sta blockUpdates                ;Reset buffer
DBU_Next:       dex
                bmi DBU_AllDone
                lda #$00
                sta zpBitBuf                    ;Clip flags left/top
                sta zpLenLo
                lda blkUpdB,x                   ;Block number to draw
                sta temp2
                lda blkUpdX,x
                sec
DBU_MapX:       sbc #$00
                bcc DBU_Next
                bmi DBU_Next
                asl
                sec
DBU_BlockX:     sbc #$00
                bcs DBU_NoLeftHalfClip
                lda #$00
                dec zpBitBuf
DBU_NoLeftHalfClip:
                cmp #39
                bcs DBU_Next
                sta zpSrcLo
                lda blkUpdY,x
                sec
DBU_MapY:       sbc #$00
                bcc DBU_Next
                bmi DBU_Next
                asl
                sec
DBU_BlockY:     sbc #$00
                bcs DBU_NoTopEdgeClip
                lda #$00
                dec zpLenLo
DBU_NoTopEdgeClip:
                cmp #SCROLLROWS
                bcs DBU_Next
                stx temp1
                tay
                sty zpSrcHi
                ldx zpSrcLo
                lda screen
                sta GRCA_Screen+1
                jsr GetRowColAddress                ;Returns with Y=0
                sty GRCA_Screen+1                   ;Restore GetRowColAddress operation to screen1
                lda zpLenLo
                bmi DBU_SkipTopEdge
                lda zpBitBuf
                bmi DBU_SkipLeftEdge
                ldx temp2
                lda blkTL,x
                sta (zpDestLo),y
                tax
                lda charColors,x
                sta (zpBitsLo),y
                iny
DBU_SkipLeftEdge:
                ldx temp2
                lda blkTR,x
                sta (zpDestLo),y
                tax
                lda charColors,x
                sta (zpBitsLo),y
                lda zpSrcHi
                cmp #SCROLLROWS-1
                bcs DBU_SkipBottomEdge
                ldy #40
DBU_SkipTopEdge:lda zpBitBuf
                bmi DBU_SkipLeftEdge2
                ldx temp2
                lda blkBL,x
                sta (zpDestLo),y
                tax
                lda charColors,x
                sta (zpBitsLo),y
                iny
DBU_SkipLeftEdge2:
                ldx temp2
                lda blkBR,x
                sta (zpDestLo),y
                tax
                lda charColors,x
                sta (zpBitsLo),y
DBU_SkipBottomEdge:
                ldx temp1
                jmp DBU_Next
