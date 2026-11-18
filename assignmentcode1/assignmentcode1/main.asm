; ============================================================
; TRAFFIC LIGHT CONTROLLER
; ATmega328P / Arduino UNO
;
; Converted from Arduino C++ program
; Clock: 16 MHz
; ============================================================

.include "m328pdef.inc"

; ============================================================
; REGISTER DEFINITIONS
; ============================================================

.def temp       = r16
.def temp2      = r17
.def temp3      = r18
.def counter    = r19
.def digit      = r20

; ============================================================
; SRAM VARIABLES
; ============================================================

.dseg
pedRequest:
    .byte 1
ms_low:
    .byte 1
ms_mid:
    .byte 1
ms_high:
    .byte 1
ms_top:
    .byte 1

.cseg

; ============================================================
; INTERRUPT VECTOR TABLE
; ============================================================
.org 0x0000
    rjmp RESET
.org INT0addr
    rjmp INT0_ISR
.org OC1Aaddr
    rjmp TIMER1_COMPA_ISR

; ============================================================
; RESET & CONFIGURATION
; ============================================================
RESET:
    ; Initialize Stack Pointer
    ldi temp, high(RAMEND)
    out SPH, temp
    ldi temp, low(RAMEND)
    out SPL, temp

    ; PORT B (Traffic Lights)
    ldi temp, 0b00111111
    out DDRB, temp
    ldi temp, 0
    out PORTB, temp

    ; PORT D (7-Seg & Button)
    ldi temp, 0b11111000
    out DDRD, temp
    ldi temp, (1<<PD2)   ; Enable pull-up on PD2
    out PORTD, temp

    ; PORT C (7-Seg & Night Switch)
    ldi temp, 0b00000011
    out DDRC, temp
    ldi temp, (1<<PC2)   ; Enable pull-up on PC2
    out PORTC, temp

    ; Initialize Variables
    ldi temp, 0
    sts pedRequest, temp
    sts ms_low, temp
    sts ms_mid, temp
    sts ms_high, temp
    sts ms_top, temp

    ; Timer1 (1ms tick)
    ldi temp, high(249)
    sts OCR1AH, temp
    ldi temp, low(249)
    sts OCR1AL, temp
    ldi temp, (1<<WGM12)
    sts TCCR1B, temp
    ldi temp, (1<<WGM12)|(1<<CS11)|(1<<CS10)
    sts TCCR1B, temp
    ldi temp, (1<<OCIE1A)
    sts TIMSK1, temp

    ; INT0 Configuration
    ldi temp, (1<<ISC01)
    sts EICRA, temp
    ldi temp, (1<<INT0)
    sts EIMSK, temp

    sei
    rcall CLEAR_DISPLAY

; ============================================================
; MAIN LOOP
; ============================================================
MAIN_LOOP:
    rcall IS_NIGHT
    tst temp
    brne NIGHT_MODE

PHASE1:
    ldi temp, (1<<PB3)|(1<<PB2)
    out PORTB, temp
    ldi r24, low(3000)
    ldi r25, high(3000)
    rcall SMART_DELAY
    tst temp
    brne MAIN_LOOP

PHASE2:
    ldi temp, (1<<PB5)|(1<<PB2)
    out PORTB, temp
    ldi r24, low(1000)
    ldi r25, high(1000)
    rcall SMART_DELAY
    tst temp
    brne MAIN_LOOP
    rcall CHECK_PEDESTRIAN

PHASE3:
    ldi temp, (1<<PB5)|(1<<PB1)
    out PORTB, temp
    ldi r24, low(1000)
    ldi r25, high(1000)
    rcall SMART_DELAY
    tst temp
    brne MAIN_LOOP

PHASE4:
    ldi temp, (1<<PB5)|(1<<PB0)
    out PORTB, temp
    ldi r24, low(3000)
    ldi r25, high(3000)
    rcall SMART_DELAY
    tst temp
    brne MAIN_LOOP

