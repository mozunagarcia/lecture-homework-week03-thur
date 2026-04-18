`timescale 1ns / 1ps

`include "uart_rx.sv"

module testbench();

parameter TX_DATA_VALUE = 8'hAB;

// Signals for UUT connection
reg Clk;
reg tx;
wire rx_ready;
wire [7:0] rx_data;
reg pass;

// Instantiate the unit under test
uart_rx uut (Clk, tx, rx_ready, rx_data);

initial begin
    // Set up output to VCDD file
    $dumpfile("tb.vcd");
    $dumpvars(0, testbench);

    // Initialize testbench variables
    pass = 1'b0;

    // Simulate the clock signal
    Clk = 1'b0;
    forever begin
        #10 Clk = ~Clk;
    end
end

localparam 
    SRC_FREQ = 76800,
    TX_FREQ  = 9600;

integer clock_multiplier = SRC_FREQ / TX_FREQ / 2;
integer tick_count = 0;
reg rx_clk = 1'b0;

always @(posedge Clk) begin
    if (tick_count >= clock_multiplier) begin
        tick_count <= 0;
        rx_clk <= ~rx_clk;
    end else begin
        tick_count <= tick_count + 1;
    end
end

localparam
    INIT = 0,
    IDLE = 1,
    START = 2,
    TX_DATA = 3,
    STOP = 4;

integer state = INIT;
reg [7:0] tx_data;
integer bit_count;
reg start_tx = 1'b0;

always @(posedge rx_clk) begin
    case(state)
        INIT: begin
            tx <= 1'b1;
            bit_count <= 0;
            tx_data <= TX_DATA_VALUE;
            state <= IDLE;
        end

        IDLE: begin
            if (start_tx) begin
                state <= START;
            end
        end

        START: begin
            tx <= 1'b0;
            start_tx <= 1'b0;
            state <= TX_DATA;
        end

        TX_DATA: begin
            if (bit_count < 8) begin
                tx <= tx_data[bit_count];
                bit_count <= bit_count + 1;
            end else state <= STOP;
        end

        STOP: begin
            tx <= 1'b1;
            state <= IDLE;
        end
    endcase
end

integer ready_count = 0;
reg rx_data_correct = 1'b0;

always @(posedge Clk) begin
    if (rx_ready) begin
        ready_count <= ready_count + 1;
        rx_data_correct <= rx_data == TX_DATA_VALUE;
    end
    pass <= ready_count == 1 && rx_data_correct;
end

// Write Checker
initial begin

    #500; start_tx <= 1'b1;

    #3000;
    if (pass) begin
        $display("Tests Passed!");
    end else begin
        $display("Failed tests");
    end


    $finish();
end

endmodule
