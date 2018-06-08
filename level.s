SCREENSIZEX     = 19
SCREENSIZEY     = 10

OBJ_MODEBITS    = $03
OBJ_TYPEBITS    = $0c
OBJ_AUTODEACT   = $10
OBJ_ACTIVE      = $80

OBJMODE_NONE    = $00
OBJMODE_TRIG    = $01
OBJMODE_MAN     = $02
OBJMODE_MANAD   = $03

OBJTYPE_NONE    = $00
OBJTYPE_WALL    = $04
OBJTYPE_SWITCH  = $08
OBJTYPE_SCRIPT  = $0c

OBJANIM_DELAY   = 1
AUTODEACT_DELAY = 12

NO_OBJECT       = $ff

NO_SCRIPT       = $ff

        ; Change zone. Load level if necessary, load charset and depack map.
        ;
        ; Parameters: X: world X destination
        ;             Y: world Y destination
        ; Returns: zoneNum, levelNum set
        ; Modifies: A,X,Y,loader temp vars,temp vars

ChangeZone:     stx temp4
                sty temp5
                jsr BlankScreen
                jsr AgeFiles                    ;Age files now so we have a better idea of what was recently used
                ldx #MAX_ACT-1
CZ_RLALoop:     lda actT,x                      ;Remove all actors (except player) from screen
                beq CZ_RLASkip
                jsr RemoveLevelActor
CZ_RLASkip:     dex
                bne CZ_RLALoop
                ldy autoDeactObj                ;If autodeactivating an object in the old zone, finish now
                bmi CZ_NoAutoDeact
                jsr DeactivateObject
CZ_NoAutoDeact: lda levelNum                    ;If in "no level" and about to load, do not store to global actors
                bmi CZ_SkipRemoveRespawning
CZ_FirstFreeLevelAct:
                ldx #MAX_LVLACT-1               ;When changing zone, remove any temp respawning and global actors
CZ_RemoveRespawning:                            ;stored at the end of levelactor-table
                lda lvlActZ,x
                and #RESPAWN|GLOBAL
                beq CZ_RemoveRespawningNext
                jsr CZ_ProcessRespawnOrGlobal
CZ_RemoveRespawningNext:
                inx
                bpl CZ_RemoveRespawning
CZ_SkipRemoveRespawning:
CZ_FindZoneAndLevel:
                ldy #$ff
CZ_FindZoneNext:iny
                lda temp4                       ;Check left bound
                cmp zoneX,y
                bcc CZ_FindZoneNext
                lda temp5                       ;Check top bound
                cmp zoneY,y
                bcc CZ_FindZoneNext
                lda zoneSize,y
                tax
                lsr
                lsr
                lsr
                lsr
                clc
                adc zoneY,y
                sbc temp5                       ;Intentionally subtract one more, check bottom bound
                bcc CZ_FindZoneNext
                txa
                and #$0f
                clc
                adc zoneX,y
                sbc temp4                       ;Intentionally subtract one more, check right bound
                bcc CZ_FindZoneNext
                sty CZ_GlobalZoneNum+1
                lda zoneX,y                     ;Set map world coordinate
                sta worldX
                lda zoneY,y
                sta worldY
                tya                             ;Global zonenumber
                pha
                jsr DecodeBit
                ora zoneBits,y
                sta zoneBits,y                  ;Mark global zone visited
                pla
                ldx #$ff
CZ_FindLevelNext:
                inx                             ;Check into which level the zone belongs
                cmp lvlZoneStart+1,x
                bcs CZ_FindLevelNext
                stx CZ_NewLevelNum+1
                sec
                sbc lvlZoneStart,x
                sta zoneNum                     ;Zone number within level

                lda musicDataLo                 ;Forget zone buffer now to allow maximum memory area while
                sta zoneBufferLo                ;loading
                lda musicDataHi
                sta zoneBufferHi

                lda songOverride
                bne CZ_HasSongOverride
                lda lvlSongTbl,x                ;Start music fade first if music should be loaded now
CZ_HasSongOverride:
                sta CZ_SongNum+1                ;Needs to be done in advance, as PrepareSong just cuts the current one to silence
                lsr
                lsr
                cmp PS_LoadedMusic+1
                beq CZ_SameSong
                jsr FadeSong
CZ_SameSong:    cpx levelNum
                bne CZ_ChangeLevel
                jmp CZ_SameLevel
CZ_ChangeLevel: jsr StoreLevelBits              ;Store current level's bits before changing
CZ_NewLevelNum: lda #$00
                sta levelNum
                cmp #LEVEL_DEMOEND
                bne CZ_NotDemoEnd
                jmp CZ_EndDemoVersion
CZ_NotDemoEnd:  ldx #F_LEVEL
                jsr MakeFileName
                tax
                ldy #C_LEVEL                    ;Load level chunk, get address of first object (packed data)
                tya
CZ_LastLoadedLevel:
                cpx #$ff                        ;Actually load a new level?
                bne CZ_ActualNewLevel
                jsr LoadChunkFile               ;No-op, just get object address
                jmp CZ_DepackLevel
CZ_ActualNewLevel:
                stx CZ_LastLoadedLevel+1
                jsr LoadChunkFileWithName
CZ_DepackLevel: lda #<lvlZoneCharset            ;Depack zone/object/actor data first
                ldx #>lvlZoneCharset
                jsr DepackFromMemory
CZ_ApplyLevelBits:
                ldx levelNum
                lda lvlNumActors,x              ;Store number of levelactors for global/respawn cleanup purposes
                sta CZ_FirstFreeLevelAct+1
                ldy lvlObjBitStart,x
                lda lvlObjBitStart+1,x
                sta CZ_ALOBEndCmp+1
                ldx #$00
                beq CZ_ALOBStart
CZ_ALOBLoop:    lda lvlObjBits,y
                and temp8
                beq CZ_ALOBInactive
                lda lvlObjFlags,x
                ora #OBJ_ACTIVE
                sta lvlObjFlags,x
