;-------------------------------------------------------------------------------
; Command data/name editor
;-------------------------------------------------------------------------------

cmdleft:        dec cmdcol
                bpl cmltdone
                ldx cmdrow
                lda cmdmaxcoltbl,x
                sta cmdcol
cmltdone:       rts

cmdright:       ldx cmdrow
                lda cmdcol
                cmp cmdmaxcoltbl,x
                bcs cmrtover
                adc #$01
                bcc cmrtdone
cmrtover:       lda #$00
cmrtdone:       sta cmdcol
                rts

cmdup:          lda cmdrow
                eor #$01
                sta cmdrow
                beq cmupok
                lda cmdnum
                bne cmupok2
                sta cmdrow
                beq cmupok
cmupok2:        dec cmdnum
cmupok:         lda #$00
                sta cmdcol
adjustcmdview:  lda cmdnum
                cmp cmdview
                bcs acvnotlow
                sta cmdview
                rts
acvnotlow:      sbc cmdview
                cmp #VISIBLE_CMDS
                bcc acvnothigh
                sbc #VISIBLE_CMDS
                adc cmdview
                sta cmdview
acvnothigh:
cmupdone:       rts

cmddown:        lda cmdrow
                eor #$01
                sta cmdrow
                bne cmupok
                lda cmdnum
                cmp cmdlen
                bcs cmdnlimit
                cmp #MAX_CMD-1
                bcc cmdnok
cmdnlimit:      lda #$01
                sta cmdrow
                bne cmupok
cmdnok:         adc #$01
                sta cmdnum
                bne cmupok

cmnamedel:      jsr cmdleft
                jsr getcmdnameeditptr
                lda #$20
                sta (destlo),y
                jsr printpattern
                jmp cmedcommon2

cmddel:         lda cmdrow
                beq cmnamedel
                ldx cmdnum
                cpx cmdlen
                beq cmdeldone
                stx var1
cmdelloop:      lda nt_cmdad+1,x
                sta nt_cmdad,x
                lda nt_cmdsr+1,x
                sta nt_cmdsr,x
                lda nt_cmdwavepos+1,x
                sta nt_cmdwavepos,x
                lda nt_cmdpulsepos+1,x
                sta nt_cmdpulsepos,x
                lda nt_cmdfiltpos+1,x
                sta nt_cmdfiltpos,x
                inx
                cpx cmdlen
                bne cmdelloop
cmdelnames:     ldx var1
                inx
                txa
                jsr getcmdnameptr
                stx srclo
                sty srchi
                stx destlo
                sty desthi
                lda #MAX_CMDNAMELEN+1
                jsr addsrc
                ldy #MAX_CMDNAMELEN-1
cmdelnames2:    lda (srclo),y
                sta (destlo),y
                dey
                bpl cmdelnames2
                inc var1
                lda var1
                cmp cmdlen
                bne cmdelnames
                dec cmdlen
                jsr getcmdnameptr
                stx destlo
                sty desthi
                ldy #MAX_CMDNAMELEN-1
                lda #$20
cmdelnames3:    sta (destlo),y
                dey
                bpl cmdelnames3
                lda cmdnum
                sta var1
                inc var1
                lda #$ff
                sta var2
                jsr adjustpatterns
cminsdone:
cmdeldone:      rts

cmdins:         lda cmdrow
                beq cminsdone
                ldx cmdlen
                cpx cmdnum
                beq cminsdone
                cpx #MAX_CMD
                bcs cminsdone
                stx var1
cminsloop:      dex
                lda nt_cmdad,x
                sta nt_cmdad+1,x
                lda nt_cmdsr,x
                sta nt_cmdsr+1,x
                lda nt_cmdwavepos,x
                sta nt_cmdwavepos+1,x
                lda nt_cmdpulsepos,x
                sta nt_cmdpulsepos+1,x
                lda nt_cmdfiltpos,x
                sta nt_cmdfiltpos+1,x
                cpx cmdnum
                bne cminsloop
                lda #$00
                sta nt_cmdad,x
                sta nt_cmdsr,x
                sta nt_cmdwavepos,x
                sta nt_cmdpulsepos,x
                sta nt_cmdfiltpos,x
