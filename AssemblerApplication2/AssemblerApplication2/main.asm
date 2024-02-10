//*******************************************************************************************************************************************************
// Universidad del Valle de Guatemala
// IE2023: Programación de Microcontroladores
// Autor: Juan Fer Maldonado 
// Contador de 4 bits con display de 7 segmentos.asm
// Descripción: lab2, existe un contador que funciona a 100 ms, además de que hay un contador de 4 bits y un display de 7 segmentos.
// Hardware: ATMega328P
// Created: 4/02/2024 17:06:34
//*******************************************************************************************************************************************************
// Encabezado
//*******************************************************************************************************************************************************
.include "M328PDEF.inc"
.cseg
.org 0x00
//*******************************************************************************************************************************************************
// Configuración de la Pila
//*******************************************************************************************************************************************************
LDI R16, LOW(RAMEND)
OUT SPL, R16
LDI R17, HIGH(RAMEND)
OUT SPH, R17
//*******************************************************************************************************************************************************
// Configuración de MCU
//*******************************************************************************************************************************************************
D7Segmentos1: .DB 0b0000010, 0b1100111, 0b0010001, 0b1000001, 0b1100100, 0b1001000, 0b0001000, 0b1100011, 0b0000000, 0b1000000, 0b0100000, 0b0001100, 0b0011010, 0b0000101, 0b0011000, 0b0111000 ; Aqui debe de agregarse los valores de A-F

SETUP:
	// Configuracion de reloj.
	LDI R31,  (1 << CLKPCE)
	STS CLKPR, R31
	LDI R31, 0b0000_0100
	STS CLKPR, R31
	CALL Init_T0         ; Configuro el timer 0 a 1024 prescaler.
	//Configuracion de los I/O Ports
	//DDRB SOLO LO USAMOS PARA DECIRLE QUE ES SALIDA O ENTRADA.
	//         76543210

	LDI	R16, 0b00011111   ; Estoy asignando que los puertos PB del 5-0 son Salidas
	OUT	DDRB, R16
	LDI	R16, 0b11111111   ; Estoy asignando que los puertos PD de 7-0 son salidas.
	OUT	DDRD, R16
	LDI	R16, 0b00000000   ; Estoy asignando que los puertos PC de 1-0 son entradas.
	OUT	DDRC, R16
	LDI R17, 0b00000011  //0b00011111  ; Activo que los botones serán pullup, debido a que los pushbutton están conectados de PC0 - PC4
	OUT PORTC, R17
	LDI R16, 0x00
	STS UCSR0B, R16
//*******************************************************************************************************************************************************
// Loop infinito
//*******************************************************************************************************************************************************
Contador:
	LDI R26, 0           ; Inicializo el contador de la posición R26, posee los valores para los leds verdes.
	LDI R28, 0			 ; Inicializo el contador de la posición R28, posee los valores para los leds amarillos.
	LDI R25, 1           ; Inicializo R25 para sumar al contador 1.
	LDI R22, 0           ; Es una bandera que nos servirá para mantener el led verde encendido o apagado.
	LDI R23, 0           ; Contador para encender los leds.
	LDI R29, 0           ; Es una bandera que nos servirá para evitar el rebote en PB1.
	LDI R30, 0			 ; Es una bandera que nos servirá para evitar el rebote en PB2.

    CALL ActivaledInc

LOOP:
		IN R16, TIFR0      ; Chequear los registros 
		CPI R16, (1<<TOV0) ; Comparo si el bit de overflow se enciende.
		BRNE LOOP          ; Si no, regresa a revisar el registro.
		LDI R16, 1 //5 //100    ; Si esta encendido, incializo R16 en 100.

		OUT TCNT0, R16     ; Escribe 
		SBI TIFR0, TOV0    ; Apaga el bit de overflow.
		INC R20            ; Incrementa el contador que se usa para el retardo en milisegundos. 
		CPI R20, 1 //2     ; Comparo si este es uno, si es uno, son 100 ms, de lo contrario, regresa.
		BRNE LOOP          ; Repetir el ciclo
		LDI R23, 0         ; Inicializar el contador de retardo en Enciendeleds

		ADD R28, R25       ; Sumo 1 al contador de leds.

		MOV R24, R26          ; Prepara R24 con el valor de R26 por si el led verde no esta encendido
		CPI R22, 0            ; Valida el estado del led verde
		BREQ Siguecomparando  ; Si esta apagado, va a sigue comparando
		LDI R24, 16           ; Si esta encendido, carga R24 con los 16 bits del led verde
		ADD R24, R26          ; Le suma el valor del display para que R28 tenga el valor del display y los 16 del bit verde

