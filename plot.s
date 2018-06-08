PLOT_NOSAVE     = 0
PLOT_DROIDBOSS  = 1
PLOT_BOMBBOSS   = 2
PLOT_FIGHTERBOSS = 3
PLOT_DISTILLERBOSS = 4
PLOT_SECURITYTOWER = 5
PLOT_UPGRADESTATIONMSG = 6
PLOT_TECHANALYZER = 7
PLOT_DISTILLATIONSMSG1 = 8
PLOT_DISTILLATIONSMSG2 = 9
PLOT_DISTILLERBOSSKILLED = 10
PLOT_VRCAPTURE = 11
PLOT_BOMBDEFUSED = 12
PLOT_BOMBRADIOMSG = 13
PLOT_UNDERSIDERADIOMSG = 14
PLOT_GRUNTRESCUED = 15

MAX_DIALOGUE_DIST = 6

        ; Get the value of a plotbit
        ;
        ; Parameters: A plotbit number
        ; Returns: A nonzero if set
        ; Modifies: A,Y

GetPlotBit:     jsr DecodeBit
                and plotBits,y
                rts

        ; Set a plotbit
        ;
        ; Parameters: A plotbit number
        ; Returns: -
        ; Modifies: A,Y

SetPlotBit:     jsr DecodeBit
                ora plotBits,y
                bne CPB_Store

        ; Clear a plotbit
        ;
        ; Parameters: A plotbit number
        ; Returns: -
        ; Modifies: A,Y

ClearPlotBit:   jsr DecodeBit
                eor #$ff
                and plotBits,y
CPB_Store:      sta plotBits,y
                rts

        ; NPC speak dialogue
        ;
        ; Parameters: zpSrcLo-Hi text pointer, actIndex actor index
        ; Returns: C=1 if successful and ended, C=0 if failed, X actIndex
        ; Modifies: A,Y,temp vars

NPCDialogue:    ldx actIndex
                lda dialogueHi
                bne NPCDialogue_Running
                lda actSX,x
                bne NPCDialogue_Fail            ;Wait until has come to a halt, as bubble can't move along
                ldy #ACTI_PLAYER
                jsr GetActorDistance
                lda temp6
                clc
                adc temp8
                cmp #MAX_DIALOGUE_DIST
                bcs NPCDialogue_Fail
                jsr UD_CopyDialoguePtr
                jsr GetBulletSpawnOffset        ;Misuse bullet spawn offset for the speech bubble offset
                lda #ACTI_FIRST                 ;Use any actor except objectmarker, since player won't be firing during dialogue
                ldy #ACTI_LAST-1
                jsr GetFreeActor
                bcc NPCDialogue_NoBubble
                lda #$00
                sta temp1
                sta temp2
                dec temp4
                lda #ACT_SPEECHBUBBLE
                jsr SpawnWithOffset
NPCDialogue_NoBubble:
                stx dialogueAct
UD_NextRow:     lda #$00
                sta dialoguePos                 ;"Fail" initially - text being printed now
NPCDialogue_Fail:
                clc
                rts

NPCDialogue_Running:
                cpx dialogueAct
                bne NPCDialogue_Fail
                lda dialoguePos
                bpl NPCDialogue_Fail
NPCDialogue_Finish:
                lda #$00
                sta dialogueHi
                sta panelTextDelay              ;If there was a right side message, it's lost now
                sta playerCtrl                  ;Stop ctrl override
                jsr DisableFire                 ;Prevent firing until fire released
                sec                             ;Finish dialogue successfully (C=1)

        ; Set to redraw panel fully and clear menu mode.
        ;
        ; Parameters: -
        ; Returns: -
        ; Modifies: A

SetRedrawPanelFull:
                lda #$ff
                sta menuMode
                sta panelUpdateFlags
                rts

        ; Update dialogue each frame
        ;
        ; Parameters: -
        ; Returns: -
        ; Modifies: A,X,Y,several temp regs

UpdateDialogue: ldy dialoguePos
                bmi UD_WaitScript               ;Everything printed, wait for script to finish
                beq UD_PrintNextLine
                jsr UD_RevealChar
UD_RevealChar:  lda panelScreen+PANELROW*40,y   ;Stop to the divider
                cmp #5
                beq UD_NoReveal
                lda #$01
                sta colors+PANELROW*40,y
                iny
                sty dialoguePos
UD_NoReveal:    jsr GetFireClick
                bcs UD_NextRow
UD_WaitScript:  rts
UD_Ended:       lda dialogueAct                 ;If actorless dialogue, return to game controls immediately
                bmi NPCDialogue_Finish
                dec dialoguePos
                rts
UD_PrintNextLine:
                lda dialogueLo
                sta zpSrcLo
                lda dialogueHi
                sta zpSrcHi
                jsr PrepareMenu                 ;Returns with Y=0 & A=1
                tax
                lda (zpSrcLo),y
                beq UD_Ended
                sty textColor                   ;Print black text initially, reveal char by char
                ldy #PANELROW
                jsr PrintText
                inc textColor                   ;Return to normal text color
                inc dialoguePos                 ;Start dialogue fade-in
UD_CopyDialoguePtr:
                lda #JOY_OVERRIDE               ;Stop player from moving
                sta playerCtrl
                lda zpSrcLo
                sta dialogueLo
                lda zpSrcHi
                sta dialogueHi
                rts
