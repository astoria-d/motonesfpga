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


.proc addr_test
    jmp @jmp_test1
    .byte   "*************"
    .byte   "0**"
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
    .byte   "***********"

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
    .byte   "****"
    .byte   "6**********"
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
    jsr status_test
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


.proc status_test
    lda ad_status_test
    sta $00
    lda ad_status_test+1
    sta $01
    jsr print_ln


;;bit7	N	ネガティブ	Aのbit7が1の時にセット
;;bit6	V	オーバーフロー	演算結果がオーバーフローを起こした時にセット
;;bit5	R	予約済み	常にセットされている
;;bit4	B	ブレークモード	BRK発生時にセット、IRQ発生時にクリア
;;bit3	D	デシマルモード	0:デフォルト、1:BCDモード (ファミコンでは未実装)
;;bit2	I	IRQ禁止	0:IRQ許可、1:IRQ禁止
;;bit1	Z	ゼロ	演算結果が0の時にセット
;;bit0	C	キャリー	キャリー発生時にセット

    ;;save status
    php

;;LDA
;;メモリからAにロードします。[N:0:0:0:0:0:Z:0]
    ;;set status
    lda #$00
    pha
    plp

    lda #$ea
    php
    pla
    and #$ef        ;;mask off brk bit...
    cmp #$a0
    beq :+
    jsr test_failure
:
    ;;set status
    lda #$00
    pha
    plp

    lda #$00
    php
    pla
    and #$ef        ;;mask off brk bit...
    cmp #$22
    beq :+
    jsr test_failure
:

;;LDX
;;メモリからXにロードします。[N:0:0:0:0:0:Z:0]
    ;;set status
    lda #00
    pha
    plp

    ldx #$a4
    php
    pla
    and #$ef        ;;mask off brk bit...
    cmp #$a0
    beq :+
    jsr test_failure
:

    lda #00
    pha
    plp

    ldx #$00
    php
    pla
    and #$ef        ;;mask off brk bit...
    cmp #$22
    beq :+
    jsr test_failure
:

;;LDY
;;メモリからYにロードします。[N:0:0:0:0:0:Z:0]
    ;;set status
    lda #00
    pha
    plp

    ldy #$2b
    php
    pla
    and #$ef        ;;mask off brk bit...
    cmp #$20
    beq :+
    jsr test_failure
:

    ;;set status
    lda #00
    pha
    plp

    ldy #$bb
    php
    pla
    and #$ef        ;;mask off brk bit...
    cmp #$a0
    beq :+
    jsr test_failure
:

    ;;set status
    lda #00
    pha
    plp

    ldy #$00
    php
    pla
    and #$ef        ;;mask off brk bit...
    cmp #$22
    beq :+
    jsr test_failure
:

;;STA
;;Aからメモリにストアします。[0:0:0:0:0:0:0:0]

    lda #$fb

    ;;set status
    lda #$c3
;;c3 is...1100 0011 = NV00 00ZC
    pha
    plp

;;sta test
    sta $501

    php
    pla
    and #$ef        ;;mask off brk bit...
    cmp #$e3
    beq :+
    jsr test_failure
:


;;STX
;;Xからメモリにストアします。[0:0:0:0:0:0:0:0]
    ldx #$fb

    ;;set status
    lda #$c3
    pha
    plp

    stx $50f

    php
    pla
    and #$ef        ;;mask off brk bit...
    cmp #$e3
    beq :+
    jsr test_failure
:


;;STY
;;Yからメモリにストアします。[0:0:0:0:0:0:0:0]
    ldy #$00

    ;;set status
    lda #$c3
    pha
    plp

    sty $510

    php
    pla
    and #$ef        ;;mask off brk bit...
    cmp #$e3
    beq :+
    jsr test_failure
:

;;TAX
;;AをXへコピーします。[N:0:0:0:0:0:Z:0]
    ;;set status
    lda #$c3
    pha
    plp

    tax

    php
    pla
    and #$ef        ;;mask off brk bit...
    cmp #$e1
    beq :+
    jsr test_failure
:

    ;;set status
    lda #$00
    pha
    plp

    tax

    php
    pla
    and #$ef        ;;mask off brk bit...
    cmp #$22
    beq :+
    jsr test_failure
