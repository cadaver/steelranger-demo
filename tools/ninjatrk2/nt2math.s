;-------------------------------------------------------------------------------
; Add value to src/dest pointers or 16bit accumulator
;-------------------------------------------------------------------------------

adddest:        clc
                adc destlo
                sta destlo
                lda desthi
                adc #$00
                sta desthi
                rts

addsrc:         clc
                adc srclo
                sta srclo
                lda srchi
                adc #$00
                sta srchi
                rts

add16:          clc
                adc alo
                sta alo
                lda ahi
                adc #$00
                sta ahi
                rts

;-------------------------------------------------------------------------------
; Unsigned multiply
; A,Y=Values to be multiplied
; alo,ahi=16bit result
;-------------------------------------------------------------------------------

mulu:           sta alo
                tya
                beq mulu_zero
                dey
                sty ahi
                ldy #$07
                lda #$00
                lsr alo
                bcc mulu_shift1
                adc ahi
mulu_shift1:    ror
                ror alo
                bcc mulu_shift2
                adc ahi
mulu_shift2:    dey
                bne mulu_shift1
mulu_shift8:    ror
                sta ahi
                ror alo
                rts
mulu_zero:      sta alo
                sta ahi
                rts

;-------------------------------------------------------------------------------
; Unsigned divide
; A=Value to be divided
; Y=divisor
; alo=result
; A=remainder
;-------------------------------------------------------------------------------

divu:           sta alo
                tya
                sta ahi
                lda #$00
                asl alo
                ldy #$07
divu_loop:      rol
                cmp ahi
                bcc divu_skip
                sbc ahi
divu_skip:      rol alo
                dey
                bpl divu_loop
                rts

