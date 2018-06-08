;-------------------------------------------------------------------------------
; Playroutine
;-------------------------------------------------------------------------------

                org ((* + $ff) & $ff00)

nt_playd020:    sta $d020
nt_play:        ldx #$00
nt_initsongnum: lda #$00
                bmi nt_filtpos

        ;New song initialization

                asl
                asl
                adc nt_initsongnum+1
                tay
                lda nt_songtbl,y
                sta nt_tracklo+1
                lda nt_songtbl+1,y
                sta nt_trackhi+1
                txa
                sta nt_filtpos+1
                sta $d417
                ldx #21
nt_initloop:    sta nt_chnpattpos-1,x
                dex
                bne nt_initloop
                jsr nt_initchn
                ldx #$07
                jsr nt_initchn
                ldx #$0e
nt_initchn:     lda nt_songtbl+2,y
                sta nt_chnsongpos,x
                iny
                lda #$ff
                sta nt_chnnewnote,x
                sta nt_chnduration,x
nt_resettrans:  sta nt_chntrans,x
                sta nt_initsongnum+1
                rts

          ;Filter execution

nt_filtpos:     ldy #$00
                beq nt_filtdone
                lda nt_filttimetbl-1,y
                bpl nt_filtmod
                cmp #$ff
                bcs nt_filtjump
nt_setfilt:     sta $d417
                and #$70
                sta nt_filtdone+1
nt_filtjump:    lda nt_filtspdtbl-1,y
                bcs nt_filtjump2
nt_nextfilt:    inc nt_filtpos+1
                bcc nt_storecutoff
nt_filtjump2:   sta nt_filtpos+1
                bcs nt_filtdone
nt_filtmod:     clc
                dec nt_filttime
                bmi nt_newfiltmod
                bne nt_filtcutoff
                inc nt_filtpos+1
                bcc nt_filtdone
nt_newfiltmod:  sta nt_filttime
nt_filtcutoff:  lda #$00
                adc nt_filtspdtbl-1,y
nt_storecutoff: sta nt_filtcutoff+1
                sta $d416
nt_filtdone:    lda #$00
                ora #$0f
                sta $d418

        ;Channel execution

                jsr nt_chnexec
                ldx #$07
                jsr nt_chnexec
                ldx #$0e

        ;Update duration counter

nt_chnexec:     inc nt_chncounter,x
                bne nt_nopattern

        ;Get data from pattern

nt_pattern:     ldy nt_chnpattnum,x
                lda nt_patttbllo-1,y
                sta nt_temp1
                lda nt_patttblhi-1,y
                sta nt_temp2
                ldy nt_chnpattpos,x
                lda (nt_temp1),y
                lsr
                sta nt_chnnewnote,x
                bcc nt_nonewcmd
nt_newcmd:      iny
                lda (nt_temp1),y
                sta nt_chncmd,x
                bcc nt_rest
nt_checkhr:     bmi nt_rest
                lda #$fe
                sta nt_chngate,x
                sta $d405,x
nt_hrparam:     lda #$00
                sta $d406,x
nt_rest:        iny
                lda (nt_temp1),y
                cmp #$c0
                bcc nt_nonewdur
                iny
                sta nt_chnduration,x
nt_nonewdur:    lda (nt_temp1),y
                beq nt_endpatt
                tya
nt_endpatt:     sta nt_chnpattpos,x
                jmp nt_waveexec

        ;No new command, or gate control

nt_nonewcmd:    cmp #FIRSTNOTE/2
                bcc nt_gatectrl
                lda nt_chncmd,x
                bcs nt_checkhr
nt_gatectrl:    lsr
                ora #$fe
                sta nt_chngate,x
                bcc nt_newcmd
                sta nt_chnnewnote,x
                bcs nt_rest

        ;No new pattern data

nt_legatocmd:   tya
                and #$7f
                tay
                bpl nt_skipadsr

nt_jumptopulse: jmp nt_pulseexec
nt_nopattern:   lda nt_chncounter,x
                cmp #$02
                bne nt_jumptopulse

        ;Reload counter and check for new note / command exec / track access

nt_reload:      lda nt_chnduration,x
                sta nt_chncounter,x
                lda nt_chnnewnote,x
                bpl nt_newnoteinit
                lda nt_chnpattpos,x
                bne nt_jumptopulse

         ;Get data from track

