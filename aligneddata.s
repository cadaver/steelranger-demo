alignedDataStart:

                org (* + $ff) & $ff00

        ; Sprite cache / depacking tables

        ; Next slice lowbyte table for sprite depacking. Interleaved with data to not waste memory,
        ; each empty space is 15 bytes.

nextSliceTbl:   dc.b 1,2,21
flipNextSliceTbl:dc.b 24,1,2

d015Tbl:        dc.b $00,$80,$c0,$e0,$f0,$f8,$fc,$fe,$ff
screenBaseTbl:  dc.b >screen1, >screen2, >screen1
d018Tbl:        dc.b GAMESCR1_D018, GAMESCR2_D018 ;1 byte free

                org nextSliceTbl+21
                dc.b 22,23,42
                dc.b 45,22,23

shiftSrcTbl:    dc.b 0,0,1
                dc.b 40,40,41
                dc.b 40,40,41

colorSrcTbl:    dc.b 37,38,1
colorDestTbl:   dc.b 38,38,0

                org nextSliceTbl+42
                dc.b 43,44,0
                dc.b 0,43,44

sprIrqJumpTbl:  dc.b <Irq2_Spr0,<Irq2_Spr1,<Irq2_Spr2,<Irq2_Spr3,<Irq2_Spr4,<Irq2_Spr5,<Irq2_Spr6,<Irq2_Spr7
sprIrqAdvanceTbl:
                dc.b -2,-3,-4,-5,-7,-8,-9,-10

                org nextSliceTbl+$40
                dc.b $40+1,$40+2,$40+21
                dc.b $40+24,$40+1,$40+2

shiftDestTbl:   dc.b 41,40,40
                dc.b 41,40,40
                dc.b 1,0,0

colorXTbl:      dc.b $ca,$ca,$e8
colorSideTbl:   dc.b 0,-1,38

                org nextSliceTbl+$40+21
                dc.b $40+22,$40+23,$40+42
                dc.b $40+45,$40+22,$40+23

shiftEndTbl:    dc.b 38,39,39
                dc.b 78,79,79
                dc.b 78,79,79

colorEndTbl:    dc.b -1,-1,39
colorYTbl:      dc.b $88,$88,$c8

                org nextSliceTbl+$40+42
                dc.b $40+43,$40+44,0
                dc.b 0,$40+43,$40+44

bitTbl:         dc.b $01,$02,$04,$08,$10,$20,$40,$80
wpnKeyTbl:      dc.b KEY_1,KEY_2,KEY_3,KEY_4,KEY_5,KEY_6,KEY_7,KEY_8

                org nextSliceTbl+$80
                dc.b $80+1,$80+2,$80+21
                dc.b $80+24,$80+1,$80+2

shiftLoopOffsetTbl:
                dc.b 6,6,6
                dc.b 0,0,0
                dc.b 6,6,6

                org nextSliceTbl+$80+21
                dc.b $80+22,$80+23,$80+42
                dc.b $80+45,$80+22,$80+23

colorJumpTblLo: dc.b <ScrollColorsUp, <ScrollColorsUp, <ScrollColorsUp
                dc.b <ScrollColorsHoriz, <NoScrollWork, <ScrollColorsHoriz
                dc.b <ScrollColorsDown, <ScrollColorsDown, <ScrollColorsDown

itemFlashTbl:   dc.b 11,10,15,10

                org nextSliceTbl+$80+42
                dc.b $80+43,$80+44,0
                dc.b 0,$80+43,$80+44

colorJumpTblHi: dc.b >ScrollColorsUp, >ScrollColorsUp, >ScrollColorsUp
                dc.b >ScrollColorsHoriz, >NoScrollWork, >ScrollColorsHoriz
                dc.b >ScrollColorsDown, >ScrollColorsDown, >ScrollColorsDown

mineFlashTbl:   dc.b 7,10,12,10
enemyPartsTbl:  dc.b MEDIUM_ENEMY_THRESHOLD,LARGE_ENEMY_THRESHOLD,SUPER_ENEMY_THRESHOLD

                org nextSliceTbl+$c0
                dc.b $c0+1,$c0+2,$c0+21
                dc.b $c0+24,$c0+1,$c0+2

drawJumpTblLo:  dc.b <DrawUpLeft, <DrawUp, <DrawUpRight
                dc.b <DrawLeft, <NoScrollWork, <DrawRight
                dc.b <DrawDownLeft, <DrawDown, <DrawDownRight

weaponSelectColorTbl:
                dc.b 2,7,1,7

                org nextSliceTbl+$c0+21
                dc.b $c0+22,$c0+23,$c0+42
                dc.b $c0+45,$c0+22,$c0+23