Siguecomparando:
		CP R24, R28         ; Si el contador del display es igual que el de leds
		BREQ Cambiarbandera ; Se va a cambiar el estado del bit verde porque son iguales los contadores
        JMP RevisarMaximo   ; Si no son iguales, se va a revisar los maximos

Cambiarbandera:
		CPI R22, 0             ; Revisa si el led verde esta apagado
		BREQ Enciendebandera   ; Si esta apagado se va a enciendebandera
		LDI R22, 0             ; Sino, esta encendido y lo apaga
		LDI R28, 0             ; Reinicia el contador de leds pero sin el led verde encendido
		JMP Enciendeleds       ; Voy a mostrar los leds

Enciendebandera:
		LDI R22, 1             ; Enciende la bandera del led verde
		LDI R28, 16            ; Reinicia el contador de leds pero con el led verde encendido
		JMP Enciendeleds       ; Voy a mostrar los leds

RevisarMaximo:
		CPI R22, 0             ; Revisa si el led verde esta apagado
		BREQ Maximonormal      ; Si esta apagado se va a maximonormal para validar - contra 16 bits
	 	CPI R28, 31            ; Revisa si el contador de led incluyendo el led verde encendido llegó al maximo - contra 31 bits
		BRNE Enciendeleds      ; Si no es 31 bits, muestra los leds
		LDI R28, 16            ; Si es 31, reinicia el contador de leds pero con el led verde encendido
		JMP Enciendeleds       ; Voy a mostrar los leds

Maximonormal:
	 	CPI R28, 16        ; Revisa si el contador de led incluyendo el led verde apagado llegó al maximo - contra 16 bits
		BRNE Enciendeleds  ; Si no es 16 bits, muestra los leds
		LDI R28, 0         ; Si es 16, reinicia el contador de leds pero con el led verde apagado

Enciendeleds:
		INC R23              ; Incrementa el contador que se usa para el retardo en milisegundos. 
		CPI R23, 100 //2     ; Comparo si este es uno, si es uno, son 100 ms, de lo contrario, regresa.
        BRNE Enciendeleds    ; Retardo para efectuar la actualizacion de los leds
		CLR R23

 		OUT PORTB, R28     ; Muestro los leds.
	    CLR R20            ; Reinicio el contador de retardo.
		IN R21, PINC         ; Leo el PINC completo para evaluar si esta oprimido el boton o no PIN es para leer lo que hay en un puerto.
		SBRC R21, 0 //1		 ; Revisa si el bit 0 tiene 0 y salta omitiendo la siguiente instruccion si esta asi.
		CALL PresionaPB1   ; Llamo al delay del primer botón solo cuando el bit 0 esta en 1 (oprimido)
		IN R21, PINC     ; Leo el PINC cuando el bit 0 esta en 0 y tambien si esta en 1
		SBRS R21, 0		 ; Revisa si el bit 0 tiene 1 y salta omitiendo la siguiente instruccion si esta así.
		CALL IncrementaPB1  ; Llamo a la subfunción de encendido PB1 por que el bit 0 esta en 0 (Se haya oprimido o no).
		
		IN R21, PINC         ; Leo el PINC completo para evaluar si esta oprimido el boton o no PIN es para leer lo que hay en un puerto.
		SBRC R21, 1 //1		 ; Revisa si el bit 0 tiene 0 y salta omitiendo la siguiente instruccion si esta asi.
		CALL PresionaPB2   ; Llamo al delay del primer botón solo cuando el bit 0 esta en 1 (oprimido)
		IN R21, PINC     ; Leo el PINC cuando el bit 0 esta en 0 y tambien si esta en 1
		SBRS R21, 1		 ; Revisa si el bit 0 tiene 1 y salta omitiendo la siguiente instruccion si esta así.
		CALL DecrementaPB2  ; Llamo a la subfunción de encendido PB1 por que el bit 0 esta en 0 (Se haya oprimido o no).
		RJMP LOOP
