module axis_fifo_wrapper 
#(
	parameter 	DEPTH 	= 1024,		// max number of words in fifo
				DATA_W 	= 8,		// data width in bits
				DATA_BW = DATA_W/8, // data width in bytes
				STRB_W	= DATA_BW,
				KEEP_W	= DATA_BW,
				ID_W 	= 1,
				DEST_W  = 1,
				USER_W 	= 1

)
(
	input  logic 				s_axis_clk,
	input  logic 				s_axis_rst,
	input  logic 				m_axis_clk,    
	input  logic 				m_axis_rst,

	// slave (from write domain)
	input  logic 				s_axis_tvalid,
	output logic 				s_axis_tready,
	input  logic [DATA_W - 1:0] s_axis_tdata,
	input  logic [STRB_W - 1:0] s_axis_tstrb,
	input  logic [KEEP_W - 1:0] s_axis_tkeep,
	input  logic 				s_axis_tlast,
	input  logic [ID_W   - 1:0] s_axis_tid,
	input  logic [DEST_W - 1:0] s_axis_tdest,
	input  logic [USER_W - 1:0] s_axis_tuser,

	// master (to read domain)
	output logic 				m_axis_tvalid,
	input  logic 				m_axis_tready,
	output logic [DATA_W - 1:0] m_axis_tdata,
	output logic [STRB_W - 1:0] m_axis_tstrb,
	output logic [KEEP_W - 1:0] m_axis_tkeep,
	output logic 				m_axis_tlast,
	output logic [ID_W   - 1:0] m_axis_tid,
	output logic [DEST_W - 1:0] m_axis_tdest,
	output logic [USER_W - 1:0] m_axis_tuser
);

// local parameters
localparam LAST_W 		= 1;
localparam FIFO_DW   	= DATA_W + STRB_W + KEEP_W + LAST_W + ID_W + DEST_W + USER_W;

localparam TDATA_IDX	= 0;
localparam STRB_IDX  	= TDATA_IDX + DATA_W;
localparam KEEP_IDX	 	= STRB_IDX  + STRB_W;
localparam LAST_IDX		= KEEP_IDX  + KEEP_W;
localparam ID_IDX		= LAST_IDX  + LAST_W;
localparam DEST_IDX		= ID_IDX 	+ ID_W;
localparam USER_IDX		= DEST_IDX  + DEST_W; 

// local declarations
logic 					wen;
logic 					ren;
logic 					full;
logic 					empty;
logic [FIFO_DW - 1:0] 	wdata;
logic [FIFO_DW - 1:0] 	rdata;

// packing s_axis signals into one bus 
always_comb begin : wdata_handler
	wdata[TDATA_IDX +: DATA_W] = s_axis_tdata;
	wdata[STRB_IDX 	+: STRB_W] = s_axis_tstrb;
	wdata[KEEP_IDX 	+: KEEP_W] = s_axis_tkeep;
	wdata[LAST_IDX 	+: LAST_W] = s_axis_tlast;
	wdata[ID_IDX 	+: 	 ID_W] = s_axis_tid;
	wdata[DEST_IDX 	+: DEST_W] = s_axis_tdest;
	wdata[USER_IDX 	+: USER_W] = s_axis_tuser;
end


async_fifo_core #(.DEPTH(DEPTH), .DW(FIFO_DW)) 
	i_async_fifo_core (
		.wclk ( s_axis_clk	),
		.wrst ( s_axis_rst	),
		.rclk ( m_axis_clk	),
		.rrst ( m_axis_rst	),
		.wen  ( wen  		),
		.ren  ( ren  		),
		.wdata( wdata 		),
		.rdata( rdata 		),
		.full ( full 		),
		.empty( empty		)
	);


always_comb begin : valid_ready_logic
	m_axis_tvalid = ~empty;
	s_axis_tready = ~full;
end

always_comb begin : wen_ren_logic
	wen = s_axis_tvalid & s_axis_tready;
	ren = m_axis_tvalid & m_axis_tready;
end

always_comb begin : mst_axis_handler
	m_axis_tdata = rdata[TDATA_IDX  +: DATA_W];
	m_axis_tstrb = rdata[STRB_IDX 	+: STRB_W];
	m_axis_tkeep = rdata[KEEP_IDX 	+: KEEP_W];
	m_axis_tlast = rdata[LAST_IDX 	+: LAST_W];
	m_axis_tid 	 = rdata[ID_IDX 	+: 	 ID_W];
	m_axis_tdest = rdata[DEST_IDX 	+: DEST_W];
	m_axis_tuser = rdata[USER_IDX 	+: USER_W];
end

endmodule : axis_fifo_wrapper