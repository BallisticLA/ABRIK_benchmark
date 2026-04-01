
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

% Sparse with CQRRT
tab = uitab(tg1, 'Title', 'CurlCurl 113k (cqrrt)');
plot_abrik_in_tab(tab, results_dir, '20260330_183228_ABRIK_speed_comparisons.csv');

tab = uitab(tg1, 'Title', 'CurlCurl 226k (cqrrt)');
plot_abrik_in_tab(tab, results_dir, '20260330_183737_ABRIK_speed_comparisons.csv');

% Sparse with GEQRF (no cqrrt)
tab = uitab(tg1, 'Title', 'CurlCurl 113k (geqrf)');
plot_abrik_in_tab(tab, results_dir, '20260330_205706_ABRIK_speed_comparisons.csv');

tab = uitab(tg1, 'Title', 'CurlCurl 226k (geqrf)');
plot_abrik_in_tab(tab, results_dir, '20260330_210215_ABRIK_speed_comparisons.csv');

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

% Sparse breakdowns with CQRRT
tab = uitab(tg2, 'Title', 'Sparse (cqrrt)');
tl = tiledlayout(tab, 1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
nexttile(tl);
abrik_runtime_breakdown(fullfile(results_dir, '20260330_184756_ABRIK_runtime_breakdown.csv'), 'BlockSize', 4, 'ShowLegend', false);
nexttile(tl);
abrik_runtime_breakdown(fullfile(results_dir, '20260330_184947_ABRIK_runtime_breakdown.csv'), 'BlockSize', 4);
set(gca, 'YTickLabel', []); ylabel('');

% Sparse breakdowns with GEQRF (no cqrrt)
tab = uitab(tg2, 'Title', 'Sparse (geqrf)');
tl = tiledlayout(tab, 1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
nexttile(tl);
abrik_runtime_breakdown(fullfile(results_dir, '20260330_211242_ABRIK_runtime_breakdown.csv'), 'BlockSize', 4, 'ShowLegend', false);
nexttile(tl);
abrik_runtime_breakdown(fullfile(results_dir, '20260330_211439_ABRIK_runtime_breakdown.csv'), 'BlockSize', 4);
set(gca, 'YTickLabel', []); ylabel('');

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