:


;;TAY
;;AをYへコピーします。[N:0:0:0:0:0:Z:0]
    ;;set status
    lda #$c3
    pha
    plp

    tay

    php
    pla
    and #$ef        ;;mask off brk bit...
    cmp #$e1
    beq :+
    jsr test_failure
:

    cpy #$c3
    beq :+
    jsr test_failure
:

    ;;set status
    lda #$00
    pha
    plp

    tay

    php
    pla
    and #$ef        ;;mask off brk bit...
    cmp #$22
    beq :+
    jsr test_failure
:
:
    cpy #$00
    beq :+
    jsr test_failure
:

;;TSX
;;SをXへコピーします。[N:0:0:0:0:0:Z:0]
    ;;set status
    lda #$c3
    pha
    plp

    ;;;now sp = 0xfX place...
    tsx

    php
    pla
    and #$ef        ;;mask off brk bit...
    cmp #$e1
    beq :+
    jsr test_failure
:

    ;;save sp
    tsx
    txa
    tay     ;; now y has the old sp
    
    lda #$0
    tax
    txs
    
    ;;set status
    lda #$c3
    pha
    plp

    tsx

    php
    pla
    and #$ef        ;;mask off brk bit...
    cmp #$63
    beq :+
    jsr test_failure
:
    cpx #$00
    beq :+
    jsr test_failure
:

    ;;restore sp
    tya
    tax
    txs


;;TXA
;;XをAへコピーします。[N:0:0:0:0:0:Z:0]
    ldx #$59

    ;;set status
    lda #$c3
    pha
    plp

    txa

    php
    pla
    and #$ef        ;;mask off brk bit...
    cmp #$61
    beq :+
    jsr test_failure
:


    ldx #$ac

    ;;set status
    lda #$c3
    pha
    plp

    txa

    php
    pla
    and #$ef        ;;mask off brk bit...
    cmp #$e1
    beq :+
    jsr test_failure
:

    ldx #$00

    ;;set status
    lda #$c3
    pha
    plp

    txa

    php
    pla
    and #$ef        ;;mask off brk bit...
    cmp #$63
    beq :+
    jsr test_failure
:


;;TXS
;;XをSへコピーします。[N:0:0:0:0:0:Z:0]

    ;;save sp
    tsx
    txa
    tay     ;; now y has the old sp
    

    ldx #$0

    ;;set status
    lda #$c3
    pha
    plp

    txs ; x > s = 0

    php
    pla
    and #$ef        ;;mask off brk bit...
    cmp #$63
    beq :+

    ;;;;this is emulator's bug!!!! txs must set n and z bit, but emulator doesn't set...
;    jsr test_failure
:

    ldx #$9a

    ;;set status
    lda #$c3
    pha
    plp

    txs ; x > s = 9a

    php
    pla
    and #$ef        ;;mask off brk bit...
    cmp #$e1
    beq :+

    ;;;;this is emulator's bug!!!! txs must set n and z bit, but emulator doesn't set...
;    jsr test_failure
:

    ;;restore sp
    tya
    tax
    txs


;;
;;TYA
;;YをAへコピーします。[N:0:0:0:0:0:Z:0]

    ldy #$0

    ;;set status
    lda #$c3
    pha
    plp

    tya ; y > a = 0

    php
    pla
    and #$ef        ;;mask off brk bit...
    cmp #$63
    beq :+

    jsr test_failure
:

    ldy #$b5

    ;;set status
    lda #$c3
    pha
    plp

    tya ; y > a = b5

    php
    pla
    and #$ef        ;;mask off brk bit...
    cmp #$e1
    beq :+

    jsr test_failure
:


;;ADC
;;(A + メモリ + キャリーフラグ) を演算して結果をAへ返します。[N:V:0:0:0:0:Z:C]

    ;;set status
    lda #$c3
    pha
    plp

    ;;;n flag test
    ldy #$c0
    sty $50     ;;@50=c0
    clc
    lda #$30
    adc $50     ;;0+30+c0=f0

    php
    tax         ;;x=f0
    pla
    and #$ef        ;;mask off brk bit...
    cmp #$a0
    beq :+
    jsr test_failure
:
    cpx #$f0
    beq :+
    jsr test_failure
