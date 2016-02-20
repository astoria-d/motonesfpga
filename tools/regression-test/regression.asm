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

    jsr init_global
    jsr init_ppu

;;address specific test comes first...
    jsr addr_test

    lda ad_start_msg
    sta $00
    lda ad_start_msg+1
    sta $01
    jsr print_ln
    jsr print_ln
    jsr print_ln
    jsr print_ln
    jsr print_ln
    jsr print_ln


;;;;;following tests all ok
;    jsr single_inst_test
;    a2_inst_test
;    a3_inst_test
;    a4_inst_test
;    a5_inst_test

    ;;test start...
    jsr single_inst_test
    jsr a2_inst_test
    jsr a3_inst_test
    jsr a4_inst_test
    jsr a5_inst_test
    jsr ppu_test

.endproc


    ;;fall through from the above func 
    ;;or jump into from the other failed func.

    ;;test finished...
test_success:
    lda ad_test_done_msg
    sta $00
    lda ad_test_done_msg+1
    sta $01
    jsr print_ln
    jmp test_done

test_failure:
    lda use_ppu
    bne :+
    lda #$00
    ;;;generate invalid opcode error.
    jsr $00
:
    lda ad_test_failed_msg
    sta $00
    lda ad_test_failed_msg+1
    sta $01
    jsr print_ln

test_done:

;;;set image attribute
	lda	#$23
	sta	$2006
	lda	#$c1
	sta	$2006
;;attr=11011000
	lda	#$d8
	sta	$2007

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


nmi_test:
    rti

.proc addr_test
    nop
    nop
    jmp @jmp_test1
    .byte   "0***************"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"
    .byte   "**********"

@jmp_ret1:
    nop
    ;;page cross at jmp cycle #0
    jmp @jmp_test2

    .byte   "**************"
    .byte   "1***************"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"
    .byte   "*************"

@jmp_ret2:
    ;;page cross at the jmp cycle #2
    nop
    jmp @jmp_test3
    .byte   "***************"
    .byte   "2***********"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"

@jmp_ret3:
    ;;page cross at the jmp cycle #1
    nop
    jmp @jmp_test4
    .byte   "3***********"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"

    ;;a1 instruction
    ;;page cross at cycle #0
@jmp_ret4:
    ldx #$5f
    nop
    inx
    cpx #$60
    beq :+
    jsr test_failure
:

    jmp @jmp_test5
    .byte   "******"
    .byte   "4***************"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"
    .byte   "***************"
@jmp_ret5:
    ;;a1 instruction
    ;;page cross at cycle #0
    nop
    inx
    cpx #$61
    beq :+
    jsr test_failure
:

    jmp @jmp_test6
    .byte   "*****"
    .byte   "5***********"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"
@jmp_ret6:
    ;;a2 instruction
    ;;page cross at cycle #0
    sec
    lda #$3b
    nop
    adc #$9b        ;;;3b+9b+1=d7
    cmp #$d7
    beq :+
    jsr test_failure
:
    jmp @jmp_test7
    .byte   "*****"
    .byte   "6*********"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"
@jmp_ret7:
    ;;a2 instruction
    ;;page cross at cycle #1
    sec
    lda #$77
    nop
    ora #$f0        ;;;3b+9b+1=d7
    cmp #$f7
    beq :+
    jsr test_failure
:
    jmp @jmp_test8
    .byte   "*****"
    .byte   "7***"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"
    .byte   "****************"
@jmp_ret8:
    ;;a2 instruction
    ;;page cross at cycle #2
    sec
    lda #$c1
    sta $0620       ;;@0620=c1
    lda #$91
    nop
    sbc $0620        ;;;91-c1=d0
    cmp #$d0
    beq :+
    jsr test_failure
:



    jmp @jmp_test_done

@jmp_test1:
    jmp @jmp_ret1
@jmp_test2:
    jmp @jmp_ret2
@jmp_test3:
    jmp @jmp_ret3
@jmp_test4:
    jmp @jmp_ret4
@jmp_test5:
    jmp @jmp_ret5
@jmp_test6:
    jmp @jmp_ret6
@jmp_test7:
    jmp @jmp_ret7
