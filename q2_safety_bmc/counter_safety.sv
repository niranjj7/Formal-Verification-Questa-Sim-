module counter(
    input  wire       clk,
    input  wire       rst,
    output reg  [1:0] count
);

    always @(posedge clk) begin
        if (rst)
            count <= 2'b00;
        else
            count <= count + 1;
    end
property safety_no_state_11;
        @(posedge clk) (count !== 2'b11);
    endproperty

    assert property (safety_no_state_11)
        else $error("SAFETY VIOLATION: counter reached state 2'b11 at time %0t", $time);

endmodule
