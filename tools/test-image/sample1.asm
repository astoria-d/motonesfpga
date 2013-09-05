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

    ;;dma test data.
    ldy #$00
    ldx #$41
    stx $00
    ldx #$00
dma_set:
    ;;y pos
    txa
    sta $0200, y
    iny
    ;;tile index
    lda $00
    cmp #$5b
    bne inc_tile
    lda #$41
    sta $00
inc_tile:
    inc $00
    sta $0200, y
    iny
    ;;attribute
    lda #$01
    sta $0200, y
    iny
    ;;x pos
    txa
    adc #$03
    tax
    rol
    sta $0200, y
    iny
    bne dma_set

    ;;dma start.
    lda #$02
    sta $4014

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

	lda	#$00
	sta	$2005
	sta	$2005

    ;;show test msg.
	lda	#$00
	sta	$2000
	lda	#$1e
	sta	$2001

;;    jmp boundary_1
;;    ;;fill dummy data to test page boundary instruction.
;;    .byte      $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;
;;    ;;;single byte instruction page boundary test.
;;boundary_1:
;;    lda #$01
;;    ror
;;    ror
;;    ror
;;    ror
;;    ror
;;    ror
;;    ror
;;    ror
;;    ror
;;    ror
;;    ror
;;    ror
;;    ror
;;;;this is pch increment at T1 cycle. 
;;;;;@80ff
;;    rol
;;    lsr
;;
;;    jmp boundary_2_1
;;
;;    .byte      $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;
;;boundary_2_1:
;;    ;;;two byte instruction page boundary test.
;;	lda	#$01
;;	lda	#$01
;;	lda	#$01
;;	lda	#$01
;;	lda	#$01
;;	lda	#$01
;;;;this is pch increment at T1 cycle. 
;;    ;;;@81ff
;;	ldx	#$08
;;
;;
;;    jmp boundary_2_2
;;
;;    .byte      $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;
;;boundary_2_2:
;;    ;;;two byte instruction page boundary test.
;;	lda	#$01
;;	lda	#$01
;;	lda	#$01
;;	lda	#$01
;;	lda	#$01
;;    ror
;;;;this is pch increment at next T0 cycle. 
;;    ;;;@82fe
;;	ldx	#$0a
;;
;;    jmp boundary_2_3
;;
;;    .byte      $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;
;;boundary_2_3:
;;    ;;;two byte instruction w/ 3 exec cycle page boundary test.
;;	lda	#$01
;;	lda	#$01
;;	lda	#$01
;;
;;	ror
;;	lda	#$01
;;	lda	#$de
;;	sta	$13
;;
;;
;;;;this is pch increment at T1 cycle. 
;;    ;;;@83ff
;;	ldy $09, x
;;
;;
;;    jmp boundary_2_4
;;
;;    .byte      $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;
;;boundary_2_4:
;;    ;;;two byte instruction w/ 3 exec cycle page boundary test.
;;	lda	#$01
;;	lda	#$01
;;	ldy	#$05
;;
;;	ror
;;	lda	#$01
;;	lda	#$de
;;;;this is pch increment at T2 cycle. 
;;    ;;;@84fe
;;	sta	$13
;;
;;
;;    jmp boundary_3_1
;;
;;    .byte      $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;
;;boundary_3_1:
;;    ;;;three byte instruction w/ page boundary test.
;;	lda	#$01
;;	lda	#$01
;;	ldy	#$05
;;
;;	ror
;;	lda	#$01
;;	lda	#$dd
;;;;this is pch increment at T3 cycle. 
;;    ;;;@85fd
;;	sta	$06fc, x
;;
;;    jmp boundary_3_2
;;
;;    .byte      $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;
;;boundary_3_2:
;;    ;;;three byte instruction w/ page boundary test.
;;	lda	#$01
;;	lda	#$01
;;	lda	#$01
;;	ldy	#$05
;;
;;	lda	#$01
;;	lda	#$dd
;;;;this is pch increment at T2 cycle. 
;;    ;;;@86fe
;;	sta	$06fc, x
;;
;;    jmp boundary_3_3
;;
;;    .byte      $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;
;;boundary_3_3:
;;    ;;;three byte instruction w/ page boundary test.
;;	lda	#$01
;;	lda	#$01
;;	lda	#$01
;;	ldy	#$05
;;
;;	ldy	#$08
;;	lda	#$dd
;;;;this is pch increment at T1 cycle. 
;;    ;;;@87ff
;;	sta	$06fc, x
;;
;;    jmp boundary_3_4
;;
;;    .byte      $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;
;;boundary_3_4:
;;    ;;;three byte instruction w/ page boundary test.
;;	lda	#$01
;;	lda	#$01
;;    ror
;;
;;	ldy	#$08
;;	lda	#$dd
;;;;this is pch increment at T0 cycle. 
;;    ;;;@88fd
;;	sta	$06fc, x
;;
;;    nop
;;    nop
;;    nop
;;
;;    ;;;instruction coverage test....
;;    ;;adc abs, y
;;    ldy #$10
;;    ldx #$fa
;;    stx $0790
;;    lda #$b0
;;    ;;fa+b0=aa
;;    adc $0780, y
;;
;;    clc
;;    ldy #$ab
;;    ldx #$fa
;;    stx $082b
;;    lda #$dd
;;    ;;fa+dd=d7
;;    adc $0780, y
;;
;;    ;;bit zp
;;    ldx #$15
;;    stx $2b
;;    bit $2b
;;    lda #$8a
;;    bit $2b
;;
;;    ;;sbc imm
;;    ;;8a-5c=2e
;;    sbc #$5c
;;    ;;2e-3d=f1
;;    sbc #$3d
;;    ;;f1-e5=0c
;;    sbc #$e5
;;
;;    ;;cli/clv
;;    cli
;;    ldx #$c0
;;    stx $2b
;;    bit $2b
;;    clv
;;
;;    ;;adc zp, x/abs, x/indir, y
;;    lda #$11
;;    ldx #$e4
;;    sta $a4
;;    ;11+81=92
;;    lda #$81
;;    adc $c0, x
;;
;;    stx $0734
;;    ;93+e4=177
;;    adc $0650, x
;;
;;    ldx #$c9
;;    stx $07e8
;;    lda #$34
;;    sta $07
;;    lda #$07
;;    sta $08
;;    ldy #$b4
;;    ;c9+07=d0
;;    adc ($07), y
;;
;;    ;;and zp, x/abs/abs, x/indir, y
;;    lda #$f5
;;    ldx #$e4
;;    sta $a4
;;    ;f5&5e=54
;;    lda #$5e
;;    and $c0, x
;;
;;    stx $0734
;;    ;e4&54=44
;;    and $0650, x
;;
;;    ldx #$c9
;;    stx $07e8
;;    lda #$34
;;    sta $07
;;    lda #$07
;;    sta $08
;;    ldy #$b4
;;    ;no page crossing
;;    ;c9&07=01
;;    and ($07), y
;;
;;    ldx #$c9
;;    stx $0825
;;    lda #$34
;;    sta $07
;;    lda #$07
;;    sta $08
;;    ldy #$f1
;;    ;page crossing
;;    ;c9&07=01
;;    and ($07), y
;;
;;    ;;cmp zp, x/abs/abs, x/indir, y
;;    lda #$de
;;    ldx #$e4
;;    sta $a4
;;    ;c5-de=-19 > (e7)
;;    lda #$c5
;;    cmp $c0, x
;;
;;    sec
;;    lda #$75
;;    stx $0734
;;    ;75-e4=-6f > 91
;;    cmp $0650, x
;;
;;    ldx #$c9
;;    stx $0825
;;    lda #$34
;;    sta $07
;;    lda #$07
;;    sta $08
;;    ldy #$f1
;;    lda #$c9
;;    ;page crossing
;;    ;c9-c9=0
;;    cmp ($07), y
;;
;;    ;;rol zp/zp, x/abs/abs, x
;;    lda #$de
;;    ldx #$e4
;;    sta $a4
;;    ;de<1 =bc w/ carry
;;    clc
;;    rol $c0, x
;;    ;bc<1 =78  w/ carry
;;    rol $a4
;;
;;    ldx #$64
;;    stx $0722
;;    ;64<1 = c8 w/o carry
;;    rol $06be, x
;;
;;    ldx #$80
;;    stx $0734
;;    ;80<1 = 00 w/ carry.
;;    rol $0734
;;
;;    ;;cpx abs
;;    ;;cpy zp/abs
;;    lda #$de
;;    sta $03a4
;;    ;c5-de=-19 > (e7)
;;    ldx #$c5
;;    cpx $03a4
;;
;;    sec
;;    ldy #$75
;;    ldx #$e4
;;    stx $34
;;    ;75-e4=-6f > 91
;;    cpy $34
;;
;;    ldx #$c9
;;    stx $0825
;;    ldy #$c9
;;    ;c9-c9=0
;;    cpy $0825
;;
;;    ;;lsr zp/zp, x/abs/abs, x
;;    lda #$de
;;    ldx #$e4
;;    sta $a4
;;    ;de>1 =6f w/o carry
;;    clc
;;    lsr $c0, x
;;    ;6f>1 =37  w/ carry
;;    lsr $a4
;;
;;    ldx #$64
;;    stx $0722
;;    ;64>1 = 32 w/o carry
;;    lsr $06be, x
;;
;;    ldx #$01
;;    stx $0734
;;    ;01>1 = 00 w/ carry.
;;    lsr $0734
;;
;;    ;;ldy abs, x
;;    ;;ldx zp, y
;;    ldx #$fa
;;    stx $0820
;;    ;;page cross
;;    ldy $0726, x
;;
;;    ldx #$10
;;    stx $0820
;;    ;no page cross
;;    ldy $0810, x
;;
;;    ldy #$10
;;    sty $e0
;;    ldx #$55
;;    ldx $d0, y
;;
;;    ;;dec zp, x/abs, x
;;    ;;inc zp, x/abs, x
;;    lda #$00
;;    ldx #$e4
;;    sta $88
;;    ldy #$00
;;    dec $a4, x
;;
;;    ldx #$64
;;    stx $0722
;;    dec $06be, x
;;
;;    lda #$fe
;;    ldx #$e4
;;    sta $88
;;    inc $a4, x
;;    inc $a4, x
;;    inc $a4, x
;;
;;    ldx #$64
;;    stx $0722
;;    inc $06be, x
;;
;;    ;;ror zp/zp,x/abs
;;    lda #$02
;;    ldx #$e4
;;    sta $88
;;    ror $a4, x
;;    ror $a4, x
;;    ror $a4, x
;;
;;    ldx #$64
;;    stx $0722
;;    ror $0722
;;
;;    ;;asl zp/zp,x/abs/abs,x
;;    lda #$40
;;    ldx #$e4
;;    sta $88
;;    asl $88
;;    asl $a4, x
;;    asl $a4, x
;;
;;    ldx #$64
;;    stx $0722
;;    asl $06be,x
;;
;;    ;;sta zp,x
;;    ;;stx zp,y
;;    ;;sty zp,x
;;    lda #$40
;;    ldx #$e4
;;    ldy #$c5
;;    sta $a4, x
;;    stx $a4, y
;;    sty $a4, x
;;
;;    ;;branch page cross test.
;;    jmp bl_test0
;;
;;bl_test0:
;;    ldx #5
;;bl_test1:
;;    dex
;;    ;;forward branch
;;    bpl bl_test2
;;
;;    jmp bl_test2
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;
;;bl_test2:
;;    dex
;;    ;;backward branch
;;    bpl bl_test1
;;
;;    ;;test2
;;    ldx #5
;;bl_test3:
;;    dex
;;    bpl bl_test4
;;
;;    jmp bl_test4
;;
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;    .byte $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
;;
;;bl_test4:
;;    dex
;;    bpl bl_test3
;;
;;    ;;ora zp, x/abs, x/indir, y
;;    lda #$de
;;    ldx #$e4
;;    sta $a4
;;    ;c5|de=df
;;    lda #$c5
;;    ora $c0, x
;;
;;    lda #$75
;;    stx $0734
;;    ;75|e4=f5
;;    ora $0650, x
;;
;;    ldx #$c9
;;    stx $0825
;;    lda #$34
;;    sta $07
;;    lda #$07
;;    sta $08
;;    ldy #$f1
;;    ;page crossing
;;    ;07|c9=cf
;;    ora ($07), y
;;
;;    ;;php/plp test
;;    sec
;;    sei
;;    php
;;
;;    clc
;;    cli
;;    plp
;;
;;    ;;eor zp, x/abs, x/indir, y
;;    lda #$de
;;    ldx #$e4
;;    sta $a4
;;    ;c5^de=1b
;;    lda #$c5
;;    eor $c0, x
;;
;;    lda #$75
;;    stx $0734
;;    ;75^e4=91
;;    eor $0650, x
;;
;;    ldx #$07
;;    stx $0825
;;    lda #$34
;;    sta $07
;;    lda #$07
;;    sta $08
;;    ldy #$f1
;;    ;page crossing
;;    ;07^07=00
;;    eor ($07), y
;;
;;    ;;sbc zp, x/abs, x/indir, y
;;    lda #$de
;;    ldx #$e4
;;    sta $a4
;;    ;c5-de=-19 > e7
;;    lda #$c5
;;    sbc $c0, x
;;
;;    lda #$75
;;    stx $0734
;;    ;75-e4=-6f > 91
;;    sbc $0650, x
;;
;;    ldx #$07
;;    stx $07ef
;;    lda #$34
;;    sta $07
;;    lda #$07
;;    sta $08
;;    ldy #$bb
;;    ;07-07=00
;;    sbc ($07), y
;;
;;    ;;bvs/bvc test
;;    ;;-120=0x88
;;    lda #$88
;;bvs_test:
;;    sbc #$10
;;    bvs bvs_test
;;    
;;    lda #$5
;;bvc_test:
;;    sbc #$a
;;    bvc bvc_test
;;
;;    ;;;;vram access test...
;;	lda	#$00
;;	sta	$2001       ;;disable bg
;;
;;    LDA   #$1e
;;    STA   $2006
;;    LDA   #$c0
;;    STA   $2006       ;;;ppuaddr=1ec0
;;    LDA   #$03
;;    STA   $01
;;    LDY   #$00
;;    STY   $00
;;    LDA   $2007       ;;;;from here acc broke...
;;    LDA   $2007

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
    ;;;;test...
    STY   $0720
    LDY   #$80
    STY   $0721
    ASL   
    ASL   
    ASL   
    ASL   
    STA   $06a0
    DEC   $0730
    DEC   $0731
    DEC   $0732
    LDA   #$0b
    STA   $071e
    ;;JSR   $9c22
    LDA   $0750
    ;;JSR   $9c09
    AND   #$60
    ASL   
    ROL   
    ROL   
    ROL   
    STA   $074e
    ;;RTS   
    TAY   
    LDA   $0750
    AND   #$1f
    STA   $074f
    LDA   $9ce0, y
    CLC   
    ADC   $074f
    TAY   
    LDA   $9ce4, y
    STA   $e9
    LDA   $9d06, y
    STA   $ea
    LDY   $074e
    LDA   $9d28, y
    CLC   
    ADC   $074f
    TAY   
    LDA   $9d2c, y
    STA   $e7
    LDA   $9d4e, y
    STA   $e8
    LDY   #$00
    LDA   ($e7), y
    PHA   
    AND   #$07
    CMP   #$04
    ;;BCC   +5
    STA   $0741
    PLA   
    PHA   
    AND   #$38
    LSR   
    LSR   
    LSR   
    STA   $0710
    PLA   
    AND   #$c0
    CLC   
    ROL   
    ROL   
    ROL   
    STA   $0715
    INY   
    LDA   ($e7), y
    PHA   
    AND   #$0f
    STA   $0727
    PLA   
    PHA   
    AND   #$30
    LSR   
    LSR   
    LSR   
    LSR   
    STA   $0742
    PLA   
    AND   #$c0
    CLC   
    ROL   
    ROL   
    ROL   
    CMP   #$03
    ;;BNE   5
    STA   $0733
    LDA   $e7
    CLC   
    ADC   #$02
    STA   $e7
    LDA   $e8
    ADC   #$00
    STA   $e8
    ;;RTS   
    LDA   $076a
    ;;BNE   16
    LDA   $075f
    CMP   #$04
    ;BCC   12
    LDA   $075b
    ;;BEQ   5
    LDA   #$80
    STA   $fb
    LDA   #$01
    STA   $0774
    INC   $0772
    ;;RTS   
    LDA   $2002
    ;PLA   
    ORA   #$80
    STA   $2000
    rti

palettes:
	.byte	$0f, $00, $10, $20
	.byte	$0f, $06, $16, $26
	.byte	$0f, $08, $18, $28
	.byte	$0f, $0a, $1a, $2a
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