@jmp_test8:
    jmp @jmp_ret8

@jmp_test_done:
    lda ad_addr_test
    sta $00
    lda ad_addr_test+1
    sta $01
    jsr print_ln

    rts
.endproc


.proc ppu_test
    jsr check_ppu
    lda ad_ppu_test
    sta $00
    lda ad_ppu_test+1
    sta $01
    jsr print_ln

    rts
.endproc


;;a5 instructions:
;;bcc   brk     php
;;bcs   bvc     pla
;;beq   bvs     plp
;;bmi   jmp     rti
;;bne   jsr     rts
;;bpl   pha
.proc a5_inst_test
    lda ad_a5_test
    sta $00
    lda ad_a5_test+1
    sta $01
    jsr print_ln

    ;;branch test
    clc
    bcc :+
    jsr test_failure
:
    sec
    bcs :+
    jsr test_failure
:
    lda #$00
    beq :+
    jsr test_failure
:
    clc
    sbc #$05
    bmi :+
    jsr test_failure
:
    bne :+
    jsr test_failure
:
    clc
    adc #$06
    bpl :+
    jsr test_failure
:
    sec
    lda #$92    ;;-110
    sbc #$46    ;;70, -110 - 70 = 4c(76)
    bvs :+
    jsr test_failure
:
    sec
    lda #$92    ;;-110
    sbc #$12    ;;18, -110 - 18 = -128
    bvc :+
    jsr test_failure
:

    lda #$00
    ldx #00
    beq @fwd            ;;<<<ok!!!!
    ;;forward page crossing branch
@bwd:
    jmp @fwd
.repeat 120
    nop
