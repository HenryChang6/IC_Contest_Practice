module DT(
	input 			        clk, 
	input			        reset,
	input		    [15:0]	sti_di,
	input		    [7:0]	res_di,
	output	reg		        done ,
	output	reg		        sti_rd ,
	output	reg 	[9:0]	sti_addr ,
	output	reg		        res_wr ,
	output	reg		        res_rd ,
	output	reg 	[13:0]	res_addr,
	output	reg 	[7:0]	res_do
);

localparam IDLE = 4'd0;
localparam F = 4'd1;
localparam F_NW = 4'd2;
localparam F_N = 4'd3;
localparam F_NE = 4'd4;
localparam F_WRITE = 4'd5;
localparam B = 4'd6;
localparam B_SE = 4'd7;
localparam B_S = 4'd8;
localparam B_SW = 4'd9;
localparam B_READ_CUR = 4'd10;
localparam B_WRITE = 4'd11;
localparam FINISH = 4'd12;

// reg
reg pixel;
reg pre_is_obj;
reg [3:0] state, nxt_state;
reg [7:0] data [0:4];
reg [13:0] pos;

// wire 
wire [6:0] pos_col = pos[6:0];
wire [6:0] pos_row = pos[13:7];
wire [13:0] pos_e = pos + {7'd0,7'd1};
wire [13:0] pos_se = pos + {7'd1,7'd1};
wire [13:0] pos_s = pos + {7'd1,7'd0};
wire [13:0] pos_sw = pos + {7'd0,7'd127};
wire [13:0] pos_w = pos - {7'd0,7'd1};
wire [13:0] pos_ne = pos - {7'd0, 7'd127};
wire [13:0] pos_n = pos - {7'd1,7'd0};
wire [13:0] pos_nw = pos - {7'd1,7'd1};
wire [7:0] min1 = ((data[0]<data[1]) ? data[0] : data[1]);
wire [7:0] min2 = ((data[2]<data[3]) ? data[2] : data[3]);
wire [7:0] f_res =  (min1 < min2 ? min1 : min2) + 1;
wire [7:0] b_res = ((f_res < data[4]) ? f_res : data[4]);

// FSM
always @(posedge clk /*or negedge reset*/) begin
	if (!reset) state <= IDLE;
	else state <= nxt_state; 
end

// Combination
always @(*) begin
	sti_rd <= 1;
	sti_addr <= pos[13:4]; 
	pixel <= sti_di[~pos_col[3:0]]; 
	res_rd <= ~res_wr;
end

// Next State Logic
// Comb要寫滿!!! 不然就要在一開始寫個 nxt_state <= state
always @(*) begin
	case(state) 
		IDLE: nxt_state <= F;
		F: begin 
			if (pos_row == 7'd127) nxt_state <= B; // front pass complete
			else if (pixel) nxt_state <= (pre_is_obj ? F_NE : F_NW);
			else nxt_state <= F;
		end
		F_NW: nxt_state <= F_N;
		F_N: nxt_state <= F_NE;
		F_NE: nxt_state <= F_WRITE;
		F_WRITE: nxt_state <= F;
		B: begin
			if (pos_row == 0) nxt_state <= FINISH;
			else if (pixel) nxt_state <= (pre_is_obj ? B_SW : B_SE);
			else nxt_state <= B;
		end
		B_SE: nxt_state <= B_S;
		B_S: nxt_state <= B_SW;
		B_SW: nxt_state <= B_READ_CUR;
		B_READ_CUR: nxt_state <= B_WRITE;
		B_WRITE: nxt_state <= B;
	endcase
end

// state behavior
always @(posedge clk) begin
	res_wr <= 0; 
	case(state) 
		IDLE: begin
			pos <= {7'd1, 7'd1};
			pre_is_obj <= 0;
			done <= 0;
		end

		F: begin
			if (pixel) begin
				res_addr <= (pre_is_obj ? pos_ne : pos_nw);
			end
			else begin
				pre_is_obj <= 0;
				pos <= pos_e;
			end
		end

		F_NW: begin
			data[3] <= 0; // cause prev is not an object
			data[0] <= res_di;
			res_addr <= pos_n;
		end

		F_N: begin
			data[1] <= res_di;
			res_addr <= pos_ne;
		end

		F_NE: begin
			data[2] <= res_di;
		end

		F_WRITE: begin
			res_wr <= 1;
			res_addr <= pos;
			res_do <= f_res;
			// update data 
			data[0] <= data[1];
			data[1] <= data[2];
			data[3] <= f_res;
			// update pos
			pos <= pos_e;
			pre_is_obj <= 1;
		end

		B: begin
			if (pixel) begin
				res_addr <= (pre_is_obj ? pos_sw : pos_se);
			end
			else begin
				pos <= pos_w;
				pre_is_obj <= 0;
			end
		end

		B_SE: begin
			data[3] <= 0;
			data[0] <= res_di;
			res_addr <= pos_s;
		end

		B_S: begin
			data[1] <= res_di;
			res_addr <= pos_sw;
		end

		B_SW: begin
			data[2] <= res_di;
			res_addr <= pos; // we want to know current value to calculate b_res;
		end

		B_READ_CUR: begin
			data[4] <= res_di;
		end

		B_WRITE: begin
			res_wr <= 1;
			res_addr <= pos;
			res_do <= b_res;
			// update data
			data[0] <= data[1];
			data[1] <= data[2];
			data[3] <= b_res;
			// updata pos
			pos <= pos_w;
			pre_is_obj <= 1;
		end

		FINISH: begin 
			done <= 1;
		end
	endcase
end

endmodule
