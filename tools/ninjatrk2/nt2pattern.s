;-------------------------------------------------------------------------------
; Pattern editor
;-------------------------------------------------------------------------------

switchkeymode:  lda keymode
                eor #$01
                sta keymode
                lda #$06
                sta $d020
                rts

nextoctave:     jsr nameeditcheck
                inc octave
                lda octave
                cmp #MAX_OCTAVE+1
                bcc nextoctok
                lda #MIN_OCTAVE
                sta octave
nextoctok:      rts

prevoctave:     jsr nameeditcheck
                dec octave
                bne prevoctok
                lda #MAX_OCTAVE
                sta octave
prevoctok:      rts

nameeditcheck:  lda editmode
                cmp #EM_CMD
                bne necok
                lda cmdrow
                bne necok
                pla
                pla
                jmp cmdedit
necok:          rts

nextpatt:       inc pattnum
                lda pattnum
                cmp #MAX_PATT+1
                bne setpatt
                lda #$01
                sta pattnum
setpatt:        lda #EM_PATTERN
                sta editmode
                jsr patttowork
                jsr resetpattpos
                jmp resetpattmark

prevpatt:       dec pattnum
                bne setpatt
                lda #MAX_PATT
                sta pattnum
                bne setpatt

resetpattpos:   lda #$00
                sta pattcol
                sta pattrow
                sta pattview
ptltdone:
ptrtdone:       rts

pattright:      inc pattcol
                lda pattcol
                cmp #5
                bne ptrtdone
                lda #0
                sta pattcol
                beq pattdown

pattleft:       dec pattcol
                bpl ptltdone
                lda #4
                sta pattcol
                bne pattup

pattdown:       lda pattrow
                cmp workpattlen
                beq ptdndone
                inc pattrow
adjustpattview: lda pattrow
                cmp pattview
                bcs apvnotlow
                sta pattview
                rts
apvnotlow:      sbc pattview
                cmp #VISIBLE_ROWS
                bcc apvnothigh
                sbc #VISIBLE_ROWS
                adc pattview
                sta pattview
apvnothigh:
ptdndone:       rts

pattup:         lda pattrow
                beq ptupdone
                dec pattrow
                jmp adjustpattview
pteddone:
ptupdone:       rts

prevcmd:        jsr ptedbegincommon
                ldx pattrow
                lda workpattcmd,x
                and #$80
                sta var1
                dec workpattcmd,x
                lda workpattcmd,x
                and #$7f
                ora var1
                sta workpattcmd,x
                jmp ptedcommon

nextcmd:        jsr ptedbegincommon
                ldx pattrow
                lda workpattcmd,x
                and #$80
                sta var1
                inc workpattcmd,x
                lda workpattcmd,x
                and #$7f
                ora var1
                sta workpattcmd,x
                jmp ptedcommon

pattedit:       jsr ptedbegincommon
                ldx pattcol
                cpx #3
                bcs pteddur
                cpx #1
                bcs ptedcmd
                jmp ptednote
ptedcmd:        dex
                lda #<workpattcmd
                clc
                adc pattrow
                sta destlo
                lda #>workpattcmd
                adc #$00
                sta desthi
                lda key
                cmp #KEY_SPACE
                beq ptedcmdclear
                jsr hexedit
                bcc pteddone
ptedcmdcommon:  jsr ptedcommon
                inc pattcol
                lda pattcol
                cmp #3
                bne ptedcmdnotdown
                lda #1
                sta pattcol
                jsr pattdown
ptedcmdnotdown: rts
ptedcmdclear:   lda #2
                sta pattcol
                lda #$00
                tay
                sta (destlo),y
                jmp ptedcmdcommon
pteddur:        lda key
                cmp #KEY_SPACE
                beq pteddurclear
                cmp #"0"
                bcc pteddurdone
                cmp #"9"+1
                bcc pteddurok
pteddurdone:    rts
pteddurclear:   lda #4
                sta pattcol
                lda #$00
                beq pteddurcommon
pteddurok:      and #$0f
                sta var1
                ldy pattrow
                lda workpattdur,y
                ldy #10
                jsr divu
                cpx #3
                beq pteddurhigh
pteddurlow:     lda alo
                ldy #10
                jsr mulu
                ldy #$00
                lda alo
                clc
                adc var1
pteddurcommon:  cmp #$00
                beq pteddurnomax
                cmp #MINDUR
                bcs pteddurnomin
                lda #MINDUR
pteddurnomin:   cmp #MAXDUR
                bcc pteddurnomax
                lda #MAXDUR
