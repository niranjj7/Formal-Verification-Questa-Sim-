// 2-bit Counter with Liveness Property (Q3)
// Liveness Property: GF(count == 2'b00)
// "Globally, Eventually count returns to 00"
// i.e., count ALWAYS eventually comes back to 00.
//
// For BMC, liveness (GF P) is harder: we look for a loop
// in the state space where P is never satisfied.
// Questa Formal handles this with loop detection in BMC.

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

    // -------------------------------------------------------
    // Liveness Property
    // GF(count == 00): Globally, eventually count == 00.
    //
    // In SVA this is expressed as a 'cover' (reachability)
    // or via an 'assert' with a sequence that loops.
    //
    // Questa Formal liveness check:
    //   We assert that there is NO infinite run where
    //   count == 00 is never visited (no lasso without 00).
    //
    // Alternatively, we use a cover property to show 00
    // IS reachable within k steps from any start state.
    // -------------------------------------------------------

    // Approach 1: Assert that within any window of 4 cycles,
    // count will be 00 at some point (bounded liveness)
    property liveness_count_returns_to_00;
        @(posedge clk) strong(##[0:4] (count == 2'b00));
    endproperty

    assert property (liveness_count_returns_to_00)
        else $error("LIVENESS VIOLATION: count did not return to 00 within 4 cycles");

    // Approach 2: Cover property — show 00 is reachable
    // (Questa Formal proves coverage = liveness witness)
    cover property (@(posedge clk) count == 2'b00);

endmodule
