                processor 6502

                include memory.s
                include mainsym.s

                org blkInfo
                incbin bg/world00.bli
                incbin bg/world00.blk
                incbin bg/world00.chc

                org levelCode
                lda worldY                  ;Skip light animation in the undamaged version of the ship
                cmp #17                     ;Instead do scrolling of the background mountains
                bcs ScrollBackground
                lda lightIndex
                bpl LightAnim
                jsr ScreenRandom
                cmp #$f0
                bcc NoNewLight
                and #$03
                tax
                lda lightInitTbl,x
                sta lightIndex
LightAnim:      dec lightDelay
                bpl NoNewLight
                lda #$02
                sta lightDelay
                ldx lightIndex
                lda lightTbl1,x
                sta Irq1_Bg1+1
                lda lightTbl2,x
                sta Irq1_Bg3+1
                dec lightIndex
NoNewLight:     rts
ScrollBackground:
                inc scrollDelay
                lda scrollDelay
                and #$07
                bne ScrollSkip
                ldx #2
ScrollLoop:     lda chars+249*8+4,x
                lsr
                ror chars+250*8+4,x
                ror chars+251*8+4,x
                ror chars+252*8+4,x
                bcc ScrollZeroBit
                ora #$80
ScrollZeroBit:  sta chars+249*8+4,x
                dex
                bpl ScrollLoop
ScrollSkip:     rts


ScreenRandom:   inc ScreenRandomLda+1
ScreenRandomLda:lda $0800
                rts

lightIndex:     dc.b $00
lightDelay:     dc.b $00
scrollDelay:    dc.b $00

lightTbl1:      dc.b $06,$00,$06,$04
lightTbl2:      dc.b $0e,$04,$0e,$03

lightInitTbl:   dc.b $01,$01,$03,$03

                org lvlObjAnimFrames
                incbin bg/world00.oba

                org waterColorOverride
                dc.b 0
                
                org chars
                incbin bg/world00.chr