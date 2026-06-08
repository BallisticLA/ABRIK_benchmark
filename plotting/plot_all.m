
% Resolve paths relative to this script's location (works on any machine)
script_dir  = fileparts(mfilename('fullpath'));
results_dir = fullfile(fileparts(script_dir), 'results');

%% === Figure 1: Performance / Accuracy (tabbed) ===
% Bergamo only (May 28; AMD Zen 4c, 224 threads, num_runs=10, b_sz=1 4 8 16 32).
fig1 = figure('Name', 'ABRIK Performance', 'Position', [50 50 1500 800]);
tg1 = uitabgroup(fig1);

tab = uitab(tg1, 'Title', 'Mat 1 (10k dense)');
plot_abrik_in_tab(tab, results_dir, '20260528_045949_ABRIK_speed_comparisons.csv');

tab = uitab(tg1, 'Title', 'Mat 6 (10k dense)');
plot_abrik_in_tab(tab, results_dir, '20260528_070542_ABRIK_speed_comparisons.csv');

tab = uitab(tg1, 'Title', 'CurlCurl 1.2M');
plot_abrik_in_tab(tab, results_dir, '20260528_085541_ABRIK_speed_comparisons.csv');

%% === Figure 2: Runtime Breakdowns (tabbed) ===
% Bergamo only (May 28; num_runs=10).
fig2 = figure('Name', 'ABRIK Runtime Breakdowns', 'Position', [100 100 1400 600]);
tg2 = uitabgroup(fig2);

% Dense: Mat 1 + Mat 6 side-by-side at b_sz=16
tab = uitab(tg2, 'Title', 'Dense');
tl = tiledlayout(tab, 1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
nexttile(tl);
abrik_runtime_breakdown(fullfile(results_dir, '20260528_071735_ABRIK_runtime_breakdown.csv'), 'BlockSize', 16, 'ShowLegend', false);
title('Mat 1 (10k)');
nexttile(tl);
abrik_runtime_breakdown(fullfile(results_dir, '20260528_080618_ABRIK_runtime_breakdown.csv'), 'BlockSize', 16);
set(gca, 'YTickLabel', []); ylabel(''); title('Mat 6 (10k)');

% Sparse: CurlCurl_3 at b_sz=4
tab = uitab(tg2, 'Title', 'Sparse (CurlCurl 1.2M)');
axes('Parent', tab);
abrik_runtime_breakdown(fullfile(results_dir, '20260528_091812_ABRIK_runtime_breakdown.csv'), 'BlockSize', 4);
title('CurlCurl\_3 (1.2M)');

%% === Figure 3: Per-Triplet Accuracy Analysis (Mat 1 + Mat 6 as vertical subplots) ===
% Bergamo, May 30 (b_sz=16, num_matmuls=32, num_runs=10; median across runs).
fig3 = figure('Name', 'ABRIK Per-Triplet Accuracy', 'Position', [150 150 1500 900]);
tl3 = tiledlayout(fig3, 2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile(tl3);
abrik_accuracy_analysis(fullfile(results_dir, '20260530_063804_ABRIK_accuracy_analysis.csv'), 'CreateFigure', false);

nexttile(tl3);
abrik_accuracy_analysis(fullfile(results_dir, '20260530_064630_ABRIK_accuracy_analysis.csv'), 'CreateFigure', false);

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
