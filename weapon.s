AIM_UP          = 0
AIM_DIAGONALUP  = 1
AIM_HORIZONTAL  = 2
AIM_DIAGONALDOWN = 3
AIM_DOWN        = 4
AIM_NUMDIRS     = 5
AIM_NONE        = $ff

AB_NONE         = 0
AB_UP           = 1
AB_DIAGONALUP   = 2
AB_HORIZONTAL   = 4
AB_DIAGONALDOWN = 8
AB_DOWN         = 16
AB_NOTOOCLOSECHECK = 128
AB_ALL          = $1f

WD_BITS         = 0
WD_ATTACKDELAY  = 1
WD_ENEMYATTACKDELAY = 2
WD_BULLETTYPE   = 3
WD_DAMAGE       = 4
WD_DURATION     = 5
WD_BULLETSPEED  = 6
WD_BULLETSPEEDDIAG = 7
WD_BULLETSPEEDNEG  = 8
WD_BULLETSPEEDNEGDIAG = 9
WD_SFX          = 10
WD_CONSUMPTION  = 11

WDB_NONE        = 0
WDB_BULLETDIRFRAME = 1
WDB_FLICKERBULLET = 2
WDB_PREMOVE     = 4
WDB_HALFPREMOVE = 8
WDB_DIRSIZEREDUCE = 16
WDB_GRAVITY     = 64
WDB_NOWALLCHECK = 128

NODMGMODIFY     = $80
PLAYERDAMAGE    = $80

GUN_PREPARE_DELAY = 2

GRAVITY_YSPD_MOD = -14

MAX_GLOBAL_ATTACK_DELAY = 4

WEAPON_SWITCH_DELAY = 5

        ; Humanoid actor attack routine
        ;
        ; Parameters: X actor index
        ; Returns: -
        ; Modifies: A,Y

AH_StopAttack:  lda actF2,x
                cmp #FR_ATTACK
                beq AH_StopOngoing
                bcc AH_NoWeapon
AH_SetPrepareFrame:
                lda #GUN_PREPARE_DELAY
                cpx #ACTI_PLAYER+1
                bcs AH_PrepareNotPlayer
AH_DoubleClickOption:
                adc #$00                        ;If using doubleclick to enter inventory, slightly longer gun prepare delay to prevent misfire
AH_PrepareNotPlayer:
                cmp actAttackD,x
                bcc AH_StopNotDone
                sta actAttackD,x
                lda #FR_ATTACK
                sta actF2,x
AH_StopNotDone: rts
AH_StopOngoing: lda actAttackD,x
                bne AH_StopNotDone
AH_NoWeapon:    lda actF1,x
                sta actF2,x
                rts

AttackHuman:    lda actCtrl,x                   ;Move this frame's controls to previous,
                sta actPrevCtrl,x               ;needed by e.g. jump checks
                lda actF1,x                     ;No attacks if dead
                cmp #FR_DIE
                bcs AH_NoWeapon
AttackCommon:   lda actAttackD,x
                beq AH_NoDelay
                dec actAttackD,x                ;Decrement delay
AH_NoDelay:     lda actCtrl,x
                cmp #JOY_FIRE
                bcc AH_StopAttack               ;StopAttack doesn't need weapon pointer
                and #JOY_LEFT|JOY_RIGHT         ;If left/right attack, turn actor
                beq AH_NoTurn
                lsr
                lsr
                lsr
                ror
                sta actD,x
AH_NoTurn:      lda actCtrl,x
                and #JOY_UP|JOY_DOWN|JOY_LEFT|JOY_RIGHT
                tay
                lda attackTbl,y
                bmi AH_StopAttack
                cpx #ACTI_PLAYER                ;No dir adjustment for enemies
                bne AH_FireDirOK
                ldy temp3                       ;Frame & $fe set by MoveHuman
                cmp #AIM_DOWN
                bne AH_NoDuckDir
                cpy #FR_DUCK
                bne AH_FireDirOK
                beq AH_SetHorizDir              ;When ducking, turn down to horizontal for easy duck-firing
AH_NoDuckDir:   cmp #AIM_UP
                bne AH_FireDirOK
                cpy #FR_JETPACK                 ;When flying, turn up likewise to horizontal
                bne AH_FireDirOK
AH_SetHorizDir: lda #AIM_HORIZONTAL
AH_FireDirOK:   sta temp2                       ;Final aim direction
                sta AH_FireDir+1
                clc
                adc #FR_ATTACK+1
                sta temp3                       ;Final attack frame
                lda actD,x
                bpl AH_AimRight
                lda temp2
                adc #AIM_NUMDIRS
                sta AH_FireDir+1
