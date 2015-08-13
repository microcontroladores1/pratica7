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

org     001Bh
ljmp    _tmr1

; *****************************************************************************
; EQUATES
; *****************************************************************************
DISP    equ     p2      ; porta do display
D1      equ     p3.4    ; habilita display 1
D2      equ     p3.5    ; habilita display 2
D3      equ     p3.6    ; habilita display 3
D4      equ     p3.7    ; habilita display 4
TMR     equ     -5000   ; frequencia de multiplexacao = 200Hz (correto = 5000)
TMR1    equ     -50000  ; Prepara para contagem de 50000us (0.05s)

F1      bit     00h
F2      bit     01h

; *****************************************************************************
; Main
; *****************************************************************************
_main:      mov     r3, #01       ; registrador que indica os minutos
            mov     r4, #03       ; registrador que indica os segundos
            mov     r5, #-20      ; valor de recarrega para segundos

            mov     sp, #2fh      ; muda o stack pointer

            acall   ConfTMR       ; configura os timers 0 e 1

            setb    ea            ; habilita interrupcoes
            setb    et0           ; habilita interrupcao do timer 0
            setb    et1           ; habilita interrupcao do timer 1
            
            sjmp    $             ; aguarda as interrupcoes

; *****************************************************************************
; ISR
; *****************************************************************************

; -----------------------------------------------------------------------------
; Timer 0
; -----------------------------------------------------------------------------
; Multiplexacao dos displays.
; -----------------------------------------------------------------------------
_tmr0:      cpl     F2

            jb      F2, _min        ; F2 == 1?
            acall   MuxSec          ; nao: multiplexa os segundos
            ajmp    _exit2          ; sai da ISR

_min:       acall   MuxMin          ; multiplexa os minutos

_exit2:     clr     tf0             ; limpa a flag de overflow
            mov     tl0, #low TMR   ; recarrega o timer com o byte baixo
            mov     th0, #high TMR  ; recarrega o timer com o byte superior

            reti                    ; retorna da ISR

; -----------------------------------------------------------------------------
; Timer 1
; -----------------------------------------------------------------------------
; Contador de segundos.
; - Registradores: r5
; -----------------------------------------------------------------------------
_tmr1:      inc     r5              ; incrementa r5
            cjne    r5, #0, _exit3  ; se ocorreu overflow, um segundo se passou

_sec:       acall   Second          ; chama rotina de segundo
            mov     r5, #-20        ; recarrega r5
            
_exit3:     clr     tf1
            mov     tl1, #low TMR1
            mov     th1, #high TMR1

            reti

; *****************************************************************************
; SUB-ROTINAS
; *****************************************************************************

; -----------------------------------------------------------------------------
; ConfTMR
; -----------------------------------------------------------------------------
; Configura os Timers 0 e 1
; - Usa: ConfigT0
;        ConfigT1
; -----------------------------------------------------------------------------
ConfTMR:
            mov     tmod, #01h  ; timer 0 e 1 no modo 1
            acall   ConfigT0    ; configura timer 0
            acall   ConfigT1    ; configura timer 1

            ret
; -----------------------------------------------------------------------------
; ConfigT0
; -----------------------------------------------------------------------------
; Configura o timer 0
; -----------------------------------------------------------------------------
ConfigT0:   setb    tr0           ; liga o timer 0
            mov     tl0, #low TMR ; recarga do byte menor
            mov     th0, #high TMR; recarga do byte maior

            ret

; -----------------------------------------------------------------------------
; ConfigT1
; -----------------------------------------------------------------------------
; Configura o timer 1
; -----------------------------------------------------------------------------
ConfigT1:   setb    tr1             ; liga o timer 1
            mov     tl1, #low TMR1  ; recarga do byte menor
            mov     th1, #high TMR1 ; recarga do byte maior

            ret

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
            setb    D2          ; nao: Habilita d2
            mov     a, b        ; acc <- b para botar no display
            acall   Display     ; imprime o valor do acc
            ajmp    _exit       ; sai da rotina

_disp1:     setb    D1          ; habilita d1
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
            setb    D4          ; nao: habilita d4
            mov     a, b        ; acc <- b para botar no display
            acall   Display     ; imprime o valor do acc
            ajmp    _exit1      ; sai da rotina

_disp3:     setb    D3          ; habilita d3
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
Disable:    clr    D1
            clr    D2
            clr    D3
            clr    D4

            ret

; -----------------------------------------------------------------------------
; Second
; -----------------------------------------------------------------------------
; Chamada a cada um segundo
; -----------------------------------------------------------------------------
Second:     dec     r4
            cjne    r4, #0FFh, _exit4   ; ocorreu underflow?

            dec     r3                  ; sim: decrementa os minutos
            cjne    r3, #0FFh, _label   ; ocorreu underflow nos minutos?

            clr     tr1                 ; sim: para o timer 1
            mov     r3, #0              ; zera os minutos
            mov     r4, #0              ; zera os segundos
            acall   Break               ; Timer finalizado.
            ajmp    _exit4              ; sai da rotina

_label:     mov     r4, #59             
_exit4:     ret

; -----------------------------------------------------------------------------
; Break
; -----------------------------------------------------------------------------
; Rotina a ser chamada quando a contagem finaliza.
; -----------------------------------------------------------------------------
Break:      
            ret

; *****************************************************************************
            end
; *****************************************************************************
