
_interrupt:
	MOVWF      R15+0
	SWAPF      STATUS+0, 0
	CLRF       STATUS+0
	MOVWF      ___saveSTATUS+0
	MOVF       PCLATH+0, 0
	MOVWF      ___savePCLATH+0
	CLRF       PCLATH+0

;radar.c,56 :: 		void interrupt(void)
;radar.c,59 :: 		if (PIR1.TMR1IF == 1)
	BTFSS      PIR1+0, 0
	GOTO       L_interrupt0
;radar.c,61 :: 		TMR1H = 0xFC; // Reinicia o timer para 64536 -> 0.0002s
	MOVLW      252
	MOVWF      TMR1H+0
;radar.c,62 :: 		TMR1L = 0x18;
	MOVLW      24
	MOVWF      TMR1L+0
;radar.c,64 :: 		tmr1++;                  // Incrementa a cada estouro (0.0002s)
	MOVF       _tmr1+0, 0
	MOVWF      R0+0
	MOVF       _tmr1+1, 0
	MOVWF      R0+1
	MOVF       _tmr1+2, 0
	MOVWF      R0+2
	MOVF       _tmr1+3, 0
	MOVWF      R0+3
	INCF       R0+0, 1
	BTFSC      STATUS+0, 2
	INCF       R0+1, 1
	BTFSC      STATUS+0, 2
	INCF       R0+2, 1
	BTFSC      STATUS+0, 2
	INCF       R0+3, 1
	MOVF       R0+0, 0
	MOVWF      _tmr1+0
	MOVF       R0+1, 0
	MOVWF      _tmr1+1
	MOVF       R0+2, 0
	MOVWF      _tmr1+2
	MOVF       R0+3, 0
	MOVWF      _tmr1+3
;radar.c,65 :: 		PORTD.RD0 = ~PORTD.RD0;  // Pino para calibrar o timer (debug)
	MOVLW      1
	XORWF      PORTD+0, 1
;radar.c,67 :: 		PIR1.TMR1IF = 0; // Limpa o flag da interrupção
	BCF        PIR1+0, 0
;radar.c,68 :: 		}
L_interrupt0:
;radar.c,71 :: 		if (INTCON.RBIF == 1)
	BTFSS      INTCON+0, 0
	GOTO       L_interrupt1
;radar.c,73 :: 		if (SENSOR1 == SENSOR_ON && (state == IDLE || state == WAIT1))
	BTFSS      PORTB+0, 4
	GOTO       L_interrupt6
	MOVF       _state+0, 0
	XORLW      0
	BTFSC      STATUS+0, 2
	GOTO       L__interrupt51
	MOVF       _state+0, 0
	XORLW      3
	BTFSC      STATUS+0, 2
	GOTO       L__interrupt51
	GOTO       L_interrupt6
L__interrupt51:
L__interrupt50:
;radar.c,75 :: 		ticks1 = tmr1;
	MOVF       _tmr1+0, 0
	MOVWF      _ticks1+0
	MOVF       _tmr1+1, 0
	MOVWF      _ticks1+1
	MOVF       _tmr1+2, 0
	MOVWF      _ticks1+2
	MOVF       _tmr1+3, 0
	MOVWF      _ticks1+3
;radar.c,76 :: 		state = READ1;
	MOVLW      1
	MOVWF      _state+0
;radar.c,78 :: 		PORTD.RD1 = ~PORTD.RD1; // Pino para verificar a interrupção (debug)
	MOVLW      2
	XORWF      PORTD+0, 1
;radar.c,79 :: 		}
L_interrupt6:
;radar.c,81 :: 		if (SENSOR2 == SENSOR_ON && (state == IDLE || state == WAIT2))
	BTFSS      PORTB+0, 5
	GOTO       L_interrupt11
	MOVF       _state+0, 0
	XORLW      0
	BTFSC      STATUS+0, 2
	GOTO       L__interrupt49
	MOVF       _state+0, 0
	XORLW      4
	BTFSC      STATUS+0, 2
	GOTO       L__interrupt49
	GOTO       L_interrupt11
