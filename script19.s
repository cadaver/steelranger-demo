                org $0000

                include macros.s
                include memory.s
                include mainsym.s

        ; Note! Code must be unambiguous! Relocated code cannot have skip1/skip2 -macros!

                dc.w scriptEnd-scriptStart  ;Chunk data size
                dc.b 14                     ;Number of objects

scriptStart:
                rorg scriptCodeRelocStart   ;Initial relocation address when loaded

                dc.w JROfficerPostIntro         ;$1300
                dc.w PilotPostIntro             ;$1301
                dc.w MedicPostIntro             ;$1302
                dc.w GruntPostIntro             ;$1303
                dc.w SROfficerPostIntro         ;$1304
                dc.w PostIntroIdleCommon        ;$1305
                dc.w GruntIdle                  ;$1306
                dc.w MedicWaitAnalyzer          ;$1307
                dc.w JROfficerPostIntroText     ;$1308
                dc.w PilotPostIntroText         ;$1309
                dc.w MedicPostIntroText         ;$130a
                dc.w GruntPostIntroText         ;$130b
                dc.w MedicTechAnalyzerText      ;$130c
                dc.w ADSROfficerWounded         ;$130d

JROfficerPostIntro:
                jsr PostIntroIdleCommon
                lda #<EP_JROfficerPostIntroText
                jsr SpeakText
                bcc JROfficerPostIntroWait
                lda #<EP_PostIntroIdleCommon
                sta npcScriptEP+NPC_JROFFICER
JROfficerPostIntroWait:
                rts

PilotPostIntro: jsr PostIntroIdleCommon
                lda #<EP_PilotPostIntroText
                jsr SpeakText
                bcc PilotPostIntroWait
PilotSetIdle:   lda #<EP_PostIntroIdleCommon
                sta npcScriptEP+NPC_PILOT
PilotPostIntroWait:
                rts

MedicPostIntro: jsr PostIntroIdleCommon
                lda upgrade
                and #UPG_TECHANALYZER
                bne MedicHasAnalyzer
                lda #<EP_MedicPostIntroText
                jsr SpeakText
                bcc MedicPostIntroWait
                lda #<EP_MedicWaitAnalyzer
                sta npcScriptEP+NPC_MEDIC
MedicPostIntroWait:
                rts

GruntPostIntro: jsr GruntIdle
                lda #<EP_GruntPostIntroText
                jsr SpeakText
                bcc GruntPostIntroWait
                lda #<EP_GruntIdle
                sta npcScriptEP+NPC_GRUNT
GruntPostIntroWait:
                rts

SROfficerPostIntro:
                lda #$58                        ;Just adjust Y-fineposition
                sta actYL,x
                rts

PostIntroIdleCommon:
                ldy #ACTI_PLAYER
                jsr GetActorDistance
                lda temp5
                sta actD,x                      ;Face player
                rts

GruntIdle:      lda #JOY_DOWN
                sta actMoveCtrl,x
                rts

MedicWaitAnalyzer:
                jsr PostIntroIdleCommon
                lda upgrade
                and #UPG_TECHANALYZER
                beq MWA_Skip
MedicHasAnalyzer:
                lda #<EP_MedicTechAnalyzerText
                jsr SpeakText
                bcc MWA_Skip
                lda #SFX_PICKUP
                jsr QueueSfx
                lda upgrade
                and #$ff-UPG_TECHANALYZER
                sta upgrade
                lda #PLOT_TECHANALYZER
                jsr SetPlotBit
MWA_SetIdle:    lda #<EP_PostIntroIdleCommon
                sta npcScriptEP+NPC_MEDIC
MWA_Skip:       rts

SpeakText:      ldy #>EP_JROfficerPostIntroText + C_FIRSTSCRIPT
                jsr LoadChunkFile               ;Get text object address
                jmp NPCDialogue

                brk

ADSROfficerWounded:
                dc.b HUMANOID                   ;Number of sprites
                dc.b C_CREW                     ;Lower part spritefile number
                dc.b 39                         ;Lower part base spritenumber
                dc.b 0                          ;Lower part base index into the frametable
                dc.b 0                          ;Lower part left frame add
                dc.b C_CREW                     ;Upper part spritefile number
                dc.b 37                         ;Upper part base spritenumber
                dc.b 1                          ;Upper part base index into the frametable
                dc.b 0                          ;Upper part left frame add

JROfficerPostIntroText:
                     ;01234567890123456789012345678901234567
                dc.b "KARA: WE UNDERESTIMATED THEM. NOW JUST",0
                dc.b "HAVE TO MAKE BEST OF THE SITUATION,",0
                dc.b "EVEN IF WE WON'T BE RETURNING.",0,0

PilotPostIntroText:
                     ;01234567890123456789012345678901234567
                dc.b "JAY: STEALTH TRACKING. THEY LIKELY HAD",0
                dc.b "US IN THEIR SIGHTS THE ENTIRE TIME.",0
                dc.b "EVEN IF WE GOT THE ENGINES FIXED, THEY",0
                dc.b "COULD JUST SHOOT US DOWN AGAIN.",0,0

GruntPostIntroText:
                     ;01234567890123456789012345678901234567
                dc.b "LEO: SUIT'S POWERED, BARELY. ONLY ONE",0
                dc.b "WEAPON SYSTEM ACTIVE. WE'LL HAVE TO",0
                dc.b "SCAVENGE FROM THE MACHINES.",0,0

MedicPostIntroText:
                     ;01234567890123456789012345678901234567
                dc.b "DIANE: I'VE STABILIZED ARCHER, BUT IT",0
                dc.b "DOESN'T LOOK GOOD. INTERNAL INJURIES.",0
                dc.b "MOST OF THE MEDICAL GEAR IS SHOT, SO",0
                dc.b "CAN'T DO MUCH MORE.",0,0

MedicTechAnalyzerText:
                     ;01234567890123456789012345678901234567
                dc.b "DIANE: TECH ANALYZER? MIGHT BE EXACTLY",0
                dc.b "WHAT I NEED. MIND IF I BORROW IT?",0
                dc.b "YOU'LL GET IT BACK. EVENTUALLY.",0,0

SROfficerBombDefusedText:
                     ;01234567890123456789012345678901234567
                dc.b "ARCHER: WELL DONE. OMEGA CANNOT AVENGE",0
                dc.b "ITSELF ANY MORE. TOOK ITS TOLL ON KARA",0
                dc.b "THOUGH. AND THEY'RE STILL KEEPING HER.",0,0

PilotBombDefusedText:
                dc.b "JAY: FEELS BETTER TO KNOW THE PLANET",0
                dc.b "WON'T BE BLOWING UP UNDERNEATH US. BUT",0
                dc.b "ARE THE MACHINES HEADED HERE NOW?",0,0

                rend

scriptEnd: