;-------------------------------------------------------------------------------
; Reset editor status
;-------------------------------------------------------------------------------

reseteditor:    lda #$00
                sta songnum
                lda #$01
                sta pattnum
                jsr resetsongpos
                jsr resetpattpos
                jsr resettblpos
                jsr resetcmdpos
                jsr resettrackmark
                jsr resetpattmark
                jmp resettblmark

;-------------------------------------------------------------------------------
; Print whole song-screen
;-------------------------------------------------------------------------------

printall:       jsr trackstowork
                jsr patttowork
                jsr printtracks
                jsr printpattern
                jsr printtables
                jmp printcmd

;-------------------------------------------------------------------------------
; Print tracks
;-------------------------------------------------------------------------------

printtracks:    lda titlecol
                sta textcolor
                ldx #0
                ldy #2
                jsr setxy
                ldx #<tracktext
                ldy #>tracktext
                jsr printtext
                lda #0
                sta var1
                lda #<worktrack1
                sta destlo
                lda #>worktrack1
                sta desthi
ptrk_loop1:     ldx var1
                lda #0
                sta var2
                clc
                adc trackview,x
                sta var4
                txa
                asl
                adc var1
                asl
                sta var3
                lda worktrackstart,x
                sta ptrk_startcmp+1
                lda worktracklen,x
                sta ptrk_endcmp+1
                tay
                dey
                dey
                lda (destlo),y
                beq ptrk_endhlok
                ldy #$ff
ptrk_endhlok:   sty ptrk_endhlcmp+1
ptrk_loop2:     ldx var3
                lda var2
                clc
                adc #3
                tay
                jsr setxy
                lda titlecol
                sta textcolor
                lda var4
                jsr printhex8
                lda trackmarkmode
                cmp #2
                bne ptrk_nomark
                lda var1
                cmp trackmarknum
                bne ptrk_nomark
                lda var4
                cmp trackmarkstart
                bcc ptrk_nomark
                cmp trackmarkend
                bcs ptrk_nomark
                lda #">"
                bne ptrk_markdone
ptrk_nomark:    lda #$20
ptrk_markdone:  jsr printchar
                ldy var4
ptrk_endcmp:    cpy #$00
                bcs ptrk_empty
                lda (destlo),y
ptrk_startcmp:  cpy #$00
                beq ptrk_highlight
                ldx normalcol
ptrk_endhlcmp:  cpy #$00
                bcs ptrk_highlight2
                cmp #$80
                bcc ptrk_normal
ptrk_highlight2:ldx highlightcol
ptrk_normal:    stx textcolor
ptrk_highlight: jsr printhex8
ptrk_rowdone:   inc var4
                inc var2
                lda var2
                cmp #VISIBLE_ROWS
                bcc ptrk_loop2
ptrk_trkdone:   inc desthi
                inc var1
                lda var1
                cmp #3
                bcs ptrk_done
                jmp ptrk_loop1
ptrk_done:      lda editmode
                cmp #EM_TRACKS
                bne ptrk_nocursor
                ldx tracknum
                lda trackrow,x
                sec
                sbc trackview,x
                clc
                adc #3
                tay
                txa
                asl
                adc tracknum
                asl
                adc #3
                adc trackcol
                tax
                lda #$00
                jsr cursorpos
ptrk_nocursor:  rts
ptrk_empty:     lda emptycol
                sta textcolor
                ldx #<emptytracktext
                ldy #>emptytracktext
                jsr printtext
                jmp ptrk_rowdone

;-------------------------------------------------------------------------------
; Print pattern
;-------------------------------------------------------------------------------

printpattern:   jsr getpattdurpos
                ldx #18
                ldy #2
                jsr setxy
                lda titlecol
                sta textcolor
                ldx #<patttext1
                ldy #>patttext1
                jsr printtext
                lda pattnum
                jsr printhex8
                ldx #<patttext2
                ldy #>patttext2
                jsr printtext
                ldx durposlo
                ldy durposhi
                jsr printdec16
                lda #"/"
                jsr printchar
                ldx totaldurlo
                ldy totaldurhi
                jsr printdec16
                ldx #<patttext3
                ldy #>patttext3
                jsr printtext
                lda pattbytes
                jsr printhex8
                lda #0
                sta var1
ppt_loop:       lda var1
                clc
                adc pattview
                sta var2
                lda var1
                adc #3
                tay
                ldx #18
                jsr setxy
                lda titlecol
                sta textcolor
                lda var2
                jsr printhex8
                lda pattmarkmode
                cmp #2
                bne ppt_nomark
                lda var2
                cmp pattmarkstart
                bcc ppt_nomark
                cmp pattmarkend
                bcs ppt_nomark
                lda #">"
                bne ppt_mark
