;-------------------------------------------------------------------------------
; Table editor
;-------------------------------------------------------------------------------

tblleft:        dec tblcol
                bpl tbltdone
                lda #3
                sta tblcol
                dec tblnum
                bpl tbltdone
                lda #2
                sta tblnum
tbltdone:       rts

tblright:       inc tblcol
                lda tblcol
                cmp #4
                bcc tbrtdone
                lda #0
                sta tblcol
                inc tblnum
                lda tblnum
                cmp #3
                bcc tbrtdone
                lda #0
                sta tblnum
tbrtdone:       rts

tblrightedit:   inc tblcol
                lda tblcol
                cmp #4
                bcc tbrtdone
                lda #0
                sta tblcol
                beq tbldown

tblup:          ldx tblnum
                lda tblrow,x
                beq tbupdone
                sec
                sbc #$01
                sta tblrow,x
adjusttblview:  lda tblrow,x
                cmp tblview,x
                bcs atvnotlow
                sta tblview,x
                rts
atvnotlow:      sbc tblview,x
                cmp #VISIBLE_TBLROWS
                bcc atvnothigh
                sbc #VISIBLE_TBLROWS
                adc tblview,x
                sta tblview,x
atvnothigh:
tbdndone:
tbupdone:       rts

tbldown:        ldx tblnum
                lda tblrow,x
                cmp tbllen,x
                bcs tbdndone
                adc #$01
                sta tblrow,x
                bne adjusttblview

tbledit:        jsr gettblptr
                lda tbllen,x
                cmp #MAX_TBLLEN
                beq tbeddone
                lda tblrow,x
                jsr adddest
                lda tblcol
                cmp #2
                and #1
                tax
                bcc tbednotright
                inc desthi
tbednotright:   jsr hexedit
                bcc tbeddone
                ldx tblnum
                lda tblrow,x
                cmp tbllen,x
                bne tbednotlast
                inc tbllen,x
tbednotlast:    tay
                txa
                bne tbednoabsarp
                lda nt_waveedittbl,y
                cmp #$c0
                bcs tbednoabsarp
                lda nt_notetbl,y
                bpl tbednoabsarp
                cmp #$df+1                    ;Keep absolute notes within range
                bcc tbednothigh
                lda #$df
tbednothigh:    cmp #$8c
                bcs tbednotlow
                lda #$8c
tbednotlow:     sta nt_notetbl,y
tbednoabsarp:   jmp tblrightedit
tbinsdone:
tbdeldone:
tbeddone:       rts
tblins:         jsr gettblptr
                lda tbllen,x
                cmp tblrow,x
                beq tbinsdone
                cmp #MAX_TBLLEN
                beq tbinsdone
                lda tblrow,x
                sta var1
                ldy tbllen,x
tbinsloop:      dey
                lda (destlo),y
                iny
                sta (destlo),y
                dey
                inc desthi
                lda (destlo),y
                iny
                sta (destlo),y
                dey
                dec desthi
                cpy var1
                bne tbinsloop
                lda #$00
                sta (destlo),y
                inc desthi
                sta (destlo),y
                dec desthi
                inc tbllen,x
                lda #$01
                sta var2
                jmp adjusttbljumps

tbldel:         jsr gettblptr
                lda tbllen,x
                cmp tblrow,x
                beq tbdeldone
                sta var1
                ldy tblrow,x
tbdelloop:      iny
                lda (destlo),y
                dey
                sta (destlo),y
                inc desthi
                iny
                lda (destlo),y
                dey
                sta (destlo),y
                dec desthi
                iny
                cpy var1
                bne tbdelloop
                dec tbllen,x
                lda tblrow,x
                sta var1
                inc var1
                lda #$ff
                sta var2
                jmp adjusttbljumps

marktbl:        ldx tblnum
                cpx tblmarknum
                bne mtbreset
                lda tblmarkmode
                cmp #2
                bcc mtbnoreset
mtbreset:       jsr resettblmark
mtbnoreset:     lda tblrow,x
                cmp tbllen,x
                beq mtbdone
                ldy tblmarkmode
                bne mtbend
mtbstart:       stx tblmarknum
                sta tblmarkstart
                lda #1
                bne mtbstore
mtbend:         cmp tblmarkstart
                bcc mtbstart
                adc #$00
                sta tblmarkend
                lda #2
mtbstore:       sta tblmarkmode
mtbdone:        rts

resettblmark:   lda #$00
                beq mtbstore

resettblpos:    ldx #2
                lda #$00
