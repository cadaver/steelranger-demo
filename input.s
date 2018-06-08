JOY_UP          = $01
JOY_DOWN        = $02
JOY_LEFT        = $04
JOY_RIGHT       = $08
JOY_FIRE        = $10
JOY_OVERRIDE    = $80

KEY_DEL         = 0
KEY_RETURN      = 1
KEY_CURSORLR    = 2
KEY_F7          = 3
KEY_F1          = 4
KEY_F3          = 5
KEY_F5          = 6
KEY_CURSORUD    = 7
KEY_3           = 8
KEY_W           = 9
KEY_A           = 10
KEY_4           = 11
KEY_Z           = 12
KEY_S           = 13
KEY_E           = 14
KEY_SHIFT1      = 15
KEY_5           = 16
KEY_R           = 17
KEY_D           = 18
KEY_6           = 19
KEY_C           = 20
KEY_F           = 21
KEY_T           = 22
KEY_X           = 23
KEY_7           = 24
KEY_Y           = 25
KEY_G           = 26
KEY_8           = 27
KEY_B           = 28
KEY_H           = 29
KEY_U           = 30
KEY_V           = 31
KEY_9           = 32
KEY_I           = 33
KEY_J           = 34
KEY_0           = 35
KEY_M           = 36
KEY_K           = 37
KEY_O           = 38
KEY_N           = 39
KEY_PLUS        = 40
KEY_P           = 41
KEY_L           = 42
KEY_MINUS       = 43
KEY_COLON       = 44
KEY_DOUBLECOLON = 45
KEY_AT          = 46
KEY_COMMA       = 47
KEY_POUND       = 48
KEY_ASTERISK    = 49
KEY_SEMICOLON   = 50
KEY_HOME        = 51
KEY_SHIFT2      = 52
KEY_EQUALS      = 53
KEY_ARROWU      = 54
KEY_SLASH       = 55
KEY_1           = 56
KEY_ARROWL      = 57
KEY_CTRL        = 58
KEY_2           = 59
KEY_SPACE       = 60
KEY_CBM         = 61
KEY_Q           = 62
KEY_RUNSTOP     = 63
KEY_NONE        = $ff

        ; Read joystick + scan the keyboard
        ;
        ; Parameters: -
        ; Returns: -
        ; Modifies: A,X,Y,zpBitBuf

GetControls:    ldy #$ff
                sty $dc00
                sty keyType
                lda joystick
                sta prevJoy
                lda $dc00
                eor #$ff
                and #JOY_UP|JOY_DOWN|JOY_LEFT|JOY_RIGHT|JOY_FIRE
                cmp #JOY_FIRE
GC_JoystickAnd: and #$ff
                sta joystick
                bcs GC_HasFire
                sty GC_JoystickAnd+1    ;Reset joystick control AND bits if fire not pressed
GC_HasFire:     ldy #$07
GC_RowLoop:     lda bitTbl,y
                eor #$ff
                sta $dc00
                lda $dc01
                cmp #$ff
                bne GC_RowFound
GC_RowEmpty:    dey
                bpl GC_RowLoop
                bmi GC_NoKey
GC_RowFound:    tax
                tya
                asl
                asl
                asl
                sta zpBitBuf
                txa
                ldy #$07
GC_ColLoop:     asl
                bcc GC_KeyFound
                dey
                bpl GC_ColLoop
GC_KeyFound:    tya
                ora zpBitBuf
                cmp keyPress
                beq GC_SameKey
                sta keyType
GC_SameKey:
GC_NoKey:       sta keyPress
                rts

        ; Return whether fire has been pressed down (not held down)
        ;
        ; Parameters: -
        ; Returns: C=1 pressed C=0 not pressed
        ; Modifies: A

GetFireClick:   clc
                lda prevJoy
                and #JOY_FIRE
                bne GFC_Not
                lda joystick
                adc #$100-JOY_FIRE              ;C=1 if fire pressed
GFC_Not:        rts
