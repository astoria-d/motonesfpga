.setcpu		"6502"
.autoimport	on

; iNES header
.segment "HEADER"
	.byte	$4E, $45, $53, $1A	; "NES" Header
	.byte	$02			; PRG-BANKS
	.byte	$01			; CHR-BANKS
	.byte	$01			; Vetrical Mirror
	.byte	$00			; 
	.byte	$00, $00, $00, $00	; 
	.byte	$00, $00, $00, $00	; 


.segment "STARTUP"
.proc	Reset

; interrupt off, initialize sp.
;;init ppu.
	lda	#$00
	sta	$2000
	sta	$2001

;;init palette
	lda	#$3f
	sta	$2006
	lda	#$00
	sta	$2006

	lda	#$11
	sta	$2007
	lda	#$01
	sta	$2007
	lda	#$03
	sta	$2007
	lda	#$13
	sta	$2007

	lda	#$0f
	sta	$2007
	lda	#$04
	sta	$2007
	lda	#$14
	sta	$2007
	lda	#$24
	sta	$2007

	lda	#$0f
	sta	$2007
	lda	#$08
	sta	$2007
	lda	#$18
	sta	$2007
	lda	#$28
	sta	$2007

	lda	#$05
	sta	$2007
	lda	#$0c
	sta	$2007
	lda	#$1c
	sta	$2007
	lda	#$2c
	sta	$2007

;;;sprite palette
	lda	#$00
	sta	$2007
	lda	#$24
	sta	$2007
	lda	#$1b
	sta	$2007
	lda	#$11
	sta	$2007

	lda	#$00
	sta	$2007
	lda	#$32
	sta	$2007
	lda	#$16
	sta	$2007
	lda	#$20
	sta	$2007

	lda	#$00
	sta	$2007
	lda	#$26
	sta	$2007
	lda	#$01
	sta	$2007
	lda	#$31
	sta	$2007

;;init vram
;;name table
	lda	#$20
	sta	$2006
	lda	#$06
	sta	$2006

	lda	#$44
	sta	$2007
	lda	#$45
	sta	$2007
	lda	#$45
	sta	$2007

;;another msg 'DEE TEST!'
	lda	#$21
	sta	$2006
	lda	#$e6
	sta	$2006

	lda	#$44
	sta	$2007
	lda	#$45
	sta	$2007
	lda	#$45
	sta	$2007
	lda	#$00
	sta	$2007
	lda	#$00
	sta	$2007
	lda	#$54
	sta	$2007
	lda	#$45
	sta	$2007
	lda	#$53
	sta	$2007
	lda	#$54
	sta	$2007
	lda	#$21
	sta	$2007

;;attr tbl
	lda	#$23
	sta	$2006
	lda	#$c1
	sta	$2006

	lda	#$d8
	sta	$2007

;;sprite
	lda	#$00
	sta	$2003
	lda	#$02
	sta	$2004
	lda	#$4d
	sta	$2004
	lda	#$03
	sta	$2004
	lda	#$64
	sta	$2004

	lda	#$04
	sta	$2003
	lda	#$32
	sta	$2004
	lda	#$4f
	sta	$2004
	lda	#$01
	sta	$2004
	lda	#$1e
	sta	$2004

	lda	#$08
	sta	$2003
	lda	#$33
	sta	$2004
	lda	#$50
	sta	$2004
	lda	#$01
	sta	$2004
	lda	#$21
	sta	$2004

	lda	#$0c
	sta	$2003
	lda	#$3d
	sta	$2004
	lda	#$51
	sta	$2004
	lda	#$02
	sta	$2004
	lda	#$23
	sta	$2004


;;enble ppu.
	lda	#$1e
	sta	$2001
	lda	#$80
	sta	$2000

    ;;all done
    ;;infinite loop.
mainloop:
	jmp	mainloop
.endproc




nmi_test:
    rti



;;;for DE1 internal memory constraints.
.segment "VECINFO_4k"
	.word	nmi_test
	.word	Reset
	.word	$0000

.segment "VECINFO"
	.word	nmi_test
	.word	Reset
	.word	$0000

; character rom file.
.segment "CHARS"
	.incbin	"character.chr"
