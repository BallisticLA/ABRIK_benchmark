%{
Master plotting script - generates all ABRIK benchmark figures.

Uses the new unified CSV format (algorithm, b_sz, num_matmuls, p,
target_rank, error, duration_us) and the three new plotting scripts:
  - abrik_convergence_profile  (Option A: scatter overlay)
  - abrik_pareto_frontier      (Option B: Pareto time-vs-accuracy)
  - abrik_precision_vs_speedup_v2 (Option C: 2x3 per-algorithm grid)

Each CSV is parsed once; pre-parsed (T, meta) are passed to all plots.

Usage:
  run('/home/mymel/data/ABRIK_benchmark/plotting/plot_all.m')
%}

script_dir  = fileparts(mfilename('fullpath'));
repo_root   = fileparts(script_dir);            % one level above plotting/
results_dir = fullfile(repo_root, 'results');

%% ---- Helper: parse once, plot three ways ----
csv_files = {
    fullfile(results_dir, '20260218_170422_ABRIK_speed_comparisons.csv'),       'Mat 1 (10k)'
    fullfile(results_dir, '20260218_174414_ABRIK_speed_comparisons.csv'),       'Mat 6 (10k)'
    fullfile(results_dir, '20260218_204624_ABRIK_speed_comparisons_sparse.csv'),'CurlCurl_1 r=0.5'
    fullfile(results_dir, '20260218_211427_ABRIK_speed_comparisons_sparse.csv'),'CurlCurl_1 r=1.0'
};

for k = 1:size(csv_files, 1)
    [T, meta] = parse_abrik_csv(csv_files{k, 1});
    label = csv_files{k, 2};

    figure('Name', [label ' — Convergence Profile']);
    abrik_convergence_profile(T, meta);

    figure('Name', [label ' — Pareto Frontier']);
    abrik_pareto_frontier(T, meta);

    figure('Name', [label ' — Per-Algorithm Grid'], 'Position', [100 100 1400 700]);
    abrik_precision_vs_speedup_v2(T, meta);
end
