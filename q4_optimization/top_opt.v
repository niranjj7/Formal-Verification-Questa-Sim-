// Optimized Netlist (Q4)
// After logic optimization: F = A & B
// (C is absorbed because (A&B)|(A&B&C) = A&B by absorption law)
// This is the result Yosys/Questa generates after 'opt' passes.
 
module top_opt(input A, B, C, output F);
    assign F = A & B;
endmodule
