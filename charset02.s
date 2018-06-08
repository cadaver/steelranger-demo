                processor 6502

                include memory.s

randomAreaStart = $0800

                org blkInfo
                incbin bg/world02.bli
                incbin bg/world02.blk
                incbin bg/world02.chc

                org levelCode
                dec delayCount
                bne SkipPowerLine
                lda #$06
                sta delayCount
                ldx #$03
                lda chars+8*8+4
PowerLineLoop:  asl
                rol chars+7*8+4
                rol chars+6*8+4
                rol chars+5*8+4
                adc #$00
                dex
                bpl PowerLineLoop
                sta chars+8*8+4
SkipPowerLine:  inc delayCount2
                lda delayCount2
                tay
                and #$0f
                cmp #$01
                bne SkipScreen
                ldx #$00
ScrollScreen:   lda chars+13*8+1,x
                sta chars+13*8,x
                lda chars+14*8+1,x
                sta chars+14*8,x
                inx
                cpx #$07
                bcc ScrollScreen
                tya
                and #$10
                bne PrintFull
                lda #$ff
                sta chars+13*8+7
                bne PrintCommon
PrintFull:      jsr ScreenRandom
                sta chars+13*8+7
                jsr ScreenRandom
PrintCommon:    sta chars+14*8+7                ;Screen scrolling is quite expensive,
                rts                             ;do not do gear + cursor animation on same frame
SkipScreen:     tya
                and #$1f
                bne SkipCursor
                lda chars+19*8+3
                eor #%00100000
                sta chars+19*8+3
                lda chars+31*8+5
                eor #%00000010
                sta chars+31*8+5
SkipCursor:     tya
                and #$03
                bne SkipGear
                lda chars+27*8+4
                eor #%01101001
                sta chars+27*8+4
                sta chars+27*8+6
                lda chars+27*8+5
                eor #%01101001
                sta chars+27*8+5
                sta chars+27*8+7
                lda chars+29*8
                eor #%00010110
                sta chars+29*8
                sta chars+29*8+2
                lda chars+29*8+1
                eor #%00010110
                sta chars+29*8+1
                sta chars+29*8+3
                ldy chars+28*8+3
                ldx #$02
GearLoop:       lda chars+28*8,x
                sta chars+28*8+1,x
                sta chars+28*8+5,x
                dex
                bpl GearLoop
                sty chars+28*8
                sty chars+28*8+4
SkipGear:       rts

ScreenRandom:   inc ScreenRandomLda+1
ScreenRandomLda:lda randomAreaStart
                rts

                org lvlObjAnimFrames
                incbin bg/world02.oba

delayCount:     dc.b 1
delayCount2:    dc.b 0

                org waterColorOverride
                dc.b 0
                
                org chars
                incbin bg/world02.chr