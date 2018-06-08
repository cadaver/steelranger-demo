                processor 6502

                include memory.s

                org blkInfo
                incbin bg/world03.bli
                incbin bg/world03.blk
                incbin bg/world03.chc

                org levelCode
                lda chars+2*8
                eor #%00010100
N               set 0
                repeat 8
                sta chars+2*8+N
N               set N+1
                repend
                rts

                org lvlObjAnimFrames
                incbin bg/world03.oba
                
                org waterColorOverride
                dc.b 0

                org chars
                incbin bg/world03.chr