//*******************************************************************************************************************************************************
// Subrutina
//*******************************************************************************************************************************************************
Init_T0:
	LDI R16, 0                             ; Obtenido del video.
	OUT TCCR0A, R16                        ; Esto según la Datasheet en 15.9.1, trabaja en modo normal.
	LDI R16, (1 << CS02) | (1 << CS00)     ; Configuramos el prescaler según 15.9.2,  
	OUT TCCR0B, R16
	LDI R16, 100
	OUT TCNT0, R16
	RET
PresionaPB1: 
	LDI R16, 0			 ; Inicializo la posición de memoria R16.
	LDI R29, 1           ; Es una bandera para saber que se oprimió el botón y debo incrementar el contador.
RetrasoPB1:
	INC R16				 ; Inicializo la posición de memoria R16.
	CPI R16, 100		 ; Retardo de 100 ms
	BRNE RetrasoPB1      ; Mientras no sea 100, regresa a RetrasoPB1
	RET		
PresionaPB2: 
	LDI R16, 0			 ; Inicializo la posición de memoria R16.
	LDI R30, 1           ; Es una bandera para saber que se oprimió el botón y debo incrementar el contador.
RetrasoPB2:
	INC R16				 ; Inicializo la posición de memoria R16.
	CPI R16, 100		 ; Retardo de 100 ms
	BRNE RetrasoPB2      ; Mientras no sea 100, regresa a RetrasoPB1
	RET		
IncrementaPB1:
    CPI R29, 1			 ; Verificar la bandera que indica que se detectó que se oprimió el botón.
	BRNE ActivaLedInc	 ; Si la bandera indica que no se oprimió, solo muestra los led.
	LDI R29, 0			 ; Apaga la bandera que indica que se oprimió el botón.
	INC R26              ; Incremento el contador dependiendo de cuantas veces ingrese.
	SBRC R26, 4			 ; Si el contador es 16, no sumará.
	CALL Regreso		 ; Reinicio el contador en 0

ActivaLedInc:
	MOV R16, R26                     ; Muevo el valor del display.
	LDI ZH, HIGH(D7Segmentos1 << 1)  ; Defino donde termina el segmento de datos 1.
	LDI ZL, LOW(D7Segmentos1 << 1)   ; Defino donde inicia el segmento de datos 1.
	ADD ZL, R16                      ; Me desplazo R16 cantidades en el segmento de datos 1.
	LPM R27, Z                       ; Leo el dato en la posición Z del segmento de datos 1.
	OUT PORTD, R27                   ; Muestro los segmentos en el display.
	OUT PORTB, R28                   ; Muestro el valor seleccionado en el segmento de datos 2.
	RET	
Regreso: 
	LDI R26, 0              ; Resto los 16 - 16 para dar la vuelta al loop
	RET
DecrementaPB2:
    CPI R30, 1			 ; Verificar la bandera que indica que se detectó que se oprimió el botón.
	BRNE MuestraLedDec	 ; Si la bandera indica que no se oprimió, solo muestra los led.
	LDI R30, 0			 ; Apaga la bandera que indica que se oprimió el botón.
	DEC R26              ; Incremento el contador dependiendo de cuantas veces ingrese.
	BRGE MuestraledDec   ; Compara si el contador es mayor o igual a 0.
	LDI	R26, 15          ; Si el contador es 0, le carga 15 directamente y baja a mostrar los leds.

MuestraledDec:
	MOV R16, R26                     ; Muevo el valor del display.
	LDI ZH, HIGH(D7Segmentos1 << 1)  ; Defino donde termina el segmento de datos 1.
	LDI ZL, LOW(D7Segmentos1 << 1)   ; Defino donde inicia el segmento de datos 1.
	ADD ZL, R16                      ; Me desplazo R16 cantidades en el segmento de datos 1.
	LPM R27, Z                       ; Leo el dato en la posición Z del segmento de datos 1.
ActivaLedDec:
	OUT PORTD, R27                   ; Muestro los segmentos en el display.
	OUT PORTB, R28                   ; Muestro el valor seleccionado en el segmento de datos 2.
	RET	
