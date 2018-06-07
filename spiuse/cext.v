module cext (
	input 			sclk,
	input 			s_rst_n,
	input 			spi_cs,
	input 			spi_sck,
	input 			spi_mosi,

	output 			spi_miso,
	output 	led
	);

//---内部端口定义---//
wire   			rxd_flag;
wire 	[7:0]	rxd_data;

reg			led_temp;
reg 	[7:0]	yuzhi_temp;
reg 	[7:0]	ch_select_temp;

/* 组合电路,根据外部按键来选择相应的索贝尔算法阀值 */
always @ (posedge sclk or negedge s_rst_n)
begin
	if(!s_rst_n)
	begin	
		led_temp <= 1'b1;
	end
	else if (rxd_flag)
	case(rxd_data)
		8'h01: led_temp		<=	1'b1; 	
		8'h02: led_temp		<=	1'b0; 
		8'h03: led_temp		<=	1'b1; 	
		8'h04: led_temp		<=	1'b0; 	
		8'h05: led_temp		<=	1'b1; 	
		8'h06: led_temp		<=	1'b0; 	
		8'h07: led_temp		<=	1'b1; 
		8'h08: led_temp		<=	1'b0;
		default: 
			begin
				led_temp 		<=	1'b1;
			end
	endcase
end

assign led = led_temp;

 SPIslaver SPIslaver_inst
 (
 	.clk		 	   (sclk		),          
 	.rst_n 			(s_rst_n	),      
 	.spi_cs 		   (spi_cs 	),    
 	.spi_sck 		(spi_sck 	),  
 	.spi_mosi 		(spi_mosi 	),
 	.spi_miso 		(spi_miso 	),  
 	.rxd_data 		(rxd_data 	),
 	.rxd_flag 		(rxd_flag 	) 
 	);
    
endmodule

