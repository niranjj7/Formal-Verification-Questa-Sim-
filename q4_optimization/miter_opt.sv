// Miter for Optimization Equivalence Check (Q4)
// Checks: top (original) ≡ top_opt (optimized)
// Both are combinational, so no clock needed.

module miter_opt(input A, B, C, output miter_out);

    wire F_orig, F_opt;

    top     u_orig (.A(A), .B(B), .C(C), .F(F_orig));
    top_opt u_opt  (.A(A), .B(B), .C(C), .F(F_opt));

    // XOR: 1 only if outputs differ
    assign miter_out = F_orig ^ F_opt;

    // Equivalence assertion (combinational — no clock)
    // Questa Formal will exhaustively check all A,B,C combos
    assert_equiv: assert (miter_out == 1'b0)
        else $error("OPTIMIZATION BUG: original and optimized outputs differ!");

endmodule