CZ_ALOBInactive:inx
                asl temp8
                bne CZ_ALOBLoop
                iny
CZ_ALOBStart:   lda #$01
                sta temp8
CZ_ALOBEndCmp:  cpy #$00
                bcc CZ_ALOBLoop
                ldx levelNum
                ldy lvlActBitStart,x
                lda lvlActBitStart+1,x
                sta CZ_ALABEndCmp+1
                ldx #$00
                beq CZ_ALABStart
CZ_ALABLoop:    lda lvlActZ,x
                asl
                bpl CZ_ALABNotRespawning
                inx
                bne CZ_ALABLoop
CZ_ALABNotRespawning:
                lda lvlActBits,y
                and temp8
                bne CZ_ALABAlive
                sta lvlActT,x
CZ_ALABAlive:   inx
                asl temp8
                bne CZ_ALABLoop
                iny
CZ_ALABStart:   lda #$01
                sta temp8
CZ_ALABEndCmp:  cpy #$00
                bcc CZ_ALABLoop
CZ_SameLevel:   ldy zoneNum
                lda lvlZoneCharset,y
CZ_LoadedCharset:
                cmp #$ff                        ;Load charset if required
                beq CZ_SameCharset
                sta CZ_LoadedCharset+1
                ldx #F_CHARSET
                jsr MakeFileName
                lda #<blkInfo
                ldx #>blkInfo
                jsr LoadFile
CZ_SameCharset: lda CZ_SongNum+1                ;Load level song now
                jsr PrepareSong

                lda #MAX_LVLACT-1               ;Find levelactors in the current zone
                sta wpnLo
                sta sprFileNum                  ;Make sure spritefilenum is reset for precaching
                lda #$00
                sta wpnHi
                ldx #MAX_GLOBALACT-1            ;First move global to the list end
CZ_GetZoneGlobalActors:
                lda globalActT,x
                beq CZ_GZGANext
                lda globalActL,x
                cmp levelNum
                bne CZ_GZGANext
                lda globalActZ,x
                and #MAX_LVLZONES-1
                cmp zoneNum
                bne CZ_GZGANext
                ldy wpnLo
                dec wpnLo
                if CHECK_RESPAWN_OVERFLOW > 0
                lda lvlActT,y                   ;If already an actor there, error!
                bne CZ_RespawnOverflow
                endif
                lda globalActX,x
                sta lvlActX,y
                lda globalActY,x
                sta lvlActY,y
                lda globalActT,x
                sta lvlActT,y
                lda globalActZ,x
                asl
                txa
                ora #GLOBAL
                jsr CarryToMSB
                sta lvlActZ,y
                stx CZ_RestX+1
                tya
                jsr CZ_StoreActorAndPrecache
CZ_RestX:       ldx #$00
CZ_GZGANext:    dex
                bpl CZ_GetZoneGlobalActors
                ldy #MAX_LVLACT-1               ;Then ordinary zone actors
CZ_FindLevelActors:
                lda lvlActT,y
                beq CZ_FLANext
                lda lvlActZ,y
                and #MAX_LVLZONES-1
                cmp zoneNum
                bne CZ_FLANext
                lda lvlActZ,y                   ;Check if actor is supposed to be respawning
                asl                             ;In that case make a copy, and use the copy during gameplay
                bpl CZ_NotRespawning
                ldx wpnLo
                dec wpnLo
                if CHECK_RESPAWN_OVERFLOW > 0
                lda lvlActT,x
                beq CZ_RespawnOK
CZ_RespawnOverflow:
                jmp LF_Error
CZ_RespawnOK:
                endif
                lda lvlActX,y
                sta lvlActX,x
                lda lvlActY,y
                sta lvlActY,x
                lda lvlActT,y
                sta lvlActT,x
                lda lvlActZ,y
                sta lvlActZ,x
                txa
                skip1
CZ_NotRespawning:
                tya
                sty CZ_RestY+1
                jsr CZ_StoreActorAndPrecache
CZ_RestY:       ldy #$00
CZ_FLANext:     dey
                bpl CZ_FindLevelActors
                tya
                ldx wpnHi
                sta zoneActIndex,x              ;Endmark
                ldy #MAX_LVLOBJ-1
                ldx #$00
CZ_FindLevelObjects:
                lda lvlObjY,y                   ;Convention: Y 0 cannot represent valid object (top wall)
                beq CZ_FLONext
                lda lvlObjZ,y
                cmp zoneNum
                bne CZ_FLONext
                tya
                sta zoneObjIndex,x
                inx
                lda lvlObjFlags,y
                and #OBJ_TYPEBITS               ;Needs script precache?
                cmp #OBJTYPE_SCRIPT
                bne CZ_FLONext
                txa
                pha
                tya
                pha
                lda lvlObjDH,y
                adc #C_FIRSTSCRIPT-1            ;C=1
                tay
                jsr LoadChunkFile
                pla
                tay
                pla
                tax
CZ_FLONext:     dey
                bpl CZ_FindLevelObjects
                tya
                sta zoneObjIndex,x              ;Endmark
                sta ULO_AnimObjIndex+1          ;Disable any ongoing level object animation
                sta SLO_LastX+1                 ;Reset levelobject search (enough to reset X, since it can never be $ff)
                ;sta SLO_LastY+1
                sta MP_UsableObj+1              ;No usable object until found
                sta ULO_OperateObj+1