AH_AimRight:    lda actAttackD,x
                beq AH_CanFire
                lda actF2,x                     ;If gun already up, switch direction fast even if delay left
                cmp #FR_ATTACK+1
                bcc AH_CannotFire
                lda temp3
                sta actF2,x
AH_CannotFire:  rts

AH_CanFire:     lda actF2,x                     ;Gun already prepared?
                cmp #FR_ATTACK
                bcs AH_CanFire2                 ;Prepare first, to give time for player to debounce input
                jmp AH_SetPrepareFrame          ;to final desired direction
AH_CanFire2:    lda temp3
                sta actF2,x
                ldy actWpn,x                    ;Weapon pointer + bits only needed when actually firing
                jsr GetWeaponData

        ; Bullet spawn routine
        ;
        ; Parameters: X actor index, wpnLo/Hi, AH_FireDir
        ; Returns: -
        ; Modifies: A,Y

AH_SpawnBullet: jsr GetBulletSpawnOffset
                beq AH_IsPlayer
AH_CustomOffset:lda #ACTI_FIRST
                ldy #ACTI_LASTPERSISTENT-1      ;For potentially rapid-firing enemies, leave one actor free for player bullets
                bne AH_IsNpc
AH_IsPlayer:    lda #ACTI_FIRST                 ;Player bullets may use any free actors
                ldy #ACTI_LAST-1                ;except the object marker
AH_IsNpc:       jsr GetFreeActor
                bcc AH_CannotFire
                sty bulletActIndex
                ldy #WD_ATTACKDELAY             ;Set attack delay even if bullet spawn fails
                lda actIndex                    ;to spread out CPU use
                beq AH_UsePlayerDelay
                iny
                clc
AH_UsePlayerDelay:
                lda (wpnLo),y
                sta actAttackD,x
                bcs AH_NoGlobalDelayCheck
AH_GlobalAttackDelay:
                ldy #$00                        ;Prevent multiple enemies from rapid-firing
                bne AH_CannotFire
                cmp #MAX_GLOBAL_ATTACK_DELAY
                bcc AH_GlobalAttackDelayOK
                lda #MAX_GLOBAL_ATTACK_DELAY
AH_GlobalAttackDelayOK:
                sta AH_GlobalAttackDelay+1
AH_NoGlobalDelayCheck:
                ldy #WD_BULLETTYPE              ;Bullet type
                lda (wpnLo),y
                ldy bulletActIndex
                jsr SpawnWithOffset
AH_FireDir:     ldx #$00
                lda wpnBits
                and #WDB_BULLETDIRFRAME
                beq AH_BulletFrameDone
                txa
AH_BulletFrameDone:
                sta actF1,y
                lda bulletXSpdTbl,x
                beq AH_ZeroXSpd
                tay
                lda (wpnLo),y
AH_ZeroXSpd:    pha
                lda bulletYSpdTbl,x
                beq AH_ZeroYSpd
                tay
                lda (wpnLo),y
AH_ZeroYSpd:    ldx bulletActIndex
                sta actSY,x                     ;Store bullet speed
                pla
                sta actSX,x
                bit wpnBits
                bmi AH_NotInsideWall
                bvc AH_NoGravity
                lda actSY,x
                bmi AH_GravityModUp
                adc #GRAVITY_YSPD_MOD
AH_GravityModUp:adc #GRAVITY_YSPD_MOD           ;Boost Y speed if gravity-based
                sta actSY,x
AH_NoGravity:   jsr GetBlockInfo                ;Check if spawned inside wall
                tay                             ;and destroy immediately in that case
                and #BI_WALL|BI_WATER
                beq AH_NotInsideWall
                and #BI_WATER
                bne AH_InsideWall
                tya
                jsr CheckInsideSlope
                bcc AH_NotInsideWall
AH_InsideWall:  jsr RemoveActor
                ldx actIndex
                rts
AH_NotInsideWall:
                jsr InitActor                   ;Set collision size
                lda wpnBits                     ;Reduce size for horizontal/vertical bullets?
                and #WDB_DIRSIZEREDUCE
                beq AH_NoSizeReduce
                lda actSX,x
                bne AH_NoHorizReduce
                lsr actSizeH,x
AH_NoHorizReduce:
                lda actSY,x
                bne AH_NoVertReduce
                lsr actSizeU,x
                lsr actSizeD,x
AH_NoVertReduce:
AH_NoSizeReduce:ldy actIndex
                php
                lda actFlags,y
                and #AF_GROUPBITS               ;Copy group from attacker
                ora actFlags,x
                sta actFlags,x
                ldy #WD_DAMAGE                  ;Set duration and damage
                lda (wpnLo),y
                plp
                bne AH_NotPlayerBullet          ;Damage upgrade for player
