%{
Master plotting script - generates all ABRIK benchmark figures.

Usage (from MATLAB, with working directory set to the ABRIK data root):
  cd /home/mymel/data/ABRIK
  run('plotting/plot_all.m')

Each figure is created in a new window.  Paths assume the working
directory is /home/mymel/data/ABRIK/.
%}

results_dir = fullfile(pwd, 'results');

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
