# =============================================================================
# Questa Formal - Logic Optimization + Equivalence Check (Q4)
# Part A: Optimization (conceptual — done via Yosys or Questa Lint)
# Part B: Equivalence Check using Questa Formal + SAT
# =============================================================================

# -------------------------------------------------------
# PART A: Logic Optimization (Yosys commands — run separately)
# Read RTL → optimize → write netlist
# -------------------------------------------------------
# yosys -p "
#   read_verilog top.v;       # Read RTL source
#   hierarchy -check;          # Check and set hierarchy
#   proc;                      # Convert always blocks to netlist
#   opt;                       # General optimisation passes
#   techmap;                   # Map to basic gates
#   opt;                       # Optimise again post-techmap
#   write_verilog top_opt.v;   # Export optimised netlist
# "
# (The result top_opt.v is: assign F = A & B)

# -------------------------------------------------------
# PART B: Formal Equivalence Check in Questa Formal
# -------------------------------------------------------

# Step 1: Compile both original and optimized netlists
vlib work
vmap work work

# vlog: compile original RTL
# -sv: enable SystemVerilog for assert statements
vlog -sv -work work top.v

# vlog: compile optimized netlist
vlog -sv -work work top_opt.v

# vlog: compile miter circuit (ties them together)
vlog -sv -work work miter_opt.sv

# -------------------------------------------------------
# Step 2: Formal compile
# formal compile: elaborates the miter design and builds
#                 the internal cone-of-influence (COI) model
#   -d miter_opt : top-level for equivalence check
#   -work work   : library with all compiled modules
# -------------------------------------------------------
formal compile -d miter_opt -work work

# -------------------------------------------------------
# Step 3: Run equivalence check
# formal verify: runs SAT on the miter assertion
#   -effort high : maximum solver effort
#   (no -bounded needed for purely combinational designs;
#    SAT exhaustively covers all 2^3 = 8 input combinations)
#
# SAT RESULT INTERPRETATION (Equivalence Check):
#   SATISFIABLE (FAILED)   → SAT solver found an input where
#                            F_orig ≠ F_opt → NOT equivalent
#                            Counterexample (A,B,C values) printed
#   UNSATISFIABLE (PROVEN) → No input exists that makes them differ
#                            → Circuits are FUNCTIONALLY EQUIVALENT
# -------------------------------------------------------
formal verify -effort high

# -------------------------------------------------------
# Step 4: Report
# -------------------------------------------------------
report_property -verbose
