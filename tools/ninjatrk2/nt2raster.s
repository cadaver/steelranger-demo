;-------------------------------------------------------------------------------
; Init raster-interrupts
;-------------------------------------------------------------------------------

initraster:     sei
                lda #$7f
                sta $dc0d
                lda #$01
                sta $d01a
                lda #<raster
                sta $0314
                lda #>raster
                sta $0315
                lda $d011
                and #$7f
                sta $d011
                lda #RASTERPOS
                sta $d012
                lda $dc0d
                lda $d019
                sta $d019
                cli
                rts

;-------------------------------------------------------------------------------
; Raster interrupt routine
;-------------------------------------------------------------------------------

ras_nomusic:    sta curraster
                lda bgcol
                sta $d020
                jsr nt_play
                lda #$fe
                sta nt_chncounter
                sta nt_chncounter+7
                sta nt_chncounter+14
                lda #$01
                sta nt_chnpattpos
                sta nt_chnpattpos+7
                sta nt_chnpattpos+14
                jmp ras_nosec

raster:         cld
                lda playflag
                beq ras_nomusic
                nop
                lda normalcol
                jsr nt_playd020
                lda $d012
                ldx bgcol
                stx $d020
                sec
                sbc #RASTERPOS
                sta curraster
                lda curraster
                cmp maxraster
                bcc ras_notmax
                sta maxraster
ras_notmax:     lda maxraster                   ;Raster-meter bugs sometimes..
                cmp #$18                        ;(loading/saving etc.)
                bcc ras_meterok
                lda #$00
                sta curraster
                sta maxraster
ras_meterok:    inc timeframe
                lda fastfwd
                beq ras_nofast
                jsr nt_play
                jsr nt_play
                jsr nt_play
                jsr nt_play
                lda timeframe
                clc
                adc #$04
                sta timeframe
ras_nofast:     lda timeframe
                cmp timeframefull
                bcc ras_nosec
                sbc timeframefull
                sta timeframe
                lda timesec
                clc
                adc #$01
                cmp #60
                bcc ras_nomin
                lda #$00
                pha
                lda timemin
                adc #$00
                cmp #60
                bcc ras_nohour
                lda #$00
ras_nohour:     sta timemin
                pla
ras_nomin:      sta timesec
ras_nosec:      inc cursorcol
                lda cursorcol
                lsr
                lsr
                and #$07
                tax
                lda cursorcoltbl,x
                sta $d027
                lda $d011
                and #$7f
                sta $d011
                lda #RASTERPOS
                sta $d012
                jsr scnkey
                lda kount
                cmp #MAX_KEYREPEAT
                bcc ras_repeatok
                lda #MAX_KEYREPEAT
                sta kount
ras_repeatok:   lda delay
                cmp #MAX_KEYDELAY
                bcc ras_delayok
                lda #MAX_KEYDELAY
                sta delay
ras_delayok:    dec $d019
                jmp $ea81

