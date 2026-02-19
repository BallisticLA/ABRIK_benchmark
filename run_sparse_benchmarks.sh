#!/bin/bash
#
# Full sparse benchmark suite for ABRIK speed comparisons.
#
# Runs sparse matrices (CurlCurl_0, CurlCurl_1) through:
#   - ABRIK: b_sz = {4, 8, 16, 32} x matmuls = {2, 4, 8, 16, 32}  (20 configs)
#   - SVDS:  nev = target_rank                                       (1 config)
#   x 3 runs per config = 63 benchmark invocations per matrix
#   (No RSVD in sparse benchmark)
#
# Usage:
#   ./run_sparse_benchmarks.sh                   # run both CurlCurl matrices
#   ./run_sparse_benchmarks.sh --quick           # quick validation (1 run, fewer params)
#
# Output CSVs go to: /home/mymel/data/ABRIK/results/
#

set -euo pipefail

# ---- Paths ----
BENCHMARK_BIN="/home/mymel/RandNLA/RandNLA-project/build/benchmark-build/ABRIK_speed_comparisons_sparse"
OUTPUT_DIR="/home/mymel/data/ABRIK/results"
MATRIX_DIR="/home/mymel/data/ABRIK/input_matrices"

# ---- Parameters ----
PRECISION="double"
TARGET_RANK=10

# ABRIK parameters
BLOCK_SIZES=(4 8 16 32)
MATMUL_COUNTS=(2 4 8 16 32)
NUM_BLOCK_SIZES=${#BLOCK_SIZES[@]}
NUM_MATMUL_SIZES=${#MATMUL_COUNTS[@]}

# Benchmark settings
NUM_RUNS=3
RUN_GESDD=0           # Skip GESDD for sparse (too expensive)
WRITE_MATRICES=0      # Don't write U,V,Sigma files
SUBMATRIX_DIM_RATIO=1.0  # Use full matrix

# ---- Parse arguments ----
MODE="full"
if [[ "${1:-}" == "--quick" ]]; then
    MODE="quick"
fi

# Quick mode: fewer parameters, single run
if [[ "$MODE" == "quick" ]]; then
    BLOCK_SIZES=(8 16)
    MATMUL_COUNTS=(4 8)
    NUM_BLOCK_SIZES=${#BLOCK_SIZES[@]}
    NUM_MATMUL_SIZES=${#MATMUL_COUNTS[@]}
    NUM_RUNS=1
fi

# ---- Select matrices ----
MATRICES=(
    "${MATRIX_DIR}/CurlCurl_0.mtx"
    "${MATRIX_DIR}/CurlCurl_1.mtx"
)
MATRIX_NAMES=("CurlCurl_0" "CurlCurl_1")

# ---- Verify prerequisites ----
if [[ ! -x "$BENCHMARK_BIN" ]]; then
    echo "ERROR: benchmark binary not found at $BENCHMARK_BIN"
    echo "Build it with: cd /home/mymel/RandNLA/RandNLA-project/build/benchmark-build && cmake --build . --target ABRIK_speed_comparisons_sparse -j\$(nproc)"
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

# ---- Print plan ----
echo "=========================================="
echo " ABRIK Sparse Benchmark Suite"
echo "=========================================="
echo "Mode:           $MODE"
echo "Precision:      $PRECISION"
echo "Target rank:    $TARGET_RANK"
echo "Num runs:       $NUM_RUNS"
echo "ABRIK configs:  ${NUM_BLOCK_SIZES} block sizes x ${NUM_MATMUL_SIZES} matmul counts = $((NUM_BLOCK_SIZES * NUM_MATMUL_SIZES))"
echo "  block_sizes:  ${BLOCK_SIZES[*]}"
echo "  matmul_counts: ${MATMUL_COUNTS[*]}"
echo "SVDS:           nev = $TARGET_RANK"
echo "Submatrix ratio: $SUBMATRIX_DIM_RATIO"
echo "Matrices:       ${#MATRICES[@]}"
for i in "${!MATRICES[@]}"; do
    echo "  [${MATRIX_NAMES[$i]}] ${MATRICES[$i]}"
done
echo "Output dir:     $OUTPUT_DIR"
echo ""

TOTAL_CONFIGS=$(( (NUM_BLOCK_SIZES * NUM_MATMUL_SIZES) * NUM_RUNS + NUM_RUNS ))
echo "Total runs per matrix: $TOTAL_CONFIGS"
echo "Total runs overall:    $(( TOTAL_CONFIGS * ${#MATRICES[@]} ))"
echo "=========================================="
echo ""

# ---- Run benchmarks ----
# Sparse CLI:
# <precision> <output_dir> <input> <num_runs> <target_rank> <run_gesdd>
# <write_matrices> <submatrix_dim_ratio> <num_block_sizes> <num_matmul_sizes>
# <block_sizes...> <matmul_sizes...>

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
        "$NUM_RUNS" "$TARGET_RANK" "$RUN_GESDD" \
        "$WRITE_MATRICES" "$SUBMATRIX_DIM_RATIO" \
        "$NUM_BLOCK_SIZES" "$NUM_MATMUL_SIZES" \
        "${BLOCK_SIZES[@]}" "${MATMUL_COUNTS[@]}"

    MATRIX_END=$(date +%s)
    MATRIX_ELAPSED=$((MATRIX_END - MATRIX_START))
    echo "    ${NAME} completed in ${MATRIX_ELAPSED}s"
    echo ""
done

END_TIME=$(date +%s)
TOTAL_ELAPSED=$((END_TIME - START_TIME))
echo "=========================================="
echo " All sparse benchmarks complete!"
echo " Total time: ${TOTAL_ELAPSED}s ($(( TOTAL_ELAPSED / 60 ))m $(( TOTAL_ELAPSED % 60 ))s)"
echo " Results in: $OUTPUT_DIR"
echo "=========================================="
