                org $0000

                include macros.s
                include memory.s
                include mainsym.s

        ; Proper startlocation

WORLD_STARTX    = 0
WORLD_STARTY    = 17
WORLD_STARTLEVEL = 0
PLAYER_STARTX   = 8
PLAYER_STARTY   = 8

WORLD_STARTX_AFTERINTRO = 4
WORLD_STARTY_AFTERINTRO = 14
PLAYER_STARTX_AFTERINTRO = 4
PLAYER_STARTY_AFTERINTRO = 19

        ; Note! Code must be unambiguous! Relocated code cannot have skip1/skip2 -macros!

                dc.w scriptEnd-scriptStart  ;Chunk data size
                dc.b 30                     ;Number of objects

scriptStart:
                rorg scriptCodeRelocStart   ;Initial relocation address when loaded

                dc.w StartGame              ;$1100
                dc.w IntroText1             ;$1101
                dc.w IntroText2             ;$1102
                dc.w PilotIntro             ;$1103
                dc.w PilotIntroText         ;$1104
                dc.w JROfficerIntro         ;$1105
                dc.w JROfficerIdle          ;$1106
                dc.w JROfficerIntroText     ;$1107
                dc.w GruntIntro             ;$1108
                dc.w GruntIntroText         ;$1109
                dc.w GruntMove              ;$110a
                dc.w StartEngineRumble      ;$110b
                dc.w StopEngineRumble       ;$110c
                dc.w EngineRumbleTick       ;$110d
                dc.w HeavyShakeTick         ;$110e
                dc.w SROfficerIntro         ;$110f
                dc.w SROfficerIntroText     ;$1110
                dc.w StartHeavyShake        ;$1111
                dc.w GruntIntro2            ;$1112
                dc.w GruntIntro2Text        ;$1113
                dc.w MedicIntro             ;$1114
                dc.w MedicIntroText         ;$1115
                dc.w SuitInstallStation     ;$1116
                dc.w SROfficerSuit          ;$1117
                dc.w SROfficerSuitText      ;$1118
                dc.w ArmoryExplosions       ;$1119
                dc.w IntroText3             ;$111a
                dc.w JROfficerRadioText     ;$111b
                dc.w PostIntroTick          ;$111c
                dc.w IntroTextsTick         ;$111d

        ; Game startup & intro script

StartGame:      ldx #$00
                txa
SG_ResetState:  sta saveState,x                 ;Score, parts, weapons etc. to zero
                inx
                cpx #playerStateZeroEnd-playerStateStart
                bcc SG_ResetState
                tax
                lda #$ff                        ;All actors/items alive
                sta saveState+scriptF-playerStateStart ;Stop tick script
                sta saveState+radioMsgF-playerStateStart ;Stop radio message
SG_ResetActorBits:
                sta saveState+lvlActBits-playerStateStart,x
                inx
                cpx #LEVELACTBITSIZE
                bcc SG_ResetActorBits
                if WEAPON_CHEAT > 0
                lda #MAX_AMMO/2
                ldx #MAX_WEAPONS-1
SG_GiveAllWeapons:
                sta saveState+ammoHi-playerStateStart,x
                dex
                bpl SG_GiveAllWeapons
                lda #$ff                        ;Player has all weapons with half ammo
                sta saveState+weapons-playerStateStart
                else
                lda #MAX_AMMO
                sta saveState+ammoHi-playerStateStart ;Full ammo to SMG
                lda #1                          ;Player has SMG
                sta saveState+weapons-playerStateStart
                endif
                ldx #5*MAX_GLOBALACT
SG_CopyGlobalActors:
                lda globalActorData-1,x
                sta saveState+globalActX-playerStateStart-1,x
                dex
                bne SG_CopyGlobalActors
                ldx #playerProfileEnd-playerProfileStart-1 ;Copy the finalized ranger profile