rtploop:        sta tblrow,x
                sta tblview,x
                dex
                bpl rtploop
                rts

cuttbl:         jsr copytbl
                bcc ctbdone
                lda tblcopylen
                sta var6
                beq ctbdone
                ldx tblnum
                lda tblmarkstart
                sta tblrow,x
                jsr adjusttblview
ctbloop:        jsr tbldel
                dec var6
                bne ctbloop
cptbdone:       clc
ptbdone:
ctbdone:        rts

copytbl:        jsr gettblptr
                cpx tblmarknum
                bne cptbdone
                lda tblmarkmode
                cmp #2
                bne cptbdone
                ldy tblmarkstart
                ldx #$00
cptbloop:       lda (destlo),y
                sta tblcopyleft,x
                inc desthi
                lda (destlo),y
                sta tblcopyright,x
                dec desthi
                inx
                iny
                cpy tblmarkend
                bne cptbloop                ;C=1 when exiting copy successfully
                stx tblcopylen
                jmp resettblmark

pastetbl:       jsr gettblptr
                lda tblcopylen
                beq ptbdone
                clc
                adc tblrow,x
                bcs ptbdone
                ldy tblrow,x
                ldx #$00
ptbloop:        cpy #MAX_TBLLEN
                beq ptbdone2
                lda tblcopyleft,x
                sta (destlo),y
                inc desthi
                lda tblcopyright,x
                sta (destlo),y
                dec desthi
                iny
                inx
                cpx tblcopylen
                bne ptbloop
ptbdone2:       tya
                ldx tblnum
                cmp tbllen,x
                bcc ptbnonewlen
                sta tbllen,x
ptbnonewlen:    lda tblcopylen
                sta var6
ptbdownloop:    jsr tbldown
                dec var6
                bne ptbdownloop
                rts

followjump:     jsr gettblptr
                lda tblrow,x
                cmp tbllen,x
                beq fjdone
                tay
                lda (destlo),y
                cmp #$ff
                bne fjdone
                inc desthi
                lda (destlo),y
                beq fjdone
                sec
                sbc #$01
                cmp tbllen,x
                bcc fjok
                beq fjok
fjdone:         rts
fjok:           sta tblrow,x
                jmp adjusttblview

gettblptr:      ldx tblnum
                lda #<nt_tables
                sta destlo
                txa
                asl
                adc #>nt_tables
                sta desthi
                rts

adjusttbljumps: lda tbllen,x
                sta var3
                ldy #$00
atjloop:        lda (destlo),y
                cmp #$ff
                bne atjnojump
                inc desthi
                lda (destlo),y
                cmp var1
                beq atjnojump2
                bcc atjnojump2
                clc
                adc var2
                sta (destlo),y
atjnojump2:     dec desthi
atjnojump:      iny
                cpy var3
                bne atjloop
                lda tblnum
                ldy #MAX_CMD
                jsr mulu
                lda alo
                clc
                adc #<nt_cmdwavepos
                sta destlo
                lda ahi
                adc #>nt_cmdwavepos
                sta desthi
                ldy #$00
atjcmds:        cpy cmdlen
                beq atjcmdsdone
                lda (destlo),y
                cmp var1
                beq atjnocmd
                bcc atjnocmd
                clc
                adc var2
                sta (destlo),y
atjnocmd:       iny
                bne atjcmds
atjcmdsdone:    jmp printcmd

converttables:  ldx #$00
cptblloop:      lda nt_pulsetimetbl,x
                cmp #$80
                bcc cptblmod
                cmp #$ff
                lda nt_pulsespdedittbl,x
                bcs cptblstore
                bcc cptblset
cptblmod:       lda nt_pulsespdedittbl,x
                bpl cptblset
                sbc #$00                    ;Decrement negative modulation
                bmi cptblset                ;value by one
                lda #$80
cptblset:       asl
                adc #$00
                asl
                adc #$00
                asl
                adc #$00
                asl
                adc #$00
cptblstore:     sta nt_pulsespdtbl,x
                inx
                cpx tbllen+1
                bcc cptblloop
                ldx #$00
cwtblloop:      lda nt_waveedittbl,x
                cmp #$c0                    ;Reverse the vibrato speed setting
                bcc cwtblstore              ;for the playroutine
                cmp #$e0
                bcs cwtblstore
                eor #$1f
cwtblstore:     sta nt_wavetbl,x
                inx
                cpx tbllen
                bcc cwtblloop
                jmp copyglobalsettings      ;Copy global settings to playroutines

