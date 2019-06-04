;********************************************************************************************
;* Title: Ejemplo Interrupciones por IRQ
;********************************************************************************************
;* Author:  Johan Herrera, Iván Peñaranda - Universidad Nacional de Colombia
;*
;* Description: Ejemplo publicado para entender la interrupción por IRQ
;*
;* Documentation: MC9S08QG8 family Data Sheet for register and bit explanations
;* HCS08 Family Reference Manual (HCS08RM1/D) for Instruction Set
;*
;* Include Files: none
;*
;* Assembler: Metrowerks Code Warrior 11.0.1
;*
;* Revision History:
;* Rev # Date Who Comments
;* ----- ----------- ------ --------------------------------------------
;* 1.0 17-Apr-19 Implementación inicial
;********************************************************************************************

; Include derivative-specific definitions
            INCLUDE 'derivative.inc'
            

; export symbols
            XDEF _Startup, main, IRQ_ISR
            ; we export both '_Startup' and 'main' as symbols. Either can
            ; be referenced in the linker .prm file or from C/C++ later on
            
            
            
            XREF __SEG_END_SSTACK   ; symbol defined by the linker for the end of the stack


; variable/data section
MY_ZEROPAGE: SECTION  SHORT         ; Insert here your data definition

; code section
MyCode:     SECTION
main:
_Startup:
            LDHX   #__SEG_END_SSTACK ; initialize the stack pointer
            TXS
            CLI         ; enable interrupts
            jsr   config

;-------------Rutina principal------------ 
mainLoop:
            ; Insert your code here
            NOP
            bset  3,PTBD      ;Asigna el valor 1 al bit 3 del PTBD
            jsr   retardo     ;Inicia la subrutina retardo
            bclr  3,PTBD      ;Asigna el valor 0 al bit 3 del PTBD
            jsr   retardo
            BRA   mainLoop    ;Inicia la rutina principal

;--------------Configuración-------------
config:     lda   #$52
            sta   SOPT1       ;Desactiva el watchdog
            jsr   IRQ_Config  ;Inicia la subrutina de configuración del puerto IRQ
            mov   #%00011000,PTBDD  ;Asigna el pin 3 y 4 del PTBD como salidas.
            rts         ;Finaliza la subrutina
            
IRQ_Config: bclr  IRQSC_IRQIE,IRQSC                     ;Deshabilita IRQ para evitar falsas interrupciones
            mov   #(mIRQSC_IRQPE | IRQSC_IRQMOD ),IRQSC ;Habilita Flanco y nivel y resistencia en Pull up.
            bset  IRQSC_IRQACK,IRQSC                    ;Limpia la badera de IRQ evita anteriores int. 
            bset  IRQSC_IRQIE,IRQSC                     ;Registro Configura INT IRQ
;                ||||||||
;                 |||||||+--------- MODE  = Flanco de Bajada 
;                ||||||+----------- IRQIE = IRQ habilitada
;                |||||+------------ ACK   = Para reconocimiento 1 limpia el flag
;                ||||+------------- IRQF  = Solo lectura
;                |||+-------------- NO disponible
;                ||+--------------- No Disponible
;                |+---------------- IRQPE   - Habilitado en pull up el modulo IRQ
;                +----------------- IRQPDD  - habilitado el modulo
            rts
;---------------Subrutinas---------------
debounce:   lda   #$ff        ;Carga el acumulador con el valor ff hex
db1:        psha              ;Guarda el valor del acumulador en la pila
            lda   #$ff        ;Carga el acumulador con el valor ff hex
db2:        psha              ;Guarda el valor del acumulador en la pila
            lda   #$01        ;Carga el acumulador con el valor 01 hex
db3:        dbnza db3         ;Resta el de a 1 al acumulador y va a 'rt3' hasta que sea 0, cuando continúa 
            pula              ;Extrae el valor de la pila al acumulador
            dbnza db2         ;Resta el de a 1 al acumulador y va a 'rt2' hasta que sea 0, cuando continúa 
            pula              ;Extrae el valor de la pila al acumulador
            dbnza db1         ;Resta el de a 1 al acumulador y va a 'rt1' hasta que sea 0, cuando continúa
            rts               ;Regresa al lugar de llamado del lable 'debounce'
            
retardo:    lda   #$ff        ;Carga el acumulador con el valor ff hex
rt1:        psha              ;Guarda el valor del acumulador en la pila
            lda   #$ff        ;Carga el acumulador con el valor ff hex
rt2:        psha              ;Guarda el valor del acumulador en la pila
            lda   #$0f        ;Carga el acumulador con el valor 0f hex
rt3:        dbnza rt3         ;Resta el de a 1 al acumulador y va a 'rt3' hasta que sea 0, cuando continúa
            pula              ;Extrae el valor de la pila al acumulador
            dbnza rt2         ;Resta el de a 1 al acumulador y va a 'rt2' hasta que sea 0, cuando continúa 
            pula              ;Extrae el valor de la pila al acumulador
            dbnza rt1         ;Resta el de a 1 al acumulador y va a 'rt1' hasta que sea 0, cuando continúa
            rts               ;Regresa al lugar de llamado del lable 'retardo'
;--------------Interrupciones--------------------
IRQ_ISR:    pshh
            lda   PTBD
            psha
            bclr  3,PTBD
            jsr   debounce
            bset  IRQSC_IRQACK,IRQSC  ;Limpia la bandera del IRQ
            bset  4,PTBD      ;Vuelve uno el bit 4 del PTBD
            jsr   retardo
            bclr  4,PTBD      ;Vuelve cero el bit 4 del PTBD
            pula
            sta   PTBD
            pulh
            rti               ;Regresa a la rutina principal   