SG_CopyProfile:lda playerProfileStart,x
                sta saveState+playerProfileStart-playerStateStart,x
                dex
                bpl SG_CopyProfile
                if PARTS_CHEAT > 0
                lda #<999
                sta saveState-playerStateStart+parts
                lda #>999
                sta saveState-playerStateStart+parts+1
                endif
                if WHEEL_CHEAT > 0 || HIGHJUMP_CHEAT > 0 || JETPACK_CHEAT > 0 || ANALYZER_CHEAT
                lda saveState-playerStateStart+upgrade
                ora #WHEEL_CHEAT*UPG_WHEEL + HIGHJUMP_CHEAT*UPG_HIGHJUMP + JETPACK_CHEAT*UPG_JETPACK + ANALYZER_CHEAT*(UPG_TECHANALYZER+UPG_BIOANALYZER)
                sta saveState-playerStateStart+upgrade
                lda #$ff
                sta saveState-playerStateStart+fuel
                endif
                if HEATSHIELD_CHEAT > 0
                lda saveState-playerStateStart+upgrade2
                ora #UPG2_HEATSHIELD
                sta saveState-playerStateStart+upgrade2
                endif
                if UPGRADE_CHEAT > 0
                lda #$ff
                sta saveState-playerStateStart+upgrade
                sta saveState-playerStateStart+upgrade2
                endif
                if HALFUPGRADE_CHEAT > 0
                lda #$ff-UPG_WPNCONSUMPTION
                sta saveState-playerStateStart+upgrade
                lda #$ff-UPG2_HEALTH2-UPG2_REGEN2-UPG2_WPNDAMAGE2
                sta saveState-playerStateStart+upgrade2
                endif
                if SECURITY_CHEAT > 0
                lda #$ff
                sta saveState-playerStateStart+security
                endif
                if PLOTBIT_CHEAT > 0
                lda #(PLOTBIT_CHEAT & $ff)
                sta saveState-playerStateStart+plotBits
                lda #(PLOTBIT_CHEAT >> 8)
                sta saveState-playerStateStart+plotBits+1
                endif
                ldx #gameInitDataEnd-gameInitData-1
SG_GameInitLoop:lda gameInitData,x              ;Copy player location, actor number etc.
                sta saveXH,x
                dex
                bpl SG_GameInitLoop
                ldx #npcInitDataEnd-npcInitData-1
SG_NPCInitLoop: lda npcInitData,x
                sta saveState-playerStateStart+npcScriptF,x
                dex
                bpl SG_NPCInitLoop

                if STARTPOS_CHEAT = 0
ShowIntro:      lda #SONG_INTRO
                sta saveState-playerStateStart+songOverride
                sta songOverride
                lda #<EP_IntroTextsTick         ;Script to show the intro pages
                sta saveState-playerStateStart+scriptEP
                lda #>EP_IntroTextsTick
                sta saveState-playerStateStart+scriptF
                else
                lda #<EP_PostIntroTick       ;If not starting from beginning, important to run the postintrotrigger,
                sta saveState-playerStateStart+scriptEP ;as it sets up proper actor types for the NPCs (run as a tick script, disables itself)
                lda #>EP_PostIntroTick
                sta saveState-playerStateStart+scriptF
                endif
                jmp RestoreState

        ; Pilot intro script

PilotIntro:     lda scriptF                     ;Hack - wait for intro pages to complete before speaking
                bpl PilotIntroWait
                lda #<EP_PilotIntroText
                jsr SpeakText
                bcc PilotIntroWait
                lda #NO_SCRIPT
                sta npcScriptF+NPC_PILOT
PilotIntroWait: rts

        ; JR officer intro script

JROfficerIntro: lda #<EP_JROfficerIntroText
                jsr SpeakText
                bcc JROfficerIdle
                lda #<EP_JROfficerIdle
                sta npcScriptEP+NPC_JROFFICER
                rts

        ; JR officer idle script

JROfficerIdle:  ldy #ACTI_PLAYER
                jsr GetActorDistance
                lda temp5
                sta actD,x                      ;Face player
                rts

        ; Grunt intro script

