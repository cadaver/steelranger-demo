                include loadsym.s

loaderCodeStart = SlowLoadEnd

                org $0000

                dc.b >(InitLoader-1)
                dc.b <(InitLoader-1)
                dc.b >(LoadFile-1)
                dc.b <(LoadFile-1)
                dc.b <loaderCodeStart
                dc.b >loaderCodeStart


