// Code your testbench here
// or browse Examples
module tb_async_fifo;
    reg wr_clk = 0, rd_clk = 0, rst;
    reg wr_en, rd_en;
    reg [7:0] din;
    wire [7:0] dout;
    wire full, empty;

    async_fifo uut (
        .wr_clk(wr_clk), .rd_clk(rd_clk), .rst(rst),
        .wr_en(wr_en), .rd_en(rd_en),
        .din(din), .dout(dout),
        .full(full), .empty(empty)
    );

    // Generate clocks
    always #4 wr_clk = ~wr_clk;  // 125 MHz
    always #7 rd_clk = ~rd_clk;  // ~71 MHz

    initial begin
        $monitor("Time=%0t | wr_en=%b, rd_en=%b, din=%h, dout=%h, full=%b, empty=%b",
                 $time, wr_en, rd_en, din, dout, full, empty);

        rst = 1; wr_en = 0; rd_en = 0; din = 0; #20;
        rst = 0;

        // Write data
        repeat (4) begin
            @(posedge wr_clk);
            wr_en = 1;
            din = din + 8'h11;
        end
        wr_en = 0;

        // Read data
        repeat (4) begin
            @(posedge rd_clk);
            rd_en = 1;
        end
        rd_en = 0;

        #100 $finish;
    end
endmodule
