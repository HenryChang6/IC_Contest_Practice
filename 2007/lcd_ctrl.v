module lcd_ctrl(clk, reset, datain, cmd, cmd_valid, dataout, output_valid, busy);
input                clk;
input                reset;
input        [7:0]   datain;
input        [2:0]   cmd;
input                cmd_valid;
output  reg  [7:0]   dataout;
output  reg          output_valid;
output  reg          busy;

        reg  [7:0]   graph     [0:35];
        reg  [1:0]   originX;
        reg  [1:0]   originY;
        reg  [2:0]   currentX;
        reg  [2:0]   currentY;
        reg  [5:0]   input_counter;
        reg  [2:0]   stage;

integer i;

always @(negedge clk or posedge reset) begin
    if(reset) begin
        stage <= 0;
        busy <= 0;
    end
    else begin
        if(cmd_valid) begin
            busy <= 2'd1;
            stage <= cmd;
        end
    end
end

always @(posedge clk or posedge reset) begin 
    if(reset) begin
        input_counter <= 6'd0;

        currentX <= 3'd2;
        currentY <= 3'd2;
        originX <= 2'd2;
        originY <= 2'd2;
        output_valid <= 0;
        for(i = 0; i < 36; i = i + 1)
            graph[i] <= 8'd0;
    end
    else begin
        /* Load Data */
        if(!cmd_valid && busy && stage == 3'b001) begin
            if(input_counter < 36) begin
                graph[input_counter] <= datain;
                input_counter <= input_counter + 1;
            end
            else begin
                // output logic
                if(originX == currentX && originY == currentY) begin
                    output_valid <= 1;
                    originX <= 2;
                    originY <= 2;
                    currentX <= originX;
                    currentY <= originY;
                end
                // output logic
                dataout <= graph[6 * currentY + currentX];
                // update currentX and currentY
                if(currentX == originX + 3'd2) begin
                    // Finished Printing
                    if(currentY == originY + 3'd2) begin
                        busy <= 0;
                        output_valid <= 0;
                        input_counter <= 0;
                    end
                    else begin
                        currentX <= originX;
                        currentY <= currentY + 1;
                    end
                end
                else begin
                    currentX <= currentX + 1;
                end
            end
        end
        /* Cmd except for Load Data*/
        else if(!cmd_valid && busy) begin
            if(originX == currentX && originY == currentY) begin
                // update currentX and currentY 
                if(stage == 3'b010)      originX <= originX >= 2'd3 ? 2'd3 : originX + 1;      /*  Shift Right    */
                else if(stage == 3'b011) originX <= originX <= 2'd0 ? 2'd0 : originX - 1;     /*   Shift Left    */
                else if(stage == 3'b100) originY <= originY <= 2'd0 ? 2'd0 : originY - 1;    /*    Shift Up     */
                else if(stage == 3'b101) originY <= originY <= 2'd3 ? 2'd3 : originY + 1;   /*     Shift Down  */
                // Update originX and originY
                output_valid <= 1;
                currentX <= originX;
                currentY <= originY;
            end
            // output logic
            dataout <= graph[6 * currentY + currentX];
            // update currentX and currentY
            if(currentX == originX + 3'd2) begin
                // Finished Printing
                if(currentY == originY + 3'd2) begin
                    busy <= 0;
                    output_valid <= 0;
                    input_counter <= 0;
                end
                else begin
                    currentX <= originX;
                    currentY <= currentY + 1;
                end
            end
            else begin
                currentX <= currentX + 1;
            end
        end
    end
end
                                                                                     
endmodule
