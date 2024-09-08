module SET ( clk , rst, en, central, radius, mode, busy, valid, candidate );

input clk, rst;
input en;
input [23:0] central;
input [11:0] radius;
input [1:0] mode;
output reg busy;
output reg valid;
output reg [7:0] candidate; 

wire [3:0] x1 ; wire [3:0] y1 ; wire [3:0] x2; wire [3:0] y2; wire [3:0] r1; wire [3:0] r2;
wire [6:0] dis1; wire [6:0] dis2; wire[6:0] r1_square; wire[6:0] r2_square;
reg  [3:0] current_x; reg [3:0]current_y ;

assign x1 = central[23:20];  assign y1 = central[19:16];
assign x2 = central[15:12];  assign y2 = central[11:8];
assign r1 = radius[11:8];    assign r2 = radius[7:4];

assign dis_x1 = $signed (current_x - x1) * $signed (current_x - x1) + $signed (current_y - y1) * $signed (current_y - y1);
assign dis2 = $signed (current_x - x2) * $signed (current_x - x2) + $signed (current_y - y2) * $signed (current_y - y2);

assign r1_square = r1 * r1;
assign r2_square = r2 * r2;

integer i, j;

always @(posedge clk or posedge rst) begin
    if(rst) begin
        /* reset logic */
        busy <= 1'b0;
        valid <= 1'b0;  
        candidate <= 8'b0;
        current_x <= 4'd1;
        current_y <= 4'd1;
    end
    else if(en) begin
        busy <= 1'b1;
        valid <= 1'b0;
        candidate <= 8'b0;
    end
    else begin
        if(mode == 2'b00) begin
            // Determine if the point is in the circle
            if(dis1 <= r1_square) begin
                candidate <= candidate + 1;
            end
            // update current_x and current_y
            if(current_x == 8 && current_y == 8) begin
                valid <= 1'b1;
                busy <= 1'b0;
                current_x <= 4'd1;
                current_y <= 4'd1;
            end
            else if(current_x == 8) begin
                current_x <= 4'd1;
                current_y <= current_y + 1;
            end
            else begin
                current_x <= current_x + 1;
            end
            
        end
        else if(mode == 2'b01) begin
            // Determine if the point is in the A ∩ B
            if(dis1 <= r1_square && dis2 <= r2_square) begin
                candidate <= candidate + 1;
            end
            // update current_x and current_y
            if(current_x == 8 && current_y == 8) begin
                valid <= 1'b1;
                busy <= 1'b0;
                current_x <= 4'd1;
                current_y <= 4'd1;
            end
            else if(current_x == 8) begin
                current_x <= 4'd1;
                current_y <= current_y + 1;
            end
            else begin
                current_x <= current_x + 1;
            end
        end
        else if(mode == 2'b10) begin
            // Determine if the point is in the (A∪B)-(A∩B)
            if((dis1 <= r1_square && dis2 > r2_square) || (dis2 <= r2_square && dis1 > r1_square)) begin
                candidate <= candidate + 1;
            end
             // update current_x and current_y
            if(current_x == 8 && current_y == 8) begin
                valid <= 1'b1;
                busy <= 1'b0;
                current_x <= 4'd1;
                current_y <= 4'd1;
            end
            else if(current_x == 8) begin
                current_x <= 4'd1;
                current_y <= current_y + 1;
            end
            else begin
                current_x <= current_x + 1;
            end
        end
    end
end


endmodule




