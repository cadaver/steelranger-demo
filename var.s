                include bg/worldinfo.s

        ; Actors

actF2:          ds.b MAX_COMPLEXACT,0
actXL:          ds.b MAX_ACT,0
actXH:          ds.b MAX_ACT,0
actYL:          ds.b MAX_ACT,0
actYH:          ds.b MAX_ACT,0
actPrevXL:      ds.b MAX_ACT,0
actPrevXH:      ds.b MAX_ACT,0
actPrevYL:      ds.b MAX_ACT,0
actPrevYH:      ds.b MAX_ACT,0
actT:           ds.b MAX_ACT,0
actD:           ds.b MAX_ACT,0
actF1:          ds.b MAX_ACT,0
actFlash:       ds.b MAX_ACT,0
actSizeH:       ds.b MAX_ACT,0
actSizeU:       ds.b MAX_ACT,0
actSizeD:       ds.b MAX_ACT,0
actFlags:       ds.b MAX_ACT,0
actHp:          ds.b MAX_ACT,0
actFd:          ds.b MAX_ACT,0
actMB:          ds.b MAX_ACT,0
actTime:        ds.b MAX_ACT,0
actSX:          ds.b MAX_ACT,0
actSY:          ds.b MAX_ACT,0
actFall:        ds.b MAX_COMPLEXACT,0
actWpn:         ds.b MAX_COMPLEXACT,0
actAttackD:     ds.b MAX_COMPLEXACT,0
actCtrl:        ds.b MAX_COMPLEXACT,0
actMoveCtrl:    ds.b MAX_COMPLEXACT,0
actPrevCtrl:    ds.b MAX_COMPLEXACT,0
actEnemyRank:   ds.b MAX_COMPLEXACT,0
actOrg:         ds.b MAX_PERSISTENTACT,0
actInWater:     ds.b MAX_PERSISTENTACT,0
actDmg:         ds.b MAX_PERSISTENTACT,0
actDmgImpulse:  ds.b MAX_PERSISTENTACT,0

gameOptions     = actFd                         ;In title, use actor vars not needed for display
                                                ;to store options & savedescs
                if gameOptions & $ff00 != 0
                    err
                endif

        ; Playroutine
        
ntChnPattPos:   dc.b 0
ntChnCounter:   dc.b 0
ntChnNewNote:   dc.b 0
ntChnWavePos:   dc.b 0
ntChnPulsePos:  dc.b 0
ntChnWave:      dc.b 0
ntChnPulse:     dc.b 0
                dc.b 0,0,0,0,0,0,0
                dc.b 0,0,0,0,0,0,0

ntChnGate:      dc.b 0
ntChnTrans:     dc.b 0
ntChnCmd:       dc.b 0
ntChnSongPos:   dc.b 0
ntChnPattNum:   dc.b 0
ntChnDuration:  dc.b 0
ntChnNote:      dc.b 0
                dc.b 0,0,0,0,0,0,0
                dc.b 0,0,0,0,0,0,0

ntChnFreqLo:    dc.b 0
ntChnFreqHi:    dc.b 0
ntChnWaveTime:  dc.b 0
ntChnPulseTime: dc.b 0
ntChnSfx:       dc.b 0
ntChnSfxLo:     dc.b 0
ntChnWaveOld:   dc.b 0
                dc.b 0,0,0,0,0,0,0
                dc.b 0,0,0,0,0,0,0

ntChnSfxHi = ntChnWaveOld

        ; Player state

playerStateStart:

score:          ds.b 3,0
parts:          ds.b 2,0
fuel:           dc.b 0
upgrade:        dc.b 0
upgrade2:       dc.b 0
security:       dc.b 0
wpnIndex:       dc.b 0
weapons:        dc.b 1
ammoLo:         ds.b MAX_WEAPONS,0
ammoHi:         dc.b MAX_AMMO,0,0,0,0,0,0,0
time:           ds.b 4,0
bossHealth:     dc.b 0
plotBits:       ds.b MAX_PLOTBITS/8,0
scriptVar:      dc.b 0
scriptVar2:     dc.b 0
scriptVar3:     dc.b 0
scriptF:        dc.b NO_SCRIPT
scriptEP:       dc.b 0
npcScriptF:     ds.b MAX_NPCS,NO_SCRIPT
npcScriptEP:    ds.b MAX_NPCS,0
radioMsgF:      dc.b NO_SCRIPT
radioMsgEP:     dc.b 0
radioMsgDelay:  dc.b 0
songOverride:   dc.b 0

lvlObjBits:     ds.b LEVELOBJBITSIZE,$00
zoneBits:       ds.b ZONEBITSIZE,$00
playerStateZeroEnd:
lvlActBits:     ds.b LEVELACTBITSIZE,$ff

globalActX:     ds.b MAX_GLOBALACT,0
globalActY:     ds.b MAX_GLOBALACT,0
globalActT:     ds.b MAX_GLOBALACT,0
globalActZ:     ds.b MAX_GLOBALACT,0
globalActL:     ds.b MAX_GLOBALACT,0

playerProfileStart:
rangerName:     ds.b MAX_NAMELENGTH+1,0
rangerColor:    dc.b 0
rangerNoArmorBaseFrame:
                dc.b 0
playerProfileEnd:
playerStateEnd:

        ; In-memory savestate

saveStart:

saveXH:         dc.b 0
saveYL:         dc.b 0
saveYH:         dc.b 0
saveT:          dc.b 0
saveD:          dc.b 0
saveHp:         dc.b 0
saveWorldX:     dc.b 0
saveWorldY:     dc.b 0
saveLevel:      dc.b 0
saveState:      ds.b playerStateEnd-playerStateStart,0

saveEnd:

        ; Other vars

lastSaveSlot:   dc.b 0

        ; Chunkfile allocation vars

fileLo:         ds.b MAX_CHUNKFILES,0
fileHi:         ds.b MAX_CHUNKFILES,0
fileNumObjects: ds.b MAX_CHUNKFILES,0
fileAge:        ds.b MAX_CHUNKFILES,0
