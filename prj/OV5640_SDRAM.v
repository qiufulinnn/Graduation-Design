module OV5640_SDRAM(
	clk,
	reset_n,

	cmos_sclk,
	cmos_sdat,
	cmos_vsync,
	cmos_href,
	cmos_pclk,
	cmos_xclk,
	cmos_data,
	cmos_rst_n,
	cmos_pwdn,
	
	//sdram control
	sdram_clk,		
	sdram_cke,		
	sdram_cs_n,		
	sdram_we_n,		
	sdram_cas_n,
	sdram_ras_n,	
	sdram_dqm,
	sdram_ba,
	sdram_addr,
	sdram_dq,		
	
	//VGA port
	TFT_VCLK,			
	TFT_HS,
	TFT_VS,		
	TFT_RGB,		
	TFT_DE,
	TFT_BL,
	
	spi_cs, 
	spi_sck, 
	spi_mosi 

	
);

	input		clk;
	input		reset_n;
	
	input 		spi_cs; 
	input 		spi_sck;
	input 		spi_mosi; 
	//cmos interface
	output		cmos_sclk;
	inout			cmos_sdat;
	input			cmos_vsync;
	input			cmos_href;
	input			cmos_pclk;
	output		cmos_xclk;
	input	[7:0]	cmos_data;
	output		cmos_rst_n;	
	output		cmos_pwdn;	
	
	//sdram control
	output				sdram_clk;	
	output				sdram_cke;		
	output				sdram_cs_n;	
	output				sdram_we_n;
	output				sdram_cas_n;	
	output				sdram_ras_n;	
	output	[1:0]		sdram_dqm;		
	output	[1:0]		sdram_ba;		
	output	[12:0]	sdram_addr;
	inout		[15:0]	sdram_dq;		
	
	//lcd port
	output			TFT_VCLK;		
	output			TFT_HS;		 
	output			TFT_VS;	
	output			TFT_DE;
	output	[15:0]	TFT_RGB;		
	output TFT_BL;
	assign TFT_BL = 1;
	
	
	assign cmos_pwdn = 1'b0;
   assign cmos_rst_n = 1'b1;

	wire clk_sdr_ctrl;
	
	wire clk_tft;
	wire vga_data_req;
	wire [15:0]vga_data_in;
	
	wire clk_cmos;

	//cmos video image capture
	wire			cmos_frame_vsync;	//cmos frame data vsync valid signal
	wire			cmos_frame_href;	//cmos frame data href vaild  signal
	wire	[15:0]cmos_frame_data;	//cmos frame data output: {cmos_data[7:0]<<8, cmos_data[7:0]}	
	wire			cmos_frame_clken;	//cmos frame data output/capture enable clock
	wire	[7:0]	cmos_fps_rate;		//cmos image output rate
	
	wire cmos_init_flag;
	
	wire			[15:0]		fifo_wrdata;				//Sobel FIFO的写数据
	wire							fifo_wrreq;					//Sobel FIFO的写使能
	wire			[7:0]			yuzhi;						//yuzhi大小
	wire 							ch_select;
	
	pll pll(
		.inclk0(clk),
		.c0(clk_sdr_ctrl),
		.c1(sdram_clk),
		.c2(clk_tft),
		.c3(clk_cmos)
	);
	
	wire	i2c_config_done;
	I2C_OV5640_Init_RGB565	u_I2C_OV5640_Init_RGB565
	(
		.clk				(clk),		//50MHz
		.rst_n			(reset_n),	//Global Reset
		.i2c_sclk		(cmos_sclk),	//I2C CLOCK
		.i2c_sdat		(cmos_sdat),	//I2C DATA
			
		.config_done	(cmos_init_flag)	//Config Done
	);
	
	CMOS_Capture_RGB565	
	#(
		.CMOS_FRAME_WAITCNT		(4'd10)				//Wait n fps for steady(OmniVision need 10 Frame)
	)
	u_CMOS_Capture_RGB565
	(
		//global clock
		.clk_cmos				(clk_cmos),			//24MHz CMOS Driver clock input
		.rst_n					(reset_n & cmos_init_flag),	//global reset

		//CMOS Sensor Interface
		.cmos_pclk				(cmos_pclk),  		//24MHz CMOS Pixel clock input
		.cmos_xclk				(cmos_xclk),		//24MHz drive clock
		.cmos_din				(cmos_data),		//8 bits cmos data input
		.cmos_vsync				(cmos_vsync),		//L: vaild, H: invalid
		.cmos_href				(cmos_href),		//H: vaild, L: invalid
		
		//CMOS SYNC Data output
		.cmos_frame_vsync		(cmos_frame_vsync),	//cmos frame data vsync valid signal
		.cmos_frame_href		(cmos_frame_href),	//cmos frame data href vaild  signal
		.cmos_frame_data		(cmos_frame_data),	//cmos frame RGB output: {{R[4:0],G[5:3]}, {G2:0}, B[4:0]}	
		.cmos_frame_clken		(cmos_frame_clken),	//cmos frame data output/capture enable clock
		
		//user interface
		.cmos_fps_rate			(cmos_fps_rate)		//cmos image output rate
	);

	Peri_Camera_Sobel 		Peri_Camera_Sobel_Init
	(
		.sclk					(cmos_pclk			), //时钟端口 				
		.s_rst_n					(reset_n					),	//复位端口
		.yuzhi					(yuzhi					),	//按键端口	
		.original_href			(cmos_frame_href		),	//没有处理过的行同步信号
		.original_wrreq		(cmos_frame_clken		),	//没有处理过的写请求信号
		.original_wrdata		(cmos_frame_data		),	//没有处理过的16位数据		
		.fifo_wrdata			(fifo_wrdata			),	//FIFO的写数据
		.fifo_wrreq				(fifo_wrreq				)	//FIFO的写使能
	);
	
	wire [15:0] datain;
	wire reqin;
	
	assign datain = ch_select? fifo_wrdata : cmos_frame_data;
	assign reqin = ch_select? fifo_wrreq : cmos_frame_clken;
	
	Sdram_Control_4Port Sdram_Control_4Port(
		//	HOST Side
		.CTRL_CLK(clk_sdr_ctrl),	//输入参考时钟，默认100M，如果为其他频率，请修改sdram_pll核设置
		.RESET_N(reset_n),	//复位输入，低电平复位

		//	FIFO Write Side 1
		.WR1_DATA(fifo_wrdata),			//写入端口1的数据输入端，16bit
		.WR1(fifo_wrreq),					//写入端口1的写使能端，高电平写入
		.WR1_ADDR(0),			//写入端口1的写起始地址
		.WR1_MAX_ADDR(800*480),		//写入端口1的写入最大地址
		.WR1_LENGTH(256),			//一次性写入数据长度
		.WR1_LOAD((~reset_n) &(~cmos_init_flag)),			//写入端口1清零请求，高电平清零写入地址和fifo
		.WR1_CLK(cmos_pclk),				//写入端口1 fifo写入时钟
		.WR1_FULL(),			//写入端口1 fifo写满信号
		.WR1_USE(),				//写入端口1 fifo已经写入的数据长度

		//	FIFO Write Side 2
		.WR2_DATA(),			//写入端口2的数据输入端，16bit
		.WR2(1'b0),					//写入端口2的写使能端，高电平写入
		.WR2_ADDR(0),			//写入端口2的写起始地址
		.WR2_MAX_ADDR(800*480),		//写入端口2的写入最大地址
		.WR2_LENGTH(8),			//一次性写入数据长度
		.WR2_LOAD(1'b0),			//写入端口2清零请求，高电平清零写入地址和fifo
		.WR2_CLK(1'b0),				//写入端口2 fifo写入时钟
		.WR2_FULL(),			//写入端口2 fifo写满信号
		.WR2_USE(),				//写入端口2 fifo已经写入的数据长度

		//	FIFO Read Side 1
		.RD1_DATA(vga_data_in),			//读出端口1的数据输出端，16bit
		.RD1(vga_data_req),					//读出端口1的读使能端，高电平读出
		.RD1_ADDR(0),			//读出端口1的读起始地址
		.RD1_MAX_ADDR(800*480),		//读出端口1的读出最大地址
		.RD1_LENGTH(256),			//一次性读出数据长度
		.RD1_LOAD((~reset_n) & (~cmos_init_flag)),			//读出端口1 清零请求，高电平清零读出地址和fifo
		.RD1_CLK(clk_tft),				//读出端口1 fifo读取时钟
		.RD1_EMPTY(),			//读出端口1 fifo读空信号
		.RD1_USE(),				//读出端口1 fifo已经还可以读取的数据长度

		//	FIFO Read Side 2
		.RD2_DATA(),			//读出端口2的数据输出端，16bit
		.RD2(1'b0),					//读出端口2的读使能端，高电平读出
		.RD2_ADDR(),			//读出端口2的读起始地址
		.RD2_MAX_ADDR(),		//读出端口2的读出最大地址
		.RD2_LENGTH(),			//一次性读出数据长度
		.RD2_LOAD(),			//读出端口2清零请求，高电平清零读出地址和fifo
		.RD2_CLK(1'b0),				//读出端口2 fifo读取时钟
		.RD2_EMPTY(),			//读出端口2 fifo读空信号
		.RD2_USE(),				//读出端口2 fifo已经还可以读取的数据长度

		//	SDRAM Side
		.SA(sdram_addr),		//SDRAM 地址线，
		.BA(sdram_ba),		//SDRAM bank地址线
		.CS_N(sdram_cs_n),		//SDRAM 片选信号
		.CKE(sdram_cke),		//SDRAM 时钟使能
		.RAS_N(sdram_ras_n),	//SDRAM 行选中信号
		.CAS_N(sdram_cas_n),	//SDRAM 列选中信号
		.WE_N(sdram_we_n),		//SDRAM 写请求信号
		.DQ(sdram_dq),		//SDRAM 双向数据总线
		.DQM(sdram_dqm)		//SDRAM 数据总线高低字节屏蔽信号
	);	
	
	TFT_CTRL_800_480_16bit TFT_CTRL_800_480_16bit(
		.Clk33M(clk_tft),	//系统输入时钟33MHZ
		.Rst_n(reset_n & cmos_init_flag),	//复位输入，低电平复位
		.data_in(vga_data_in),	//待显示数据
		.hcount(),		//TFT行扫描计数器
		.vcount(),		//TFT场扫描计数器
		.TFT_RGB(TFT_RGB),	//TFT数据输出
		.TFT_HS(TFT_HS),		//TFT行同步信号
		.TFT_VS(TFT_VS),		//TFT场同步信号
		.TFT_BLANK(),
		.TFT_VCLK(TFT_VCLK),
		.TFT_DE(TFT_DE)
	);
	assign vga_data_req = TFT_DE;

	cext cext_inst (
	.sclk 		(clk 		),
	.s_rst_n		(reset_n 	),
	.spi_cs 		(spi_cs 	),
	.spi_sck 	(spi_sck 	),
	.spi_mosi 	(spi_mosi 	),
	
	.pclk 		(cmos_pclk),
	.vsync		(cmos_vsync),
	
	.yuzhi 		(yuzhi 		),
	.ch_select  (ch_select)
	);
	
endmodule