drawJumpTblHi:  dc.b >DrawUpLeft, >DrawUp, >DrawUpRight
                dc.b >DrawLeft, >NoScrollWork, >DrawRight
                dc.b >DrawDownLeft, >DrawDown, >DrawDownRight

timeMaxTbl:     dc.b 99,60,60,25

                org nextSliceTbl+$c0+42
                dc.b $c0+43,$c0+44,0
                dc.b 0,$c0+43,$c0+44

moveCtrlAndTbl: dc.b $ff-JOY_LEFT-JOY_RIGHT-JOY_UP-JOY_DOWN ;None
                dc.b $ff-JOY_DOWN-JOY_LEFT-JOY_RIGHT ;Up
                dc.b $ff-JOY_UP-JOY_LEFT-JOY_RIGHT ;Down
                dc.b $ff-JOY_UP-JOY_DOWN-JOY_LEFT-JOY_RIGHT ;Up+Down
                dc.b $ff-JOY_RIGHT-JOY_UP-JOY_DOWN ;Left
                dc.b $ff-JOY_RIGHT-JOY_DOWN     ;Left+Up
                dc.b $ff-JOY_RIGHT-JOY_UP       ;Left+Down
                dc.b $ff-JOY_RIGHT-JOY_UP-JOY_DOWN ;Left+Up+Down
                dc.b $ff-JOY_LEFT-JOY_UP-JOY_DOWN ;Right
                dc.b $ff-JOY_LEFT-JOY_DOWN      ;Right+Up
                dc.b $ff-JOY_LEFT-JOY_UP        ;Right+Down
                dc.b $ff-JOY_LEFT-JOY_UP-JOY_DOWN ;Right+Up+Down
                dc.b $ff-JOY_LEFT-JOY_RIGHT-JOY_UP-JOY_DOWN     ;Right+Left
                dc.b $ff-JOY_LEFT-JOY_RIGHT-JOY_DOWN ;Right+Left+Up
                dc.b $ff-JOY_LEFT-JOY_RIGHT-JOY_UP ;Right+Left+Down
                dc.b $ff-JOY_LEFT-JOY_RIGHT-JOY_UP-JOY_DOWN ;Right+Left+Up+Down

                org nextSliceTbl+$100

        ; Sprite flipping table

flipTbl:        dc.b %00000000,%01000000,%10000000,%11000000,%00010000,%01010000,%10010000,%11010000,%00100000,%01100000,%10100000,%11100000,%00110000,%01110000,%10110000,%11110000
                dc.b %00000100,%01000100,%10000100,%11000100,%00010100,%01010100,%10010100,%11010100,%00100100,%01100100,%10100100,%11100100,%00110100,%01110100,%10110100,%11110100
                dc.b %00001000,%01001000,%10001000,%11001000,%00011000,%01011000,%10011000,%11011000,%00101000,%01101000,%10101000,%11101000,%00111000,%01111000,%10111000,%11111000
                dc.b %00001100,%01001100,%10001100,%11001100,%00011100,%01011100,%10011100,%11011100,%00101100,%01101100,%10101100,%11101100,%00111100,%01111100,%10111100,%11111100
                dc.b %00000001,%01000001,%10000001,%11000001,%00010001,%01010001,%10010001,%11010001,%00100001,%01100001,%10100001,%11100001,%00110001,%01110001,%10110001,%11110001
                dc.b %00000101,%01000101,%10000101,%11000101,%00010101,%01010101,%10010101,%11010101,%00100101,%01100101,%10100101,%11100101,%00110101,%01110101,%10110101,%11110101
                dc.b %00001001,%01001001,%10001001,%11001001,%00011001,%01011001,%10011001,%11011001,%00101001,%01101001,%10101001,%11101001,%00111001,%01111001,%10111001,%11111001
                dc.b %00001101,%01001101,%10001101,%11001101,%00011101,%01011101,%10011101,%11011101,%00101101,%01101101,%10101101,%11101101,%00111101,%01111101,%10111101,%11111101
                dc.b %00000010,%01000010,%10000010,%11000010,%00010010,%01010010,%10010010,%11010010,%00100010,%01100010,%10100010,%11100010,%00110010,%01110010,%10110010,%11110010
                dc.b %00000110,%01000110,%10000110,%11000110,%00010110,%01010110,%10010110,%11010110,%00100110,%01100110,%10100110,%11100110,%00110110,%01110110,%10110110,%11110110
                dc.b %00001010,%01001010,%10001010,%11001010,%00011010,%01011010,%10011010,%11011010,%00101010,%01101010,%10101010,%11101010,%00111010,%01111010,%10111010,%11111010
                dc.b %00001110,%01001110,%10001110,%11001110,%00011110,%01011110,%10011110,%11011110,%00101110,%01101110,%10101110,%11101110,%00111110,%01111110,%10111110,%11111110
                dc.b %00000011,%01000011,%10000011,%11000011,%00010011,%01010011,%10010011,%11010011,%00100011,%01100011,%10100011,%11100011,%00110011,%01110011,%10110011,%11110011
                dc.b %00000111,%01000111,%10000111,%11000111,%00010111,%01010111,%10010111,%11010111,%00100111,%01100111,%10100111,%11100111,%00110111,%01110111,%10110111,%11110111
                dc.b %00001011,%01001011,%10001011,%11001011,%00011011,%01011011,%10011011,%11011011,%00101011,%01101011,%10101011,%11101011,%00111011,%01111011,%10111011,%11111011
                dc.b %00001111,%01001111,%10001111,%11001111,%00011111,%01011111,%10011111,%11011111,%00101111,%01101111,%10101111,%11101111,%00111111,%01111111,%10111111,%11111111

        ; Instruction length table for relocation, 4 instructions packed into one byte
        ; Instructions x4-x7 and xc-xf have always same length, so they are omitted

