#!/bin/bash
# ABRIK Benchmark Result Validator
# Validates correctness properties of benchmark CSV results.

RESULTS_DIR="/home/mymel/data/ABRIK/results"

# The 6 full dense run files (3500-3800 bytes each, 96 lines)
DENSE_FILES=(
    "$RESULTS_DIR/20260218_150535_ABRIK_speed_comparisons.csv"
    "$RESULTS_DIR/20260218_150746_ABRIK_speed_comparisons.csv"
    "$RESULTS_DIR/20260218_150936_ABRIK_speed_comparisons.csv"
    "$RESULTS_DIR/20260218_151107_ABRIK_speed_comparisons.csv"
    "$RESULTS_DIR/20260218_151242_ABRIK_speed_comparisons.csv"
    "$RESULTS_DIR/20260218_151417_ABRIK_speed_comparisons.csv"
)

# Sparse files — two formats exist
SPARSE_FILES_OLD=(
    "$RESULTS_DIR/0_5_ABRIK_speed_comparisons_sparse.csv"
    "$RESULTS_DIR/1_0_ABRIK_speed_comparisons_sparse.csv"
)
SPARSE_FILES_NEW=(
    "$RESULTS_DIR/20260218_150536_ABRIK_speed_comparisons_sparse.csv"
    "$RESULTS_DIR/20260218_150609_ABRIK_speed_comparisons_sparse.csv"
)

TOTAL_PASS=0
TOTAL_FAIL=0

pass_check() {
    echo "  PASS: $1"
    TOTAL_PASS=$((TOTAL_PASS + 1))
}

fail_check() {
    echo "  FAIL: $1"
    TOTAL_FAIL=$((TOTAL_FAIL + 1))
}

# Returns "yes" if a <= b (floats), "no" otherwise
float_le() {
    awk "BEGIN { if ($1 <= $2) print \"yes\"; else print \"no\" }"
}

echo "========================================================================"
echo "ABRIK Benchmark Result Validation"
echo "========================================================================"
echo ""

###############################################################################
# CHECK 1: RSVD monotonicity — error should decrease as p increases
###############################################################################
echo "--- CHECK 1: RSVD error monotonicity (error decreases as p increases) ---"
echo ""

for f in "${DENSE_FILES[@]}"; do
    fname=$(basename "$f")
    echo "  File: $fname"

    rsvd_data=$(awk -F', ' '/^RSVD/ { print $4, $6 }' "$f" | sort -u -k1,1n)

    prev_err=""
    prev_p=""
    monotonic=true

    while read -r p err; do
        printf "    p=%-3s  error=%s\n" "$p" "$err"
        if [ -n "$prev_err" ]; then
            result=$(float_le "$err" "$prev_err")
            if [ "$result" != "yes" ]; then
                echo "    *** Non-monotonic: p=$p error=$err > previous p=$prev_p error=$prev_err"
                monotonic=false
            fi
        fi
        prev_err="$err"
        prev_p="$p"
    done <<< "$rsvd_data"

    if $monotonic; then
        pass_check "RSVD monotonicity in $fname"
    else
        fail_check "RSVD monotonicity in $fname"
    fi
    echo ""
done

###############################################################################
# CHECK 2: SVDS accuracy — should be ~1e-11 to 1e-14
###############################################################################
echo "--- CHECK 2: SVDS accuracy (~1e-11 to 1e-14) ---"
echo ""

for f in "${DENSE_FILES[@]}"; do
    fname=$(basename "$f")
    svds_err=$(awk -F', ' '/^SVDS/ { print $6 }' "$f" | sort -u)
    echo "  File: $fname  SVDS error: $svds_err"

    ok=$(awk "BEGIN {
        e = $svds_err + 0;
        if (e < 1e-10 && e > 1e-16) print \"yes\"; else print \"no\"
    }")
    if [ "$ok" = "yes" ]; then
        pass_check "SVDS accuracy in $fname"
    else
        fail_check "SVDS accuracy in $fname (expected 1e-16 to 1e-10, got $svds_err)"
    fi
done
echo ""

###############################################################################
# CHECK 3: ABRIK convergence for b_sz=16 — error decreases as mm increases
###############################################################################
echo "--- CHECK 3: ABRIK convergence (b_sz=16, error decreases as mm increases) ---"
echo ""

