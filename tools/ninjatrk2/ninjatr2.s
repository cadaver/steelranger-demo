;-------------------------------------------------------------------------------
; NinjaTracker V2.04
;
; Cadaver 6/2013
;-------------------------------------------------------------------------------

                processor 6502

MAX_SONGS       = 16
MAX_PATT        = 127
MAX_CMD         = 127
MAX_CMDNAMELEN  = 9
MAX_PATTLEN     = 192
MAX_SONGLEN     = 256
MAX_TBLLEN      = 255
MAX_PTPIANOKEYS = 29
MAX_DMCPIANOKEYS = 16
MAX_RELOCITEMS  = 17
MIN_OCTAVE      = 1
MAX_OCTAVE      = 7

VISIBLE_ROWS    = 12
VISIBLE_TBLROWS = (25-5-VISIBLE_ROWS)
VISIBLE_CMDS    = (VISIBLE_TBLROWS/2)

MAX_KEYREPEAT   = 2
MAX_KEYDELAY    = 12
FASTUPDOWN      = 16

EM_TRACKS       = 0
EM_PATTERN      = 1
EM_TABLES       = 2
EM_CMD          = 3
EM_GENERAL      = 4

N_PROTRACKER    = 0
N_DMC           = 1

MSG_LOAD        = 0
MSG_SAVE        = 1
MSG_ERASE       = 2
MSG_PACKER      = 3

MAX_COLORS      = 5
BGCOL           = $00
NORMALCOL       = $0c
HIGHLIGHTCOL    = $0f
EMPTYCOL        = $0b
TITLECOL        = $01

RASTERPOS       = $34

        ;Song load/save RLE coding escape byte

ESCBYTE         = $bf

        ;Some keycodes

KEY_F1          = $85
KEY_F3          = $86
KEY_F5          = $87
KEY_F7          = $88
KEY_F2          = $89
KEY_F4          = $8a
KEY_F6          = $8b
KEY_F8          = $8c
KEY_SHIFTSPACE  = $a0
KEY_SPACE       = $20
KEY_HOME        = $13
KEY_UP          = $91
KEY_DOWN        = $11
KEY_LEFT        = $9d
KEY_RIGHT       = $1d
KEY_INS         = $94
KEY_DEL         = $14
KEY_RUNSTOP     = $03
KEY_LEFTARROW   = $5f
KEY_RETURN      = $0d
KEY_SHIFTRETURN = $8d

        ;Default hardrestart parameters

DEFAULT_HRPARAM = $00
DEFAULT_FIRSTWAVE = $09

        ;Orderlist commands

LOOP            = $00
TRANS           = $80

        ;Pattern commands / note numbers

ENDPATT         = $00
CMD             = $01
KEYON           = $02*2
KEYOFF          = $04*2
FIRSTNOTE       = $0c*2
LASTNOTE        = $5f*2
DUR             = $c0
MAXDUR          = 65
MINDUR          = 3

        ;Zeropage

alo             = $02
ahi             = $03
alo2            = $04
ahi2            = $05
textlo          = $06
texthi          = $07
scrlo           = $08
scrhi           = $09
colorlo         = $0a
colorhi         = $0b

srclo           = $0c
srchi           = $0d
destlo          = $0e
desthi          = $0f
var1            = $10
var2            = $11
var3            = $12
var4            = $13
var5            = $14
var6            = $15

bgcol           = $16
emptycol        = $17
normalcol       = $18
highlightcol    = $19
titlecol        = $1a

timeframefull   = $1b
timeframehalf   = $1c

nt_temp1        = $fc
nt_temp2        = $fd

status          = $90
fa              = $ba

mode            = $0291
kount           = $028b
delay           = $028c

        ;Kernal routines

scnkey          = $ff9f
getin           = $ffe4
setnam          = $ffbd
setlfs          = $ffba
load            = $ffd5
save            = $ffd8
chrin           = $ffcf
open            = $ffc0
close           = $ffc3
chkin           = $ffc6
chkout          = $ffc9
clrchn          = $ffcc
chrout          = $ffd2
plot            = $fff0

                org $0800

;-------------------------------------------------------------------------------
; Sprite cursor
;-------------------------------------------------------------------------------

                dc.b $ff,0,0
                dc.b $ff,0,0
                dc.b $ff,0,0
                dc.b $ff,0,0
                dc.b $ff,0,0
                dc.b $ff,0,0
                dc.b $ff,0,0
                dc.b $ff,0,0
                ds.b 39,0

                org $0840

;-------------------------------------------------------------------------------
; Editor main program
;-------------------------------------------------------------------------------

start:          lda #$36                    ;Switch off BASIC-rom
                sta $01
                jsr detectdevice            ;Get default device
                jsr detectntsc              ;Get video standard
                lda #60                     ;(for correct time display)
                bcc isntsc
                lda #50
isntsc:         sta timeframefull
                lsr
                sta timeframehalf
                ldx #MAX_COLORS-1
colorloop:      lda coltbl,x                ;Set default colors
                sta bgcol,x
                dex
                bpl colorloop
                lda firsttime
                bne skipclear               ;Clear & init songdata
                jsr cleardata
                inc firsttime
skipclear:      jsr stop
                jsr initraster
                jsr initscreen
mainloop:       jsr printstatus
                jsr getkey
                beq mainloop
                jsr generalkeys
                bcs skipeditkeys
                jsr editmodekeys
skipeditkeys:   jsr updatescreen
                jmp mainloop

;-------------------------------------------------------------------------------
; Code to branch into the commands
;-------------------------------------------------------------------------------

generalkeys:    lda #EM_GENERAL
keycommon:      asl
                tax
                lda keytbl,x
                sta destlo
                lda keytbl+1,x
                sta desthi
                lda key
                beq keydone
                ldy #$00
keyloop:        lda (destlo),y
                beq keydone
                cmp #$ff
                beq keyfound
                cmp key
                beq keyfound
                iny
                iny
                iny
                bne keyloop
keydone:        clc
                rts
keyfound:       iny
                lda (destlo),y
                sta keyjump+1
                iny
                lda (destlo),y
                sta keyjump+2
keyjump:        jsr donothing
                sec
                rts

editmodekeys:   lda editmode
                jmp keycommon

;-------------------------------------------------------------------------------
; Go to different editmodes
;-------------------------------------------------------------------------------

edittrk:        lda key
                sec
                sbc #$21
                sta tracknum
                lda #EM_TRACKS
editcommon:     sta editmode
donothing:      rts
editpatt:       lda #EM_PATTERN
                bne editcommon
edittbl:        lda key
                sec
                sbc #$25
                sta tblnum
                lda #EM_TABLES
                bne editcommon
editcmd:        lda #EM_CMD
                bne editcommon

                include nt2playback.s
                include nt2track.s
                include nt2pattern.s
                include nt2table.s
                include nt2command.s
                include nt2disk.s
                include nt2packer.s
                include nt2display.s
                include nt2math.s
                include nt2key.s
                include nt2screen.s
                include nt2raster.s
                include nt2data.s
                include nt2player.s
                include nt2songdata.s
                include nt2var.s
                include nt2helptext.s


