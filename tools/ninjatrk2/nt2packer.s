;-------------------------------------------------------------------------------
; Packer/Relocator
;-------------------------------------------------------------------------------

prlabort:       rts
packrelocate:   jsr stop
                jsr clearscreen
                lda titlecol
                sta textcolor
                ldx #0
                ldy #0
                jsr setxy
                lda #<packtext1
                sta textlo
                lda #>packtext1
                sta texthi
                jsr printtextcont
                lda normalcol
                sta textcolor
                ldx #0
                ldy #2
                jsr setxy
                jsr printtextcont
prl1:           jsr getkey
                cmp #KEY_RUNSTOP
                beq prlabort
                ldx #$00
                cmp #"N"
                beq prl1ok
                cmp #"G"
                bne prl1
                inx
prl1ok:         stx relocmode               ;0 = normal, 1 = gamemusic
                jsr printchar
                ldx relocmode
                beq prlnogamemode
                lda #$00                    ;For Steel Ranger - calculate gamemusic reloc
                sta relochi                 ;address from $d000 (spritecache) down
                sta reloclo
                jsr getrelocdatasize
                lda #$00
                sec
                sbc relocendlo
                sta reloclo
                lda #$d0
                sbc relocendhi
                sta relochi
prlnogamemode:  ldx #0
                ldy #3
                jsr setxy
                jsr printtextcont
prl2:           ldx #14
                ldy #3
                jsr setxy
                ldx reloclo
                ldy relochi
                jsr printhex16
prl2wait:       jsr getkey
                beq prl2wait
                cmp #KEY_DOWN
                bne prl2not1
                dec relochi
prl2not1:       cmp #KEY_UP
                bne prl2not2
                inc relochi
prl2not2:       cmp #KEY_LEFT
                bne prl2not3
                dec reloclo
                ldx reloclo
                cpx #$ff
                bne prl2not3
                dec relochi
prl2not3:       cmp #KEY_RIGHT
                bne prl2not4
                inc reloclo
                bne prl2not4
                inc relochi
prl2not4:       cmp #KEY_RUNSTOP
                beq prlabort2
                cmp #KEY_RETURN
                beq prl2ok
                bne prl2
prlabort2:      rts
prl2ok:         lda relocmode
                bne prl3ok
                ldx #0
                ldy #4
                jsr setxy
                jsr printtextcont
prl3:           ldx #14
                ldy #4
                jsr setxy
                lda reloczp
                jsr printhex8
prl3wait:       jsr getkey
                beq prl3wait
                cmp #KEY_DOWN
                beq prl3dec
                cmp #KEY_LEFT
                bne prl3not1
prl3dec:        dec reloczp
prl3not1:       cmp #KEY_UP
                beq prl3inc
                cmp #KEY_RIGHT
                bne prl3not2
prl3inc:        inc reloczp
prl3not2:       cmp #KEY_RUNSTOP
                beq prlabort2
                cmp #KEY_RETURN
                bne prl3
prl3ok:         jsr getrelocdatasize

                lda relocmode               ;Print data size results:
                beq prresnormal             ;normal or gamemusic
prresgame:      ldx #0
                ldy #5
                jsr setxy
                ldx #<packres3
                ldy #>packres3
                jsr printtext
                jmp rrescommon

prresnormal:    ldx #0
                ldy #6
                jsr setxy
                ldx #<packres1
                ldy #>packres1
                jsr printtext
                ldx playersizelo
                ldy playersizehi
                jsr printhex16
                ldx #0
                ldy #7
                jsr setxy
                jsr printtextcont
                lda relocendlo
                sec
                sbc wavetbladrlo
                tax
                lda relocendhi
                sbc wavetbladrhi
                tay
                jsr printhex16
                ldx #0
                ldy #8
                jsr setxy
                jsr printtextcont
rrescommon:     lda relocendlo
                sec
                sbc reloclo
                tax
                lda relocendhi
                sbc relochi
                tay
                jsr printhex16
                lda #MSG_PACKER
                jsr askname
                lda namelength
                bne prnameok
                rts