cminsnames:     dec var1
                ldx var1
                inx
                txa
                jsr getcmdnameptr
                stx srclo
                sty srchi
                stx destlo
                sty desthi
                lda #MAX_CMDNAMELEN+1
                jsr adddest
                ldy #MAX_CMDNAMELEN-1
cminsnames2:    lda (srclo),y
                sta (destlo),y
                dey
                bpl cminsnames2
                lda var1
                cmp cmdnum
                bne cminsnames
                ldy #MAX_CMDNAMELEN-1
                lda #$20
cminsnames3:    sta (srclo),y
                dey
                bpl cminsnames3
                inc cmdlen
                lda cmdnum
                sta var1
                lda #$01
                sta var2
                jmp adjustpatterns

cmdedit:        lda cmdrow
                bne cmparamedit
cmnameedit:     jsr getcmdnameeditptr
                lda key
                cmp #$20
                bcc cmnamedone
cmnametype:     cmp #$40
                bcc cmnamenoadjust
                cmp #$80
                bcc cmnamelower
cmnameupper:    sbc #$20
                bcs cmnamenoadjust
cmnamelower:    adc #$20
cmnamenoadjust: sta (destlo),y
                jsr printpattern
                jmp cmedcommon
cmeddone:
cmnamedone:     rts

cmparamedit:    lda key
                cmp #KEY_SHIFTSPACE
                beq cmtest
                cmp #KEY_SPACE
                beq cmkeyoff
                lda cmdcol
                lsr
                ldy #MAX_CMD
                jsr mulu
                lda cmdnum
                jsr add16
                lda alo
                adc #<nt_cmdad
                sta destlo
                lda ahi
                adc #>nt_cmdad
                sta desthi
                lda cmdcol
                and #$01
                tax
                jsr hexedit
                bcc cmnamedone
cmedcommon:     jsr cmdright
cmedcommon2:    lda cmdnum
                cmp cmdlen
                bne cmednotlast
                inc cmdlen
cmednotlast:    rts

cmtest:         lda cmdnum
                clc
                adc #$01
                sta testnotecmd
                lda #12*2
                ldy octave
                jsr mulu
                lda alo
                jmp playtestnote

cmkeyoff:       lda #KEYOFF
                jmp playtestnote

gotocmdparam:   ldx cmdnum
                cpx cmdlen
                beq gcpdone
                lda cmdrow
                beq gcpdone
                lda cmdcol
                lsr
                sec
                sbc #2
                bcc gcpdone
                sta var1
                ldy #MAX_CMD
                jsr mulu
                txa
                jsr add16
                lda alo
                clc
                adc #<nt_cmdwavepos
                sta srclo
                lda ahi
                adc #>nt_cmdwavepos
                sta srchi
                ldy #$00
                ldx var1
                lda key
                bmi gcpgotoend
                lda (srclo),y
                beq gcpdone
                sec
                sbc #$01
                cmp tbllen,x
                beq gcpok
                bcc gcpok
gcpdone:        rts
gcpok:          sta tblrow,x
                stx tblnum
                lda #EM_TABLES
                sta editmode
                jsr adjusttblview
                jmp printcmd
gcpgotoend:     lda tbllen,x
                clc
                adc #$01
                sta (srclo),y
                lda tbllen,x
                jmp gcpok

adjustpatterns: ldx #$00
aploop:         lda nt_patttbllo,x
                sta destlo
                lda nt_patttblhi,x
                sta desthi
                ldy #$00
aploop2:        lda (destlo),y
                beq apdone
                iny
                cmp #DUR
                bcs aploop2
                cmp #FIRSTNOTE
                bcc apgatectrl
                lsr
                bcc aploop2
apcmd:          lda (destlo),y
                and #$7f
                cmp var1
                bcc apskip
                beq apskip
                lda (destlo),y
                clc
                adc var2
                beq apskip
                cmp #$80
                beq apskip
                sta (destlo),y
apskip:         iny
                bne aploop2
apgatectrl:     and #$02
                beq apcmd
                bne aploop2
apdone:         inx
                cpx #MAX_PATT
                bne aploop
                lda cmdcopysrc              ;Move also the copy source
                cmp var1                    ;for the smart paste function
                bcc apsrcskip
                beq apsrcskip
                clc
                adc var2
                beq apsrcskip
                cmp #$80
                beq apsrcskip
                sta cmdcopysrc
apsrcskip:      jsr patttowork
                jmp printpattern