pteddurnomax:   ldx pattrow
                sta workpattdur,x
                jsr ptedcommon
                inc pattcol
                lda pattcol
                cmp #5
                bne pteddurnotdown
                lda #3
                sta pattcol
                jsr pattdown
pteddurnotdown: rts
pteddurhigh:    sta var2
                lda var1
                ldy #10
                jsr mulu
                lda alo
                clc
                adc var2
                jmp pteddurcommon

ptednote:       lda key
                cmp #KEY_SPACE
                beq ptedkeyoff
                cmp #KEY_SHIFTSPACE
                beq ptedkeyon
                ldy keymode
                beq ptedprotracker
pteddmcoctave:  cmp #"1"
                bcc pteddmcnooct
                cmp #"7"+1
                bcs pteddmcnooct
                sec
                sbc #"0"
                sta octave
                rts
pteddmcnooct:   ldx #MAX_DMCPIANOKEYS-1
pteddmcsearch:  cmp dmckeytbl,x
                beq ptednotefound
                dex
                bpl pteddmcsearch
                rts
ptedprotracker: ldx #MAX_PTPIANOKEYS-1
ptedptsearch:   cmp ptkeytbl,x
                beq ptednotefound
                dex
                bpl ptedptsearch
ptednotedone:   rts
ptednotefound:  stx var1
                lda octave
                ldy #12
                jsr mulu
                lda alo
                clc
                adc var1
                asl
                cmp #LASTNOTE
                bcc ptednoteok
                lda #LASTNOTE
ptednoteok:     ldx pattrow
                sta workpattnote,x
                pha
                ldy #$ff
ptedgettestcmd: iny
                lda workpattcmd,y           ;Search for command up to this
                beq ptedtestcmdskip         ;point in the pattern
                sta testnotecmd
ptedtestcmdskip:cpy pattrow
                bcc ptedgettestcmd
                pla
                jsr playtestnote
                jsr ptedcommon
                jmp pattdown
ptedkeyoff:     lda #KEYOFF
                bne ptednoteok
ptedkeyon:      lda #KEYON
                bne ptednoteok

ptedbegincommon:ldx workpattlen
                jsr clearworkpattrow
                lda pattrow
                cmp #MAX_PATTLEN
                bne ptedbeginok
                pla
                pla
ptdeldone:
ptinsdone:
ptedbeginok:    rts

ptedcommon:     lda pattrow
                cmp workpattlen
                bne ptednotlast
                inc workpattlen
ptednotlast:    jmp worktopatt

pattins:        lda workpattlen
                cmp #MAX_PATTLEN
                beq ptinsdone
                ldx workpattlen
                cpx pattrow
                beq ptinsnocopy
ptinsloop:      dex
                lda workpattnote,x
                sta workpattnote+1,x
                lda workpattcmd,x
                sta workpattcmd+1,x
                lda workpattdur,x
                sta workpattdur+1,x
                cpx pattrow
                bne ptinsloop
ptinsnocopy:    ldy workpattnote,x
                jsr clearworkpattrow
                cpy #KEYON
                bne ptinsnokeyon
                tya
                sta workpattnote,x
ptinsnokeyon:   inc workpattlen
                jmp worktopatt


pattdel:        ldx pattrow
                cpx workpattlen
                beq ptdeldone
pattdelloop:    lda workpattnote+1,x
                sta workpattnote,x
                lda workpattcmd+1,x
                sta workpattcmd,x
                lda workpattdur+1,x
                sta workpattdur,x
                inx
                cpx workpattlen
                bne pattdelloop
                dec workpattlen
                jmp worktopatt

copynote:       lda pattcol
                bne gotocmd
                lda key
                bmi cndone
                ldx pattrow
                beq cndone
                lda workpattnote-1,x
                sta var1
                lda workpattnote,x
                sta var2
cnloop:         cpx workpattlen
                bcs cndone2
                lda workpattnote,x
                cmp var2
                bne cndone2
                lda var1
                sta workpattnote,x
                inx
                bne cnloop
cndone2:        jmp worktopatt
gotocmd:        cmp #3
                bcc gotocmdok
cndone:         rts
gotocmdok:      ldx pattrow
                lda key
                bmi gotocmdempty
                lda workpattcmd,x
                and #$7f
                beq cndone
                sec
                sbc #$01
                cmp cmdlen
                beq cngotocmdok
                bcs cndone
cngotocmdok:    sta cmdnum
                lda #EM_CMD
                sta editmode
                jmp adjustcmdview
gotocmdempty:   lda cmdlen
                clc
                adc #$01
                bmi cndone
                sta workpattcmd,x
                jsr worktopatt
                jsr printpattern
                lda cmdlen
                jmp cngotocmdok