prnameok:       jsr converttables           ;Make sure we have fresh tables
                jsr savecommon              ;Open file
                lda reloclo                 ;Save startaddress
                jsr savebyte
                lda relochi
                jsr savebyte
                lda relocmode
                beq prsavenormal

prsavegame:     lda #<gamedatastart         ;Gamemusic mode: save the header
                ldx #>gamedatastart         ;with lengths of data sections
                ldy #6
                jsr saveblock
                jmp prsavecommon

prsavenormal:   lda #<playerstart
                sta destlo
                lda #>playerstart
                sta desthi
prplayercode:   ldy #$00
                lda (destlo),y              ;Take instruction
                sta prinstrcmp+1
                jsr savebyte                ;Save it
                lda #<asmtable
                sta srclo
                lda #>asmtable
                sta srchi
prinstrloop:    lda (srclo),y
prinstrcmp:     cmp #$00
                beq prinstrfound
                cmp #$ff
                beq prunknown
                lda #2
                jsr addsrc
                jmp prinstrloop
prunknown:      inc $d020                   ;Something went wrong
                jmp prunknown
prinstrfound:   iny
                lda (srclo),y
                cmp #1
                beq pronebyte               ;One byte?
                cmp #2
                beq prtwobyte               ;Two bytes (no relocation)?
                cmp #3
                beq prabsolute              ;Three bytes (absolute relocation)?
przeropage:     lda (destlo),y
                adc reloczp
                jmp prtwobytecommon
prtwobyte:      lda (destlo),y
prtwobytecommon:jsr savebyte
                lda #2
pronebyte:      jsr adddest
                lda destlo                  ;Arrived at end of playercode?
                cmp #<(playerstart+vfreqtbl-vinit)
                bne prplayercode
                lda desthi
                cmp #>(playerstart+vfreqtbl-vinit)
                bne prplayercode
                jmp prplayerdata
prabsolute:     lda (destlo),y              ;Take address
                sta alo
                iny
                lda (destlo),y
                sta ahi
                cmp #$d4                    ;SID?
                beq prabsok
                sbc #(>vplayer)-1
                lsr
                lsr
                tax                         ;Take fixup type
                lda ahi
                and #$03
                sta ahi
                cmp #$03                    ;Check for negative access
                bcc prnotneg                ;(wavetbl-1 for example)
                lda alo
                cmp #$f0
                bcc prnotneg
                inx                         ;Adjust fixup and make
                lda #$ff                    ;highbyte negative
                sta ahi
prnotneg:       lda relocadrtbllo,x         ;Add fixup start
                clc                         ;to address
                adc alo
                sta alo
                lda relocadrtblhi,x
                adc ahi
                sta ahi
prabsok:        lda alo                     ;Save address
                jsr savebyte
                lda ahi
                jsr savebyte
                lda #3
                bne pronebyte

prplayerdata:   ldy #$00
                lda (destlo),y
                jsr savebyte
                jsr incdest
                lda destlo                  ;Arrived at end of player data?
                cmp #<playerend
                bne prplayerdata
                lda desthi
                cmp #>playerend
                bne prplayerdata