:

    ;;;c flag test
    ;;set status
    lda #$c3
    pha
    plp

    ldy #$ee
    sty $0550     ;;@0550=ee
    sec
    lda #$ad
    adc $0550     ;;ad+ee+1=19c

    php
    tax         ;;x=9c
    pla
    and #$ef        ;;mask off brk bit...
    cmp #$a1
    beq :+
    jsr test_failure
:
    cpx #$9c
    beq :+
    jsr test_failure
:

    ;;;z flag test
    ;;set status
    lda #$c3
    pha
    plp

    ldy #$ee
    sty $0551     ;;@0551=ee
    sec
    lda #$11
    adc $0550     ;;11+ee+1=0

    php
    tax         ;;x=0
    pla
    and #$ef        ;;mask off brk bit...
    cmp #$23
    beq :+
    jsr test_failure
:
    cpx #$0
    beq :+
    jsr test_failure
:

    ;;;v flag test
    ;;set status
    lda #$c3
    pha
    plp

    ldy #75
    sty $0552     ;;@0551=75
    sec
    lda #100
    adc $0552     ;;75+100+1=176

    php
    tax         ;;x=176
    pla
    and #$ef        ;;mask off brk bit...
    cmp #$e0
    beq :+
    jsr test_failure
:
    cpx #176
    beq :+
    jsr test_failure
:

;;AND
;;Aとメモリを論理AND演算して結果をAへ返します。[N:0:0:0:0:0:Z:0]

    ;;set status
    lda #$c3
    pha
    plp

    ldy #$8e
    sty $e4     ;;@e4=c0

    lda #$b3
    ldx #$30
    and $b4,x     ;;b3 & 8e=82

    php
    tax         ;;x=82
    pla
    and #$ef        ;;mask off brk bit...
    cmp #$e1
    beq :+
    jsr test_failure
:
    cpx #$82
    beq :+
    jsr test_failure
:

    ;;set status
    lda #$c3
    pha
    plp

    ldy #$7e
    sty $04e4     ;;@04e4=7e

    lda #$81
    ldx #$30
    and $04b4,x     ;;81 & 7e=0

    php
    tax         ;;x=0
    pla
    and #$ef        ;;mask off brk bit...
    cmp #$63
    beq :+
    jsr test_failure
:
    cpx #$0
    beq :+
    jsr test_failure
:

;;ASL
;;Aまたはメモリを左へシフトします。[N:0:0:0:0:0:Z:C]

    ;;set status
    lda #$c3
    pha
    plp

    ;;c bit test
    lda #$b3
    asl         ;; b3 << 1 = 166

    php
    tax         ;;x=66
    pla
    and #$ef        ;;mask off brk bit...
    cmp #$61
    beq :+
    jsr test_failure
:
    cpx #$66
    beq :+
    jsr test_failure
:

    ;;set status
    lda #$c3
    pha
    plp

    ;;n bit test
    lda #$61
    sta $7b
    ldx #$ce
    asl $ad,x       ;;61 << 1 = c2

    php
    pla
    and #$ef        ;;mask off brk bit...
    cmp #$e0
    beq :+
    jsr test_failure
:
    ldy $ad,x
    cpy #$c2
    beq :+
    jsr test_failure
:

    ;;set status
    lda #$c3
    pha
    plp

    ;;z bit test
    lda #$80
    sta $e5
    asl $e5       ;;80 << 1 = 0

    php
    pla
    and #$ef        ;;mask off brk bit...
    cmp #$63
    beq :+
    jsr test_failure
:
    ldy $e5
    cpy #$0
    beq :+
    jsr test_failure
:

;;BIT
;;Aとメモリをビット比較演算します。[N:V:0:0:0:0:Z:0]

    ;;set status
    lda #$c3
    pha
    plp

    ;;z bit test
    lda #$0
    sta $e5
    lda #$01
    bit $e5

    php
    pla
    and #$ef        ;;mask off brk bit...
    cmp #$23
    beq :+
    jsr test_failure
:

    ;;set status
    lda #$c3
    pha
    plp

    ;;n/v bit test
    lda #$4a
    sta $0440
    lda #$01
    bit $0440

    php
    pla
    and #$ef        ;;mask off brk bit...
    cmp #$63
    beq :+
    jsr test_failure
