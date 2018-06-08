F_MAIN          = $00
F_TITLE         = $01
F_OPTIONS       = $02
F_SAVE          = $03
F_MUSIC         = $07
F_CHARSET       = $13
F_LEVEL         = $20
F_CHUNK         = $33-3                         ;Account for first chunk being the level, and common/player being always resident

C_LEVEL         = 0
C_COMMON        = 1
C_PLAYER        = 2
C_CREW          = 3
C_ENEMIES0      = 4
C_ENEMIES1      = 5
C_ENEMIES2      = 6
C_ENEMIES3      = 7
C_ENEMIES4      = 8
C_ENEMIES5      = 9
C_ENEMIES6      = 10
C_ENEMIES7      = 11
C_ENEMIES8      = 12
C_ENEMIES9      = 13
C_ENEMIES10     = 14
C_BOSS0         = 15
C_BOSS1         = 16
C_BOSS2         = 17
C_BOSS3         = 18
C_BOSS4         = 19
C_BOSS5         = 20
C_CREW2         = 21
C_SCRIPT0       = 22
C_SCRIPT1       = 23
C_SCRIPT2       = 24
C_SCRIPT3       = 25
C_SCRIPT4       = 26
C_SCRIPT5       = 27
C_SCRIPT6       = 28
C_SCRIPT7       = 29
C_SCRIPT8       = 30
C_SCRIPT9       = 31
C_SCRIPT10      = 32
C_SCRIPT11      = 33
C_SCRIPT12      = 34
C_SCRIPT13      = 35
C_SCRIPT14      = 36
C_SCRIPT15      = 37
C_SCRIPT16      = 38
C_SCRIPT17      = 39
C_SCRIPT18      = 40
C_SCRIPT19      = 41
C_SCRIPT20      = 42
C_SCRIPT21      = 43
C_SCRIPT22      = 44
C_SCRIPT23      = 45
C_SCRIPT24      = 46
C_SCRIPT25      = 47
C_SCRIPT26      = 48
C_SCRIPT27      = 49
C_SCRIPT28      = 50
C_SCRIPT29      = 51

C_FIRSTSPR      = C_COMMON
C_FIRSTPURGEABLE = C_CREW
C_FIRSTSCRIPT   = C_SCRIPT0
C_LAST          = C_SCRIPT29

USE_ORDERED_PURGE = 0

        ; Create a number-based file name
        ;
        ; Parameters: A file number, X file number add
        ; Returns: fileName,C=0
        ; Modifies: A,X,zpSrcLo

MakeFileName:   stx zpSrcLo
                clc
                adc zpSrcLo
MakeFileName_Direct:
                sta fileNumber
LF_NoError:     rts

        ; Load a compressed file, hang on error
        ;
        ; Parameters: A,X depack address, fileName
        ; Returns: C=0
        ; Modifies: A,X,Y,loader zp vars

LoadFileHandleError:
                jsr LoadFile
                bcc LF_NoError
LF_Error:       lda #$02
                sta $d020
                jmp LF_Error

        ; Allocate & load a chunk-resource file, and return address of object from inside.
        ; If no memory, purge unused files. In case of unrecoverable IO error, will hang.
        ;
        ; Parameters: A object number, Y chunk file number
        ; Returns: temp6 chunk file number, zpDestLo-Hi file address, zpSrcLo-Hi object address
        ; Modifies: A,X,Y,temp6-temp8,loader temp vars

LoadChunkFileWithName:
                pha
                sty temp6
                jsr PurgeFile
                jmp LF_CustomFileName

LoadChunkFile:  pha
                sty temp6
LF_WasLoaded:   lda fileHi,y
                beq LF_NotInMemory
                sta zpDestHi
                lda fileLo,y
                sta zpDestLo                    ;Reset file age whenever accessed
                lda #$00
                sta fileAge,y
                pla
                asl
                tay
LF_GetObjectAddress:
                lda (zpDestLo),y
                sta zpSrcLo
                iny
                lda (zpDestLo),y
                sta zpSrcHi
                rts
LF_NotInMemory: tya
                ldx #F_CHUNK
                jsr MakeFileName
LF_CustomFileName:
                jsr AgeFiles                    ;Age all files now so we are sure to have something to purge
                jsr OpenFile
                jsr GetByte                     ;Get datasize lowbyte, or abort due to error
                bcs LF_Error
                sta temp7
                jsr GetByte                     ;Get datasize highbyte
                sta temp8
                jsr GetByte                     ;Get object count
                pha
                jsr PurgeUntilFree
                lda freeMemLo
                ldx freeMemHi
                jsr LoadFileHandleError

        ; Finish loading, relocate chunk object pointers

                ldy temp6
                pla
                sta fileNumObjects,y
                lda freeMemLo                   ;Increment free mem pointer
                sta zpBitsLo
                sta zpDestLo
                sta fileLo,y
                adc temp7                       ;C=0 here
                sta freeMemLo
                lda freeMemHi
                sta zpBitsHi
                sta zpDestHi
                sta fileHi,y
                adc temp8
                sta freeMemHi
                cpy #C_FIRSTSCRIPT              ;Is script that requires code relocation?
                bcc LF_NotScript
                lda zpBitsHi                    ;Scripts are initially relocated at $8000
                sbc #>scriptCodeRelocStart      ;to distinguish between resident & loadable code
                sta zpBitsHi
LF_NotScript:   jsr LF_Relocate
                ldy temp6
                jmp LF_WasLoaded                ;Retry getting the object address now

LF_Relocate:    ldx fileNumObjects,y
                sty zpBitBuf
                ;txa                            ;There are no objectless files
                ;beq LF_RelocDone
                ldy #$00
LF_RelocateLoop:lda (zpDestLo),y                ;Relocate object pointers
                clc
                adc zpBitsLo
                sta (zpDestLo),y
                iny
                lda (zpDestLo),y
                adc zpBitsHi
                sta (zpDestLo),y
                iny
                dex
                bne LF_RelocateLoop
LF_RelocDone:   ldy zpBitBuf
                cpy #C_FIRSTSCRIPT
                bcc LF_NoCodeReloc
                lda fileNumObjects,y            ;Assume that code starts immediately past the object pointers
                asl
                adc zpDestLo
                sta zpSrcLo
                lda zpDestHi
                adc #$00
                sta zpSrcHi
LF_CodeRelocLoop:
                ldy #$00
                lda (zpSrcLo),y                 ;Read instruction
                beq LF_CodeRelocDone            ;BRK - done
                lsr
                lsr
                lsr
                bcc LF_LookupLength
                and #$01                        ;Instructions xc - xf are always 3 bytes
                ora #$02                        ;Instructions x4 - x7 are always 2 bytes
                bne LF_HasLength
LF_LookupLength:tax
                lda (zpSrcLo),y
                and #$03
                tay
                lda instrLenTbl,x               ;4 lengths packed into one byte
LF_DecodeLength:dey
                bmi LF_DecodeLengthDone
                lsr                             ;Shift until we have the one we want
                lsr
                bpl LF_DecodeLength
LF_DecodeLengthDone:
                and #$03
