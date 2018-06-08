;-------------------------------------------------------------------------------
; Playroutine support data (not saved)
;-------------------------------------------------------------------------------

nt_songtbl:
N               set 0
                repeat MAX_SONGS
                dc.b <(nt_tracks+N*MAX_SONGLEN)
                dc.b >(nt_tracks+N*MAX_SONGLEN)
                dc.b 0,0,0
N               set N+1
                repend

nt_patttbllo:
N               set 0
                repeat MAX_PATT
                dc.b <(nt_patterns+N*MAX_PATTLEN)
N               set N+1
                repend

nt_patttblhi:
N               set 0
                repeat MAX_PATT
                dc.b >(nt_patterns+N*MAX_PATTLEN)
N               set N+1
                repend
              
nt_wavetbl:     ds.b MAX_TBLLEN+1,0
nt_pulsespdtbl: ds.b MAX_TBLLEN+1,0

;-------------------------------------------------------------------------------
; Song data
;-------------------------------------------------------------------------------

savesongstart:

nt_tables:
nt_waveedittbl: ds.b MAX_TBLLEN+1,0
nt_notetbl:     ds.b MAX_TBLLEN+1,0
nt_pulsetimetbl:ds.b MAX_TBLLEN+1,0
nt_pulsespdedittbl: ds.b MAX_TBLLEN+1,0
nt_filttimetbl: ds.b MAX_TBLLEN+1,0
nt_filtspdtbl:  ds.b MAX_TBLLEN+1,0

nt_patterns:    ds.b MAX_PATT*MAX_PATTLEN,0

nt_song:
nt_tracks:      ds.b MAX_SONGS*MAX_SONGLEN,0

nt_cmdad:       ds.b MAX_CMD,0
nt_cmdsr:       ds.b MAX_CMD,0
nt_cmdwavepos:  ds.b MAX_CMD,0
nt_cmdpulsepos: ds.b MAX_CMD,0
nt_cmdfiltpos:  ds.b MAX_CMD,0

nt_cmdnames:
                repeat MAX_CMD
                ds.b MAX_CMDNAMELEN," "
                dc.b 0
                repend

songlen:        ds.b MAX_SONGS*3,0
tbllen:         dc.b 0,0,0
cmdlen:         dc.b 0

hrparam:        dc.b DEFAULT_HRPARAM
firstwave:      dc.b DEFAULT_FIRSTWAVE

savesongend:    dc.b $ff ;Save endmark, will not actually be saved

