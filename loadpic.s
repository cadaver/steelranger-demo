                include memory.s
                include mainsym.s

                org loaderCodeEnd

                lda #<$e000                     ;Load bitmap
                ldx #>$e000
                jsr LoadFile
                ldx #$00
                ldy #$04
CopyColorData:  lda screenData,x
                sta $cc00,x
                lda colorData,x
                sta $d800,x
                inx
                bne CopyColorData
                inc CopyColorData+2
                inc CopyColorData+5
                inc CopyColorData+8
                inc CopyColorData+11
                dey
                bne CopyColorData
WBLoop1:        lda $d011                       ;Wait until bottom of screen
                bmi WBLoop1
WBLoop2:        lda $d011
                bpl WBLoop2
                stx $d020
                lda $dd00
                and #$fc
                sta $dd00
                lda #$18
                sta $d016
                lda #$38
                sta $d018
                lda #$3b
                sta $d011                       ;Show loading picture
                lda #>(InitAll-1)               ;Store mainpart entrypoint to stack
                pha
                lda #<(InitAll-1)
                pha
                lda #<loaderCodeEnd
                ldx #>loaderCodeEnd
                jmp LoadFile                    ;Load mainpart & jump to it

screenData:     incbin loadpicscr.dat
colorData:      incbin loadpiccol.dat