for f in "${DENSE_FILES[@]}"; do
    fname=$(basename "$f")
    echo "  File: $fname"

    abrik_bsz16=$(awk -F', ' '/^ABRIK/ { gsub(/ /,"",$2); if ($2+0 == 16) print $3+0, $6 }' "$f" | sort -u -k1,1n)

    prev_err=""
    prev_mm=""
    monotonic=true

    while read -r mm err; do
        printf "    mm=%-3s  error=%s\n" "$mm" "$err"
        if [ -n "$prev_err" ]; then
            result=$(float_le "$err" "$prev_err")
            if [ "$result" != "yes" ]; then
                echo "    *** Non-monotonic: mm=$mm error=$err > previous mm=$prev_mm error=$prev_err"
                monotonic=false
            fi
        fi
        prev_err="$err"
        prev_mm="$mm"
    done <<< "$abrik_bsz16"

    if $monotonic; then
        pass_check "ABRIK convergence (b_sz=16) in $fname"
    else
        fail_check "ABRIK convergence (b_sz=16) in $fname"
    fi
    echo ""
done

###############################################################################
# CHECK 4: No NaN or negative errors in any dense file
###############################################################################
echo "--- CHECK 4: No NaN or negative errors (dense files) ---"
echo ""

for f in "${DENSE_FILES[@]}"; do
    fname=$(basename "$f")

    nan_count=$(awk -F', ' '!/^#/ && !/^algorithm/ && NF>=6 { if ($6 ~ /[Nn][Aa][Nn]/) print }' "$f" | wc -l)
    neg_count=$(awk -F', ' '!/^#/ && !/^algorithm/ && NF>=6 { e=$6+0; if (e < 0) print }' "$f" | wc -l)

    if [ "$nan_count" -eq 0 ] && [ "$neg_count" -eq 0 ]; then
        pass_check "No NaN/negative errors in $fname"
    else
        fail_check "Found NaN($nan_count) or negative($neg_count) errors in $fname"
    fi
done
echo ""

###############################################################################
# CHECK 5: GESDD reference — error near machine precision (~1e-15)
###############################################################################
echo "--- CHECK 5: GESDD error near machine precision (~1e-15) ---"
echo ""

for f in "${DENSE_FILES[@]}"; do
    fname=$(basename "$f")
    gesdd_err=$(awk -F', ' '/^GESDD/ { print $6 }' "$f" | sort -u)
    echo "  File: $fname  GESDD error: $gesdd_err"

    ok=$(awk "BEGIN {
        e = $gesdd_err + 0;
        if (e < 1e-13 && e > 0) print \"yes\"; else print \"no\"
    }")
    if [ "$ok" = "yes" ]; then
        pass_check "GESDD near machine precision in $fname"
    else
        fail_check "GESDD near machine precision in $fname (got $gesdd_err)"
    fi
done
echo ""

###############################################################################
# CHECK 6: Sparse — SVDS accuracy
###############################################################################
echo "--- CHECK 6: Sparse SVDS accuracy ---"
echo ""

# Old-format sparse files: err_SVDS is column 6
for f in "${SPARSE_FILES_OLD[@]}"; do
    fname=$(basename "$f")
    svds_errs=$(awk -F', ' '!/^#/ && !/^b_sz/ && NF>=7 { print $6 }' "$f" | sort -u)
    echo "  File: $fname  SVDS errors:"
    while read -r err; do
        printf "    %s\n" "$err"
    done <<< "$svds_errs"

    all_ok=true
    while read -r err; do
        ok=$(awk "BEGIN {
            e = $err + 0;
            if (e < 1e-10 && e > 0) print \"yes\"; else print \"no\"
        }")
        if [ "$ok" != "yes" ]; then
            all_ok=false
        fi
    done <<< "$svds_errs"

    if $all_ok; then
        pass_check "Sparse SVDS accuracy in $fname"
    else
        fail_check "Sparse SVDS accuracy in $fname"
    fi
done

# New-format sparse files: SVDS rows
for f in "${SPARSE_FILES_NEW[@]}"; do
    fname=$(basename "$f")
    svds_errs=$(awk -F', ' '/^SVDS/ { print $6 }' "$f" | sort -u)

    if [ -z "$svds_errs" ]; then
        echo "  File: $fname  No SVDS rows found — checking if SVDS data embedded in ABRIK rows"
        # These files don't have separate SVDS rows; skip
        echo "    (Skipping — file uses old-sparse-like format with no separate SVDS algorithm rows)"
    else
        echo "  File: $fname  SVDS errors:"
        while read -r err; do
            printf "    %s\n" "$err"
        done <<< "$svds_errs"

        all_ok=true
        while read -r err; do
            ok=$(awk "BEGIN {
                e = $err + 0;
                if (e < 1e-10 && e > 0) print \"yes\"; else print \"no\"
            }")
            if [ "$ok" != "yes" ]; then
                all_ok=false
            fi
        done <<< "$svds_errs"

        if $all_ok; then
            pass_check "Sparse SVDS accuracy in $fname"
        else
            fail_check "Sparse SVDS accuracy in $fname"
        fi
    fi
done
echo ""