transup:        jsr transrange
                ldx var1
trnuploop:      cpx var2
                bcs trnupdone
                lda workpattnote,x
                cmp #FIRSTNOTE
                bcc trnupskip
                adc #$01
                cmp #LASTNOTE
                bcc trnupok
                lda #LASTNOTE
trnupok:        sta workpattnote,x
trnupskip:      inx
                bne trnuploop
trndndone:
trnupdone:      jmp worktopatt

transdown:      jsr transrange
                ldx var1
trndnloop:      cpx var2
                bcs trndndone
                lda workpattnote,x
                cmp #FIRSTNOTE
                bcc trndnskip
                sbc #$02
                cmp #FIRSTNOTE
                bcs trndnok
                lda #FIRSTNOTE
trndnok:        sta workpattnote,x
trndnskip:      inx
                bne trndnloop

transrange:     lda #$00
                ldx workpattlen
                ldy pattmarkmode
                cpy #2
                bne trangeok
                lda pattmarkstart
                ldx pattmarkend
trangeok:       sta var1
                stx var2
                rts

opdone:         rts
optimizepatt:   ldx #$00
oploop1:        cpx workpattlen
                bcs opdone
                lda workpattdur,x           ;Find first non-zero duration
                bne opdone1                 ;so that optimizing can begin
                inx
                bne oploop1
opdone1:        stx var1                    ;Var1 = optimization startpoint
                sta var2                    ;Var2 = last known duration
oploop2:        lda workpattdur,x           ;Fill zero durations with last
                beq oploop2nonew            ;known duration to help joining
                sta var2
oploop2nonew:   lda var2
                sta workpattdur,x
                inx
                cpx workpattlen
                bcc oploop2
                ldy workpattlen
                dey
                sty var3                    ;Var3 = last position to join
                ldx var1
oploop3:        cpx var3
                beq opdone3
                jsr opcheckjoin             ;Can join this step and the next?
                bcs opjoin
oploop3next:    inx
                bne oploop3
opdone3:        jmp opfinalize


opjoin:         stx var5
                lda workpattlen             ;If at least 3 steps to
                sec                         ;pattern end, check also
                sbc var5                    ;the following steps for
                sta var6                    ;optimal result
                cmp #3
                bcc opjoinok
                txa
                beq opjoinnoprevious
                lda workpattdur,x           ;If join results in same
                clc                         ;duration as previous,
                adc workpattdur+1,x         ;definitely go ahead
                cmp workpattdur-1,x
                beq opjoinok
opjoinnoprevious:
                lda workpattnote,x          ;If notes are same,
                cmp workpattnote+1,x        ;go ahead with the join
                beq opjoinok
                lda workpattdur+2,x         ;If durations don't
                cmp workpattdur+1,x         ;match, go ahead with the join
                bne opjoinok
                cmp workpattdur,x
                bne opjoinok
                inx                         ;If the next pair can be
                jsr opcheckjoin             ;joined too, go ahead
                bcs opjoinok
                lda var6
                cmp #4                      ;If there are 4 or more steps
                bcc oploop3next             ;check also two notes ahead
                inx
                jsr opcheckjoin
                bcc oploop3next
opjoinok:       ldx var5
                lda workpattdur,x           ;Check that duration doesn't
                clc                         ;overflow
                adc workpattdur+1,x
                cmp #MAXDUR+1
                bcs oploop3next
                sta workpattdur,x           ;Add to the first note
                inx
opshift:        cpx workpattlen
                bcs opshiftdone
                lda workpattnote+1,x
                sta workpattnote,x
                lda workpattcmd+1,x
                sta workpattcmd,x
                lda workpattdur+1,x
                sta workpattdur,x
                inx
                bne opshift
opshiftdone:    dec workpattlen
                dec var3
                ldx var5
                jmp oploop3

opfinalize:     ldx #$00
                txa
                sta var2
                sta var4
oploop4:        lda workpattdur,x           ;Finally remove duplicate
                beq oploop4durdone          ;durations and commands
                cmp var2
                bne oploop4newdur
                lda #$00
                beq oploop4nonewdur
oploop4newdur:  sta var2
oploop4nonewdur:sta workpattdur,x
oploop4durdone: lda workpattcmd,x
                beq oploop4cmddone
                cmp var4
                bne oploop4newcmd
                lda workpattnote,x          ;Do not remove command execs
                cmp #FIRSTNOTE
                bcc oploop4cmddone
                lda #$00
                beq oploop4nonewcmd