PHASE5:
    ldi temp, (1<<PB5)|(1<<PB2)
    out PORTB, temp
    ldi r24, low(1000)
    ldi r25, high(1000)
    rcall SMART_DELAY
    tst temp
    brne MAIN_LOOP
    rcall CHECK_PEDESTRIAN

PHASE6:
    ldi temp, (1<<PB4)|(1<<PB2)
    out PORTB, temp
    ldi r24, low(1000)
    ldi r25, high(1000)
    rcall SMART_DELAY
    tst temp
    brne MAIN_LOOP
    rjmp MAIN_LOOP

; ============================================================
; NIGHT MODE
; ============================================================
NIGHT_MODE:
    clr r22
    rcall GET_MILLIS
    mov r28, r24
    mov r29, r25
    clr r23
    clr r30
    clr r31

NIGHT_LOOP:
    rcall GET_MILLIS
    sub r24, r28
    sbc r25, r29
    cpi r24, low(500)
    ldi temp, high(500)
    cpc r25, temp
    brlo NIGHT_CHECK_SWITCH

    ldi temp, 1
    eor r22, temp
    tst r22
    breq NIGHT_YELLOW_OFF

NIGHT_YELLOW_ON:
    ldi temp, (1<<PB4)|(1<<PB1)
    out PORTB, temp
    rjmp UPDATE_FLASH_TIME

NIGHT_YELLOW_OFF:
    ldi temp, 0
    out PORTB, temp

UPDATE_FLASH_TIME:
    rcall GET_MILLIS
    mov r28, r24
    mov r29, r25

NIGHT_CHECK_SWITCH:
    in temp, PINC
    sbrc temp, PC2
    rjmp DAY_DETECTED
    clr r23
    rjmp NIGHT_LOOP

DAY_DETECTED:
    tst r23
    brne HYSTERESIS_RUNNING
    ldi r23, 1
    rcall GET_MILLIS
    mov r30, r24
    mov r31, r25
    rjmp NIGHT_LOOP

HYSTERESIS_RUNNING:
    rcall GET_MILLIS
    sub r24, r30
    sbc r25, r31
    cpi r24, low(5000)
    ldi temp, high(5000)
    cpc r25, temp
    brlo NIGHT_LOOP
    ldi temp, 0
    out PORTB, temp
    rjmp MAIN_LOOP

; ============================================================
; SMART DELAY (Fixed Stack Logic)
; ============================================================
SMART_DELAY:
    ; Move requested delay straight to safe registers
    mov r18, r24
    mov r19, r25
    rcall GET_MILLIS
    mov r26, r24
    mov r27, r25

SMART_DELAY_LOOP:
    rcall IS_NIGHT
    tst temp
    brne SMART_NIGHT
    rcall GET_MILLIS
    sub r24, r26
    sbc r25, r27
    cp r24, r18
    cpc r25, r19
    brlo SMART_DELAY_LOOP
    clr temp
    ret

SMART_NIGHT:
    ldi temp, 1
    ret

; ============================================================
; UTILITIES & SUBROUTINES
; ============================================================
IS_NIGHT:
    in temp, PINC
    sbrc temp, PC2
    rjmp NOT_NIGHT
    ldi temp, 1
    ret
NOT_NIGHT:
    clr temp
    ret

GET_MILLIS:
    cli
    lds r24, ms_low
    lds r25, ms_mid
    sei
    ret

CHECK_PEDESTRIAN:
    lds temp, pedRequest
    tst temp
    breq PED_DONE
    rcall IS_NIGHT
    tst temp
    brne PED_DONE

    ldi temp, (1<<PB5)|(1<<PB2)
    out PORTB, temp
    ldi digit, 5

PED_COUNTDOWN:
    mov r24, digit
    rcall DISPLAY_DIGIT
    ldi r24, low(1000)
    ldi r25, high(1000)
    rcall BASIC_DELAY
    dec digit
    brpl PED_COUNTDOWN

    rcall CLEAR_DISPLAY
    ldi temp, 0
    sts pedRequest, temp
