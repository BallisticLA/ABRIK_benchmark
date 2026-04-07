
% Resolve paths relative to this script's location (works on any machine)
script_dir  = fileparts(mfilename('fullpath'));
results_dir = fullfile(fileparts(script_dir), 'results');

%% === Figure 1: Performance / Accuracy (tabbed) ===
fig1 = figure('Name', 'ABRIK Performance', 'Position', [50 50 1500 800]);
tg1 = uitabgroup(fig1);

% Dense
tab = uitab(tg1, 'Title', 'Mat 1 (dense)');
plot_abrik_in_tab(tab, results_dir, '20260330_181308_ABRIK_speed_comparisons.csv');

tab = uitab(tg1, 'Title', 'Mat 6 (dense)');
plot_abrik_in_tab(tab, results_dir, '20260330_181955_ABRIK_speed_comparisons.csv');

% Sparse (ISAAC Apr 7, CurlCurl_1-4)
tab = uitab(tg1, 'Title', 'CurlCurl 226k');
plot_abrik_in_tab(tab, results_dir, '20260406_231506_ABRIK_speed_comparisons.csv');

tab = uitab(tg1, 'Title', 'CurlCurl 807k');
plot_abrik_in_tab(tab, results_dir, '20260406_231956_ABRIK_speed_comparisons.csv');

tab = uitab(tg1, 'Title', 'CurlCurl 1.2M');
plot_abrik_in_tab(tab, results_dir, '20260406_233250_ABRIK_speed_comparisons.csv');

tab = uitab(tg1, 'Title', 'CurlCurl 2.4M');
plot_abrik_in_tab(tab, results_dir, '20260406_235621_ABRIK_speed_comparisons.csv');

%% === Figure 2: Runtime Breakdowns (tabbed) ===
fig2 = figure('Name', 'ABRIK Runtime Breakdowns', 'Position', [100 100 1400 600]);
tg2 = uitabgroup(fig2);

% Dense breakdowns
tab = uitab(tg2, 'Title', 'Dense');
tl = tiledlayout(tab, 1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
nexttile(tl);
abrik_runtime_breakdown(fullfile(results_dir, '20260330_182920_ABRIK_runtime_breakdown.csv'), 'BlockSize', 16, 'ShowLegend', false);
nexttile(tl);
abrik_runtime_breakdown(fullfile(results_dir, '20260330_183055_ABRIK_runtime_breakdown.csv'), 'BlockSize', 16);
set(gca, 'YTickLabel', []); ylabel('');

% Sparse breakdowns (ISAAC Apr 7, CurlCurl_1-4)
tab = uitab(tg2, 'Title', 'Sparse (CurlCurl 1-4)');
tl = tiledlayout(tab, 2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
nexttile(tl);
abrik_runtime_breakdown(fullfile(results_dir, '20260407_132601_ABRIK_runtime_breakdown.csv'), 'BlockSize', 4, 'ShowLegend', false);
title('CurlCurl\_1 (226k)');
nexttile(tl);
abrik_runtime_breakdown(fullfile(results_dir, '20260407_132751_ABRIK_runtime_breakdown.csv'), 'BlockSize', 4);
set(gca, 'YTickLabel', []); ylabel(''); title('CurlCurl\_2 (807k)');
nexttile(tl);
abrik_runtime_breakdown(fullfile(results_dir, '20260407_133229_ABRIK_runtime_breakdown.csv'), 'BlockSize', 4, 'ShowLegend', false);
title('CurlCurl\_3 (1.2M)');
nexttile(tl);
abrik_runtime_breakdown(fullfile(results_dir, '20260407_133931_ABRIK_runtime_breakdown.csv'), 'BlockSize', 4);
set(gca, 'YTickLabel', []); ylabel(''); title('CurlCurl\_4 (2.4M)');

%% === Figure 3: Per-Triplet Accuracy Analysis (tabbed) ===
fig3 = figure('Name', 'ABRIK Per-Triplet Accuracy', 'Position', [150 150 1500 600]);
tg3 = uitabgroup(fig3);

tab = uitab(tg3, 'Title', 'Mat 1');
axes('Parent', tab);
abrik_accuracy_analysis(fullfile(results_dir, '20260401_103154_ABRIK_accuracy_analysis.csv'), 'CreateFigure', false);

tab = uitab(tg3, 'Title', 'Mat 6');
axes('Parent', tab);
abrik_accuracy_analysis(fullfile(results_dir, '20260401_103455_ABRIK_accuracy_analysis.csv'), 'CreateFigure', false);

%% -----------------------------------------------------------------------
function plot_abrik_in_tab(tab, results_dir, csv_name)
    csv_path = fullfile(results_dir, csv_name);
    [T, meta] = parse_abrik_csv(csv_path);
    abrik_precision_vs_speedup_v2(T, meta, 'Parent', tab);
end