:


;;CMP
;;Aとメモリを比較演算します。[N:0:0:0:0:0:Z:C]

    ;;set status
    lda #$c3
    pha
    plp

    ;;c bit test
    lda #$91
    sta $04e5   ;;@04e5 = 91
    lda #$e5    ;; e5 - 91 = 54
    ldy #$f2
    cmp $03f3, y

    php
    pla
    and #$ef        ;;mask off brk bit...
    cmp #$61        ;;c is set when acc >= mem.
    beq :+
    jsr test_failure
:

    ;;set status
    lda #$c3
    pha
    plp

    ;;z/c bit test
    ldx #$e5
    stx $04e5   ;;@04e5 = 91
    lda #$e5
    ldy #$f2
    cmp $03f3, y

    php
    pla
    and #$ef        ;;mask off brk bit...
    cmp #$63        ;;c is set when acc >= mem.
    beq :+
    jsr test_failure
:

    ;;set status
    lda #$c3
    pha
    plp

    ;;n bit test
    ldx #$7e
    stx $05d7   ;;@05d7 = 7e

    lda #$e5
    sta $10
    lda #$04
    sta $11
    ldy #$f2    ;;04e5+f2=05d7
    lda #$45    ;;45-7e=c7
    cmp ($10), y

    php
    pla
    and #$ef        ;;mask off brk bit...
    cmp #$e0        ;;c is set when acc >= mem.
    beq :+
    jsr test_failure
:


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;merge failure...
;;;;;;;;;;;;;;;;;;;made duplicated tests....

;;TXS
;;XをSへコピーします。[N:0:0:0:0:0:Z:0]

    tsx
    stx $50     ;;sp is stored @0x50
    
    ldx #$d9

    ;;set status
    lda #$c3
    pha
    plp

    txs

    php
    pla
    and #$ef        ;;mask off brk bit...
    cmp #$e1        ;;;emulator bug!!! status reg is not reflected....
    beq :+
;    jsr test_failure
:

    ldx #$00

    ;;set status
    lda #$c3
    pha
    plp

    txs

    php
    pla
    and #$ef        ;;mask off brk bit...
    cmp #$63        ;;;emulator bug!!! status reg is not reflected....
    beq :+
;    jsr test_failure
:

    ldx $50
    txs     ;;sp is restored


;;TYA
;;YをAへコピーします。[N:0:0:0:0:0:Z:0]

    ldy #$00
    lda #$0b

    ;;set status
    lda #$c3
    pha
    plp

    tya

    php
    pla
    and #$ef        ;;mask off brk bit...
    cmp #$63
    beq :+
    jsr test_failure
:
    tya
    cmp #0
    beq :+
    jsr test_failure
:

    ldy #$b0
    lda #$00

    ;;set status
    lda #$c3
    pha
    plp

    tya

    php
    pla
    and #$ef        ;;mask off brk bit...
    cmp #$e1
    beq :+
    jsr test_failure
:
    tya
    cmp #$b0
    beq :+
    jsr test_failure
:

;;ADC
;;(A + メモリ + キャリーフラグ) を演算して結果をAへ返します。[N:V:0:0:0:0:Z:C]

    lda #$76
    sta $73
    lda #$05
    sta $72     ;;;@72=0576

    lda #$91
    sta $0576     ;;;@0576=91

    lda #$99
    ldx #$a3

    ;;set status
    lda #$c3
    pha
    plp

    ;;91+99=12a
    adc ($cf, x)        ;;cf+a3=72

    php
    tax     ;;x=2a
    pla
    and #$ef        ;;mask off brk bit...
    cmp #$a1
    beq :+
    jsr test_failure
:
    cpx #$2a
    beq :+
    jsr test_failure
:


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;ok until above....
;;;;more tests with various addr mode and status bit combination...



