#line 1 "C:/Users/Uinstrutor/Documents/ProfKleber/PROJETOS/Radar/radar_pic/radar.c"
#line 1 "c:/users/public/documents/mikroelektronika/mikroc pro for pic/include/stdint.h"




typedef signed char int8_t;
typedef signed int int16_t;
typedef signed long int int32_t;


typedef unsigned char uint8_t;
typedef unsigned int uint16_t;
typedef unsigned long int uint32_t;


typedef signed char int_least8_t;
typedef signed int int_least16_t;
typedef signed long int int_least32_t;


typedef unsigned char uint_least8_t;
typedef unsigned int uint_least16_t;
typedef unsigned long int uint_least32_t;



typedef signed char int_fast8_t;
typedef signed int int_fast16_t;
typedef signed long int int_fast32_t;


typedef unsigned char uint_fast8_t;
typedef unsigned int uint_fast16_t;
typedef unsigned long int uint_fast32_t;


typedef signed int intptr_t;
typedef unsigned int uintptr_t;


typedef signed long int intmax_t;
typedef unsigned long int uintmax_t;
#line 34 "C:/Users/Uinstrutor/Documents/ProfKleber/PROJETOS/Radar/radar_pic/radar.c"
enum states {IDLE, READ1, READ2, WAIT1, WAIT2, WAITEN, OK, ERROR};
#line 51 "C:/Users/Uinstrutor/Documents/ProfKleber/PROJETOS/Radar/radar_pic/radar.c"
volatile uint8_t state = IDLE, last_state = IDLE, temp = 0;
volatile int32_t tmr1 = 0, ticks1 = 0, ticks2 = 0, timeout = 0;



void interrupt(void)
{

 if (PIR1.TMR1IF == 1)
 {
 TMR1H = 0xFC;
 TMR1L = 0x18;

 tmr1++;
 PORTD.RD0 = ~PORTD.RD0;

 PIR1.TMR1IF = 0;
 }


 if (INTCON.RBIF == 1)
 {
 if ( PORTB.RB4  ==  1  && (state == IDLE || state == WAIT1))
 {
 ticks1 = tmr1;
 state = READ1;

 PORTD.RD1 = ~PORTD.RD1;
 }

 if ( PORTB.RB5  ==  1  && (state == IDLE || state == WAIT2))
 {
 ticks2 = tmr1;
 state = READ2;

 PORTD.RD2 = ~PORTD.RD2;
 }

 temp = PORTB;
 INTCON.RBIF = 0;
 }
}
#line 108 "C:/Users/Uinstrutor/Documents/ProfKleber/PROJETOS/Radar/radar_pic/radar.c"
uint8_t decToBcd(uint8_t val)
{
 return ((val / 10 * 16) + (val % 10));
}



void main(void)
{

 int32_t delta_ticks = 0;
 float speed_km_h = 0;


 PIR1.TMR1IF = 0;
 TMR1H =  0xFC ;
 TMR1L =  0x18 ;
 T1CON.TMR1CS = 0;
 T1CON.T1CKPS0 = 0;
 T1CON.T1CKPS1 = 0;


 ADCON1 = 7;
 TRISB = 0b00110000;
 TRISC = 0b00000000;
 TRISD = 0b00000000;
 PORTB = PORTC = PORTD = 0;


 delay_ms(2000);
 PIE1.TMR1IE = 1;
 INTCON.PEIE = 1;
 T1CON.TMR1ON = 1;
 INTCON.RBIE = 1;
 INTCON.GIE = 1;
#line 152 "C:/Users/Uinstrutor/Documents/ProfKleber/PROJETOS/Radar/radar_pic/radar.c"
 while (1)
 {

 switch (state)
 {
 case IDLE:


 last_state = IDLE;
 break;

 case READ1:
  ;


 if (last_state == IDLE) state = WAIT2;
 else if (last_state == WAIT1) state = OK;
 else state = ERROR;

 last_state = READ1;
 timeout = 0;
 break;

 case READ2:
  ;


 if (last_state == IDLE) state = WAIT1;
 else if (last_state == WAIT2) state = OK;
 else state = ERROR;

 last_state = READ2;
 timeout = 0;
 break;

 case WAIT1:



 delay_ms(1);
 if (++timeout >=  3000 ) state = ERROR;

 last_state = WAIT1;
 break;

 case WAIT2:



 delay_ms(1);
 if (++timeout >=  3000 ) state = ERROR;

 last_state = WAIT2;
 break;

 case WAITEN:



 delay_ms(1);
 if (++timeout >=  1000 ) state = IDLE;

 last_state = WAITEN;
 break;

 case OK:
  ;


 delta_ticks = abs(ticks2 - ticks1);
 speed_km_h = 3.6f * ( 2.0f  / (float)(delta_ticks *  0.0002f ));


 if (speed_km_h >  20 )
 {
  ;

 delta_ticks = tmr1;
  PORTB.RB1  = 1;

 if (speed_km_h > 99) speed_km_h = 99;
 }


 PORTC = decToBcd((uint8_t)(speed_km_h + 0.5f));

 state = WAITEN;
 last_state = OK;
 timeout = 0;
 break;

 case ERROR:
 if (last_state == WAIT1 || last_state == WAIT2)
 {
  ;
 PORTC = 0x00;
 }
 else
 {
  ;
 PORTC = 0xFF;
 }

 state = IDLE;
 last_state = ERROR;
 timeout = 0;
 break;

 default:
 break;

 }


 if ( PORTB.RB1  == 1)
 {
 if (((tmr1 - delta_ticks) *  0.0002f ) >  2 )  PORTB.RB1  = 0;
 }


 }

}
