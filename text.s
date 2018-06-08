txtShip:        dc.b "UMS SCOURGE",0
txtSurface:     dc.b "PLANET SURFACE",0
txtSurfaceCaves:dc.b "SURFACE"
txtCaves:       dc.b " CAVES",0
txtSecurityTower:dc.b "SECURITY"
txtTower:       dc.b " TOWER",0
txtCity:        dc.b "MACHINE CITY",0
txtComputer:    dc.b "COMPUTER"
txtVault:       dc.b " VAULT",0
txtResearch:

txtResume:      dc.b "BACK",0
txtStatus:      dc.b "STATUS",0
txtPan:         dc.b "PAN",0
txtRetry:       dc.b "CONTINUE",0
txtSave:        dc.b "SAVE&END",0
txtStatusHeader:dc.b "WEAPONS & SYSTEMS:",0

txtSMG:         dc.b "FULL AUTO",0
txtBounce:      dc.b "BOUNCE",0
txtLaser:       dc.b "LASER",0
txtFlamethrower:dc.b "FLAMETHROWER",0
txtGrenades:    dc.b "GRENADES",0
txtMissiles:    dc.b "MISSILES",0
txtArcGun:      dc.b "ARC GUN",0
txtHeavyPlasma: dc.b "HEAVY PLASMA",0
txtHealth:      dc.b "POWERUP",0
txtFuel:        dc.b "FUEL",0
txtParts:       dc.b "PARTS",0
txtAlpha:       dc.b "ALPHA"
txtPass:        dc.b " PASS",0
txtBeta:        dc.b "BETA",TEXTJUMP+>txtPass,<txtPass
txtGamma:       dc.b "GAMMA",TEXTJUMP+>txtPass,<txtPass
txtDelta:       dc.b "DELTA",TEXTJUMP+>txtPass,<txtPass
txtEpsilon:     dc.b "EPSILON",TEXTJUMP+>txtPass,<txtPass
txtOmega:       dc.b "OMEGA",TEXTJUMP+>txtPass,<txtPass
txtNeedPass:    dc.b "NEED",TEXTJUMP+>txtPass,<txtPass

txtWheel:       dc.b "WHEEL",0
txtHighJump:    dc.b "HI-JUMP",0
txtJetPack:     dc.b "JETPACK",0
txtHeatShield:  dc.b "HEAT SHIELD",0
txtWheelFuel:   dc.b "WHEEL"
txtFuelUse:     dc.b " FUEL"
txtUse:         dc.b " USE",0
txtJetpackFuel: dc.b "JETPACK",TEXTJUMP+>txtFuelUse,<txtFuelUse
txtWpnConsumption:dc.b "WEAPON AMMO",TEXTJUMP+>txtUse,<txtUse
txtTechAnalyzer:dc.b "TECH ANALYZER",0
txtHealth1:     dc.b "ARMOR STRENGTH",0
txtHealth2:     dc.b "MAX ",TEXTJUMP+>txtHealth1,<txtHealth1
txtRegen1:      dc.b "POWER REGEN",0
txtRegen2:      dc.b "MAX ",TEXTJUMP+>txtRegen1,<txtRegen1
txtWheelDamage: dc.b "WHEEL TOUCH"
txtDamage:      dc.b " DAMAGE",0
txtWpnDamage1:  dc.b "WEAPON",TEXTJUMP+>txtDamage,<txtDamage
txtWpnDamage2:  dc.b "MAX ",TEXTJUMP+>txtWpnDamage1,<txtWpnDamage1
                     ;0123456789012345678901234567890123456789
txtDemoEnd:     dc.b " CONGRATULATIONS! YOU HAVE FINISHED THE",0
                dc.b " STEEL RANGER DEMO VERSION. TO CONTINUE",0
                dc.b "  THE MISSION, GET THE FULL GAME FROM:",0
                dc.b " WWW.PSYTRONIK.NET OR PSYTRONIK.ITCH.IO",0,0