CZ_GlobalZoneNum:
                ldy #$00
                ldx #<mapSizeX                  ;Calculate zone map size from global zone data
                lda zoneSize,y
                pha
                and #$0f
                ldy #SCREENSIZEX                ;X-size
                jsr MulU
                pla
                lsr
                lsr
                lsr
                lsr
                ldy #SCREENSIZEY                ;Y-size. Note: zoneBufferLo will be trashed, but
                inx                             ;it's recalculated immediately after
                jsr MulU
                lda mapSizeX
                ldy mapSizeY
                iny                             ;Make room for the blank row
                ldx #<zoneBufferLo
                jsr MulU
                jsr Negate16                    ;Size of zone as negative
                ldy #<musicDataLo               ;Add music startaddress to get zone start
                jsr Add16
                jsr PurgeUntilFreeNoNew         ;Purge files until there's room for the zone
                ldx zoneNum                     ;Zone packed data in object (zonenumber+1)
                inx
                txa
                ldy #C_LEVEL
                jsr LoadChunkFile               ;This shouldn't load anything at this point, just get zone object address
                lda zoneBufferLo                ;Now depack zone data from RLE format
                sta zpBitsLo
                sta zpDestLo
                lda zoneBufferHi
                sta zpBitsHi
                sta zpDestHi
CZ_AfterSequence:
                ldy #$00
CZ_RLELoop:     lda (zpSrcLo),y
                cmp #$ff
                beq CZ_SequenceOrEndMark
CZ_Literal:     sta (zpDestLo),y
                iny
                bne CZ_RLELoop
                inc zpSrcHi
                inc zpDestHi
                bne CZ_RLELoop
CZ_SequenceOrEndMark:
                tya
                ldx #<zpDestLo
                jsr Add8
                tya
                ldx #<zpSrcLo
                jsr Add8
                ldy #$01
                lda (zpSrcLo),y
                beq CZ_EndMark
                sta zpLenLo
                iny
                lda (zpSrcLo),y
                ldy #$00
CZ_Sequence:    sta (zpDestLo),y
                iny
                cpy zpLenLo
                bne CZ_Sequence
                lda #$03
                jsr Add8
                tya
                ldx #<zpDestLo
                jsr Add8
                jmp CZ_AfterSequence
CZ_EndMark:     iny
                lda (zpSrcLo),y                 ;Multi-block fillshape?
                beq CZ_NoFill
                pha
                and #$0f
                sta temp1                       ;Fillshape X-size
                pla
                lsr
                lsr
                lsr
                lsr
                sta temp2                       ;Fillshape Y-size
                lda zpSrcLo
                clc
                adc #$03
                sta CZ_FillLda+1                ;Source pointer for accessing fillshape data
                lda zpSrcHi
                adc #$00
                sta CZ_FillLda+2
                lda mapSizeY
                sta temp6
CZ_ResetFillShape:
                lda #$00                        ;Start from first row
                sta temp3
                sta temp4
CZ_RowLoop:     lda temp4                       ;Source start index
                tax
                clc
                adc temp1
                sta temp5                       ;Source end index
                ldy #$00
CZ_ColumnLoop:  lda (zpBitsLo),y
                cmp #$fe                        ;Need to be filled?
                bne CZ_SkipFill
CZ_FillLda:     lda $1000,x
                sta (zpBitsLo),y
CZ_SkipFill:    inx
                cpx temp5
                bcc CZ_NoSrcColumnReload
                ldx temp4
CZ_NoSrcColumnReload:
                iny
                cpy mapSizeX
                bcc CZ_ColumnLoop
                dec temp6
                beq CZ_FillDone
                ldx #<zpBitsLo                  ;Proceed to next dest row
                lda mapSizeX
                jsr Add8
                lda temp5                       ;Proceed to next fillshape row
                sta temp4
                inc temp3
                lda temp3                       ;Start fillshape over?
                cmp temp2
                bcs CZ_ResetFillShape
                bcc CZ_RowLoop
CZ_FillDone:    lda zoneBufferLo
                sta zpBitsLo
                lda zoneBufferHi
                sta zpBitsHi
CZ_NoFill:      ldy #$00                        ;Write map row table
                ldx #<zpBitsLo
CZ_InitMapTbl:  lda zpBitsLo
                sta mapTblLo,y
                lda zpBitsHi
                sta mapTblHi,y
                lda mapSizeX
                jsr Add8
                iny
                cpy mapSizeY
                bcc CZ_InitMapTbl
                beq CZ_InitMapTbl               ;Write the extra row pointer for shake effect
                lda #$00
                tay
CZ_FillExtraRow:sta (zpDestLo),y                ;Write the extra row map data (block 0)
                iny
                cpy mapSizeX
                bcc CZ_FillExtraRow

                tax                             ;Zone map drawn now, animate activated levelobjects
CZ_AnimLevelObjects:                            ;to their end frame
                ldy zoneObjIndex,x
                bmi CZ_AnimLevelObjectsDone
                lda lvlObjFlags,y
                bpl CZ_AnimLevelObjectsSkip
                jsr DrawLevelObjectEndFrame
CZ_AnimLevelObjectsSkip:
                inx
                bpl CZ_AnimLevelObjects
CZ_AnimLevelObjectsDone:

CZ_SongNum:     lda #$00                        ;Finally play the level song
                jmp PlaySong

CZ_ProcessRespawnOrGlobal:
                cmp #GLOBAL
                bne CZ_RemoveRespawn
CZ_ProcessGlobal:
                lda lvlActZ,x                   ;For global actors, lvlActZ stores global table index
                and #MAX_GLOBALACT-1
                tay
                lda lvlActX,x                   ;Update position / type / direction of global actor
                sta globalActX,y
                lda lvlActY,x
                sta globalActY,y
                lda lvlActT,x
                sta globalActT,y
                lda lvlActZ,x
                asl
                lda globalActZ,y
                jsr CarryToMSB
                sta globalActZ,y
CZ_RemoveRespawn:
                lda #$00
                sta lvlActZ,x
                sta lvlActT,x
CZ_SkipPrecache:
CZ_ProcessSkip: rts