GruntIntro:     lda #<EP_GruntIntroText
                jsr SpeakText
                bcc GruntIntroWait
                lda #<EP_GruntMove
                sta npcScriptEP+NPC_GRUNT
GruntIntroWait: rts

        ; Grunt move script

GruntMove:      lda zoneNum
                cmp #6
                beq GruntMove_Stairs
                cmp #9
                beq GruntMove_Armory
                lda #JOY_RIGHT
                sta actMoveCtrl,x
                lda actMB,x
                and #MB_HITWALL
                beq GruntMove_NoWall
                lda actT,x
                jsr FindGlobalActor
                lda #6                          ;Move to the stairwell room
                sta globalActZ,y
                lda #2
                sta globalActX,y
                ldx actIndex                    ;Actor isn't here at this point, so just return quickly
GruntMove_NoWall:rts
GruntMove_Stairs:
                lda actYH,x
                cmp #13
                bcs GruntMove_StairsLeft
                lda #JOY_RIGHT
                sta actMoveCtrl,x
                rts
GruntMove_StairsLeft:
                lda #JOY_LEFT
                sta actMoveCtrl,x
                lda actMB,x
                and #MB_HITWALL
                beq GruntMove_NoWall
                lda actT,x
                jsr FindGlobalActor
                lda #9+$80                      ;Move to the armory, face left
                sta globalActZ,y
                lda #34
                sta globalActX,y
                lda #8
                sta globalActY,y
                ldx actIndex
                rts
GruntMove_Armory:
                lda #JOY_LEFT
                sta actMoveCtrl,x
                lda actXH,x
                cmp #31
                beq GruntMove_ArmoryDone
                rts
GruntMove_ArmoryDone:
                lda #$00
                sta actMoveCtrl,x
                lda #<EP_GruntIntro2
                sta npcScriptEP+NPC_GRUNT
                rts

        ; Screen shake effects

StartEngineRumble:
                lda #<EP_EngineRumbleTick
SetScriptThisFile:
                sta scriptEP
                lda #>EP_StartGame
                sta scriptF
                rts

StopEngineRumble:
                lda #NO_SCRIPT
                sta scriptF
                rts

EngineRumbleTick:
                lda UA_ItemFlashCounter+1
                and #$01
ERT_Common:     asl
                asl
                asl
                sta shakeScreen
                rts

HeavyShakeTick: lda UA_ItemFlashCounter+1
                and #$02
                bpl ERT_Common

        ; Senior officer intro

SROfficerIntro: jsr JROfficerIdle
                lda #<EP_SROfficerIntroText
                jsr SpeakText
                bcc SROfficerIntroWait
                lda #<EP_JROfficerIdle          ;Reuse JR officer idle
                sta npcScriptEP+NPC_SROFFICER
SkipHeavyShake:
SROfficerIntroWait:
                rts

        ; Heavy shake start + close armory door

StartHeavyShake:;lda scriptF                     ;Already triggered?
                ;bpl SkipHeavyShake
                lda #<EP_HeavyShakeTick         ;Start heavy screen shake
                jsr SetScriptThisFile
                ldy #$02
                jmp DeactivateObject

        ; Grunt intro part 2

GruntIntro2:    lda #<EP_GruntIntro2Text
                jsr SpeakText
                bcc GruntIntro2Wait
                lda #$80
                sta actD,x                      ;Face the medic
                lda #NO_SCRIPT
                sta npcScriptF+NPC_GRUNT
GruntIntro2Wait:rts

MedicIntro:     lda #<EP_MedicIntroText
                jsr SpeakText
                bcc MedicIntroWait
                lda #NO_SCRIPT
                sta npcScriptF+NPC_MEDIC
MedicIntroWait: rts

        ; Steel Ranger suit installation + ship getting hit

SuitInstallStation:
                jsr BlankScreen                 ;1 sec blanking to explain the sudden clothes change :)
                lda #25
                sta temp1
SIS_Delay:      jsr TextDisplayFrame
                bcs SIS_BreakDelay              ;Allow to interrupt
                dec temp1
                bne SIS_Delay
