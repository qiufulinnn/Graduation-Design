 /**
  ******************************************************************************
  * @file    main.c
  * @author  fire
  * @version V1.0
  * @date    2013-xx-xx
  * @brief   华邦 8M串行flash测试，并将测试信息通过串口1在电脑的超级终端中打印出来
  ******************************************************************************
  * @attention
  *
  * 实验平台:野火 iSO STM32 开发板 
  * 论坛    :http://www.chuxue123.com
  * 淘宝    :http://firestm32.taobao.com
  *
  ******************************************************************************
  */ 
#include "stm32f10x.h"
#include "bsp_usart1.h"
#include "bsp_spi_flash.h"
#include "bsp_key.h" 

typedef enum { FAILED = 0, PASSED = !FAILED} TestStatus;

/* 获取缓冲区的长度 */
#define TxBufferSize1   (countof(TxBuffer1) - 1)
#define RxBufferSize1   (countof(TxBuffer1) - 1)
#define countof(a)      (sizeof(a) / sizeof(*(a)))

// 函数原型声明
void Delay(__IO uint32_t nCount);
TestStatus Buffercmp(uint8_t* pBuffer1, uint8_t* pBuffer2, uint16_t BufferLength);

/*
 * 函数名：main
 * 描述  ：主函数
 * 输入  ：无
 * 输出  ：无
 */
int main(void)
{ 
	uint8_t i = 0;
	uint8_t ch = 0x04;	
	/* 配置串口1为：115200 8-N-1 */
	USART1_Config();
	SPI_FLASH_Init();
	Key_GPIO_Config();

	while(1)
	 {
		 if(!Key_Scan(GPIOC,GPIO_Pin_11,1))//&i)		//阈值减少
		 {
			// GPIO_ResetBits(GPIOC, GPIO_Pin_5);
			 GPIOC->ODR ^=GPIO_Pin_5;
			if(ch==0x01)
					ch=0x08;
			else
					ch--;
			SPI_FLASH_CS_LOW();
			/* Send "Write Enable" instruction */
			SPI_FLASH_SendByte(ch);
			/* Deselect the FLASH: Chip Select high */
			SPI_FLASH_CS_HIGH();
		 }

		 if(!Key_Scan(GPIOC,GPIO_Pin_10,1))//&i)		//阈值增加
		 {
			// GPIO_ResetBits(GPIOC, GPIO_Pin_5);
			 GPIOC->ODR ^=GPIO_Pin_5;
			if(ch==0x08)
					ch=0x01;
			else
					ch++;
			SPI_FLASH_CS_LOW();
			/* Send "Write Enable" instruction */
			SPI_FLASH_SendByte(ch);
			/* Deselect the FLASH: Chip Select high */
			SPI_FLASH_CS_HIGH();
		 }
		 
		 if(!Key_Scan(GPIOC,GPIO_Pin_12,1))		//显示按键
		 {
			 i = !i;
			//GPIO_ResetBits(GPIOB, GPIO_Pin_0);
			 GPIOB->ODR ^=GPIO_Pin_0;
			SPI_FLASH_CS_LOW();
			/* Send "Write Enable" instruction */
			SPI_FLASH_SendByte(0xAA);
			/* Deselect the FLASH: Chip Select high */
			SPI_FLASH_CS_HIGH();
		 }	 
		 
		 if(!Key_Scan(GPIOD,GPIO_Pin_2,1))		//模式按键
		 {
			i = 0;
			//GPIO_ResetBits(GPIOB, GPIO_Pin_0);
			 GPIOB->ODR ^=GPIO_Pin_0;
			SPI_FLASH_CS_LOW();
			/* Send "Write Enable" instruction */
			SPI_FLASH_SendByte(0xFF);
			/* Deselect the FLASH: Chip Select high */
			SPI_FLASH_CS_HIGH();
		 }	 
   }
 }


void Delay(__IO uint32_t nCount)
{
  for(; nCount != 0; nCount--);
}
/*********************************************END OF FILE**********************/