CZ_StoreActorAndPrecache:
                ldx wpnHi
                inc wpnHi
                sta zoneActIndex,x
                lda lvlActT,y
                bmi CZ_SkipPrecache

        ; Precache actor sprites & scripts
        ;
        ; Parameters: A actor type (must not be zero)
        ; Returns: C=1 if collided
        ; Modifies: A,Y,various vars

PrecacheActor:  sta actT+ACTI_FIRST
                lda #MAX_SPR
                sta sprIndex
                ldx #ACTI_FIRST
                jsr DrawActorSub_NoColor        ;"Draw" actor to ensure sprite load
                ldx #ACTI_FIRST
                jsr GetActorLogicData           ;Get actor logic data; if in script, it's in same place as code
                ldy #$00
PA_CheckRelatedLoop:
                lda relatedActorTbl,y
                beq PA_CheckRelatedDone
                cmp actT+ACTI_FIRST
                bne PA_CheckRelatedNext
                lda relatedActorTbl+1,y
                bpl PrecacheActor
PA_CheckRelatedNext:
                iny
                iny
                bne PA_CheckRelatedLoop
PA_CheckRelatedDone:
                sta actT+ACTI_FIRST
                rts

CZ_EndDemoVersion:
                jsr BeginTextDisplay
                lda #<txtDemoEnd
                sta zpSrcLo
                lda #>txtDemoEnd
                sta zpSrcHi
                lda #6
                jsr ShowMultiLineText
                jmp LoadTitleScreen

        ; Store levelobject & levelactor bits based on current state. Called before level change
        ;
        ; Parameters: -
        ; Returns: -
        ; Modifies: A,X,Y,temp8

StoreLevelBits: ldx levelNum
                bmi SLAB_Done                   ;Skip if no level loaded or if restarting a checkpoint
                ldy lvlObjBitStart,x
                lda lvlObjBitStart+1,x
                sta SLOB_EndCmp+1
                ldx #$00
                beq SLOB_Start
SLOB_Loop:      lda lvlObjFlags,x
                bpl SLOB_Inactive
                lda lvlObjBits,y
                ora temp8
                bne SLOB_Next
SLOB_Inactive:  lda temp8
                eor #$ff
                and lvlObjBits,y
SLOB_Next:      sta lvlObjBits,y
                inx
                asl temp8
                bne SLOB_Loop
                iny
SLOB_Start:     lda #$01
                sta temp8
SLOB_EndCmp:    cpy #$00
                bcc SLOB_Loop
                ldx levelNum
                ldy lvlActBitStart,x
                lda lvlActBitStart+1,x
                sta SLAB_EndCmp+1
                ldx #$00
                beq SLAB_Start
SLAB_Loop:      lda lvlActZ,x
                asl
                bpl SLAB_NotRespawning
                inx
                bne SLAB_Loop
SLAB_NotRespawning:
                lda lvlActT,x
                beq SLAB_NoActor
                lda lvlActBits,y
                ora temp8
                bne SLAB_Next
SLAB_NoActor:   lda temp8
                eor #$ff
                and lvlActBits,y
SLAB_Next:      sta lvlActBits,y
                inx
                asl temp8
                bne SLAB_Loop
                iny
SLAB_Start:     lda #$01
                sta temp8
SLAB_EndCmp:    cpy #$00
                bcc SLAB_Loop
SLAB_Done:      rts

        ; Turn a number into a byte offset into a bit-table and a bitmask
        ;
        ; Parameters: A number
        ; Returns: A bitmask, Y byte offset
        ; Modifies: A,Y

DecodeBit:      pha
                and #$07
                tay
                lda bitTbl,y
                sta DB_Value+1
                pla
                lsr
                lsr
                lsr
                tay
DB_Value:       lda #$00
                rts

        ; Set zone's multicolors
        ;
        ; Parameters: zoneNum
        ; Returns: -
        ; Modifies: A,Y

SetZoneColors:  ldy zoneNum
                lda lvlZoneBg1,y
                sta Irq1_Bg1+1
                lda lvlZoneBg2,y
                sta Irq1_Bg2+1
                lda lvlZoneBg3,y
                sta Irq1_Bg3+1
OO_DoNothing:   rts

        ; Operate a levelobject, subject to checks like security passes
        ;
        ; Parameters: Y:object index
        ; Returns: -
        ; Modifies: A,X,Y,loader zp vars,temp7-temp8

OperateObject:  lda lvlObjFlags,y
                and #OBJ_TYPEBITS               ;Switch objects may have security requirements
                cmp #OBJTYPE_SWITCH
                bne OO_OK
                lda lvlObjDH,y                  ;Check security bits
                beq OO_OK
                and security
                bne OO_OK
                lda #SFX_PICKUP
                jsr QueueSfx
                lda #<txtNeedPass
                ldx #>txtNeedPass
                jmp PrintPanelTextItemDur
OO_OK:          jsr MenuActionSound

        ; Toggle a levelobject
        ;
        ; Parameters: Y:object index
        ; Returns: -
        ; Modifies: A,X,Y,loader zp vars,temp7-temp8

ToggleObject:   lda lvlObjFlags,y
                bmi DeactivateObject

        ; Activate a levelobject
        ;
        ; Parameters: Y:object index
        ; Returns: -
        ; Modifies: A,X,Y,loader zp vars,temp6-temp8,more possibly depending on script

ActivateObject: lda lvlObjFlags,y
                bmi AO_AlreadyActive
                ora #OBJ_ACTIVE
                sta lvlObjFlags,y
                and #OBJ_AUTODEACT
                beq AO_NoAutoDeact              ;Autodeactivating?
                lda autoDeactObj                ;If another object already deactivating,
                bmi AO_NoPreviousAutoDeact      ;deactivate it immediately
                cpy autoDeactObj
                beq AO_NoPreviousAutoDeact      ;If same object deactivating, no need to do that
                sty AO_RestY+1
                tay
                jsr DeactivateObject
AO_RestY:       ldy #$00
AO_NoPreviousAutoDeact:
                sty autoDeactObj
                lda #AUTODEACT_DELAY
                sta autoDeactDelay
