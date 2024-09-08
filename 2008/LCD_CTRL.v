module LCD_CTRL (
    input  wire        clk,              // posedge
    input  wire        reset,            // active high asynchronous
    input  wire [7:0]  datain,
    input  wire [2:0]  cmd,              // seven types of cmds in total, Valid When cmd_valid is high and busy is low
    input  wire        cmd_valid,        // high --> valid cmd 
    output reg  [7:0]  dataout,          
    output reg         output_valid,     // high --> valid output
    output reg         busy
);

parameter IDLE = 2'b00;
parameter LOAD = 2'b01;
parameter OUTPUT = 2'b10;
parameter OPERATE = 2'b11;

reg OutputFlag; // 0 zoomfit 1 zoomin
reg OperateCounter;
reg [1:0] state, nxt_state;
reg [2:0] CountToFour, OperateFlag;  // For OperateFlag: 00 Up 01 Down 10 Left 11 Right    
reg [4:0] OutputCounter;
reg [6:0] LoadingCounter, OutputInd, X, Y;
reg [7:0] graph [108:0];

always @(posedge clk or posedge reset) begin
    if (reset) state <= IDLE;
    else state <= nxt_state;
end 

always @(*) begin 
    nxt_state <= state;
    case(state) 
        IDLE: if (cmd_valid && cmd == 3'd0) nxt_state <= LOAD;
        LOAD: if (LoadingCounter == 7'd108) nxt_state <= OUTPUT;
        OPERATE: if (OperateCounter) nxt_state <= OUTPUT; // let operate run one Idle cycle --> avoid data confict
        OUTPUT: begin
            if (cmd_valid && cmd == 3'd0) begin 
                nxt_state <= LOAD;
                OutputFlag <= 0;
            end
            else if (cmd_valid && cmd == 3'd1) OutputFlag <= 1;
            else if (cmd_valid && cmd == 3'd2) OutputFlag <= 0; 
            else if (cmd_valid && OutputFlag) begin // shift is valid only in zoomin mode
                if (cmd == 3'd3)      OperateFlag <= 2'b11; // right
                else if (cmd == 3'd4) OperateFlag <= 2'b10; // left
                else if (cmd == 3'd5) OperateFlag <= 2'b00; // up
                else if (cmd == 3'd6) OperateFlag <= 2'b01; // down
                nxt_state <= OPERATE;
            end
        end
    endcase
end

always @(posedge clk) begin
    case(state) 
        IDLE: begin
            busy <= 0;
            output_valid <= 0;
            OutputInd <= 0;
            OutputFlag <= 0;
            OperateCounter <= 0;
            LoadingCounter <= 7'd0;
            OutputCounter <= 5'd0;
            X <= 7'd6; Y <= 7'd5;
            CountToFour <= 3'd0;
        end

        LOAD: begin
            busy <= 1;
            if (LoadingCounter == 7'd108) begin 
                LoadingCounter <= 7'd0;
                OutputFlag <= 0;
            end
            else begin
                graph[LoadingCounter] <= datain;
                LoadingCounter <= LoadingCounter + 1;
            end
        end

        OPERATE: begin 
            OutputCounter <= 0;
            if (OperateFlag == 2'b11 && !OperateCounter)      X <= (X>9) ? 10 : (X+1); // right 
            else if (OperateFlag == 2'b10 && !OperateCounter) X <= (X<3) ?  2 : (X-1); // left 
            else if (OperateFlag == 2'b00 && !OperateCounter) Y <= (Y<3) ?  2 : (Y-1); // up
            else if (OperateFlag == 2'b01 && !OperateCounter) Y <= (Y>6) ?  7 : (Y+1); // down
            OperateCounter <= 1;
        end

        OUTPUT: begin
            // In ZoomFit mode, set X, Y to the default value
            X <= (!OutputFlag) ? 7'd6 : X;
            Y <= (!OutputFlag) ? 7'd5 : Y;
            OperateCounter <= 0;
            // Init Index
            if (OutputCounter == 5'd0) begin
                // if zoomin, start from the left corner point
                OutputInd <= (OutputFlag) ? (((Y-2)<<3)+((Y-2)<<2)+(X-2)) : (7'd13);
                CountToFour <= 3'd1;
                OutputCounter <= 1;
                busy <= 1;
            end
            // Output Ended
            else if (OutputCounter == 5'd17) begin
                OutputCounter <= 5'd0;
                output_valid <= 0;
                busy <= 0;
            end
            else begin
                output_valid <= 1;
                // output
                dataout <= graph[OutputInd];
                // update index
                CountToFour <= CountToFour + 1;
                if (CountToFour == 3'd4) begin
                    OutputInd <= (OutputFlag) ? (OutputInd+9) : (OutputInd+15);
                    CountToFour <= 3'd1; 
                end
                else begin
                    OutputInd <= (OutputFlag) ? (OutputInd+1) : (OutputInd+3);
                    CountToFour <= CountToFour + 1;
                end
                // update OutputCounter
                OutputCounter <= OutputCounter + 1;
            end
        end
    endcase
end

endmodule
