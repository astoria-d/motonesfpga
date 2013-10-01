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


;;;;memory map
;;0000 - 00ff  zp: volatile though functions
;;0100 - 01ff  sp: preserved through functions   
;;0200 - 02ff  dma: dedicated for dma
;;0300 - 07ff  global: global variables.

.segment "STARTUP"
.proc	Reset

; interrupt off, initialize sp.
	sei
	ldx	#$ff
	txs

    jsr init_ppu
    jsr init_global

    lda ad_start_msg
    sta $00
    lda ad_start_msg+1
    sta $01
    jsr print_ln




@test_success:
    lda ad_test_done_msg
    sta $00
    lda ad_test_done_msg+1
    sta $01
    jsr print_ln
    jmp @test_done


@test_failure:
    lda ad_test_failed_msg
    sta $00
    lda ad_test_failed_msg+1
    sta $01
    jsr print_ln

@test_done:
    ;;show bg...
	lda	#$1e
	sta	$2001

    ;;;enable nmi
	lda	#$80
	sta	$2000

    ;;done...
    ;;infinite loop.
@mainloop:
	jmp	@mainloop
.endproc


nmi_test:
    rti

;;;param $00, $01 = msg addr.
;;;print_ln display message. 
;;;start position is the bottom of the screen.
.proc print_ln
    lda vram_current
    sta $2006
    lda vram_current + 1
    sta $2006

    ldy #$00
@msg_loop:
    lda ($00), y
    sta $2007
    beq @print_done
    iny
    jmp @msg_loop
@print_done:

    ;;clear remaining space.
@clr_line:
    tya
    and #$1f
    cmp #$1f
    beq @clr_done
    lda #$00
    sta $2007
    iny
    jmp @clr_line
@clr_done:

    ;;renew vram pos
    lda vram_current + 1
    sty vram_current + 1
    adc vram_current + 1
    sta vram_current + 1
    tax         ;; x = new vram_l
    lda vram_current
    bcc @no_carry
    clc
    adc #01     ;; a = new vram_h
    sta vram_current
@no_carry:

    cmp #$23
    bne @vpos_done

    txa 
    cmp #$c0
    bne @vpos_done
    ;;;if vram pos = 23c0. reset pos.
    lda #$20
    sta vram_current
    lda #$00
    sta vram_current + 1
@vpos_done:

    ;;scroll 1 line
    lda scroll_x
    sta $2005

    lda scroll_y
    clc
    adc #8
    cmp #240
    bne @scr_done
    lda #$0
@scr_done:
    sta scroll_y
    sta $2005

    rts
.endproc

.proc init_ppu
    ;ppu register initialize.
	lda	#$00
	sta	$2000
	sta	$2001

    ;;load palette.
	lda	#$3f
	sta	$2006
	lda	#$00
	sta	$2006

	ldx	#$00
	ldy	#$20
@copypal:
	lda	@palettes, x
	sta	$2007
	inx
	dey
	bne	@copypal
    rts

@palettes:
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

.endproc


.proc init_global
;;vram pos start from the bottom line.
    lda #$23
    sta vram_current
    lda #$a0
    sta vram_current + 1

    lda #$00
    sta scroll_x
    lda #232
    sta scroll_y
    rts

.endproc




;;;;string datas
ad_start_msg:
    .addr   start_msg
start_msg:
    .byte   "regression test start..."
    .byte   $00

ad_test_done_msg:
    .addr   test_done_msg
test_done_msg:
    .byte   "test succeeded..."
    .byte   $00

ad_test_failed_msg:
    .addr   test_failed_msg
test_failed_msg:
    .byte   "test failed!!!"
    .byte   $00


;;;;global variables.
.segment "BSS"
vram_current:
    .byte   $00
    .byte   $00
scroll_x:
    .byte   $00
scroll_y:
    .byte   $00


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
