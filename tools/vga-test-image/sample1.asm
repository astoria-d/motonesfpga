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
	sei
	ldx	#$ff
	txs

    ;ppu register initialize.
	lda	#$00
	sta	$2000
	sta	$2001


;;palettes:
;;;;;bg palette
;;$0f, $00, $10, $20
;;$0f, $04, $14, $24
;;$0f, $08, $18, $28
;;$0f, $0c, $1c, $2c
;;;;;spr palette
;;$0f, $00, $10, $20
;;$0f, $06, $16, $26
;;$0f, $08, $18, $28
;;$0f, $0a, $1a, $2a

;step0.1 = palette set.
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


;;sprite pallete
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



;;step1 = name table set.
;;set vram addr 2005 (first row, 6th col)
	lda	#$20
	sta	$2006
	lda	#$06
	sta	$2006

;;set name tbl data
;;0x44, 45, 45 = DEE

	lda	#$44
	sta	$2007
	lda	#$45
	sta	$2007
	lda	#$45
	sta	$2007

;;set vram addr 21d1
	lda	#$21
	sta	$2006
	lda	#$E6
	sta	$2006

;;msg=DEE TEST !!!
	lda	#$44
	sta	$2007
	lda	#$45
	sta	$2007
	lda	#$45
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

;;msg=TEST !!!
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
	lda	#$21
	sta	$2007


;;set vram addr 23c1 (attribute)
	lda	#$23
	sta	$2006
	lda	#$c1
	sta	$2006
;;attr=11011000
	lda	#$d8
	sta	$2007


;;step2 = sprite set.
;;set sprite addr=00 (first sprite)
	lda	#$00
	sta	$2003
;;set sprite data: y=02
	lda	#$02
	sta	$2004
;;tile=0x4d (ascii 'M')
	lda	#$4d
	sta	$2004
;;set sprite attr=03 (palette 03)
	lda	#$03
	sta	$2004
;;set sprite data: x=100
	lda	#$64
	sta	$2004

;;set sprite data: y=50
	lda	#$32
	sta	$2004
;;tile=0x4d (ascii 'O')
	lda	#$4f
	sta	$2004
;;set sprite attr=01
	lda	#$01
	sta	$2004
;;set sprite data: x=30
	lda	#$1e
	sta	$2004

;;set sprite data: y=60
	lda	#60
	sta	$2004
;;tile=0x4d (ascii 'P')
	lda	#$50
	sta	$2004
;;set sprite attr=01
	lda	#$01
	sta	$2004
;;set sprite data: x=33
	lda	#$21
	sta	$2004

;;set sprite data: y=61
	lda	#$3d
	sta	$2004
;;tile=0x4d (ascii 'Q')
	lda	#$51
	sta	$2004
;;set sprite attr=02
	lda	#$02
	sta	$2004
;;set sprite data: x=45
	lda	#45
	sta	$2004

    ;;show bg...
	lda	#$1e
	sta	$2001

    ;;;enable nmi
	lda	#$80
	sta	$2000

    ;;done...
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