.endrepeat
@fwd:
    inx
    cpx #$01
    beq @bwd

    ;;repeat the same test 
    ;;(in case the above test doesn't go across the page)
    lda #$00
    ldx #00
    beq @fwd2
    ;;forward page crossing branch
@bwd2:
    jmp @fwd2
.repeat 120
    nop
.endrepeat
@fwd2:
    inx
    cpx #$01
    beq @bwd2

    ;jmp, jsr, rts test...
    clc
    lda #100
    jsr @jsr_test1
    cmp #200
    beq @jsr_ok
    jsr test_failure
@jsr_test1:
    jsr @jsr_test2
    rts
@jsr_test2:
    jsr @jsr_test3
    rts
@jsr_test3:
    adc #100
    rts
@jsr_ok:

    sec
    lda #200
    jmp @jmp_test1
@jmp_test3:
    adc #50
    jmp @jmp_test_done
@jmp_test2:
    jmp @jmp_test3
    adc #50
@jmp_test1:
    jmp @jmp_test2
    adc #50
@jmp_test_done:
    cmp #251
    beq :+
    jsr test_failure
:

    sec
    lda #195

    ;;jmp (ind) test
    jmp (@ind1)

@ind1:
.addr @jmp_addr1
@ind2:
.addr @jmp_addr2
@ind3:
.addr @jmp_addr3
@ind4:
.addr @jmp_addr_done

@jmp_addr2:
    jmp (@ind3)
    adc #230
@jmp_addr3:
    adc #230
    jmp (@ind4)
@jmp_addr1:
    jmp (@ind2)
    adc #230

@jmp_addr_done:
    cmp #170
    beq :+
    jsr test_failure
:

    ;;pha,php,pla,plp test
    lda #35
    pha
    lda #70
    pha
    lda #110
    pha

    sec
    php
    sei
    php
    clc
    php
    lda #$ff
    php
    lda #$00
    php
    lda #$ff

    plp
    beq :+
    jsr test_failure
:
    plp
    bmi :+
    jsr test_failure
:
    plp
    bcc :+
    jsr test_failure
:
    plp
    plp
    bcs :+
    jsr test_failure
:
    cli
    pla
    cmp #110
    beq :+
    jsr test_failure
:
    pla
    cmp #70
    beq :+
    jsr test_failure
:
    pla
    cmp #35
    beq :+
    jsr test_failure
:


    rts
.endproc

;;a4 instructions:
;;asl   lsr
;;dec   rol
;;inc   ror
.proc a4_inst_test
    lda ad_a4_test
    sta $00
    lda ad_a4_test+1
    sta $01
    jsr print_ln

    lda #$39
    sta $6b
    lda #$a1
    sta $04cc
    lda #$9f
    sta $ff

    ldx #$fd

    ;;zp, abs, absx, zpx
    asl $6b         ;@6b=39 > 72            <<ok...
    lda $6b
    cmp #$72
    beq :+
    jsr test_failure
:

    dec $04cc       ;@4cc=a1 > a0           <<ok????
    lda $04cc
    cmp #$a0
    beq :+
    jsr test_failure
:

    lsr $03cf, x    ;@4cc=a0 > 50
    lda $04cc
    cmp #$50
    beq :+
    jsr test_failure
:

    inc $02, x      ;@ff=9f > a0            <<ok....
    lda $ff
    cmp #$a0
    beq :+
    jsr test_failure
:

    clc
    rol $02, x      ;@ff=a0 > 40
    rol $02, x      ;@ff=40 > 81
    lda $ff
    cmp #$81
    beq :+
    jsr test_failure
:

    sec
    ror $02, x      ;@ff=81 > c0
    ror $02, x      ;@ff=40 > e0
    lda $ff
    cmp #$e0
    beq :+
    jsr test_failure
:

    rts
.endproc

;;a3 instructions:
;;sta   stx     sty
.proc a3_inst_test
    lda ad_a3_test
    sta $00
    lda ad_a3_test+1
    sta $01
    jsr print_ln

    lda #$78
    sta $a1
    lda #$05
    sta $a2

    lda #$b7
    ldx #$e1
    ldy #$8a

    ;;zp, abs, absx, zpx, (ind),y
    ;;(indir, x) is ommited.
    sta $a9         ;@a9=b7
    stx $0a99       ;@a99=e1
    sta $0d80, x    ;@e61=b7
    sty $1f, x      ;@00=8a
    sta ($a1), y    ;@602=b7

    cmp $a9
    beq :+
    jsr test_failure
:
    cpx $0a99
    beq :+
    jsr test_failure
:
    cmp $0e61
    beq :+
    jsr test_failure
:
    cpy $00
    beq :+
    jsr test_failure
:
    cmp $0602
    beq :+
    jsr test_failure
:

    rts
.endproc

;;a2 instructions:
;;adc   cmp     eor     ldy
;;and   cpx     lda     ora
;;bit   cpy     ldx     sbc
.proc a2_inst_test
    lda ad_a2_test
    sta $00
    lda ad_a2_test+1
    sta $01
    jsr print_ln

    ;;a2 addr mode test
    ;;immediate
    clc
    lda #$0d
    adc #$fa
    cmp #$07
    beq :+
    jsr test_failure
:
    ;;zp addr mode
    lda #$37
    sta $5e     ;@5e = 37
    lda #$c9
    sta $71     ;@71 = c9
    lda #$b6
    and $5e
    ;;b6 and 37=36
    bit $71 ;;36 bit c9 = 00.
    beq :+
    jsr test_failure
:

    ;;abs addr mode.
    lda #$3b
    sta $0421   ;;@0421 = 3b
    lda #$d7
    sta $051b   ;;@051b = d7
    lda #$eb
    sta $06cc   ;;@06cc = eb
    ldx $0421
    inx
    txa     ;;a=3c
    eor $051b   ;;3c eor d7 = eb
    tay
    cpy $06cc
    beq :+
    jsr test_failure
:

    ;;abs,x/y test...
    ldx #$17
    ldy #$a1
    lda #$2f
    sta $359        ;;@359=2f
    lda #$90
    sta $0190, y    ;;@231=90                          << ok!!!
    txa
    ora $0190, y    ;;@231(page cross), 90 | 17 = 97   << ok!
    sec
    sbc $0342, x    ;;@359, 97-2f=68
    tay
    cpy #$68
    beq :+
    jsr test_failure
:

    ;;zp,xy test
    ldx #$cd
    lda #$f1
    sta $35     ;;@35=f1
    lda #$ac
    sta $bc     ;;@bc=ac

    lda #$8d
    and $68,x   ;;@35, 8d & f1=81
    ldy #$9a
    eor $22,y   ;;@bc, ac^81=2d
    tax
    cpx #$2d
    beq :+
    jsr test_failure
:

    ;;(ind),y test...
    lda #$38
    sta $90         ;@90=38
    lda #$08
    sta $91         ;@91=08, @0838+ca=0902
    lda #$d9
    sta $0902       ;@0902=d9
    lda #$0a
    ldy #$ca
    clc
    adc ($90),y      ;@0902, 0a+d9=e3               << ok!!!
    cmp #$e3
    beq :+
    jsr test_failure
:
    
    ;;a.2.4 indirect,x is not implemented...


    rts

.endproc

;;;single byte instructions.
.proc single_inst_test
    lda ad_single_test
    sta $00
    lda ad_single_test+1
    sta $01
    jsr print_ln

    ;;asl test
    lda #$80
    clc
    asl
    beq :+
    jsr test_failure
:
    bcs :+
    jsr test_failure
:
    bpl :+
    jsr test_failure
:
    asl
    beq :+
    jsr test_failure
:
    bcc :+
    jsr test_failure
:
    bpl :+
    jsr test_failure
:
    lda #$40
    asl
    bne :+
    jsr test_failure
:
    bcc :+
    jsr test_failure
:
    bmi :+
    jsr test_failure
:
    cmp #$80
    beq :+
    jsr test_failure
:
    lda #$a5
    asl
    cmp #$4a
    beq :+
    jsr test_failure
:
    asl
    cmp #$94
    beq :+
    jsr test_failure
:

    ;;clc test
;;-- SR Flags (bit 7 to bit 0):
;;--  7   N   ....    Negative
;;--  6   V   ....    Overflow
;;--  5   -   ....    ignored
;;--  4   B   ....    Break
;;--  3   D   ....    Decimal (use BCD for arithmetics)
;;--  2   I   ....    Interrupt (IRQ disable)
;;--  1   Z   ....    Zero
;;--  0   C   ....    Carry

    lda #$01
    ;;save status
    php
    ;;load carry flag.
    pha
    plp
    bcs :+
    jsr test_failure
:
    clc
    bcc :+
    jsr test_failure
:
    ;;restore status
    plp

    ;;clv test
    lda #$40
    ;;save status
    php
    ;;load v flag.
    pha
    plp
    bvs :+
    jsr test_failure
:
    clv
    bvc :+
    jsr test_failure
:
    ;;restore status
    plp


    ;;;;;dex test
    ldx #$03
    dex
    bne :+
    jsr test_failure
:
    cpx #$02
    beq :+
    jsr test_failure
:
    bpl :+
    jsr test_failure
:
    dex
    bne :+
    jsr test_failure
:
    cpx #$01
    beq :+
    jsr test_failure
:
    bpl :+
    jsr test_failure
:
    dex
    beq :+
    jsr test_failure
:
    cpx #$00
    beq :+
    jsr test_failure
:
    bpl :+
    jsr test_failure
:
    dex
    bne :+
    jsr test_failure
:
    bmi :+
    jsr test_failure
:
    cpx #$ff
    beq :+
    jsr test_failure
:
    ldx #$80
    bmi :+
    jsr test_failure
:
    dex
    bpl :+
    jsr test_failure
:
    cpx #$7f
    beq :+
    jsr test_failure
:

    ;;;dey test
    ldy #$50
    dey
    cpy #$4f
    beq :+
    jsr test_failure
:
    dey
    cpy #$4e
    beq :+
    jsr test_failure
:
    ;;inx/iny test
    iny
    cpy #$4f
    beq :+
    jsr test_failure
:
    inx
    cpx #$80
    beq :+
    jsr test_failure
:


    ;;;lsr test
    lda #$01
    clc
    lsr
    beq :+
    jsr test_failure
:
    bcs :+
    jsr test_failure
:
    lsr
    beq :+
    jsr test_failure
:
    bcc :+
    jsr test_failure
:
    lda #$5a
    lsr
    cmp #$2d
    beq :+
    jsr test_failure
:

    ;;;ror/rol test
    lda #$a5
    sec
    ror
    cmp #$d2
    beq :+
    jsr test_failure
:
    ror
    bcc :+
    jsr test_failure
:
    cmp #$e9
    beq :+
    jsr test_failure
:
    clc
    rol
    rol
    cmp #$a5
    beq :+
    jsr test_failure
:
    bcs :+
    jsr test_failure
:

    ;;sec/sei/cli test
    ;;save status
    php
    ;;load carry flag.
    lda #$00
    pha
    plp
    bcc :+
    jsr test_failure
:
    sec
    bcs :+
    jsr test_failure
:
    sei
    php
    pla
    and #$04
    bne :+
    jsr test_failure
:
    cli
    php
    pla
    and #$04
    beq :+
    jsr test_failure
:
    ;;restore status
    plp

    ;;tax/tay/txa/tya test
    lda #$01
    tax
    bpl :+
    jsr test_failure
:
    bne :+
    jsr test_failure
:
    cpx #$01
    beq :+
    jsr test_failure
:
    dex
    txa
    bpl :+
    jsr test_failure
:
    beq :+
    jsr test_failure
:
    lda #$01
    tay
    iny
    iny
    tya

    cpy #$03
    beq :+
    jsr test_failure
:

    ;;;txs/tsx test...
    tsx
    stx $00 ;;;save sp

    ldx #$30
    txs
    lda #$dd
    pha         ;;0130 = dd, sp=012f
    tsx
    cpx #$2f
    beq :+
    jsr test_failure
:
    ldx $00
    txs     ;;restore sp
    ;;check 0130 value
    lda #$ee
    lda $0130
    cmp #$dd
    beq :+
    jsr test_failure
:

    ;;;;jsr test_failure

    ;;;single byte instruction test done.
    rts
.endproc

;;;param $00, $01 = msg addr.
;;;print_ln display message. 
;;;start position is the bottom of the screen.
.proc print_ln
    jsr check_ppu
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

;;    ;;scroll 1 line
;;    lda scroll_x
;;    sta $2005
;;
;;    lda scroll_y
;;    clc
;;    adc #8
;;    cmp #240
;;    bne @scr_done
;;    lda #$0
;;@scr_done:
;;    sta scroll_y
;;    sta $2005
;;
    rts
.endproc

;;check_ppu exists caller's function if use_ppu flag is off
.proc check_ppu
    lda use_ppu
    bne @use_ppu_ret
    ;;pop caller's return addr
    pla
    pla
@use_ppu_ret:
    rts
.endproc

;;ppu initialize
.proc init_ppu
    jsr check_ppu
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

;;initialize bss segment datas
.proc init_global
;;ppu test flag
    lda use_ppu
    beq @ppu_skip

;;vram pos start from the top left.
;;(pos 0,0 is sprite hit point.)
    lda #$20
    sta vram_current
    lda #$01
    sta vram_current + 1

    lda #$00
    sta scroll_x
;    lda #232
    lda #$00
    sta scroll_y
@ppu_skip:

    rts

.endproc



;;;;string datas
ad_start_msg:
    .addr   :+
:
    .byte   "regression test start..."
    .byte   $00

ad_test_done_msg:
    .addr   :+
:
    .byte   "test succeeded..."
    .byte   $00

ad_test_failed_msg:
    .addr   :+
:
    .byte   "test failed!!!"
    .byte   $00

ad_addr_test:
    .addr   :+
:
    .byte   "address test..."
    .byte   $00

ad_ppu_test:
    .addr   :+
:
    .byte   "ppu inst test..."
    .byte   $00

ad_a5_test:
    .addr   :+
:
    .byte   "a5 inst test..."
    .byte   $00

ad_a4_test:
    .addr   :+
:
    .byte   "a4 inst test..."
    .byte   $00

ad_a3_test:
    .addr   :+
:
    .byte   "a3 inst test..."
    .byte   $00

ad_a2_test:
    .addr   :+
:
    .byte   "a2 inst test..."
    .byte   $00

ad_single_test:
    .addr   :+
:
    .byte   "single byte inst test..."
    .byte   $00

;;;read only global datas
use_ppu:
    .byte   $01

;;;;r/w global variables.
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
