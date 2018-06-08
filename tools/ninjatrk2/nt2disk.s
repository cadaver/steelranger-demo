;-------------------------------------------------------------------------------
; Disk menu
;-------------------------------------------------------------------------------

diskmenu:       jsr stop
                jsr clearscreen
diskmenu2:      lda titlecol
                sta textcolor
                ldy #$00
                sty var1
                lda #<disktext
                sta textlo
                lda #>disktext
                sta texthi
dmloop1:        ldx #0
                jsr setxy
                jsr printtextcont
                lda normalcol
                sta textcolor                
                inc var1
                ldy var1
                cpy #11
                bcc dmloop1
                jsr clearbottomrow
                ldx #0
                ldy #24
                jsr setxy
                ldx #<devicetext
                ldy #>devicetext
                jsr printtext
                lda drivenumber
                jsr printhex8
dm_wait:        jsr getkey
                beq dm_wait
                cmp #"C"
                bne dm_nodrivechg
                lda drivenumber
                clc
                adc #$01
                cmp #$20
                bcc dm_notover
                lda #$08
dm_notover:     sta drivenumber
                jmp diskmenu2
dm_nodrivechg:  cmp #"C"+$80
                bne dm_nodrivechg2
                lda drivenumber
                sec
                sbc #$01
                cmp #$08
                bcs dm_notover2
                lda #$1f
dm_notover2:    sta drivenumber
                jmp diskmenu2
dm_nodrivechg2: cmp #"N"
                beq dm_nuke
                cmp #"X"
                beq dm_exit
                cmp #"L"
                bne dm_noload
                jsr loadsong
                lda desthi
                cmp #>savesongend
                bcc dm_noloadend
                lda #$01
                jsr convertdurations
dm_noloadend:   jmp dm_wait
dm_noload:      cmp #"S"
                bne dm_nosave
                lda #$ff
                jsr convertdurations
                jsr savesong
                lda #$01
                jsr convertdurations
                jmp dm_wait
dm_nosave:      cmp #"E"
                bne dm_noerase
                jsr erasefile
                jmp dm_wait
dm_noerase:     cmp #"D"
                bne dm_nodir
                jsr directory
                jmp diskmenu
dm_nodir:       cmp #"G"
                bne dm_noglobals
                jsr globalsettings
                jmp diskmenu2
dm_noglobals:   cmp #"P"
                bne dm_exitmenu
                jsr packrelocate
                jmp diskmenu
dm_exitmenu:    jmp initscreen

dm_exit:        jsr confirm
                cmp #"Y"
                beq dm_exit2
                jmp diskmenu2
dm_exit2:       jmp 64738

dm_nuke:        jsr confirm
                cmp #"Y"
                beq dm_nuke2
                jmp diskmenu2
dm_nuke2:       jsr stop
                jsr cleardata
                jmp dm_exitmenu

;-------------------------------------------------------------------------------
; Print drive error status
;-------------------------------------------------------------------------------

printerrorstatus:
                lda #15
                ldx drivenumber
                ldy #15
                jsr setlfs
                lda #0
                jsr setnam
                jsr open
                bcs printsterror
                ldx #15
                jsr chkin
                ldy #0
printstloop:    jsr chrin
                cmp #KEY_RETURN
                beq printstdone
                sta $0400+24*40,y
                lda normalcol
                sta $d800+24*40,y
                iny
                jmp printstloop
printstdone:    lda #15
                jsr close
                ldx #0
                jmp chkin
printsterror:   ldx #0
                jsr chkin
                rts

;-------------------------------------------------------------------------------
; Load song data
;-------------------------------------------------------------------------------

loadsong:       lda #<savesongstart
                sta destlo
                lda #>savesongstart
                sta desthi
                lda #MSG_LOAD
                jsr askname
                lda namelength
                bne loadok
                rts
loadok:         lda #$02
                ldy #$00
                ldx drivenumber
                jsr setlfs
                lda namelength
                ldx #<name
                ldy #>name
                jsr setnam
                jsr open
                ldx #$02
                jsr chkin
                jsr chrin
                ldx status
                bne loaderror
                cmp #"N"
                bne loaderror
                jsr chrin
                cmp #"2"
                bne loaderror
loadloop:       jsr loadbyte
                cmp #ESCBYTE
                beq loadblock
                jsr storebyte
                jmp loadloop
loadblock:      jsr loadbyte
                sta var1
                jsr loadbyte
                tax
                lda var1
