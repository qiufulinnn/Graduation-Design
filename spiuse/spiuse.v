module spiuse(

	input sclk,
	input s_rst_n,

	input spi_sck_in,
	input spi_mosi_in,
	input spi_cs_in,
	input reset_in,
	output spi_sck_out,
	output spi_mosi_out,
	output spi_cs_out,
	output reset_out,
	output led
	);
	
	
	assign spi_sck_out = spi_sck_in;
		assign spi_mosi_out = spi_mosi_in;
			assign spi_cs_out = spi_cs_in;
				assign reset_out = reset_in;
	
		cext cext_inst (
	.sclk 		(sclk 		),
	.s_rst_n		(s_rst_n 	),
	.spi_cs 		(spi_cs_in 	),
	.spi_sck 	(spi_sck_in 	),
	.spi_mosi 	(spi_mosi_in 	),
	.led 		(led 		)
	);
	
endmodule 
