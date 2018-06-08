ITEM_SMG        = 0
ITEM_BOUNCE     = 1
ITEM_LASER      = 2
ITEM_FLAMETHROWER = 3
ITEM_GRENADE    = 4
ITEM_MISSILE    = 5
ITEM_ARCGUN     = 6
ITEM_HEAVYPLASMA = 7
ITEM_HEALTH     = 8
ITEM_FUEL       = 9
ITEM_PARTS      = 10
ITEM_PARTS2     = 11
ITEM_PARTS3     = 12
ITEM_PARTS4     = 13
ITEM_ALPHAPASS  = 14
ITEM_BETAPASS   = 15
ITEM_GAMMAPASS  = 16
ITEM_DELTAPASS  = 17
ITEM_EPSILONPASS = 18
ITEM_OMEGAPASS  = 19

ITEM_FLICKER_DELAY  = 20

        ; Item update routine
        ;
        ; Parameters: X actor index
        ; Returns: -
        ; Modifies: A,Y

MoveItem:       lda actMB,x
                and #MB_HITWALL|MB_LANDED
                beq MoveItem_NoHitWall
                jsr StopXSpeed
MoveItem_NoHitWall:
                jsr FallingMotionCommon         ;Move & check collisions
                jsr UpdateInWater
MoveItem_Done:  ldy actFd,x
                lda actCtrl+ACTI_PLAYER
                sta actFd,x
                lda actF1+ACTI_PLAYER
                cmp #FR_DUCK                    ;Pickup if player is starting to duck
                bne MI_NoPickup
                tya                             ;and joystick down released in the meanwhile
                and #JOY_DOWN
                bne MI_NoPickup
                lda actCtrl+ACTI_PLAYER
                and #JOY_DOWN|JOY_FIRE
                cmp #JOY_DOWN
                bne MI_NoPickup
                jsr CheckPlayerCollision
                bcc MI_NoPickup
                jsr TryPickup                   ;Does not return if picked up
MI_NoPickup:    lda actOrg,x                    ;If item is not persisted, vanish after time expired
                bpl FlashActor
                jsr FlashActor
                lda dialogueHi                  ;Do not expire items during dialogue
                bne MI_SkipItemExpire
                dec actTime,x
                beq MI_Remove
MI_SkipItemExpire:
                lda actTime,x
                cmp #ITEM_FLICKER_DELAY
                bcs MI_FlickerDone
                lda actFlash,x
                ora #COLOR_FLICKER
                skip2
FlashActor:     lda #$01
                sta actFlash,x
MI_FlickerDone: rts
MI_Remove:      jmp RemoveActor

        ; Object marker update routine (only remove if expired)
        ;
        ; Parameters: X actor index
        ; Returns: -
        ; Modifies: A,Y

MoveObjectMarker:
                inc actFd,x
                lda actFd,x
                jsr GetWeaponFlashColor
                sta actFlash,x
                dec actTime,x
                bmi MI_Remove
                rts

GetWeaponFlashColor:
                lsr
                lsr
                and #$03
                tay
                lda weaponSelectColorTbl,y
                rts

        ; Speech bubble update routine
        ;
        ; Parameters: X actor index
        ; Returns: -
        ; Modifies: A,Y

MoveSpeechBubble:
                lda dialoguePos                 ;Remove when dialogue ended
                bmi MI_Remove
                rts

        ; Attempt item pickup. To be called from item's move routine
        ;
        ; Parameters: X item actor index (must also be in actIndex)
        ; Returns: Item removed if picked up successfully, will not return to actor routine in that case
        ; Modifies: A,X,temp5-temp8,zpSrcLo/Hi

TryPickup:      lda #$ff                        ;Only pickup 1 item at a time
                beq TP_Fail2
                lda actOrg,x
                sta temp8
                lda actF1,x
                cmp #ITEM_ALPHAPASS
                bcs TP_Security
                cmp #ITEM_PARTS
                bcs TP_Parts
                cmp #ITEM_HEALTH
                bcc TP_Ammo
                beq TP_Health
TP_Fuel:        lda #MAX_FUEL
                jsr AddFuel
                bcc TP_Success
TP_Fail2:       jmp TP_Fail

TP_Security:    tax
                lda bitTbl-ITEM_ALPHAPASS,x
                ora security
                sta security
                bne TP_Success

TP_Parts:       tax
                lda partsPickupTbl-ITEM_PARTS,x
                asl temp8
                bcc TP_PartsInLevel
                lsr                             ;Enemy parts drop is 1/2 from placed
TP_PartsInLevel:jsr AddParts
                jmp TP_Success

TP_Health:      lda actHp+ACTI_PLAYER           ;Already full?
                cmp #HP_PLAYER
                beq TP_Fail
TP_HealthPickup:lda #HP_PLAYER/2                ;Fixed on all difficulties
                asl temp8
                bcc TP_HealthInLevel
                lda #HP_PLAYER/3                ;1/3 of health if dropped from enemy
TP_HealthInLevel:
                jsr AddHealth
                jmp TP_Success

TP_Ammo:        tay
                lda #MAX_AMMO*$10/3+1
                asl temp8
                bcc TP_AmmoInLevel
                bne TP_AmmoInLevel              ;Special case: $81-$ff dispenser, treat like level
TP_EnemyAmmoPickup:
                lda #MAX_AMMO*$10/6
TP_AmmoInLevel: jsr AddAmmo
                bcs TP_Fail
TP_Success:     ldx actIndex
                lda #$00
                sta TryPickup+1                 ;Do not pick up another item this frame
                sta actT,x
                lda actF1,x
                tay
                lda itemNameTblLo,y
                ldx itemNameTblHi,y
                jsr PrintPanelTextItemDur
                lda #SFX_PICKUP
                jsr QueueSfx
                pla                             ;Do not return to actor move routine
                pla
TP_Fail:        ldx actIndex
                rts
