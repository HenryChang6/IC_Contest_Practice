
`timescale 1ns/10ps
module LBP ( clk, reset, gray_addr, gray_req, gray_ready, gray_data, lbp_addr, lbp_valid, lbp_data, finish);
input clk;
input reset;
input gray_ready;
input [7:0] gray_data;
output [13:0] gray_addr;
output gray_req;
output [13:0] lbp_addr;
output lbp_valid;
output [7:0] lbp_data;
output finish;

// parameters
localparam IDLE = 3'd0;
localparam READUR = 3'd1;
localparam READR = 3'd2;
localparam READDR = 3'd3;
localparam WRITE = 3'd4;
localparam FININSH = 3'd5;

// reg
reg finish;
reg gray_req;
reg lbp_valid;
reg [2:0] state, nxt_state;
reg [7:0] lbp_data;
reg [7:0] data [8:0];
reg [13:0] lbp_addr;
reg [13:0] gray_addr;
reg [13:0] pos;

// wire
// u = up; r = right; d = down; l = left
wire [6:0] pos_row = pos[13:7];
wire [6:0] pos_col = pos[6:0];
wire [13:0] pos_r = pos + {7'd0,7'd1};
wire [13:0] pos_dr = pos + {7'd1,7'd1};
wire [13:0] pos_ur = pos - {7'd0, 7'd127};
wire [13:0] pos_urr = pos - {7'd0, 7'd126};
wire is_first_col = (pos_col == 7'd0);
wire is_last_col = (pos_col == 7'd127);
wire dont_output = (is_first_col || is_last_col);

//FSM
always @(posedge clk or posedge reset) begin
    if (reset) state <= IDLE;
    else state <= nxt_state;
end 

// Next State Logic
always @(*) begin
    case(state)
        IDLE: if (gray_ready) nxt_state <= READUR;
        READUR: nxt_state <= READR;
        READR:  nxt_state <= READDR;
        READDR: nxt_state <= WRITE;
        WRITE: begin
            if (pos_row == 7'd127) nxt_state <= FININSH;
            else nxt_state <= READUR; 
        end
    endcase
end

// Action on each State
always @(posedge clk) begin
    gray_req <= 1;
    lbp_valid <= 0;
    lbp_addr <= 14'hx;
    lbp_data <= 8'hx;
    case (state)
        IDLE: begin
            gray_addr <= {7'd0, 7'd0};
            pos <= {7'd0, 7'd127};
            finish <= 0;
        end

        READUR: begin
            data[2] <= gray_data; 
            gray_addr <= pos_r;
        end

        READR: begin
            data[5] <= gray_data;
            gray_addr <= pos_dr;
        end

        READDR: begin
            data[8] <= gray_data;            
        end

        WRITE: begin
            /*
            data
            -----------
            0   1   2
            3   4   5
            6   7   8
            ----------
            */
            lbp_valid <= !dont_output;
            lbp_addr <= pos;
            // calculate the lbp value of current pos
            lbp_data[0] <= (data[0] >= data[4]);
            lbp_data[1] <= (data[1] >= data[4]);
            lbp_data[2] <= (data[2] >= data[4]);
            lbp_data[3] <= (data[3] >= data[4]);
            lbp_data[4] <= (data[5] >= data[4]);
            lbp_data[5] <= (data[6] >= data[4]);
            lbp_data[6] <= (data[7] >= data[4]);
            lbp_data[7] <= (data[8] >= data[4]);
            // update data
            data[0] <= data[1];
            data[3] <= data[4];
            data[6] <= data[7];
            data[1] <= data[2];
            data[4] <= data[5];
            data[7] <= data[8];
            // update pos 
            pos <= pos_r;
            // ready to go back to READUR state
            gray_addr <= pos_urr;
        end

        FININSH: finish <= 1;
    endcase
end

endmodule
