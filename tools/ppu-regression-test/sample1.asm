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


    ;;bg palette
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

    ;;sprite..
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



    ;;name table set.
	lda	#$20
	sta	$2006
	lda	#$06
	sta	$2006

;;0x44, 45, 45 = DEE
	lda	#$44
	sta	$2007
	lda	#$45
	sta	$2007
	lda	#$45
	sta	$2007


	lda	#$20
	sta	$2006
	lda	#$60
	sta	$2006

	lda	#48
	sta	$2007
	lda	#49
	sta	$2007
	lda	#50
	sta	$2007
	lda	#51
	sta	$2007
	lda	#52
	sta	$2007
	lda	#53
	sta	$2007
	lda	#54
	sta	$2007
	lda	#55
	sta	$2007
	lda	#56



	lda	#$21
	sta	$2006
	lda	#$e6
	sta	$2006

;;test pattern
	lda	#$20
	sta	$2006
	lda	#$20
	sta	$2006

	lda	#$01
	sta	$2007
	lda	#$02
	sta	$2007
	lda	#$03
	sta	$2007
	lda	#$04
	sta	$2007
	lda	#$05
	sta	$2007
	lda	#$06
	sta	$2007
	lda	#$07
	sta	$2007
	lda	#$08
	sta	$2007
	lda	#$09
	sta	$2007
	lda	#$0a
	sta	$2007
	lda	#$0b
	sta	$2007
	lda	#$0c
	sta	$2007
	lda	#$0d
	sta	$2007
	lda	#$0e
	sta	$2007
	lda	#$0f
	sta	$2007

	lda	#$20
	sta	$2006
	lda	#$40
	sta	$2006

	lda	#$10
	sta	$2007
	lda	#$11
	sta	$2007
	lda	#$12
	sta	$2007
	lda	#$13
	sta	$2007
	lda	#$14
	sta	$2007
	lda	#$15
	sta	$2007
	lda	#$16
	sta	$2007
	lda	#$17
	sta	$2007
	lda	#$18
	sta	$2007
	lda	#$19
	sta	$2007
	lda	#$1a
	sta	$2007
	lda	#$1b
	sta	$2007
	lda	#$1c
	sta	$2007
	lda	#$1d
	sta	$2007
	lda	#$1e
	sta	$2007
	lda	#$1f
	sta	$2007


;;attr
	lda	#$23
	sta	$2006
	lda	#$c1
	sta	$2006

;;--attr=11011000
	lda	#$d8
	sta	$2007


;;;set sprite
    ;;sprite addr=00
    lda #$00
    sta $2003

    ;;sprite data: y=02
    lda #3
    sta $2004
    ;;tile=0x4d (ascii 'M')
    lda #$4d
    sta $2004
    lda #$01
    sta $2004
    ;x=100
    lda #$64
    sta $2004

    lda #$32
    sta $2004
    lda #$4f
    sta $2004
    lda #$01
    sta $2004
    lda #$1e
    sta $2004

    lda #60
    sta $2004
    lda #$50
    sta $2004
    lda #$01
    sta $2004
    lda #$21
    sta $2004


    lda #$3d
    sta $2004
    lda #$51
    sta $2004
    lda #$02
    sta $2004
    lda #45
    sta $2004

    ;;init scroll point.
    lda #$00
    sta $2005
    lda #248
    sta $2005

    ;;show bg...
	lda	#$1e
	sta	$2001

    ;;;enable nmi
	lda	#$80
	sta	$2000

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


    ;;done...
    ;;infinite loop.
mainloop:
	jmp	mainloop
.endproc


nmi_test:
;    jsr set_scroll
;    jsr set_bg_col

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
