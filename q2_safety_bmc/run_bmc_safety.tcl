# =============================================================================
# Questa Formal - Bounded Model Checking (BMC) for Safety Property (Q2)
# Property: G ¬(count == 2'b11)
# Reasoning Engine: SAT Solver performing BMC unrolling
# =============================================================================

# -------------------------------------------------------
# Step 1: Create library
# vlib  - creates the ModelSim/Questa library folder
# vmap  - registers library name with the tool
# -------------------------------------------------------
vlib work
vmap work work

# -------------------------------------------------------
# Step 2: Compile the SystemVerilog source
# vlog  - Verilog/SystemVerilog compiler
#   -sv          : enable SystemVerilog features (assert, property)
#   -work work   : target library
# -------------------------------------------------------
vlog -sv -work work counter_safety.sv

# -------------------------------------------------------
# Step 3: Formal compile (elaboration)
# formal compile - reads the library, elaborates hierarchy,
#                  builds the internal formal model (AIG/CNF)
#   -d counter   : top-level design
#   -work work   : compiled library
# -------------------------------------------------------
formal compile -d counter -work work

# -------------------------------------------------------
# Step 4: Run BMC
# formal verify  - launches the verification engine
#   -bounded     : use BMC mode (SAT-based unrolling)
#   -depth <k>   : maximum unrolling depth (number of clock cycles)
#                  Here k=10 means we check 10 clock steps
#
# BMC SAT Formula for each step i (0..k):
#   I(s0) ∧ [∧_{i=0}^{k-1} T(si, s_{i+1})] ∧ ¬P(sk)
#   where I = initial state predicate,
#         T = transition relation (counter logic),
#         P = property (count ≠ 11)
#
# SAT RESULT INTERPRETATION:
#   SATISFIABLE   → Counterexample found: property is VIOLATED
#                   Tool shows a waveform trace reaching count==11
#   UNSATISFIABLE → Property HOLDS for all paths up to depth k
# -------------------------------------------------------
formal verify -bounded -depth 10

# -------------------------------------------------------
# Step 5: Report
# report_property - prints each assert with PROVEN / FAILED status
# -------------------------------------------------------
report_property -verbose

# -------------------------------------------------------
# Step 6: (Optional) Increase depth for stronger assurance
# If UNSAT up to 10, try deeper to increase confidence
# -------------------------------------------------------
# formal verify -bounded -depth 20
