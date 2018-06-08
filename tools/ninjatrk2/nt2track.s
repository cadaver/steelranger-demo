;-------------------------------------------------------------------------------
; Track editor
;-------------------------------------------------------------------------------

nextsong:       inc songnum
songchgcommon:  lda songnum
                and #$0f
                sta songnum
                jsr stop
                jsr resetsongpos
                jsr trackstowork
                jmp printtracks
prevsong:       dec songnum
                jmp songchgcommon

resetsongpos:   lda #$00
                ldx #$02
rsp_loop:       sta worktrackstart,x
                sta trackview,x
                sta trackrow,x
                dex
                bpl rsp_loop
                sta trackcol
                rts

trackleft:      lda trackcol
                eor #$01
                sta trackcol
                beq trltdone
                dec tracknum
                bpl trltdone
                lda #2
                sta tracknum
trltdone:       rts

trackright:     lda trackcol
                eor #$01
                sta trackcol
                bne trrtdone
                inc tracknum
                lda tracknum
                cmp #3
                bcc trrtdone
                lda #0
                sta tracknum
trrtdone:       rts

trackrightedit: lda trackcol
                eor #$01
                sta trackcol
                beq trackdown
                rts

trackup:        ldx tracknum
                lda trackrow,x
                beq trupdone
                dec trackrow,x
adjusttrackview:lda trackrow,x
                cmp trackview,x
                bcs atrvnotlow
                sta trackview,x
                rts
atrvnotlow:     sbc trackview,x
                cmp #VISIBLE_ROWS
                bcc atrvnothigh
                sbc #VISIBLE_ROWS
                adc trackview,x
                sta trackview,x
atrvnothigh:
trdndone:
trupdone:       rts

trackdown:      ldx tracknum
                lda trackrow,x
                cmp worktracklen,x
                bcs trdndone
                inc trackrow,x
                jmp adjusttrackview

trackdel:       jsr stop
                jsr gettrackptr
                lda trackrow,x
                cmp worktracklen,x
                beq trdeldone
                tay
trdelloop:      iny
                beq trdeldone2
                lda (destlo),y
                dey
                sta (destlo),y
                iny
                bne trdelloop
trdeldone2:     dec worktracklen,x
                ldy worktracklen,x
                dey
                lda (destlo),y
                cmp trackrow,x
                bcc trdelnojump
                beq trdelnojump
                sbc #$01
                sta (destlo),y
trdelnojump:    lda worktrackstart,x
                cmp trackrow,x
                bcc trdelnostart
                beq trdelnostart
                dec worktrackstart,x
trdelnostart:   jsr worktotracks
trdeldone:      rts

trackins:       jsr stop
                jsr gettrackptr
                lda worktracklen,x
                cmp #$ff
                bcs trinsdone
                lda trackrow,x
                sta var1
                lda worktracklen,x
                cmp var1
                beq trinsdone
                tay
                dey
trinsloop:      lda (destlo),y
                iny
                sta (destlo),y
                dey
                cpy var1
                beq trinsdone2
                dey
                jmp trinsloop
trinsdone2:     inc worktracklen,x
                ldy worktracklen,x
                dey
                lda (destlo),y
                cmp trackrow,x
                bcc trinsnojump
                beq trinsnojump
                adc #$00
                sta (destlo),y
trinsnojump:    lda worktrackstart,x
                cmp trackrow,x
                bcc trinsnostart
                beq trinsnostart
                inc worktrackstart,x
trinsnostart:   jsr worktotracks
trinsdone:      rts

gettrackptr:    ldx tracknum
                lda #<worktrack1
                sta destlo
                txa
                clc
                adc #>worktrack1
                sta desthi
                rts

gofastup:       lda #FASTUPDOWN
                sta fastup
                rts

gofastdown:     lda #FASTUPDOWN
                sta fastdown
treddone:       rts

trackedit:      ldx tracknum
                lda trackrow,x
                cmp #MAX_SONGLEN-1
                bcs treddone
                adc #<worktrack1
                sta destlo
                lda #>worktrack1
                adc #$00
                adc tracknum
                sta desthi
                ldx trackcol
                jsr hexedit
                bcc treddone
                jsr tredcommon
                jmp trackrightedit
tredcommon:     ldx tracknum
                lda trackrow,x
                cmp worktracklen,x
                bne trednotlast
                inc worktracklen,x
                jsr stop
trednotlast:    jmp worktotracks

setsongstart:   ldx tracknum
                lda trackrow,x
                cmp worktracklen,x
                bcs sssdone
                sta worktrackstart,x
                jsr worktotracks
sssdone:        rts

gotopatt:       jsr gettrackptr
                lda trackrow,x
                jsr adddest
                ldy #$00
                lda key
                bmi gpgotoend
                lda trackrow,x
                cmp worktracklen,x
                beq gpdone
                lda (destlo),y
                bmi gpdone
                beq gpdone
                sta pattnum
                jmp setpatt
gpgotoend:      lda trackrow,x
                cmp #$ff
                beq gpdone
                ldx #$01
gpgeloop:       lda nt_patttbllo-1,x
                sta srclo
                lda nt_patttblhi-1,x
                sta srchi
                lda (srclo),y
                beq gpgefound
                inx
                cpx #MAX_PATT+1
                bne gpgeloop
gpdone:         rts
gpgefound:      txa
                sta (destlo),y
                sta pattnum
                jsr setpatt
                jsr tredcommon
                jmp printtracks
                
marktrack:      ldx tracknum
                cpx trackmarknum
                bne mtrreset
                lda trackmarkmode
                cmp #2
                bcc mtrnoreset