L__interrupt49:
L__interrupt48:
;radar.c,83 :: 		ticks2 = tmr1;
	MOVF       _tmr1+0, 0
	MOVWF      _ticks2+0
	MOVF       _tmr1+1, 0
	MOVWF      _ticks2+1
	MOVF       _tmr1+2, 0
	MOVWF      _ticks2+2
	MOVF       _tmr1+3, 0
	MOVWF      _ticks2+3
;radar.c,84 :: 		state = READ2;
	MOVLW      2
	MOVWF      _state+0
;radar.c,86 :: 		PORTD.RD2 = ~PORTD.RD2; // Pino para verificar a interrupção (debug)
	MOVLW      4
	XORWF      PORTD+0, 1
;radar.c,87 :: 		}
L_interrupt11:
;radar.c,89 :: 		temp = PORTB;    // Necessário para zerar a interrupção
	MOVF       PORTB+0, 0
	MOVWF      _temp+0
;radar.c,90 :: 		INTCON.RBIF = 0; // Limpa o flag da interrupção
	BCF        INTCON+0, 0
;radar.c,91 :: 		}
L_interrupt1:
;radar.c,92 :: 		}
L_end_interrupt:
L__interrupt54:
	MOVF       ___savePCLATH+0, 0
	MOVWF      PCLATH+0
	SWAPF      ___saveSTATUS+0, 0
	MOVWF      STATUS+0
	SWAPF      R15+0, 1
	SWAPF      R15+0, 0
	RETFIE
; end of _interrupt

_decToBcd:

;radar.c,108 :: 		uint8_t decToBcd(uint8_t val)
;radar.c,110 :: 		return ((val / 10 * 16) + (val % 10));
	MOVLW      10
	MOVWF      R4+0
	MOVF       FARG_decToBcd_val+0, 0
	MOVWF      R0+0
	CALL       _Div_8X8_U+0
	MOVF       R0+0, 0
	MOVWF      FLOC__decToBcd+0
	RLF        FLOC__decToBcd+0, 1
	BCF        FLOC__decToBcd+0, 0
	RLF        FLOC__decToBcd+0, 1
	BCF        FLOC__decToBcd+0, 0
	RLF        FLOC__decToBcd+0, 1
	BCF        FLOC__decToBcd+0, 0
	RLF        FLOC__decToBcd+0, 1
	BCF        FLOC__decToBcd+0, 0
	MOVLW      10
	MOVWF      R4+0
	MOVF       FARG_decToBcd_val+0, 0
	MOVWF      R0+0
	CALL       _Div_8X8_U+0
	MOVF       R8+0, 0
	MOVWF      R0+0
	MOVF       FLOC__decToBcd+0, 0
	ADDWF      R0+0, 1
;radar.c,111 :: 		}
L_end_decToBcd:
	RETURN
; end of _decToBcd

_main:

;radar.c,115 :: 		void main(void)
;radar.c,118 :: 		int32_t delta_ticks = 0;
	CLRF       main_delta_ticks_L0+0
	CLRF       main_delta_ticks_L0+1
	CLRF       main_delta_ticks_L0+2
	CLRF       main_delta_ticks_L0+3
	CLRF       main_speed_km_h_L0+0
	CLRF       main_speed_km_h_L0+1
	CLRF       main_speed_km_h_L0+2
	CLRF       main_speed_km_h_L0+3
;radar.c,122 :: 		PIR1.TMR1IF = 0;    // Limpa o flag do Timer1
	BCF        PIR1+0, 0
;radar.c,123 :: 		TMR1H = TMR1_H;     // Configura o tempo de estouro do Timer1
	MOVLW      252
	MOVWF      TMR1H+0
;radar.c,124 :: 		TMR1L = TMR1_L;
	MOVLW      24
	MOVWF      TMR1L+0
;radar.c,125 :: 		T1CON.TMR1CS = 0;   // Oscilador interno (modo temporizador)
	BCF        T1CON+0, 1