LF_HasLength:   cmp #$03                        ;3 byte long instructions need relocation
                bne LF_NotAbsolute
                ldy #$02
                lda (zpSrcLo),y                 ;Read absolute address highbyte
                cmp #>(fileAreaStart+$100)      ;Is it a reference to self or to resident code/data?
                bcc LF_NoRelocation             ;(filearea start may not be page-aligned, but the common sprites
                cmp #>fileAreaEnd               ;will always be first)
                bcs LF_NoRelocation
                dey
                lda (zpSrcLo),y                 ;Add relocation offset to the absolute address
                adc zpBitsLo
                sta (zpSrcLo),y
                iny
                lda (zpSrcLo),y
                adc zpBitsHi
                sta (zpSrcLo),y
LF_NoRelocation:lda #$03
LF_NotAbsolute: ldx #<zpSrcLo
                jsr Add8
                jmp LF_CodeRelocLoop
LF_CodeRelocDone:
LF_NoCodeReloc: rts

        ; Copy a block of memory
        ;
        ; Parameters: A,X: destination, zpSrcLo,Hi source zpBitsLo,Hi amount of bytes
        ; Returns: N=1
        ; Modifies: A,X,Y,loader temp vars

CopySaveMemory: ldy #<(playerStateEnd-playerStateStart)
                sty zpBitsLo
                ldy #>(playerStateEnd-playerStateStart)
                sty zpBitsHi
CopyMemory:     sta zpDestLo
                stx zpDestHi
CopyMemory_PointersSet:
                ldy #$00
                ldx zpBitsLo                    ;Predecrement highbyte if lowbyte 0 at start
                beq CM_Predecrement
CM_Loop:        lda (zpSrcLo),y
                sta (zpDestLo),y
                iny
                bne CM_NotOver
                inc zpSrcHi
                inc zpDestHi
CM_NotOver:     dex
                bne CM_Loop
CM_Predecrement:dec zpBitsHi
                bpl CM_Loop
PUF_HasFreeMemory:
                if USE_ORDERED_PURGE = 0
PF_Done:
                endif
                rts

        ; Remove files until enough memory to load the new file
        ;
        ; Parameters: temp7-temp8 new object size, zoneBufferLo-Hi zone buffer start (alloc area end)
        ; Returns: -
        ; Modifies: A,X,Y,loader temp vars

PurgeUntilFreeNoNew:
                lda #$00
                sta temp7
                sta temp8
PurgeUntilFree: lda freeMemLo
                sta zpBitsLo
                lda freeMemHi
                sta zpBitsHi
                ldx #<zpBitsLo
                ldy #<temp7
                jsr Add16

                if USE_ORDERED_PURGE = 0

                lda zpBitsLo
                cmp zoneBufferLo
                lda zpBitsHi
                sbc zoneBufferHi
                bcc PUF_HasFreeMemory
PUF_Loop:       jsr FindOldestChunk
                jsr PurgeFile
                jmp PurgeUntilFree

                else

                jsr PUF_Compare
                bcc PUF_HasFreeMemory
                lda #<purgeList
                sta PUF_StoreChunkNum+1
PUF_Loop:       jsr FindOldestChunk
                jsr FindChunkEnd
                ldy zpLenLo
PUF_StoreChunkNum:
                sty purgeList
                bmi PUF_PurgeLoop
                inc PUF_StoreChunkNum+1
                lda #$00                        ;Reset age already so that the same chunk won't be
                sta fileAge,y                   ;erroneously reconsidered
                lda fileLo,y                    ;Turn chunk end to negative chunk length
                sec
                sbc zpSrcLo
                sta zpSrcLo
                lda fileHi,y
                sbc zpSrcHi
                sta zpSrcHi
                ldx #<zpBitsLo                  ;Adjust the simulated free mem pointer
                ldy #<zpSrcLo
                jsr Add16
                jsr PUF_Compare                 ;Continue finding chunks until enough free
                bcs PUF_Loop
                ldy #$ff                        ;Store purge list endmark
                bmi PUF_StoreChunkNum
PUF_PurgeLoop:  ldx #$00
                stx zpSrcLo
                stx zpSrcHi
PUF_FindLastLoop:
                ldy purgeList,x                 ;Find the last of purgelist in memory
                bmi PUF_Endmark                 ;to reduce unnecessary memory shifting
                lda fileLo,y
                cmp zpSrcLo
                lda fileHi,y
                beq PUF_FindLastNext
                sbc zpSrcHi
                bcc PUF_FindLastNext
PUF_FindLastStore:
                sty zpLenLo
                lda fileLo,y
                sta zpSrcLo
                lda fileHi,y
                sta zpSrcHi
PUF_FindLastNext:
                inx
                bne PUF_FindLastLoop
PUF_Endmark:    lda zpSrcHi                     ;All in purgelist already purged?
                beq PUF_Done
                ldy zpLenLo
                jsr PurgeFile
                jmp PUF_PurgeLoop

PUF_Compare:    lda zpBitsLo
                cmp zoneBufferLo
                lda zpBitsHi
                sbc zoneBufferHi
PF_Done:
PUF_Done:       rts

                endif

        ; Remove a chunk-file from memory
        ;
        ; Parameters: Y file number
        ; Returns: -
        ; Modifies: A,X,loader temp vars

PurgeFile:      lda fileHi,y
                beq PF_Done
                lda #$ff                        ;Invalidate last used spritefile, as it may now move in memory
                sta sprFileNum
                jsr FindChunkEnd
                lda freeMemLo                   ;How much memory to shift
                sec
                sbc zpSrcLo
                sta zpBitsLo
                lda freeMemHi
                sbc zpSrcHi
                sta zpBitsHi
                jsr CopyMemory_PointersSet
                lda zpDestLo
                sec
                sbc zpSrcLo
                sta zpBitsLo
                lda zpDestHi
                sbc zpSrcHi
                sta zpBitsHi                    ;Negative delta to filepointers
                ldx #<freeMemLo
                ldy #<zpBitsLo
                jsr Add16                       ;Shift the free memory pointer
                lda dialogueHi                  ;Relocate current dialogue ptr if necessary
                beq PF_NoDialogue
                ldx zpLenLo
                lda dialogueLo
                cmp fileLo,x
                lda dialogueHi
                sbc fileHi,x
                bcc PF_NoDialogue
                ldx #<dialogueLo
                ldy #<zpBitsLo
                jsr Add16
PF_NoDialogue:  ldy #MAX_CHUNKFILES-1
PF_RelocLoop:   cpy zpLenLo                     ;Do not relocate itself
                beq PF_RelocNext
                ldx zpLenLo
                lda fileLo,y                    ;Need relocation? (higher in memory than purged file)
                cmp fileLo,x
                lda fileHi,y
                sbc fileHi,x
                bcc PF_RelocNext
PF_RelocOk:     lda fileLo,y                    ;Relocate the file pointer
                clc
                adc zpBitsLo
                sta fileLo,y
                sta zpDestLo
                lda fileHi,y
                adc zpBitsHi
                sta fileHi,y
                sta zpDestHi
                jsr LF_Relocate                 ;Relocate the object pointers
                ldy zpBitBuf
PF_RelocNext:   dey
                bpl PF_RelocLoop
                ldy zpLenLo
                lda #$00
                sta fileHi,y                    ;Mark chunk not in memory
                sta fileAge,y                   ;and reset age for eventual reload
                rts

        ; Find end of chunk's data by comparing to next chunk pointers
        ;
        ; Parameters: Y file number
        ; Returns: chunk end in zpSrcLo-Hi, file number in zpLenLo
        ; Modifies: A,X,Y,loader temp vars
        
FindChunkEnd:   sty zpLenLo
                lda fileLo,y
                sta zpDestLo
                lda fileHi,y
                sta zpDestHi
                lda freeMemLo
                sta zpSrcLo
                lda freeMemHi
                sta zpSrcHi
                ldx #MAX_CHUNKFILES-1
PF_FindSizeLoop:cpx zpLenLo
                beq PF_FindSizeSkip
                ldy fileLo,x
                cpy zpDestLo
                lda fileHi,x
                sbc zpDestHi
                bcc PF_FindSizeSkip
                cpy zpSrcLo
                lda fileHi,x
                sbc zpSrcHi
                bcs PF_FindSizeSkip
                sty zpSrcLo
                lda fileHi,x
                sta zpSrcHi
PF_FindSizeSkip:dex
                bpl PF_FindSizeLoop
                rts

        ; Find the currently oldest chunk
        ; 
        ; Parameters: -
        ; Returns: file number in Y
        ; Modifies: A,X,Y,zpBitBuf
        
FindOldestChunk:ldx #$01
                stx zpBitBuf
                dex
                txa
FOC_Loop:       ldy fileAge,x
                cpy zpBitBuf
                bcc FOC_Skip
                sty zpBitBuf
                txa
FOC_Skip:       inx
                cpx #MAX_CHUNKFILES
                bcc FOC_Loop
                tay
                rts

        ; Depack Exomizer packed data from memory
        ;
        ; Parameters: A,X: destination, zpSrcLo,Hi source
        ; Returns: C=0
        ; Modifies: A,X,Y,loader temp vars

DepackFromMemory:
                ldy zpSrcLo
                sty DFM_GetByte+1
                ldy zpSrcHi
                sty DFM_GetByte+2
DepackFromMemoryContinue:
                sta zpDestLo
                stx zpDestHi
                jsr SwitchGetByte
                jsr Depack
SwitchGetByte:  ldx #$02
SWG_Loop:       lda GetByte,x
                eor getByteJump,x
                sta GetByte,x
                dex
                bpl SWG_Loop
                rts

DFM_GetByte:    lda $1000
                inc DFM_GetByte+1
                bne DFM_GetByteNoHigh
                inc DFM_GetByte+2
DFM_GetByteNoHigh:
                clc
                rts

getByteJump:    jmp DFM_GetByte                 ;Getbyte jump for loading from memory

        ; Age all chunkfiles
        ;
        ; Parameters: -
        ; Returns: -
        ; Modifies: A,X,Y

AgeFiles:       ldx #C_FIRSTPURGEABLE           ;First chunk to age
AF_Loop:        ldy fileHi,x
                beq AF_Skip
                lda fileAge,x                   ;Needless to age past $80
                bmi AF_Skip
                inc fileAge,x
AF_Skip:        inx
                cpx #MAX_CHUNKFILES
                bcc AF_Loop
                rts