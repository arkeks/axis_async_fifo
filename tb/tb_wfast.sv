`timescale 1ps/1ps

//---------CASE 2: Write clock is faster then read clock----------

module tb;

localparam DEPTH   = 32;
localparam DATA_W  = 8;
localparam DATA_BW = DATA_W/8;
localparam FIFO_DW = DATA_W + DATA_BW*6;

// dut connections 
logic 					s_axis_clk;
logic 					s_axis_rst;
logic 					m_axis_clk;
logic 					m_axis_rst;

logic 					s_axis_tvalid;
logic 					s_axis_tready;
logic [DATA_W  - 1:0] 	s_axis_tdata;
logic [DATA_BW - 1:0] 	s_axis_tstrb;
logic [DATA_BW - 1:0] 	s_axis_tkeep;
logic 					s_axis_tlast;
logic 					s_axis_tid;
logic 					s_axis_tdest;
logic 					s_axis_tuser;

logic 					m_axis_tvalid;
logic 					m_axis_tready;
logic [DATA_W  - 1:0] 	m_axis_tdata;
logic [DATA_BW - 1:0] 	m_axis_tstrb;
logic [DATA_BW - 1:0] 	m_axis_tkeep;
logic 					m_axis_tlast;
logic 					m_axis_tid;
logic 					m_axis_tdest;
logic 					m_axis_tuser;


axis_fifo_wrapper #(.DEPTH(DEPTH), .DATA_W(DATA_W), .ID_W(1), .DEST_W(1), .USER_W(1)) 
	dut_axis_fifo (
		.s_axis_clk   (s_axis_clk   ),
		.s_axis_rst   (s_axis_rst   ),
		.m_axis_clk   (m_axis_clk   ),
		.m_axis_rst   (m_axis_rst   ),
		.s_axis_tvalid(s_axis_tvalid),
		.s_axis_tready(s_axis_tready),
		.s_axis_tdata (s_axis_tdata ),
		.s_axis_tstrb (s_axis_tstrb ),
		.s_axis_tkeep (s_axis_tkeep ),
		.s_axis_tlast (s_axis_tlast ),
		.s_axis_tid   (s_axis_tid   ),
		.s_axis_tdest (s_axis_tdest ),
		.s_axis_tuser (s_axis_tuser ),
		.m_axis_tvalid(m_axis_tvalid),
		.m_axis_tready(m_axis_tready),
		.m_axis_tdata (m_axis_tdata ),
		.m_axis_tstrb (m_axis_tstrb ),
		.m_axis_tkeep (m_axis_tkeep ),
		.m_axis_tlast (m_axis_tlast ),
		.m_axis_tid   (m_axis_tid   ),
		.m_axis_tdest (m_axis_tdest ),
		.m_axis_tuser (m_axis_tuser )
	);


localparam WCLK_PER = 50;
localparam RCLK_PER = WCLK_PER*2;

logic [DATA_W - 1:0] wdata_arr [(DEPTH)*2];

int i;

// clocks
initial begin
	s_axis_clk = 0;

	forever begin
		#WCLK_PER;
		s_axis_clk = ~s_axis_clk;
	end
end

initial begin
	m_axis_clk = 0;

	forever begin
		#RCLK_PER;
		m_axis_clk = ~m_axis_clk;
	end
end

// resets
initial begin
	s_axis_rst = 0;
	m_axis_rst = 0;
	#10;
	s_axis_rst = 1;
	m_axis_rst = 1;
	#10;
	s_axis_rst = 0;
	m_axis_rst = 0;
end

// test body
initial begin
	// initial values
	s_axis_tvalid = 0; // wen
	s_axis_tdata  = 0;
	s_axis_tstrb  = 0;
	s_axis_tkeep  = 0;
	s_axis_tlast  = 0;
	s_axis_tid 	  = 0;
	s_axis_tdest  = 0;
	s_axis_tuser  = 0;
	m_axis_tready = 0; // ren
	
	// wait for resets
	wait (s_axis_rst == 1);
	wait (s_axis_rst == 0);

	// generatig data for sending
	foreach (wdata_arr[i]) begin
		wdata_arr[i] = i % 256;
	end

	// sending generated data by driving s_tvalid high
	m_axis_tready = 1;
	for (int i = 0; i < (DEPTH)*2; i++) begin
		repeat (1) @ (posedge s_axis_clk);
		s_axis_tvalid = 1;
		s_axis_tdata  = wdata_arr[i]; // changing write data after wclk edge

		// repeat (1) @ (posedge m_axis_clk);
	end
	
	m_axis_tready = 0;
	repeat (1) @ (posedge m_axis_clk);
	s_axis_tvalid = 0;

	assert (s_axis_tready == 0) begin
		$display("FIFO is full => not ready [SUCCESS]\n",);
	end
	else
		$display("FIFO is ready [FAIL]\n",);

	// read till empty
	m_axis_tready = 1;
	repeat (DEPTH + 1) @ (posedge m_axis_clk);
	m_axis_tready = 0;

	assert (m_axis_tvalid == 0) begin
		$display("FIFO is empty => rdata not valid [SUCCESS]\n",);
	end
	else
		$display("FIFO rdata is valid [FAIL]\n",);

	$stop();

end



endmodule