prsavecommon:   lda #<nt_wavetbl
                ldx #>nt_wavetbl
                ldy tbllen
                jsr saveblock
                lda #<nt_notetbl
                ldx #>nt_notetbl
                ldy tbllen
                jsr saveblock
                lda #<nt_pulsetimetbl
                ldx #>nt_pulsetimetbl
                ldy tbllen+1
                jsr saveblock
                lda #<nt_pulsespdtbl
                ldx #>nt_pulsespdtbl
                ldy tbllen+1
                jsr saveblock
                lda #<nt_filttimetbl
                ldx #>nt_filttimetbl
                ldy tbllen+2
                jsr saveblock
                lda #<nt_filtspdtbl
                ldx #>nt_filtspdtbl
                ldy tbllen+2
                jsr saveblock

                lda #<nt_cmdad
                ldx #>nt_cmdad
                ldy lastcmd
                jsr saveblock
                lda #<nt_cmdsr
                ldx #>nt_cmdsr
                ldy lastcmd
                jsr saveblock
                lda #<nt_cmdwavepos
                ldx #>nt_cmdwavepos
                ldy lastlegatocmd
                jsr saveblock
                lda #<nt_cmdpulsepos
                ldx #>nt_cmdpulsepos
                ldy lastlegatocmd
                jsr saveblock
                lda #<nt_cmdfiltpos
                ldx #>nt_cmdfiltpos
                ldy lastlegatocmd
                jsr saveblock

                lda pattadrlo
                sta alo
                lda pattadrhi
                sta ahi
                ldx #$ff
prpatttbllo:    inx
                lda alo
                jsr savebyte
                jsr getpattsize
                jsr add16
                cpx lastpatt
                bne prpatttbllo

                lda pattadrlo
                sta alo
                lda pattadrhi
                sta ahi
                ldx #$ff
prpatttblhi:    inx
                lda ahi
                jsr savebyte
                jsr getpattsize
                jsr add16
                cpx lastpatt
                bne prpatttblhi

                lda trackadrlo
                sta alo
                lda trackadrhi
                sta ahi
                ldx #$ff
prsongtbl:      inx
                lda alo
                jsr savebyte
                lda ahi
                jsr savebyte
                txa
                sta var1
                asl
                adc var1
                tay
                lda #$00
                jsr savebyte
                lda songlen,y
                jsr savebyte
                lda songlen,y
                clc
                adc songlen+1,y
                jsr savebyte
                lda songlen,y
                jsr add16
                lda songlen+1,y
                jsr add16
                lda songlen+2,y
                jsr add16
                cpx lastsong
                bne prsongtbl

                ldx #$ff
prpatt:         inx
                jsr getpattsize
                jsr saveblockdirect
                cpx lastpatt
                bne prpatt

                ldx #$ff
prtracks:       inx
                txa
                sta var1
                asl
                asl
                adc var1
                tay
                lda nt_songtbl,y
                sta destlo
                lda nt_songtbl+1,y
                sta desthi
                lda var1
                asl
                adc var1
                tay
                lda songlen,y
                sta alo
                lda #$00
                sta ahi
                lda songlen+1,y
                jsr add16
                lda songlen+2,y
                jsr add16
                ldy alo
                lda ahi
                bne prtrackfull
                jsr saveblockdirect
                cpx lastsong
                bne prtracks
                jmp savedone
prtrackfull:    lda (destlo),y
                jsr savebyte
                iny
                bne prtrackfull
                cpx lastsong
                bne prtracks
                jmp savedone

addpattsize:    clc
                adc pattsizelo
                sta pattsizelo
                bcc apsok
                inc pattsizehi
apsok:          rts

;-------------------------------------------------------------------------------
; Get relocation data end address
;-------------------------------------------------------------------------------

getrelocdatasize:
                ldx #<(playerend-playerstart) ;Store length of player
                ldy #>(playerend-playerstart)
                lda relocmode
                beq plrsizeok
                ldx #<(gamedataend-gamedatastart)
                ldy #>(gamedataend-gamedatastart)
plrsizeok:      stx playersizelo
                sty playersizehi
                lda tbllen                  ;Store length of tables
                sta wavetblsizelo
                sta notetblsizelo
                sta gamewavetblsize
                lda tbllen+1
                sta pulsetimetblsizelo
                sta pulsespdtblsizelo
                sta gamepulsetblsize
                lda tbllen+2
                sta filttimetblsizelo
                sta filtspdtblsizelo
                sta gamefilttblsize

                lda #$00                    ;Find out last used pattern,
                sta pattsizelo              ;last used cmd/legatocmd,
                sta pattsizehi              ;and total size of patterns
                sta lastcmd
                sta lastlegatocmd
                ldx #MAX_PATT-1
