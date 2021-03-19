/**
 ******************************************************************************
 * @file    main.c
 * @author  Professor Edinilson Santos Menezes <edinilson.menezes@sp.senai.br>
 * @author  Professor Kleber Lima da Silva <kleber.lima@sp.senai.br>
 * @version V0.1.0
 * @date    04-Mar-2021
 * @brief   Code - Radar SENAI 9.14
 ******************************************************************************
 */

/* Bibliotecas --------------------------------------------------------------*/
#include <stdint.h>

/* Definições ---------------------------------------------------------------*/
/* Constantes para utilização do DEBUG via serial */
#define DEBUG       0   // Para habilitar o debug: mudar para 1
#define DEBUG_TX    6   // Pino TX
#define DEBUG_RX    7   // Pino RX
#define DEBUG_BAUD  9600    // Baudrate

/* Definição dos Pinos */
#define SENSOR1     PORTB.RB4
#define SENSOR2     PORTB.RB5
#define ALERT       PORTB.RB1
#define SENSOR_ON   1   // Define o nível lógico em que o sensor está acionado

/* Constantes de configuração do radar */
#define TIMEOUT_ENABLE  1000    // Tempo (ms) para liberar a próxima leitura
#define TIMEOUT_ERROR   3000    // Tempo máximo (ms) sem receber a leitura do próximo sensor
#define DELTA_S         2.0f    // Distância entre os sensores (em metros)
#define SPEED_LIMIT     20      // Velocidade máxima permitida (em km/h) - aciona alerta
#define ALERT_TIME      2       // Duração (s) do alerta
enum states {IDLE, READ1, READ2, WAIT1, WAIT2, WAITEN, OK, ERROR};

/* Constantes para configuração do Timer1 (considerando FOSC = 20MHz) */
#define TMR1_H          0xFC
#define TMR1_L          0x18    // 0xFC18 = 64536
#define TICK_TMR1       0.0002f // t = (4 / Fosc) * PS * (65536 - TMR1H:TMR1L)


/* Macros -------------------------------------------------------------------*/
#if DEBUG == 1
#define DEBUG_PRINT(x)  debug(x)
#else
#define DEBUG_PRINT(x)
#endif


/* Variáveis Privadas -------------------------------------------------------*/
volatile uint8_t state = IDLE, last_state = IDLE, temp = 0;
volatile int32_t tmr1 = 0, ticks1 = 0, ticks2 = 0, timeout = 0;


/* Tratamento das Interrupções ----------------------------------------------*/
void interrupt(void)
{
    /* Interrupção por estouro do Timer 1 */
    if (PIR1.TMR1IF == 1)
    {
        TMR1H = 0xFC; // Reinicia o timer para 64536 -> 0.0002s
        TMR1L = 0x18;

        tmr1++;                  // Incrementa a cada estouro (0.0002s)
        PORTD.RD0 = ~PORTD.RD0;  // Pino para calibrar o timer (debug)

        PIR1.TMR1IF = 0; // Limpa o flag da interrupção
    }

    /* Interrupção por mudança de estado no pinos B4 a B7 */
    if (INTCON.RBIF == 1)
    {
        if (SENSOR1 == SENSOR_ON && (state == IDLE || state == WAIT1))
        {
            ticks1 = tmr1;
            state = READ1;

            PORTD.RD1 = ~PORTD.RD1; // Pino para verificar a interrupção (debug)
        }

        if (SENSOR2 == SENSOR_ON && (state == IDLE || state == WAIT2))
        {
            ticks2 = tmr1;
            state = READ2;

            PORTD.RD2 = ~PORTD.RD2; // Pino para verificar a interrupção (debug)
        }

        temp = PORTB;    // Necessário para zerar a interrupção
        INTCON.RBIF = 0; // Limpa o flag da interrupção
    }
}


/* Função para enviar uma string para a serial de debug -------------------- */
#if DEBUG == 1
void debug(const char *s)
{
    // Necessário desabilitar a interrupção durante a escrita, pois a Soft_Uart usa o mesmo timer
    PIE1.TMR1IE = 0;
    while (*s) Soft_Uart_Write(*s++);
    PIE1.TMR1IE = 1;
}
#endif


/* Função para converter número inteiro em código BCD ---------------------- */
uint8_t decToBcd(uint8_t val)
{
    return ((val / 10 * 16) + (val % 10));
}