loadblockloop:  jsr storebyte
                dex
                bne loadblockloop
                jmp loadloop

loadbyte:       stx loadbytex+1
                sty loadbytey+1
                ldx status
                bne loadfileend
                jsr chrin
                ldx emptycol
                stx $d020
                ldx bgcol
                stx $d020
loadbytex:      ldx #$00
loadbytey:      ldy #$00
                rts
loadfileend:    jsr reseteditor
                pla
                pla
loaderror:      lda #$02
                jsr close
                jsr clrchn
                jmp printerrorstatus

storebyte:      ldy #$00
                sta (destlo),y
incdest:        inc destlo
                bne storebyte2
                inc desthi
storebyte2:     rts

;-------------------------------------------------------------------------------
; Save song data
;-------------------------------------------------------------------------------

savesong:       lda #MSG_SAVE
                jsr askname
                lda namelength
                bne saveok
                rts
saveok:         jsr stop
                jsr savecommon
                lda #"N"                ;Identification
                jsr savebyte
                lda #"2"
                jsr savebyte
                lda #<savesongstart
                sta destlo
                lda #>savesongstart
                sta desthi
                ldx savesongend-1       ;Make sure the packed-block
                inx                     ;save doesn't overshoot
                stx savesongend
saveloop:       ldy #$00
                lda (destlo),y
                iny
                cmp (destlo),y
                beq savepacked
                cmp #ESCBYTE
                beq saveliteral
savestore:      jsr savebyte
savenext:       tya
                jsr adddest
                lda destlo
                cmp #<savesongend
                bne saveloop
                lda desthi
                cmp #>savesongend
                bne saveloop
                jmp savedone
saveliteral:    lda #ESCBYTE
                jsr savebyte
                jsr savebyte
                lda #$01
                jsr savebyte
                jmp savenext
savepacked:     lda #ESCBYTE
                jsr savebyte
                ldy #$00
                lda (destlo),y
                sta var1
                jsr savebyte
                ldy #$00
savepackedlen:  iny
                cpy #$ff
                beq savepackedready
                lda (destlo),y
                cmp var1
                beq savepackedlen
savepackedready:tya
                jmp savestore

savebyte:       stx savebytex+1
                sty savebytey+1
                jsr chrout
                ldx status
                bne saveerror
                ldx emptycol
                stx $d020
                ldx bgcol
                stx $d020
savebytex:      ldx #$00
savebytey:      ldy #$00
                rts
saveerror:      pla
                pla
savedone:       jmp loaderror

saveblock:      sta destlo
                stx desthi
saveblockdirect:tya
                beq sbdone
                sty sbcmp+1
                ldy #$00
sbloop:         lda (destlo),y
                jsr savebyte
                iny
sbcmp:          cpy #$00
                bne sbloop
sbdone:         rts

savecommon:     lda #15
                ldx drivenumber
                ldy #15
                jsr setlfs
                clc
                lda namelength
                adc #$03
                ldx #<scratch
                ldy #>scratch
                jsr setnam
                jsr open
                lda #15
                jsr close
                lda #$02
                ldy #$01
                ldx drivenumber
                jsr setlfs
                lda namelength
                ldx #<name
                ldy #>name
                jsr setnam
                lda namelength
                jsr open
                ldx #$02
                jmp chkout

;-------------------------------------------------------------------------------
; Erase a file
;-------------------------------------------------------------------------------

erasefile:      lda #MSG_ERASE
                jsr askname
                lda namelength
                bne erase_ok
                rts
erase_ok:       lda #15
                ldx drivenumber
                ldy #15
                jsr setlfs
                clc
                lda namelength
                adc #$03
                ldx #<scratch
                ldy #>scratch
                jsr setnam
                jsr open
                lda #15
                jsr close
                jmp printerrorstatus

;-------------------------------------------------------------------------------
; Print directory
;-------------------------------------------------------------------------------

dir_end:        lda #$02
                jsr close
                jsr clrchn
dir_wait:       jsr getkey
                beq dir_wait
                rts
directory:      jsr clearscreen
                lda #$02
                ldy #$00
                ldx drivenumber
                jsr setlfs
                lda #$01
                ldx #<dirname
                ldy #>dirname
                jsr setnam
                jsr open
                ldx #$02
                jsr chkin
                lda #27
                sta $d011
                clc
                ldx #$00
                ldy #$00
                jsr plot
                lda #$0c
                sta 646
                jsr chrin
                jsr chrin
