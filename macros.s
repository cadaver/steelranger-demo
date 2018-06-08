                processor 6502

                mac varbase
NEXT_VAR        set {1}
                endm

                mac var
{1}             = NEXT_VAR
NEXT_VAR        set NEXT_VAR + 1
                endm

                mac varrange
{1}             = NEXT_VAR
NEXT_VAR        set NEXT_VAR + {2}
                endm

                mac checkvarbase
                if NEXT_VAR > {1}
                    err
                endif
                endm

                mac definescript
NEXT_EP         set {1}*$100
                endm
                
                mac defineep
EP_{1}          = NEXT_EP
NEXT_EP         set NEXT_EP + 1
                endm

        ; BIT instruction for skipping the next 1- or 2-byte instruction

                mac skip1
                dc.b $24
                endm

                mac skip2
                dc.b $2c
                endm

        ; Encode 4 instruction lengths into one byte
        
                mac instrlen
                dc.b {1} | ({2} * 4) | ({3} * 16) | ({4} * 64)
                endm