; Temporizador de rele
; Programador: Francisco Edno
;
; No projeto o usuário poderar definir um tempo em minutos e segundos para 
; acionamento de uma carga (rele). A interface com usuario e por meio de
; displays de 7 segmentos e 5 botoes (4 para configurar o tempo de acionamento
; e 1 para iniciar a temporizacao).

; *****************************************************************************
; INTERRUPCOES
; *****************************************************************************
org     0000h
ljmp    _main

org     000Bh
ljmp    _tmr0

; *****************************************************************************
; EQUATES
; *****************************************************************************
DISP    equ     p2
D1      equ     p3.4
D2      equ     p3.5
T0REL   equ     -5000

; *****************************************************************************
; Main
; *****************************************************************************
_main:      mov     r3, #25
            mov     tmod, #01h      ; timer 0, modo1
            setb    tr0             ; liga o timer 0
            mov     tl0, #low T0REL ; delay de 5000 us
            mov     th0, #high T0REL; delay de 5000 us
            setb    ea              ; habilita interrupcoes
            setb    et0             ; habilitar interrupcao do timer 0
            
            sjmp    $               ; aguarda as interrupcoes

; *****************************************************************************
; ISR
; *****************************************************************************
_tmr0:      cpl     f0
            mov     a, r3
            mov     b, #10
            div     ab
            
            jb      f0, _disp1
            clr     d2
            setb    d1
            mov     a, b
            acall   Display
            ajmp    _exit

_disp1:     clr     d1
            setb    d2
            acall   Display

_exit:      clr     tf0
            mov     tl0, low T0REL
            mov     th0, high T0REL

            reti

; *****************************************************************************
; SUB-ROTINAS
; *****************************************************************************

; -----------------------------------------------------------------------------
; LKDisp
; -----------------------------------------------------------------------------
; Decodifica o digito do ACC para o display de 7 segmentos. Retorna com
; o valor no ACC.
; -----------------------------------------------------------------------------
LKDisp:     mov     dptr, #TABELA 
            movc    a, @a+dptr
            ret

TABELA: db  0C0h,0F9h,0A4h,0B0h,99h,92h,82h,0F8h,80h,90h

; -----------------------------------------------------------------------------
; Display
; -----------------------------------------------------------------------------
; Imprime num display o digito no acumulador.
; - Usa: LKDisp
; -----------------------------------------------------------------------------
Display:    acall   LKDisp
            mov     DISP, a 
            ret

; *****************************************************************************
            end
; *****************************************************************************