SIS_BreakDelay: lda #ACT_PLAYER                 ;Turn into Steel Ranger
                sta actT+ACTI_PLAYER
                jsr ApplyRangerColorAndUpgrades
                ldx #ACTI_PLAYER
                stx SuitFlash+1
                stx actSX+ACTI_PLAYER
                lda #$40                        ;Stand on the station platform
                sta actXL+ACTI_PLAYER
                sta actYL+ACTI_PLAYER
                lda #7
                sta actYH+ACTI_PLAYER
                lda #JOY_OVERRIDE+JOY_UP
                sta playerCtrl
                jsr NoInterpolation
                lda #<EP_SROfficerSuit
                sta npcScriptEP+NPC_SROFFICER
                rts

SROfficerSuit:  lda #<EP_SROfficerSuitText
                jsr SpeakText
                bcs SROfficerSuitDone
SuitFlash:      lda #$00
                pha
                inc SuitFlash+1
                lsr
                and #$03
                tay
                lda suitFlashTbl,y
                sta actFlash+ACTI_PLAYER
                pla
                and #$03
                bne SuitNoSound
                lda #SFX_ARCGUN
                jsr QueueSfx
SuitNoSound:    lda #JOY_OVERRIDE+JOY_UP        ;Keep the "up" override during suit powerup
                sta playerCtrl
SROfficerSuitWait:
                rts
SROfficerSuitDone:
                lda #NO_SCRIPT
                sta npcScriptF+NPC_SROFFICER
                lda #JOY_OVERRIDE               ;Look right, movement still disabled
                sta playerCtrl
                ldy #$04                        ;Show wall as broken
                jsr ActivateObject
                ldx actIndex
                jsr HumanDeath                  ;"Kill" the SR officer
                lda #3*8
                sta actSX,x
                lda #$00
                sta actHp,x
                sta actD+ACTI_PLAYER            ;Player forcibly looks right now
                lda #3
                sta flashScreen
                lda #4
                sta temp5
SROfficer_FirstExplosions:
                ldy lvlObjX+$04
                iny
                sty temp1
                ldy lvlObjY+$04
                ;iny
                sty temp3
                lda #$01
                sta temp2
                sta temp4
                jsr CreateExplosion
                dec temp5
                bne SROfficer_FirstExplosions
SROfficer_NoExplosion:
                lda #NO_SCRIPT                  ;Stop NPC script
                sta npcScriptF+NPC_SROFFICER
                lda #<EP_ArmoryExplosions
                jsr SetScriptThisFile
                lda #60
                sta explosionTime
                lda #$00
                sta explosionCounter
                jsr ApplyRangerColorAndUpgrades
                ldx actIndex
                rts

        ; Explosions in the armory, show final full page text, transport player outside

AE_Done:        jmp ShowIntroFinalPage
ArmoryExplosions:
                dec explosionTime
                beq AE_Done
                ldy #$00
                lda explosionTime
                lsr
                bcc AE_NoShake
                asl
                tay
AE_NoShake:     sty shakeScreen
                lda explosionTime
                cmp #15                 ;Stop some time before end
                bcc AE_NoExplosion
                jsr Random
                and #$70
                adc explosionCounter
                sta explosionCounter
                bcc AE_NoExplosion
                lda #$06
                sta temp1
                lda #$0f
                sta temp2
                lda #$03
                sta temp3
                lda #$01
                sta temp4
                jsr CreateExplosion
                bcc AE_NoExplosion
                lda #3
                sta flashScreen
AE_NoExplosion: rts

        ; Show final intro page and begin actual game

