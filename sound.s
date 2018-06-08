        ; Ninjatracker V2.03 gamemusic playroutine
        ; Relocation defines

NT_FIRSTNOTE        = $18
NT_DUR              = $c0
NT_HEADERLENGTH     = 6
NT_NUMFIXUPS        = 21
NT_ADDZERO          = $80
NT_ADDWAVE          = $00
NT_ADDPULSE         = $04
NT_ADDFILT          = $08
NT_ADDCMD           = $0c
NT_ADDLEGATOCMD     = $10
NT_ADDPATT          = $14
NT_HRPARAM          = $00
NT_FIRSTWAVE        = $09
NT_SFXFIRSTWAVE     = $09

MODULE_MASK         = $fc
SUBTUNE_MASK        = $03

SONG_SILENCE        = $00                       ;Silence subtune always first in each module
SONG_TITLE          = $01
SONG_INTRO          = $02
SONG_INGAME1        = $05
SONG_BOSS1          = $06
SONG_INGAME2        = $09
SONG_BOSS2          = $0a
SONG_INGAME3        = $0d
SONG_BOSS3          = $0e
SONG_BOSS3B         = $0f
SONG_INGAME4        = $11
SONG_BOSS4          = $12
SONG_INGAME5        = $15
SONG_INGAME6        = $19
SONG_INGAME7        = $1d
SONG_INGAME7B       = $1e
SONG_INGAME8        = $21
SONG_BOSS8          = $22
SONG_INGAME9        = $25
SONG_BOSS9          = $26
SONG_BOMBGAMEOVER   = $27
SONG_FINALBOSSSILENCE = $28
SONG_INGAME10       = $29
SONG_FINALBOSS      = $2a
SONG_ESCAPE         = $2b
SONG_ENDING1        = $2d
SONG_ENDING2        = $2e
SONG_ENDING3        = $2f

SOUND_OVERWRITE_DELAY = 12                      ;How many frame after a low-priority sound can
                                                ;interrupt a higher priority sound (assume it has decayed)

FADESPEED       = $30

CUTOFF_8580_ADJUST = $40
MIN_8580_CUTOFF    = $04

        ; Request playback of sound effect for musuic disabled mode only (footsteps etc.) Will actually be played during next panel IRQ
        ;
        ; Parameters: A sound effect number
        ; Returns: -
        ; Modifies: A

QueueFootstep:  lda #SFX_FOOTSTEP
QueueSfxNoMusicPlayerOnly:
                cpx #ACTI_PLAYER
                bne QSfx_Done
QueueSfxNoMusic:sta QSNM_SoundNum+1
                lda Irq4_MusicCheck+1
                bne QSfx_Done
QSNM_SoundNum:  lda #$00

        ; Request playback of sound effect. Will actually be played during next panel IRQ
        ;
        ; Parameters: A sound effect number
        ; Returns: -
        ; Modifies: A

QueueSfx:       cmp Irq4_SfxNum+1
                bcc QSfx_Done
QSfx_Store:     sta Irq4_SfxNum+1
CQS_Skip:
QSfx_Done:      rts

        ; Play a song. Load if necessary. Do not reinit if already playing
        ;
        ; Parameters: A song number, $00-$03 in first file, $04-$07 in second etc.
        ; Returns: -
        ; Modifies: A,X,Y,loader temp vars,temp7-8

PlaySong:
PS_MusicMode:   ldx #$00                        ;If music off, always select silence tune
                bne PS_MusicOn
                and #MODULE_MASK
ForcePlaySong:
PS_MusicOn:
PS_CurrentSong: cmp #$ff
                beq PS_Done
                sta PS_CurrentSong+1
                pha
                jsr PrepareSong
                pla
                and #SUBTUNE_MASK
                sta ntInitSong
                sta Irq4_MusicCheck+1
PS_Done:        rts

        ; Prepare song by loading its module, but do not start playback yet
        ;
        ; Parameters: A song number
        ; Returns: -
        ; Modifies: A,X,Y,loader temp vars,temp7-8

