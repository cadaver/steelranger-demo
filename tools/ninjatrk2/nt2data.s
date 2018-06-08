;-------------------------------------------------------------------------------
; Editor data
;-------------------------------------------------------------------------------

rowtbllo:
N               set 0
                repeat 25
                dc.b <($400+40*N)
N               set N+1
                repend

rowtblhi:
N               set 0
                repeat 25
                dc.b >($400+40*N)
N               set N+1
                repend

keytbl:         dc.w trackkeytbl
                dc.w pattkeytbl
                dc.w tblkeytbl
                dc.w cmdkeytbl
                dc.w generalkeytbl

trackkeytbl:    dc.b ":",<prevsong,>prevsong
                dc.b ";",<nextsong,>nextsong
                dc.b " ",<setsongstart,>setsongstart
                dc.b KEY_RETURN,<gotopatt,>gotopatt
                dc.b KEY_SHIFTRETURN,<gotopatt,>gotopatt
                dc.b KEY_LEFT,<trackleft,>trackleft
                dc.b KEY_RIGHT,<trackright,>trackright
                dc.b KEY_UP,<trackup,>trackup
                dc.b KEY_DOWN,<trackdown,>trackdown
                dc.b KEY_INS,<trackins,>trackins
                dc.b KEY_DEL,<trackdel,>trackdel
                dc.b "M"+$80,<marktrack,>marktrack
                dc.b "X"+$80,<cuttrack,>cuttrack
                dc.b "C"+$80,<copytrack,>copytrack
                dc.b "V"+$80,<pastetrack,>pastetrack
                dc.b $ff,<trackedit,>trackedit
                dc.b 0

pattkeytbl:     dc.b ":",<prevpatt,>prevpatt
                dc.b ";",<nextpatt,>nextpatt
                dc.b "-",<prevcmd,>prevcmd
                dc.b "+",<nextcmd,>nextcmd
                dc.b KEY_RETURN,<copynote,>copynote
                dc.b KEY_SHIFTRETURN,<copynote,>copynote
                dc.b KEY_LEFT,<pattleft,>pattleft
                dc.b KEY_RIGHT,<pattright,>pattright
                dc.b KEY_UP,<pattup,>pattup
                dc.b KEY_DOWN,<pattdown,>pattdown
                dc.b KEY_INS,<pattins,>pattins
                dc.b KEY_DEL,<pattdel,>pattdel
                dc.b "Q"+$80,<transup,>transup
                dc.b "A"+$80,<transdown,>transdown
                dc.b "O"+$80,<optimizepatt,>optimizepatt
                dc.b "L"+$80,<legatocmd,>legatocmd
                dc.b "M"+$80,<markpatt,>markpatt
                dc.b "X"+$80,<cutpatt,>cutpatt
                dc.b "C"+$80,<copypatt,>copypatt
                dc.b "V"+$80,<pastepatt,>pastepatt
                dc.b $ff,<pattedit,>pattedit
                dc.b 0

tblkeytbl:      dc.b KEY_RETURN,<followjump,>followjump
                dc.b KEY_LEFT,<tblleft,>tblleft
                dc.b KEY_RIGHT,<tblright,>tblright
                dc.b KEY_UP,<tblup,>tblup
                dc.b KEY_DOWN,<tbldown,>tbldown
                dc.b KEY_INS,<tblins,>tblins
                dc.b KEY_DEL,<tbldel,>tbldel
                dc.b KEY_SHIFTSPACE,<cmtest,>cmtest
                dc.b KEY_SPACE,<cmkeyoff,>cmkeyoff
                dc.b "M"+$80,<marktbl,>marktbl
                dc.b "X"+$80,<cuttbl,>cuttbl
                dc.b "C"+$80,<copytbl,>copytbl
                dc.b "V"+$80,<pastetbl,>pastetbl
                dc.b $ff,<tbledit,>tbledit
                dc.b 0

cmdkeytbl:      dc.b KEY_LEFT,<cmdleft,>cmdleft
                dc.b KEY_RIGHT,<cmdright,>cmdright
                dc.b KEY_UP,<cmdup,>cmdup
                dc.b KEY_DOWN,<cmddown,>cmddown
                dc.b KEY_INS,<cmdins,>cmdins
                dc.b KEY_DEL,<cmddel,>cmddel
                dc.b KEY_RETURN,<gotocmdparam,>gotocmdparam
                dc.b KEY_SHIFTRETURN,<gotocmdparam,>gotocmdparam
                dc.b "X"+$80,<cutcmd,>cutcmd
                dc.b "C"+$80,<copycmd,>copycmd
                dc.b "V"+$80,<pastecmd,>pastecmd
                dc.b "S"+$80,<smartpastecmd,>smartpastecmd
                dc.b $ff,<cmdedit,>cmdedit
                dc.b 0