AH_PlayerBulletDamageMod:
                ldy #NO_MODIFY
                jsr ModifyDamage
                ora #PLAYERDAMAGE               ;Mark damage originating from player
AH_NotPlayerBullet:
                sta actHp,x
                ldy #WD_DURATION
                lda (wpnLo),y
                sta actTime,x
                lda wpnBits                     ;Use flickering for bullets?
                and #WDB_FLICKERBULLET
                beq AH_NoFlicker
                lda #COLOR_FLICKER
                sta actFlash,x
AH_NoFlicker:   ldy #WD_SFX                     ;Finally play attack sound
                lda (wpnLo),y
AH_QueueSound:  jsr QueueSfx
                lda wpnBits                     ;Perform first move if requested
                and #WDB_PREMOVE|WDB_HALFPREMOVE
                beq AH_NoPreMove
                cmp #WDB_PREMOVE
                beq AH_PreMove
AH_HalfPreMove: lda actSX,x
                jsr Asr8
                jsr MoveActorX
                lda actSY,x
                jsr Asr8
                jsr MProj_CustomYSpeed
                jmp AH_NoPreMove
AH_PreMove:     jsr MoveProjectile              ;May also explode/remove
AH_NoPreMove:   ldx actIndex
                bne AH_NoAmmoReduce
                lda upgrade
                and #UPG_WPNCONSUMPTION
                cmp #$01                        ;Upgrade bit to carry
                ldy #WD_CONSUMPTION
                lda (wpnLo),y
                beq AH_NoAmmoReduce
                bmi AH_MineAmmo
                bcc AH_NoAmmoUpgrade
                ldy #6
                jsr ModifyDamage
AH_NoAmmoUpgrade:
                ldy wpnIndex
                jsr DecreaseAmmo
                bne AH_NotOutOfAmmo
                jsr SelectWeapon                ;Return to SMG when run out of ammo (A=0)
                lda #REDRAW_WEAPONS             ;Redraw all weapons + update red color
                jsr SetPanelRedraw
AH_NotOutOfAmmo:
AH_NoAmmoReduce:
                rts
AH_MineAmmo:    lda #16                         ;Decrement fuel+parts
                jsr DecreaseFuel
                lda #1
                jmp DecreaseParts

        ; Get weapon data & bits
        ;
        ; Parameters: Y weapon number
        ; Returns: wpnLo,wpnHi,wpnBits set
        ; Modifies: A,Y

GetWeaponData:  lda wpnTblLo,y
                sta wpnLo
                lda wpnTblHi,y
                sta wpnHi
                ldy #WD_BITS
                lda (wpnLo),y
                sta wpnBits
                rts

        ; Get bullet spawn offset by fake-drawing the actor
        ;
        ; Parameters: X actor index
        ; Returns: offset in temp1-temp4, Z set if player
        ; Modifies: A,Y,temp vars

GetBulletSpawnOffset:
                lda #$00
                sta temp1
                sta temp3
                lda #MAX_SPR                    ;"Draw" the actor in a fake manner
                sta sprIndex                    ;to get the last connect-spot
                jsr DrawActorSub_NoColor
                ldy #$00
                lda temp1                       ;Sign expand sprite offset, convert back
                bpl GBO_XPos                    ;to map coords
                dey
GBO_XPos:       sty temp2
                asl
                ;rol temp2                      ;First shift shouldn't modify MSB yet, so optimize away
                asl
                rol temp2
                asl
                rol temp2
                asl
                rol temp2
                tay
                asl
                rol temp2
                tya
                and #$7f
                sta temp1
                ldy #$00
                lda temp3
                bpl GBO_YPos
                dey
GBO_YPos:       sty temp4
                asl
                rol temp4
                asl
                rol temp4
                asl
                rol temp4
                tay
                asl
                rol temp4
                tya
                and #$7f
                sta temp3
                ldx actIndex
                rts

        ; Modify damage by a multiplier
        ;
        ; Parameters: A damage Y multiplier (8 = unmodified)
        ; Returns: A modified damage
        ; Modifies: A,Y,loader temp vars

ModifyDamage:   cpy #NO_MODIFY                  ;Optimize the unmodified case
                beq MD_Done
                stx zpBitsLo
                ldx #zpSrcLo
                jsr MulU
                ldx zpBitsLo
                lda zpSrcLo
                lsr zpSrcHi                     ;Divide by 8
                ror
                lsr zpSrcHi
                ror
                lsr zpSrcHi
                ror
                adc #$00                        ;Round to nearest
                bne MD_Done
MD_EnsureOne:   lda #$01                        ;Ensure at least 1 point damage
MD_Done:        rts