PrepareSong:    lsr                             ;Get music module number
                lsr
PS_LoadedMusic: cmp #$ff                        ;Check if music already loaded
                beq PS_Done
                sta PS_LoadedMusic+1
                ldx #F_MUSIC
                jsr MakeFileName
                lda #$7f
                sta ntInitSong                  ;Silence during loading
                jsr OpenFile                    ;Music files are raw Exomizer2 output,
                jsr GetByte                     ;meaning they start with startaddress hi/lo
                bcc PS_NoError
                jmp LF_Error
PS_NoError:     sta musicDataHi                 ;Reset zonebuffer now
                sta zoneBufferHi
                jsr GetByte
                sta musicDataLo
                sta zoneBufferLo
                jsr PurgeUntilFreeNoNew         ;Purge files if necessary to fit the music
                lda musicDataLo
                ldx musicDataHi
                jsr LoadFile
                lda musicDataLo
                clc
                adc #NT_HEADERLENGTH-1
                sta zpSrcLo
                lda musicDataHi
                adc #$00
                sta zpSrcHi
                ldx #NT_NUMFIXUPS-1
IMD_Loop:       lda ntFixupTblLo,x
                sta zpDestLo
                lda ntFixupTblHi,x
                sta zpDestHi
                lda ntFixupTblAdd,x
                pha
                bmi IMD_AddDone
                lsr
                lsr
IMD_AddSize:    tay
IMD_GetSize:    lda (musicDataLo),y
                clc
                adc zpSrcLo
                sta zpSrcLo
                bcc IMD_AddDone
                inc zpSrcHi
IMD_AddDone:    pla
                and #$03
                clc
                adc zpSrcLo
                ldy #$01
                sta (zpDestLo),y
                lda #$00
                adc zpSrcHi
                iny
                sta (zpDestLo),y
                dex
                bpl IMD_Loop
PS_SameMusicFile:
                rts

        ; Fadeout music. Note: sounds will not play before a new song (at least silence tune)
        ; is initialized
        ;
        ; Parameters: -
        ; Returns: -
        ; Modifies: A

FadeSong:       lda Irq4_MusicCheck+1           ;When silence subtune is active, do not fade,
                beq FS_Silence                  ;as it causes SID master volume noises
                lda #FADESPEED
                sta Play_FadeSpd+1
FS_Silence:     rts

        ;New song initialization

Play_DoInit:    asl
                bpl Play_NoSilence
SilenceSID:     ldx #$00                        ;Mute SID by setting frequencies to zero
                txa
                jsr SS_Sub
                inx
SS_Sub:         sta $d400,x
                sta $d407,x
                sta $d40e,x
                rts
Play_NoSilence: asl
                adc ntInitSong
                tay
Play_SongTblP0: lda $1000,y
                sta ntTrackLo
Play_SongTblP1: lda $1000,y
                sta ntTrackHi
                txa
                sta ntFiltPos
                sta $d417
                ldx #21
Play_InitLoop:  sta ntChnPattPos-1,x
                dex
                bne Play_InitLoop
                stx Play_FadeSpd+1
                jsr Play_InitChn
                ldx #$07
                jsr Play_InitChn
                ldx #$0f
                stx Play_MasterVol+1
                dex
Play_InitChn:
Play_SongTblP2: lda $1000,y
                sta ntChnSongPos,x
                iny
                lda #$ff
                sta ntChnNewNote,x
                sta ntChnDuration,x
                sta ntChnTrans,x
                sta ntInitSong
                rts

        ; Play one frame of music & sound effects
        ;
        ; Parameters: X=0
        ; Returns: -
        ; Modifies: A,X,Y,player vars

PlayRoutine:    lda ntInitSong
                bpl Play_DoInit

          ;Filter execution

                ldy ntFiltPos
                beq Play_FiltDone
Play_FiltTimeM1:lda $1000,y
                bpl Play_FiltMod
                cmp #$ff
                bcs Play_FiltJump
Play_SetFilt:   sta $d417
                and #$70
                sta Play_FiltType+1
