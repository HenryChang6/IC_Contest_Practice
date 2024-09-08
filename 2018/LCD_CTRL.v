module LCD_CTRL(clk, reset, cmd, cmd_valid, IROM_Q, IROM_rd, IROM_A, IRAM_valid, IRAM_D, IRAM_A, busy, done);
input clk;
input reset;
input [3:0] cmd;
input cmd_valid;
input [7:0] IROM_Q;
output reg IROM_rd;
output reg [5:0] IROM_A;
output reg IRAM_valid;
output reg [7:0] IRAM_D;
output reg [6:0] IRAM_A;
output reg busy;
output reg done;
// state parameters
parameter IDLE = 4'b1100;
parameter READ = 4'b1101;
parameter OPERATE = 4'b1110;
parameter WRITE = 4'b1111;
// command parameters
parameter WRITE_CMD = 4'b0000;
parameter UP = 4'b0001;
parameter DOWN = 4'b0010;
parameter LEFT = 4'b0011;
parameter RIGHT = 4'b0100;
parameter MAX = 4'b0101;
parameter MIN = 4'b0110;
parameter AVG = 4'b0111;
parameter ROTATE_COUNTER = 4'b1000;
parameter ROTATE = 4'b1001;
parameter MIRROR_X = 4'b1010;
parameter MIRROR_Y = 4'b1011;
// register
reg [3:0] nxt_state, state;
reg [7:0] graph [63:0];
reg [5:0] pos1; // left up corner
// wire
wire [5:0] IRAM_A_plusone = IRAM_A + 1;
wire [5:0] pos2 = pos1 + 1; // right up corner
wire [5:0] pos3 = pos1 + 8; // left down corner
wire [5:0] pos4 = pos1 + 9; // right down corner
wire [5:0] pos_up = pos1 - 8;
wire [5:0] pos_left = pos1 - 1;
wire [7:0] data1 = graph[pos1];
wire [7:0] data2 = graph[pos2];
wire [7:0] data3 = graph[pos3];
wire [7:0] data4 = graph[pos4];
wire [7:0] max1 = (data1 > data2) ? data1 : data2;
wire [7:0] max2 = (data3 > data4) ? data3 : data4;
wire [7:0] max = (max1 > max2) ? max1 : max2;
wire [7:0] min1 = (data1 < data2) ? data1 : data2;
wire [7:0] min2 = (data3 < data4) ? data3 : data4;
wire [7:0] min = (min1 < min2) ? min1 : min2;
wire [9:0] sum = data1 + data2 + data3 + data4;
wire [7:0] avg = sum[9:2];
// FSM
always @(posedge clk or posedge reset) begin
    if (reset) state <= IDLE;
    else state <= nxt_state;
end

// Next State Logic
always @(*) begin
    case(state) 
        IDLE: nxt_state <= READ;
        READ: if (IROM_A == 6'd63) nxt_state <= OPERATE;
        OPERATE: if (cmd_valid && cmd == WRITE_CMD) nxt_state <= WRITE;
        // When WRITE complete, the program will end 
    endcase
end 

// State Action Logic
always @(posedge clk) begin
    case (state) 
        IDLE: begin
            busy <= 1;     done <= 0;
            IROM_rd <= 1;  IROM_A <= 0;
            IRAM_A <= -1;   
            pos1 <= 8'd27;
        end

        READ: begin
            busy <= 1;
            graph[IROM_A] <= IROM_Q;
            IROM_A <= IROM_A + 1;
            if (IROM_A == 7'd63) busy <= 0;
        end

        OPERATE: begin
            if (cmd_valid) begin
               case (cmd) 
                    UP:    if (pos1[5:3] != 3'b000) pos1 <= pos_up; 
                    DOWN:  if (pos1[5:3] != 3'b110) pos1 <= pos3;
                    LEFT:  if (pos1[2:0] != 3'b000) pos1 <= pos_left;
                    RIGHT: if (pos1[2:0] != 3'b110) pos1 <= pos2;
                    MAX: begin
                        graph[pos1] <= max;
                        graph[pos2] <= max;
                        graph[pos3] <= max;
                        graph[pos4] <= max;
                    end
                    MIN: begin
                        graph[pos1] <= min;
                        graph[pos2] <= min;
                        graph[pos3] <= min;
                        graph[pos4] <= min;
                    end 
                    AVG: begin
                        graph[pos1] <= avg;
                        graph[pos2] <= avg;
                        graph[pos3] <= avg;
                        graph[pos4] <= avg;
                    end 
                    ROTATE_COUNTER: begin
                        graph[pos1] <= data2;
                        graph[pos2] <= data4;
                        graph[pos3] <= data1;
                        graph[pos4] <= data3;
                    end
                    ROTATE: begin
                        graph[pos1] <= data3;
                        graph[pos2] <= data1;
                        graph[pos3] <= data4;
                        graph[pos4] <= data2;
                    end
                    MIRROR_X: begin
                        graph[pos1] <= data3;
                        graph[pos2] <= data4;
                        graph[pos3] <= data1;
                        graph[pos4] <= data2;
                    end
                    MIRROR_Y: begin
                        graph[pos1] <= data2;
                        graph[pos2] <= data1;
                        graph[pos3] <= data4;
                        graph[pos4] <= data3;
                    end
               endcase
            end    
        end

        WRITE: begin
            IRAM_valid <= 1;
            busy <= 1;
            IRAM_D <= graph[IRAM_A_plusone];
            IRAM_A <= IRAM_A + 1;
            if (IRAM_A == 7'd63) begin
                busy <= 0;
                IRAM_valid <= 0;
                done <= 1;
            end
        end
    endcase
end

endmodule