dir_loop:       lda status
                bne dir_end
                jsr chrin
                cmp #$01
                bne dir_loop
                jsr chrin
                lda status
                bne dir_end
                jsr chrin
                sta textlo
                jsr chrin
                sta texthi
                lda #$00
                sta dirprintnum
                tay
dir_100loop:    lda texthi
                cmp #>100
                beq dir_100cl
                bcs dir_100ok
                bcc dir_100quit
dir_100cl:      lda textlo
                cmp #<100
                bcs dir_100ok
                bcc dir_100quit
dir_100ok:      iny
                sec
                lda textlo
                sbc #<100
                sta textlo
                lda texthi
                sbc #>100
                sta texthi
                jmp dir_100loop
dir_100quit:    tya
                clc
                adc #"0"
                cmp #"0"
                beq dir_10
                jsr chrout
                inc dirprintnum
dir_10:         ldy #$00
dir_10loop:     lda texthi
                cmp #>10
                beq dir_10cl
                bcs dir_10ok
                bcc dir_10quit
dir_10cl:       lda textlo
                cmp #<10
                bcs dir_10ok
                bcc dir_10quit
dir_10ok:       iny
                sec
                lda textlo
                sbc #<10
                sta textlo
                lda texthi
                sbc #>10
                sta texthi
                jmp dir_10loop
dir_10quit:     tya
                clc
                adc #"0"
                ldy dirprintnum
                bne dir_10pr
                cmp #"0"
                beq dir_10np
dir_10pr:       jsr chrout
dir_10np:       lda textlo
                clc
                adc #"0"
                jsr chrout
                lda #$20
                jsr chrout
dir_loop3:      lda status
                bne dir_end2
                jsr chrin
                cmp #$00
                bne dir_noline
                lda #13
                jsr chrout
                jmp dir_loop
dir_noline:     jsr chrout
                jmp dir_loop3
dir_end2:       jmp dir_end

;-------------------------------------------------------------------------------
; Ask for filename
;-------------------------------------------------------------------------------

askname:        tay
                asl
                tax
                lda namemsgtbl,x
                sta textlo
                lda namemsgtbl+1,x
                sta texthi
                lda namemsglentbl,y
                sta var1
                lda #$00
                sta namelength
                ldx #$0f
                lda #$20
askname1:       sta name,x
                dex
                bpl askname1
                ldx #0
                ldy #24
                jsr setxy
                jsr printtextcont
asknameloop:    ldx var1
                ldy #24
                jsr setxy
                ldx #<name
                ldy #>name
                jsr printtext
                lda namelength
                clc
                adc var1
                tax
                ldy #24
                lda #$00
                jsr cursorpos
askname_getkey: jsr getkey
                beq askname_getkey
                cmp #KEY_RUNSTOP
                beq askname_quit
                cmp #KEY_RETURN
                beq askname_end
                cmp #KEY_DEL
                bne askname_nodel
                lda namelength
                beq asknameloop
                dec namelength
                ldx namelength
                lda #$20
                sta name,x
                jmp asknameloop
askname_nodel:  cmp #$20
                bcc asknameloop
                and #$3f
                ldx namelength
                cpx #$10
                bcs asknameloop
                sta name,x
                inc namelength
                jmp asknameloop
askname_end:    ldx #$0f
askname_final:  lda name,x
                cmp #$20
                bcs askname_final2
                ora #$40
                sta name,x
askname_final2: dex
                bpl askname_final
askname_final3: lda #$00
                sta $d015
                jmp clearbottomrow
askname_quit:   lda #$00
                sta namelength
                beq askname_final3

;-------------------------------------------------------------------------------
; Confirm activity
;-------------------------------------------------------------------------------

confirm:        jsr clearbottomrow
                ldx #0
                ldy #24
                jsr setxy
                ldx #<confirmtext
                ldy #>confirmtext
                jsr printtext
confirm_getkey: jsr getkey
                beq confirm_getkey
clearbottomrow: pha
                ldy #24
                jsr printemptyrow
                pla
                rts

;-------------------------------------------------------------------------------
; Adjust global settings
;-------------------------------------------------------------------------------

