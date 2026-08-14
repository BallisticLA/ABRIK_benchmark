
%% === Centralized figure styling (single source of truth for all plots) ===
% Every axes / line / legend / label created by the plotting functions below
% inherits these defaults, so the three paper figures share one consistent,
% print-legible look. Sizes are chosen so that, once a figure is scaled to the
% paper column width, tick and label text land around 10-11 pt. The defaults are
% removed again when the script exits (onCleanup), so they do not leak into the
% interactive MATLAB session.
set(groot, ...
    'defaultFigureColor',                 'w', ...
    'defaultAxesFontName',                'Helvetica', ...
    'defaultTextFontName',                'Helvetica', ...
    'defaultAxesFontSize',                18, ...    % tick labels
    'defaultAxesLabelFontSizeMultiplier', 1.15, ...  % x/y labels ~ 21 pt
    'defaultAxesTitleFontSizeMultiplier', 1.05, ...  % axes titles ~ 19 pt
    'defaultLegendFontSize',              16, ...
    'defaultLineLineWidth',               2.0);
cleanup_style = onCleanup(@() set(groot, ...
    'defaultFigureColor',                 'remove', ...
    'defaultAxesFontName',                'remove', ...
    'defaultTextFontName',                'remove', ...
    'defaultAxesFontSize',                'remove', ...
    'defaultAxesLabelFontSizeMultiplier', 'remove', ...
    'defaultAxesTitleFontSizeMultiplier', 'remove', ...
    'defaultLegendFontSize',              'remove', ...
    'defaultLineLineWidth',               'remove')); %#ok<NASGU>

% Resolve paths relative to this script's location (works on any machine)
script_dir  = fileparts(mfilename('fullpath'));
addpath(fullfile(script_dir, 'plotting'));
results_dir = fullfile(script_dir, 'results');

% NOTE (2026-07-15): superseded CSVs (Bergamo 20260528/20260530 and the June 17 speed
% reruns) were removed from results/. Copies remain in the maintainers' cluster mirror --
% restore from there before uncommenting any block below that references them.

%% === Figure 1: Performance / Accuracy (tabbed) ===
% SPR (June 17; Intel Sapphire Rapids, 128 threads, b_sz=1 4 16, RSVD pinned to b=16).
% Dense Mat 1 / Mat 6: num_runs=10 (clean, both finished under the 2h cap).
% Sparse CurlCurl_3: num_runs=5 (truncated by the ai-tenn 2h QOS cap, runs 0-4; still
% more reps than the prior 3-run June 2 data). Supersedes the June 2 SPR run.
% Bergamo run (May 28) commented out below pending review of its data issues.
% Perf figures are a vertical 2-panel stack, so keep a less-landscape aspect (narrower
% native width => taller and larger-fonted once scaled to \linewidth in the paper).
fig1 = figure('Name', 'ABRIK Performance', 'Position', [50 50 1150 820]);
tg1 = uitabgroup(fig1);

% PAPER FIGURE SET (identified 2026-07-15): the May 8 SPR sweep, b_sz = {4, 8, 16, 32},
% budget 4096, single-run legacy CSV schema; RSVD = largest block (32). Tab titles are
% chosen so save_tabs emits the exact filenames the paper includes
% (perf_Mat_1__10k_dense_.png, perf_CurlCurl_807k.png, perf_CurlCurl_2_4M.png, ...).
% --- May-8 speed set RETIRED from the figure set (Max, 2026-08-03): superseded by
%     the 07-30/31 clean-harness reruns below, and tainted by the 2x thread
%     oversubscription diagnosed 07-27. CSVs retained; uncomment to compare eras. ---
% tab = uitab(tg1, 'Title', 'Mat 1 (10k dense)');
% plot_abrik_in_tab(tab, results_dir, '20260508_180537_ABRIK_speed_comparisons.csv');
% tab = uitab(tg1, 'Title', 'Mat 6 (10k dense)');
% plot_abrik_in_tab(tab, results_dir, '20260508_180922_ABRIK_speed_comparisons.csv');

% --- CurlCurl_2 (807k) DROPPED from the figure set (Max, 2026-07-31): the paper
%     no longer shows it. CSVs retained; uncomment to restore. ---
% tab = uitab(tg1, 'Title', 'CurlCurl 807k');
% plot_abrik_in_tab(tab, results_dir, '20260508_010115_ABRIK_speed_comparisons.csv');

% tab = uitab(tg1, 'Title', 'CurlCurl 2.4M');   % May-8, retired with the set above
% plot_abrik_in_tab(tab, results_dir, '20260508_013025_ABRIK_speed_comparisons.csv');
% (Second CurlCurl_4 run of the same sweep: 20260508_012821, kept in the ISAAC mirror.)