AO_NoAutoDeact: jsr AnimateObject               ;Animate now before object action
                lda lvlObjFlags,y               ;Check object action type
                and #OBJ_TYPEBITS
                cmp #OBJTYPE_SWITCH
                bne AO_NoSwitch
                lda lvlObjDL,y                  ;Low object byte = $00-$7f object, $80-$ff actor
                bmi AO_SwitchActor
AO_SwitchObject:tay
                jmp ToggleObject
AO_NoSwitch:    cmp #OBJTYPE_SCRIPT
                bne AO_NoScript
DO_ExecScript:  lda lvlObjDL,y
                ldx lvlObjDH,y
                sty ES_Param+1

        ; Execute loadable code (script)
        ;
        ; Parameters: A script entrypoint, X script file
        ; Returns: -
        ; Modifies: A,X,Y,loader temp vars,temp6-temp8

ExecScript:     pha
                txa
                clc
                adc #C_FIRSTSCRIPT
                tay
                pla
                jsr LoadChunkFile
ES_Param:       ldx #$00
                jmp (zpSrcLo)
AO_NoScript:
AO_AlreadyActive:
DO_NotActive:   rts

        ; Deactivate a levelobject
        ;
        ; Parameters: Y:object index
        ; Returns: -
        ; Modifies: A,loader zp vars,temp7-temp8

DeactivateObject:
                lda lvlObjFlags,y
                bpl DO_NotActive
                and #$ff-OBJ_ACTIVE
                sta lvlObjFlags,y
                cpy autoDeactObj          ;If this object was autodeactivating, reset it now
                bne DO_NoAutoDeact
                lda #NO_OBJECT
                sta autoDeactObj
DO_NoAutoDeact: jsr AnimateObject
                lda lvlObjFlags,y         ;If object has script and is manually activating/deactivating
                cmp #OBJTYPE_SCRIPT+OBJMODE_MANAD ;execute script at both activate & deactivate (stations)
                beq DO_ExecScript
                rts

        ; Activate lift based on X-coordinate
        ;
        ; Parameters: A X-coordinate
        ; Returns: -
        ; Modifies: A,X,Y,temp vars

AO_SwitchActor:
ActivateLift:   and #$7f
                sta temp1
                ldx #ACTI_LASTPERSISTENT
AL_FindActor:   lda actT,x
                cmp #ACT_LIFT
                bne AL_FindNext
                lda actXH,x
                cmp temp1
                beq AL_Found
AL_FindNext:    dex
                bne AL_FindActor
                ldy #$00
AL_FindLDActor: ldx zoneActIndex,y
                bmi AL_Fail
                lda lvlActT,x
                cmp #ACT_LIFT
                bne AL_FindLDNext
                lda lvlActX,x
                cmp temp1
                beq AL_LDFound
AL_FindLDNext:  iny
                bpl AL_FindLDActor
AL_LDFound:     jsr TryAddActor
                bcc AL_Fail
AL_Found:       lda actYH+ACTI_PLAYER
                sta actSX,x                     ;Store vertical target to prevent stopping in the meanwhile (speedX not used otherwise)
                cmp actYH,x
                beq AL_DoNothing
                lda #JOY_UP
                bcc AL_GoUp
                asl
AL_GoUp:        sta actMoveCtrl,x
                lda actFlags,x                  ;While lift is moving, do not remove even if offscreen
                ora #AF_NOREMOVECHECK
                sta actFlags,x
AL_DoNothing:
AL_Fail:        rts

        ; Start levelobject animation to either active or inactive state
        ;
        ; Parameters: Y:object index
        ; Returns: -
        ; Modifies: A,loader zp vars,temp7-temp8

AnimateObject:  lda lvlObjZ,y                   ;If has more than one frame and is in same zone, animate
                cmp zoneNum
                bne AO_NoAnimation
                jsr GetLevelObjectFrames
                sec
                sbc #$01
                beq AO_NoAnimation
                sta temp7
                lda ULO_AnimObjIndex+1
                bmi AO_AnimationFree
                cpy ULO_AnimObjIndex+1          ;If animating the same object, just overwrite
                beq AO_AnimationFree
                sty temp8
                tay
                lda ULO_AnimObjTarget+1
                jsr DrawLevelObjectFrame        ;Finish existing animation forcibly now if needed
                ldy temp8                       ;(only 1 animation at a time)
AO_AnimationFree:
                sty ULO_AnimObjIndex+1
                lda #$00
                sta animObjDelay
                lda lvlObjFlags,y
                bmi AO_AnimateToEnd
AO_AnimateToStart:
                lda temp7
                sta ULO_AnimObjFrame+1
                lda #$00
                beq AO_StoreTargetFrame
AO_AnimateToEnd:lda #$00
                sta ULO_AnimObjFrame+1
                lda temp7
AO_StoreTargetFrame:
                sta ULO_AnimObjTarget+1
AO_NoAnimation: rts

        ; Get number of frames on a levelobject
        ;
        ; Parameters: Y:object index
        ; Returns: A:number of frames
        ; Modifies: A

GetLevelObjectFrames:
                lda lvlObjSize,y
                lsr
                lsr
                lsr
                lsr
                clc
                adc #$01
                rts

        ; Get levelobject center (optimized)
        ;
        ; Parameters: Y:object index
        ; Returns: A:X center, temp8 Y center,C=0
        ; Modifies: A,temp8

GetLevelObjectCenter:
                lda lvlObjSize,y
                and #$0c
                lsr
                lsr
                adc #$01
                lsr
                clc
                adc lvlObjY,y
                sta temp8
                lda lvlObjSize,y
                and #$03
                adc #$01                        ;C=0 here
                lsr
                clc
                adc lvlObjX,y
