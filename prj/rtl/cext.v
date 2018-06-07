module cext (
	input 			sclk,
	input 			s_rst_n,
	input 			spi_cs,
	input 			spi_sck,
	input 			spi_mosi,

	input 			pclk,
	input 			vsync,
	
	output 			spi_miso,
	output [7:0]	yuzhi,
	output 			ch_select
	);

//---内部端口定义---//
wire   		rxd_flag;
wire 	[7:0]	rxd_data;

reg 	[7:0]	yuzhi_temp;
reg 		   ch_select_temp;
reg 			ch_select_tempr1;

/* 组合电路,根据外部按键来选择相应的索贝尔算法阀值 */
always @ (posedge sclk or negedge s_rst_n)
begin
	if(!s_rst_n)
	begin
		yuzhi_temp <= 8'd50;	
		ch_select_temp <= 1'b0;
	end
	else if (rxd_flag)
	case(rxd_data)
		8'h01: yuzhi_temp		<=	8'd20; 	
		8'h02: yuzhi_temp		<=	8'd30; 
		8'h03: yuzhi_temp		<=	8'd40; 	
		8'h04: yuzhi_temp		<=	8'd50; 	
		8'h05: yuzhi_temp		<=	8'd60; 	
		8'h06: yuzhi_temp		<=	8'd70; 	
		8'h07: yuzhi_temp		<=	8'd80; 
		8'h08: yuzhi_temp		<=	8'd90;
		8'hAA: ch_select_temp <= !ch_select_temp;
//		8'h5A：ch_select_temp <= 1'b0;
		default: 
			begin
				yuzhi_temp 		<=	8'd50;
				ch_select_temp <= 1'b0;
			end
	endcase
end

always @ (posedge pclk or negedge s_rst_n)
begin
	if(!s_rst_n)
		ch_select_tempr1 <= 1'b0;
	else if (vsync)
		ch_select_tempr1 <= ch_select_temp;
end

assign ch_select = ch_select_tempr1;
assign yuzhi = yuzhi_temp;

 SPIslaver SPIslaver1
 (
 	.clk		 	   (sclk		),          
 	.rst_n 		(s_rst_n	),      
 	.spi_cs 		   (spi_cs 	),    
 	.spi_sck 		(spi_sck 	),  
 	.spi_mosi 		(spi_mosi 	),
 	.spi_miso 		(spi_miso 	),  
 	.rxd_data 		(rxd_data 	),
 	.rxd_flag 		(rxd_flag 	) 
 	);
    
endmodule