Play_FiltJump:
Play_FiltSpdM1a:lda $1000,y
                bcs Play_FiltJump2
Play_NextFilt:  inc ntFiltPos
                bcc Play_StoreCutoff
Play_FiltJump2: sta ntFiltPos
                bcs Play_FiltDone
Play_FiltMod:   clc
                dec ntFiltTime
                bmi Play_NewFiltMod
                bne Play_FiltCutoff
                inc ntFiltPos
                bcc Play_FiltDone
Play_NewFiltMod:sta ntFiltTime
Play_FiltCutoff:lda #$00
Play_FiltSpdM1b:adc $1000,y
Play_StoreCutoff:
                sta Play_FiltCutoff+1
Play_ModifyCutoff8580:
                sbc #CUTOFF_8580_ADJUST
                bcc Play_CutoffOver
                cmp #MIN_8580_CUTOFF
                bcs Play_CutoffOK
Play_CutoffOver:lda #MIN_8580_CUTOFF
Play_CutoffOK:  sta $d416

Play_FiltDone:
Play_FadeSpd:   lda #$00
                beq Play_FiltType               ;Optimize for no fade
Play_FadeDelay: adc #$00
                sta Play_FadeDelay+1
                bcc Play_FiltType
                dec Play_MasterVol+1
                bpl Play_FiltType
                stx Play_MasterVol+1            ;X=0 here
Play_FiltType:  lda #$00
Play_MasterVol: ora #$0f
                sta $d418

        ;Channel execution

                jsr Play_ChnExec
                ldx #$07
                jsr Play_ChnExec
                ldx #$0e

        ;Update duration counter

Play_ChnExec:   inc ntChnCounter,x
                bne Play_NoPattern

        ;Get data from pattern

Play_Pattern:   ldy ntChnPattNum,x
Play_PattTblLoM1:
                lda $1000,y
                sta ntTemp1
Play_PattTblHiM1:
                lda $1000,y
                sta ntTemp2
                ldy ntChnPattPos,x
                lda (ntTemp1),y
                lsr
                sta ntChnNewNote,x
                bcc Play_NoNewCmd
Play_NewCmd:    iny
                lda (ntTemp1),y
                sta ntChnCmd,x
                bcc Play_Rest
Play_CheckHr:   bmi Play_Rest
                lda ntChnSfx,x
                bne Play_Rest
                lda #$fe
                sta ntChnGate,x
                sta $d405,x
                lda #NT_HRPARAM
                sta $d406,x
Play_Rest:      iny
                lda (ntTemp1),y
                cmp #$c0
                bcc Play_NoNewDur
                iny
                sta ntChnDuration,x
Play_NoNewDur:  lda (ntTemp1),y
                beq Play_EndPatt
                tya
Play_EndPatt:   sta ntChnPattPos,x
Play_JumpToWave:ldy ntChnSfx,x
                bne Play_JumpToSfx
                jmp Play_WaveExec
Play_JumpToSfx: jmp Play_SfxExec

        ;No new command, or gate control

Play_NoNewCmd:  cmp #NT_FIRSTNOTE/2
                bcc Play_GateCtrl
                lda ntChnCmd,x
                bcs Play_CheckHr
Play_GateCtrl:  lsr
                ora #$fe
                sta ntChnGate,x
                bcc Play_NewCmd
                sta ntChnNewNote,x
                bcs Play_Rest

        ;No new pattern data

Play_LegatoCmd: tya
                and #$7f
                tay
                bpl Play_SkipAdsr

Play_JumpToPulse:
                ldy ntChnSfx,x
                bne Play_JumpToSfx
                jmp Play_PulseExec
Play_NoPattern: lda ntChnCounter,x
                cmp #$02
                bne Play_JumpToPulse

        ;Reload counter and check for new note / command exec / track access

Play_Reload:    lda ntChnDuration,x
                sta ntChnCounter,x
                lda ntChnNewNote,x
                bpl Play_NewNoteInit
                lda ntChnPattPos,x
                bne Play_JumpToPulse

         ;Get data from track