;;CPX
;;Xとメモリを比較演算します。[N:0:0:0:0:0:Z:C]
;;
;;CPY
;;Yとメモリを比較演算します。[N:0:0:0:0:0:Z:C]
;;
;;DEC
;;メモリをデクリメントします。[N:0:0:0:0:0:Z:0]
;;
;;DEX
;;Xをデクリメントします。[N:0:0:0:0:0:Z:0]
;;
;;DEY
;;Yをデクリメントします。[N:0:0:0:0:0:Z:0]
;;
;;EOR
;;Aとメモリを論理XOR演算して結果をAへ返します。[N:0:0:0:0:0:Z:0]
;;
;;INC
;;メモリをインクリメントします。[N:0:0:0:0:0:Z:0]
;;
;;INX
;;Xをインクリメントします。[N:0:0:0:0:0:Z:0]
;;
;;INY
;;Yをインクリメントします。[N:0:0:0:0:0:Z:0]
;;
;;LSR
;;Aまたはメモリを右へシフトします。[N:0:0:0:0:0:Z:C]
;;
;;ORA
;;Aとメモリを論理OR演算して結果をAへ返します。[N:0:0:0:0:0:Z:0]
;;
;;ROL
;;Aまたはメモリを左へローテートします。[N:0:0:0:0:0:Z:C]
;;
;;ROR
;;Aまたはメモリを右へローテートします。[N:0:0:0:0:0:Z:C]
;;
;;SBC
;;(A - メモリ - キャリーフラグの反転) を演算して結果をAへ返します。[N:V:0:0:0:0:Z:C]
;;
;;PHA
;;Aをスタックにプッシュダウンします。[0:0:0:0:0:0:0:0]
;;
;;PHP
;;Pをスタックにプッシュダウンします。[0:0:0:0:0:0:0:0]
;;
;;PLA
;;スタックからAにポップアップします。[N:0:0:0:0:0:Z:0]
;;
;;PLP
;;スタックからPにポップアップします。[N:V:R:B:D:I:Z:C]
;;
;;JMP
;;アドレスへジャンプします。[0:0:0:0:0:0:0:0]
;;
;;JSR
;;サブルーチンを呼び出します。[0:0:0:0:0:0:0:0]
;;
;;RTS
;;サブルーチンから復帰します。[0:0:0:0:0:0:0:0]
;;
;;RTI
;;割り込みルーチンから復帰します。[N:V:R:B:D:I:Z:C]
;;
;;BCC
;;キャリーフラグがクリアされている時にブランチします。[0:0:0:0:0:0:0:0]
;;
;;BCS
;;キャリーフラグがセットされている時にブランチします。[0:0:0:0:0:0:0:0]
;;
;;BEQ
;;ゼロフラグがセットされている時にブランチします。[0:0:0:0:0:0:0:0]
;;
;;BMI
;;ネガティブフラグがセットされている時にブランチします。[0:0:0:0:0:0:0:0]
;;
;;BNE
;;ゼロフラグがクリアされている時にブランチします。[0:0:0:0:0:0:0:0]
;;
;;BPL
;;ネガティブフラグがクリアされている時にブランチします。[0:0:0:0:0:0:0:0]
;;
;;BVC
;;オーバーフローフラグがクリアされている時にブランチします。[0:0:0:0:0:0:0:0]
;;
;;BVS
;;オーバーフローフラグがセットされている時にブランチします。[0:0:0:0:0:0:0:0]
;;
;;CLC
;;キャリーフラグをクリアします。[0:0:0:0:0:0:0:C]
;;
;;CLD
;;BCDモードから通常モードに戻ります。ファミコンでは実装されていません。[0:0:0:0:D:0:0:0]
;;
;;
;;BCDモードから通常モードに戻ります。ファミコンでは実装されていません。[0:0:0:0:D:0:0:0]
;;
;;CLI
;;IRQ割り込みを許可します。[0:0:0:0:0:I:0:0]
;;
;;CLV
;;オーバーフローフラグをクリアします。[0:V:0:0:0:0:0:0]
;;
;;SEC
;;キャリーフラグをセットします。[0:0:0:0:0:0:0:C]
;;
;;SED
;;BCDモードに設定します。ファミコンでは実装されていません。[0:0:0:0:D:0:0:0]
;;
;;SEI
;;IRQ割り込みを禁止します。[0:0:0:0:0:I:0:0]


    ;;restore status
    plp

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

    ;;cld/sed(bcd mode) not supported...

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

ad_status_test:
    .addr   :+
:
    .byte   "status test..."
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
.segment "VECINFO_8k"
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