PED_DONE:
    ret

BASIC_DELAY:
    mov r18, r24
    mov r19, r25
    rcall GET_MILLIS
    mov r26, r24
    mov r27, r25
BASIC_DELAY_LOOP:
    rcall GET_MILLIS
    sub r24, r26
    sbc r25, r27
    cp r24, r18
    cpc r25, r19
    brlo BASIC_DELAY_LOOP
    ret

; ============================================================
; 7-SEGMENT DISPLAY (Fixed Pull-Up Registers)
; ============================================================
DISPLAY_DIGIT:
    cpi r24, 0
    breq DISPLAY_0
    cpi r24, 1
    breq DISPLAY_1
    cpi r24, 2
    breq DISPLAY_2
    cpi r24, 3
    breq DISPLAY_3
    cpi r24, 4
    breq DISPLAY_4
    cpi r24, 5
    breq DISPLAY_5
    ret

DISPLAY_0:
    ldi temp, 0b11111000
    ori temp, (1<<PD2)   ; Protect Pull-up
    out PORTD, temp
    ldi temp, (1<<PC0)
    ori temp, (1<<PC2)   ; Protect Pull-up
    out PORTC, temp
    ret

DISPLAY_1:
    ldi temp, (1<<PD6)|(1<<PD5)
    ori temp, (1<<PD2)
    out PORTD, temp
    ldi temp, 0
    ori temp, (1<<PC2)
    out PORTC, temp
    ret

DISPLAY_2:
    ldi temp, (1<<PD7)|(1<<PD6)|(1<<PD4)|(1<<PD3)
    ori temp, (1<<PD2)
    out PORTD, temp
    ldi temp, (1<<PC1)
    ori temp, (1<<PC2)
    out PORTC, temp
    ret

DISPLAY_3:
    ldi temp, (1<<PD7)|(1<<PD6)|(1<<PD5)|(1<<PD4)
    ori temp, (1<<PD2)
    out PORTD, temp
    ldi temp, (1<<PC1)
    ori temp, (1<<PC2)
    out PORTC, temp
    ret

DISPLAY_4:
    ldi temp, (1<<PD6)|(1<<PD5)
    ori temp, (1<<PD2)
    out PORTD, temp
    ldi temp, (1<<PC0)|(1<<PC1)
    ori temp, (1<<PC2)
    out PORTC, temp
    ret

DISPLAY_5:
    ldi temp, (1<<PD7)|(1<<PD5)|(1<<PD4)|(1<<PD3)
    ori temp, (1<<PD2)
    out PORTD, temp
    ldi temp, (1<<PC0)|(1<<PC1)
    ori temp, (1<<PC2)
    out PORTC, temp
    ret

CLEAR_DISPLAY:
    in temp, PORTD
    andi temp, 0b00000111
    out PORTD, temp
    in temp, PORTC
    andi temp, 0b11111100
    ori temp, (1<<PC2)
    out PORTC, temp
    ret

; ============================================================
; INTERRUPT ROUTINES
; ============================================================
INT0_ISR:
    push temp
    in temp, SREG
    push temp
    ldi temp, 1
    sts pedRequest, temp
    pop temp
    out SREG, temp
    pop temp
    reti

TIMER1_COMPA_ISR:
    push temp
    in temp, SREG
    push temp
    lds temp, ms_low
    inc temp
    sts ms_low, temp
    brne TIMER_DONE
    lds temp, ms_mid
    inc temp
    sts ms_mid, temp
    brne TIMER_DONE
    lds temp, ms_high
    inc temp
    sts ms_high, temp
    brne TIMER_DONE
    lds temp, ms_top
    inc temp
    sts ms_top, temp
TIMER_DONE:
    pop temp
    out SREG, temp
    pop temp
    reti