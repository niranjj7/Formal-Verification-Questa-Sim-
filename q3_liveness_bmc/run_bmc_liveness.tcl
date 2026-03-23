# =============================================================================
# Questa Formal - BMC for Liveness Property (Q3)
# Property: GF(count == 2'b00)
# "Eventually count always returns to zero"
# =============================================================================

vlib work
vmap work work

# -------------------------------------------------------
# vlog: Compile the liveness-annotated counter
# -------------------------------------------------------
vlog -sv -work work counter_liveness.sv

# -------------------------------------------------------
# formal compile: Elaborate design, build formal model
# -------------------------------------------------------
formal compile -d counter -work work

# -------------------------------------------------------
# formal verify for liveness using BMC
# -bounded    : SAT-based bounded unrolling
# -depth 8    : check over 8 time steps (2-bit counter
#               cycles in 4 steps, so 8 is > 1 full cycle)
#
# For liveness GF(P):
#   BMC searches for a LASSO-shaped counterexample:
#   a finite prefix followed by a loop where P never holds.
#   If SAT solver finds such a loop → liveness VIOLATED.
#   If no loop found up to depth k → holds up to k steps.
#
# SAT RESULT INTERPRETATION (Liveness):
#   SATISFIABLE   → Found a loop with no visit to count==00
#                   Liveness property is VIOLATED
#   UNSATISFIABLE → No such loop exists up to bound k
#                   Liveness HOLDS (up to k steps)
# -------------------------------------------------------
formal verify -bounded -depth 8

# -------------------------------------------------------
# Also check the cover property (reachability witness)
# A covered cover property means 00 IS reachable —
# a witness trace is produced by the tool.
# -------------------------------------------------------
report_property -verbose
