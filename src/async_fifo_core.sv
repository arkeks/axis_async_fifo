`timescale 1ps/1ps

module async_fifo_core
#(
	parameter 	DEPTH 	= 1024,					// max number of words in fifo
				AW 		= $clog2(DEPTH + 1),	// address width
				DW 		= 8						// data width
)
(
	input  logic 			wclk,
	input  logic 			wrst,
	input  logic 			rclk,
	input  logic 			rrst,

	input  logic 			wen,
	input  logic 			ren,

	input  logic [DW - 1:0] wdata,
	output logic [DW - 1:0] rdata,

	output logic 			full,
	output logic 			empty
	// output logic w_cnt
);

// local declarations
logic [DW - 1:0] mem [DEPTH - 1:0];

logic [AW - 1:0] waddr, waddr_next, waddr_g, waddr_g_next, waddr_g_sync;
logic [AW - 1:0] raddr, raddr_next, raddr_g, raddr_g_next, raddr_g_sync;

// checks
initial begin
	assert ( DEPTH == (1 << $clog2(DEPTH)) ) begin
		$display("DEPTH = %d\n", DEPTH);
	end
	else begin
		$display("DEPTH must be a power of two!\n");
	end
end

//--------------write domain---------------

// memory write logic
always_ff @ (posedge wclk or posedge wrst)
	if (wrst) begin
		foreach (mem[i]) begin
			mem[i] <= 0;
		end
	end
	else if (wen) // no check of full, because axis wrapper ensures no wen while !ready (<=> full)
		mem[waddr] <= wdata;


// write pointer (address)
always_ff @ (posedge wclk or posedge wrst)
	if (wrst)
		waddr <= 0;
	else if (wen) // no check of full, because axis wrapper ensures no wen while !ready (<=> full)
		waddr <= waddr_next;

assign waddr_next = waddr + 'd1;


// write pointer binary to gray code conversion
always_ff @ (posedge wclk or posedge wrst)
	if (wrst)
		waddr_g <= 0;
	else if (wen)
		waddr_g <= waddr_g_next;

assign waddr_g_next = (waddr_next >> 1) ^ waddr_next;


// read pointer synchronization
sync #( .DW(AW) )
	i_raddr_sync (
		.clk 	( wclk 		 	),
		.rst 	( wrst 		 	),
		.data_i ( raddr_g 		),
		.data_o ( raddr_g_sync 	)
	);


// write domain output logic
assign full = ({~waddr_g[AW - 1:AW - 2], waddr_g[AW - 3:0]} == raddr_g_sync);


//--------------read domain---------------

// read pointer (address)
always_ff @ (posedge rclk or posedge rrst)
	if (rrst)
		raddr <= 0;
	else if (ren) // no check of empty, because axis wrapper ensures no ren while !valid (<=> empty)
		raddr <= raddr_next;

assign raddr_next = raddr + 'd1;


// read pointer binary to gray code conversion
always_ff @ (posedge rclk or posedge rrst)
	if (rrst)
		raddr_g <= 0;
	else if (ren) // no check of empty, because axis wrapper ensures no ren while !valid (<=> empty)
		raddr_g <= raddr_g_next;

assign raddr_g_next = (raddr_next >> 1) ^ raddr_next;


// write gray pointer synchronizing
sync #( .DW(AW) )
	i_waddr_sync (
		.clk 	( rclk 		 	),
		.rst 	( rrst 		 	),
		.data_i ( waddr_g 		),
		.data_o ( waddr_g_sync 	)
	);

// read domain output logic
assign empty = (raddr_g == waddr_g_sync);

assign rdata = mem[raddr];


endmodule : async_fifo_core