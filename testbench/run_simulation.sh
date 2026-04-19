#!/bin/bash
# ============================================================================
# run_simulation.sh
# Compile and simulate Croc SoC with the custom RD/WR testbench
# Run this INSIDE the IIC-OSIC-TOOLS Docker container
# ============================================================================

set -e

CROC_DIR="/fosic/designs/croc"
TB_DIR="${CROC_DIR}/../croc-soc-vlsi/testbench"
RESULTS_DIR="${CROC_DIR}/../croc-soc-vlsi/results/simulation"

echo "============================================"
echo " Croc SoC Simulation — Arpan Jain"
echo " BITS Pilani | 2025HT08066"
echo "============================================"

cd "$CROC_DIR"

echo "[1/3] Generating file list with Bender..."
bender script verilator -t verilator > /tmp/croc_flist.f

echo "[2/3] Compiling with Verilator..."
verilator --lint-only -sv \
  -f /tmp/croc_flist.f \
  --top-module croc_soc \
  2>&1 | tee "$RESULTS_DIR/verilator_lint.log"

echo "[3/3] Building simulation with testbench..."
verilator --binary -sv \
  -f /tmp/croc_flist.f \
  "$TB_DIR/croc_tb.sv" \
  --top-module croc_tb \
  --trace \
  -Mdir "$RESULTS_DIR/obj_dir" \
  2>&1 | tee "$RESULTS_DIR/verilator_build.log"

echo ""
echo "[RUN] Running simulation..."
"$RESULTS_DIR/obj_dir/Vcroc_tb" 2>&1 | tee "$RESULTS_DIR/sim_output.log"

echo ""
echo "Done! Results in: $RESULTS_DIR"
echo "  - verilator_lint.log   : lint/compile messages"
echo "  - verilator_build.log  : build messages"
echo "  - sim_output.log       : test results"
echo "  - croc_tb.vcd          : waveform dump"