mtrreset:       jsr resettrackmark
mtrnoreset:     lda trackrow,x
                cmp worktracklen,x
                beq mtrdone
                ldy trackmarkmode
                bne mtrend
mtrstart:       stx trackmarknum
                sta trackmarkstart
                lda #1
                bne mtrstore
mtrend:         cmp trackmarkstart
                bcc mtrstart
                adc #$00
                sta trackmarkend
                lda #2
mtrstore:       sta trackmarkmode
mtrdone:        rts

resettrackmark: lda #$00
                beq mtrstore

cuttrack:       jsr copytrack
                bcc ctrdone
                lda trackcopylen
                sta var6
                beq ctrdone
                ldx tracknum
                lda trackmarkstart
                sta trackrow,x
                jsr adjusttrackview
ctrloop:        jsr trackdel
                dec var6
                bne ctrloop
cptrdone:       clc
ptrdone:
ctrdone:        rts

copytrack:      jsr gettrackptr
                cpx trackmarknum
                bne cptrdone
                lda trackmarkmode
                cmp #2
                bne cptrdone
                ldy trackmarkstart
                ldx #$00
cptrloop:       lda (destlo),y
                sta trackcopybuffer,x
                inx
                iny
                cpy trackmarkend
                bne cptrloop                ;C=1 when exiting copy successfully
                stx trackcopylen
                jmp resettrackmark

pastetrack:     jsr stop
                jsr gettrackptr
                lda trackcopylen
                beq ptrdone
                clc
                adc trackrow,x
                bcs ptrdone
                ldy trackrow,x
                ldx #$00
ptrloop:        lda trackcopybuffer,x
                sta (destlo),y
                iny
                inx
                cpx trackcopylen
                bne ptrloop
                tya
                ldx tracknum
                cmp worktracklen,x
                bcc ptrnonewlen
                sta worktracklen,x
ptrnonewlen:    lda trackcopylen
                sta var6
ptrdownloop:    jsr trackdown
                dec var6
                bne ptrdownloop
                jmp worktotracks

;-------------------------------------------------------------------------------
; Convert work tracks to song
;-------------------------------------------------------------------------------

worktotracks:   lda worktracklen            ;Combined length must not exceed
                sta destlo                  ;256 bytes
                lda #$00
                sta desthi
                lda worktracklen+1
                jsr adddest
                lda worktracklen+2
                jsr adddest
                lda desthi
                cmp #$01
                bcc wtotr_ok
                bne wtotr_error
                lda destlo
                beq wtotr_ok
wtotr_error:    lda #$02
                sta $d020
                jsr trackstowork
                ldx tracknum
                lda trackrow,x
                cmp worktracklen,x
                bcc wtotr_errorposok
                lda worktracklen,x
                sta trackrow,x
wtotr_errorposok:
                jmp adjusttrackview
wtotr_ok:       jsr getsongindex
                lda nt_songtbl,x
                sta destlo
                lda nt_songtbl+1,x
                sta desthi
                lda #$00
                sta var1
                sta var4
                lda songnum
                asl
                adc songnum
                sta var2
                lda #<worktrack1
                sta srclo
                lda #>worktrack1
                sta srchi
wtotr_loop:     ldx var1
                ldy var2
                lda worktracklen,x
                sta var3
                sta var5
                dec var5
                sta songlen,y
                ldy #$00
wtotr_loop2:    cpy var3
                beq wtotr_done
                lda (srclo),y
                cpy var5
                bne wtotr_noadjust
                clc
                adc var4
                jmp wtotr_store
wtotr_noadjust: cmp #$80
                bcc wtotr_store
                sbc #$41
                ora #$80
wtotr_store:    sta (destlo),y
                iny
                jmp wtotr_loop2
wtotr_done:     tya
                jsr adddest
                tya
                clc
                adc var4
                sta var4
                inc srchi
                inc var1
                inc var2
                lda var1
                cmp #3
                bne wtotr_loop
                lda #$00                    ;Fill the rest with zero
                cmp var4
                beq wtotr_filldone
                tay
wtotr_fillrest: sta (destlo),y
                iny
                cpy var4
                bne wtotr_fillrest
wtotr_filldone: rts

;-------------------------------------------------------------------------------
; Convert song to work tracks
;-------------------------------------------------------------------------------

trackstowork:   jsr getsongindex
                lda nt_songtbl,x
                sta srclo
                lda nt_songtbl+1,x
                sta srchi
                lda #$00
                sta var1
                sta var4
                lda songnum
                asl
                adc songnum
                sta var2
                lda #<worktrack1
                sta destlo
                lda #>worktrack1
                sta desthi
trtow_loop:     ldx var2
                lda songlen,x
                sta var3
                sta var5
                dec var5
                ldx var1
                sta worktracklen,x
                ldy #$00
trtow_loop2:    cpy var3
                beq trtow_done
                lda (srclo),y
                cpy var5
                bne trtow_noadjust
                sbc var4
                jmp trtow_store
trtow_noadjust: cmp #$80
                bcc trtow_store
                adc #$40
                ora #$80
trtow_store:    sta (destlo),y
                iny
                jmp trtow_loop2
trtow_done:     tya
                jsr addsrc
                tya
                clc
                adc var4
                sta var4
                lda #$00
trtow_clear:    sta (destlo),y
                iny
                bne trtow_clear
                inc desthi
                inc var1
                inc var2
                lda var1
                cmp #3
                bne trtow_loop
                rts

;-------------------------------------------------------------------------------
; Get index to songtable (song number * 5)
;-------------------------------------------------------------------------------

getsongindex:   lda songnum
                asl
                asl
                adc songnum
                tax
                rts