copycmd:        lda cmdrow
                beq cpcmeditname
                ldx cmdnum
                cpx cmdlen
                bcs cpcmdone
                stx cmdcopysrc
                inc cmdcopysrc
                lda nt_cmdad,x
                sta cmdcopyad
                lda nt_cmdsr,x
                sta cmdcopysr
                lda nt_cmdwavepos,x
                sta cmdcopywave
                lda nt_cmdpulsepos,x
                sta cmdcopypulse
                lda nt_cmdfiltpos,x
                sta cmdcopyfilt
                inx
                txa
                jsr getcmdnameptr
                stx destlo
                sty desthi
                ldy #MAX_CMDNAMELEN-1
cpcmname:       lda (destlo),y
                sta cmdcopyname,y
                dey
                bpl cpcmname
                sty cmdcopied
                clc
cpcmdone:       rts

cpcmeditname:   jmp cmdedit

cutcmd:         lda cmdrow
                beq cpcmeditname
                jsr copycmd
                bcs cpcmdone
                ldx cmdnum
                lda #$00
                sta nt_cmdad,x
                sta nt_cmdsr,x
                sta nt_cmdwavepos,x
                sta nt_cmdpulsepos,x
                sta nt_cmdfiltpos,x
                inx
                txa
                jsr getcmdnameptr
                stx destlo
                sty desthi
                ldy #MAX_CMDNAMELEN-1
                lda #$20
ccmname:        sta (destlo),y
                dey
                bpl ccmname
                ldx cmdnum
                inx
                cpx cmdlen
                bne ccmnotlast
                dec cmdlen
ccmnotlast:     jmp printpattern

pastecmd:       lda cmdrow
                beq cpcmeditname
                lda cmdcopied
                beq cpcmdone
                ldx cmdnum
                stx cmdcopydest
                inc cmdcopydest
                lda cmdcopyad
                sta nt_cmdad,x
                lda cmdcopysr
                sta nt_cmdsr,x
                lda cmdcopywave
                sta nt_cmdwavepos,x
                lda cmdcopypulse
                sta nt_cmdpulsepos,x
                lda cmdcopyfilt
                sta nt_cmdfiltpos,x
                inx
                txa
                jsr getcmdnameptr
                stx destlo
                sty desthi
                ldy #MAX_CMDNAMELEN-1
pcmname:        lda cmdcopyname,y
                sta (destlo),y
                dey
                bpl pcmname
                ldx cmdnum
                cpx cmdlen
                bcc pcmnotlast
                inc cmdlen
spcmdone:
pcmnotlast:     rts

smartpastecmd:  jsr pastecmd
                lda cmdrow
                beq spcmdone
                lda cmdcopied
                beq spcmdone
                ldx #$00
spcloop:        lda nt_patttbllo,x
                sta destlo
                lda nt_patttblhi,x
                sta desthi
                ldy #$00
spcloop2:       lda (destlo),y
                beq spcdone
                iny
                cmp #DUR
                bcs spcloop2
                cmp #FIRSTNOTE
                bcc spcgatectrl
                lsr
                bcc spcloop2
spccmd:         lda (destlo),y
                and #$80
                sta var1
                lda (destlo),y
                and #$7f
                cmp cmdcopysrc
                bne spcskip
                lda cmdcopydest
                ora var1
                sta (destlo),y
spcskip:        iny
                bne spcloop2
spcgatectrl:    and #$02
                bne spcloop2
                beq spccmd
spcdone:        inx
                cpx #MAX_PATT
                bne spcloop
                jsr patttowork
                jmp printpattern

resetcmdpos:    lda #$00
                sta cmdnum
                sta cmdview
                rts

;-------------------------------------------------------------------------------
; Get command name 
; A=Command, starting from 1
;-------------------------------------------------------------------------------

getcmdnameptr:  tay
                dey
                lda #MAX_CMDNAMELEN+1
                jsr mulu
                lda alo
                clc
                adc #<nt_cmdnames
                tax
                lda ahi
                adc #>nt_cmdnames
                tay
                rts

;-------------------------------------------------------------------------------
; Get command name editing pointer
;-------------------------------------------------------------------------------

getcmdnameeditptr:
                ldx cmdnum
                inx
                txa
                jsr getcmdnameptr
                stx destlo
                sty desthi
                ldy cmdcol
                rts

