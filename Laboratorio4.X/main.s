;Archivo:   main.s
;Dispositivo:	PIC16F887
;Autor:	    Jose Victor Vanegas
;Compilador: pic-as (v2.30), MPLABX V5.45
;
;Programa:	Timer de 1000ms y 2 displays de 7 segmentos
;Hardware:	LEDs en el puerto A, displays en el puerto C y D
;
;Creado:    23 febrero 2021
;Ultima modificación:	    27 febrero 2021

PROCESSOR 16F887
#include <xc.inc>
    ;configuration word 1

    CONFIG FOSC=INTRC_NOCLKOUT // Osilador interno sin salida
    CONFIG WDTE=OFF // WDT disabled (reinicio repetitivo del pic)
    CONFIG PWRTE=ON // PWRT eneable (espeera de 72ms al inicial)
    CONFIG MCLRE=OFF // El pin de MCLR se utiliza como I/O 
    CONFIG CP=OFF // Sin proteccion de código
    CONFIG CPD=OFF // Sin proteccion de datos
    
    CONFIG BOREN=OFF //Sin reinicio cuando el voltaje de alimentación baja de 4V
    CONFIG IESO=OFF // Reinicio sin cambio de reloj de interno a externo
    CONFIG FCMEN=OFF // Cambio de reloj externo a interno en caso de fallo
    CONFIG LVP=ON // Programación en bajo voltaje permitida
    
    ;configuration word 2
    
    CONFIG WRT=OFF // Proteccion de autoescritura por el programa desactivada
    CONFIG BOR4V=BOR40V // Reinicio abajo de 4V1 (BOR21V=2.1V)
    
    PSECT udata_shr ;common memory
	W_TEMP: DS 1 ;1 byte
	STATUS_TEMP: DS 1 ;var: DS 5
	num_hex: DS 1
;------------------------Para el vector reset----------------------------------- 
    PSECT resVect, class=CODE, abs, delta=2
    ORG 00h	;posicion 0000h para el reset
    
resetVec:
	PAGESEL interpush
	goto interpush
    

    PSECT intVect, class=CODE, abs, delta=2
    ORG 04h	;posicion 0004h para el reset

push:	    ;guardar W y STATUS
    movwf  W_TEMP
    swapf STATUS,w
    movwf STATUS_TEMP
       
isr:
    btfsc RBIF	    ;Para revisar la interrupcion por cambio
    call boton	    
    btfsc INTCON,2  ;Para revisar el overflow del timer0
    call taimer
 
pop:	    ;desplegar los guardados de W y STATUS
    swapf STATUS_TEMP,w
    movwf STATUS
    swapf W_TEMP,f
    swapf W_TEMP,w
    retfie

    PSECT code, delta=2, abs
    ORG 100h
    
tabla7seg:
    clrf PCLATH
    bsf PCLATH,0
    
    addwf PCL

    retlw 00111111B ;0
    retlw 00000110B ;1
    retlw 01011011B ;2
    retlw 01001111B ;3
    retlw 01100110B ;4
    retlw 01101101B ;5
    retlw 01111101B ;6
    retlw 00000111B ;7
    retlw 01111111B ;8
    retlw 01100111B ;9
    retlw 01110111B ;A
    retlw 01111100B ;B
    retlw 00111001B ;C
    retlw 01011110B ;D
    retlw 01111001B ;E
    retlw 01110001B ;F   
    
boton:
    banksel PORTA
    btfss PORTB,0
    incf PORTA
    btfss PORTB,1
    decf PORTA

    bcf RBIF
    return

taimer:
    call ress ;Resetear el timer
    
    movf num_hex,w
    call tabla7seg
    movwf PORTD
    
    incf num_hex

    movlw 0x0F ;revisar si num_hex es F
    subwf num_hex,w
    btfsc STATUS,2
    call interr
    
    return
    
interpush:
    call config_inter_eneable
    call config_io
    call config_ioc
    
Loop:
    
    movf PORTA,w
    call tabla7seg
    movwf PORTC
    goto Loop

interr:
    movf num_hex,w	;Imprimir F
    call tabla7seg
    movwf PORTD
    
    clrf num_hex	;Borrar num_hex
    return

config_io:
    banksel ANSEL
    clrf ANSEL
    clrf ANSELH
    
    banksel TRISA
    bsf TRISB,0
    bsf TRISB,1
    
    clrf TRISC
    clrf TRISD
    clrf TRISA
    bsf TRISA,4
    bsf TRISA,5
    bsf TRISA,6
    bsf TRISA,7
    
    bcf OPTION_REG,7 ;Para abilitar pull-ups
    bsf WPUB,0	;Para que el puerto B en 0,1 esten con el pull-up  
    bsf WPUB,1
    

    banksel PORTA
    clrf PORTA
    clrf PORTC
    clrf PORTD

    ;----------------------------OPTION_REG-------------------------------------   
 
    banksel OPTION_REG
    bcf OPTION_REG,5 ;Para configurar como timer interno
    bcf OPTION_REG,3 ;Activar el prescaler para timer0
    
    bsf OPTION_REG,0 ;Cargar el prescaler
    bsf OPTION_REG,1 
    bsf OPTION_REG,2 
        
    banksel OSCCON
    bcf OSCCON,6 ;Configurar el osilador a 125kHz
    bcf OSCCON,5
    bsf OSCCON,4
    
    bsf OSCCON,0 ;osilador interno
    
return    

config_ioc:
    banksel TRISA ;Para las interrupciones por cambio
    bsf IOCB,0
    bsf IOCB,1
    
    banksel PORTA
    movf PORTB,w
    bcf RBIF
    return
    
config_inter_eneable:
    
    bsf GIE ;encender interrupciones
    bsf RBIE ;interrupcion por cambio en el pueto b
    bcf RBIF ;borrar la bandera de la interrupcion en b
    bsf T0IE ;encender interrupcion timer0
    return
    
ress:
    movlw 134
    movwf TMR0
    bcf INTCON,2
    return 
    
END