globalsettings:
gsloop:         jsr gsdisplay
                jsr getkey
                cmp #"G"
                beq gsexit
                cmp #KEY_RETURN
                beq gsexit
                cmp #KEY_RUNSTOP
                beq gsexit
                cmp #KEY_UP
                beq gsup
                cmp #KEY_DOWN
                beq gsdown
                cmp #KEY_LEFT
                beq gsleft
                cmp #KEY_RIGHT
                beq gsright
gsedit:         lda #<hrparam
                clc
                adc globalrow
                sta destlo
                lda #>hrparam
                adc #$00
                sta desthi
                ldx globalcol
                jsr hexedit
                bcs gsright
                bcc gsloop
gsup:
gsdown:         lda globalrow
                eor #$01
                sta globalrow
                jmp gsloop
gsleft:         lda globalcol
                eor #$01
                sta globalcol
                bne gsup
                beq gsloop
gsright:        lda globalcol
                eor #$01
                sta globalcol
                beq gsdown
                bne gsloop
gsexit:         lda #$00
                sta $d015
                ldy #12
                jsr printemptyrow
                ldy #13
                jsr printemptyrow
copyglobalsettings:
                lda hrparam
                sta nt_hrparam+1
                sta playerstart+vhrparam+1-vplayer
                lda firstwave
                sta nt_firstwave+1
                sta playerstart+vfirstwave+1-vplayer
                rts

gsdisplay:      ldx #0
                ldy #12
                jsr setxy
                ldx #<globaltext
                ldy #>globaltext
                jsr printtext
                lda hrparam
                jsr printhex8
                ldx #0
                ldy #13
                jsr setxy
                jsr printtextcont
                lda firstwave
                jsr printhex8
                lda globalrow
                clc
                adc #12
                tay
                lda globalcol
                adc #15
                tax
                lda #$00
                jmp cursorpos

;-------------------------------------------------------------------------------
; Clear all song data
;-------------------------------------------------------------------------------

cleardata:      lda #DEFAULT_HRPARAM
                sta hrparam
                lda #DEFAULT_FIRSTWAVE
                sta firstwave
                ldx #$00
                txa
clrd_tables:    sta nt_tables,x
                sta nt_tables+$100,x
                sta nt_tables+$200,x
                sta nt_tables+$300,x
                sta nt_tables+$400,x
                sta nt_tables+$500,x
                inx
                cpx #MAX_TBLLEN
                bne clrd_tables
                sta tbllen
                sta tbllen+1
                sta tbllen+2
                sta cmdlen
                jsr converttables
                ldx #$00
clrd_patterns:  lda nt_patttbllo,x
                sta destlo
                lda nt_patttblhi,x
                sta desthi
                lda #$00
clrd_commands:  sta nt_cmdad,x
                sta nt_cmdsr,x
                sta nt_cmdwavepos,x
                sta nt_cmdpulsepos,x
                sta nt_cmdfiltpos,x
                tay
clrd_patterns2: sta (destlo),y
                iny
                cpy #MAX_PATTLEN
                bne clrd_patterns2
                inx
                cpx #MAX_PATT
                bne clrd_patterns
                lda #KEYOFF+$02
                sta nt_patterns
                lda #$c2
                sta nt_patterns+1
                ldx #$00
clrd_songs:     txa
                sta alo
                asl
                asl
                adc alo
                tay
                lda nt_songtbl,y
                sta destlo
                lda nt_songtbl+1,y
                sta desthi
                txa
                sta alo
                asl
                adc alo
                tay
                lda #$00
                sta songlen,y
                sta songlen+1,y
                sta songlen+2,y
                tay
clrd_songs2:    sta (destlo),y
                iny
                bne clrd_songs2
                inx
                cpx #MAX_SONGS
                bne clrd_songs
                lda #$01
                sta nt_tracks
                sta nt_tracks+3
                sta nt_tracks+6
                lda #$03
                sta nt_tracks+5
                lda #$06
                sta nt_tracks+8
                lda #$03
                sta songlen
                sta songlen+1
                sta songlen+2
                lda #<nt_cmdnames
                sta destlo
                lda #>nt_cmdnames
                sta desthi
                ldx #$00
clrd_names:     lda #$20
                ldy #$00
clrd_names2:    sta (destlo),y
                iny
                cpy #MAX_CMDNAMELEN
                bne clrd_names2
                lda destlo
                adc #MAX_CMDNAMELEN         ;C=1 here, so add one more
                sta destlo                  ;skipping the endzero
                lda desthi
                adc #$00
                sta desthi
                inx
                cpx #MAX_CMD
                bne clrd_names