ptsizeloop:     jsr getpattsize
                bne ptsizefound
                dex
                cpx #$ff
                bne ptsizeloop
                ldx #$00
ptsizefound:    stx lastpatt
ptsizeloop2:    jsr getpattsize
                jsr addpattsize
ptsizenotover:  dex
                cpx #$ff
                bne ptsizeloop2
                lda lastcmd
                cmp lastlegatocmd
                bcc numlegatook
                sta lastlegatocmd
numlegatook:

ptsizeok:       lda lastcmd                 ;Store length of command tables
                sta cmdadsizelo
                sta cmdsrsizelo
                sta gamecmdsize
                lda lastlegatocmd
                sta cmdwavesizelo
                sta cmdpulsesizelo
                sta cmdfiltsizelo
                sta gamelegatocmdsize

                ldx lastpatt              ;Store length of pattern table
                inx
                stx patttbllosizelo
                stx patttblhisizelo
                stx gamepatttblsize

                lda #$00                  ;Find out last used song and
                sta destlo                ;total size of tracks
                sta desthi
                ldx #MAX_SONGS-1
                ldy #(MAX_SONGS-1)*3
trsizeloop:     lda songlen,y
                ora songlen+1,y
                ora songlen+2,y
                bne trsizefound
                dey
                dey
                dey
                dex
                bpl trsizeloop
                ldx #$00
                ldy #$00
trsizefound:    stx lastsong
trsizeloop2:    lda songlen,y
                jsr adddest
                lda songlen+1,y
                jsr adddest
                lda songlen+2,y
                jsr adddest
                dey
                dey
                dey
                dex
                bpl trsizeloop2
                lda destlo
                sta tracksizelo
                lda desthi
                sta tracksizehi

                ldy lastsong                ;Store length of song table
                iny
                lda #5
                jsr mulu
                lda alo
                sta songtblsizelo

                lda reloclo
                sta playeradrlo
                lda relochi
                sta playeradrhi
                ldx #$00
calcadrloop:    lda relocadrtbllo,x         ;Calculate addresses when
                clc                         ;all lengths are known
                adc relocsizetbllo,x
                sta relocadrtbllo+1,x
                lda relocadrtblhi,x
                adc relocsizetblhi,x
                sta relocadrtblhi+1,x
                inx
                cpx #MAX_RELOCITEMS
                bcc calcadrloop
                rts

;-------------------------------------------------------------------------------
; Get size of pattern
; X=Pattern number
;-------------------------------------------------------------------------------

getpattsize:    lda nt_patttbllo,x
                sta destlo
                lda nt_patttblhi,x
                sta desthi
                ldy #$00
gpsloop:        lda (destlo),y
                beq gpsdone
                iny
                cmp #$c0
                bcs gpsloop
                cmp #FIRSTNOTE
                bcc gpsgatectrl
gpsnote:        lsr
                bcc gpsloop
gpscmd:         lda (destlo),y
                bpl gpshrcmd
gpslegatocmd:   iny
                and #$7f
                cmp lastlegatocmd
                bcc gpsloop
                sta lastlegatocmd
                bcs gpsloop
gpshrcmd:       iny
                cmp lastcmd
                bcc gpsloop
                sta lastcmd
                bcs gpsloop
gpsgatectrl:    and #$02
                beq gpscmd
                bne gpsloop
gpsdone:        cpy #$00
                beq gpszero
                iny
gpszero:        tya
                rts

;-------------------------------------------------------------------------------
; Playroutine for relocation
;-------------------------------------------------------------------------------

playerstart:

vplayer         = $1000
vwavetbl        = $1400
vnotetbl        = $1800
vpulsetimetbl   = $1c00
vpulsespdtbl    = $2000
vfilttimetbl    = $2400
vfiltspdtbl     = $2800
vcmdad          = $2c00
vcmdsr          = $3000
vcmdwavepos     = $3400
vcmdpulsepos    = $3800
vcmdfiltpos     = $3c00
vpatttbllo      = $4000
vpatttblhi      = $4400
vsongtbl        = $4800
vpatterns       = $4c00
vsong           = $5000

