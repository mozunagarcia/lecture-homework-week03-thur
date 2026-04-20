`include "clock_mul.sv"

module uart_rx (
    input clk,
    input rx,
    output reg rx_ready,
    output reg [7:0] rx_data
);

parameter SRC_FREQ = 76800;
parameter BAUDRATE = 9600;

// STATES: State of the state machine
localparam DATA_BITS = 8;
localparam
    INIT = 0,
    IDLE = 1,
    RX_DATA = 2,
    STOP = 3;

// CLOCK MULTIPLIER: Instantiate the clock multiplier
wire rx_clk;
clock_mul #(
    .SRC_FREQ(SRC_FREQ),
    .OUT_FREQ(BAUDRATE)
) clk_mul (
    .src_clk(clk),
    .out_clk(rx_clk)
);

reg [7:0] rx_data_buf = 8'h00;
integer bit_index = 0;
integer state = INIT;
reg uart_done = 1'b0;

// CROSS CLOCK DOMAIN: The rx_ready flag should only be set high for one source
// clock cycle. Synchronize uart_done into the source clock domain with two FFs,
// then generate a 1-cycle pulse on the rising edge.
reg uart_done_sync1 = 1'b0;
reg uart_done_sync2 = 1'b0;
reg uart_done_prev = 1'b0;

always @(posedge clk) begin
    uart_done_sync1 <= uart_done;
    uart_done_sync2 <= uart_done_sync1;
    uart_done_prev  <= uart_done_sync2;
    rx_ready <= uart_done_sync2 & ~uart_done_prev;
end

// STATE MACHINE: Use the UART clock to drive the state machine that receives a byte
always @(posedge rx_clk) begin
    case (state)
        INIT: begin
            bit_index <= 0;
            uart_done <= 1'b0;
            rx_data_buf <= 8'h00;
            state <= IDLE;
        end

        IDLE: begin
            uart_done <= 1'b0;
            bit_index <= 0;
            if (!rx)          // Start bit detected (logic low)
                state <= RX_DATA;
        end

        RX_DATA: begin
            rx_data_buf[bit_index] <= rx;
            if (bit_index == DATA_BITS - 1)
                state <= STOP;
            else
                bit_index <= bit_index + 1;
        end

        STOP: begin
            if (rx) begin     // Valid stop bit (logic high)
                rx_data <= rx_data_buf;
                uart_done <= 1'b1;
            end
            state <= IDLE;
        end
    endcase
end

endmodule