clrd_nameskip:  jmp reseteditor

;-------------------------------------------------------------------------------
; Online help
;-------------------------------------------------------------------------------

onlinehelp:     jsr stop
                jsr clearscreen
                lda #<onlinehelptext
                sta textlo
                lda #>onlinehelptext
                sta texthi
                ldx #$00
                lda #$0f
ohr_setcolors:  sta $d800,x
                sta $d900,x
                sta $da00,x
                sta $db00,x
                inx
                bne ohr_setcolors
oh_redraw:      sei
                lda #$34
                sta $01
                ldy #$00
ohr_loop1:      lda (textlo),y
                cmp #96
                bcc ohr_nolower1
                sbc #96
ohr_nolower1:   sta $0400,y
                iny
                bne ohr_loop1
                inc texthi
ohr_loop2:      lda (textlo),y
                cmp #96
                bcc ohr_nolower2
                sbc #96
ohr_nolower2:   sta $0500,y
                iny
                bne ohr_loop2
                inc texthi
ohr_loop3:      lda (textlo),y
                cmp #96
                bcc ohr_nolower3
                sbc #96
ohr_nolower3:   sta $0600,y
                iny
                bne ohr_loop3
                inc texthi
ohr_loop4:      lda (textlo),y
                cmp #96
                bcc ohr_nolower4
                sbc #96
ohr_nolower4:   sta $0700,y
                iny
                bne ohr_loop4
                lda texthi
                sec
                sbc #$03
                sta texthi
                lda #$36
                sta $01
                cli
oh_keyloop:     jsr getkey
                beq oh_keyloop
                cmp #KEY_UP
                bne oh_notup
                lda textlo
                cmp #<onlinehelptext
                bne oh_upok
                lda texthi
                cmp #>onlinehelptext
                bne oh_upok
                jmp oh_keyloop
oh_upok:        lda textlo
                sec
                sbc #40
                sta textlo
                bcs oh_upok2
                dec texthi
oh_upok2:       jmp oh_redraw
oh_notup:       cmp #KEY_DOWN
                bne oh_notdown
                lda textlo
                cmp #<onlinehelpend
                bne oh_downok
                lda texthi
                cmp #>onlinehelpend
                bne oh_downok
                jmp oh_keyloop
oh_downok:      lda textlo
                clc
                adc #40
                sta textlo
                bcc oh_downok2
                inc texthi
oh_downok2:     jmp oh_redraw
oh_notdown:
oh_quit:        jmp initscreen

;-------------------------------------------------------------------------------
; Color scheme adjustment
;-------------------------------------------------------------------------------

adjustcolors:   ldx #17
                lda #$20
acclear:        sta $0400,x
                dex
                bpl acclear
acloop:         lda acnum
                asl
                tax
                ldy #0
                tya
                jsr cursorpos
                lda #MAX_COLORS-1
                tax
                asl
                sta var1
acdisplay:      lda bgcol,x
                and #$0f
                tay
                lda hexcodes,y
                ldy var1
                sta $0400,y
                lda bgcol,x
                sta $d800,y
                dec var1
                dec var1
                dex
                bpl acdisplay
acwait:         jsr getkey
                beq acwait
                cmp #KEY_LEFT
                bne acnotleft
                dec acnum
                bpl acnotleft
                ldx #MAX_COLORS-1
                stx acnum
acnotleft:      cmp #KEY_RIGHT
                bne acnotright
                inc acnum
                ldx acnum
                cpx #MAX_COLORS
                bcc acnotright
                ldx #0
                stx acnum
acnotright:     cmp #KEY_UP
                bne acnotup
                ldx acnum
                inc bgcol,x
accommon:       jsr changecolors
acnoexit:       jmp acloop
acnotup:        cmp #KEY_DOWN
                bne acnotdown
                ldx acnum
                dec bgcol,x
                bcs accommon
acnotdown:      cmp #KEY_RETURN
                beq acexit
                cmp #KEY_RUNSTOP
                beq acexit
                cmp #KEY_F6
                bne acnoexit
acexit:         lda #$00
                sta $d015
                jmp changecolors2

;-------------------------------------------------------------------------------
; Get default device number
;-------------------------------------------------------------------------------

detectdevice:   lda fa                      ;Find out drive number
                cmp #$08
                bcs driveok
                lda #$08
driveok:        sta drivenumber
                rts