ShowIntroFinalPage:
                lda #<EP_IntroText3
                jsr ShowTextPage
                lda #$00
                sta saveState-playerStateStart+songOverride
                sta saveD
                sta saveState-playerStateStart+zoneBits     ;Clear visited zones to not show the undamaged ship on map
                sta saveState-playerStateStart+zoneBits+1
                lda #PLAYER_STARTX_AFTERINTRO
                sta saveXH+ACTI_PLAYER
                lda #PLAYER_STARTY_AFTERINTRO
                sta saveYH+ACTI_PLAYER
                lda #WORLD_STARTX_AFTERINTRO
                sta saveWorldX
                lda #WORLD_STARTY_AFTERINTRO
                sta saveWorldY
                lda #ACT_PLAYER
                sta saveT
                lda #LEVEL_SURFACE
                sta saveLevel                   ;Fix saveLevel as levelNum wasn't correct yet
                lda #<EP_PostIntroTick
                sta saveState-playerStateStart+scriptEP
                lda #>EP_PostIntroTick
                sta saveState-playerStateStart+scriptF
                jmp RestoreState

        ; Planet surface script. Assign new scripts & move NPCs & radio message

PostIntroTick:  ldx #npcPostInitDataEnd-npcPostInitData-1
PIT_NPCInitLoop:lda npcPostInitData,x
                sta npcScriptF,x
                dex
                bpl PIT_NPCInitLoop
                inx
PIT_NPCMoveLoop:lda npcNewPosData,x
                bmi PIT_NPCMoveEnd
                stx temp1
                jsr FindGlobalActor
                ldx temp1
                lda npcNewPosData+1,x
                sta globalActT,y
                lda npcNewPosData+2,x
                sta globalActL,y
                lda npcNewPosData+3,x
                sta globalActZ,y
                lda npcNewPosData+4,x
                sta globalActX,y
                lda npcNewPosData+5,x
                sta globalActY,y
                txa
                clc
                adc #$06
                tax
                bne PIT_NPCMoveLoop
PIT_NPCMoveEnd: ldx #$03
PIT_DisableEnemies:
                lda level3ActIDData,x    ;Disable elite soldiers in security tower, will be enabled later
                jsr DecodeBit
                pha
                tya
                clc
                adc lvlActBitStart+LEVEL_SECURITY
                tay
                pla
                eor #$ff
                and lvlActBits,y
                sta lvlActBits,y
                dex
                bpl PIT_DisableEnemies
                lda #NO_SCRIPT
                sta scriptF                     ;Was running as a tick script. Remove now
                if STARTPOS_CHEAT > 0
                if TEST_ENDING = 1
                lda #<EP_NormalEnding
                ldx #>EP_NormalEnding
                jmp ExecScript
                endif
                if TEST_ENDING = 2
                lda #PLOT_BOMBDEFUSED
                jsr SetPlotBit
                lda #<EP_PeacefulEnding
                ldx #>EP_PeacefulEnding
                jmp ExecScript
                endif
                endif
                if (STARTPOS_CHEAT = 0) || (TEST_WORLD_STARTX = 4)
                lda #<EP_JROfficerRadioText     ;Show radio message only at proper location, not when cheating
                sta radioMsgEP
                lda #>EP_JROfficerRadioText
                sta radioMsgF
                lda #$00
                sta radioMsgDelay
                endif
                rts
                endif

        ; Intro texts tick script
        
IntroTextsTick: lda #<EP_IntroText1
                jsr ShowTextPage
                lda #<EP_IntroText2
                jsr ShowTextPage
                lda #NO_SCRIPT
                sta scriptF
                jmp SaveState                   ;Resave state without intro texts

        ; Subroutines

SpeakText:      jsr GetTextAddress
                jmp NPCDialogue

GetTextAddress: ldy #>EP_IntroText1 + C_FIRSTSCRIPT
                jmp LoadChunkFile               ;Get text object address

ShowTextPage:   jsr GetTextAddress
                jsr BeginTextDisplay
                lda #0
                jmp ShowMultiLineText

CreateExplosion:lda #ACTI_FIRST
                ldy #ACTI_LASTPERSISTENT-1
                jsr GetFreeActor
                bcc CE_Cancel
                jsr Random
                and temp2
                adc temp1                       ;C=0
                sta actXH,y
                jsr Random
                and temp4
                adc temp3                       ;C=0
                sta actYH,y
                jsr Random
                lsr
                sta actXL,y
                jsr Random
                lsr
                sta actYL,y
                lda #ACT_EXPLOSION
                sta actT,y
                lda #SFX_EXPLOSION
                jsr QueueSfx
                sec
