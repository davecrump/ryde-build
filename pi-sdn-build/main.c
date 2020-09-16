#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <stdlib.h>
#include <wiringPi.h>

#include "timer.h"

int8_t IndicationGPIO;
int8_t ButtonGPIO;
_timer_t shutdown_button_timer;

void Edge_ISR(void);
void Shutdown_Function(void);

int main( int argc, char *argv[] )
{
  IndicationGPIO = -1;
  if( argc == 2 )
  {
    /* Only Input GPIO provided */
    ButtonGPIO = atoi(argv[1]);
    if(ButtonGPIO < 0 || ButtonGPIO > 31)
    {
      printf("ERROR: Input GPIO is out of bounds!\n");
      printf("Input GPIO was %d\n",ButtonGPIO);
      return 0;
    }
  }
  else if( argc == 3 ) 
  {
    /* Both Input and Output GPIO provided */
    ButtonGPIO = atoi(argv[1]);
    if(ButtonGPIO < 0 || ButtonGPIO > 31)
    {
      printf("ERROR: Button GPIO is out of bounds!\n");
      printf("Button GPIO was %d\n",ButtonGPIO);
      return 0;
    }
    IndicationGPIO = atoi(argv[2]);
    if(IndicationGPIO < 0 || IndicationGPIO > 31)
    {
      printf("ERROR: Indication GPIO is out of bounds!\n");
      printf("Indication GPIO was %d\n",IndicationGPIO);
      return 0;
    }
  }
  else
  {
    printf("ERROR: Incorrect number of parameters!\n");
    printf(" == pi-sdn == by Phil Crump <phil@philcrump.co.uk ==\n");
    printf(" == modified by Dave Crump <dave.g8gkq@gmail.com  ==\n");
    printf("  usage: pi-sdn x [y]\n");
    printf("    x: Button GPIO to listen for falling edge\n");
    printf("       Button GPIO must remain low for 5 seconds to trigger shutdown.\n");
    printf("    y: Indication GPIO to output HIGH, to detect successful shutdown (optional).\n");
    printf(" ----- \n");
    printf("Notes:\n");
    printf(" * WiringPi GPIO pin numbers are used. (0-20)\n");
    printf("    http://wiringpi.com/pins/\n");
    return 0;
  }
    
  /* Set up wiringPi module */
  if (wiringPiSetup() < 0)
  {
    return 0;
  }
    
  if(IndicationGPIO >= 0)
  {
    pinMode(IndicationGPIO, OUTPUT);
    digitalWrite(IndicationGPIO, HIGH);
  }

  /* Set up GPIOi as Input */
  pinMode(ButtonGPIO, INPUT);
  wiringPiISR(ButtonGPIO, INT_EDGE_BOTH, Edge_ISR);
    
  /* Spin loop while waiting for ISR */
  while(1)
  {
    delay(10000);
  }
  return 0;
}

void Edge_ISR(void)
{
  printf("ISR triggered\n");

  if(digitalRead(ButtonGPIO) == LOW)
  {
    /* Try to reset the timer incase it's already running */
    timer_reset(&shutdown_button_timer);

    /* Set timer */
    timer_set(&shutdown_button_timer, 1000, Shutdown_Function);
  }
  else
  {
    /* Disarm timer */
    timer_reset(&shutdown_button_timer);
  }
}

void Shutdown_Function(void)
{
  if(digitalRead(ButtonGPIO) == LOW)  // Check that power button is still low
  {
    /* Shut. It. Down */
    system("sudo shutdown now");
    exit;
  }
    // else keep listening
}

