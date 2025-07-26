// Code your design here
module async_fifo #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 2  // 2^2 = 4 depth
)(
    input wr_clk, rd_clk,
    input rst,
    input wr_en,
    input rd_en,
    input [DATA_WIDTH-1:0] din,
    output reg [DATA_WIDTH-1:0] dout,
    output reg full,
    output reg empty
);

    localparam DEPTH = 1 << ADDR_WIDTH;

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // Pointers
    reg [ADDR_WIDTH:0] wr_ptr_bin = 0, rd_ptr_bin = 0;
    reg [ADDR_WIDTH:0] wr_ptr_gray = 0, rd_ptr_gray = 0;

    // Sync pointers across domains
    reg [ADDR_WIDTH:0] rd_ptr_gray_sync1 = 0, rd_ptr_gray_sync2 = 0;
    reg [ADDR_WIDTH:0] wr_ptr_gray_sync1 = 0, wr_ptr_gray_sync2 = 0;

    // Write domain logic
    always @(posedge wr_clk or posedge rst) begin
        if (rst) begin
            wr_ptr_bin <= 0;
            wr_ptr_gray <= 0;
        end else if (wr_en && !full) begin
            mem[wr_ptr_bin[ADDR_WIDTH-1:0]] <= din;
            wr_ptr_bin <= wr_ptr_bin + 1;
            wr_ptr_gray <= (wr_ptr_bin >> 1) ^ wr_ptr_bin;
        end
    end

    // Read domain logic
    always @(posedge rd_clk or posedge rst) begin
        if (rst) begin
            rd_ptr_bin <= 0;
            rd_ptr_gray <= 0;
            dout <= 0;
        end else if (rd_en && !empty) begin
            dout <= mem[rd_ptr_bin[ADDR_WIDTH-1:0]];
            rd_ptr_bin <= rd_ptr_bin + 1;
            rd_ptr_gray <= (rd_ptr_bin >> 1) ^ rd_ptr_bin;
        end
    end

    // Pointer synchronization
    always @(posedge wr_clk or posedge rst) begin
        if (rst) begin
            rd_ptr_gray_sync1 <= 0;
            rd_ptr_gray_sync2 <= 0;
        end else begin
            rd_ptr_gray_sync1 <= rd_ptr_gray;
            rd_ptr_gray_sync2 <= rd_ptr_gray_sync1;
        end
    end

    always @(posedge rd_clk or posedge rst) begin
        if (rst) begin
            wr_ptr_gray_sync1 <= 0;
            wr_ptr_gray_sync2 <= 0;
        end else begin
            wr_ptr_gray_sync1 <= wr_ptr_gray;
            wr_ptr_gray_sync2 <= wr_ptr_gray_sync1;
        end
    end

    // Empty & Full Logic
    always @(*) begin
        empty = (rd_ptr_gray == wr_ptr_gray_sync2);
        full  = (wr_ptr_gray == {~rd_ptr_gray_sync2[ADDR_WIDTH:ADDR_WIDTH-1], rd_ptr_gray_sync2[ADDR_WIDTH-2:0]});
    end
endmodule
