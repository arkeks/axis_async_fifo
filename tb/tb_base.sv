`timescale 1ps/1ps

module tb;

localparam DEPTH   = 1024;
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
localparam RCLK_PER = 100;

logic [DATA_W - 1:0] wdata_arr [DEPTH];
logic [DATA_W - 1:0] rdata_arr [DEPTH];

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

//-----------CASE 0: Base test with FIFO write, read and check data------- 

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
	for (int i = 0; i < DEPTH + 1; i++) begin
		repeat (1) @ (posedge s_axis_clk);
		s_axis_tvalid = 1;
		s_axis_tdata  = wdata_arr[i]; // changing write data after wclk edge
	end

	// stop sending data
	s_axis_tvalid = 0;

	// reading fifo data
	i = 0;
	m_axis_tready = 1;
	repeat (DEPTH + 1) @ (posedge m_axis_clk) begin
		rdata_arr[i] = m_axis_tdata;
		i++;
	end

	// stop reading data
	m_axis_tready = 0;

	foreach (wdata_arr[i]) begin
		assert(wdata_arr[i] == rdata_arr[i]) begin
			$display("OK - [%4d]\n", i);
		end
		else begin
			$display("FAIL - [%4d]", i);
			$display("wdata_arr[%4d] = %3d, rdata_arr[%4d] = %3d\n", i, wdata_arr[i], i, rdata_arr[i]);
		end
	end

	$stop();

end



endmodule