 /**
  ******************************************************************************
  * @file    main.c
  * @author  fire
  * @version V1.0
  * @date    2013-xx-xx
  * @brief   ���� 8M����flash���ԣ�����������Ϣͨ������1�ڵ��Եĳ����ն��д�ӡ����
  ******************************************************************************
  * @attention
  *
  * ʵ��ƽ̨:Ұ�� iSO STM32 ������ 
  * ��̳    :http://www.chuxue123.com
  * �Ա�    :http://firestm32.taobao.com
  *
  ******************************************************************************
  */ 
#include "stm32f10x.h"
#include "bsp_usart1.h"
#include "bsp_spi_flash.h"
#include "bsp_key.h" 

typedef enum { FAILED = 0, PASSED = !FAILED} TestStatus;

/* ��ȡ�������ĳ��� */
#define TxBufferSize1   (countof(TxBuffer1) - 1)
#define RxBufferSize1   (countof(TxBuffer1) - 1)
#define countof(a)      (sizeof(a) / sizeof(*(a)))

// ����ԭ������
void Delay(__IO uint32_t nCount);
TestStatus Buffercmp(uint8_t* pBuffer1, uint8_t* pBuffer2, uint16_t BufferLength);

/*
 * ��������main
 * ����  ��������
 * ����  ����
 * ���  ����
 */
int main(void)
{ 
	uint8_t i = 0;
	uint8_t ch = 0x04;	
	/* ���ô���1Ϊ��115200 8-N-1 */
	USART1_Config();
	SPI_FLASH_Init();
	Key_GPIO_Config();

	while(1)
	 {
		 if(!Key_Scan(GPIOC,GPIO_Pin_11,1))//&i)		//��ֵ����
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

		 if(!Key_Scan(GPIOC,GPIO_Pin_10,1))//&i)		//��ֵ����
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
		 
		 if(!Key_Scan(GPIOC,GPIO_Pin_12,1))		//��ʾ����
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
		 
		 if(!Key_Scan(GPIOD,GPIO_Pin_2,1))		//ģʽ����
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
