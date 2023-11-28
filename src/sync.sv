`timescale 1ps/1ps

module sync 
#(
	parameter DW = 8
)
(
	input  logic 			clk,
	input  logic 			rst,
	input  logic [DW - 1:0] data_i,

	output logic [DW - 1:0] data_o
);

logic [DW - 1:0] data_sync_1, data_sync_2;

// 3 flip-flops synchronizer
always_ff @ (posedge clk or posedge rst)
	if (rst)
		{data_o, data_sync_2, data_sync_1} <= 0;
	else
		{data_o, data_sync_2, data_sync_1} <= {data_sync_2, data_sync_1, data_i};

endmodule : sync