generalkeytbl:  dc.b KEY_F1,<playstart,>playstart
                dc.b KEY_F3,<stop,>stop
                dc.b KEY_F4,<switchkeymode,>switchkeymode
                dc.b KEY_F5,<playpos,>playpos
                dc.b KEY_F7,<togglefastfwd,>togglefastfwd
                dc.b KEY_F6,<adjustcolors,>adjustcolors
                dc.b KEY_F8,<onlinehelp,>onlinehelp
                dc.b KEY_LEFTARROW,<diskmenu,>diskmenu
                dc.b $21,<edittrk,>edittrk
                dc.b $22,<edittrk,>edittrk
                dc.b $23,<edittrk,>edittrk
                dc.b $24,<editpatt,>editpatt
                dc.b $25,<edittbl,>edittbl
                dc.b $26,<edittbl,>edittbl
                dc.b $27,<edittbl,>edittbl
                dc.b $28,<editcmd,>editcmd
                dc.b "<",<gofastup,>gofastup
                dc.b ">",<gofastdown,>gofastdown
                dc.b ",",<prevoctave,>prevoctave
                dc.b ".",<nextoctave,>nextoctave
                dc.b "[",<prevoctave,>prevoctave
                dc.b "]",<nextoctave,>nextoctave
                dc.b "/",<silenceall,>silenceall
                dc.b 0

namemsgtbl:     dc.w loadtext
                dc.w savetext
                dc.w erasetext
                dc.w packertext

namemsglentbl:  dc.b 10,10,11,15

ptkeytbl:       dc.b "ZSXDCVGBHNJMQ2W3ER5T6Y7UI9O0P"
dmckeytbl:      dc.b "AWSEDFTGYHUJKOLP"

        ;Instruction table for relocation
        ;0 = 2 byte instr., zeropage relocation
        ;1 = 1 byte instr., no relocation
        ;2 = 2 byte instr., no relocation
        ;3 = 3 byte instr., absolute relocation