nt_track:
nt_tracklo:     lda #$00
                sta nt_temp1
nt_trackhi:     lda #$00
                sta nt_temp2
                ldy nt_chnsongpos,x
                lda (nt_temp1),y
                bne nt_nosongjump
                iny
                lda (nt_temp1),y
                tay
                lda (nt_temp1),y
nt_nosongjump:  bpl nt_nosongtrans
                sta nt_chntrans,x
                iny
                lda (nt_temp1),y
nt_nosongtrans: sta nt_chnpattnum,x
                iny
                tya
                sta nt_chnsongpos,x
                bcc nt_cmdexecuted
                jmp nt_waveexec

        ;New note init / command exec

nt_newnoteinit: cmp #FIRSTNOTE/2
                bcc nt_skipnote
                adc nt_chntrans,x
                asl
                sta nt_chnnote,x
                sec
nt_skipnote:    ldy nt_chncmd,x
                bmi nt_legatocmd
                lda nt_cmdad-1,y
                sta $d405,x
                lda nt_cmdsr-1,y
                sta $d406,x
                bcc nt_skipgate
                lda #$ff
                sta nt_chngate,x
nt_firstwave:   lda #$09
                sta $d404,x
nt_skipgate:
nt_skipadsr:    lda nt_cmdwavepos-1,y
                beq nt_skipwave
                sta nt_chnwavepos,x
                lda #$00
                sta nt_chnwavetime,x
nt_skipwave:    lda nt_cmdpulsepos-1,y
                beq nt_skippulse
                sta nt_chnpulsepos,x
                lda #$00
                sta nt_chnpulsetime,x
nt_skippulse:   lda nt_cmdfiltpos-1,y
                beq nt_skipfilt
                sta nt_filtpos+1
                lda #$00
                sta nt_filttime
nt_skipfilt:    clc
                lda nt_chnpattpos,x
                beq nt_track
nt_cmdexecuted:
nt_notrack:     rts

        ;Pulse execution

nt_nopulsemod:  cmp #$ff
                lda nt_pulsespdtbl-1,y
                bcs nt_pulsejump
                inc nt_chnpulsepos,x
                bcc nt_storepulse
nt_pulsejump:   sta nt_chnpulsepos,x
                bcs nt_pulsedone
nt_pulseexec:   ldy nt_chnpulsepos,x
                beq nt_pulsedone
                lda nt_pulsetimetbl-1,y
                bmi nt_nopulsemod
nt_pulsemod:    clc
                dec nt_chnpulsetime,x
                bmi nt_newpulsemod
                bne nt_nonewpulsemod
                inc nt_chnpulsepos,x
                bcc nt_pulsedone
nt_newpulsemod: sta nt_chnpulsetime,x
nt_nonewpulsemod:
                lda nt_chnpulse,x
                adc nt_pulsespdtbl-1,y
                adc #$00
nt_storepulse:  sta nt_chnpulse,x
                sta $d402,x
                sta $d403,x
nt_pulsedone:

        ;Wavetable execution

nt_waveexec:    ldy nt_chnwavepos,x
                beq nt_wavedone
                lda nt_wavetbl-1,y
                cmp #$c0
                bcs nt_slideorvib
                cmp #$90
                bcc nt_wavechange

        ;Delayed wavetable

nt_wavedelay:   beq nt_nowavechange
                dec nt_chnwavetime,x
                beq nt_nowavechange
                bpl nt_wavedone
                sbc #$90
                sta nt_chnwavetime,x
                bcs nt_wavedone

        ;Wave change + arpeggio

nt_wavechange:  sta nt_chnwave,x
                tya
                sta nt_chnwaveold,x
nt_nowavechange:lda nt_wavetbl,y
                cmp #$ff
                bcs nt_wavejump
nt_nowavejump:  inc nt_chnwavepos,x
                bcc nt_wavejumpdone
nt_wavejump:    lda nt_notetbl,y
                sta nt_chnwavepos,x
nt_wavejumpdone:lda nt_notetbl-1,y
                asl
                bcs nt_absfreq
                adc nt_chnnote,x
nt_absfreq:     tay
                bne nt_notenum
nt_slidedone:   ldy nt_chnnote,x
                lda nt_chnwaveold,x
                sta nt_chnwavepos,x