CE_Cancel:      rts

                brk

explosionTime:  dc.b 0
explosionCounter:
                dc.b 0

                if STARTPOS_CHEAT = 0
gameInitData:   dc.b PLAYER_STARTX, 0, PLAYER_STARTY, ACT_PLAYER_NOARMOR, $80, HP_PLAYER, WORLD_STARTX, WORLD_STARTY, WORLD_STARTLEVEL
                else
gameInitData:   dc.b TEST_PLAYER_STARTX, 0, TEST_PLAYER_STARTY, ACT_PLAYER, 0, HP_PLAYER, TEST_WORLD_STARTX, TEST_WORLD_STARTY, WORLD_STARTLEVEL
                endif
gameInitDataEnd:

npcInitData:    dc.b >EP_JROfficerIntro, >EP_PilotIntro, >EP_SROfficerIntro, >EP_GruntIntro, >EP_MedicIntro
                dc.b <EP_JROfficerIntro, <EP_PilotIntro, <EP_SROfficerIntro, <EP_GruntIntro, <EP_MedicIntro
npcInitDataEnd:

npcPostInitData:dc.b >EP_JROfficerPostIntro, >EP_PilotPostIntro, >EP_SROfficerPostIntro, >EP_GruntPostIntro, >EP_MedicPostIntro
                dc.b <EP_JROfficerPostIntro, <EP_PilotPostIntro, <EP_SROfficerPostIntro, <EP_GruntPostIntro, <EP_MedicPostIntro
npcPostInitDataEnd:

npcNewPosData:  if TEST_ENDING = 2
                dc.b ACT_JROFFICER_NOARMOR,ACT_JROFFICER_TRAPPED,LEVEL_DERELICT,$07,9,5
                else
                dc.b ACT_JROFFICER_NOARMOR,ACT_JROFFICER,LEVEL_SHIP,1,10,8
                endif
                dc.b ACT_PILOT_SITTING,ACT_PILOT,LEVEL_SHIP,3,12,8
                if TEST_ENDING = 2
                dc.b ACT_GRUNT_NOARMOR,ACT_GRUNT_NOARMOR,LEVEL_SHIP,1,4,8
                else
                dc.b ACT_GRUNT_NOARMOR,ACT_GRUNT,LEVEL_SHIP,1,4,8
                endif
                dc.b ACT_MEDIC,ACT_MEDIC,LEVEL_SHIP,1,24,8
                if TEST_ENDING = 2
                dc.b ACT_SROFFICER,ACT_SROFFICER,LEVEL_SHIP,1,28,6
                else
                dc.b ACT_SROFFICER,ACT_SROFFICER_WOUNDED,LEVEL_SHIP,1,28,6
                endif
                dc.b $ff

level3ActIDData:dc.b $00,$04,$0d,$13

globalActorData:include bg/worldglobalact.s

suitFlashTbl:   dc.b 11,14,15,14

IntroText1:     dc.b "YEAR 2218.",0
                     ;0123456789012345678901234567890123456789
                dc.b "AS HUMANITY IS FORCED TO EXPAND BEYOND",0
                dc.b "EARTH, THEY COME INTO CONTACT WITH A",0
                dc.b "HOSTILE MACHINE INTELLIGENCE BORN FROM",0
                dc.b "THEIR OWN CREATIONS. BY INITIALLY USING",0
                dc.b "MILITARY SHIPMENTS THOUGHT TO BE LOST,",0
                dc.b "IT HAS MINED OTHER PLANETS FOR RESOURCES",0
                dc.b "AND BUILT A VAST OFFENSIVE FLEET. NOW",0
                dc.b "MANKIND IS STRANDED IN A DESPERATE WAR,",0
                dc.b "WITH SAFETY NOWHERE TO BE FOUND.",0,0