instrLenTbl:    instrlen 1,2,1,2
                ;instrlen 2,2,2,2
                instrlen 1,2,1,2
                ;instrlen 3,3,3,3

                instrlen 2,2,1,2 ;1
                ;instrlen 2,2,2,2
                instrlen 1,3,1,3
                ;instrlen 3,3,3,3

                instrlen 3,2,1,2 ;2
                ;instrlen 2,2,2,2
                instrlen 1,2,1,2
                ;instrlen 3,3,3,3

                instrlen 2,2,1,2 ;3
                ;instrlen 2,2,2,2
                instrlen 1,3,1,3
                ;instrlen 3,3,3,3

                instrlen 1,2,1,2 ;4
                ;instrlen 2,2,2,2
                instrlen 1,2,1,2
                ;instrlen 3,3,3,3

                instrlen 2,2,1,2 ;5
                ;instrlen 2,2,2,2
                instrlen 1,3,1,3
                ;instrlen 3,3,3,3

                instrlen 1,2,1,2 ;6
                ;instrlen 2,2,2,2
                instrlen 1,2,1,2
                ;instrlen 3,3,3,3

                instrlen 2,2,1,2 ;7
                ;instrlen 2,2,2,2
                instrlen 1,3,1,3
                ;instrlen 3,3,3,3

                instrlen 2,2,2,2 ;8
                ;instrlen 2,2,2,2
                instrlen 1,2,1,2
                ;instrlen 3,3,3,3

                instrlen 2,2,1,3 ;9
                ;instrlen 2,2,2,2
                instrlen 1,3,1,3
                ;instrlen 3,3,3,3

                instrlen 2,2,2,2 ;a
                ;instrlen 2,2,2,2
                instrlen 1,2,1,2
                ;instrlen 3,3,3,3

                instrlen 2,2,1,2 ;b
                ;instrlen 2,2,2,2
                instrlen 1,3,1,3
                ;instrlen 3,3,3,3

                instrlen 2,2,2,2 ;c
                ;instrlen 2,2,2,2
                instrlen 1,2,1,2
                ;instrlen 3,3,3,3

                instrlen 2,2,1,2 ;d
                ;instrlen 2,2,2,2
                instrlen 1,3,1,3
                ;instrlen 3,3,3,3

                instrlen 2,2,2,2 ;e
                ;instrlen 2,2,2,2
                instrlen 1,2,1,2
                ;instrlen 3,3,3,3

                instrlen 2,2,1,2 ;f
                ;instrlen 2,2,2,2
                instrlen 1,3,1,3
                ;instrlen 3,3,3,3

        ; Playroutine frequency table (accessed at minus 24 offset)

ntFreqTbl:      dc.w $022d,$024e,$0271,$0296,$02be,$02e8
                dc.w $0314,$0343,$0374,$03a9,$03e1,$041c
                dc.w $045a,$049c,$04e2,$052d,$057c,$05cf
                dc.w $0628,$0685,$06e8,$0752,$07c1,$0837
                dc.w $08b4,$0939,$09c5,$0a5a,$0af7,$0b9e
                dc.w $0c4f,$0d0a,$0dd1,$0ea3,$0f82,$106e
                dc.w $1168,$1271,$138a,$14b3,$15ee,$173c
                dc.w $189e,$1a15,$1ba2,$1d46,$1f04,$20dc
                dc.w $22d0,$24e2,$2714,$2967,$2bdd,$2e79
                dc.w $313c,$3429,$3744,$3a8d,$3e08,$41b8
                dc.w $45a1,$49c5,$4e28,$52cd,$57ba,$5cf1
                dc.w $6278,$6853,$6e87,$751a,$7c10,$8371
                dc.w $8b42,$9389,$9c4f,$a59b,$af74,$b9e2
                dc.w $c4f0,$d0a6,$dd0e,$ea33,$f820,$ffff

