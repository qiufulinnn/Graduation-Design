module  Peri_MUX(
	input 			ch_select,
	input [15:0]	data_in1,
	input 			data_req1,
	input [15:0]	data_in2,
	input 			data_req2,	
	output 			data_out,
	output 			data_req_out
	);


	assign data_out = ch_select ? data_in2 : data_in1;
	assign data_req = ch_select ? data_req2 : data_req1;	
    
	 
endmodule