;radar.c,126 :: 		T1CON.T1CKPS0 = 0;  // Prescala 1:1
	BCF        T1CON+0, 4
;radar.c,127 :: 		T1CON.T1CKPS1 = 0;
	BCF        T1CON+0, 5
;radar.c,130 :: 		ADCON1 = 7;         // Todos os IOs como digital
	MOVLW      7
	MOVWF      ADCON1+0
;radar.c,131 :: 		TRISB = 0b00110000; // Ports B.4 e B.5 como entrada
	MOVLW      48
	MOVWF      TRISB+0
;radar.c,132 :: 		TRISC = 0b00000000; // Todos pinos do PORTC como saída
	CLRF       TRISC+0
;radar.c,133 :: 		TRISD = 0b00000000; // Todos pinos do PORTD como saída
	CLRF       TRISD+0
;radar.c,134 :: 		PORTB = PORTC = PORTD = 0;  // Zera PORTB, PORTC e PORTD
	CLRF       PORTD+0
	MOVF       PORTD+0, 0
	MOVWF      PORTC+0
	MOVF       PORTC+0, 0
	MOVWF      PORTB+0
;radar.c,137 :: 		delay_ms(2000);
	MOVLW      51
	MOVWF      R11+0
	MOVLW      187
	MOVWF      R12+0
	MOVLW      223
	MOVWF      R13+0
L_main12:
	DECFSZ     R13+0, 1
	GOTO       L_main12
	DECFSZ     R12+0, 1
	GOTO       L_main12
	DECFSZ     R11+0, 1
	GOTO       L_main12
	NOP
	NOP
;radar.c,138 :: 		PIE1.TMR1IE = 1;    // Habilita a interrupção do Timer1
	BSF        PIE1+0, 0
;radar.c,139 :: 		INTCON.PEIE = 1;    // Habilita a interrupção dos periféricos
	BSF        INTCON+0, 6
;radar.c,140 :: 		T1CON.TMR1ON = 1;   // Habilita a contagem do Timer1
	BSF        T1CON+0, 0
;radar.c,141 :: 		INTCON.RBIE = 1;    // Habilita a interrupção do PORTB
	BSF        INTCON+0, 3
;radar.c,142 :: 		INTCON.GIE = 1;     // Habilita as interrupções de uso geral
	BSF        INTCON+0, 7
;radar.c,152 :: 		while (1)
L_main13:
;radar.c,155 :: 		switch (state)
	GOTO       L_main15
;radar.c,157 :: 		case IDLE: /* Estado ocioso - não faz nada */
L_main17:
;radar.c,160 :: 		last_state = IDLE;
	CLRF       _last_state+0
;radar.c,161 :: 		break;
	GOTO       L_main16
;radar.c,163 :: 		case READ1: /* Tratamento da leitura do SENSOR1 */
L_main18:
;radar.c,167 :: 		if (last_state == IDLE) state = WAIT2;
	MOVF       _last_state+0, 0
	XORLW      0
	BTFSS      STATUS+0, 2
	GOTO       L_main19
	MOVLW      4
	MOVWF      _state+0
	GOTO       L_main20
L_main19:
;radar.c,168 :: 		else if (last_state == WAIT1) state = OK;
	MOVF       _last_state+0, 0
	XORLW      3
	BTFSS      STATUS+0, 2
	GOTO       L_main21
	MOVLW      6
	MOVWF      _state+0
	GOTO       L_main22
L_main21:
;radar.c,169 :: 		else state = ERROR;
	MOVLW      7
	MOVWF      _state+0
L_main22:
L_main20:
;radar.c,171 :: 		last_state = READ1;
	MOVLW      1
	MOVWF      _last_state+0
;radar.c,172 :: 		timeout = 0;
	CLRF       _timeout+0
	CLRF       _timeout+1
	CLRF       _timeout+2
	CLRF       _timeout+3
;radar.c,173 :: 		break;
	GOTO       L_main16
