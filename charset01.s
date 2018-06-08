                processor 6502

                include memory.s

                org blkInfo
                incbin bg/world01.bli
                incbin bg/world01.blk
                incbin bg/world01.chc

                org levelCode

                ldy chars+2*8+7
                ldx #$06
WaterLoop:      lda chars+2*8,x
                sta chars+2*8+1,x
                dex
                bpl WaterLoop
                sty chars+2*8
                ldx #$00
                inc delayCount
                lda delayCount
                and #$07
                bne WaterSkip1
                jsr WaterSub
                inx
                jsr WaterSub
WaterSkip1:     ldx #$02
                lda delayCount
                and #$0f
                bne WaterSkip2
WaterSub:       lda chars+4*8,x
                asl
                rol chars+3*8,x
                adc #$00
                sta chars+4*8,x
WaterSkip2:     rts

delayCount:     dc.b 0

                org lvlObjAnimFrames
                incbin bg/world01.oba
                
                org waterColorOverride
                dc.b 0

                org chars
                incbin bg/world01.chr