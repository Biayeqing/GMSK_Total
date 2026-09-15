`timescale 1ns / 1ps
module downsample_10x (
    input wire clk,
    input wire rst_n,
    input wire [15:0] data_in,
    input wire data_valid,
    output reg [15:0] data_out,
    output reg data_out_valid
);

    reg [3:0] counter;  // 计数0-9
    reg [15:0] data_in_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 4'd0;
            data_out <= 'b0;
            data_out_valid <= 1'b0;
            data_in_reg <= 'b0;
        end else begin
            if (data_valid) begin
                data_in_reg <= data_in;  // 锁存输入数据
                if (counter == 4'd0) begin
                    counter <= 4'd1;
                    data_out <= data_in;  // 输出第10个数据
                    data_out_valid <= 1'b1;
                end else begin
                    if(counter == 4'd9)begin
                        counter <= 0;
                        data_out_valid <= 1'b0;
                        end
                    else
                        counter <= counter + 1'b1;
                        data_out_valid <= 1'b0;
                end
            end else begin
                data_out_valid <= 1'b0;
            end
        end
    end

endmodule