ppt_nomark:     lda #$20
ppt_mark:       jsr printchar
                lda normalcol
                sta textcolor
                ldx var2
                cpx workpattlen
                beq ppt_end
                bcs ppt_empty
                lda workpattnote,x
                cmp #KEYOFF
                beq ppt_keyoff
                cmp #KEYON
                bne ppt_note
ppt_keyon:      ldx #<keyontext
                ldy #>keyontext
                jsr printtext
                jmp ppt_notedone
ppt_keyoff:     ldx #<keyofftext
                ldy #>keyofftext
                jsr printtext
                jmp ppt_notedone
ppt_end:        lda highlightcol
                ldx #<endpatttext
                ldy #>endpatttext
                jmp ppt_emptycommon
ppt_empty:      lda emptycol
                ldx #<emptypatttext
                ldy #>emptypatttext
ppt_emptycommon:sta textcolor
                jsr printtext
                lda #1
                jsr skipchars
                lda #$00
                jsr printcmdname
                jmp ppt_rowdone
ppt_note:       lsr
                tay
                ldx notetbl-12,y
                lda notenames,x
                sta notetext
                lda notenames+1,x
                sta notetext+1
                lda octavetbl-12,y
                ora #$30
                sta notetext+2
                lda highlightcol
                sta textcolor
                ldx #<notetext
                ldy #>notetext
                jsr printtext
ppt_notedone:   lda #$20
                jsr printchar
                lda normalcol
                sta textcolor
                ldx var2
                lda workpattcmd,x
                beq ppt_emptycmd
                jsr printhex8
                jmp ppt_cmddone
ppt_emptycmd:   ldx #<emptytracktext
                ldy #>emptytracktext
                jsr printtext
ppt_cmddone:    lda #$20
                jsr printchar
                ldx var2
                lda workpattdur,x
                beq ppt_emptydur
                jsr printdec8
                jmp ppt_durdone
ppt_emptydur:   ldx #<emptytracktext
                ldy #>emptytracktext
                jsr printtext
ppt_durdone:    lda #1
                jsr skipchars
                lda highlightcol
                sta textcolor
                ldx var2
                lda workpattcmd,x
                jsr printcmdname
ppt_rowdone:    inc var1
                lda var1
                cmp #VISIBLE_ROWS
                bcs ppt_done
                jmp ppt_loop
ppt_done:       lda editmode
                cmp #EM_PATTERN
                bne ppt_nocursor
                lda pattrow
                sec
                sbc pattview
                clc
                adc #3
                tay
                ldx pattcol
                lda pattcoltbl,x
                adc #18
                tax
                lda #$00
                cpx #21
                bne ppt_nowidecursor
                lda #$ff
ppt_nowidecursor:
                jsr cursorpos
ppt_nocursor:   rts

;-------------------------------------------------------------------------------
; Print tables
;-------------------------------------------------------------------------------

printtables:    jsr converttables
                ldx #0
                ldy #4+VISIBLE_ROWS
                jsr setxy
                lda titlecol
                sta textcolor
                ldx #<tbltext
                ldy #>tbltext
                jsr printtext
                lda #0
                sta var1
                lda #<nt_tables
                sta destlo
                lda #>nt_tables
                sta desthi
ptbl_loop1:     lda #0
                sta var2
                clc
                ldx var1
                adc tblview,x
                sta var4
                txa
                asl
                asl
                asl
                adc var1
                sta var3
                lda tblhighlighttbl,x
                sta ptbl_hlcmp+1
ptbl_loop2:     ldx var3
                lda var2
                clc
                adc #5+VISIBLE_ROWS
                tay
                jsr setxy
                ldx var1
                lda titlecol
                sta textcolor
                lda var4
                clc
                adc #$01
                jsr printhex8
                lda tblmarkmode
                cmp #2
                bne ptbl_nomark
                lda var1
                cmp tblmarknum
                bne ptbl_nomark
                lda var4
                cmp tblmarkstart
                bcc ptbl_nomark
                cmp tblmarkend
                bcs ptbl_nomark
                lda #">"
                bne ptbl_mark
ptbl_nomark:    lda #$20
ptbl_mark:      jsr printchar
                ldx var1
                lda var4
                cmp tbllen,x
                bcs ptbl_empty
                tay
                lda (destlo),y
                ldx normalcol
ptbl_hlcmp:     cmp #$00
                bcc ptbl_hldone
                ldx highlightcol
ptbl_hldone:    stx textcolor
                jsr printhex8
                lda #1
                jsr skipchars
                inc desthi
                ldy var4
                lda (destlo),y
                dec desthi
                jsr printhex8