;radar.c,175 :: 		case READ2: /* Tratamento da leitura do SENSOR2 */
L_main23:
;radar.c,179 :: 		if (last_state == IDLE) state = WAIT1;
	MOVF       _last_state+0, 0
	XORLW      0
	BTFSS      STATUS+0, 2
	GOTO       L_main24
	MOVLW      3
	MOVWF      _state+0
	GOTO       L_main25
L_main24:
;radar.c,180 :: 		else if (last_state == WAIT2) state = OK;
	MOVF       _last_state+0, 0
	XORLW      4
	BTFSS      STATUS+0, 2
	GOTO       L_main26
	MOVLW      6
	MOVWF      _state+0
	GOTO       L_main27
L_main26:
;radar.c,181 :: 		else state = ERROR;
	MOVLW      7
	MOVWF      _state+0
L_main27:
L_main25:
;radar.c,183 :: 		last_state = READ2;
	MOVLW      2
	MOVWF      _last_state+0
;radar.c,184 :: 		timeout = 0;
	CLRF       _timeout+0
	CLRF       _timeout+1
	CLRF       _timeout+2
	CLRF       _timeout+3
;radar.c,185 :: 		break;
	GOTO       L_main16
;radar.c,187 :: 		case WAIT1: /* Aguarda pela leitura do SENSOR1 */
L_main28:
;radar.c,191 :: 		delay_ms(1);
	MOVLW      7
	MOVWF      R12+0
	MOVLW      125
	MOVWF      R13+0
L_main29:
	DECFSZ     R13+0, 1
	GOTO       L_main29
	DECFSZ     R12+0, 1
	GOTO       L_main29
;radar.c,192 :: 		if (++timeout >= TIMEOUT_ERROR) state = ERROR;
	MOVF       _timeout+0, 0
	MOVWF      R0+0
	MOVF       _timeout+1, 0
	MOVWF      R0+1
	MOVF       _timeout+2, 0
	MOVWF      R0+2
	MOVF       _timeout+3, 0
	MOVWF      R0+3
	INCF       R0+0, 1
	BTFSC      STATUS+0, 2
	INCF       R0+1, 1
	BTFSC      STATUS+0, 2
	INCF       R0+2, 1
	BTFSC      STATUS+0, 2
	INCF       R0+3, 1
	MOVF       R0+0, 0
	MOVWF      _timeout+0
	MOVF       R0+1, 0
	MOVWF      _timeout+1
	MOVF       R0+2, 0
	MOVWF      _timeout+2
	MOVF       R0+3, 0
	MOVWF      _timeout+3
	MOVLW      128
	XORWF      _timeout+3, 0
	MOVWF      R0+0
	MOVLW      128
	SUBWF      R0+0, 0
	BTFSS      STATUS+0, 2
	GOTO       L__main57
	MOVLW      0
	SUBWF      _timeout+2, 0
	BTFSS      STATUS+0, 2
	GOTO       L__main57
	MOVLW      11
	SUBWF      _timeout+1, 0
	BTFSS      STATUS+0, 2
	GOTO       L__main57
	MOVLW      184
	SUBWF      _timeout+0, 0
L__main57:
	BTFSS      STATUS+0, 0
	GOTO       L_main30
	MOVLW      7
	MOVWF      _state+0
L_main30:
;radar.c,194 :: 		last_state = WAIT1;
	MOVLW      3
	MOVWF      _last_state+0
;radar.c,195 :: 		break;
	GOTO       L_main16
;radar.c,197 :: 		case WAIT2: /* Aguarda pela leitura do SENSOR2 */
L_main31:
;radar.c,201 :: 		delay_ms(1);
	MOVLW      7
	MOVWF      R12+0
	MOVLW      125
	MOVWF      R13+0
L_main32:
	DECFSZ     R13+0, 1
	GOTO       L_main32
	DECFSZ     R12+0, 1
	GOTO       L_main32
