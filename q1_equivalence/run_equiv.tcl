# =============================================================================
# Questa Formal - Equivalence Checking Script (Q1)
# Tool: Questa Formal Verification (front-end: Questa / back-end: Questa Formal)
# Reasoning Engine: SAT Solver (MiniSAT / Glucose inside Questa Formal)
# =============================================================================

# -------------------------------------------------------
# Step 1: Create and map the working library
# vlib  - creates a new simulation/formal library directory
# vmap  - maps the logical library name to the directory
# -------------------------------------------------------
vlib work
vmap work work

# -------------------------------------------------------
# Step 2: Compile RTL sources
# vlog  - compiles Verilog/SystemVerilog source files
#         -sv flag enables SystemVerilog parsing
#         -work specifies the target library
# -------------------------------------------------------
vlog -sv -work work ref.v
vlog -sv -work work impl.v
vlog -sv -work work miter.sv

# -------------------------------------------------------
# Step 3: Launch Questa Formal engine
# qformal - invokes Questa Formal Verification tool
#   -d <top>     : specifies the top-level design unit
#   -work <lib>  : points to compiled library
#   -init        : initialises the formal database
# -------------------------------------------------------
qformal -d miter -work work -init

# -------------------------------------------------------
# Step 4: Set verification mode to property checking
# formal compile - elaborates design and prepares formal DB
#   -d <top>     : top-level module
#   -work <lib>  : compiled library
# -------------------------------------------------------
formal compile -d miter -work work

# -------------------------------------------------------
# Step 5: Run formal verification
# formal verify  - runs the SAT/BDD engine on all asserts
#   -init        : initial state constraints (default: free)
#   -effort high : maximum proof effort
# -------------------------------------------------------
formal verify -init -effort high

# -------------------------------------------------------
# Step 6: View results
# The tool reports each assertion as:
#   PROVEN  -> circuits are equivalent (SAT returned UNSAT
#              for the miter, i.e. no differing output exists)
#   FAILED  -> counterexample found (SAT returned SAT,
#              meaning a differing input sequence exists)
# -------------------------------------------------------
report_property -verbose
