#!/bin/bash
#
# Full dense benchmark suite for ABRIK speed comparisons.
#
# Runs all 6 test matrices (2000x2000, full rank) through:
#   - ABRIK: b_sz = {4, 8, 16, 32} x matmuls = {2, 4, 8, 16, 32}  (20 configs)
#   - RSVD:  p = {0, 1, 2, 4, 8, 16}                                (6 configs)
#   - SVDS:  nev = target_rank                                       (1 config)
#   - GESDD: single reference run                                    (1 config)
#   x 3 runs per config = 82 benchmark invocations per matrix
#
# Total: 6 matrices x 82 = 492 runs (~10-20 min on 2000x2000)
#
# Usage:
#   ./run_dense_benchmarks.sh                    # run 2000x2000 suite
#   ./run_dense_benchmarks.sh --large            # run 10000x10000 suite (mat1, mat6 only)
#   ./run_dense_benchmarks.sh --quick            # quick validation (1 run, fewer params)
#
# Output CSVs go to: /home/mymel/data/ABRIK/results/
#

set -euo pipefail

# ---- Paths ----
BENCHMARK_BIN="/home/mymel/RandNLA/RandNLA-project/build/benchmark-build/ABRIK_speed_comparisons"
OUTPUT_DIR="/home/mymel/data/ABRIK/results"
SMALL_MATRIX_DIR="/home/mymel/data/ABRIK/input_matrices/2000x2000_rank_2000"
LARGE_MATRIX_DIR="/home/mymel/data/ABRIK/input_matrices"

# ---- Parameters ----
PRECISION="double"
TARGET_RANK=10

