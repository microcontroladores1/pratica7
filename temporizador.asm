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
D3      equ     p3.6
D4      equ     p3.7
TMR     equ     -5000

F1      bit     00h
F2      bit     01h

; *****************************************************************************
; Main
; *****************************************************************************
_main:      mov     r3, #95
            mov     r4, #33
            mov     tmod, #01h    ; timer 0, modo1
            setb    tr0           ; liga o timer 0
            mov     tl0, #low TMR ; delay de 5000 us
            mov     th0, #high TMR; delay de 5000 us
            setb    ea            ; habilita interrupcoes
            setb    et0           ; habilitar interrupcao do timer 0
            
            sjmp    $             ; aguarda as interrupcoes

; *****************************************************************************
; ISR
; *****************************************************************************
_tmr0:      cpl     F2

            jb      F2, _min        ; F2 == 1?
            acall   MuxSec
            ajmp    _exit2

_min:       acall   MuxMin

_exit2:     clr     tf0
            mov     tl0, #low TMR
            mov     th0, #high TMR

            reti

; *****************************************************************************
; SUB-ROTINAS
; *****************************************************************************

; -----------------------------------------------------------------------------
; MuxMin
; -----------------------------------------------------------------------------
; Multiplexa dois displays (D1 e D2), imprimindo o valor do R3 (Minutos).
; - Registradores: R3
; - Usa: Display
; -----------------------------------------------------------------------------
MuxMin:     cpl     f0          ; complementa flag de controle
            acall   Disable

            mov     a, r3       ; a <- r3
            mov     b, #10      ; prepara para separar unidade e dezena
            div     ab          ; a <- dezenas | b <- unidade
            
            jb      f0, _disp1  ; f0 == 1?
            clr     D2          ; nao: Habilita d2
            mov     a, b        ; acc <- b para botar no display
            acall   Display     ; imprime o valor do acc
            ajmp    _exit       ; sai da rotina

_disp1:     clr     D1          ; habilita d1
            setb    D2          ; desabilita d2
            acall   Display     ; imprime o valor do acc

_exit:      ret

; -----------------------------------------------------------------------------
; MuxSec
; -----------------------------------------------------------------------------
; Multiplexa dois displays (D3 e D4), impimindo o valor do R4 (segundos).
; - Registradores: R4
; - Usa: Display
; -----------------------------------------------------------------------------
MuxSec:     cpl     F1          ; complementa flag de controle
            acall   Disable

            mov     a, r4       ; a <- r4
            mov     b, #10      ; prepara para separar unidade e dezena
            div     ab          ; a <- dezena | b <- unidade

            jb      F1, _disp3  ; F1 == 1?
            clr     D4          ; nao: habilita d4
            mov     a, b        ; acc <- b para botar no display
            acall   Display     ; imprime o valor do acc
            ajmp    _exit1      ; sai da rotina

_disp3:     clr     D3          ; habilita d3
            acall   Display     ; imprime o valor do acc

_exit1:     ret

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

; -----------------------------------------------------------------------------
; Disable
; -----------------------------------------------------------------------------
; Desabilita todos os displays
; -----------------------------------------------------------------------------
Disable:    setb    D1
            setb    D2
            setb    D3
            setb    D4

            ret

; *****************************************************************************
            end
; *****************************************************************************
