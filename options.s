                processor 6502
                include memory.s

                org $0000

                dc.b 2,1,1,1                    ;Default options
                ds.b MAX_SAVES*SAVEDESCSIZE,0   ;Empty savedescs

