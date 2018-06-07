//---------------------------------------------------------------------------
// -- qfl
//---------------------------------------------------------------------------
module Peri_Camera_Sobel
(
	/* 时钟和复位 */
	sclk,s_rst_n,
	/* 用户输入端口 */
	original_href,original_wrreq,original_wrdata,
	/* 用户输出端口 */
	fifo_wrdata,fifo_wrreq,
	/* 阈值输入 */
	yuzhi
);

//---------------------------------------------------------------------------
//--	外部端口声明
//---------------------------------------------------------------------------
input							sclk;  					//时钟端口 
input							s_rst_n;						//复位端口
input			[ 7:0]		yuzhi;						//阈值输入端口
input							original_href;				//没有处理过的行同步信号
input							original_wrreq;			//没有处理过的写请求信号
input			[15:0]		original_wrdata;			//没有处理过的16位数据
output		[15:0]		fifo_wrdata;				//FIFO的写数据	
output						fifo_wrreq;					//FIFO的写使能
//---------------------------------------------------------------------------
//--	内部端口声明
//---------------------------------------------------------------------------
wire							process_href;				//经过矩阵模块处理过的行同步信号
wire							process_wrreq;				//经过矩阵模块处理过的行同步信号
wire			[ 7:0]		matrix_p11;					//矩阵第一行第一个数据
wire			[ 7:0]		matrix_p12;					//矩阵第一行第二个数据
wire			[ 7:0]		matrix_p13;					//矩阵第一行第三个数据
wire			[ 7:0]		matrix_p21;					//矩阵第二行第一个数据
wire			[ 7:0]		matrix_p22;					//矩阵第二行第二个数据
wire			[ 7:0]		matrix_p23;					//矩阵第二行第三个数据
wire			[ 7:0]		matrix_p31;					//矩阵第三行第一个数据
wire			[ 7:0]		matrix_p32;					//矩阵第三行第二个数据
wire			[ 7:0]		matrix_p33;					//矩阵第三行第三个数据
reg			[ 9:0]		Gx_temp1;					//计算Gx矩阵的临时寄存器	
wire			[ 9:0]		Gx_temp1_n;					//Gx_temp1的下一个状态
reg			[ 9:0]		Gx_temp2;					//计算Gx矩阵的临时寄存器
wire			[ 9:0]		Gx_temp2_n;					//Gx_temp2的下一个状态
reg			[ 9:0]		Gx_data;						//计算Gx矩阵的临时寄存器
wire			[ 9:0]		Gx_data_n;					//Gx_data的下一个状态
reg			[ 9:0]		Gy_temp1;					//计算Gy矩阵的临时寄存器	
wire			[ 9:0]		Gy_temp1_n;					//Gy_temp1的下一个状态
reg			[ 9:0]		Gy_temp2;					//计算Gy矩阵的临时寄存器	
wire			[ 9:0]		Gy_temp2_n;					//Gy_temp2的下一个状态
reg			[ 9:0]		Gy_data;						//计算Gy矩阵的临时寄存器
wire			[ 9:0]		Gy_data_n;					//Gy_data的下一个状态
reg			[20:0]		Gxy_square;					//计算Gx矩阵+Gy矩阵的平方和
wire			[20:0]		Gxy_square_n;				//Gxy_square的下一个状态
wire			[10:0]		sqrt_result;				//索贝尔算法最终求得的结果
reg							sobel_data;					//经过索贝尔算法模块处理后的摄像头数据
reg							sobel_data_n;				//sobel_data的下一个状态
reg			[ 4:0]		buffer_href;				//用于缓存行信号
wire			[ 4:0]		buffer_href_n;				//buffer_href的下一个状态
reg			[ 7:0]		sobel_threshold;			//索贝尔算法阀值
reg			[ 7:0]		sobel_threshold_n;		//sobel_threshold的下一个状态

//---------------------------------------------------------------------------
//--	逻辑功能实现	
//---------------------------------------------------------------------------
/* 生成矩阵模块 */	
Generate_Matrix			Generate_Matrix_Init
(
	.sclk						(sclk				), 	//时钟信号				
	.s_rst_n					(s_rst_n				),		//复位信号
	.matrix_p11				(matrix_p11			),		//矩阵第一行第一个数据
	.matrix_p12				(matrix_p12			),		//矩阵第一行第二个数据
	.matrix_p13				(matrix_p13			),		//矩阵第一行第三个数据
	.matrix_p21				(matrix_p21			),		//矩阵第二行第一个数据
	.matrix_p22				(matrix_p22			), 	//矩阵第二行第二个数据
	.matrix_p23				(matrix_p23			),		//矩阵第二行第三个数据
	.matrix_p31				(matrix_p31			),		//矩阵第三行第一个数据
	.matrix_p32				(matrix_p32			),		//矩阵第三行第二个数据
	.matrix_p33				(matrix_p33			),		//矩阵第三行第三个数据
	.original_href			(original_href		),		//没有处理过的行同步信号
	.original_wrreq		(original_wrreq	),		//没有处理过的写请求信号
	.original_wrdata		(original_wrdata	),		//没有处理过的16位数据
	.process_wrreq			(process_wrreq		),		//处理过的写请求信号
	.process_href			(process_href		)		//处理过的行同步信号
);

//----------------Sobel Parameter--------------------------------------------
//      Gx             Gy				 Pixel
// [-1  0  +1]   [+1  +2  +1]   [P11  P12  P13]
// [-2  0  +2]   [ 0   0   0]   [P21  P22  P23]
// [-1  0  +1]   [-1  -2  -1]   [P31  P32  P33]
//---------------------------------------------------------------------------

/* 时序电路,用来给Gx_temp1寄存器赋值 */
always@(posedge sclk or negedge s_rst_n)
begin
	if(!s_rst_n)
		Gx_temp1 <= 10'd0;
	else
		Gx_temp1 <= Gx_temp1_n;
end

/* 组合电路,用来计算Gx阵列中P13+P23+P33的值 */
assign Gx_temp1_n = matrix_p13 + (matrix_p23 << 1) + matrix_p33;

/* 时序电路,用来给Gx_temp2寄存器赋值 */
always@(posedge sclk or negedge s_rst_n)
begin
	if(!s_rst_n)
		Gx_temp2 <= 10'd0;
	else
		Gx_temp2 <= Gx_temp2_n;
end

/* 组合电路,用来计算Gx阵列中P11+P21+P31的值 */
assign Gx_temp2_n = matrix_p11 + (matrix_p21 << 1) + matrix_p31;

/* 时序电路,用来给Gx_data寄存器赋值 */
always@(posedge sclk or negedge s_rst_n)
begin
	if(!s_rst_n)
		Gx_data <= 10'd0;
	else
		Gx_data <= Gx_data_n;
end

/* 组合电路,用来计算Gx阵列中所有参数的值 */
assign Gx_data_n = (Gx_temp1 >= Gx_temp2) ? Gx_temp1 - Gx_temp2 : Gx_temp2 - Gx_temp1;

/* 时序电路,用来给Gy_temp1寄存器赋值 */
always@(posedge sclk or negedge s_rst_n)
begin
	if(!s_rst_n)
		Gy_temp1 <= 10'd0;
	else
		Gy_temp1 <= Gy_temp1_n;
end

/* 组合电路,用来计算Gy阵列中P11+P12+P13的值 */
assign Gy_temp1_n = matrix_p11 + (matrix_p12 << 1) + matrix_p13;	

/* 时序电路,用来给Gy_temp2寄存器赋值 */
always@(posedge sclk or negedge s_rst_n)
begin
	if(!s_rst_n)
		Gy_temp2 <= 10'd0;
	else
		Gy_temp2 <= Gy_temp2_n;
end

/* 组合电路,用来计算Gy阵列中P31+P32+P33的值 */
assign Gy_temp2_n = matrix_p31 + (matrix_p32 << 1) + matrix_p33;	

/* 时序电路,用来给Gy_data寄存器赋值 */
always@(posedge sclk or negedge s_rst_n)
begin
	if(!s_rst_n)
		Gy_data <= 10'd0;
	else
		Gy_data <= Gy_data_n;
end

/* 组合电路,用来计算Gy阵列中所有参数的值 */
assign Gy_data_n = (Gy_temp1 >= Gy_temp2) ? Gy_temp1 - Gy_temp2 : Gy_temp2 - Gy_temp1;

/* 时序电路,用来给Gxy_square寄存器赋值 */
always@(posedge sclk or negedge s_rst_n)
begin
	if(!s_rst_n)
		Gxy_square <= 10'd0;
	else
		Gxy_square <= Gxy_square_n;
end

/* 组合电路,用来计算(Gx^2 + Gy^2)的值 */
assign Gxy_square_n = Gx_data * Gx_data + Gy_data * Gy_data;

//平方根IP核,计算(Gx^2 + Gy^2)的平方根的值
SQRT					SQRT_Init
(
	.radical			(Gxy_square	),
	.q					(sqrt_result)
);

/* 时序电路,用来给buffer_href寄存器赋值 */
always @ (posedge sclk or negedge s_rst_n)
begin
	if(!s_rst_n)
		buffer_href <= 5'b0;
	else
		buffer_href <= buffer_href_n;
end

/* 组合电路,缓存5个时钟 */
assign buffer_href_n = {buffer_href[3:0], process_href};

/* 时序电路,用来给sobel_data寄存器赋值 */
always@(posedge sclk or negedge s_rst_n)
begin
	if(!s_rst_n)
		sobel_data <= 1'b0;	
	else
		sobel_data <= sobel_data_n;
end

/* 组合电路,根据外部输入阀值,判断并实现边缘的检测 */
always @ (*)
begin
	if(sqrt_result >= sobel_threshold && buffer_href[4])
		sobel_data_n <= 1'b1;	
	else
		sobel_data_n <= 1'b0;	
end

/* 时序电路,用来给sobel_threshold寄存器赋值 */
always@(posedge sclk or negedge s_rst_n)
begin
	if(!s_rst_n)
		sobel_threshold <= 8'd90;	
	else
		sobel_threshold <= sobel_threshold_n;
end

/* 组合电路,根据外部按键来选择相应的索贝尔算法阀值 */
always @ (*)
begin
	case(yuzhi)
		8'd20: sobel_threshold_n = 8'd20; 	
		8'd30: sobel_threshold_n = 8'd30; 
		8'd40: sobel_threshold_n = 8'd40; 	
		8'd50: sobel_threshold_n = 8'd50; 	
		8'd60: sobel_threshold_n = 8'd60; 	
		8'd70: sobel_threshold_n = 8'd70; 	
		8'd80: sobel_threshold_n = 8'd80; 
		8'd90: sobel_threshold_n = 8'd90; 	
		default: sobel_threshold_n = sobel_threshold;
	endcase
end

assign fifo_wrdata = ~{16{sobel_data}};	//FIFO的写数据	
assign fifo_wrreq = process_wrreq;	//FIFO的写使能

endmodule