;radar.c,202 :: 		if (++timeout >= TIMEOUT_ERROR) state = ERROR;
	MOVF       _timeout+0, 0
	MOVWF      R0+0
	MOVF       _timeout+1, 0
	MOVWF      R0+1
	MOVF       _timeout+2, 0
	MOVWF      R0+2
	MOVF       _timeout+3, 0
	MOVWF      R0+3
	INCF       R0+0, 1
	BTFSC      STATUS+0, 2
	INCF       R0+1, 1
	BTFSC      STATUS+0, 2
	INCF       R0+2, 1
	BTFSC      STATUS+0, 2
	INCF       R0+3, 1
	MOVF       R0+0, 0
	MOVWF      _timeout+0
	MOVF       R0+1, 0
	MOVWF      _timeout+1
	MOVF       R0+2, 0
	MOVWF      _timeout+2
	MOVF       R0+3, 0
	MOVWF      _timeout+3
	MOVLW      128
	XORWF      _timeout+3, 0
	MOVWF      R0+0
	MOVLW      128
	SUBWF      R0+0, 0
	BTFSS      STATUS+0, 2
	GOTO       L__main58
	MOVLW      0
	SUBWF      _timeout+2, 0
	BTFSS      STATUS+0, 2
	GOTO       L__main58
	MOVLW      11
	SUBWF      _timeout+1, 0
	BTFSS      STATUS+0, 2
	GOTO       L__main58
	MOVLW      184
	SUBWF      _timeout+0, 0
L__main58:
	BTFSS      STATUS+0, 0
	GOTO       L_main33
	MOVLW      7
	MOVWF      _state+0
L_main33:
;radar.c,204 :: 		last_state = WAIT2;
	MOVLW      4
	MOVWF      _last_state+0
;radar.c,205 :: 		break;
	GOTO       L_main16
;radar.c,207 :: 		case WAITEN: /* Aguarda tempo para liberar próxima leitura */
L_main34:
;radar.c,211 :: 		delay_ms(1);
	MOVLW      7
	MOVWF      R12+0
	MOVLW      125
	MOVWF      R13+0
L_main35:
	DECFSZ     R13+0, 1
	GOTO       L_main35
	DECFSZ     R12+0, 1
	GOTO       L_main35
;radar.c,212 :: 		if (++timeout >= TIMEOUT_ENABLE) state = IDLE;
	MOVF       _timeout+0, 0
	MOVWF      R0+0
	MOVF       _timeout+1, 0
	MOVWF      R0+1
	MOVF       _timeout+2, 0
	MOVWF      R0+2
	MOVF       _timeout+3, 0
	MOVWF      R0+3
	INCF       R0+0, 1
	BTFSC      STATUS+0, 2
	INCF       R0+1, 1
	BTFSC      STATUS+0, 2
	INCF       R0+2, 1
	BTFSC      STATUS+0, 2
	INCF       R0+3, 1
	MOVF       R0+0, 0
	MOVWF      _timeout+0
	MOVF       R0+1, 0
	MOVWF      _timeout+1
	MOVF       R0+2, 0
	MOVWF      _timeout+2
	MOVF       R0+3, 0
	MOVWF      _timeout+3
	MOVLW      128
	XORWF      _timeout+3, 0
	MOVWF      R0+0
	MOVLW      128
	SUBWF      R0+0, 0
	BTFSS      STATUS+0, 2
	GOTO       L__main59
	MOVLW      0
	SUBWF      _timeout+2, 0
	BTFSS      STATUS+0, 2
	GOTO       L__main59
	MOVLW      3
	SUBWF      _timeout+1, 0
	BTFSS      STATUS+0, 2
	GOTO       L__main59
	MOVLW      232
	SUBWF      _timeout+0, 0
L__main59:
	BTFSS      STATUS+0, 0
	GOTO       L_main36
	CLRF       _state+0
L_main36:
;radar.c,214 :: 		last_state = WAITEN;
	MOVLW      5
	MOVWF      _last_state+0
;radar.c,215 :: 		break;
	GOTO       L_main16
