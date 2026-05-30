
% Resolve paths relative to this script's location (works on any machine)
script_dir  = fileparts(mfilename('fullpath'));
results_dir = fullfile(fileparts(script_dir), 'results');

%% === Figure 1: Performance / Accuracy (tabbed) ===
fig1 = figure('Name', 'ABRIK Performance', 'Position', [50 50 1500 800]);
tg1 = uitabgroup(fig1);

% Dense — Bergamo, May 28 (num_runs=10, b_sz=1 4 8 16 32; AMD Zen 4c, 224 threads)
tab = uitab(tg1, 'Title', 'Mat 1 (10k dense, Bergamo)');
plot_abrik_in_tab(tab, results_dir, '20260528_045949_ABRIK_speed_comparisons.csv');

tab = uitab(tg1, 'Title', 'Mat 6 (10k dense, Bergamo)');
plot_abrik_in_tab(tab, results_dir, '20260528_070542_ABRIK_speed_comparisons.csv');

% Sparse — Bergamo, May 28 (CurlCurl_3 only, num_runs=10)
tab = uitab(tg1, 'Title', 'CurlCurl 1.2M (Bergamo)');
plot_abrik_in_tab(tab, results_dir, '20260528_085541_ABRIK_speed_comparisons.csv');

% Dense — SPR (May 8, 10k x 10k, num_runs=1; Intel Sapphire Rapids, 128 threads)
tab = uitab(tg1, 'Title', 'Mat 1 (10k dense, SPR)');
plot_abrik_in_tab(tab, results_dir, '20260508_180537_ABRIK_speed_comparisons.csv');

tab = uitab(tg1, 'Title', 'Mat 6 (10k dense, SPR)');
plot_abrik_in_tab(tab, results_dir, '20260508_180922_ABRIK_speed_comparisons.csv');

% Sparse — SPR (May 8, CurlCurl_1-4, single-run budgeted checkpointing)
tab = uitab(tg1, 'Title', 'CurlCurl 226k (SPR)');
plot_abrik_in_tab(tab, results_dir, '20260508_005743_ABRIK_speed_comparisons.csv');

tab = uitab(tg1, 'Title', 'CurlCurl 807k (SPR)');
plot_abrik_in_tab(tab, results_dir, '20260508_010115_ABRIK_speed_comparisons.csv');

tab = uitab(tg1, 'Title', 'CurlCurl 1.2M (SPR)');
plot_abrik_in_tab(tab, results_dir, '20260508_011128_ABRIK_speed_comparisons.csv');

tab = uitab(tg1, 'Title', 'CurlCurl 2.4M (SPR)');
plot_abrik_in_tab(tab, results_dir, '20260508_012821_ABRIK_speed_comparisons.csv');  % 013025 is a duplicate rerun

%% === Figure 2: Runtime Breakdowns (tabbed) ===
fig2 = figure('Name', 'ABRIK Runtime Breakdowns', 'Position', [100 100 1400 600]);
tg2 = uitabgroup(fig2);

