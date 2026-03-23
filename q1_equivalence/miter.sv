// Miter Circuit for Equivalence Checking
// Instantiates both ref and impl with shared inputs.
// The output 'miter_out' is 1 (asserted) if any output differs.
// For equivalence: miter_out must NEVER be 1.
// This is passed to the SAT solver as a reachability check.

module miter(input clk, input a, input b, output miter_out);

    wire y_ref, y_impl;

    // Instantiate both circuits with identical inputs
    ref   u_ref  (.clk(clk), .a(a), .b(b), .y(y_ref));
    impl  u_impl (.clk(clk), .a(a), .b(b), .y(y_impl));

    // XOR: high only when outputs differ
    assign miter_out = y_ref ^ y_impl;

    // Assertion: outputs should never differ
    // In Questa Formal, this property is checked by the engine
    property equiv_check;
        @(posedge clk) (miter_out == 1'b0);
    endproperty

    assert property (equiv_check)
        else $error("EQUIVALENCE VIOLATION: ref and impl outputs differ!");

endmodule
