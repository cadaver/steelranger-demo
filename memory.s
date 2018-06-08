                include macros.s

        ; Constants that affect the memory map

MAX_SPR         = 24
MAX_CACHESPRITES = 64
MAX_CHUNKFILES  = 52
MAX_ACT         = 16
MAX_COMPLEXACT  = 8
MAX_PERSISTENTACT = 13
MAX_ZONEACT     = 21
MAX_ZONEOBJ     = 9
MAX_LVLACT      = 128
MAX_LVLOBJ      = 32
MAX_LVLZONES    = 32
MAX_GLOBALACT   = 32
MAX_NPCS        = 5
MAX_BLOCKUPDATES = 8
MAX_WEAPONS     = 8
MAX_ZONEROWS    = 64
MAX_SAVES       = 4
MAX_NAMELENGTH  = 12
MAX_PLOTBITS    = 16
SCROLLROWS      = 21
SCROLLSPLIT     = 11
STACKSTART      = $ff
SAVEDESCSIZE    = MAX_NAMELENGTH+1+1+3          ;Name, levelnumber, time hours/minutes/seconds

ACTI_PLAYER     = 0
ACTI_FIRST      = 1
ACTI_LASTCOMPLEX = 7
ACTI_LASTPERSISTENT = 12
ACTI_LAST       = 15                            ;Two dedicated actors for player bullets only + object marker

USETURBOMODE    = 1                            ;C128 / SCPU turbo mode enable during blanking

        ; Zeropage variables

                varbase $02

                var loadTempReg                 ;Loader variables
                var fileOpen

                var zpLenLo                     ;Exomizer 2 depackroutine variables
                var zpSrcLo
                var zpSrcHi
                var zpDestLo
                var zpDestHi
                var zpBitsLo
                var zpBitsHi
                var zpBitBuf
                var ntscFlag

                var temp1
                var temp2
                var temp3
                var temp4
                var temp5
                var temp6
                var temp7
                var temp8

                var freeMemLo                   ;Memory allocator variables
                var freeMemHi
                var musicDataLo                 ;Free memory end before zonebuffer
                var musicDataHi

                var joystick                    ;Input variables
                var prevJoy
                var keyPress
                var keyType

                var scrCounter                  ;Scrolling / screen variables
                var scrollX
                var scrollY
                var scrollSX
                var scrollSY
                var screen
                var blockX
                var blockY
                var mapX
                var mapY
                var mapSizeX
                var mapSizeY
                var zoneBufferLo                ;Free memory end after musicdata + zone
                var zoneBufferHi
                var worldX
                var worldY
                var levelNum
                var zoneNum
                var blockUpdates

                var panelUpdateFlags            ;Scorepanel / menu system variables
                var panelTextDelay
                var dialogueLo
                var dialogueHi
                var textColor

                var sprIndex                    ;Spritefile access variables
                var sprFileNum
                var sprFileLo
                var sprFileHi

                var actIndex                    ;Actor / game variables
                var bulletActIndex
                var actLo
                var actHi
                var wpnLo
                var wpnHi
                var wpnBits
                var numTargets
                var atObj
                var adjacentObj
                var autoDeactObj
                var autoDeactDelay
                var wpnMenuMode
                varrange sprOrder,MAX_SPR+1
                varrange sprY,MAX_SPR+1
                varrange sprX,MAX_SPR

                checkvarbase $90

                varbase $c0
                varrange sprXLSB,MAX_SPR
                varrange sprC,MAX_SPR

                var flashScreen
                var shakeScreen
                var irqSaveA
                var irqSaveX
                var irqSaveY
                var irqSave01
                var irqTemp
                var newFrameFlag
                var firstSortSpr

                var ntInitSong                  ;Playroutine
                var ntTemp1
                var ntTemp2
                var ntTrackLo
                var ntTrackHi
                var ntFiltPos
                var ntFiltTime

                checkvarbase $100

        ; Memory areas and non-zeropage variables

purgeList       = $0100
depackBuffer    = $0101
loadBuffer      = $0200

exomizerCodeStart = $0334

scriptCodeRelocStart = $8000
videoBank       = $c000
fileAreaEnd     = $d000
emptySprite     = $d000
spriteCache     = $d000
colors          = $d800
panelChars      = $e000
panelScreen     = $e400
screen1         = $e400
screen2         = $e800
levelDataStart  = $ec00
titleStart      = $ed00
blkInfo         = $f100
blkTL           = $f200
blkTR           = $f300
blkBL           = $f400
blkBR           = $f500
charColors      = $f600
levelCode       = $f700
lvlObjAnimFrames = $f7c0
waterColorOverride = $f7ff
chars           = $f800

                varbase panelChars+104*8

                varrange sprF,MAX_SPR
                varrange sprAct,MAX_SPR
                varrange sortSprX,MAX_SPR*2
                varrange sortSprD010,MAX_SPR*2
                varrange zoneObjIndex,MAX_ZONEOBJ+1
                varrange zoneActIndex,MAX_ZONEACT+1
                varrange targetList,MAX_PERSISTENTACT+1
                checkvarbase screen1

                varbase screen1+24*40
                varrange sortSprY,MAX_SPR*2
                varrange blkUpdB,MAX_BLOCKUPDATES
                checkvarbase screen1+1016

                varbase screen2+21*40
                varrange sortSprF,MAX_SPR*2
                varrange sortSprC,MAX_SPR*2
                varrange sprIrqLine,MAX_SPR*2
                varrange blkUpdX,MAX_BLOCKUPDATES
                varrange blkUpdY,MAX_BLOCKUPDATES

                varrange displayedAmmo,MAX_WEAPONS
                var playerCtrl
                var animObjDelay
                var fuelRechargeDelay
                var healthRechargeDelay
                var dialoguePos
                var dialogueAct
                var menuMode
                var menuPos

                checkvarbase screen2+1016

                varbase levelDataStart

                varrange actBoundL,MAX_ACT
                varrange actBoundR,MAX_ACT
                varrange actBoundU,MAX_ACT
                varrange actBoundD,MAX_ACT

                ;Accessed as -$40, so best not placed at page start
                varrange cacheSprAge,MAX_CACHESPRITES
                varrange cacheSprFrame,MAX_CACHESPRITES
                varrange cacheSprFile,MAX_CACHESPRITES

                checkvarbase titleStart
                varrange lvlZoneCharset,MAX_LVLZONES
                varrange lvlZoneBg1,MAX_LVLZONES
                varrange lvlZoneBg2,MAX_LVLZONES
                varrange lvlZoneBg3,MAX_LVLZONES

                varrange lvlObjX,MAX_LVLOBJ
                varrange lvlObjY,MAX_LVLOBJ
                varrange lvlObjZ,MAX_LVLOBJ
                varrange lvlObjFlags,MAX_LVLOBJ
                varrange lvlObjSize,MAX_LVLOBJ
                varrange lvlObjFrame,MAX_LVLOBJ
                varrange lvlObjDL,MAX_LVLOBJ
                varrange lvlObjDH,MAX_LVLOBJ

                varrange lvlActX,MAX_LVLACT
                varrange lvlActY,MAX_LVLACT
                varrange lvlActT,MAX_LVLACT
                varrange lvlActZ,MAX_LVLACT
                
                varrange mapTblLo,MAX_ZONEROWS
                varrange mapTblHi,MAX_ZONEROWS

                checkvarbase blkInfo