oploop4newcmd:  sta var4
oploop4nonewcmd:sta workpattcmd,x
oploop4cmddone: inx
                cpx workpattlen
                bcc oploop4
                lda pattrow
                cmp workpattlen
                beq opposok
                bcc opposok
                lda workpattlen
                sta pattrow
opposok:        jsr adjustpattview
                jmp worktopatt

opcheckjoin:    stx ocjrestx+1
ocjgetcmd:      lda workpattcmd,x
                bne ocjcmdfound
                dex
                bpl ocjgetcmd
                lda #$ff
ocjcmdfound:    sta var4
ocjrestx:       ldx #$00
ocjcase1:       lda workpattnote,x          ;Join note and keyon
                cmp #FIRSTNOTE              ;if it's an HR note
                bcc ocjcase2                ;and the keyon doesn't have
                lda var4                    ;a command
                bmi ocjcase2
                lda workpattcmd+1,x
                bne ocjcase2
                lda workpattnote+1,x
                cmp #KEYON
                beq ocjok
ocjcase2:       lda workpattnote,x          ;Join two keyoffs or keyons
                cmp #FIRSTNOTE              ;if there is no command on
                bcs ocjnext                 ;the latter
                cmp workpattnote+1,x
                bne ocjnext
                lda workpattcmd+1,x
                beq ocjok
ocjnext:        clc
                rts
ocjok:          sec
                rts

clearworkpattrow:
                lda #KEYOFF
                sta workpattnote,x
                lda #$00
                sta workpattcmd,x
                sta workpattdur,x
lcmddone:       rts

legatocmd:      ldx pattrow
                cpx workpattlen
                bcs lcmddone
                lda workpattcmd,x
                beq lcmddone
                eor #$80
                sta workpattcmd,x
                jmp worktopatt

markpatt:       lda pattmarkmode
                cmp #2
                bcc mptnoreset
mptreset:       jsr resetpattmark
mptnoreset:     lda pattrow
                cmp workpattlen
                beq mptdone
                ldy pattmarkmode
                bne mptend
mptstart:       sta pattmarkstart
                lda #1
                bne mptstore
mptend:         cmp pattmarkstart
                bcc mptstart
                adc #$00
                sta pattmarkend
                lda #2
mptstore:       sta pattmarkmode
mptdone:        rts

resetpattmark:  lda #$00
                beq mptstore

cutpatt:        jsr copypatt
                bcc cptdone
                lda pattcopylen
                sta var6
                beq cptdone
                lda pattmarkstart
                sta pattrow
                jsr adjustpattview
cptloop:        jsr pattdel
                dec var6
                bne cptloop
cpptdone:       clc
pptdone:
cptdone:        rts

copypatt:       lda pattmarkmode
                cmp #2
                bne cpptwhole
cpptcommon:     ldy pattmarkstart
                ldx #$00
cpptloop:       lda workpattnote,y
                sta pattcopynote,x
                lda workpattcmd,y
                sta pattcopycmd,x
                lda workpattdur,y
                sta pattcopydur,x
                inx
                iny
                cpy pattmarkend
                bne cpptloop                ;C=1 when exiting copy successfully
                stx pattcopylen
                jmp resetpattmark
cpptwhole:      lda #$00
                sta pattmarkstart
                lda workpattlen
                sta pattmarkend
                beq cpptdone
                bne cpptcommon

pastepatt:      lda pattcopylen
                beq pptdone
                clc
                adc pattrow
                bcs pptdone
                cmp #MAX_PATTLEN+1
                bcs pptdone
                ldy pattrow
                ldx #$00
pptloop:        lda pattcopynote,x
                sta workpattnote,y
                lda pattcopycmd,x
                sta workpattcmd,y
                lda pattcopydur,x
                sta workpattdur,y
                iny
                inx
                cpx pattcopylen
                bne pptloop
                tya
                sta pattrow
                cmp workpattlen
                bcc pptnonewlen
                sta workpattlen
pptnonewlen:    jsr adjustpattview
                jmp worktopatt

;-------------------------------------------------------------------------------
; Convert work pattern to pattern
;-------------------------------------------------------------------------------

wtop_error:     lda #$02
                sta $d020
                jsr patttowork
                lda pattrow
                cmp workpattlen
                bcc wtop_errorposok
                lda workpattlen
                sta pattrow
wtop_errorposok:jmp adjustpattview

worktopatt:     ldx pattnum
                lda nt_patttbllo-1,x
                sta destlo
                lda nt_patttblhi-1,x
                sta desthi
                ldx #$00
                ldy #$00
wtop_predict:   cpx workpattlen
                beq wtop_predictdone
                iny
                lda workpattcmd,x
                beq wtop_predictnocmd
                iny
wtop_predictnocmd:
                lda workpattdur,x
                beq wtop_predictnodur
                iny
wtop_predictnodur:
                inx
                jmp wtop_predict
wtop_predictdone:
                iny
                cpy #MAX_PATTLEN+1
                bcs wtop_error
                ldx #$00
                stx alo
                stx ahi
                stx var1
                ldy #$00
wtop_loop:      cpx workpattlen
                beq wtop_done
                lda workpattnote,x
                sta (destlo),y
                iny
                cmp #FIRSTNOTE
                bcc wtop_gatectrl
                lda workpattcmd,x
                beq wtop_nocmd
                sta (destlo),y
                dey
                lda (destlo),y
                ora #$01
                sta (destlo),y
                iny
                iny
wtop_nocmd:     lda workpattdur,x
                beq wtop_nodur
                sta var1
                sec
                sbc #$03
                eor #$ff
                sta (destlo),y
                iny
wtop_nodur:     inx
                lda var1
                jsr add16
                jmp wtop_loop
wtop_done:      lda #$00
                sta (destlo),y
                iny
                sty pattbytes
wtop_clear:     cpy #MAX_PATTLEN
                bcc wtop_cleardone
                sta (destlo),y
                iny
                bne wtop_clear
wtop_cleardone: lda alo
                sta totaldurlo
                lda ahi
                sta totaldurhi
                rts
wtop_gatectrl:  lda workpattcmd,x
                beq wtop_gatectrlnocmd
                sta (destlo),y
                iny
                bne wtop_nocmd
wtop_gatectrlnocmd:
                dey
                lda (destlo),y
                ora #$02
                sta (destlo),y
                iny
                bne wtop_nocmd

;-------------------------------------------------------------------------------
; Convert pattern to work pattern
;-------------------------------------------------------------------------------

patttowork:     ldx pattnum
                lda nt_patttbllo-1,x
                sta srclo
                lda nt_patttblhi-1,x
                sta srchi
                ldx #$00
                stx alo
                stx ahi
                stx var1
                ldy #$00
ptow_loop:      jsr clearworkpattrow
                lda (srclo),y
                beq ptow_end
                iny
                cmp #FIRSTNOTE
                bcc ptow_gatectrl
                pha
                and #$fe
                sta workpattnote,x
                pla
                lsr
                bcc ptow_nocmd
                lda (srclo),y
                iny
                sta workpattcmd,x
ptow_nocmd:     lda (srclo),y
                cmp #DUR
                bcc ptow_nodur
                iny
                eor #$ff
                adc #$02 ;C=1 -> add one more
                sta workpattdur,x
                sta var1
ptow_nodur:     inx
                lda var1
                jsr add16
                jmp ptow_loop
ptow_end:       stx workpattlen
                iny
                sty pattbytes
                lda alo
                sta totaldurlo
                lda ahi
                sta totaldurhi
                rts
ptow_gatectrl:  pha
                and #$fc
                sta workpattnote,x
                pla
                and #$02
                bne ptow_nocmd
                lda (srclo),y
                iny
                sta workpattcmd,x
                jmp ptow_nocmd

getpattdurpos:  lda #$00
                sta alo
                sta ahi
                sta var1
                tax
gpdploop:       cpx pattrow
                beq gpdpdone
                lda workpattdur,x
                beq gpdpnonew
                sta var1
gpdpnonew:      lda var1
                jsr add16
                inx
                bne gpdploop
gpdpdone:       lda alo
                sta durposlo
                lda ahi
                sta durposhi
                rts

convertdurations:
                sta var1
                ldx #$00
cdloop1:        lda nt_patttbllo,x
                sta destlo
                lda nt_patttblhi,x
                sta desthi
                ldy #$00
cdloop2:        lda (destlo),y
                beq cdnextpatt
                cmp #$c0
                bcc cdnodur 
                clc
                adc var1
                bne cddurnothigh
                lda #$ff
cddurnothigh:   cmp #$bf
                bne cddurok
                lda #$c0
cddurok:        sta (destlo),y
                iny
                bne cdloop2
cdnodur:        iny
                cmp #FIRSTNOTE
                bcc cdgatectrl
                lsr
                bcc cdloop2
cdcmd:          iny
                bne cdloop2
cdgatectrl:     and #$02
                beq cdcmd
                bne cdloop2
cdnextpatt:     inx
                cpx #MAX_PATT
                bcc cdloop1
                rts






