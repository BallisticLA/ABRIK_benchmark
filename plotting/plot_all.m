
% Resolve paths relative to this script's location (works on any machine)
script_dir  = fileparts(mfilename('fullpath'));
results_dir = fullfile(fileparts(script_dir), 'results');

%% === Figure 1: Performance / Accuracy (tabbed) ===
fig1 = figure('Name', 'ABRIK Performance', 'Position', [50 50 1500 800]);
tg1 = uitabgroup(fig1);

% Tab 1: Dense Mat 1 (10k)
tab = uitab(tg1, 'Title', 'Mat 1 (dense, 10k)');
plot_abrik_in_tab(tab, results_dir, '20260324_132117_ABRIK_speed_comparisons.csv');

% Tab 2: Dense Mat 6 (10k)
tab = uitab(tg1, 'Title', 'Mat 6 (dense, 10k)');
plot_abrik_in_tab(tab, results_dir, '20260324_135933_ABRIK_speed_comparisons.csv');

% Tab 3: Sparse CurlCurl_1 half
tab = uitab(tg1, 'Title', 'CurlCurl\_1 (113k, r=0.5)');
plot_abrik_in_tab(tab, results_dir, '20260324_154147_ABRIK_speed_comparisons_sparse.csv');

% Tab 4: Sparse CurlCurl_1 full
tab = uitab(tg1, 'Title', 'CurlCurl\_1 (226k, r=1.0)');
plot_abrik_in_tab(tab, results_dir, '20260324_154453_ABRIK_speed_comparisons_sparse.csv');

%% === Figure 2: Runtime Breakdowns (tabbed) ===
fig2 = figure('Name', 'ABRIK Runtime Breakdowns', 'Position', [100 100 1400 600]);
tg2 = uitabgroup(fig2);

% Tab 1: Dense breakdowns (Mat 1 + Mat 6)
tab = uitab(tg2, 'Title', 'Dense');
tl = tiledlayout(tab, 1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
nexttile(tl);
abrik_runtime_breakdown(fullfile(results_dir, '20260324_145040_ABRIK_runtime_breakdown.csv'), 'BlockSize', 16, 'ShowLegend', false);
nexttile(tl);
abrik_runtime_breakdown(fullfile(results_dir, '20260324_145314_ABRIK_runtime_breakdown.csv'), 'BlockSize', 16);

% Tab 2: Sparse breakdowns (CurlCurl_1 half + full)
tab = uitab(tg2, 'Title', 'Sparse');
tl = tiledlayout(tab, 1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
nexttile(tl);
abrik_runtime_breakdown(fullfile(results_dir, '20260324_155051_ABRIK_runtime_breakdown_sparse.csv'), 'BlockSize', 4, 'ShowLegend', false);
nexttile(tl);
abrik_runtime_breakdown(fullfile(results_dir, '20260324_155310_ABRIK_runtime_breakdown_sparse.csv'), 'BlockSize', 4);

%% -----------------------------------------------------------------------
function plot_abrik_in_tab(tab, results_dir, csv_name)
    csv_path = fullfile(results_dir, csv_name);
    [T, meta] = parse_abrik_csv(csv_path);
    abrik_precision_vs_speedup_v2(T, meta, 'Parent', tab);
end