;radar.c,217 :: 		case OK: /* Leitura concluída */
L_main37:
;radar.c,221 :: 		delta_ticks = abs(ticks2 - ticks1);
	MOVF       _ticks1+0, 0
	SUBWF      _ticks2+0, 0
	MOVWF      FARG_abs_a+0
	MOVF       _ticks1+1, 0
	BTFSS      STATUS+0, 0
	ADDLW      1
	SUBWF      _ticks2+1, 0
	MOVWF      FARG_abs_a+1
	CALL       _abs+0
	MOVF       R0+0, 0
	MOVWF      main_delta_ticks_L0+0
	MOVF       R0+1, 0
	MOVWF      main_delta_ticks_L0+1
	MOVLW      0
	BTFSC      main_delta_ticks_L0+1, 7
	MOVLW      255
	MOVWF      main_delta_ticks_L0+2
	MOVWF      main_delta_ticks_L0+3
;radar.c,222 :: 		speed_km_h = 3.6f * (DELTA_S / (float)(delta_ticks * TICK_TMR1));
	MOVF       main_delta_ticks_L0+0, 0
	MOVWF      R0+0
	MOVF       main_delta_ticks_L0+1, 0
	MOVWF      R0+1
	MOVF       main_delta_ticks_L0+2, 0
	MOVWF      R0+2
	MOVF       main_delta_ticks_L0+3, 0
	MOVWF      R0+3
	CALL       _longint2double+0
	MOVLW      23
	MOVWF      R4+0
	MOVLW      183
	MOVWF      R4+1
	MOVLW      81
	MOVWF      R4+2
	MOVLW      114
	MOVWF      R4+3
	CALL       _Mul_32x32_FP+0
	MOVF       R0+0, 0
	MOVWF      R4+0
	MOVF       R0+1, 0
	MOVWF      R4+1
	MOVF       R0+2, 0
	MOVWF      R4+2
	MOVF       R0+3, 0
	MOVWF      R4+3
	MOVLW      0
	MOVWF      R0+0
	MOVLW      0
	MOVWF      R0+1
	MOVLW      0
	MOVWF      R0+2
	MOVLW      128
	MOVWF      R0+3
	CALL       _Div_32x32_FP+0
	MOVLW      102
	MOVWF      R4+0
	MOVLW      102
	MOVWF      R4+1
	MOVLW      102
	MOVWF      R4+2
	MOVLW      128
	MOVWF      R4+3
	CALL       _Mul_32x32_FP+0
	MOVF       R0+0, 0
	MOVWF      main_speed_km_h_L0+0
	MOVF       R0+1, 0
	MOVWF      main_speed_km_h_L0+1
	MOVF       R0+2, 0
	MOVWF      main_speed_km_h_L0+2
	MOVF       R0+3, 0
	MOVWF      main_speed_km_h_L0+3
;radar.c,225 :: 		if (speed_km_h > SPEED_LIMIT)
	MOVF       R0+0, 0
	MOVWF      R4+0
	MOVF       R0+1, 0
	MOVWF      R4+1
	MOVF       R0+2, 0
	MOVWF      R4+2
	MOVF       R0+3, 0
	MOVWF      R4+3
	MOVLW      0
	MOVWF      R0+0
	MOVLW      0
	MOVWF      R0+1
	MOVLW      32
	MOVWF      R0+2
	MOVLW      131
	MOVWF      R0+3
	CALL       _Compare_Double+0
	MOVLW      1
	BTFSC      STATUS+0, 0
	MOVLW      0
	MOVWF      R0+0
	MOVF       R0+0, 0
	BTFSC      STATUS+0, 2
	GOTO       L_main38
;radar.c,229 :: 		delta_ticks = tmr1;
	MOVF       _tmr1+0, 0
	MOVWF      main_delta_ticks_L0+0
	MOVF       _tmr1+1, 0
	MOVWF      main_delta_ticks_L0+1
	MOVF       _tmr1+2, 0
	MOVWF      main_delta_ticks_L0+2
	MOVF       _tmr1+3, 0
	MOVWF      main_delta_ticks_L0+3