vtemp1          = $00
vtemp2          = $01

                rorg vplayer

vinit:          jmp vstoreinit
vplay:          ldx #$00
vinitsongnum:   lda #$00
                bmi vfiltpos

        ;New song initialization

                asl
                asl
                adc vinitsongnum+1
                tay
                lda vsongtbl,y
                sta vtracklo+1
                lda vsongtbl+1,y
                sta vtrackhi+1
                txa
                sta vfiltpos+1
                sta $d417
                ldx #21
vinitloop:      sta vchnpattpos-1,x
                dex
                bne vinitloop
                jsr vinitchn
                ldx #$07
                jsr vinitchn
                ldx #$0e
vinitchn:       lda vsongtbl+2,y
                sta vchnsongpos,x
                iny
                lda #$ff
                sta vchnnewnote,x
                sta vchnduration,x
                sta vchntrans,x
vstoreinit:     sta vinitsongnum+1
                rts

          ;Filter execution

vfiltpos:       ldy #$00
                beq vfiltdone
                lda vfilttimetbl-1,y
                bpl vfiltmod
                cmp #$ff
                bcs vfiltjump
vsetfilt:       sta $d417
                and #$70
                sta vfiltdone+1
vfiltjump:      lda vfiltspdtbl-1,y
                bcs vfiltjump2
vnextfilt:      inc vfiltpos+1
                bcc vstorecutoff
vfiltjump2:     sta vfiltpos+1
                bcs vfiltdone
vfiltmod:       clc
                dec vfilttime
                bmi vnewfiltmod
                bne vfiltcutoff
                inc vfiltpos+1
                bcc vfiltdone
vnewfiltmod:    sta vfilttime
vfiltcutoff:    lda #$00
                adc vfiltspdtbl-1,y
vstorecutoff:   sta vfiltcutoff+1
                sta $d416
vfiltdone:      lda #$00
                ora #$0f
                sta $d418

        ;Channel execution

                jsr vchnexec
                ldx #$07
                jsr vchnexec
                ldx #$0e

        ;Update duration counter

vchnexec:       inc vchncounter,x
                bne vnopattern

        ;Get data from pattern

vpattern:       ldy vchnpattnum,x
                lda vpatttbllo-1,y
                sta vtemp1
                lda vpatttblhi-1,y
                sta vtemp2
                ldy vchnpattpos,x
                lda (vtemp1),y
                lsr
                sta vchnnewnote,x
                bcc vnonewcmd
vnewcmd:        iny
                lda (vtemp1),y
                sta vchncmd,x
                bcc vrest
vcheckhr:       bmi vrest
                lda #$fe
                sta vchngate,x
                sta $d405,x
vhrparam:       lda #$00
                sta $d406,x
vrest:          iny
                lda (vtemp1),y
                cmp #$c0
                bcc vnonewdur
                iny
                sta vchnduration,x
vnonewdur:      lda (vtemp1),y
                beq vendpatt
                tya
vendpatt:       sta vchnpattpos,x
                jmp vwaveexec

        ;No new command, or gate control

vnonewcmd:      cmp #FIRSTNOTE/2
                bcc vgatectrl
                lda vchncmd,x
                bcs vcheckhr
vgatectrl:      lsr
                ora #$fe
                sta vchngate,x
                bcc vnewcmd
                sta vchnnewnote,x
                bcs vrest

        ;No new pattern data

vlegatocmd:     tya
                and #$7f
                tay
                bpl vskipadsr

vjumptopulse:   jmp vpulseexec
vnopattern:     lda vchncounter,x
                cmp #$02
                bne vjumptopulse

        ;Reload counter and check for new note / command exec / track access

vreload:        lda vchnduration,x
                sta vchncounter,x
                lda vchnnewnote,x
                bpl vnewnoteinit
                lda vchnpattpos,x
                bne vjumptopulse
                
         ;Get data from track

