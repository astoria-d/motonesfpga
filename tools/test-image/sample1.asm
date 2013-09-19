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
    ldx #$40    ;;name table entry cnt.

    lda #$20
    sta $2006
    lda #$c0
    sta $2006

nt_st:
    lda nt1, y
    sta $2007
    iny
    dex
    bpl nt_st

    ;;load attr tbl.
    ldy #$00
    ldx #$08    ;;attribute entry cnt

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
    lda #$3d
    sta $0302
    jsr set_bg_col

    ;;set scroll reg.
    ;;lda #$a6
    lda #$05
    sta $0300
    lda #00
    sta $0301
    jsr set_scroll

    ;;set next page name table
    ldy #$00
    ldx #$0b

    lda #$24
    sta $2006
    lda #$c0
    sta $2006

nt2_st:
    lda nt2, y
    sta $2007
    iny
    dex
    bpl nt2_st

    ;;next page attr.
    lda #$27
    sta $2006
    lda #$d0
    sta $2006

    lda #$e4
    sta $2007

;;;    ;;dma test data.
;;;    ldy #$00
;;;    ldx #$41
;;;    stx $00
;;;    ldx #$00
;;;dma_set:
;;;    ;;y pos
;;;    txa
;;;    sta $0200, y
;;;    iny
;;;    ;;tile index
;;;    lda $00
;;;    cmp #$5b
;;;    bne inc_tile
;;;    lda #$41
;;;    sta $00
;;;inc_tile:
;;;    inc $00
;;;    sta $0200, y
;;;    iny
;;;    ;;attribute
;;;    lda #$01
;;;    sta $0200, y
;;;    iny
;;;    ;;x pos
;;;    txa
;;;    adc #$03
;;;    tax
;;;    rol
;;;    sta $0200, y
;;;    iny
;;;    bne dma_set
;;;
;;;    ;;dma start.
;;;    lda #$02
;;;    sta $4014

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
    jsr set_scroll
    jsr set_bg_col

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

set_scroll:
    lda $0300
    sta $2005
    clc
    adc #$05
    sta $0300
    lda $0301
    sta $2005
    clc
    adc #04
;;    sta $0301
    rts

set_bg_col:
    lda #$3f
    sta $2006
    lda #$10
    sta $2006
    lda $0302
    sta $2007
    cmp #$30
    bne bg_dec
    lda #$3d
    sta $0302
    jmp bg_done
bg_dec:
    dec $0302
bg_done:
    rts

nt1:
	.byte	$41, $42, $43, $44, $45, $46, $47, $48, $49, $4a, $4b, $4c, $4d, $4e, $4f, $50
	.byte	$61, $62, $63, $64, $65, $66, $67, $68, $69, $6a, $6b, $6c, $6d, $6e, $6f, $70
	.byte	$80, $81, $82, $83, $84, $85, $86, $87, $88, $89, $8a, $8b, $8c, $8d, $8e, $8f
	.byte	$90, $91, $92, $93, $94, $95, $96, $97, $98, $99, $9a, $9b, $9c, $9d, $9e, $9f
nt2:
	.byte	$6b, $6a, $69, $68, $67, $66, $65, $64, $63, $62, $61
	.byte	$30, $31, $32, $33, $34, $35, $36, $37, $38, $39, $3a

at1:
	.byte	$1b, $e4, $a5, $5a
	.byte	$e4, $1b, $5a, $a5

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