DLOEF_NoAnim:   rts

        ; Draw end frame for a levelobject. If not animating, no-op
        ;
        ; Parameters: Y:object index
        ; Returns: -
        ; Modifies: A,loader zp vars

DrawLevelObjectEndFrame:
                jsr GetLevelObjectFrames
                cmp #$02
                bcc DLOEF_NoAnim                ;Check if animating (at least 2 frames)
                sbc #$01

        ; Draw animation frame for a levelobject
        ;
        ; Parameters: Y:object index A:frame number
        ; Returns: -
        ; Modifies: A,loader zp vars

DrawLevelObjectFrame:
                stx zpBitBuf
                sty zpLenLo
                pha
                lda lvlObjSize,y
                pha
                and #$0c
                lsr
                lsr
                adc #$01                        ;C=0
                sta zpBitsHi
                pla
                and #$03
                adc #$01                        ;C=0
                sta zpBitsLo
                ldy zpBitsHi
                ldx #<zpSrcLo
                jsr MulU                        ;Get size of frame in bytes
                ldy zpSrcLo
                pla
                jsr MulU                        ;Get offset to frameblocktable
                ldy zpLenLo
                lda zpSrcLo
                clc
                adc lvlObjFrame,y
                adc #<lvlObjAnimFrames
                sta DLOF_Lda+1
                lda lvlObjX,y
                sta DLOF_XReload+1
                adc zpBitsLo
                sta DLOF_XEndCmp+1
                lda lvlObjY,y
                tax
                adc zpBitsHi
                sta DLOF_YEndCmp+1
DLOF_XReload:   ldy #$00
DLOF_Lda:       lda lvlObjAnimFrames
                inc DLOF_Lda+1
                jsr UpdateBlock
                iny
DLOF_XEndCmp:   cpy #$00
                bcc DLOF_Lda
                inx
DLOF_YEndCmp:   cpx #$00
                bcc DLOF_XReload
                ldx zpBitBuf
                ldy zpLenLo
ULO_PlayerDying:rts

        ; Divide player Y-pos by screen size
        ;
        ; Parameters: current zone
        ; Returns: A: Y-pos remainder, temp1 divide result
        ; Modifies: A,X,Y,temp1-temp2

DividePlayerYPos:
                lda actYH+ACTI_PLAYER
                ldy #SCREENSIZEY
                ldx #<temp1
                jmp DivU

        ; Update global actions
        ;
        ; Parameters: -
        ; Returns: -
        ; Modifies: A,X,Y,temp5-temp8

ULO_PlayerDead: lda actT+ACTI_PLAYER            ;Player disappeared after death?
                bne ULO_PlayerDying
                ldy menuMode                    ;Already in gameovermenu?
                bpl ULO_GameOverMenu
                sta menuPos                     ;Reset menu pos to "retry"
                ldy dialogueHi
                beq ULO_GameOverNoDialogue
                sta dialogueHi                  ;Make sure any dialogue is cleared, though
                jsr ClearMenuNoSound            ;player should never die during it (damage disabled)
ULO_GameOverNoDialogue:
                lda #MENU_GAMEOVER
                jsr DrawMenu
ULO_GameOverMenu:
                jmp MenuFrameCustom

UpdateLevelObjects:
                ldy autoDeactObj                ;Perform object autodeactivation
                bmi ULO_AnimObjIndex
                lda autoDeactDelay
                bne ULO_AutoDeactOK
                lda lvlObjFlags,y               ;Special case: if object is triggered (automatic doors)
                and #OBJ_MODEBITS               ;do not let the timer run completely out
                cmp #OBJMODE_TRIG
                bne ULO_AutoDeactOK
                cpy atObj
                beq ULO_AnimObjIndex
                cpy adjacentObj
                beq ULO_AnimObjIndex
ULO_AutoDeactOK:dec autoDeactDelay
                bpl ULO_AnimObjIndex
                jsr DeactivateObject
ULO_AnimObjIndex:
                ldy #NO_OBJECT                  ;Perform object animation (1 object either activating
                bmi ULO_SkipObjectAnim          ;or deactivating at a time)
                dec animObjDelay
                bpl ULO_SkipObjectAnim
                lda #OBJANIM_DELAY
                sta animObjDelay
ULO_AnimObjFrame:
                lda #$00
ULO_AnimObjTarget:
                cmp #$00
                beq ULO_FinishObjectAnim
                bcc ULO_AnimForward
ULO_AnimBackward:
                sbc #$01
                bcs ULO_AnimRedraw
ULO_AnimForward:adc #$01
ULO_AnimRedraw: sta ULO_AnimObjFrame+1
                jsr DrawLevelObjectFrame
                jmp ULO_SkipObjectAnim
ULO_FinishObjectAnim:
                lda #NO_OBJECT
                sta ULO_AnimObjIndex+1
ULO_SkipObjectAnim:
                lda actHp+ACTI_PLAYER
                beq ULO_PlayerDead
                ldx #$03
ULO_IncreaseTime:
                inc time,x                      ;time+3 = frames
                lda time,x                      ;time = hours
                cmp timeMaxTbl,x
                bcc ULO_SkipTime
                lda #$00
                sta time,x
                dex
                bpl ULO_IncreaseTime
ULO_SkipTime:   lda actFlags+ACTI_PLAYER        ;When player is alive, disable/enable damage
                and #$ff-AF_TAKEDAMAGE          ;based on whether control override is active
                ldy playerCtrl                  ;(dialogue / cutscenes)
                bmi ULO_ControlOverrideNoDamage
                ora #AF_TAKEDAMAGE
ULO_ControlOverrideNoDamage:
                sta actFlags+ACTI_PLAYER
                tya                             ;If controls are overridden, also no menu
                bmi ULO_WeaponSelectDone
                ldy wpnIndex
ULO_WeaponMenuDelay:
                lda #$00
                beq ULO_WeaponMenuOK
                dec ULO_WeaponMenuDelay+1
                bpl ULO_NoWeaponMenu