ammoBarXPosTbl:
N               set 2
                repeat MAX_WEAPONS
                dc.b N
N               set N+3
                repend

        ; Sprite bit table

sprBitTbl:      repeat MAX_SPR*2/8
                dc.b $80,$40,$20,$10,$08,$04,$02,$01
                repend
                
        ; Slope table

slopeTbl:       dc.b $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
                dc.b $78,$70,$68,$60,$58,$50,$48,$40,$38,$30,$28,$20,$18,$10,$08,$00
                dc.b $78,$78,$70,$70,$68,$68,$60,$60,$58,$58,$50,$50,$48,$48,$40,$40
                dc.b $38,$38,$30,$30,$28,$28,$20,$20,$18,$18,$10,$10,$08,$08,$00,$00
                dc.b $40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40
                dc.b $00,$08,$10,$18,$20,$28,$30,$38,$40,$48,$50,$58,$60,$68,$70,$78
                dc.b $00,$00,$08,$08,$10,$10,$18,$18,$20,$20,$28,$28,$30,$30,$38,$38
                dc.b $40,$40,$48,$48,$50,$50,$58,$58,$60,$60,$68,$68,$70,$70,$78,$78

        ; Coordinate tables for actor display

yCoordTbl:
N               set 32
                repeat MAX_ACTY
                dc.b <N
N               set N+16
                repend
xCoordTbl:
N               set -8
                repeat MAX_ACTX
                dc.b <N
N               set N+8
                repend

        ; Music relocation tables

ntFixupTblLo:   dc.b <Play_SongTblP2
                dc.b <Play_SongTblP1
                dc.b <Play_SongTblP0
                dc.b <Play_PattTblHiM1
                dc.b <Play_PattTblLoM1
                dc.b <Play_CmdFiltM1
                dc.b <Play_CmdPulseM1
                dc.b <Play_CmdWaveM1
                dc.b <Play_CmdSRM1
                dc.b <Play_CmdADM1
                dc.b <Play_FiltSpdM1b
                dc.b <Play_FiltSpdM1a
                dc.b <Play_FiltTimeM1
                dc.b <Play_PulseSpdM1b
                dc.b <Play_PulseSpdM1a
                dc.b <Play_PulseTimeM1
                dc.b <Play_NoteP0
                dc.b <Play_NoteM1b
                dc.b <Play_NoteM1a
                dc.b <Play_WaveP0
                dc.b <Play_WaveM1

ntFixupTblHi:   dc.b >Play_SongTblP2
                dc.b >Play_SongTblP1
                dc.b >Play_SongTblP0
                dc.b >Play_PattTblHiM1
                dc.b >Play_PattTblLoM1
                dc.b >Play_CmdFiltM1
                dc.b >Play_CmdPulseM1
                dc.b >Play_CmdWaveM1
                dc.b >Play_CmdSRM1
                dc.b >Play_CmdADM1
                dc.b >Play_FiltSpdM1b
                dc.b >Play_FiltSpdM1a
                dc.b >Play_FiltTimeM1
                dc.b >Play_PulseSpdM1b
                dc.b >Play_PulseSpdM1a
                dc.b >Play_PulseTimeM1
                dc.b >Play_NoteP0
                dc.b >Play_NoteM1b
                dc.b >Play_NoteM1a
                dc.b >Play_WaveP0
                dc.b >Play_WaveM1

ntFixupTblAdd:  dc.b NT_ADDZERO+3
                dc.b NT_ADDZERO+2
                dc.b NT_ADDPATT+1
                dc.b NT_ADDPATT
                dc.b NT_ADDLEGATOCMD
                dc.b NT_ADDLEGATOCMD
                dc.b NT_ADDLEGATOCMD
                dc.b NT_ADDCMD
                dc.b NT_ADDCMD
                dc.b NT_ADDFILT
                dc.b NT_ADDZERO
                dc.b NT_ADDFILT
                dc.b NT_ADDPULSE
                dc.b NT_ADDZERO
                dc.b NT_ADDPULSE
                dc.b NT_ADDWAVE
                dc.b NT_ADDZERO+1
                dc.b NT_ADDZERO
                dc.b NT_ADDWAVE
                dc.b NT_ADDZERO+1
                dc.b NT_ADDZERO
