`timescale 1ps/1ps

module tb;


logic wclk;
logic wrst;
logic rclk;
logic rrst;
logic wen;
logic ren;
logic [7:0] wdata;
logic [7:0] rdata;
logic full;
logic empty;

localparam DEPTH = 64;

async_fifo_core #(.DEPTH(64))
	i_async_fifo_core (
		.wclk (wclk ),
		.wrst (wrst ),
		.rclk (rclk ),
		.rrst (rrst ),
		.wen  (wen  ),
		.ren  (ren  ),
		.wdata(wdata),
		.rdata(rdata),
		.full (full ),
		.empty(empty)
	);

localparam W_PER = 50;
localparam R_PER = 100;

logic [7:0] wdata_arr [DEPTH];
logic [7:0] rdata_arr [DEPTH];

int i;

// clocks
initial begin
	wclk = 0;

	forever begin
		#W_PER;
		wclk = ~wclk;
	end
end

initial begin
	rclk = 0;

	forever begin
		#R_PER;
		rclk = ~rclk;
	end
end

// resets
initial begin
	wrst = 0;
	rrst = 0;
	#10;
	wrst = 1;
	rrst = 1;
	#10;
	wrst = 0;
	rrst = 0;
end

initial begin
	wen 	= 0;
	ren 	= 0;
	wdata 	= 0;
	
	wait (wrst == 1);
	wait (wrst == 0);

	foreach (wdata_arr[i]) begin
		wdata_arr[i] = i % 256;
	end

	for (int i = 0; i < DEPTH + 1; i++) begin
		repeat (1) @ (posedge wclk);
		wen = 1;
		wdata = wdata_arr[i];
	end

	wen = 0;

	i = 0;
	repeat (DEPTH + 1) @ (posedge rclk) begin
		rdata_arr[i] = rdata;
		ren = 1;
		i++;
	end

	ren = 0;

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