###############################################################################
# CHECK 7: Sparse — ABRIK convergence for b_sz=16
###############################################################################
echo "--- CHECK 7: Sparse ABRIK convergence (b_sz=16, error decreases as mm increases) ---"
echo ""

# Old-format sparse files
for f in "${SPARSE_FILES_OLD[@]}"; do
    fname=$(basename "$f")
    echo "  File: $fname"

    abrik_bsz16=$(awk -F', ' '!/^#/ && !/^b_sz/ && NF>=7 { gsub(/ /,"",$1); if ($1+0 == 16) print $2+0, $4 }' "$f" | sort -u -k1,1n)

    if [ -z "$abrik_bsz16" ]; then
        echo "    No b_sz=16 rows found, skipping."
        echo ""
        continue
    fi

    prev_err=""
    prev_mm=""
    monotonic=true

    while read -r mm err; do
        printf "    mm=%-3s  error=%s\n" "$mm" "$err"
        if [ -n "$prev_err" ]; then
            result=$(float_le "$err" "$prev_err")
            if [ "$result" != "yes" ]; then
                echo "    *** Non-monotonic: mm=$mm error=$err > previous mm=$prev_mm error=$prev_err"
                monotonic=false
            fi
        fi
        prev_err="$err"
        prev_mm="$mm"
    done <<< "$abrik_bsz16"

    if $monotonic; then
        pass_check "Sparse ABRIK convergence (b_sz=16) in $fname"
    else
        fail_check "Sparse ABRIK convergence (b_sz=16) in $fname"
    fi
    echo ""
done

# New-format sparse files
for f in "${SPARSE_FILES_NEW[@]}"; do
    fname=$(basename "$f")
    echo "  File: $fname"

    abrik_bsz16=$(awk -F', ' '/^ABRIK/ { gsub(/ /,"",$2); if ($2+0 == 16) print $3+0, $6 }' "$f" | sort -u -k1,1n)

    if [ -z "$abrik_bsz16" ]; then
        echo "    No ABRIK b_sz=16 rows found, skipping."
        echo ""
        continue
    fi

    prev_err=""
    prev_mm=""
    monotonic=true

    while read -r mm err; do
        printf "    mm=%-3s  error=%s\n" "$mm" "$err"
        if [ -n "$prev_err" ]; then
            result=$(float_le "$err" "$prev_err")
            if [ "$result" != "yes" ]; then
                echo "    *** Non-monotonic: mm=$mm error=$err > previous mm=$prev_mm error=$prev_err"
                monotonic=false
            fi
        fi
        prev_err="$err"
        prev_mm="$mm"
    done <<< "$abrik_bsz16"

    if $monotonic; then
        pass_check "Sparse ABRIK convergence (b_sz=16) in $fname"
    else
        fail_check "Sparse ABRIK convergence (b_sz=16) in $fname"
    fi
    echo ""
done

# Bonus: NaN/negative check on sparse files
echo "--- BONUS: No NaN or negative errors (sparse files) ---"
echo ""

for f in "${SPARSE_FILES_OLD[@]}" "${SPARSE_FILES_NEW[@]}"; do
    fname=$(basename "$f")
    nan_count=$(awk -F', ' '!/^#/ && !/^b_sz/ && !/^algorithm/ { for(i=1;i<=NF;i++) if ($i ~ /[Nn][Aa][Nn]/) print }' "$f" | wc -l)
    neg_err_count=0

    if [[ "$fname" == 0_5_* ]] || [[ "$fname" == 1_0_* ]]; then
        neg_err_count=$(awk -F', ' '!/^#/ && !/^b_sz/ && NF>=7 { if ($4+0 < 0 || $6+0 < 0) print }' "$f" | wc -l)
    else
        neg_err_count=$(awk -F', ' '!/^#/ && !/^algorithm/ && NF>=6 { if ($6+0 < 0) print }' "$f" | wc -l)
    fi

    if [ "$nan_count" -eq 0 ] && [ "$neg_err_count" -eq 0 ]; then
        pass_check "No NaN/negative errors in sparse $fname"
    else
        fail_check "Found NaN($nan_count) or negative($neg_err_count) errors in sparse $fname"
    fi
done
echo ""

###############################################################################
# SUMMARY
###############################################################################
echo "========================================================================"
echo "VALIDATION SUMMARY"
echo "========================================================================"
echo "  Total PASS: $TOTAL_PASS"
echo "  Total FAIL: $TOTAL_FAIL"
echo ""
if [ "$TOTAL_FAIL" -eq 0 ]; then
    echo "  *** ALL CHECKS PASSED ***"
else
    echo "  *** $TOTAL_FAIL CHECK(S) FAILED ***"
fi
echo "========================================================================"