ptbl_rowdone:   inc var4
                inc var2
                lda var2
                cmp #VISIBLE_TBLROWS
                bne ptbl_loop2
                inc desthi
                inc desthi
                inc var1
                lda var1
                cmp #3
                beq ptbl_done
                jmp ptbl_loop1
ptbl_done:      lda editmode
                cmp #EM_TABLES
                bne ptbl_nocursor
                ldx tblnum
                lda tblrow,x
                sec
                sbc tblview,x
                clc
                adc #5+VISIBLE_ROWS
                tay
                txa
                asl
                asl
                asl
                adc tblnum
                ldx tblcol
                adc tblcoltbl,x
                tax
                lda #$00
                jsr cursorpos
ptbl_nocursor:  rts
ptbl_empty:     lda emptycol
                sta textcolor
                ldx #<emptytbltext
                ldy #>emptytbltext
                jsr printtext
                jmp ptbl_rowdone

;-------------------------------------------------------------------------------
; Print commands
;-------------------------------------------------------------------------------

printcmd:       ldx #27
                ldy #4+VISIBLE_ROWS
                jsr setxy
                lda titlecol
                sta textcolor
                ldx #<cmdtext
                ldy #>cmdtext
                jsr printtext
                lda #$00
                sta var1
pcmd_loop:      ldx #27
                lda var1
                asl
                adc #5+VISIBLE_ROWS
                sta var3
                tay
                jsr setxy
                lda titlecol
                sta textcolor
                lda var1
                sec
                adc cmdview
                sta var2
                jsr printhex8
                lda #1
                jsr skipchars
                lda highlightcol
                sta textcolor
                lda var2
                jsr printcmdname
                lda normalcol
                sta textcolor
                ldx #27
                ldy var3
                iny
                jsr setxy
                ldx var2
                cpx cmdlen
                beq pcmd_ok
                bcs pcmd_empty
pcmd_ok:        lda nt_cmdad-1,x
                jsr printhex8
                ldx var2
                lda nt_cmdsr-1,x
                jsr printhex8
                lda #1
                jsr skipchars
                ldx var2
                lda nt_cmdwavepos-1,x
                jsr printhex8
                lda #1
                jsr skipchars
                ldx var2
                lda nt_cmdpulsepos-1,x
                jsr printhex8
                lda #1
                jsr skipchars
                ldx var2
                lda nt_cmdfiltpos-1,x
                jsr printhex8
pcmd_rowdone:   inc var1
                lda var1
                cmp #VISIBLE_CMDS
                bne pcmd_loop
                lda editmode
                cmp #EM_CMD
                bne pcmd_nocursor
                lda cmdnum
                sec
                sbc cmdview
                asl
                adc #5+VISIBLE_ROWS
                adc cmdrow
                tay
                lda cmdrow
                clc
                beq pcmd_namecursor
pcmd_valuecursor:
                ldx cmdcol
                lda cmdcoltbl,x
                adc #27
pcmd_cursorcommon:
                tax
                lda #$00
                jmp cursorpos
pcmd_namecursor:lda #30
                adc cmdcol
                bne pcmd_cursorcommon
pcmd_nocursor:  rts
pcmd_empty:     lda emptycol
                sta textcolor
                ldx #<emptycmdtext
                ldy #>emptycmdtext
                jsr printtext
                jmp pcmd_rowdone

printcmdname:   and #$7f
                beq pcn_empty
                jsr getcmdnameptr
                jmp printtext
pcn_empty:      ldx #<emptycmdname
                ldy #>emptycmdname
                jmp printtext

;-------------------------------------------------------------------------------
; Print current status (including rastertime)
;-------------------------------------------------------------------------------

printstatus:    lda titlecol
                sta textcolor
                ldx #21
                ldy #0
                jsr setxy
                lda songnum
                jsr printdigit
                ldx #26
                ldy #0
                jsr setxy
                lda octave
                jsr printdigit
                ldx #28
                ldy #0
                jsr setxy
                lda timemin
                jsr printdec8
                lda #":"
                ldx timeframe
                cpx timeframehalf
                bcc psframeok
                lda #" "
psframeok:      jsr printchar
                lda timesec
                jsr printdec8
                ldx #37
                ldy #0
                jsr setxy
                lda curraster
                jsr printdigit
                ldx #39
                ldy #0
                jsr setxy
                lda maxraster
                jsr printdigit
upds_done:      rts

;-------------------------------------------------------------------------------
; Update current edit window
;-------------------------------------------------------------------------------

updatescreen:   lda fastup
                ora fastdown
                bne upds_done
                ldx editmode
                beq upds_tracks
                dex
                beq upds_pattern
                dex
                beq upds_tables
upds_commands:  jmp printcmd
upds_tracks:    jmp printtracks
upds_pattern:   jmp printpattern
upds_tables:    jmp printtables