ULO_WeaponMenuOK:
                lda keyPress                    ;Use repeat in prev/next controls,
                cmp #KEY_COLON                  ;similar to doubleclick menu
                beq ULO_NextWeapon
                cmp #KEY_COMMA
                beq ULO_PrevWeapon
                lda wpnMenuMode
                bmi ULO_NoWeaponMenu
                lda joystick
                and #JOY_LEFT|JOY_RIGHT
                beq ULO_NoWeaponMenu
                cmp #JOY_RIGHT
                beq ULO_NextWeapon
                bne ULO_PrevWeapon
ULO_NoWeaponMenu:
                lda keyType
                bmi ULO_NoKeyControls
                cmp #KEY_RUNSTOP
                bne ULO_NoEnterMap
ULO_EnterMap:   lda #$00                        ;Always start from the Back menu option
                sta menuPos
                jmp MapDisplay
ULO_NoEnterMap: cmp #KEY_SPACE
                beq ULO_NextWeapon
                ldy #MAX_WEAPONS-1
ULO_DirectWeaponSelectLoop:
                cmp wpnKeyTbl,y
                beq ULO_DirectWeaponSelect
                dey
                bpl ULO_DirectWeaponSelectLoop
                bmi ULO_WeaponSelectDone
ULO_DirectWeaponSelect:
                tya
                beq ULO_WeaponSelected
                jsr CheckHasAmmo
                bne ULO_WeaponSelected
                beq ULO_WeaponSelectDone
ULO_NextWeapon: tax
ULO_NextWeaponLoop:
                iny
                cpy #MAX_WEAPONS
                bcs ULO_NextWeaponOver
                jsr CheckHasAmmo
                beq ULO_NextWeaponLoop
                bne ULO_WeaponSelected
ULO_NextWeaponOver:
                cpx #KEY_SPACE
                bne ULO_WeaponSelectDone
                ldy #$00
                beq ULO_WeaponSelected
ULO_PrevWeapon:
ULO_PrevWeaponLoop:
                dey
                beq ULO_WeaponSelected
                bmi ULO_WeaponSelectDone
                jsr CheckHasAmmo
                beq ULO_PrevWeaponLoop
ULO_WeaponSelected:
                lda #WEAPON_MENU_DELAY
                sta ULO_WeaponMenuDelay+1
                tya
                jsr SelectWeapon
ULO_NoKeyControls:
ULO_WeaponSelectDone:
                dec fuelRechargeDelay
                bpl ULO_NoFuelRecharge
                lda #1
                sta fuelRechargeDelay
                jsr AddFuel
ULO_NoFuelRecharge:
                dec healthRechargeDelay
                bne ULO_NoHealthRecharge
                lda #1
                jsr AddHealth
ULO_NoHealthRecharge:
                lda actInWater+ACTI_PLAYER
                beq ULO_PlayerNotInLava
                lda waterColorOverride          ;Damaging water only in lava caves (yellow splash override)
                cmp #7
                bne ULO_PlayerNotInLava
                lda #DMG_LAVA
ULO_ApplyEnvironmentDamage:
                jsr AddPlayerEnvironmentDamage
ULO_PlayerNotInLava:
                if SHOW_HEALTHRECHARGE > 0
                lda healthRechargeDelay
                sta parts
                lda #REDRAW_PARTS
                jsr SetPanelRedraw
                endif
                if DEATH_KEY > 0
                lda keyType
                cmp #KEY_D
                bne ULO_NoDeathKey
                lda #1
                sta UA_ItemFlashCounter+1
                lda #$7f
                jsr AddPlayerEnvironmentDamage
ULO_NoDeathKey:
                endif
                if DAMAGE_KEY > 0
                lda keyType
                cmp #KEY_D
                bne ULO_NoDamageKey
                lda #1
                sta actHp+ACTI_PLAYER
                lda #DAMAGE_HEALTHRECHARGE_DELAY
                jsr SetHealthRechargeDelay
ULO_NoDamageKey:
                endif
                ldy adjacentObj
                bmi ULO_NoAdjacent
                lda lvlObjFlags,y               ;Check for adjacent object that is triggered
                and #OBJ_MODEBITS+OBJ_ACTIVE    ;and not yet active
                cmp #OBJMODE_TRIG
                bne ULO_NoAdjacent
                jsr ActivateObject
ULO_NoAdjacent: ldy atObj                       ;Check for manually activating "at" object
                bmi ULO_NoAt
                lda lvlObjFlags,y
                php
                and #OBJ_MODEBITS
                plp
                bmi ULO_NoAtTrigger
                cmp #OBJMODE_TRIG
                bne ULO_NoAtTrigger
                jsr ActivateObject
                jmp ULO_NotUsable
ULO_NoAtTrigger:
                cmp #OBJMODE_MAN
                bcc ULO_NotUsable
                bne ULO_IsUsable                ;Manual A/D mode always usable
                lda lvlObjFlags,y               ;Manual only usable when not active
                bpl ULO_IsUsable
ULO_NotUsable:  ldy #NO_OBJECT
                bmi ULO_NoAt
ULO_IsUsable:   ldx #ACTI_LAST                  ;Object marker always occupies
                lda actT,x                      ;last actor slot
                beq ULO_MarkerOK
                cmp #ACT_OBJECTMARKER           ;If already shown, just refresh time
                beq ULO_Refresh
                lda #$00
ULO_MarkerOK:   sta actXL,x
                sta actYL,x
                sta actF1,x
                sta actFd,x
                sta actFlash,x
                jsr GetLevelObjectCenter
                sta actXH,x
                lda temp8
                sta actYH,x
                sty temp8
                lda #ACT_OBJECTMARKER
                sta actT,x
                jsr InitActor
ULO_FindGround: inc actYH,x
                jsr GetBlockInfo                ;Lower marker until has ground, except slopetype 4
                lsr
                bcc ULO_FindGround
                cmp #$40
                beq ULO_FindGround