% --- 2026-07-30/31 REBUILT CAMPAIGN (SPR campus-bigmem, fresh clone @2b9b388,
%     threads=SLURM_CPUS_PER_TASK, --exclusive, num_runs=5, b_sz={4,8,16,32}).
%     Fixes the thread-oversubscription and ai-tenn-reaper defects of the May runs;
%     paper set above kept intact until these are reviewed. ---
tab = uitab(tg1, 'Title', 'Mat 1 (10k) 07-30');
plot_abrik_in_tab(tab, results_dir, '20260730_122832_ABRIK_speed_comparisons.csv');

tab = uitab(tg1, 'Title', 'Mat 6 (10k) 07-30');
plot_abrik_in_tab(tab, results_dir, '20260730_124019_ABRIK_speed_comparisons.csv');

% tab = uitab(tg1, 'Title', 'CurlCurl 807k 07-31');   % dropped with CurlCurl_2 (see above)
% plot_abrik_in_tab(tab, results_dir, '20260731_024710_ABRIK_speed_comparisons.csv');

tab = uitab(tg1, 'Title', 'CurlCurl 2.4M 07-31');
plot_abrik_in_tab(tab, results_dir, '20260731_035131_ABRIK_speed_comparisons.csv');

% --- June 17 SPR reruns (b_sz = {1, 4, 16}, RSVD b=16, num_runs=10): superseded for the
%     paper by the May 8 sweep above; kept for reference. ---
% tab = uitab(tg1, 'Title', 'Mat 1 jun17');
% plot_abrik_in_tab(tab, results_dir, '20260617_045215_ABRIK_speed_comparisons.csv');
% tab = uitab(tg1, 'Title', 'Mat 6 jun17');
% plot_abrik_in_tab(tab, results_dir, '20260617_053601_ABRIK_speed_comparisons.csv');
% tab = uitab(tg1, 'Title', 'CurlCurl 1.2M jun17');
% plot_abrik_in_tab(tab, results_dir, '20260617_165609_ABRIK_speed_comparisons.csv');

% --- Bergamo (May 28), commented out pending review ---
% tab = uitab(tg1, 'Title', 'Mat 1 (10k dense)');
% plot_abrik_in_tab(tab, results_dir, '20260528_045949_ABRIK_speed_comparisons.csv');
%
% tab = uitab(tg1, 'Title', 'Mat 6 (10k dense)');
% plot_abrik_in_tab(tab, results_dir, '20260528_070542_ABRIK_speed_comparisons.csv');
%
% tab = uitab(tg1, 'Title', 'CurlCurl 1.2M');
% plot_abrik_in_tab(tab, results_dir, '20260528_085541_ABRIK_speed_comparisons.csv');

%% === Figure 2: Runtime Breakdowns (tabbed) ===
% SPR single-b_sz reruns (June 11): dense b=16 (Mat1/Mat6, n=10), sparse b=4
% (CurlCurl_3, n=6). Block size = the speed-benchmark winner per matrix.
% Bergamo (May 28) commented out pending review.
fig2 = figure('Name', 'ABRIK Runtime Breakdowns', 'Position', [100 100 1400 600]);
tg2 = uitabgroup(fig2);

