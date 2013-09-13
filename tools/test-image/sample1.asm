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

    ;;load palette.
	ldx	#$00
	ldy	#$20
copypal:
	lda	palettes, x
	sta	$2007
	inx
	dey
	bne	copypal

	lda	#$20
	sta	$2006
	lda	#$ab
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

    ;;scroll reg set.
	lda	#$00
	sta	$2005
	sta	$2005

;;;;----------------------
    ;;load name tbl.
    ldy #$00
    ldx #$2c

    lda #$20
    sta $2006
    lda #$80
    sta $2006

    lda #$80
    sta $00
    lda #$20
    sta $01

nt_st:
    cpy #$0b
    bne goto_next1
    jsr add_nl
    jmp goto_next3
goto_next1:
    cpy #$16
    bne goto_next2
    jsr add_nl
    jmp goto_next3
goto_next2:
    cpy #$21
    bne goto_next3
    jsr add_nl
goto_next3:

    lda nt1, y
    sta $2007
    iny
    dex
    bpl nt_st


    ;;load attr tbl.
    ldy #$00
    ldx #$04

    lda #$23
    sta $2006
    lda #$c8
    sta $2006

at_st:
    lda at1, y
    sta $2007
    iny
    dex
    bpl at_st

    ;;set universal bg color.
    lda #$3f
    sta $2006
    lda #$10
    sta $2006
    lda #$3d
    sta $2007

    ;;set scroll reg.
    lda #$03
    sta $2005
    lda #$00
    sta $2005

    ;;show bg...
	lda	#$1e
	sta	$2001

    ;;;enable nmi
	lda	#$80
	sta	$2000

    ;;done...
    ;;infinite loop.
mainloop:

    ;;read ppu status reg while displaying
    ;;vram read test
    ldx #$0a
l1:
    nop
    dex
    bne l1

    ldx #$0a
read_status:
    lda $2002
    dex
    bne read_status

	jmp	mainloop
.endproc


nmi_test:

    rti

add_nl:
    clc
    txa
    pha

    lda $01
    sta $2006

    lda $00
    adc #$20
    sta $00
    sta $2006

    bcc no_carry
    lda $01
    adc #$00
    sta $01
    sta $2006
    lda $00
    sta $2006
no_carry:

    pla
    tax
    rts

nt1:
	.byte	$61, $62, $63, $64, $65, $66, $67, $68, $69, $6a, $6b
	.byte	$30, $31, $32, $33, $34, $35, $36, $37, $38, $39, $3a
	.byte	$41, $42, $43, $44, $45, $46, $47, $48, $49, $4a, $4b
	.byte	$30, $31, $32, $33, $34, $35, $36, $37, $38, $39, $3a

at1:
	.byte	$1b, $e4, $a5, $5a

palettes:
;;;bg palette
	.byte	$0f, $00, $10, $20
	.byte	$0f, $04, $14, $24
	.byte	$0f, $08, $18, $28
	.byte	$0f, $0c, $1c, $2c
;;;spr palette
	.byte	$0f, $00, $10, $20
	.byte	$0f, $06, $16, $26
	.byte	$0f, $08, $18, $28
	.byte	$0f, $0a, $1a, $2a

string:
	.byte	"test2!"

.segment "VECINFO"
	.word	nmi_test
	.word	Reset
	.word	$0000

; character rom file.
.segment "CHARS"
	.incbin	"character.chr"
