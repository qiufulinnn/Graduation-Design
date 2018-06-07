module SPIslaver(
	//输入端口
	clk,					//系统时钟
	rst_n,					//系统复位
	spi_cs,					//spi片选
	spi_sck,				//spi时钟
	spi_mosi,				//spi数据
	
    txd_data,				//数据发送
	txd_en, 				//发送使能
	//输出端口	
	spi_miso,				//spi数据
	txd_flag,				//发送完成标志

	rxd_data,				//数据接收
	rxd_flag 				//接收完成标志
	);
	
//---外部端口定义---//
input 					clk;				//系统时钟
input 					rst_n;				//系统复位
input 					spi_cs;				//spi片选
input 					spi_sck;			//spi时钟
//spi数据接收
input 					spi_mosi;			//spi数据
output reg [7:0]        rxd_data;               //数据接收
output reg              rxd_flag;               //接收完成标志
//spi数据发送
input [7:0]				txd_data;    		//数据发送
input 					txd_en; 			//发送使能
output reg 			 	spi_miso;				//spi数据
output reg  			txd_flag;	 			//发送完成标志

//---内部端口定义---//
reg 					spi_cs_r0;
reg 					spi_cs_r1;
reg 					spi_sck_r0;
reg 					spi_sck_r1;
reg 					spi_mosi_r0;
reg 					spi_mosi_r1;
reg [3:0]				rxd_cnt;
reg [7:0]				rxd_data_r;
reg [1:0]				txd_state;
reg [3:0]				txd_cnt;

wire 					mcu_cs;
wire 					mcu_data;
wire 					mcu_read_flag;
wire  					mcu_read_done;

wire 					mcu_write_flag;
wire 					mcu_write_done;
wire 					mcu_write_start;

//---逻辑功能实现---//
//同步信号模块
always @ (posedge clk or negedge rst_n)
    begin
        if (!rst_n) 
            begin
                spi_cs_r0 <= 1'b1;
                spi_cs_r1 <= 1'b1;
                spi_sck_r0 <= 1'b0;
                spi_sck_r1 <= 1'b0;
                spi_mosi_r0 <= 1'b0;
                spi_mosi_r1 <= 1'b0;
            end
        else 
            begin
                spi_cs_r0 <= spi_cs;
                spi_cs_r1 <= spi_cs_r0;
                spi_sck_r0 <= spi_sck;
                spi_sck_r1 <= spi_sck_r0;
                spi_mosi_r0 <= spi_mosi;
                spi_mosi_r1 <= spi_mosi_r0;
            end
    end

//信号处理部分
assign mcu_cs = spi_cs_r1;					
assign mcu_data = spi_mosi_r1;				
assign mcu_read_flag = (spi_sck_r0 & ~spi_sck_r1) ? 1'b1 : 1'b0;					//sck上升沿
assign mcu_read_done = (spi_cs_r0 & ~spi_cs_r1 & (rxd_cnt == 4'd8)) ? 1'b1 : 1'b0;	//cs上升沿

//数据接收处理部分
always @ (posedge clk or negedge rst_n)
    begin
        if (!rst_n) 
            begin
                rxd_cnt <= 4'd0;
                rxd_data_r <= 8'd0;
            end
        else if (!mcu_cs)
            begin
                if (mcu_read_flag) 
                    begin
                        rxd_data_r[3'd7 - rxd_cnt] <= mcu_data;		//数据接收
                        rxd_cnt <= rxd_cnt + 1'b1;					//读取计数
                    end
                else 												//
                    begin
                        rxd_data_r <= rxd_data_r;
                        rxd_cnt <= rxd_cnt;
                    end
            end
        else 
            begin
                rxd_data_r <= rxd_data_r;							
                rxd_cnt <= 4'd0; 									//清零
            end
    end

//输出部分
always @ (posedge clk or negedge rst_n)
    begin
        if (!rst_n) 
            begin
                rxd_data <= 8'd0;
                rxd_flag <= 1'b0;
            end
        else if (mcu_read_done)             //主机拉高了CS
            begin
                rxd_data <= rxd_data_r;     //将本次读到的数据导出
                rxd_flag <= 1'b1;           //读结束标志拉高,这个高电平只持续一个时钟周期
            end
        else                                //
            begin
                rxd_data <= rxd_data;       //
                rxd_flag <= 1'b0;
            end
    end

//发送信号处理部分
assign mcu_write_flag = (~spi_sck_r0 & spi_sck_r1) ? 1'b1 : 1'b0;			//sck下降沿
assign mcu_write_done = (spi_cs_r0 & ~spi_cs_r1) ? 1'b1 : 1'b0; 			//cs上升沿
assign mcu_write_start = (~spi_cs_r0 & spi_cs_r1) ? 1'b1 : 1'b0; 			//cs下降沿,进入通信阶段

//数据发送状态机
localparam T_IDLE           = 2'd0;
localparam T_START          = 2'd1;
localparam T_SEND           = 2'd2;
localparam SPI_MISO_DEFAULT = 1'b1;

always @ (posedge clk or negedge rst_n)
    begin
        if (!rst_n) 
            begin
                txd_cnt <= 4'd0;
                spi_miso <= SPI_MISO_DEFAULT;
                txd_state <= T_IDLE;
            end
        else 
            begin
                case (txd_state) 
                    T_IDLE:
                        begin
                            txd_cnt  <= 4'd0;
                            spi_miso <= SPI_MISO_DEFAULT;
                            if (txd_en)                         //只要使能拉高就进入开始状态
                                begin                           //在主机发数据的同时向主机发
                                    txd_state <= T_START;       //送数据.
                                end
                            else 
                                begin
                                    txd_state <= T_IDLE;
                                end
                        end
                    T_START:
                        begin
                            if (mcu_write_start) 
                                begin
                                    spi_miso  <= txd_data[3'd7 - txd_cnt[2:0]];
                                    txd_cnt   <= txd_cnt + 1'b1;
                                    txd_state <= T_SEND;
                                end
                            else 
                                begin
                                    spi_miso  <= spi_miso;
                                    txd_cnt   <= txd_cnt;
                                    txd_state <= T_START;
                                end
                        end
                    T_SEND:
                        begin
                            if (mcu_write_done) 
                                begin
                                    txd_state <= T_IDLE;
                                end
                            else 
                                begin
                                    txd_state <= T_SEND;
                                end

                            if (!mcu_cs) 
                                begin
                                    if (mcu_write_flag) 
                                        begin
                                            if (txd_cnt < 4'd8) 
                                                begin
                                                    spi_miso <= txd_data[3'd7 - txd_cnt[2:0]];
                                                    txd_cnt  <= txd_cnt + 1'b1;
                                                end
                                            else 
                                                begin
                                                    spi_miso <= 1'b1;
                                                    txd_cnt  <= txd_cnt;
                                                end
                                        end
                                    else 
                                        begin
                                            spi_miso <= spi_miso;
                                            txd_cnt  <= txd_cnt;
                                        end
                                end
                            else 
                                begin
                                    spi_miso <= SPI_MISO_DEFAULT;
                                    txd_cnt  <= 4'd0;
                                end
                        end                        
                    default:
                        begin
                            txd_cnt   <= 4'd0;
                            spi_miso  <= SPI_MISO_DEFAULT;
                            txd_state <= T_IDLE;
                        end
                endcase
            end
    end

//发送完成标志部分
always @ (posedge clk or negedge rst_n)
    begin
        if (!rst_n) 
            begin
                txd_flag <= 1'b0;
            end
        else 
            begin
                txd_flag <= mcu_write_done;         //CS拉高说明写完,这个高电平只持续一个时钟周期
            end
    end

endmodule