// Btn Debouncer
// By Alex Allsup
//
// Implementation based off the design in the debouncing lab
// State diagram found on page 3 of the lab manual

module btn_debouncer(
	input CLK, input RESET,
	input Btn, output Btn_pulse);

// inputs 
input CLK; // should be at about 24.4 kHz
input RESET;
input Btn;

// output
output reg Btn_pulse;

localparam INIT = 3'b000, WQ = 3'b001, SCEN_St = 3'b010, CCR = 3'b011, WFCR = 3'b100;
reg[2:0] state;

localparam max_i = 6100; // should yield a wait time of approx 0.25s
reg I;

always @(posedge CLK, posedge RESET)
begin
	if (RESET) begin
		Btn_pulse <= 0;
		state <= INIT;
		I <= 0;
	end
	else begin
		case (state)
			INIT:
			begin
				if (Btn) state <= WQ;
				// else remain

				I <= 0;
			end

			WQ:
			begin
				if (!Btn) state <= INIT;
				else if (I == max_i) state <= SCEN_St;
				// else remain

				I <= I + 1;
				Btn_pulse <= 1;
			end

			SCEN_St:
			begin
				state <= CCR;

				Btn_pulse <= 0;
				I <= 0;
			end

			CCR:
			begin
				if (!Btn) state <= WFCR;
				// else remain

				I <= 0;
			end

			WFCR:
			begin
				if (Btn) state <= CCR;
				else if (I == max_i) state <= INIT;
				// else remain

				I <= I + 1;
			end
	end
end

endmodule