vtrack:  
vtracklo:       lda #$00
                sta vtemp1
vtrackhi:       lda #$00
                sta vtemp2
                ldy vchnsongpos,x
                lda (vtemp1),y
                bne vnosongjump
                iny
                lda (vtemp1),y
                tay
                lda (vtemp1),y
vnosongjump:    bpl vnosongtrans
                sta vchntrans,x
                iny
                lda (vtemp1),y
vnosongtrans:   sta vchnpattnum,x
                iny
                tya
                sta vchnsongpos,x
                bcc vcmdexecuted
                jmp vwaveexec

        ;New note init / command exec

vnewnoteinit:   cmp #FIRSTNOTE/2
                bcc vskipnote
                adc vchntrans,x
                asl
                sta vchnnote,x
                sec
vskipnote:      ldy vchncmd,x
                bmi vlegatocmd
                lda vcmdad-1,y
                sta $d405,x
                lda vcmdsr-1,y
                sta $d406,x
                bcc vskipgate
                lda #$ff
                sta vchngate,x
vfirstwave:     lda #$09
                sta $d404,x
vskipgate:  
vskipadsr:      lda vcmdwavepos-1,y
                beq vskipwave
                sta vchnwavepos,x
                lda #$00
                sta vchnwavetime,x
vskipwave:      lda vcmdpulsepos-1,y
                beq vskippulse
                sta vchnpulsepos,x
                lda #$00
                sta vchnpulsetime,x
vskippulse:     lda vcmdfiltpos-1,y
                beq vskipfilt
                sta vfiltpos+1
                lda #$00
                sta vfilttime
vskipfilt:      clc
                lda vchnpattpos,x
                beq vtrack
vcmdexecuted:  
vnotrack:       rts

        ;Pulse execution

vnopulsemod:    cmp #$ff
                lda vpulsespdtbl-1,y
                bcs vpulsejump
                inc vchnpulsepos,x
                bcc vstorepulse
vpulsejump:     sta vchnpulsepos,x
                bcs vpulsedone
vpulseexec:     ldy vchnpulsepos,x
                beq vpulsedone
                lda vpulsetimetbl-1,y
                bmi vnopulsemod
vpulsemod:      clc
                dec vchnpulsetime,x
                bmi vnewpulsemod
                bne vnonewpulsemod
                inc vchnpulsepos,x
                bcc vpulsedone
vnewpulsemod:   sta vchnpulsetime,x
vnonewpulsemod:  
                lda vchnpulse,x
                adc vpulsespdtbl-1,y
                adc #$00
vstorepulse:    sta vchnpulse,x
                sta $d402,x
                sta $d403,x
vpulsedone:  

        ;Wavetable execution

vwaveexec:      ldy vchnwavepos,x
                beq vwavedone
                lda vwavetbl-1,y
                cmp #$c0
                bcs vslideorvib
                cmp #$90
                bcc vwavechange

        ;Delayed wavetable

vwavedelay:     beq vnowavechange
                dec vchnwavetime,x
                beq vnowavechange
                bpl vwavedone
                sbc #$90
                sta vchnwavetime,x
                bcs vwavedone

        ;Wave change + arpeggio

vwavechange:    sta vchnwave,x
                tya
                sta vchnwaveold,x
vnowavechange:  lda vwavetbl,y
                cmp #$ff
                bcs vwavejump
vnowavejump:    inc vchnwavepos,x
                bcc vwavejumpdone
vwavejump:      lda vnotetbl,y
                sta vchnwavepos,x
vwavejumpdone:  lda vnotetbl-1,y
                asl
                bcs vabsfreq
                adc vchnnote,x
vabsfreq:       tay
                bne vnotenum
vslidedone:     ldy vchnnote,x
                lda vchnwaveold,x
                sta vchnwavepos,x
vnotenum:       lda vfreqtbl-24,y
                sta vchnfreqlo,x
                sta $d400,x
                lda vfreqtbl-23,y