;radar.c,230 :: 		ALERT = 1;          // Liga a saída da sirene
	BSF        PORTB+0, 1
;radar.c,232 :: 		if (speed_km_h > 99) speed_km_h = 99;
	MOVF       main_speed_km_h_L0+0, 0
	MOVWF      R4+0
	MOVF       main_speed_km_h_L0+1, 0
	MOVWF      R4+1
	MOVF       main_speed_km_h_L0+2, 0
	MOVWF      R4+2
	MOVF       main_speed_km_h_L0+3, 0
	MOVWF      R4+3
	MOVLW      0
	MOVWF      R0+0
	MOVLW      0
	MOVWF      R0+1
	MOVLW      70
	MOVWF      R0+2
	MOVLW      133
	MOVWF      R0+3
	CALL       _Compare_Double+0
	MOVLW      1
	BTFSC      STATUS+0, 0
	MOVLW      0
	MOVWF      R0+0
	MOVF       R0+0, 0
	BTFSC      STATUS+0, 2
	GOTO       L_main39
	MOVLW      0
	MOVWF      main_speed_km_h_L0+0
	MOVLW      0
	MOVWF      main_speed_km_h_L0+1
	MOVLW      70
	MOVWF      main_speed_km_h_L0+2
	MOVLW      133
	MOVWF      main_speed_km_h_L0+3
L_main39:
;radar.c,233 :: 		}
L_main38:
;radar.c,236 :: 		PORTC = decToBcd((uint8_t)(speed_km_h + 0.5f));
	MOVF       main_speed_km_h_L0+0, 0
	MOVWF      R0+0
	MOVF       main_speed_km_h_L0+1, 0
	MOVWF      R0+1
	MOVF       main_speed_km_h_L0+2, 0
	MOVWF      R0+2
	MOVF       main_speed_km_h_L0+3, 0
	MOVWF      R0+3
	MOVLW      0
	MOVWF      R4+0
	MOVLW      0
	MOVWF      R4+1
	MOVLW      0
	MOVWF      R4+2
	MOVLW      126
	MOVWF      R4+3
	CALL       _Add_32x32_FP+0
	CALL       _double2byte+0
	MOVF       R0+0, 0
	MOVWF      FARG_decToBcd_val+0
	CALL       _decToBcd+0
	MOVF       R0+0, 0
	MOVWF      PORTC+0
;radar.c,238 :: 		state = WAITEN;
	MOVLW      5
	MOVWF      _state+0
;radar.c,239 :: 		last_state = OK;
	MOVLW      6
	MOVWF      _last_state+0
;radar.c,240 :: 		timeout = 0;
	CLRF       _timeout+0
	CLRF       _timeout+1
	CLRF       _timeout+2
	CLRF       _timeout+3
;radar.c,241 :: 		break;
	GOTO       L_main16
;radar.c,243 :: 		case ERROR: /* Erro na leitura */
L_main40:
;radar.c,244 :: 		if (last_state == WAIT1 || last_state == WAIT2)
	MOVF       _last_state+0, 0
	XORLW      3
	BTFSC      STATUS+0, 2
	GOTO       L__main52
	MOVF       _last_state+0, 0
	XORLW      4
	BTFSC      STATUS+0, 2
	GOTO       L__main52
	GOTO       L_main43
L__main52:
;radar.c,247 :: 		PORTC = 0x00;
	CLRF       PORTC+0
;radar.c,248 :: 		}
	GOTO       L_main44
L_main43:
;radar.c,252 :: 		PORTC = 0xFF;
	MOVLW      255
	MOVWF      PORTC+0
;radar.c,253 :: 		}
L_main44:
;radar.c,255 :: 		state = IDLE;
	CLRF       _state+0
;radar.c,256 :: 		last_state = ERROR;
	MOVLW      7
	MOVWF      _last_state+0