% Dense: Mat 1 + Mat 6 side-by-side at b_sz=16.
% PAPER FIGURE SET (identified 2026-07-15): the June 2 SPR campaign (b_sz sweep 1..128,
% matmuls 2..64 -> at b=16 the mv range 32..1024 shown in the paper). The June 11
% single-b_sz reruns (mv up to 4096, commented below) show a different GEMM share and
% are NOT what the paper prints.
% --- June-2 paper set RETIRED (Max, 2026-08-03): superseded by the clean-harness
%     07-30 rerun below; headings simplified to the paper's three panels. ---
% tab = uitab(tg2, 'Title', 'Dense');
% tl = tiledlayout(tab, 1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
% nexttile(tl);
% abrik_runtime_breakdown(fullfile(results_dir, '20260602_185805_ABRIK_runtime_breakdown.csv'), 'BlockSize', 16, 'ShowLegend', false);
% title('Mat 1 (10k)');
% nexttile(tl);
% abrik_runtime_breakdown(fullfile(results_dir, '20260602_190006_ABRIK_runtime_breakdown.csv'), 'BlockSize', 16);
% set(gca, 'YTickLabel', []); ylabel(''); title('Mat 6 (10k)');
% --- June 11 single-b_sz reruns (superseded for the paper): ---
% abrik_runtime_breakdown(fullfile(results_dir, '20260611_212622_ABRIK_runtime_breakdown.csv'), 'BlockSize', 16, 'ShowLegend', false);  % Mat 1
% abrik_runtime_breakdown(fullfile(results_dir, '20260611_212936_ABRIK_runtime_breakdown.csv'), 'BlockSize', 16);                       % Mat 6

% --- Bergamo (May 28), commented out pending review ---
% abrik_runtime_breakdown(fullfile(results_dir, '20260528_071735_ABRIK_runtime_breakdown.csv'), 'BlockSize', 16, 'ShowLegend', false);  % Mat 1
% abrik_runtime_breakdown(fullfile(results_dir, '20260528_080618_ABRIK_runtime_breakdown.csv'), 'BlockSize', 16);                       % Mat 6

% --- Sparse: CurlCurl_3 at b_sz=4 (SPR, June 11 single-b_sz rerun). Complete
%     clean sweep mv 8..4096, num_runs=6, finished in 33 min under the 2h cap. ---
% tab = uitab(tg2, 'Title', 'Sparse (CurlCurl 1.2M)');   % June-11, retired with the set above
% axes('Parent', tab);
% abrik_runtime_breakdown(fullfile(results_dir, '20260611_213327_ABRIK_runtime_breakdown.csv'), 'BlockSize', 4);
% title('CurlCurl\_3 (1.2M)');

% --- 2026-07-30 rebuilt campaign: dense pair at b=16 (num_runs=5) ---
tab = uitab(tg2, 'Title', 'Dense (Mat 1 | Mat 6)');
tl_d2 = tiledlayout(tab, 1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
nexttile(tl_d2);
abrik_runtime_breakdown(fullfile(results_dir, '20260730_122516_ABRIK_runtime_breakdown.csv'), 'BlockSize', 16, 'ShowLegend', false);
title('Mat 1 (10k)');
nexttile(tl_d2);
abrik_runtime_breakdown(fullfile(results_dir, '20260730_122646_ABRIK_runtime_breakdown.csv'), 'BlockSize', 16);
set(gca, 'YTickLabel', []); ylabel(''); title('Mat 6 (10k)');

% --- Sparse: the largest sparse matrix WITH breakdown data is CurlCurl_3 (1.2M);
%     b = 4 (the sparse winner), from the 07-30 clean-harness b-sweep. ---
tab = uitab(tg2, 'Title', 'Sparse (CurlCurl_3, 1.2M)');
axes('Parent', tab);
abrik_runtime_breakdown(fullfile(results_dir, '20260730_130114_ABRIK_runtime_breakdown.csv'), 'BlockSize', 4);
title('CurlCurl\_3 (1.2M), b = 4');

% --- 2026-07-30 rebuilt campaign: the b-sweep sparse breakdown (Rob's red 747 /
%     Max's Q4): CurlCurl_3 (1.2M) at b = 4, 8, 16, 32, one clean cell each
%     (35m / 1h16 / 3h13 / 8h50 on campus-bigmem, no reaper truncation). ---
tab = uitab(tg2, 'Title', 'Sparse b-sweep (CurlCurl_3)');
% 2026-08-04 (Max): full-width panel row with ONE shared y-axis label and one
% shared x-axis label; per-tile labels collided at page width.
set(fig2, 'Position', [100 100 1800 520]);
tl_sw = tiledlayout(tab, 1, 4, 'TileSpacing', 'tight', 'Padding', 'compact');
nexttile(tl_sw);
abrik_runtime_breakdown(fullfile(results_dir, '20260730_130114_ABRIK_runtime_breakdown.csv'), 'BlockSize', 4, 'ShowLegend', false);
title('b = 4');
nexttile(tl_sw);
abrik_runtime_breakdown(fullfile(results_dir, '20260730_133638_ABRIK_runtime_breakdown.csv'), 'BlockSize', 8, 'ShowLegend', false);
set(gca, 'YTickLabel', []); ylabel(''); title('b = 8');
nexttile(tl_sw);
abrik_runtime_breakdown(fullfile(results_dir, '20260730_145313_ABRIK_runtime_breakdown.csv'), 'BlockSize', 16, 'ShowLegend', false);
set(gca, 'YTickLabel', []); ylabel(''); title('b = 16');
nexttile(tl_sw);
abrik_runtime_breakdown(fullfile(results_dir, '20260730_175646_ABRIK_runtime_breakdown.csv'), 'BlockSize', 32);
set(gca, 'YTickLabel', []); ylabel(''); title('b = 32');
% one shared label per axis for the whole row
for a_sw = 1:numel(tl_sw.Children)
    if isa(tl_sw.Children(a_sw), 'matlab.graphics.axis.Axes')
        xlabel(tl_sw.Children(a_sw), ''); ylabel(tl_sw.Children(a_sw), '');
    end
end
xlabel(tl_sw, 'Matrix-vector products', 'FontSize', 20);
ylabel(tl_sw, 'Runtime %', 'FontSize', 20);

% --- Bergamo (May 28) sparse, commented out pending review ---
% abrik_runtime_breakdown(fullfile(results_dir, '20260528_091812_ABRIK_runtime_breakdown.csv'), 'BlockSize', 4);

% --- TODO (paper figure set): the paper's sparse breakdown is a 3-panel figure
%     (CurlCurl_1 226k / _2 807k / _3 1.2M side by side, breakdown_Sparse__CurlCurl_1_3_.png).
%     Panel 3 (1.2M, b=4, mv 8..4096) = 20260611_213327 (local). Panels 1-2 (CC1/CC2 at
%     b=4, mv 8..512) have NO CSV anywhere: the ISAAC sparse-breakdown script only ever
%     ran CurlCurl_3 (checked 2026-07-15), so CC1/CC2 breakdowns must be rerun on ISAAC
%     (or located on whatever machine produced the zip figure). Then uncomment:
% tab = uitab(tg2, 'Title', 'Sparse 3-panel (CurlCurl 1-3)');
% tl_sp = tiledlayout(tab, 1, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
% nexttile(tl_sp);
% abrik_runtime_breakdown(fullfile(results_dir, '<PULL>_226k.csv'), 'BlockSize', 16, 'ShowLegend', false); title('CurlCurl\_1 (226k)');
% nexttile(tl_sp);
% abrik_runtime_breakdown(fullfile(results_dir, '<PULL>_807k.csv'), 'BlockSize', 16, 'ShowLegend', false); set(gca,'YTickLabel',[]); ylabel(''); title('CurlCurl\_2 (807k)');
% nexttile(tl_sp);
% abrik_runtime_breakdown(fullfile(results_dir, '<PULL>_1_2M.csv'), 'BlockSize', 16); set(gca,'YTickLabel',[]); ylabel(''); title('CurlCurl\_3 (1.2M)');

%% (Figure 3 RETIRED 2026-08-03, Max: the June-2 accuracy pair is superseded by
%  the 07-30/08-03 clean-harness rerun below and rendered identically; keep only
%  the new results. CSVs retained in results/.)

%% === Figure 3b: Per-Triplet Accuracy, 2026-07-30 rebuilt campaign ===
% Same layout as Figure 3; three-metric svd_residual variant (@2b9b388), num_runs=5.
fig3b = figure('Name', 'ABRIK Per-Triplet Accuracy (dense)', 'Position', [170 170 1200 960]);
tl3b = tiledlayout(fig3b, 2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
nexttile(tl3b);
abrik_accuracy_analysis(fullfile(results_dir, '20260803_150417_ABRIK_accuracy_analysis.csv'), 'CreateFigure', false);
nexttile(tl3b);
abrik_accuracy_analysis(fullfile(results_dir, '20260803_150548_ABRIK_accuracy_analysis.csv'), 'CreateFigure', false, 'ShowLegend', false);


%% (Figure 3c RETIRED 2026-08-03, Max: the C4 metric curves are integrated
%  directly into the per-triplet accuracy figure above -- abrik_accuracy_analysis
%  overlays eq.(14)/eq.(6.1) whenever the CSV carries the columns. The standalone
%  comparison helper abrik_metric_comparison.m remains available if wanted.)

%% === Figure 3c: Per-triplet accuracy on CurlCurl_0 (metric failure case) ===
% 2026-08-11 (Max): its own figure, placed after the dense accuracy figure. The
% smallest curl-curl operator (11,083^2), densified so GESDD supplies the
% reference. This is where the one-sided metric fails hardest.
fig3c = figure('Name', 'ABRIK Per-Triplet Accuracy (CurlCurl\_0)', 'Position', [190 190 1200 560]);
ax3c = axes('Parent', fig3c); %#ok<NASGU>
abrik_accuracy_analysis(fullfile(results_dir, '20260811_103040_ABRIK_accuracy_analysis_CurlCurl_0.csv'), 'CreateFigure', false);

%% === Figure 4: Adversarial hard instance (Wishart lower bound) ===
% Gapless spectrum sigma_i = sqrt(1 - (i/n)^2), n = 1000. Two budgets:
%   512  (< n)  -- the lower-bound regime: bounded budget => bounded accuracy
%   1024 (>= n) -- the Krylov space can span all of n, showing the escape from
%                  that regime (2026-08-03, Max). k_r = 512 keeps RSVD's
%                  unclamped k_r = budget/2 within n.
% Both cells ran ON ISAAC under the rebuilt harness (2026-08-03, num_runs=5).
% The 20260714_163000 CSV they replace was a LOCAL-machine run (its own header
% records a /home/mymel input path) despite this block previously claiming
% "SPR, July 14", and predated the thread-oversubscription fix.
fig4 = figure('Name', 'ABRIK Adversarial (Wishart LB)', 'Position', [200 200 1150 820]);
tg4 = uitabgroup(fig4);
% One tab per ISAAC wishart budget, header-verified (never filename-guessed --
% a failed pull once got the 512 CSV wired in mislabeled, 2026-08-03). Budgets
% sort ascending; 2000 = 2n is the ceiling (subspace saturation per side AND
% the largest budget with RSVD's unclamped k_r = budget/2 still <= n).
wB = []; wN = []; wF = {};
dW = dir(fullfile(results_dir, '*_ABRIK_speed_comparisons.csv'));
for wi = 1:numel(dW)
    hd = fileread(fullfile(results_dir, dW(wi).name));
    if isempty(regexp(hd, 'wishart', 'once')), continue; end
    bt = regexp(hd, 'Budget \(total matvecs\): (\d+)', 'tokens', 'once');
    nt = regexp(hd, 'Input size: (\d+) x', 'tokens', 'once');
    if isempty(bt) || isempty(nt) || isempty(regexp(hd, 'scratch/mmelnic1', 'once')), continue; end  % ISAAC runs only
    wB(end+1) = str2double(bt{1}); wN(end+1) = str2double(nt{1}); wF{end+1} = dW(wi).name; %#ok<SAGROW>
end
[~, wo] = sortrows([wN(:), wB(:)]); wB = wB(wo); wN = wN(wo); wF = wF(wo);
assert(~isempty(wB), 'Figure 4: no ISAAC wishart CSVs found in results/');
for wi = 1:numel(wB)
    r = wB(wi) / wN(wi);
    if r >= 2, rel = '= 2n'; elseif r >= 1, rel = '~ n'; else, rel = '< n'; end
    tab = uitab(tg4, 'Title', sprintf('n=%d, budget %d (%s)', wN(wi), wB(wi), rel));
    plot_abrik_in_tab(tab, results_dir, wF{wi});
end
% Superseded local run, kept for reference:
% [T4, meta4] = parse_abrik_csv(fullfile(results_dir, '20260714_163000_ABRIK_speed_comparisons.csv'));

%% === Figure 5: Adaptive termination, Rob's design (B2, red 656) ===
% Sparse CurlCurl_3, b=4: non-adaptive sweep vs the adaptive driver at Rob's
% exact absolute tolerances (1e-5 / 1e-10, b38ca8e negative-arg mode).
fig5 = figure('Name', 'ABRIK Adaptive Termination (B2)', 'Position', [210 210 1250 560]);
tl5 = tiledlayout(fig5, 1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
ax5a = nexttile(tl5);
abrik_adaptive_termination(fullfile(results_dir, '20260803_150649_ABRIK_adaptive_hard.csv'), ax5a, 'tol = 1e-5');
ax5b = nexttile(tl5);
abrik_adaptive_termination(fullfile(results_dir, '20260803_153253_ABRIK_adaptive_hard.csv'), ax5b, 'tol = 1e-10');

%% === Save all tabs / figures as PNG ===
plots_dir = fullfile(script_dir, 'figures');
if ~exist(plots_dir, 'dir'), mkdir(plots_dir); end

save_tabs(tg1, plots_dir, 'perf');
save_tabs(tg2, plots_dir, 'breakdown');

% Figures 3 and 4 are single figures (no uitabs); save directly.
exportgraphics(fig3b, fullfile(plots_dir, 'accuracy_mat1_mat6.png'), 'Resolution', 300);
exportgraphics(fig3c, fullfile(plots_dir, 'accuracy_curlcurl0.png'), 'Resolution', 300);
exportgraphics(fig5, fullfile(plots_dir, 'adaptive_termination_b2.png'), 'Resolution', 300);
save_tabs(tg4, plots_dir, 'perf_wishart_lb_1000');

fprintf('Saved %d PNGs to %s\n', ...
    numel(tg1.Children) + numel(tg2.Children) + 2, plots_dir);

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
        exportgraphics(tab, fname, 'Resolution', 300);
    end
end