vstorefreqhi:   sta $d401,x
                sta vchnfreqhi,x
vwavedone:      lda vchnwave,x
                and vchngate,x
                sta $d404,x
                rts

        ;Slide or vibrato

vslideorvib:    sbc #$e0
                sta vtemp1
                lda vchncounter,x
                beq vwavedone
                lda vnotetbl-1,y
                sta vtemp2
                bcc vvibrato

        ;Slide (toneportamento)

vslide:         ldy vchnnote,x
                lda vchnfreqlo,x
                sbc vfreqtbl-24,y
                pha
                lda vchnfreqhi,x
                sbc vfreqtbl-23,y
                tay
                pla
                bcs vslidedown
vslideup:       adc vtemp2
                tya
                adc vtemp1
                bcs vslidedone
vfreqadd:       lda vchnfreqlo,x
                adc vtemp2
                sta vchnfreqlo,x
                sta $d400,x
                lda vchnfreqhi,x
                adc vtemp1
                jmp vstorefreqhi
vslidedown:     sbc vtemp2
                tya
                sbc vtemp1
                bcc vslidedone
vfreqsub:       lda vchnfreqlo,x
                sbc vtemp2
                sta vchnfreqlo,x
                sta $d400,x
                lda vchnfreqhi,x
                sbc vtemp1
                jmp vstorefreqhi

          ;Vibrato

vvibrato:       lda vchnwavetime,x
                bpl vvibnodir
                cmp vtemp1
                bcs vvibnodir2
                eor #$ff
vvibnodir:      sec
vvibnodir2:     sbc #$02
                sta vchnwavetime,x
                lsr
                lda #$00
                sta vtemp1
                bcc vfreqadd
                bcs vfreqsub

vfreqtbl:       dc.w $022d,$024e,$0271,$0296,$02be,$02e8,$0314,$0343,$0374,$03a9,$03e1,$041c
                dc.w $045a,$049c,$04e2,$052d,$057c,$05cf,$0628,$0685,$06e8,$0752,$07c1,$0837
                dc.w $08b4,$0939,$09c5,$0a5a,$0af7,$0b9e,$0c4f,$0d0a,$0dd1,$0ea3,$0f82,$106e
                dc.w $1168,$1271,$138a,$14b3,$15ee,$173c,$189e,$1a15,$1ba2,$1d46,$1f04,$20dc
                dc.w $22d0,$24e2,$2714,$2967,$2bdd,$2e79,$313c,$3429,$3744,$3a8d,$3e08,$41b8
                dc.w $45a1,$49c5,$4e28,$52cd,$57ba,$5cf1,$6278,$6853,$6e87,$751a,$7c10,$8371
                dc.w $8b42,$9389,$9c4f,$a59b,$af74,$b9e2,$c4f0,$d0a6,$dd0e,$ea33,$f820,$ffff

vchnpattpos:    dc.b 0
vchncounter:    dc.b 0
vchnnewnote:    dc.b 0
vchnwavepos:    dc.b 0
vchnpulsepos:   dc.b 0
vchnwave:       dc.b 0
vchnwaveold:    dc.b 0

                dc.b 0,0,0,0,0,0,0
                dc.b 0,0,0,0,0,0,0

vchngate:       dc.b $fe
vchntrans:      dc.b $ff
vchncmd:        dc.b $01
vchnsongpos:    dc.b 0
vchnpattnum:    dc.b 0
vchnduration:   dc.b 0
vchnnote:       dc.b 0


                dc.b $fe,$ff,$01,0,0,0,0
                dc.b $fe,$ff,$01,0,0,0,0

vchnfreqlo:     dc.b 0
vchnfreqhi:     dc.b 0
vchnpulse:      dc.b 0
vchnwavetime:   dc.b 0
vchnpulsetime:  dc.b 0
vfilttime:      dc.b 0
                dc.b 0

                dc.b 0,0,0,0,0,0,0
                dc.b 0,0,0,0,0

                rend

playerend:


