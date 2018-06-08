FR_STAND        = 0
FR_WALK         = 1
FR_JUMP         = 9
FR_JETPACK      = 12
FR_DUCK         = 14
FR_ENTER        = 16
FR_CLIMB        = 17
FR_DIE          = 25
FR_ATTACK       = 28

WATER_XBRAKING = 2
WATER_YBRAKING = 2
WATER_MAX_XSPEED = 2*8

PLAYER_SIDESPEED = 4*8
PLAYER_WHEELSPEED = 6*8
PLAYER_JUMPSPEED = -6*8
PLAYER_HIGHJUMPSPEED = -6*8-2
PLAYER_BRAKEACCEL = 7
PLAYER_GROUNDACCEL = 6
PLAYER_WHEELACCEL = 8
PLAYER_AIRACCEL = 2
PLAYER_JETPACKACCEL = 10

PLAYER_GRAVITY  = 9
PLAYER_LONGJUMPGRAVITY = 4
PLAYER_HIGHJUMPGRAVITY = 3

MAX_FALLDISTANCE = 15

MAX_PARTS       = 999
MIN_FUEL        = 20
MAX_FUEL        = 255
MAX_AMMO        = 8

UPG_WHEEL       = 1
UPG_HIGHJUMP    = 2
UPG_JETPACK     = 4
UPG_WHEELFUEL   = 8
UPG_JETPACKFUEL = 16
UPG_WPNCONSUMPTION = 32
UPG_TECHANALYZER = 64
UPG_BIOANALYZER = 128

UPG2_HEALTH1    = 1
UPG2_HEALTH2    = 2
UPG2_REGEN1     = 4
UPG2_REGEN2     = 8
UPG2_WHEELDAMAGE = 16
UPG2_WPNDAMAGE1 = 32
UPG2_WPNDAMAGE2 = 64
UPG2_HEATSHIELD = 128

MAX_UPGRADES    = 15

SEC_ALPHA       = 1
SEC_BETA        = 2
SEC_GAMMA       = 4
SEC_DELTA       = 8
SEC_EPSILON     = 16
SEC_OMEGA       = 32

INIT_FUELRECHARGE_DELAY = 8
NORMAL_FUELRECHARGE_DELAY = 1

MAX_DOUBLECLICK_DELAY = 7
WEAPON_MENU_DELAY = 2
WEAPON_MENU_PAUSEDELAY = 48

MIN_HEALTH      = HP_PLAYER/3

DIFF_CASUAL     = 0
DIFF_EASY       = 1
DIFF_NORMAL     = 2
DIFF_HARD       = 3

BASE_HEALTHRECHARGE_DELAY = 10
DAMAGE_HEALTHRECHARGE_DELAY = 40

        ; Player control and movement routine
        ;
        ; Parameters: X actor index
        ; Returns: -
        ; Modifies: A,Y,temp1-temp8,loader temp vars

MP_EnterPause:  lda #KEY_RUNSTOP
                sta keyType
MP_ExitWeaponMenu:
                lda #$ff
                sta MP_DoubleClickDelay+1
                bne MP_IWMNotOver

MP_InWeaponMenu:ldy playerCtrl
                bmi MP_ExitWeaponMenu           ;If overriding controls, exit menu
                cpy #JOY_FIRE
                bcc MP_ExitWeaponMenu
                beq MP_CanEnterPause
                ora #$40                        ;If joystick moved while in doubleclick menu, do not enter pause
MP_CanEnterPause:
                adc #$00
                bpl MP_IWMNoWrap
                eor #$c0
MP_IWMNoWrap:   cmp #WEAPON_MENU_PAUSEDELAY
                beq MP_EnterPause
MP_IWMNotOver:  sta wpnMenuMode
                lda #REDRAW_WEAPONSELECT
                jsr SetPanelRedraw
                lda playerCtrl
                and #JOY_UP|JOY_DOWN
                jmp MP_SetMoveCtrl

MP_EnterWeaponMenu:
                lda #SFX_SELECT
                jsr QueueSfx
                lda #$00
                sta actCtrl+ACTI_PLAYER
                beq MP_IWMNotOver

MovePlayer:     lda actT+ACTI_PLAYER
                cmp #ACT_PLAYER_NOARMOR
                bne MP_HasArmor
                lda #2
                sta actAttackD+ACTI_PLAYER
                ldy actSY+ACTI_PLAYER           ;Reduce jump height without armor, prevent firing
                bpl MP_NoArmorJump
                inc actSY+ACTI_PLAYER
MP_NoArmorJump: jsr MP_HasArmor
                jmp AH_NoWeapon

MP_HasArmor:
MP_DoubleClickOption:
                lda #$00
                beq MP_NoDoubleClickMode
                lda wpnMenuMode
                bpl MP_InWeaponMenu
                inc MP_DoubleClickDelay+1
                bne MP_NoDelayWrap
                lda #$ff
                sta MP_DoubleClickDelay+1
MP_NoDelayWrap: lda playerCtrl                  ;Only consider pure fire presses (no other directions)
                cmp #JOY_FIRE
                bne MP_NoDoubleClickMode
                lda prevJoy
                and #JOY_FIRE
                bne MP_NoDoubleClickMode
MP_DoubleClickDelay:
                lda #$ff
                cmp #MAX_DOUBLECLICK_DELAY
                bcc MP_EnterWeaponMenu
MP_NoDoubleClick:
                lda #$00
                sta MP_DoubleClickDelay+1
MP_NoDoubleClickMode:
                lda playerCtrl
                and #$7f
                sta actCtrl+ACTI_PLAYER
                cmp #JOY_FIRE
                bcc MP_NewMoveCtrl
MP_SetMoveCtrl: and #$0f                        ;When fire held down, eliminate the opposite
                tay                             ;directions from the previous move control
                lda moveCtrlAndTbl,y
                ldy actF1+ACTI_PLAYER           ;Keep up+down unless jumping or climbing
                cpy #FR_CLIMB
                bcs MP_SMCRemoveUpDown
                cpy #FR_JETPACK
                bcs MP_SMCKeepUpDown
                cpy #FR_JUMP
                bcs MP_SMCRemoveUpDown
MP_SMCKeepUpDown:ora #JOY_UP|JOY_DOWN
MP_SMCRemoveUpDown:and actMoveCtrl+ACTI_PLAYER
MP_NewMoveCtrl: sta actMoveCtrl+ACTI_PLAYER
MP_SetWeapon:   ldy wpnIndex
                bne MP_WeaponOK
                jsr CheckHasAmmo
                bne MP_WeaponOK
                ldy #WPN_SMG_NOAMMO             ;Slow SMG (no ammo) as the special case
MP_WeaponOK:    sty actWpn+ACTI_PLAYER
                lda actF1+ACTI_PLAYER           ;Check object / lift operation
                bne MP_NoOperate                ;Must be standing and no fire / left / right
                lda actCtrl+ACTI_PLAYER
                beq MP_NoOperate
                cmp #JOY_LEFT
                bcs MP_NoOperate
MP_UsableObj:   ldy #$00
                bmi MP_NoUsableObj              ;Positive = ordinary levelobject
                cmp #JOY_DOWN
                bcs MP_NoOperate
                sty ULO_OperateObj+1
                lda #FR_ENTER
                jmp MH_AnimDone
MP_NoUsableObj: cpy #$80+MAX_COMPLEXACT         ;Standing at lift actor?
                bcs MP_NoOperate
                sta actMoveCtrl-$80,y           ;Set controls to it
                lda #$00
                sta actSX-$80,y                 ;Clear target Y-pos
                sta actMoveCtrl+ACTI_PLAYER     ;Clear player controls to prevent jump/duck
MP_NoOperate:

        ; Humanoid character move routine. Jumps to attack routine
        ;
        ; Parameters: X actor index
        ; Returns: -
        ; Modifies: A,Y,temp1-temp8,loader temp vars

MoveHuman:      lda actMoveCtrl,x               ;Current joystick controls
                sta temp2
                lda actF1,x                     ;Frame & $fe for duck/jetpack tests
                tay
                and #$fe
                sta temp3
                cpy #FR_CLIMB
                bcc MH_NoClimb
                cpy #FR_CLIMB+8
                bcc MH_IsClimbing
MH_DyingAnim:   lda #$00                        ;Make sure no movement when dead
                sta temp2
                lda actMB,x
                bpl MH_DeathInAir
MH_DeathGrounded:
                lda #FR_DIE+2
                sta actF1,x
                sta actF2,x
                lda actT,x                      ;Only player explodes/vanishes
                cmp #ACT_PLAYER
                bne MH_DeathNotPlayer
                ldy #EXPL_FF_7F
                jmp GenerateExplosionsAndFlicker
MH_DeathNotPlayer:
                rts
MH_DeathInAir:  lda #5
                ldy #FR_DIE+1
                jsr OneShotAnimation
MH_DeathAnimDone:
                jmp MH_Brake
MH_IsClimbing:  jmp MH_Climbing
MH_NoClimb:     txa                             ;Humanoid enemies don't jump or climb
                bne MH_NoNewJump
                lda temp3                       ;No grab / jump when flying
                cmp #FR_JETPACK
                beq MH_NoNewJump
                lda temp2                       ;Check jumping / climbing up
                lsr
                bcc MH_NoNewJump
                bne MH_NoInitClimbUp            ;Must be up only to climb / grab
                lda actCtrl,x                   ;And not if fire held
                and #JOY_FIRE
                bne MH_NoNewJump
                ldy actMB,x
                bmi MH_ClimbCheckOnGround
                lda #-2
                skip2
MH_ClimbCheckOnGround:
                lda #-3
                jsr GetBlockInfoOffset
                and #BI_CLIMB
                beq MH_NoInitClimbUp
                jmp MH_InitClimb
MH_NoInitClimbUp:
                lda actMB,x                     ;Check starting a jump
                bpl MH_NoNewJump
                lda actF1,x
                cmp #FR_DUCK+1
                beq MH_NoNewJump
                lda actPrevCtrl,x
                and #JOY_UP|JOY_FIRE
                bne MH_NoNewJump
MH_StartJump:   txa
                bne MH_StartNormalJump
                lda upgrade
                and #UPG_HIGHJUMP
                beq MH_StartNormalJump
                lda #PLAYER_HIGHJUMPSPEED
                skip2
MH_StartNormalJump:
                lda #PLAYER_JUMPSPEED
                sta actSY,x
                lda #1                          ;Initialize fall-counter with 1 so we
                sta actFall,x                   ;always get some ducking on landing
                lda #$00
                sta actMB,x
                lda #SFX_JUMP
                jsr QueueSfxNoMusicPlayerOnly
MH_NoNewJump:   ldy actF1,x
                lda temp2                       ;Check turning / X-acceleration / braking
                and #JOY_LEFT|JOY_RIGHT
                beq MH_Brake
                and #JOY_RIGHT
                bne MH_TurnRight
                lda #$80
MH_TurnRight:   pha
                eor actD,x
                bmi MH_NoWheel
                txa                             ;No wheel if not player
                bne MH_NoWheel
                lda upgrade
                and #UPG_WHEEL
                beq MH_NoWheel
                cpy #FR_DUCK+1                  ;Check wheel transform (down+left/right without turning
                bne MH_NoWheel                  ;while ducked)
                lda actCtrl,x
                and #JOY_FIRE
                bne MH_NoWheel
                lda temp2
                and #JOY_DOWN
                beq MH_NoWheel
                lda actPrevCtrl,x
                cmp #JOY_DOWN
                bne MH_NoWheel
                lda fuel                        ;Must have minimum fuel
                cmp #MIN_FUEL
                bcc MH_NoWheel
MH_WheelTransform:
                pla
                lda #ACT_PLAYERWHEEL
                sta actT,x
                lda #$00
                sta actFd,x
                lda #$03
                sta actF1,x
                lda #SFX_WHEELBEGIN
                jmp QueueSfx
MH_NoWheel:     pla
MH_DoTurn:      cpy #FR_DUCK                    ;Only turn & brake if ducked
                sta actD,x
                bcs MH_Brake2
                lda actD,x
                asl                             ;Direction to carry
                ldy #AL_MAXSPEED
                lda (actLo),y
                tay
                lda actMB,x
                bmi MH_UseGroundAccel
                lda #PLAYER_AIRACCEL
                skip2
MH_UseGroundAccel:
                lda #PLAYER_GROUNDACCEL
                jsr AccActorXNegOrPos
                jmp MH_HorizMoveDone
MH_Brake:       lda actMB,x                     ;Only brake when grounded
                bpl MH_HorizMoveDone
MH_Brake2:      lda #PLAYER_BRAKEACCEL
                jsr BrakeActorX
MH_HorizMoveDone:
                lda actInWater,x                ;Water braking before movement
                beq MH_NotInWater
                jsr DoWaterBraking
MH_NotInWater:  lda temp3
                cmp #FR_JETPACK
                beq MH_LongJump
                lda actSY,x                     ;Make jump longer when going up by holding up
                bpl MH_NoLongJump               ;or using jetpack
                lda temp2
                and #JOY_UP
                beq MH_NoLongJump
                txa
                bne MH_LongJump
                lda upgrade
                and #UPG_HIGHJUMP
                beq MH_LongJump
                lda #PLAYER_HIGHJUMPGRAVITY
                bne MH_JumpAccelOK
MH_LongJump:    lda #PLAYER_LONGJUMPGRAVITY
                skip2
MH_NoLongJump:  lda #PLAYER_GRAVITY
MH_JumpAccelOK: ldy #-2
                jsr MoveAndUpdateInWater        ;Actually move & check collisions
MH_NoHitWall:   lda actF1,x                     ;If death animation, continue it and don't animate
                cmp #FR_DIE                     ;jump/walk/run
                bcs MH_AnimDone2
                lda actMB,x
                and #MB_GROUNDED|MB_LANDED
                bne MH_OnGround

MH_InAir:       txa                             ;No jetpack if not player
                bne MH_NoJetpack
                lda upgrade
                and #UPG_JETPACK
                beq MH_NoJetpack
                lda temp2
                lsr
                bcc MH_NoJetpack
                lda fuel
                beq MH_NoJetpack
                ldy temp3
                cpy #FR_JETPACK
                beq MH_JetpackContinue
                cmp #MIN_FUEL                   ;Do not start jetpack if has recharged only a little fuel
                bcc MH_NoJetpack
                lda actCtrl,x                   ;Do not start jetpack when fire down
                and #JOY_FIRE
                bne MH_NoJetpack
                lda actSY,x                     ;Must be falling to start jetpack
                bmi MH_NoJetpack
                cmp #2*8+4
                bcc MH_NoJetpack
MH_JetpackStart:
MH_JetpackContinue:
                lda #UPG_JETPACKFUEL
                jsr DecreaseFuelUpgradeCommon
                lda #PLAYER_JETPACKACCEL
                ldy #2*8+PLAYER_LONGJUMPGRAVITY
                jsr AccActorYNeg
                lda actF1,x                    ;Jetpack flame animation
                cmp #FR_JETPACK
                bne MH_NoJetpackSound
                tay
                lda #SFX_JETPACK
                jsr QueueSfxNoMusic
                tya
MH_NoJetpackSound:
                and #$01
                eor #$01
                ora #FR_JETPACK
                jmp MH_AnimDone

MH_NoJetpack:   ldy #FR_JUMP
                lda actSY,x
                bpl MH_Falling
                jsr Negate8
                bne MH_JumpAnim
MH_Falling:     cmp #COMMON_MAX_YSPEED
                bne MH_JumpAnim
                inc actFall,x                   ;Increase fall counter when falling at max speed

MH_JumpAnim:    cmp #4*8
                bcs MH_JumpAnimDone
                iny
                cmp #2*8
                bcs MH_JumpAnimDone
                iny
                bne MH_JumpAnimDone
MH_JumpAnimDone:tya
MH_AnimDone2:   jmp MH_AnimDone

MH_OnGround:    lda actFall,x
                beq MH_NoForceDuck
                cmp #MAX_FALLDISTANCE            ;Clamp duck-time to a maximum
                bcc MH_NoMaxFallDistance
                lda #MAX_FALLDISTANCE-1
MH_NoMaxFallDistance:
                sbc #$02-1
                bcs MH_FallAnimNoWrap
                lda #$00
MH_FallAnimNoWrap:
                sta actFall,x
                lda actMB,x
                and #MB_LANDED
                beq MH_NoLandingSound
                jsr QueueFootstep
MH_NoLandingSound:
                jmp MH_Duck                     ;Forced ducking until the fall counter is zero
MH_NoForceDuck: txa                             ;Humanoid enemies don't climb
                bne MH_NoClimbDown
                lda temp2
                cmp #JOY_DOWN
                bne MH_NoClimbDown
                lda actF1,x                     ;Must not be fully ducked to allow climbing down
                cmp #FR_DUCK+1
                beq MH_NoClimbDown
                lda actCtrl,x                   ;No climbing if fire held
                and #JOY_FIRE
                bne MH_NoClimbDown
                jsr GetBlockInfo
                and #BI_CLIMB
                beq MH_NoClimbDown
                jmp MH_InitClimb
MH_NoClimbDown: lda temp2
                and #JOY_DOWN
                beq MH_NoDuck
MH_Duck:        lda actF1,x
                cmp #FR_DUCK
                bcs MH_DuckAnim
MH_StartDuck:   lda #$00
                sta actFd,x
                lda #FR_DUCK
                bne MH_AnimDone
MH_DuckAnim:    lda #1
                ldy #FR_DUCK+1
                jsr OneShotAnimation
                lda actF1,x
                bpl MH_AnimDone
MH_NoDuck:      lda actF1,x
                cmp #FR_DUCK
                bcc MH_StandOrWalk
                cmp #FR_ENTER                   ;Check for staying in the operate stance
                bne MH_NoEnterFrame
                lda actCtrl,x
                cmp actPrevCtrl,x
                beq MH_AnimDone3
                bne MH_StandAnim
MH_NoEnterFrame:
MH_DuckStandUpAnim:
                lda #-2
                jsr GetBlockInfoOffset
                and #BI_WALL
                bne MH_AnimDone3                ;Cannot stand up if wall above (exited wheel involuntarily)
                lda #1
                jsr AnimationDelay
                bcc MH_AnimDone3
                lda actF1,x
                sbc #$01
                cmp #FR_DUCK
                bcc MH_StandAnim
                bcs MH_AnimDone
MH_StandOrWalk: lda temp2
                and #JOY_LEFT|JOY_RIGHT
                beq MH_AnimDone                 ;0 = walk frame
                lda actSX,x
                beq MH_StandAnim
                asl
                bcc MH_WalkAnimSpeedPos
                eor #$ff
                adc #$00
MH_WalkAnimSpeedPos:
                adc #$40
MH_WalkSpeedZero:
                adc actFd,x
                sta actFd,x
                lda actF1,x
                bcc MH_NoWalkSound
                pha
                and #$03
                bne MH_NoWalkSound2
                jsr QueueFootstep
                sec
MH_NoWalkSound2:pla
MH_NoWalkSound: adc #$00
                cmp #FR_WALK+8
                bcc MH_NoWalkAnimWrap
                lda #FR_WALK
MH_NoWalkAnimWrap:
MH_AnimDone:    sta actF1,x
MH_AnimDone4:   tay
                lda humanSizeModTbl,y           ;Set size up based on current frame
                ldy #AL_SIZEUP
                clc
                adc (actLo),y
                sta actSizeU,x
MH_AnimDone3:   jmp AttackHuman
MH_StandAnim:   lda #FR_STAND
                beq MH_AnimDone

MH_InitClimb:   lda #$40
                sta actXL,x
                asl
                sta actFd,x
                lda actYL,x
                and #$40
                sta actYL,x
                jsr StopXSpeed
                sta actFall,x
                sta actSY,x
                jsr NoInterpolation
                lda #FR_CLIMB
                bne MH_AnimDone

MH_Climbing:    jsr GetBlockInfo
                sta temp1
                lda temp2
                lsr
                bcc MH_NoClimbUp
                jmp MH_ClimbUp
MH_NoClimbUp:   lsr
                bcs MH_ClimbDown
                lda temp2                       ;Exit ladder?
                and #JOY_LEFT|JOY_RIGHT
                beq MH_ClimbDone
                lsr                             ;Left bit to direction
                lsr
                lsr
                ror
                sta actD,x
                lda actYL,x
                asl
                bmi MH_ClimbExitBelow
                lda temp1                       ;Check ground bit at actor
                lsr
                bcs MH_ClimbExit
                bcc MH_ClimbDone
MH_ClimbExitBelow:
                lda #1                          ;Check ground bit below
                jsr GetBlockInfoOffset
                lsr
                bcc MH_ClimbDone
                inc actYH,x
MH_ClimbExit:   lda #$00
                sta actYL,x
                lda #MB_GROUNDED
                sta actMB,x
                jsr NoInterpolation
                jmp MH_StandAnim

MH_ClimbDown:   lda temp1
                and #BI_CLIMB
                beq MH_ClimbDone
                ldy #2*8
                bne MH_ClimbCommon
MH_ClimbDone:   jmp AttackHuman

MH_ClimbUp:     lda temp2                       ;Check for exiting the ladder
                cmp actPrevCtrl,x               ;by jumping
                beq MH_ClimbUpNoJump
                and #JOY_LEFT|JOY_RIGHT
                beq MH_ClimbUpNoJump
                lda temp2
                cmp #JOY_RIGHT
                lda #2*8
                bcs MH_ClimbExitRight
                jsr Negate8
MH_ClimbExitRight:
                sta actSX,x
                sta actD,x
                jmp MH_StartJump
MH_ClimbUpNoJump:
                lda actYL,x
                bne MH_ClimbUpOk
                lda #-3
                jsr GetBlockInfoOffset
                and #BI_CLIMB
                beq MH_ClimbDone
MH_ClimbUpOk:   ldy #-2*8
MH_ClimbCommon: lda actFd,x
                clc
                adc #$c0
                sta actFd,x
                bcc MH_ClimbDone
                lda #$01                        ;Add 1 or 7 depending on climbing dir
                cpy #$80
                bcc MH_ClimbAnimDown
                lda #$06                        ;C=1, add one less
MH_ClimbAnimDown:
                adc actF1,x
                sbc #FR_CLIMB-1                 ;Keep within climb frame range
                and #$07
                adc #FR_CLIMB-1
                sta actF1,x
                and #$03
                bne MH_NoClimbSound
                jsr QueueFootstep
MH_NoClimbSound:tya
                jsr MoveActorY
                jsr NoInterpolation
                lda actF1,x
                jmp MH_AnimDone4

        ; Player wheel form control and movement routine
        ;
        ; Parameters: X actor index
        ; Returns: -
        ; Modifies: A,Y,temp1-temp8,loader temp vars

MovePlayerWheel:lda playerCtrl                  ;If controls being overridden, exit wheel to standing mode
                bmi MW_ExitWheel
                sta actCtrl+ACTI_PLAYER
                sta actMoveCtrl+ACTI_PLAYER
MoveWheel:      ldy #AL_SIZEUP                  ;Reset collision size for wheel
                lda (actLo),y
                sta actSizeU,x
                lda upgrade2                    ;Check if should apply damage to enemies
                and #UPG2_WHEELDAMAGE
                beq MW_NoDamage
                jsr CheckBulletCollision
                bcc MW_NoDamage
                lda #DMG_WHEEL+$80
                jsr AddStrobedDamage
MW_NoDamage:    lda actInWater,x                ;Water braking. Do before acceleration to allow wheel to move slightly faster
                beq MW_NotInWater               ;than walking in water
                jsr DoWaterBraking
MW_NotInWater:  lda fuel                        ;Forced exit when no more fuel
                beq MW_ExitWheel
                lda actMB,x
                bpl MW_NotOnGround
                lda actCtrl,x                   ;No exit if fire held
                and #JOY_FIRE
                beq MW_TestExit
MW_TestExit:    lda actMoveCtrl,x
                lsr
                bcc MW_NoExit
                lda #-2
                jsr GetBlockInfoOffset          ;Cannot exit at low ceiling
                and #BI_WALL                    ;If fuel runs out, will stay ducked
                bne MW_NoExit
MW_ExitWheel:   lda #ACT_PLAYER
                sta actT,x
                lda actSX,x                     ;Halve X-speed, but do not stop entirely
                jsr Asr8
                sta actSX,x
                lda #FR_DUCK+1
                sta actF1,x
                sta actF2,x
                lda #SFX_WHEELEND
                jmp QueueSfx
MW_NotPlayer:
MW_NoExit:      lda actMoveCtrl,x
                and #JOY_LEFT|JOY_RIGHT
                beq MW_NoDirChange
                and #JOY_RIGHT
                bne MW_TurnRight
                lda #$80
MW_TurnRight:   sta actD,x
MW_NoDirChange: lda actD,x
                asl                             ;Direction to carry, accelerate always to facing dir (if on ground)
                lda #PLAYER_WHEELACCEL
                ldy #PLAYER_WHEELSPEED
                jsr AccActorXNegOrPos
                lda parts                       ;If run out of parts, cannot fire mines
                ora parts+1
                bne MW_AccelDone
MW_NotOnGround: lda #2                          ;Cannot fire mines if airborne (set delay)
                sta actAttackD,x
MW_AccelDone:   lda #FR_ATTACK+1                ;Act as if weapon is already drawn to eliminate firing delay
                sta actF2,x
                lda #WPN_WHEELMINE
                sta actWpn,x
                jsr AttackHuman
                lda #PLAYER_GRAVITY
                ldy #0
                jsr MoveAndUpdateInWater
                ldy #2
                lda actF1,x
                cmp #3
                bcc MW_NoInitAnimation
                lsr
MW_NoInitAnimation:
                lda #0
                jsr LoopingAnimation
                bcs MW_SkipFuel                 ;Skip fuel consumption whenever frame wraps (each third frame)
                txa
                bne MW_SkipFuelNotPlayer        ;NPC wheel: skip fuel
                lda #UPG_WHEELFUEL
                jmp DecreaseFuelUpgradeCommon
MW_SkipFuel:    lda #SFX_JUMP
                jmp QueueSfxNoMusic
MW_SkipFuelNotPlayer:
                rts

        ; Player death routine
        ;
        ; Parameters: X actor index
        ; Returns: -
        ; Modifies: A,Y

PlayerDeath:    jsr ApplyDeathImpulse
                lda #ACT_PLAYER                 ;If was in wheel form, move back to bipedal
                sta actT,x
HumanDeath:     lda #-7*8
                sta actSY,x
                lda #50
                sta actTime,x
HumanoidDeathCommon:
                lda #FR_DIE
                sta actF1,x
                sta actF2,x
                lda #$00
                sta actFd,x
                sta actMB,x                     ;Reset grounded state
                lda #SFX_DEATH
                jmp QueueSfx

        ; Decrease fuel, one less each second time if has upgrade
        ;
        ; Parameters: A upgrade bit to check, Y amount to subtract
        ; Returns: -
        ; Modifies: A,temp8

DecreaseFuelUpgradeCommon:
                ldy #2                          ;Consumption for both wheel & jetpack
DecreaseFuelUpgrade:
                and upgrade
                beq DFU_NoUpgrade
                inc DFU_Strobe+1
DFU_Strobe:     lda #$00
                lsr
                bcc DFU_NoUpgrade
                dey
DFU_NoUpgrade:  tya

        ; Decrease fuel
        ;
        ; Parameters: A amount to subtract
        ; Returns: -
        ; Modifies: A,temp8

DecreaseFuel:   if FUEL_CHEAT > 0
                rts
                endif
                sta temp8
                lda #INIT_FUELRECHARGE_DELAY
                sta fuelRechargeDelay
                lda fuel
                sec
                sbc temp8
                bcs DF_NotOver
                lda #$00
DF_NotOver:     sta fuel
DP_NotEnough:   rts

        ; Decrease parts
        ;
        ; Parameters: A amount
        ; Returns: C=1 if successful
        ; Modifies: A,Y,temp8

DecreaseParts:  sta temp8
                lda parts
                sec
                sbc temp8
                bcs DP_NotOver
                ldy parts+1
                beq DP_NotEnough
                dec parts+1
                sec
DP_NotOver:     sta parts
                jmp SetPartsRedraw

        ; Decrease ammo
        ;
        ; Parameters: Y weapon index (0-7), A how much to decrease
        ; Returns: A=0 if out of ammo, nonzero otherwise
        ; Modifies: A,temp8

DecreaseAmmo:   sec
                sta temp8
                lda ammoLo,y
                sbc temp8
                sta ammoLo,y
                lda ammoHi,y
                sbc #$00
                bcs DA_NotOver
                lda #$00
                sta ammoLo,y
DA_NotOver:     sta ammoHi,y

        ; Check whether has ammo
        ;
        ; Parameters: Y weapon index (0-7)
        ; Returns: A=0 if out of ammo, nonzero otherwise
        ; Modifies: A

CheckHasAmmo:   lda ammoLo,y
                ora ammoHi,y
AA_Full:        rts

        ; Add ammo to weapon
        ;
        ; Parameters: Y weapon index (0-7), A how much to add/4
        ; Returns: C=1 was already full, C=0 added
        ; Modifies: A,X,temp7-temp8

AddAmmo:        sta temp7
                lda #$00
                ldx #$04
AA_ShiftLoop:   asl temp7
                rol
                dex
                bne AA_ShiftLoop
                sta temp8
                lda ammoHi,y
                cmp #MAX_AMMO
                bcs AA_Full
                lda ammoLo,y
                adc temp7
                sta ammoLo,y
                lda ammoHi,y
                adc temp8
                cmp #MAX_AMMO
                bcc AA_NotOver
                lda #$00
                sta ammoLo,y
                lda #MAX_AMMO
                clc
AA_NotOver:     sta ammoHi,y
                lda weapons                     ;Do full weapon redraw to update ammo/no ammo color
                ora bitTbl,y
                sta weapons
                lda #REDRAW_WEAPONS
                bne SetPanelRedraw

        ; Calculate score from destruction of enemy
        ;
        ; Parameters: X actor index, actLo-Hi Actor logic structure
        ; Returns: -
        ; Modifies: A,Y

AddDestroyScore:lda #$00
                ldy actWpn,x
                bmi ADS_NoWeaponScore
                lda wpnScoreTbl,y
ADS_NoWeaponScore:
                ldy #AL_INITIALHP
                adc (actLo),y
                and #$fe
                tay
                cpy #MAX_SCORE_INDEX
                bcc ADS_ScoreIndexOK
                ldy #MAX_SCORE_INDEX
ADS_ScoreIndexOK:

        ; Add score
        ;
        ; Parameters: Y score table index
        ; Returns: -
        ; Modifies: A

AddScore:       lda score
                clc
                adc scoreTbl,y
                sta score
                lda score+1
                adc scoreTbl+1,y
                sta score+1
                bcc AS_Done
                inc score+2
AS_Done:        lda #REDRAW_SCORE
SetPanelRedraw: ora panelUpdateFlags
                sta panelUpdateFlags
SW_SameWeapon:  rts

        ; Switch weapon
        ;
        ; Parameters: A new weapon (0-7)
        ; Returns: -
        ; Modifies: A

SelectWeapon:   cmp wpnIndex
                beq SW_SameWeapon
                sta wpnIndex
                lda #SFX_SELECT
                sta actAttackD+ACTI_PLAYER
                jsr QueueSfx
                lda #REDRAW_WEAPONSELECT
                bne SetPanelRedraw

        ; Add parts, clamp to maximum
        ;
        ; Parameters: A amount to add
        ; Returns: -
        ; Modifies: A,Y

AddParts:       ldy parts+1
                clc
                adc parts
                bcc AP_NoCarry
                iny
AP_NoCarry:     cpy #>MAX_PARTS
                bcc AP_NotOver
                bne AP_Over
                cmp #<MAX_PARTS
                bcc AP_NotOver
AP_Over:        lda #<MAX_PARTS
                ldy #>MAX_PARTS
AP_NotOver:     sta parts
                sty parts+1
SetPartsRedraw: lda #REDRAW_PARTS
                bne SetPanelRedraw

        ; Add fuel. Does nothing if player doesn't have wheel/jetpack yet
        ;
        ; Parameters: A amount to add
        ; Returns: C=1 already full or no upgrades yet, C=0 added
        ; Modifies: A,temp8

AddFuel:        sta temp8
                lda upgrade
                and #UPG_WHEEL|UPG_JETPACK
                beq AF_NoUpgrades
                lda fuel
                cmp #MAX_FUEL
                bcs AF_AtMax
                adc temp8
                bcc AF_NoClamp
                lda #MAX_FUEL
AF_NoClamp:     sta fuel
                clc
                rts
AF_NoUpgrades:  sec
AF_AtMax:       rts

        ; Add health, clamp to maximum, set regen timer
        ;
        ; Parameters: A amount to add
        ; Returns: -
        ; Modifies: A,X,Y,temp7-temp8

AddHealth:      clc
                adc actHp+ACTI_PLAYER
                cmp #HP_PLAYER
                bcc AH_NotOver
                lda #HP_PLAYER
AH_NotOver:     sta actHp+ACTI_PLAYER
SetBaseHealthRechargeDelay:
                lda #BASE_HEALTHRECHARGE_DELAY

        ; Calculate and reset health recharge timer
        ;
        ; Parameters: A base delay value to add
        ; Returns: -
        ; Modifies: A,X,Y,loader temp vars

SetHealthRechargeDelay:
                sta SHR_Base+1
                ldx #zpSrcLo
                lda actHp+ACTI_PLAYER
                lsr
                tay
                jsr MulU
                lda zpSrcLo
                lsr zpSrcHi
                ror
                lsr zpSrcHi
                ror
                clc
SHR_Base:       adc #$00
SHR_Mod:        ldy #8
                jsr ModifyDamage
                sta healthRechargeDelay
                rts

        ; Save player state
        ;
        ; Parameters: -
        ; Returns: -
        ; Modifies: A,X,Y,vars

SaveState:      jsr StoreLevelBits
                lda #<playerStateStart
                sta zpSrcLo
                lda #>playerStateStart
                sta zpSrcHi
                lda #<saveState
                ldx #>saveState
                jsr CopySaveMemory
                lda actXH+ACTI_PLAYER
                sta saveXH
                lda actYL+ACTI_PLAYER
                sta saveYL
                lda actYH+ACTI_PLAYER
                sta saveYH
                lda actT+ACTI_PLAYER
                sta saveT
                lda actD+ACTI_PLAYER
                sta saveD
                lda actHp+ACTI_PLAYER           ;Ensure minimum health after checkpoint restart
                cmp #MIN_HEALTH
                bcs SS_HealthOK
                lda #MIN_HEALTH
SS_HealthOK:    sta saveHp
                lda worldX
                sta saveWorldX
                lda worldY
                sta saveWorldY
                lda levelNum
                sta saveLevel
                rts

        ; Restore player state
        ;
        ; Parameters: -
        ; Returns: -
        ; Modifies: A,X,Y,vars

RestartAfterDeath:
                ldx #$03
RAD_CopyTime:   lda time,x                      ;When restarting after death, do not lose gametime
                sta time-playerStateStart+saveState,x
                dex
                bpl RAD_CopyTime
RestoreState:   lda #<saveState
                sta zpSrcLo
                lda #>saveState
                sta zpSrcHi
                lda #<playerStateStart
                ldx #>playerStateStart
                jsr CopySaveMemory
                lda saveT
                sta actT+ACTI_PLAYER
                lda saveD
                sta actD+ACTI_PLAYER
                ldy #ACTI_PLAYER
                jsr GFA_Found
                ldx #ACTI_PLAYER
                jsr InitActor
                lda #$40
                sta actXL+ACTI_PLAYER
                lda saveXH
                sta actXH+ACTI_PLAYER
                lda saveYL
                sta actYL+ACTI_PLAYER
                lda saveYH
                sta actYH+ACTI_PLAYER
                lda saveHp
                sta actHp+ACTI_PLAYER
                ldx #$00
                stx dialogueHi
                stx playerCtrl                  ;Disable any ctrl override
                stx fuelRechargeDelay
                stx DI_HealthInterval+1
                dex                             ;$ff
                stx wpnMenuMode
                stx levelNum                    ;In "no level" now - do not store actor/objectbits
                ldx saveWorldX
                ldy saveWorldY

        ; Change zone and center player, then apply upgrades
        ; Note: do not JSR from scripts, only JMP, as actor update before redraw
        ; could cause code relocation
        ;
        ; Parameters: X,Y new world pos
        ; Returns: -
        ; Modifies: A,X,Y,vars

ChangeZoneAndCenter:
                jsr ChangeZone
                jsr SetRedrawPanelFull          ;Request full panel update
                jsr ApplyRangerColorAndUpgrades
                jmp CenterPlayer

        ; Apply ranger suit color from player appearance, difficulty & upgrades
        ;
        ; Parameters: -
        ; Returns: -
        ; Modifies: A,X,Y,vars

ApplyRangerColorAndUpgrades:
                lda rangerColor
                ldy actT                        ;If player is without armor, use also the upper part override
                cpy #ACT_PLAYER_NOARMOR
                beq RS_UseFullColorOverride
                and #$0f
RS_UseFullColorOverride:
                sta actFlash+ACTI_PLAYER
                lda rangerNoArmorBaseFrame
                sta plrNoArmorUpperBaseFrame

        ; Apply difficulty and upgrade bonuses
        ;
        ; Parameters: -
        ; Returns: -
        ; Modifies: A,X,Y,vars

ApplyDifficulty:
AD_Difficulty:  ldy #$00
                lda regenDiffTbl,y
                sta temp1
                lda damageDiffTbl,y
                sta temp2
                lda enemyAmmoPickupDiffTbl,y         ;Enemy ammo pickup depends on difficulty
                sta TP_EnemyAmmoPickup+1
                lda upgrade2
                lsr
                lsr
                pha
                and #$03
                tax
                lda temp1
                ldy healthUpgradeTbl,x
                jsr ModifyDamage
                sta SHR_Mod+1
                pla
                lsr
                lsr
                lsr
                and #$03
                tay
                lda wpnDamageUpgradeTbl,y
                sta AH_PlayerBulletDamageMod+1
                lda upgrade2
                and #$03
                tax
                lda temp2
                ldy healthUpgradeTbl,x
                jsr ModifyDamage
                tay
                sty plrDmgModify
                dey
                sty wheelDmgModify              ;Wheel damage multiplier always 1 step less
                jmp SetBaseHealthRechargeDelay