ULO_FoundGround:ldy temp8
ULO_Refresh:    lda #1                          ;Will remove if not refreshed
                sta actTime,x
ULO_NoAt:       sty MP_UsableObj+1
ULO_OperateObj: ldy #$00
                bmi ULO_ZoneTransition
                ldx #$00                        ;Remove the object marker already so it doesn't flash for 1 frame
                stx actT+ACTI_LAST              ;(in case the object begins a fullscreen text display)
                dex                             ;$ff
                stx ULO_OperateObj+1
                jsr OperateObject               ;This might not return but re-execute the mainloop (after textdisplay)
ULO_ZoneTransition:
                ldy actD+ACTI_PLAYER
                lda actMB+ACTI_PLAYER
                and #MB_HITWALL
                beq ZT_DoNothing
                ldx actXH+ACTI_PLAYER
                beq ZT_Left
                inx
                cpx mapSizeX
                beq ZT_Right
ZT_DoNothing:   rts
ZT_Left:        tya                             ;Verify correct facing
                bpl ZT_DoNothing
                lda #$ff
                bne ZT_Common
ZT_Right:       tya                             ;Verify correct facing
                bmi ZT_DoNothing
                txa
                ldy #SCREENSIZEX
                ldx #<temp1
                jsr DivU
                lda temp1
ZT_Common:      clc
                adc worldX
                sta temp4                       ;X-destination in world space
                ldx #ACTI_PLAYER
                jsr GetBlockInfo
                and #BI_NOZONECHANGE            ;Check for specially marked no zone change areas (e.g. ship roof)
                bne ZT_DoNothing
                jsr DividePlayerYPos
                sta ZT_YPosRemainder+1          ;Remainder of Y-world destination
                lda temp1
                clc
                adc worldY
                tay                             ;Y-destination in world space
                ldx temp4
                sty ZT_YPosScreen+1
                jsr ChangeZone
                lda actXH+ACTI_PLAYER
                beq ZT_MovedLeft
                ldx #$00
                beq ZT_SetXPos
ZT_MovedLeft:   ldx mapSizeX
                dex
ZT_SetXPos:     stx actXH+ACTI_PLAYER           ;Set new actor X-pos
                txa
                beq ZT_SetXFinePos
                lda #$7f
ZT_SetXFinePos: sta actXL+ACTI_PLAYER
ZT_PlayerXSpeed:lda #$00                        ;Restore speed before wallhit
                sta actSX+ACTI_PLAYER
ZT_YPosScreen:  lda #$00                        ;Calculate new Y-pos
                sec
                sbc worldY
                ldy #SCREENSIZEY
                ldx #<temp1
                jsr MulU
                lda temp1
                clc
ZT_YPosRemainder:
                adc #$00
                sta actYH+ACTI_PLAYER
                lda #PLOT_NOSAVE
                jsr GetPlotBit
                bne ZT_SkipSave
                jsr SaveState
ZT_SkipSave:

        ; Center player, add/update all actors and redraw screen, then start mainloop
        ;
        ; Parameters: -
        ; Returns: -
        ; Modifies: A,X,Y,ZP vars

CenterPlayer:   lda #0
                sta blockX
                sta blockY
                sta scrollX
                sta scrollY
                ;lda #9
                ;sta CP_XCenter+1
                lda #-(SCROLLCENTER_X)
                sta SP_ScrollCenterX+1
                lda actXH
                sec
CP_XCenter:     sbc #9
                bcs CP_NotOverLeft
                lda #0
CP_NotOverLeft: tay
                clc
                adc #SCREENSIZEX
                cmp mapSizeX
                bcc CP_NotOverRight
                lda mapSizeX
                sbc #SCREENSIZEX
                tay
CP_NotOverRight:sty mapX
                lda actYH
                sec
                sbc #7
                bcs CP_NotOverUp
                lda #0
CP_NotOverUp:   tay
                clc
                adc #SCREENSIZEY
                cmp mapSizeY
                bcc CP_NotOverDown
                lda mapSizeY
                sbc #SCREENSIZEY
                tay
CP_NotOverDown: sty mapY
CP_Finish:      jsr AddAndUpdateAllActors
                ldy atObj                       ;If player is at a door now and it's triggered/switched
                bmi CP_NotAtDoor                ;animate it directly to the end
                lda lvlObjFlags,y
                and #OBJMODE_MAN+OBJTYPE_SWITCH+OBJ_ACTIVE
                bne CP_NotAtDoor
                jsr ActivateObject
                jsr DrawLevelObjectEndFrame
                lda #NO_OBJECT
                sta ULO_AnimObjIndex+1
CP_NotAtDoor:   jsr RedrawScreen

        ; Main loop
        ;
        ; Parameters: -
        ; Returns: -
        ; Modifies: Everything

StartMainLoop:  ldx #$ff
                txs
MainLoop:       jsr ScrollLogic
                jsr DrawActors
                jsr AddActors
                jsr UpdatePanel
                jsr UpdateFrame
                jsr UpdateActors
                jsr ScrollLogic
                jsr InterpolateActors
                jsr UpdatePanelBars
                jsr UpdateFrame
                jsr UpdateLevelObjects
                jmp MainLoop

        ; Update actors, disable ingame firebutton until not held and redraw screen / start mainloop
        ; Used for exiting text displays. Can not be JSR'd to, as mainloop rewrites stackpointer.
        ;
        ; Parameters: -
        ; Returns: -
        ; Modifies: A,X,Y,various

ExitTextDisplay:jsr DisableFire
                bmi CP_Finish

        ; Disable firebutton until not held
        ;
        ; Parameters: -
        ; Returns: N=1
        ; Modifies: A

DisableFire:    lda #$ff-JOY_FIRE
                sta GC_JoystickAnd+1            ;Fire disabled until at least 1 frame without fire
                rts