Play_Track:     ldy ntChnSongPos,x
                lda (ntTrackLo),y
                bne Play_NoSongJump
                iny
                lda (ntTrackLo),y
                tay
                lda (ntTrackLo),y
Play_NoSongJump:bpl Play_NoSongTrans
                sta ntChnTrans,x
                iny
                lda (ntTrackLo),y
Play_NoSongTrans:
                sta ntChnPattNum,x
                iny
                tya
                sta ntChnSongPos,x
                bcs Play_JumpToWave
                bcc Play_CmdExecuted

        ;New note init / command exec

Play_NewNoteInit: 
                cmp #NT_FIRSTNOTE/2
                bcc Play_SkipNote
                adc ntChnTrans,x
                asl
                sta ntChnNote,x
                sec
Play_SkipNote:  ldy ntChnCmd,x
                bmi Play_LegatoCmd
Play_CmdADM1:   lda $1000,y
                sta $d405,x
Play_CmdSRM1:   lda $1000,y
                sta $d406,x
                bcc Play_SkipGate
                lda #$ff
                sta ntChnGate,x
                lda #NT_FIRSTWAVE
                sta $d404,x
Play_SkipGate:
Play_SkipAdsr:
Play_CmdWaveM1: lda $1000,y
                beq Play_SkipWave
                sta ntChnWavePos,x
                lda #$00
                sta ntChnWaveTime,x
Play_SkipWave:    
Play_CmdPulseM1:lda $1000,y
                beq Play_SkipPulse
                sta ntChnPulsePos,x
                lda #$00
                sta ntChnPulseTime,x
Play_SkipPulse:   
Play_CmdFiltM1: lda $1000,y
                beq Play_SkipFilt
                sta ntFiltPos
                lda #$00
                sta ntFiltTime
Play_SkipFilt:  clc
                lda ntChnPattPos,x
                beq Play_Track
Play_CmdExecuted:
Play_NoTrack:   rts

        ;Pulse execution

Play_NoPulseMod:cmp #$ff
Play_PulseSpdM1a:
                lda $1000,y
                bcs Play_PulseJump
                inc ntChnPulsePos,x
                bcc Play_StorePulse
Play_PulseJump: sta ntChnPulsePos,x
                bcs Play_PulseDone
Play_PulseExec: ldy ntChnPulsePos,x
                beq Play_PulseDone
Play_PulseTimeM1:
                lda $1000,y
                bmi Play_NoPulseMod
Play_PulseMod:  clc
                dec ntChnPulseTime,x
                bmi Play_NewPulseMod
                bne Play_NoNewPulseMod
                inc ntChnPulsePos,x
                bcc Play_PulseDone
Play_NewPulseMod:
                sta ntChnPulseTime,x
Play_NoNewPulseMod:
                lda ntChnPulse,x
Play_PulseSpdM1b:
                adc $1000,y
                adc #$00
Play_StorePulse:sta ntChnPulse,x
                sta $d402,x
                sta $d403,x
Play_PulseDone:

        ;Wavetable execution

Play_WaveExec:  ldy ntChnWavePos,x
                beq Play_WaveDone
Play_WaveM1:    lda $1000,y
                cmp #$c0
                bcs Play_SlideOrVib
                cmp #$90
                bcc Play_WaveChange

        ;Delayed wavetable

Play_WaveDelay: beq Play_NoWaveChange
                dec ntChnWaveTime,x
                beq Play_NoWaveChange
                bpl Play_WaveDone
                sbc #$90
                sta ntChnWaveTime,x
                bcs Play_WaveDone

        ;Wave change + arpeggio

Play_WaveChange:sta ntChnWave,x
                tya
                sta ntChnWaveOld,x
Play_NoWaveChange:
Play_WaveP0:    lda $1000,y
                cmp #$ff
                bcs Play_WaveJump
Play_NoWaveJump:inc ntChnWavePos,x
                bcc Play_WaveJumpDone
Play_WaveJump:
Play_NoteP0:    lda $1000,y
                sta ntChnWavePos,x
