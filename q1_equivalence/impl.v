// Circuit B - Implementation Design
// Computes y = NOT(NOT a OR NOT b) = a AND b  (De Morgan's theorem)
module impl(input clk, input a, input b, output reg y);
    always @(posedge clk)
        y <= ~(~a | ~b);
endmodule
