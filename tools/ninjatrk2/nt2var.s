;-------------------------------------------------------------------------------
; Editor variables
;-------------------------------------------------------------------------------

dirname:        dc.b "$"
scratch:        dc.b "S0:"
name:           dc.b "                ",0

textcolor:      dc.b 0
drivenumber:    dc.b 0
dirprintnum:    dc.b 0
namelength:     dc.b 0
fastfwd:        dc.b 0
curraster:      dc.b 0
maxraster:      dc.b 0
timeframe:      dc.b 0
timesec:        dc.b 0
timemin:        dc.b 0
playflag:       dc.b 0
fastup:         dc.b 0
fastdown:       dc.b 0
key:            dc.b 0
hexdigit:       dc.b 0
firsttime:      dc.b 0
cursorcol:      dc.b 0
octave:         dc.b 3
songnum:        dc.b 0
pattnum:        dc.b 1
editmode:       dc.b 0

tracknum:       dc.b 0
trackcol:       dc.b 0
trackrow:       dc.b 0,0,0
trackview:      dc.b 0,0,0
trackmarkmode:  dc.b 0
trackmarknum:   dc.b 0
trackmarkstart: dc.b 0
trackmarkend:   dc.b 0
trackcopylen:   dc.b 0
worktrackstart: dc.b 0,0,0
worktracklen:   dc.b 0,0,0

pattrow:        dc.b 0
pattcol:        dc.b 0
pattview:       dc.b 0
pattmarkmode:   dc.b 0
pattmarkstart:  dc.b 0
pattmarkend:    dc.b 0
pattcopylen:    dc.b 0
workpattlen:    dc.b 0
totaldurlo:     dc.b 0
totaldurhi:     dc.b 0
durposlo:       dc.b 0
durposhi:       dc.b 0
pattbytes:      dc.b 0
testnotecmd:    dc.b 1
keymode:        dc.b 0

tblnum:         dc.b 0
tblcol:         dc.b 0
tblrow:         dc.b 0,0,0
tblview:        dc.b 0,0,0
tblmarkmode:    dc.b 0
tblmarknum:     dc.b 0
tblmarkstart:   dc.b 0
tblmarkend:     dc.b 0
tblcopylen:     dc.b 0

cmdcol:         dc.b 0
cmdrow:         dc.b 0
cmdnum:         dc.b 0
cmdview:        dc.b 0
cmdcopied:      dc.b 0
cmdcopydest:    dc.b 0
cmdcopysrc:     dc.b 0
cmdcopyad:      dc.b 0
cmdcopysr:      dc.b 0
cmdcopywave:    dc.b 0
cmdcopypulse:   dc.b 0
cmdcopyfilt:    dc.b 0

globalrow:      dc.b 0
globalcol:      dc.b 0
acnum:          dc.b 0

relocmode:      dc.b 0
reloclo:        dc.b $00
relochi:        dc.b $10
reloczp:        dc.b $fc

lastpatt:       dc.b 0
lastsong:       dc.b 0
lastcmd:        dc.b 0
lastlegatocmd:  dc.b 0

relocsizetbllo:
playersizelo:    dc.b 0
wavetblsizelo:   dc.b 0
notetblsizelo:   dc.b 0
pulsetimetblsizelo:dc.b 0
pulsespdtblsizelo:dc.b 0
filttimetblsizelo:dc.b 0
filtspdtblsizelo:dc.b 0
cmdadsizelo:     dc.b 0
cmdsrsizelo:     dc.b 0
cmdwavesizelo:   dc.b 0
cmdpulsesizelo:  dc.b 0
cmdfiltsizelo:   dc.b 0
patttbllosizelo: dc.b 0
patttblhisizelo: dc.b 0
songtblsizelo:   dc.b 0
pattsizelo:      dc.b 0
tracksizelo:     dc.b 0

relocsizetblhi:
playersizehi:    dc.b 0
wavetblsizehi:   dc.b 0
notetblsizehi:   dc.b 0
pulsetimetblsizehi:dc.b 0
pulsespdtblsizehi:dc.b 0
filttimetblsizehi:dc.b 0
filtspdtblsizehi:dc.b 0
cmdadsizehi:     dc.b 0
cmdsrsizehi:     dc.b 0
cmdwavesizehi:   dc.b 0
cmdpulsesizehi:  dc.b 0
cmdfiltsizehi:   dc.b 0
patttbllosizehi: dc.b 0
patttblhisizehi: dc.b 0
songtblsizehi:   dc.b 0
pattsizehi:      dc.b 0
tracksizehi:     dc.b 0

relocadrtbllo:
playeradrlo:    dc.b 0
wavetbladrlo:   dc.b 0
notetbladrlo:   dc.b 0
pulsetimetbladrlo:dc.b 0
pulsespdtbladrlo:dc.b 0
filttimetbladrlo:dc.b 0
filtspdtbladrlo:dc.b 0
cmdadadrlo:     dc.b 0
cmdsradrlo:     dc.b 0
cmdwaveadrlo:   dc.b 0
cmdpulseadrlo:  dc.b 0
cmdfiltadrlo:   dc.b 0
patttblloadrlo: dc.b 0
patttblhiadrlo: dc.b 0
songtbladrlo:   dc.b 0
pattadrlo:      dc.b 0
trackadrlo:     dc.b 0
relocendlo:     dc.b 0

relocadrtblhi:
playeradrhi:    dc.b 0
wavetbladrhi:   dc.b 0
notetbladrhi:   dc.b 0
pulsetimetbladrhi:dc.b 0
pulsespdtbladrhi:dc.b 0
filttimetbladrhi:dc.b 0
filtspdtbladrhi:dc.b 0
cmdadadrhi:     dc.b 0
cmdsradrhi:     dc.b 0
cmdwaveadrhi:   dc.b 0
cmdpulseadrhi:  dc.b 0
cmdfiltadrhi:   dc.b 0
patttblloadrhi: dc.b 0
patttblhiadrhi: dc.b 0
songtbladrhi:   dc.b 0
pattadrhi:      dc.b 0
trackadrhi:     dc.b 0
relocendhi:     dc.b 0

;-------------------------------------------------------------------------------
; Worktracks/patterns & copybuffers
;-------------------------------------------------------------------------------

worktrack1:     ds.b MAX_SONGLEN,0
worktrack2:     ds.b MAX_SONGLEN,0
worktrack3:     ds.b MAX_SONGLEN,0

workpattnote:   ds.b MAX_PATTLEN+1,0
workpattcmd:    ds.b MAX_PATTLEN+1,0
workpattdur:    ds.b MAX_PATTLEN+1,0

trackcopybuffer:ds.b MAX_SONGLEN,0

pattcopynote:   ds.b MAX_PATTLEN,0
pattcopycmd:    ds.b MAX_PATTLEN,0
pattcopydur:    ds.b MAX_PATTLEN,0

tblcopyleft:    ds.b MAX_TBLLEN,0
tblcopyright:   ds.b MAX_TBLLEN,0

cmdcopyname:    ds.b MAX_CMDNAMELEN," "

;-------------------------------------------------------------------------------
; Gamemusicmode header
;-------------------------------------------------------------------------------

gamedatastart:

gamewavetblsize:  dc.b 0
gamepulsetblsize: dc.b 0
gamefilttblsize:  dc.b 0
gamecmdsize:      dc.b 0
gamelegatocmdsize:dc.b 0
gamepatttblsize:  dc.b 0

gamedataend:
