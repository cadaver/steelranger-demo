;-------------------------------------------------------------------------------
; Get key
;-------------------------------------------------------------------------------

getkey:         lda fastup
                bne gk_fastup
                lda fastdown
                bne gk_fastdown
gk_delay:       jsr getin
gk_ok:          sta key
                pha
                cmp #"0"
                bcc gk_hnotnum
                cmp #"9"+1
                bcs gk_hnotnum
                sbc #"0"-1
                bcs gk_done
gk_hnotnum:     cmp #"A"
                bcc gk_hnotalpha
                cmp #"F"+1
                bcs gk_hnotalpha
                sbc #"A"-11
                bcs gk_done
gk_hnotalpha:   lda #$ff
gk_done:        sta hexdigit
                pla
                rts

;-------------------------------------------------------------------------------
; Fast movement up/down
;-------------------------------------------------------------------------------

gk_fastup:      dec fastup
                lda #KEY_UP
                bne gk_ok
gk_fastdown:    dec fastdown
                lda #KEY_DOWN
                bne gk_ok

;-------------------------------------------------------------------------------
; Hex editing of databyte
; destlo,desthi=address
; x=nybble (0=high, 1=low)
; c=1 if successful, 0 if no valid hex key entered
;-------------------------------------------------------------------------------

hexedit:        ldy #$00
                lda hexdigit
                cmp #$10
                bcc heok
                clc
                rts
heok:           cpx #$00
                beq hehigh
helow:          sta hedata+1
                lda #$f0
hecommon:       and (destlo),y
hedata:         ora #$00
                sta (destlo),y
                sec
                rts
hehigh:         asl
                asl
                asl
                asl
                sta hedata+1
                lda #$0f
                bne hecommon