# ABRIK parameters
BLOCK_SIZES=(4 8 16 32)
MATMUL_COUNTS=(2 4 8 16 32)
NUM_BLOCK_SIZES=${#BLOCK_SIZES[@]}
NUM_MATMUL_SIZES=${#MATMUL_COUNTS[@]}

# RSVD power iteration values
P_VALUES=(0 1 2 4 8 16)
NUM_P_VALUES=${#P_VALUES[@]}

# Benchmark settings
NUM_RUNS=3
RUN_GESDD=1   # 1 = include GESDD reference

# ---- Parse arguments ----
MODE="small"
if [[ "${1:-}" == "--large" ]]; then
    MODE="large"
elif [[ "${1:-}" == "--quick" ]]; then
    MODE="quick"
fi

# Quick mode: fewer parameters, single run
if [[ "$MODE" == "quick" ]]; then
    BLOCK_SIZES=(8 16)
    MATMUL_COUNTS=(4 8 16)
    NUM_BLOCK_SIZES=${#BLOCK_SIZES[@]}
    NUM_MATMUL_SIZES=${#MATMUL_COUNTS[@]}
    P_VALUES=(1 2 4 8)
    NUM_P_VALUES=${#P_VALUES[@]}
    NUM_RUNS=1
fi

# ---- Select matrices ----
if [[ "$MODE" == "large" ]]; then
    M=10000
    N=10000
    MATRICES=(
        "${LARGE_MATRIX_DIR}/ABRIK_test_mat1.txt"
        "${LARGE_MATRIX_DIR}/ABRIK_test_mat6.txt"
    )
    MATRIX_NAMES=("mat1_10k" "mat6_10k")
else
    M=2000
    N=2000
    MATRICES=(
        "${SMALL_MATRIX_DIR}/ABRIK_test_mat1.txt"
        "${SMALL_MATRIX_DIR}/ABRIK_test_mat2.txt"
        "${SMALL_MATRIX_DIR}/ABRIK_test_mat3.txt"
        "${SMALL_MATRIX_DIR}/ABRIK_test_mat4.txt"
        "${SMALL_MATRIX_DIR}/ABRIK_test_mat5.txt"
        "${SMALL_MATRIX_DIR}/ABRIK_test_mat6.txt"
    )
    MATRIX_NAMES=("mat1" "mat2" "mat3" "mat4" "mat5" "mat6")
fi

# ---- Verify prerequisites ----
if [[ ! -x "$BENCHMARK_BIN" ]]; then
    echo "ERROR: benchmark binary not found at $BENCHMARK_BIN"
    echo "Build it with: cd /home/mymel/RandNLA/RandNLA-project/build/benchmark-build && cmake --build . --target ABRIK_speed_comparisons -j\$(nproc)"
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

# ---- Print plan ----
echo "=========================================="
echo " ABRIK Dense Benchmark Suite"
echo "=========================================="
echo "Mode:           $MODE"
echo "Precision:      $PRECISION"
echo "Matrix size:    ${M} x ${N}"
echo "Target rank:    $TARGET_RANK"
echo "Num runs:       $NUM_RUNS"
echo "ABRIK configs:  ${NUM_BLOCK_SIZES} block sizes x ${NUM_MATMUL_SIZES} matmul counts = $((NUM_BLOCK_SIZES * NUM_MATMUL_SIZES))"
echo "  block_sizes:  ${BLOCK_SIZES[*]}"
echo "  matmul_counts: ${MATMUL_COUNTS[*]}"
echo "RSVD configs:   ${NUM_P_VALUES} p values"
echo "  p_values:     ${P_VALUES[*]}"
echo "SVDS:           nev = $TARGET_RANK"
echo "GESDD:          $([ $RUN_GESDD -eq 1 ] && echo 'yes' || echo 'no')"
echo "Matrices:       ${#MATRICES[@]}"
for i in "${!MATRICES[@]}"; do
    echo "  [${MATRIX_NAMES[$i]}] ${MATRICES[$i]}"
done
echo "Output dir:     $OUTPUT_DIR"
echo ""

TOTAL_CONFIGS=$(( (NUM_BLOCK_SIZES * NUM_MATMUL_SIZES + NUM_P_VALUES) * NUM_RUNS + NUM_RUNS + RUN_GESDD ))
echo "Total runs per matrix: $TOTAL_CONFIGS"
echo "Total runs overall:    $(( TOTAL_CONFIGS * ${#MATRICES[@]} ))"
echo "=========================================="
echo ""

# ---- Run benchmarks ----
START_TIME=$(date +%s)

for i in "${!MATRICES[@]}"; do
    MATRIX="${MATRICES[$i]}"
    NAME="${MATRIX_NAMES[$i]}"

    if [[ ! -f "$MATRIX" ]]; then
        echo "WARNING: Matrix file not found, skipping: $MATRIX"
        continue
    fi

    echo ">>> [$((i+1))/${#MATRICES[@]}] Running ${NAME} (${MATRIX})..."
    MATRIX_START=$(date +%s)

    "$BENCHMARK_BIN" \
        "$PRECISION" "$OUTPUT_DIR" "$MATRIX" \
        "$NUM_RUNS" "$M" "$N" "$TARGET_RANK" "$RUN_GESDD" \
        "$NUM_BLOCK_SIZES" "$NUM_MATMUL_SIZES" "$NUM_P_VALUES" \
        "${BLOCK_SIZES[@]}" "${MATMUL_COUNTS[@]}" "${P_VALUES[@]}"

    MATRIX_END=$(date +%s)
    MATRIX_ELAPSED=$((MATRIX_END - MATRIX_START))
    echo "    ${NAME} completed in ${MATRIX_ELAPSED}s"
    echo ""
done

END_TIME=$(date +%s)
TOTAL_ELAPSED=$((END_TIME - START_TIME))
echo "=========================================="
echo " All benchmarks complete!"
echo " Total time: ${TOTAL_ELAPSED}s ($(( TOTAL_ELAPSED / 60 ))m $(( TOTAL_ELAPSED % 60 ))s)"
echo " Results in: $OUTPUT_DIR"
echo "=========================================="
