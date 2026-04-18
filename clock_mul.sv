module clock_mul #(
    parameter SRC_FREQ = 8, 
    parameter OUT_FREQ = 1
) (
    input src_clk,
    output out_clk   
);

reg out_clk_reg = 1'b0;

integer clock_multiplier = SRC_FREQ / OUT_FREQ / 2;
integer offset = SRC_FREQ / OUT_FREQ / 2 / 2 - 1;

// Put in the clock multip
integer tick_count = 0;
integer offset_count = 0;

always @(posedge src_clk) begin
    if (offset_count < offset) begin
        offset_count <= offset_count + 1;
    end else
        if (tick_count >= clock_multiplier) begin
            tick_count <= 0;
            out_clk_reg <= ~out_clk_reg;
        end else begin
            tick_count <= tick_count + 1;
        end
end

assign out_clk = out_clk_reg;

endmodule