asmtable:       dc.b $69,2 ;ADC immediate
                dc.b $65,0 ;ADC zeropage
                dc.b $75,0 ;ADC zeropage,X
                dc.b $6d,3 ;ADC absolute
                dc.b $7d,3 ;ADC absolute,X
                dc.b $79,3 ;ADC absolute,Y
                dc.b $61,0 ;ADC indirect,X
                dc.b $71,0 ;ADC indirect,Y

                dc.b $29,2 ;AND immediate
                dc.b $25,0 ;AND zeropage
                dc.b $35,0 ;AND zeropage,X
                dc.b $2d,3 ;AND absolute
                dc.b $3d,3 ;AND absolute,X
                dc.b $39,3 ;AND absolute,Y
                dc.b $21,0 ;AND indirect,X
                dc.b $31,0 ;AND indirect,Y

                dc.b $0a,1 ;ASL accumulator
                dc.b $06,0 ;ASL zeropage
                dc.b $16,0 ;ASL zeropage,X
                dc.b $0e,3 ;ASL absolute
                dc.b $1e,3 ;ASL absolute,X
                dc.b $90,2 ;BCC
                dc.b $b0,2 ;BCS
                dc.b $f0,2 ;BEQ

                dc.b $24,0 ;BIT zeropage
                dc.b $2c,3 ;BIT absolute
                dc.b $30,2 ;BMI
                dc.b $d0,2 ;BNE
                dc.b $10,2 ;BPL
                dc.b $00,1 ;BRK
                dc.b $50,2 ;BVC
                dc.b $70,2 ;BVS

                dc.b $18,1 ;CLC
                dc.b $d8,1 ;CLD
                dc.b $58,1 ;CLI
                dc.b $b8,1 ;CLV
                dc.b $c9,2 ;CMP immediate
                dc.b $c5,0 ;CMP zeropage
                dc.b $d5,0 ;CMP zeropage,X
                dc.b $cd,3 ;CMP absolute

                dc.b $dd,3 ;CMP absolute,X
                dc.b $d9,3 ;CMP absolute,Y
                dc.b $c1,0 ;CMP indirect,X
                dc.b $d1,0 ;CMP indirect,Y
                dc.b $e0,2 ;CPX immediate
                dc.b $e4,0 ;CPX zeropage
                dc.b $ec,3 ;CPX absolute
                dc.b $c0,2 ;CPY immediate

                dc.b $c4,0 ;CPY zeropage
                dc.b $cc,3 ;CPY absolute
                dc.b $c6,0 ;DEC zeropage
                dc.b $d6,0 ;DEC zeropage,X
                dc.b $ce,3 ;DEC absolute
                dc.b $de,3 ;DEC absolute,X
                dc.b $ca,1 ;DEX
                dc.b $88,1 ;DEY

                dc.b $49,2 ;EOR immediate
                dc.b $45,0 ;EOR zeropage
                dc.b $55,0 ;EOR zeropage,X
                dc.b $4d,3 ;EOR absolute
                dc.b $5d,3 ;EOR absolute,X
                dc.b $59,3 ;EOR absolute,Y
                dc.b $41,0 ;EOR indirect,X
                dc.b $51,0 ;EOR indirect,Y

                dc.b $e6,0 ;INC zeropage
                dc.b $f6,0 ;INC zeropage,X
                dc.b $ee,3 ;INC absolute
                dc.b $fe,3 ;INC absolute,X
                dc.b $e8,1 ;INX
                dc.b $c8,1 ;INY
                dc.b $4c,3 ;JMP absolute
                dc.b $6c,3 ;JMP indirect

                dc.b $20,3 ;JSR absolute
                dc.b $a9,2 ;LDA immediate
                dc.b $a5,0 ;LDA zeropage
                dc.b $b5,0 ;LDA zeropage,X
                dc.b $ad,3 ;LDA absolute
                dc.b $bd,3 ;LDA absolute,X
                dc.b $b9,3 ;LDA absolute,Y
                dc.b $a1,0 ;LDA indirect,X

                dc.b $b1,0 ;LDA indirect,Y
                dc.b $a2,2 ;LDX immediate
                dc.b $a6,0 ;LDX zeropage
                dc.b $b6,0 ;LDX zeropage,Y
                dc.b $ae,3 ;LDX absolute
                dc.b $be,3 ;LDX absolute,Y
                dc.b $a0,2 ;LDY immediate
                dc.b $a4,0 ;LDY zeropage

                dc.b $b4,0 ;LDY zeropage,Y
                dc.b $ac,3 ;LDY absolute
                dc.b $bc,3 ;LDY absolute,Y
                dc.b $4a,1 ;LSR accumulator
                dc.b $46,0 ;LSR zeropage
                dc.b $56,0 ;LSR zeropage,X
                dc.b $4e,3 ;LSR absolute
                dc.b $5e,3 ;LSR absolute,X

                dc.b $ea,1 ;NOP
                dc.b $09,2 ;ORA immediate
                dc.b $05,2 ;ORA zeropage
                dc.b $15,2 ;ORA zeropage,X
                dc.b $0d,3 ;ORA absolute
                dc.b $1d,3 ;ORA absolute,X
                dc.b $19,3 ;ORA absolute,Y
                dc.b $01,0 ;ORA indirect,X

                dc.b $11,0 ;ORA indirect,Y
                dc.b $48,1 ;PHA
                dc.b $08,1 ;PHP
                dc.b $68,1 ;PLA
                dc.b $28,1 ;PLP
                dc.b $2a,1 ;ROL accumulator
                dc.b $26,0 ;ROL zeropage

                dc.b $36,2 ;ROL zeropage,X
                dc.b $2e,3 ;ROL absolute
                dc.b $3e,3 ;ROL absolute,X
                dc.b $6a,1 ;ROR accumulator
                dc.b $66,0 ;ROR zeropage
                dc.b $76,0 ;ROR zeropage,X
                dc.b $6e,3 ;ROR absolute
                dc.b $7e,3 ;ROR absolute,X

                dc.b $40,1 ;RTI
                dc.b $60,1 ;RTS
                dc.b $e9,2 ;SBC immediate
                dc.b $e5,0 ;SBC zeropage
                dc.b $f5,0 ;SBC zeropage,X
                dc.b $ed,3 ;SBC absolute
                dc.b $fd,3 ;SBC absolute,X
                dc.b $f9,3 ;SBC absolute,Y

                dc.b $e1,0 ;SBC indirect,X
                dc.b $f1,0 ;SBC indirect,Y
                dc.b $38,1 ;SEC
                dc.b $f8,1 ;SED
                dc.b $78,1 ;SEI
                dc.b $85,0 ;STA zeropage
                dc.b $95,0 ;STA zeropage,X
                dc.b $8d,3 ;STA absolute

                dc.b $9d,3 ;STA absolute,X
                dc.b $99,3 ;STA absolute,Y
                dc.b $81,0 ;STA indirect,X
                dc.b $91,0 ;STA indirect,Y
                dc.b $86,0 ;STX zeropage
                dc.b $96,0 ;STX zeropage,Y
                dc.b $8e,3 ;STX absolute
                dc.b $84,0 ;STY zeropage

                dc.b $94,0 ;STY zeropage,X
                dc.b $8c,3 ;STY absolute
                dc.b $aa,1 ;TAX
                dc.b $a8,1 ;TAY
                dc.b $ba,1 ;TSX
                dc.b $8a,1 ;TXA
                dc.b $9a,1 ;TXS
                dc.b $98,1 ;TYA
                dc.b $ff,0 ;End of table

