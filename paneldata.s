MENU_MAP        = 0
MENU_GAMEOVER   = 5
MENU_NONE       = $ff

MENUITEM_RESUME = 0
MENUITEM_RETRY  = 1
MENUITEM_SAVE   = 2
MENUITEM_STATUS = 3
MENUITEM_PAN    = 4

gameTextFadeTbl:dc.b 0,6 ;Must be adjacent, 3 is last entry in gameTextFadeTbl
partsPickupTbl: dc.b 3,5,10,15

mapDisplayXTbl: dc.b MAPDISPLAYCENTERX,MAPDISPLAYCENTERX+19,MAPDISPLAYCENTERX-20,MAPDISPLAYCENTERX
mapDisplayYTbl: dc.b MAPDISPLAYCENTERY,MAPDISPLAYCENTERY+9,MAPDISPLAYCENTERY-9,MAPDISPLAYCENTERY

menuItemTbl:    dc.b 1,MENUITEM_RESUME,MENUITEM_STATUS,MENUITEM_PAN,MENUITEM_SAVE  ;Map mode
                dc.b 4,MENUITEM_RETRY,MENUITEM_SAVE                   ;Gameover mode

menuItemTxtLo:  dc.b <txtResume
                dc.b <txtRetry
                dc.b <txtSave
                dc.b <txtStatus
                dc.b <txtPan

menuItemTxtHi:  dc.b >txtResume
                dc.b >txtRetry
                dc.b >txtSave
                dc.b >txtStatus
                dc.b >txtPan

analyzerColorTbl:
                dc.b $08,$0e,$0a,$0f,$09

humanoidUpperOverride:
                dc.b 9 ;15 bytes inbetween to next value

upgradeNameTblLo:
                dc.b <txtWheel              ;0
                dc.b <txtHighJump           ;1
                dc.b <txtJetPack            ;2
                dc.b <txtWheelFuel          ;3
                dc.b <txtJetpackFuel        ;4
                dc.b <txtWpnConsumption     ;5
                dc.b <txtTechAnalyzer       ;6
                dc.b <txtHealth1            ;7
                dc.b <txtHealth2            ;8
                dc.b <txtRegen1             ;9
                dc.b <txtRegen2             ;10
                dc.b <txtWheelDamage        ;11
                dc.b <txtWpnDamage1         ;12
                dc.b <txtWpnDamage2         ;13
                dc.b <txtHeatShield         ;14

                dc.b 8

upgradeNameTblHi:
                dc.b >txtWheel              ;0
                dc.b >txtHighJump           ;1
                dc.b >txtJetPack            ;2
                dc.b >txtWheelFuel          ;3
                dc.b >txtJetpackFuel        ;4
                dc.b >txtWpnConsumption     ;5
                dc.b >txtTechAnalyzer       ;6
                dc.b >txtHealth1            ;7
                dc.b >txtHealth2            ;8
                dc.b >txtRegen1             ;9
                dc.b >txtRegen2             ;10
                dc.b >txtWheelDamage        ;11
                dc.b >txtWpnDamage1         ;12
                dc.b >txtWpnDamage2         ;13
                dc.b >txtHeatShield         ;14

                dc.b 10

upgradeDisregardTbl:
                dc.b UPG2_HEALTH2
                dc.b 0
                dc.b UPG2_REGEN2
                dc.b 0
                dc.b 0
                dc.b UPG2_WPNDAMAGE2
                dc.b 0
                dc.b 0