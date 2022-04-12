`timescale 1ns / 1ps

module test(

	input wire clk,
	input wire rw,                // WRITE into memory (1), READ out of memory (0)
	input wire [7:0] data_in,     // 8-bit data incoming from MCU
	inout wire [7:0] data_io,     // Bi-directional data port between FPGA and SRAM
	output reg [15:0] data_out,   // 16-bit data outputted to DAC
	output wire ce_n,             // SRAM Chip Enable (always low when device is on)
	output wire oe_n,             // SRAM Output Enable (must be low in READ mode)
	output wire we_n,             // SRAM Write Enable (high in READ and low in WRITE)
	output reg [18:0] addr         // 19-bit address to memory cell
	);
   
	wire clk_ibufg;
	wire clk_int;
	IBUFG clk_ibufg_inst (.I(clk), .O(clk_ibufg));
	BUFG clk_bufg_inst (.I(clk_ibufg), .O(clk_int));
	 
	reg	[18:0] w_count;
	reg	[18:0] r_count;            
	reg	[18:0] final_count;
	reg	odd_addr;
	reg	[7:0] data1;
	reg	[7:0] data2;
	reg	[15:0] o_data_out;
	reg	flag;

 	initial
	begin
		flag = 0;
		r_count = 19'b0;
		w_count = 19'b0;
		final_count = 19'b0;
		odd_addr = 1'b0;
	 end

	 assign we_n =~ rw;    // Write is active low so in WRITE mode, we send a low
	 assign ce_n = 0;	     // Chip is enabled
	 assign oe_n = 0;		  // Output is enabled
	 
	 
	 /* If WRITE(rw=1), the data_io takes the value of data_in
	    If READ(rw=0), the data_io is defualted to high impedance */
	 assign data_io = (rw == 1'b1)? data_in : 8'bZZZZZZZZ;

	 always @(posedge clk_int)                   // At every positive edge clk...
	 begin        

		// WRITE Mode 
		if (rw == 1'b1)                    // If we are in READ mode...
		begin 
			flag = 1;
			addr <= w_count;              // The address takes the value of w_count
			final_count <= w_count;       // Give the final_count the value of w_count
			w_count <= w_count + 1;       // Increment w_count
		end
		
		// READ Mode
		if (rw == 1'b0 && flag == 1)                    // If we are in READ mode...
		begin			
			addr <= r_count;              // The address is restarted to 0
			odd_addr <= addr % 2;         // Evaluates to 1 when odd
			
			if (w_count == 0)
				$display("No data to read.");
						   
			if (odd_addr)                      // If is odd...
			begin
				data2 <= data_io;              // Store this data value in data2
            o_data_out[7:0] <= data1;      // Output data1
            o_data_out[15:8] <= data2;     // Output data2
				data_out[15] <= ~o_data_out[15]; 
				data_out[14:0] <= o_data_out[14:0]; 
				r_count <= r_count + 1;        // Increment r_count
			end

			if (r_count == final_count)
				r_count <= 0;            // Resetting the read counter
              
			else 
			begin

				data1 <= data_io;        // Store this data value in data1
				r_count <= r_count + 1;  // Increment r_count
			end
		end 
	end

endmodule



