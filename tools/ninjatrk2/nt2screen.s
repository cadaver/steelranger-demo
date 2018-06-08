;-------------------------------------------------------------------------------
; Detect PAL/NTSC
;-------------------------------------------------------------------------------

detectntsc:     lda #$00
dnloop:         ldx $d011                   ;Get the biggest rasterline in the
                bmi dnloop                  ;area >= 256 to detect NTSC/PAL
dnloop2:        ldx $d011
                bpl dnloop2
dnloop3:        cmp $d012
                bcs dnloop4
                lda $d012
dnloop4:        ldx $d011
                bmi dnloop3
                cli
                cmp #$30
                rts

;-------------------------------------------------------------------------------
; Init VIC-II, clear/redraw screen
;-------------------------------------------------------------------------------

initscreen:     sta $d07a                   ;SCPU to slow mode
                lda #$0b
                sta $d022
                lda #$0c
                sta $d023
                lda #$03
                sta $dd00
                lda #$08
                sta $d016
                lda #$1b
                sta $d011
                lda #22
                sta $d018
                lda #$80
                sta mode
                jsr clearscreen
changecolors2:  lda titlecol
                sta textcolor
                ldx #0
                ldy #0
                jsr setxy
                ldx #<titletext
                ldy #>titletext
                jsr printtext
changecolors:   lda bgcol
                sta $d020
                sta $d021
                lda titlecol
                sta textcolor
                ldx #18
                ldy #0
                jsr setxy
                ldx #<statustext
                ldy #>statustext
                jsr printtext
                jsr printstatus
                jmp printall

;-------------------------------------------------------------------------------
; Clear screen
;-------------------------------------------------------------------------------

clearscreen:    lda #$20
                ldx #$00
                stx $d015
cs_loop:        sta $0400,x
                sta $0500,x
                sta $0600,x
                sta $0700,x
                inx
                bne cs_loop
                rts

;-------------------------------------------------------------------------------
; Position sprite cursor
; X=X position
; Y=Y position
; A=Width ($00 normal, $ff wide)
;-------------------------------------------------------------------------------

cursorpos:
N               set 0
                repeat 8
                sta $0801+N*3
                sta $0802+N*3
N               set N+1
                repend
                lda #$ff
N               set 0
                repeat 8
                sta $0800+N*3
N               set N+1
                repend
                sta $d01b                
                lda #$00
                sta $d01c
                sta $d017
                sta $d019
                tya
                asl
                asl
                asl
                adc #50
                tay
                txa
                asl
                asl
                adc #12
                asl
                sta $d000
                lda #$00
                rol
                sta $d010
                sty $d001
                lda #$01
                sta $d015
                rts

;-------------------------------------------------------------------------------
; Set cursor pos
; X=X position
; Y=Y position
;-------------------------------------------------------------------------------

setxy:          txa
                clc
                adc rowtbllo,y
                sta scrlo
                sta colorlo
                lda #$00
                adc rowtblhi,y
                sta scrhi
                eor #$dc
                sta colorhi
                rts

;-------------------------------------------------------------------------------
; Print nullterminated text
; X=Text address lowbyte
; Y=Text address highbyte
;-------------------------------------------------------------------------------

printtext:      stx textlo
                sty texthi
printtextcont:  ldy #$00
pt_loop:        lda (textlo),y
                beq pt_done
                cmp #96
                bcc pt_nolowercase
                sbc #96
pt_nolowercase: sta (scrlo),y
                lda textcolor
                sta (colorlo),y
                iny
                jmp pt_loop
pt_done:        tya
                sec
                adc textlo
                sta textlo
                lda texthi
                adc #$00
                sta texthi
                tya
skipchars:
pt_addscrpos:   clc
                adc scrlo
                sta scrlo
                sta colorlo
                bcc pt_aspok
                inc scrhi
                inc colorhi
pt_aspok:       rts

;-------------------------------------------------------------------------------
; Print empty row
; Y=Row to clear
;-------------------------------------------------------------------------------

printemptyrow:  ldx #0
                jsr setxy
printemptyrow2: ldx #<emptyrowtext
                ldy #>emptyrowtext
                jmp printtext

;-------------------------------------------------------------------------------
; Print 8bit value as hexadecimal
; A=Value
;-------------------------------------------------------------------------------

printhex8:      pha
                lsr
                lsr
                lsr
                lsr
                tax
                ldy #$00
                lda hexcodes,x
                sta (scrlo),y
                lda textcolor
                sta (colorlo),y
                pla
                and #$0f
                tax
                iny
                lda hexcodes,x
                sta (scrlo),y
                lda textcolor
                sta (colorlo),y
                lda #$02
                jmp skipchars
                
;-------------------------------------------------------------------------------
; Print 16bit value as hexadecimal
; X,Y=Value
;-------------------------------------------------------------------------------

printhex16:     txa
                pha
                tya
                jsr printhex8
                pla
                jmp printhex8

;-------------------------------------------------------------------------------
; Print 16bit value as decimal (4 digits)
; X,Y=Value
;-------------------------------------------------------------------------------

printdec16:     jsr pd16convert
                lda ahi2
                jsr printhex8
                lda alo2
                jmp printhex8

pd16convert:    stx alo
                sty ahi
                lda #$00
                sta alo2
                sta ahi2
                sed
                ldx #16
pd16_loop:      asl alo
                rol ahi
                lda alo2
                adc alo2
                sta alo2
                lda ahi2
                adc ahi2
                sta ahi2
                dex
                bne pd16_loop
                cld
                rts

;-------------------------------------------------------------------------------
; Print 8bit value as decimal
; A=Value
;-------------------------------------------------------------------------------

printdec8:      tax
                ldy #$00
                jsr pd16convert
                lda alo2
                jmp printhex8

;-------------------------------------------------------------------------------
; Print single hexadecimal digit
; A=Digit
;-------------------------------------------------------------------------------

printdigit:     and #$0f
                tax
                ldy #$00
                lda hexcodes,x
                sta (scrlo),y
                lda textcolor
                sta (colorlo),y
                lda #$01
                jmp skipchars

;-------------------------------------------------------------------------------
; Print single character
; A=Character
;-------------------------------------------------------------------------------

printchar:      ldy #$00
                cmp #96
                bcc pc_nolowercase
                sbc #96
pc_nolowercase: sta (scrlo),y
                lda textcolor
                sta (colorlo),y
                lda #$01
                jmp skipchars