;radar.c,257 :: 		timeout = 0;
	CLRF       _timeout+0
	CLRF       _timeout+1
	CLRF       _timeout+2
	CLRF       _timeout+3
;radar.c,258 :: 		break;
	GOTO       L_main16
;radar.c,260 :: 		default:
L_main45:
;radar.c,261 :: 		break;
	GOTO       L_main16
;radar.c,263 :: 		} // Fim do switch
L_main15:
	MOVF       _state+0, 0
	XORLW      0
	BTFSC      STATUS+0, 2
	GOTO       L_main17
	MOVF       _state+0, 0
	XORLW      1
	BTFSC      STATUS+0, 2
	GOTO       L_main18
	MOVF       _state+0, 0
	XORLW      2
	BTFSC      STATUS+0, 2
	GOTO       L_main23
	MOVF       _state+0, 0
	XORLW      3
	BTFSC      STATUS+0, 2
	GOTO       L_main28
	MOVF       _state+0, 0
	XORLW      4
	BTFSC      STATUS+0, 2
	GOTO       L_main31
	MOVF       _state+0, 0
	XORLW      5
	BTFSC      STATUS+0, 2
	GOTO       L_main34
	MOVF       _state+0, 0
	XORLW      6
	BTFSC      STATUS+0, 2
	GOTO       L_main37
	MOVF       _state+0, 0
	XORLW      7
	BTFSC      STATUS+0, 2
	GOTO       L_main40
	GOTO       L_main45
L_main16:
;radar.c,266 :: 		if (ALERT == 1)
	BTFSS      PORTB+0, 1
	GOTO       L_main46
;radar.c,268 :: 		if (((tmr1 - delta_ticks) * TICK_TMR1) > ALERT_TIME) ALERT = 0;
	MOVF       _tmr1+0, 0
	MOVWF      R0+0
	MOVF       _tmr1+1, 0
	MOVWF      R0+1
	MOVF       _tmr1+2, 0
	MOVWF      R0+2
	MOVF       _tmr1+3, 0
	MOVWF      R0+3
	MOVF       main_delta_ticks_L0+0, 0
	SUBWF      R0+0, 1
	MOVF       main_delta_ticks_L0+1, 0
	BTFSS      STATUS+0, 0
	INCFSZ     main_delta_ticks_L0+1, 0
	SUBWF      R0+1, 1
	MOVF       main_delta_ticks_L0+2, 0
	BTFSS      STATUS+0, 0
	INCFSZ     main_delta_ticks_L0+2, 0
	SUBWF      R0+2, 1
	MOVF       main_delta_ticks_L0+3, 0
	BTFSS      STATUS+0, 0
	INCFSZ     main_delta_ticks_L0+3, 0
	SUBWF      R0+3, 1
	CALL       _longint2double+0
	MOVLW      23
	MOVWF      R4+0
	MOVLW      183
	MOVWF      R4+1
	MOVLW      81
	MOVWF      R4+2
	MOVLW      114
	MOVWF      R4+3
	CALL       _Mul_32x32_FP+0
	MOVF       R0+0, 0
	MOVWF      R4+0
	MOVF       R0+1, 0
	MOVWF      R4+1
	MOVF       R0+2, 0
	MOVWF      R4+2
	MOVF       R0+3, 0
	MOVWF      R4+3
	MOVLW      0
	MOVWF      R0+0
	MOVLW      0
	MOVWF      R0+1
	MOVLW      0
	MOVWF      R0+2
	MOVLW      128
	MOVWF      R0+3
	CALL       _Compare_Double+0
	MOVLW      1
	BTFSC      STATUS+0, 0
	MOVLW      0
	MOVWF      R0+0
	MOVF       R0+0, 0
	BTFSC      STATUS+0, 2
	GOTO       L_main47
	BCF        PORTB+0, 1
L_main47:
;radar.c,269 :: 		}
L_main46:
;radar.c,272 :: 		} // Fim do while
	GOTO       L_main13
;radar.c,274 :: 		} // Fim da main
L_end_main:
	GOTO       $+0
; end of _main