nt_notenum:     lda nt_freqtbl-24,y
                sta nt_chnfreqlo,x
                sta $d400,x
                lda nt_freqtbl-23,y
nt_storefreqhi: sta $d401,x
                sta nt_chnfreqhi,x
nt_wavedone:    lda nt_chnwave,x
                and nt_chngate,x
                sta $d404,x
                rts

        ;Slide or vibrato

nt_slideorvib:  sbc #$e0
                sta nt_temp1
                lda nt_chncounter,x
                beq nt_wavedone
                lda nt_notetbl-1,y
                sta nt_temp2
                bcc nt_vibrato

        ;Slide (toneportamento)

nt_slide:       ldy nt_chnnote,x
                lda nt_chnfreqlo,x
                sbc nt_freqtbl-24,y
                pha
                lda nt_chnfreqhi,x
                sbc nt_freqtbl-23,y
                tay
                pla
                bcs nt_slidedown
nt_slideup:     adc nt_temp2
                tya
                adc nt_temp1
                bcs nt_slidedone
nt_freqadd:     lda nt_chnfreqlo,x
                adc nt_temp2
                sta nt_chnfreqlo,x
                sta $d400,x
                lda nt_chnfreqhi,x
                adc nt_temp1
                jmp nt_storefreqhi
nt_slidedown:   sbc nt_temp2
                tya
                sbc nt_temp1
                bcc nt_slidedone
nt_freqsub:     lda nt_chnfreqlo,x
                sbc nt_temp2
                sta nt_chnfreqlo,x
                sta $d400,x
                lda nt_chnfreqhi,x
                sbc nt_temp1
                jmp nt_storefreqhi

          ;Vibrato

nt_vibrato:     lda nt_chnwavetime,x
                bpl nt_vibnodir
                cmp nt_temp1
                bcs nt_vibnodir2
                eor #$ff
nt_vibnodir:    sec
nt_vibnodir2:   sbc #$02
                sta nt_chnwavetime,x
                lsr
                lda #$00
                sta nt_temp1
                bcc nt_freqadd
                bcs nt_freqsub

nt_freqtbl:     dc.w $022d,$024e,$0271,$0296,$02be,$02e8,$0314,$0343,$0374,$03a9,$03e1,$041c
                dc.w $045a,$049c,$04e2,$052d,$057c,$05cf,$0628,$0685,$06e8,$0752,$07c1,$0837
                dc.w $08b4,$0939,$09c5,$0a5a,$0af7,$0b9e,$0c4f,$0d0a,$0dd1,$0ea3,$0f82,$106e
                dc.w $1168,$1271,$138a,$14b3,$15ee,$173c,$189e,$1a15,$1ba2,$1d46,$1f04,$20dc
                dc.w $22d0,$24e2,$2714,$2967,$2bdd,$2e79,$313c,$3429,$3744,$3a8d,$3e08,$41b8
                dc.w $45a1,$49c5,$4e28,$52cd,$57ba,$5cf1,$6278,$6853,$6e87,$751a,$7c10,$8371
                dc.w $8b42,$9389,$9c4f,$a59b,$af74,$b9e2,$c4f0,$d0a6,$dd0e,$ea33,$f820,$ffff

nt_chnpattpos:  dc.b 0
nt_chncounter:  dc.b 0
nt_chnnewnote:  dc.b 0
nt_chnwavepos:  dc.b 0
nt_chnpulsepos: dc.b 0
nt_chnwave:     dc.b 0
nt_chnwaveold:  dc.b 0

                dc.b 0,0,0,0,0,0,0
                dc.b 0,0,0,0,0,0,0

nt_chngate:     dc.b $fe
nt_chntrans:    dc.b $ff
nt_chncmd:      dc.b $01
nt_chnsongpos:  dc.b 0
nt_chnpattnum:  dc.b 0
nt_chnduration: dc.b 0
nt_chnnote:     dc.b 0

                dc.b $fe,$ff,$01,0,0,0,0
                dc.b $fe,$ff,$01,0,0,0,0

nt_chnfreqlo:   dc.b 0
nt_chnfreqhi:   dc.b 0
nt_chnpulse:    dc.b 0
nt_chnwavetime: dc.b 0
nt_chnpulsetime:dc.b 0
nt_filttime:    dc.b 0
                dc.b 0

                dc.b 0,0,0,0,0,0,0
                dc.b 0,0,0,0,0


