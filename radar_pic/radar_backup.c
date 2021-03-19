/**
 ******************************************************************************
 * @file    main.c
 * @author  Professor Edinilson Santos Menezes <edinilson.menezes@sp.senai.br>
 * @author  Professor Kleber Lima da Silva <kleber.lima@sp.senai.br>
 * @version V0.1.0
 * @date    02-Fev-2021
 * @brief   Code - Radar SENAI 9.14
 ******************************************************************************
 */

/* Bibliotecas --------------------------------------------------------------*/
#include <stdint.h>

/* Definições ---------------------------------------------------------------*/
#define SENSOR_ON   1   // Define o estado em que o sensor está acionado
enum in_portb {SENSOR1 = 4, SENSOR2 = 5}; // Pinos de entrada PORTB

/* Constantes de configuração da leitura */
#define DEBOUNCE_TIME   
#define TIMEOUT_ERROR   5   // Tempo máximo sem receber a leitura do próximo sensor
#define DELTA_S         2.0f    // Distância entre os sensores (em metros)
enum states {IDLE, READ1, READ2, WAIT1, WAIT2, OK, ERROR};


/* Constantes para configuração do Timer1 (considerando FOSC = 20MHz) */
#define TMR1_H          0xFC
#define TMR1_L          0x18    // 0xFC18 = 64536
#define TICK_TMR1       0.0002f // t = (4 / Fosc) * PS * (65536 - TMR1H:TMR1L)


/* Macros -------------------------------------------------------------------*/


/* Variáveis Privadas -------------------------------------------------------*/
uint8_t state = IDLE, last_state = IDLE, temp = 0, aux = 0;
int32_t tmr1 = 0, ticks1 = 0, ticks2 = 0;


/* Tratamento das Interrupções ----------------------------------------------*/
void interrupt(void)
{
    if (PIR1.TMR1IF == 1)
    {
        TMR1H = 0xFC;       // Reinicia o timer para 64536 -> 0.0002s
        TMR1L = 0x18;

        tmr1++;             // Incrementa a cada estouro (0.0002s)
        PORTB.F0 = ~PORTB.F0;   // Pino para calibrar o timer

        PIR1.TMR1IF = 0;    // Limpa o flag da interrupção
    }

    if (INTCON.RBIF == 1)
    {
        if (PORTB.SENSOR1 == SENSOR_ON && (state == IDLE || state == WAIT1))
        {
            ticks1 = tmr1;
            state = READ1;

            PORTB.F1 = ~PORTB.F1;
        }

        if (PORTB.SENSOR2 == SENSOR_ON && (state == IDLE || state == WAIT2))
        {
            ticks2 = tmr1;
            state = READ2;

            PORTB.F2 = ~PORTB.F2;
        }
        
        temp = PORTB;       // Necessário para zerar a interrupção
        INTCON.RBIF = 0;    // Limpa o flag da interrupção
    }
 }

uint8_t decToBcd(uint8_t val)
{
    return ((val / 10 * 16) + (val % 10));
}

/* PROGRAMA PRINCIPAL -------------------------------------------------------*/
void main(void)
{
    uint8_t speed_7seg_bcd = 0;
    int32_t delta_ticks = 0;
    float speed_km_h = 0;
    char txt0[7];

    /* Configuração do Timer 1 */
    PIR1.TMR1IF = 0;    // Limpa o flag do Timer1
    TMR1H = TMR1_H;     // Configura o tempo de estouro do Timer1
    TMR1L = TMR1_L;
    T1CON.TMR1CS = 0;   // Oscilador interno (modo temporizador)
    T1CON.T1CKPS0 = 0;  // Prescala 1:1
    T1CON.T1CKPS1 = 0;
    PIE1.TMR1IE = 1;    // Habilita a interrupção do Timer1
    INTCON.PEIE = 1;    // Habilita a interrupção dos periféricos
    T1CON.TMR1ON = 1;   // Habilita a contagem do Timer1

    /* Configurações - Pinos and Interrupções */
    ADCON1 = 7;         // Todos os IOs como digital
    PORTB = PORTC = PORTD = 0;  // Zera PORTB, PORTC e PORTD
    TRISB = 0b00110000; // Ports B.4 e B.5 como entrada
    TRISC = 0b00000000; // Todos pinos do PORTC como saída
    TRISD = 0b00000000; // Todos pinos do PORTC como saída
    INTCON.RBIE = 1;    // Habilita a interrupção do PORTB
    INTCON.GIE = 1;     // Habilita as interrupções de uso geral


    /* Loop principal infinito */
    while (1)
    {
        /* Máquina de Estados */
        switch (state)
        {
        case IDLE:

            last_state = IDLE;
            break;

        case READ1:
            /* Debouncing - verifica se não foi ruído */

            /* Tratamento para o próximo estado */ 
            if (last_state == IDLE) state = WAIT2;
            else if (last_state == WAIT1) state = OK;
            else state = ERROR;

            last_state = READ1;
            break;

        case READ2:
            /* Debouncing - verifica se não foi ruído */

            /* Tratamento para o próximo estado */ 
            if (last_state == IDLE) state = WAIT1;
            else if (last_state == WAIT2) state = OK;
            else state = ERROR;

            last_state = READ2;
            break;

        case WAIT1:
            /* Timeout - verifica se demorou muito para receber o sinal */

            last_state = WAIT1;
            break;

        case WAIT2:
            /* Timeout - verifica se demorou muito para receber o sinal */

            last_state = WAIT2;
            break;

        case OK:
            /* Calcula e mostra a velocidade */
            delta_ticks = abs(ticks2 - ticks1);
            speed_km_h = 3.6f * (DELTA_S / (float)(delta_ticks * TICK_TMR1));

            /* Converte a velocidade para código BCD */
            PORTC = decToBcd((uint8_t)(speed_km_h + 0.5f));

            state = IDLE;
            last_state = OK;
            break;

        case ERROR:

            state = IDLE;
            last_state = ERROR;
            break;

        default:
            break;
        }

        PORTD = state;
        delay_ms(100);
    }
}