notetbl:        
                repeat 7
                dc.b 0,2,4,6,8,10,12,14,16,18,20,22
                repend

octavetbl:      ds.b 12,1
                ds.b 12,2
                ds.b 12,3
                ds.b 12,4
                ds.b 12,5
                ds.b 12,6
                ds.b 12,7

coltbl:         dc.b BGCOL,EMPTYCOL,NORMALCOL,HIGHLIGHTCOL,TITLECOL
cursorcoltbl:   dc.b 0,9,8,7,1,7,8,9
pattcoltbl:     dc.b 3,7,8,10,11
tblcoltbl:      dc.b 3,4,6,7
tblhighlighttbl:dc.b $c0,$80,$80
cmdcoltbl:      dc.b 0,1,2,3,5,6,8,9,11,12
cmdmaxcoltbl:   dc.b MAX_CMDNAMELEN-1,9
chnregindex:    dc.b 0,7,14

;-------------------------------------------------------------------------------
; Editor texts
;-------------------------------------------------------------------------------

notenames:      dc.b "C-"
                dc.b "C#"
                dc.b "D-"
                dc.b "D#"
                dc.b "E-"
                dc.b "F-"
                dc.b "F#"
                dc.b "G-"
                dc.b "G#"
                dc.b "A-"
                dc.b "A#"
                dc.b "B-"

notetext:       dc.b "C-1",0
keyofftext:     dc.b "---",0
keyontext:      dc.b "+++",0

emptytracktext: dc.b "--",0
emptytbltext:   dc.b "-- --",0
endpatttext:    dc.b "===END===",0
emptypatttext:  dc.b "--- -- --",0
emptycmdtext:   dc.b "---- -- -- --",0
emptycmdname:   ds.b MAX_CMDNAMELEN," "
                dc.b 0

emptyrowtext:   dc.b "                                        ",0

titletext:      dc.b "NinjaTrackerV2.04",0
statustext:     dc.b "Sng  Oct        Ras / ",0

tracktext:      dc.b "Trk 1 Trk 2 Trk 3",0
patttext1:      dc.b "Patt",0
patttext2:      dc.b " D",0
patttext3:      dc.b " Ps",0
tbltext:        dc.b "Wave Tbl Puls Tbl Filt Tbl",0
cmdtext:        dc.b "Commands",0

disktext:       dc.b "Disk Menu",0
                dc.b " ",0
                dc.b "C Change Device",0
                dc.b "D Directory",0
                dc.b "L Load Song",0
                dc.b "S Save Song",0
                dc.b "E Erase File",0
                dc.b "P Pack & Relocate",0
                dc.b "G Global Settings",0
                dc.b "N Nuke Songdata",0
                dc.b "X Exit NinjaTracker",0

devicetext:     dc.b "Device number:",0

globaltext:     dc.b "Hardrestart SR:",0
                dc.b "Initframe wave:",0

loadtext:       dc.b "Load Song:",0
savetext:       dc.b "Save Song:",0
erasetext:      dc.b "Erase File:",0
packertext:     dc.b "Output To File:",0

confirmtext:    dc.b "Confirm (Y/N)?",0

hexcodes:       dc.b "0123456789ABCDEFGHIJKLMN",0

packtext1:      dc.b "Pack & Relocate",0
packtext2:      dc.b "Normal/Gmusic:",0
packtext3:      dc.b "Start address:",0
packtext4:      dc.b "Zeropage base:",0

packres1:       dc.b "Playroutine:",0
packres2:       dc.b "Musicdata:",0
packres3:       dc.b "Total size:",0