% Bergamo dense breakdowns (May 28, 10k x 10k, num_runs=10)
tab = uitab(tg2, 'Title', 'Dense (Bergamo)');
tl = tiledlayout(tab, 1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
nexttile(tl);
abrik_runtime_breakdown(fullfile(results_dir, '20260528_071735_ABRIK_runtime_breakdown.csv'), 'BlockSize', 16, 'ShowLegend', false);
title('Mat 1 (10k)');
nexttile(tl);
abrik_runtime_breakdown(fullfile(results_dir, '20260528_080618_ABRIK_runtime_breakdown.csv'), 'BlockSize', 16);
set(gca, 'YTickLabel', []); ylabel(''); title('Mat 6 (10k)');

% Bergamo sparse breakdown (May 28, CurlCurl_3 only, num_runs=10)
tab = uitab(tg2, 'Title', 'Sparse (CurlCurl 1.2M, Bergamo)');
axes('Parent', tab);
abrik_runtime_breakdown(fullfile(results_dir, '20260528_091812_ABRIK_runtime_breakdown.csv'), 'BlockSize', 4);
title('CurlCurl\_3 (1.2M)');

% Legacy SPR dense breakdowns (Mar 30)
tab = uitab(tg2, 'Title', 'Dense (SPR, legacy)');
tl = tiledlayout(tab, 1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
nexttile(tl);
abrik_runtime_breakdown(fullfile(results_dir, '20260330_182920_ABRIK_runtime_breakdown.csv'), 'BlockSize', 16, 'ShowLegend', false);
nexttile(tl);
abrik_runtime_breakdown(fullfile(results_dir, '20260330_183055_ABRIK_runtime_breakdown.csv'), 'BlockSize', 16);
set(gca, 'YTickLabel', []); ylabel('');

% Legacy SPR sparse breakdowns (ISAAC Apr 8, CurlCurl_1-3; CC4 b=4-only — incomplete, skipped pending rerun)
tab = uitab(tg2, 'Title', 'Sparse (CurlCurl 1-3, SPR)');
tl = tiledlayout(tab, 1, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
nexttile(tl);
abrik_runtime_breakdown(fullfile(results_dir, '20260408_010540_ABRIK_runtime_breakdown.csv'), 'BlockSize', 4, 'ShowLegend', false);
title('CurlCurl\_1 (226k)');
nexttile(tl);
abrik_runtime_breakdown(fullfile(results_dir, '20260408_010705_ABRIK_runtime_breakdown.csv'), 'BlockSize', 4, 'ShowLegend', false);
set(gca, 'YTickLabel', []); ylabel(''); title('CurlCurl\_2 (807k)');
nexttile(tl);
abrik_runtime_breakdown(fullfile(results_dir, '20260408_011057_ABRIK_runtime_breakdown.csv'), 'BlockSize', 4);
set(gca, 'YTickLabel', []); ylabel(''); title('CurlCurl\_3 (1.2M)');

%% === Figure 3: Per-Triplet Accuracy Analysis (Mat 1 + Mat 6 as vertical subplots) ===
fig3 = figure('Name', 'ABRIK Per-Triplet Accuracy', 'Position', [150 150 1500 900]);
tl3 = tiledlayout(fig3, 2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile(tl3);
abrik_accuracy_analysis(fullfile(results_dir, '20260401_103154_ABRIK_accuracy_analysis.csv'), 'CreateFigure', false);

nexttile(tl3);
abrik_accuracy_analysis(fullfile(results_dir, '20260401_103455_ABRIK_accuracy_analysis.csv'), 'CreateFigure', false);

%% === Save all tabs / figures as PNG ===
plots_dir = fullfile(fileparts(script_dir), 'plots');
if ~exist(plots_dir, 'dir'), mkdir(plots_dir); end

save_tabs(tg1, plots_dir, 'perf');
save_tabs(tg2, plots_dir, 'breakdown');

% Figure 3 is a single figure (no uitabs); save directly.
exportgraphics(fig3, fullfile(plots_dir, 'accuracy_mat1_mat6.png'), 'Resolution', 200);

fprintf('Saved %d PNGs to %s\n', ...
    numel(tg1.Children) + numel(tg2.Children) + 1, plots_dir);

%% -----------------------------------------------------------------------
function plot_abrik_in_tab(tab, results_dir, csv_name)
    csv_path = fullfile(results_dir, csv_name);
    [T, meta] = parse_abrik_csv(csv_path);
    abrik_precision_vs_speedup_v2(T, meta, 'Parent', tab);
end

%% -----------------------------------------------------------------------
function save_tabs(tg, plots_dir, prefix)
% Save each tab in uitabgroup tg as a PNG: <plots_dir>/<prefix>_<tab_title>.png
    for i = 1:numel(tg.Children)
        tab = tg.Children(i);
        tg.SelectedTab = tab;
        drawnow;
        safe_title = regexprep(tab.Title, '[^A-Za-z0-9_]', '_');
        fname = fullfile(plots_dir, sprintf('%s_%s.png', prefix, safe_title));
        exportgraphics(tab, fname, 'Resolution', 200);
    end
end
