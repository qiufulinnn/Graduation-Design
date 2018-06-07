#ifndef __USART1_H
#define	__USART1_H

#include "stm32f10x.h"
#include <stdio.h>

void USART1_Config(void);
int fputc(int ch, FILE *f);
int fgetc(FILE *f);
void USART1_printf(USART_TypeDef* USARTx, uint8_t *Data,...);
static char *itoa( int value, char *string, int radix );
#define     PC_Usart( fmt, ... )                USART_printf ( USART1, fmt, ##__VA_ARGS__ )
#endif /* __USART1_H */
