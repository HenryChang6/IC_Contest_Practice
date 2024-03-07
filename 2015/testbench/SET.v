module SET ( clk , rst, en, central, radius, mode, busy, valid, candidate );
// 二維 8x8 座標空間

input clk, rst;
input en;
input [23:0] central;
// central[23:20] :為集合 A 的 X 軸座標(x1) 
// central[19:16] :為集合 A 的 Y 軸座標(y1) 
// central[15:12] :為集合 B 的 X 軸座標(x2) 
// central[11:8] :為集合 B 的 Y 軸座標(y2)
input [11:0] radius;
// radius[11:8]:為集合 A 的半徑值 r1 
// radius[7:4] :為集合 B 的半徑值 r2
input [1:0] mode;
// mode 訊號為 2’b00 A 
// mode 訊號為 2’b01 ( A ∪ B )
// mode 訊號為 2’b10 ( A ∪ B ) - ( A ∩ B ) 
output busy;
output valid;
output [7:0] candidate; //集合 A 與集合 B 的交集個數

wire x1 [3:0] , y1 [3:0] , x2 [3:0] , y2 [3:0] , r1 [3:0] , r2 [3:0] ;
wire deltaX1 [3:0] , deltaY1 [3:0] , deltaX2 [3:0] , deltaY2 [3:0] ;
reg current_x [3:0] , current_y [3:0] ;

assign x1 = central[23:20];
assign y1 = central[19:16];
assign x2 = central[15:12];
assign y2 = central[11:8];
assign r1 = radius[11:8];
assign r2 = radius[7:4];
assign deltaX1 = current_x > x1 ? current_x - x1 : x1 - current_x;
assign deltaY1 = current_y > y1 ? current_y - y1 : y1 - current_y;
assign deltaX2 = current_x > x2 ? current_x - x2 : x2 - current_x;
assign deltaY2 = current_y > y2 ? current_y - y2 : y2 - current_y;



integer i, j;

// busy 變為 0 後的第一個negedge 會馬上送下一筆（包含en central radius mode）

always @(posedge clk or posedge rst) begin
    if(rst) begin
        /* reset logic */
        busy <= 1'b0;
        valid <= 1'b0;
        candidate <= 8'b0;
    end
    else begin
        if(en) begin
            /* SET logic */
            busy <= 1'b1;
            candidate <= 8'b0;
            if(mode == 2'b00) begin
                // Determine if the point is in the circle
                if((deltaX1 < r1 && deltaY1 < r1) || (deltaX1 == r1 && deltaY1 == 0) || (deltaX1 == 0 && deltaY1 == r1)) begin
                    candidate <= candidate + 1;
                end
                // update current_x and current_y
                if(current_x == 7 && current_y == 7) begin
                    valid <= 1'b1;
                    busy <= 1'b0;
                    current_x <= 0;
                    current_y <= 0;
                end
                else if(current_x == 7) begin
                    current_x <= 0;
                    current_y <= current_y + 1;
                end
                else begin
                    current_x <= current_x + 1;
                end
                
            end
            else if(mode == 2'b01) begin
                // Determine if the point is in the A U B
                if((deltaX1 < r1 && deltaY1 < r1) || (deltaX1 == r1 && deltaY1 == 0) || (deltaX1 == 0 && deltaY1 == r1)) begin
                    if((deltaX2 < r2 && deltaY2 < r2) || (deltaX2 == r2 && deltaY2 == 0) || (deltaX2 == 0 && deltaY2 == r2)) begin
                        candidate <= candidate + 1;
                    end
                end
                else if((deltaX2 < r2 && deltaY2 < r2) || (deltaX2 == r2 && deltaY2 == 0) || (deltaX2 == 0 && deltaY2 == r2)) begin
                    if((deltaX1 < r1 && deltaY1 < r1) || (deltaX1 == r1 && deltaY1 == 0) || (deltaX1 == 0 && deltaY1 == r1)) begin
                        candidate <= candidate + 1;
                    end
                end
                // update current_x and current_y
                if(current_x == 7 && current_y == 7) begin
                    valid <= 1'b1;
                    busy <= 1'b0;
                    current_x <= 0;
                    current_y <= 0;
                end
                else if(current_x == 7) begin
                    current_x <= 0;
                    current_y <= current_y + 1;
                end
                else begin
                    current_x <= current_x + 1;
                end
            end
            else if(mode == 2'b10) begin
                // Determine if the point is in the (A∪B)-(A∩B)
                if((deltaX1 < r1 && deltaY1 < r1) || (deltaX1 == r1 && deltaY1 == 0) || (deltaX1 == 0 && deltaY1 == r1)) begin
                    if(!((deltaX2 < r2 && deltaY2 < r2) || (deltaX2 == r2 && deltaY2 == 0) || (deltaX2 == 0 && deltaY2 == r2))) begin
                        candidate <= candidate + 1;
                    end
                end
                else if((deltaX2 < r2 && deltaY2 < r2) || (deltaX2 == r2 && deltaY2 == 0) || (deltaX2 == 0 && deltaY2 == r2)) begin
                    if(!((deltaX1 < r1 && deltaY1 < r1) || (deltaX1 == r1 && deltaY1 == 0) || (deltaX1 == 0 && deltaY1 == r1))) begin
                        candidate <= candidate + 1;
                    end
                end
                // update current_x and current_y
                if(current_x == 7 && current_y == 7) begin
                    valid <= 1'b1;
                    busy <= 1'b0;
                    current_x <= 0;
                    current_y <= 0;
                end
                else if(current_x == 7) begin
                    current_x <= 0;
                    current_y <= current_y + 1;
                end
                else begin
                    current_x <= current_x + 1;
                end
            end
        end
    end

end


endmodule