IntroText2:          ;0123456789012345678901234567890123456789
                dc.b "UNITED MILITARY PATROL SHIP ",34,"SCOURGE",34,0
                dc.b "LED BY COMMANDER ARCHER HESS PICKS UP AN",0
                dc.b "UNUSUAL TRANSMISSION SENT FROM A BARREN",0
                dc.b "PLANET - ONES & ZEROES FORMING AN OMEGA",0
                dc.b "SYMBOL. THOUGH POSSIBLY A TRAP, THE SHIP",0
                dc.b "IS CLEARED TO INVESTIGATE. ITS CREW IS",0
                dc.b "EQUIPPED WITH SELF-RECHARGING ",34,"RANGER",34,0
                dc.b "ARMOR SUITS, DESIGNED FOR COMBAT AGAINST",0
                dc.b "OVERWHELMING ENEMIES IN ANY ENVIRONMENT.",0,0

                     ;01234567890123456789012345678901234567
PilotIntroText: if STARTPOS_CHEAT = 0
                dc.b "JAY: A HUGE STRUCTURE DOWN THERE.",0
                dc.b "MACHINES CERTAINLY. WILL BEGIN DESCENT",0
                dc.b "NOW - JUST NEED TO STAY THE HELL OUT",0
                dc.b "OF THEIR RANGE.",0,0
                endif

JROfficerIntroText:
                     ;01234567890123456789012345678901234567
                dc.b "KARA: BETTER GET SUITED UP. THE RIDE'S",0
                dc.b "ABOUT TO GET BUMPY.",0,0

                     ;01234567890123456789012345678901234567
GruntIntroText: dc.b "LEO: ABOUT TIME WE TAKE THE FIGHT TO",0
                dc.b "THEM. REMEMBER - IT'S SHOOT OR DIE!",0,0

SROfficerIntroText:
                     ;01234567890123456789012345678901234567
                dc.b "ARCHER: FEEL THAT? JAY'S GOING IN HARD",0
                dc.b "AND FAST. MAN VERSUS MACHINE. IT'S",0
                dc.b "ALMOST LIKE HE'S BOTH.",0,0

GruntIntro2Text:
                     ;01234567890123456789012345678901234567
                dc.b "LEO: YOU GO AHEAD. I NEED TO HAVE A",0
                dc.b "FEW WORDS ABOUT MY LAST.. EVALUATION.",0,0

MedicIntroText:      ;0123456789012345678901234
                dc.b "DIANE: RIGHT. HOPE YOU DON'T GET TO",0
                dc.b "KNOW THIS SIDE OF THE ARMORY AS MUCH.",0,0

SROfficerSuitText:   ;01234567890123456789012345678901234567
                dc.b "ARCHER: SUIT SYSTEMS COMING ONLINE.",0
                dc.b "TOLD THEM IT SHOULD BE FASTER -",0,0

IntroText3:     ;0123456789012345678901234567890123456789
                dc.b "DISABLED BY HEAVY FIRE FROM THE MACHINE",0
                dc.b "CITY, THE PATROL SHIP CRASH-LANDS ON THE",0
                dc.b "PLANET SURFACE. AS THE ONLY RANGER WITH",0
                dc.b "A POWERED-UP SUIT AT THE MOMENT, IT'S",0
                dc.b "UP TO YOU TO TAKE POINT AND CONTINUE THE",0
                dc.b "MISSION - TO INVESTIGATE THE CITY AND",0
                dc.b "THE MYSTERY TRANSMISSION. CHANCES OF",0
                dc.b "ESCAPING THE PLANET APPEAR SLIM.",0,0

JROfficerRadioText:
                     ;01234567890123456789012345678901234567
                dc.b "KARA: IT'S ME IN CHARGE NOW. TRY TO",0
                dc.b "MAKE YOUR WAY INSIDE, WE'LL FOLLOW AS",0
                dc.b "SOON AS POSSIBLE. YOUR FEED IS COMING",0
                dc.b "THROUGH CLEAR. GOOD LUCK.",0,0

                rend

scriptEnd: