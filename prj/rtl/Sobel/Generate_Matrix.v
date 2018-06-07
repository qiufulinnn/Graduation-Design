//---------------------------------------------------------------------------
//--	文件名		:	Generate_Matrix.v
//--	作者		:	ZIRCON
//--	描述		:	生成3X3矩阵模块
//--	修订历史	:	2016-09-01
//---------------------------------------------------------------------------
module Generate_Matrix
(
	/* 时钟和复位 */
	sclk,s_rst_n,
	/* 用户输入端口 */
	original_href,original_wrreq,original_wrdata,
	/* 用户输出端口 */
	matrix_p11,matrix_p12,matrix_p13,matrix_p21,matrix_p22,
	matrix_p23,matrix_p31,matrix_p32,matrix_p33,
	process_href,process_wrreq
);

//---------------------------------------------------------------------------
//--	外部端口声明
//---------------------------------------------------------------------------
input							sclk;  					//时钟端口
input							s_rst_n;						//复位端口
input			[15:0]		original_wrdata;			//没有处理过的16位数据
input							original_wrreq;			//没有处理过的写请求信号
input							original_href;				//没有处理过的行同步信号
output						process_wrreq;				//处理过的写请求信号
output						process_href;				//处理过的行同步信号
output		[ 7:0]		matrix_p11;					//矩阵第一行第一个数据
output		[ 7:0]		matrix_p12;					//矩阵第一行第二个数据
output		[ 7:0]		matrix_p13;					//矩阵第一行第三个数据
output		[ 7:0]		matrix_p21;					//矩阵第二行第一个数据
output		[ 7:0]		matrix_p22;					//矩阵第二行第二个数据
output		[ 7:0]		matrix_p23;					//矩阵第二行第三个数据
output		[ 7:0]		matrix_p31;					//矩阵第三行第一个数据
output		[ 7:0]		matrix_p32;					//矩阵第三行第二个数据
output		[ 7:0]		matrix_p33;					//矩阵第三行第三个数据

//---------------------------------------------------------------------------
//--	内部端口声明
//---------------------------------------------------------------------------
wire			[ 7:0]			row1_data;				//第一行数据
wire			[ 7:0]			row2_data;				//第二行数据
reg			[ 7:0]			row3_data;				//第三行数据
reg			[ 7:0]			row3_data_n;			//row3_data的下一个状态
reg			[ 7:0]			matrix_p31;				//矩阵第三行第一个数据
reg			[ 7:0]			matrix_p31_n;			//matrix_p31的下一个状态
reg			[ 7:0]			matrix_p32;				//矩阵第三行第二个数据
reg			[ 7:0]			matrix_p32_n;			//matrix_p32的下一个状态
reg			[ 7:0]			matrix_p33;				//矩阵第三行第三个数据
reg			[ 7:0]			matrix_p33_n;			//matrix_p33的下一个状态
reg			[ 7:0]			matrix_p21;				//矩阵第二行第一个数据
reg			[ 7:0]			matrix_p21_n;			//matrix_p21的下一个状态
reg			[ 7:0]			matrix_p22;				//矩阵第二行第二个数据
reg			[ 7:0]			matrix_p22_n;			//matrix_p22的下一个状态
reg			[ 7:0]			matrix_p23;				//矩阵第二行第三个数据
reg			[ 7:0]			matrix_p23_n;			//matrix_p23的下一个状态
reg			[ 7:0]			matrix_p11;				//矩阵第一行第一个数据
reg			[ 7:0]			matrix_p11_n;			//matrix_p11的下一个状态
reg			[ 7:0]			matrix_p12;				//矩阵第一行第二个数据
reg			[ 7:0]			matrix_p12_n;			//matrix_p12的下一个状态
reg			[ 7:0]			matrix_p13;				//矩阵第一行第三个数据
reg			[ 7:0]			matrix_p13_n;			//matrix_p13的下一个状态		
reg			[ 1:0]			buffer_href;			//用于缓存行信号
wire			[ 1:0]			buffer_href_n;			//buffer_href的下一个状态
reg			[ 1:0]			buffer_wrreq;			//用于缓存写请求信号
wire			[ 1:0]			buffer_wrreq_n;		//buffer_wrreq的下一个状态

//---------------------------------------------------------------------------
//--	逻辑功能实现	
//---------------------------------------------------------------------------
/* 时序电路,用来给row3_data寄存器赋值 */
always @ (posedge sclk or negedge s_rst_n)
begin
	if(!s_rst_n)
		row3_data <= 8'd0;
	else
		row3_data <= row3_data_n;
end

/* 组合电路,用来接收摄像头传来的高8位数据 */
always @ (*)
begin
	if(original_wrreq)
		row3_data_n = original_wrdata[15:8];
	else
		row3_data_n = row3_data;
end

//基于RAM的移位寄存器,用来实现3X3矩阵
RAM_SHIFT			RAM_SHIFT_Init 
(
	.clock 			(sclk 				),	//时钟端口
	.clken 			(original_wrreq		),	//时钟使能端口
	.shiftin 		(row3_data 				),	//数据输入端口
	.taps0x 			(row2_data 				),	//数据输出端口
	.taps1x 			(row1_data 				)	//数据输出端口
);

/* 时序电路,用来给matrix_p31,matrix_p32,matrix_p33寄存器赋值 */
always@(posedge sclk or negedge s_rst_n)
begin
	if(!s_rst_n)
		{matrix_p31, matrix_p32, matrix_p33} <= 24'h0;
	else
		{matrix_p31, matrix_p32, matrix_p33} = {matrix_p31_n, matrix_p32_n, matrix_p33_n };
end

/* 组合电路,用来转换矩阵,实际是第一行,需要转换成第三行:[P11 P12 P13] --> [P31 P32 P33] */
always @ (*)
begin
	if(original_href && original_wrreq)
		{matrix_p31_n, matrix_p32_n, matrix_p33_n } = {matrix_p32, matrix_p33, row3_data};
	else if(original_href && (!original_wrreq))
		{matrix_p31_n, matrix_p32_n, matrix_p33_n } = {matrix_p31, matrix_p32, matrix_p33};
	else
		{matrix_p31_n, matrix_p32_n, matrix_p33_n } = 24'h0;
end

/* 时序电路,用来给matrix_p21,matrix_p22,matrix_p23寄存器赋值 */
always@(posedge sclk or negedge s_rst_n)
begin
	if(!s_rst_n)
		{matrix_p21, matrix_p22, matrix_p23} <= 24'h0;
	else
		{matrix_p21, matrix_p22, matrix_p23} = {matrix_p21_n, matrix_p22_n, matrix_p23_n };
end

/* 组合电路,用来转换矩阵,实际是第二行,需要转换成第二行:[P21 P22 P23] --> [P21 P22 P23] */
always @ (*)
begin
	if(original_href && original_wrreq)
		{matrix_p21_n, matrix_p22_n, matrix_p23_n} = {matrix_p22, matrix_p23, row2_data};
	else if(original_href && (!original_wrreq))
		{matrix_p21_n, matrix_p22_n, matrix_p23_n} = {matrix_p21, matrix_p22, matrix_p23};
	else
		{matrix_p21_n, matrix_p22_n, matrix_p23_n} = 24'h0;
end

/* 时序电路,用来给matrix_p11,matrix_p12,matrix_p13寄存器赋值 */
always@(posedge sclk or negedge s_rst_n)
begin
	if(!s_rst_n)
		{matrix_p11, matrix_p12, matrix_p13} <= 24'h0;
	else
		{matrix_p11, matrix_p12, matrix_p13} = {matrix_p11_n, matrix_p12_n, matrix_p13_n };
end

/* 组合电路,用来转换矩阵,实际是第三行,需要转换成第一行:[P31 P32 P33] --> [P11 P12 P13] */
always @ (*)
begin
	if(original_href && original_wrreq)
		{matrix_p11_n, matrix_p12_n, matrix_p13_n} = {matrix_p12, matrix_p13, row1_data};
	else if(original_href && (!original_wrreq))
		{matrix_p11_n, matrix_p12_n, matrix_p13_n} = {matrix_p11, matrix_p12, matrix_p13};
	else
		{matrix_p11_n, matrix_p12_n, matrix_p13_n} = 24'h0;
end

/* 时序电路,用来给buffer_href寄存器赋值 */
always @ (posedge sclk or negedge s_rst_n)
begin
	if(!s_rst_n)
		buffer_href <= 2'd0;
	else
		buffer_href <= buffer_href_n;
end

/* 组合电路,缓存2个时钟,放弃第一行和第二行的数据 */
assign buffer_href_n = {buffer_href[0], original_href};

/* 时序电路,用来给buffer_wrreq寄存器赋值 */
always @ (posedge sclk or negedge s_rst_n)
begin
	if(!s_rst_n)
		buffer_wrreq <= 2'd0;
	else
		buffer_wrreq <= buffer_wrreq_n;
end

/* 组合电路,缓存2个时钟,放弃第一行和第二行的数据 */
assign buffer_wrreq_n = {buffer_wrreq[0], original_wrreq};

assign process_wrreq = buffer_wrreq[1]; 	//将缓存后的写请求信号输出
assign process_href  = buffer_href[1]; 	//将缓存后的行信号输出

endmodule
