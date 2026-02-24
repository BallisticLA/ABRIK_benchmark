%{
Master plotting script - generates all ABRIK benchmark figures.

Uses the new unified CSV format (algorithm, b_sz, num_matmuls, p,
target_rank, error, duration_us) and the three new plotting scripts:
  - abrik_convergence_profile  (Option A: scatter overlay)
  - abrik_pareto_frontier      (Option B: Pareto time-vs-accuracy)
  - abrik_precision_vs_speedup_v2 (Option C: 2x3 per-algorithm grid)

Usage:
  run('/home/mymel/data/ABRIK_benchmark/plotting/plot_all.m')
%}

script_dir  = fileparts(mfilename('fullpath'));
repo_root   = fileparts(script_dir);            % one level above plotting/
results_dir = fullfile(repo_root, 'results');

%% ---- Dense: Mat 1 (10000x10000) ----
mat1 = fullfile(results_dir, '20260218_170422_ABRIK_speed_comparisons.csv');

figure('Name', 'Mat 1 — Convergence Profile');
abrik_convergence_profile(mat1);

figure('Name', 'Mat 1 — Pareto Frontier');
abrik_pareto_frontier(mat1);

figure('Name', 'Mat 1 — Per-Algorithm Grid');
abrik_precision_vs_speedup_v2(mat1);

%% ---- Dense: Mat 6 (10000x10000) ----
mat6 = fullfile(results_dir, '20260218_174414_ABRIK_speed_comparisons.csv');

figure('Name', 'Mat 6 — Convergence Profile');
abrik_convergence_profile(mat6);

figure('Name', 'Mat 6 — Pareto Frontier');
abrik_pareto_frontier(mat6);

figure('Name', 'Mat 6 — Per-Algorithm Grid');
abrik_precision_vs_speedup_v2(mat6);

%% ---- Sparse: CurlCurl_1 (ratio 0.5, 113k x 113k) ----
sparse_05 = fullfile(results_dir, '20260218_204624_ABRIK_speed_comparisons_sparse.csv');

figure('Name', 'CurlCurl_1 r=0.5 — Convergence Profile');
abrik_convergence_profile(sparse_05);

figure('Name', 'CurlCurl_1 r=0.5 — Pareto Frontier');
abrik_pareto_frontier(sparse_05);

figure('Name', 'CurlCurl_1 r=0.5 — Per-Algorithm Grid');
abrik_precision_vs_speedup_v2(sparse_05);

%% ---- Sparse: CurlCurl_1 (ratio 1.0, 226k x 226k) ----
sparse_10 = fullfile(results_dir, '20260218_211427_ABRIK_speed_comparisons_sparse.csv');

figure('Name', 'CurlCurl_1 r=1.0 — Convergence Profile');
abrik_convergence_profile(sparse_10);

figure('Name', 'CurlCurl_1 r=1.0 — Pareto Frontier');
abrik_pareto_frontier(sparse_10);

figure('Name', 'CurlCurl_1 r=1.0 — Per-Algorithm Grid');
abrik_precision_vs_speedup_v2(sparse_10);
