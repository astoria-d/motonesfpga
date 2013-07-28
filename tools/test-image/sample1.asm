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

	lda	#$3f
	sta	$2006
	lda	#$00
	sta	$2006
	ldx	#$00
	ldy	#$10

    ;;load palette.
copypal:
	lda	palettes, x
	sta	$2007
	inx
	dey
	bne	copypal

	lda	#$21
	sta	$2006
	lda	#$c9
	sta	$2006
	ldx	#$00
	ldy	#$0d

    ;;load name table.
copymap:
	lda	string, x
	sta	$2007
	inx
	dey
	bne	copymap

	lda	#$00
	sta	$2005
	sta	$2005

    ;;show test msg.
	lda	#$08
	sta	$2000
	lda	#$1e
	sta	$2001

    ;;infinite loop.
mainloop:
	jmp	mainloop
.endproc

palettes:
	.byte	$0f, $00, $10, $20
	.byte	$0f, $06, $16, $26
	.byte	$0f, $08, $18, $28
	.byte	$0f, $0a, $1a, $2a

string:
	.byte	"test2!"

.segment "VECINFO"
	.word	$0000
	.word	Reset
	.word	$0000

; character rom file.
.segment "CHARS"
	.incbin	"character.chr"