Play_WaveJumpDone:
Play_NoteM1a:   lda $1000,y
                asl
                bcs Play_AbsFreq
                adc ntChnNote,x
Play_AbsFreq:   tay
                bne Play_NoteNum
Play_SlideDone: ldy ntChnNote,x
                lda ntChnWaveOld,x
                sta ntChnWavePos,x
Play_NoteNum:   lda ntFreqTbl-24,y
                sta ntChnFreqLo,x
                sta $d400,x
                lda ntFreqTbl-23,y
Play_StoreFreqHi:
                sta $d401,x
                sta ntChnFreqHi,x
Play_WaveDone:  lda ntChnWave,x
                and ntChnGate,x
                sta $d404,x
                rts

        ;Slide or vibrato

Play_SlideOrVib:sbc #$e0
                sta ntTemp1
                lda ntChnCounter,x
                beq Play_WaveDone
Play_NoteM1b:   lda $1000,y
                sta ntTemp2
                bcc Play_Vibrato

        ;Slide (toneportamento)

Play_Slide:     ldy ntChnNote,x
                lda ntChnFreqLo,x
                sbc ntFreqTbl-24,y
                pha
                lda ntChnFreqHi,x
                sbc ntFreqTbl-23,y
                tay
                pla
                bcs Play_SlideDown
Play_Slideup:   adc ntTemp2
                tya
                adc ntTemp1
                bcs Play_SlideDone
Play_FreqAdd:   lda ntChnFreqLo,x
                adc ntTemp2
                sta ntChnFreqLo,x
                sta $d400,x
                lda ntChnFreqHi,x
                adc ntTemp1
                jmp Play_StoreFreqHi

Play_SlideDown: sbc ntTemp2
                tya
                sbc ntTemp1
                bcc Play_SlideDone
Play_FreqSub:   lda ntChnFreqLo,x
                sbc ntTemp2
                sta ntChnFreqLo,x
                sta $d400,x
                lda ntChnFreqHi,x
                sbc ntTemp1
                jmp Play_StoreFreqHi

          ;Sound effect hard restart

Play_SfxHRFirstWave:
                lda #NT_SFXFIRSTWAVE
                sta ntChnWave,x
Play_SfxHR:     lda #$00
                sta $d405,x
                sta $d406,x
                beq Play_WaveDone

          ;Vibrato

Play_Vibrato:   lda ntChnWaveTime,x
                bpl Play_VibNoDir
                cmp ntTemp1
                bcs Play_VibNoDir2
                eor #$ff
Play_VibNoDir:  sec
Play_VibNoDir2: sbc #$02
                sta ntChnWaveTime,x
                lsr
                lda #$00
                sta ntTemp1
                bcc Play_FreqAdd
                bcs Play_FreqSub

          ;Sound effect

Play_SfxExec:   lda ntChnSfxLo,x
                sta ntTemp1
                lda ntChnSfxHi,x
                sta ntTemp2
                lda #$fe
                sta ntChnNewNote,x
                sta ntChnGate,x
                inc ntChnSfx,x
                cpy #$02
                beq Play_SfxHRFirstWave
                bcc Play_SfxHR
Play_SfxMain:   lda (ntTemp1),y
                beq Play_SfxEnd
Play_SfxNoEnd:  asl
                tay
                lda ntFreqTbl-24,y
                sta $d400,x
                lda ntFreqTbl-23,y
                sta $d401,x
                ldy ntChnSfx,x
                lda (ntTemp1),y
                beq Play_SfxDone
                cmp #$82
                bcs Play_SfxDone
                inc ntChnSfx,x
Play_SfxWaveChg:sta ntChnWave,x
                sta $d404,x
                ldy #$02
                lda (ntTemp1),y
                sta $d402,x
                sta $d403,x
                dey
                lda (ntTemp1),y
                sta $d405,x
                dey
                lda (ntTemp1),y
                sta $d406,x
Play_SfxDone:   rts
Play_SfxEnd:    sta ntChnSfx,x
                sta ntChnWavePos,x
                sta ntChnWaveOld,x
                beq Play_SfxWaveChg
