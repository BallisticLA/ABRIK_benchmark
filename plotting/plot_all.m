%{
Master plotting script - generates all ABRIK benchmark figures.

Usage (from MATLAB, with working directory set to the ABRIK data root):
  run('/home/mymel/data/ABRIK_benchmark/plotting/plot_all.m')

Each figure is created in a new window.  Paths are resolved relative
to the script location (no need to cd first).
%}

script_dir  = fileparts(mfilename('fullpath'));
repo_root   = fileparts(script_dir);            % one level above plotting/
results_dir = fullfile(repo_root, 'results');

%% ---- Dense speed comparisons ----
figure('Name', 'Dense - Mat 1');
abrik_precision_vs_speedup(fullfile(results_dir, 'one_ABRIK_speed_comparisons.csv'));

figure('Name', 'Dense - Mat 6');
abrik_precision_vs_speedup(fullfile(results_dir, 'six_ABRIK_speed_comparisons.csv'));

%% ---- Sparse speed comparisons ----
figure('Name', 'Sparse - CurlCurl_1 (ratio 0.5)');
abrik_precision_vs_speedup_sparse(fullfile(results_dir, '0_5_ABRIK_speed_comparisons_sparse.csv'));

figure('Name', 'Sparse - CurlCurl_1 (ratio 1.0)');
abrik_precision_vs_speedup_sparse(fullfile(results_dir, '1_0_ABRIK_speed_comparisons_sparse.csv'));