/* PROGRAMA PRINCIPAL -------------------------------------------------------*/
void main(void)
{
    /* Variáveis locais */
    int32_t delta_ticks = 0;
    float speed_km_h = 0;

    /* Configuração do Timer 1 */
    PIR1.TMR1IF = 0;    // Limpa o flag do Timer1
    TMR1H = TMR1_H;     // Configura o tempo de estouro do Timer1
    TMR1L = TMR1_L;
    T1CON.TMR1CS = 0;   // Oscilador interno (modo temporizador)
    T1CON.T1CKPS0 = 0;  // Prescala 1:1
    T1CON.T1CKPS1 = 0;

    /* Configurações - Pinos and Interrupções */
    ADCON1 = 7;         // Todos os IOs como digital
    TRISB = 0b00110000; // Ports B.4 e B.5 como entrada
    TRISC = 0b00000000; // Todos pinos do PORTC como saída
    TRISD = 0b00000000; // Todos pinos do PORTD como saída
    PORTB = PORTC = PORTD = 0;  // Zera PORTB, PORTC e PORTD

    /* Aguarda estabilizar para habilitar as interrupções */
    delay_ms(2000);
    PIE1.TMR1IE = 1;    // Habilita a interrupção do Timer1
    INTCON.PEIE = 1;    // Habilita a interrupção dos periféricos
    T1CON.TMR1ON = 1;   // Habilita a contagem do Timer1
    INTCON.RBIE = 1;    // Habilita a interrupção do PORTB
    INTCON.GIE = 1;     // Habilita as interrupções de uso geral

    /* Configuração da UART para debug */
#if DEBUG == 1
    Soft_Uart_Init(&PORTD, DEBUG_RX, DEBUG_TX, DEBUG_BAUD, 0);  // Inicializa uma serial para debug
    DEBUG_PRINT("Radar SENAI 9.14\r");
#endif


    /* Loop principal infinito */
    while (1)
    {
        /* Máquina de Estados */
        switch (state)
        {
        case IDLE: /* Estado ocioso - não faz nada */
            //DEBUG_PRINT("IDLE\r");

            last_state = IDLE;
            break;

        case READ1: /* Tratamento da leitura do SENSOR1 */
            DEBUG_PRINT("READ1\r");

            /* Tratamento para o próximo estado */ 
            if (last_state == IDLE) state = WAIT2;
            else if (last_state == WAIT1) state = OK;
            else state = ERROR;

            last_state = READ1;
            timeout = 0;
            break;

        case READ2: /* Tratamento da leitura do SENSOR2 */
            DEBUG_PRINT("READ2\r");

            /* Tratamento para o próximo estado */ 
            if (last_state == IDLE) state = WAIT1;
            else if (last_state == WAIT2) state = OK;
            else state = ERROR;

            last_state = READ2;
            timeout = 0;
            break;

        case WAIT1: /* Aguarda pela leitura do SENSOR1 */
            //DEBUG_PRINT("WAIT1\r");

            /* Timeout - verifica se demorou muito para receber o sinal */
            delay_ms(1);
            if (++timeout >= TIMEOUT_ERROR) state = ERROR;

            last_state = WAIT1;
            break;

        case WAIT2: /* Aguarda pela leitura do SENSOR2 */
            //DEBUG_PRINT("WAIT2\r");
            
            /* Timeout - verifica se demorou muito para receber o sinal */
            delay_ms(1);
            if (++timeout >= TIMEOUT_ERROR) state = ERROR;

            last_state = WAIT2;
            break;

        case WAITEN: /* Aguarda tempo para liberar próxima leitura */
            //DEBUG_PRINT("WAITOK\r");
            
            /* Timeout - aguarda tempo para ativar próxima leitura */
            delay_ms(1);
            if (++timeout >= TIMEOUT_ENABLE) state = IDLE;

            last_state = WAITEN;
            break;

        case OK: /* Leitura concluída */
            DEBUG_PRINT("OK\r");

            /* Calcula e mostra a velocidade */
            delta_ticks = abs(ticks2 - ticks1);
            speed_km_h = 3.6f * (DELTA_S / (float)(delta_ticks * TICK_TMR1));

            /* Ativa o alerta de velocidade alta */
            if (speed_km_h > SPEED_LIMIT)
            {
                DEBUG_PRINT("SPEED_LIMIT\r");

                delta_ticks = tmr1;
                ALERT = 1;          // Liga a saída da sirene

                if (speed_km_h > 99) speed_km_h = 99;
            }

            /* Converte a velocidade para código BCD */
            PORTC = decToBcd((uint8_t)(speed_km_h + 0.5f));

            state = WAITEN;
            last_state = OK;
            timeout = 0;
            break;

        case ERROR: /* Erro na leitura */
            if (last_state == WAIT1 || last_state == WAIT2)
            {
                DEBUG_PRINT("ERROR: timeout\r");
                PORTC = 0x00;
            }
            else
            {
                DEBUG_PRINT("ERROR: desconhecido\r");
                PORTC = 0xFF;
            }

            state = IDLE;
            last_state = ERROR;
            timeout = 0;
            break;

        default:
            break;

        } // Fim do switch

        /* Verifica o tempo e desliga o alerta - radar continua funcionando mesmo em alerta */
        if (ALERT == 1)
        {
            if (((tmr1 - delta_ticks) * TICK_TMR1) > ALERT_TIME) ALERT = 0;
        }
        

    } // Fim do while

} // Fim da main