%{
Per-algorithm grid: digits of accuracy vs matvec budget (top row) and
vs wall-clock time (bottom row).

Always 2x3 layout: ABRIK, RSVD, Spectra (unified CSV format).

  Row 1: digits vs matvec budget (b_sz * num_matmuls), log scale
  Row 2: digits vs time (seconds), log scale

ABRIK and RSVD show one curve per block size.
Spectra (SVDS) is single-vector Lanczos — shown as one merged curve.

Usage:
  abrik_precision_vs_speedup_v2('path/to/file.csv')
  abrik_precision_vs_speedup_v2(T, meta)               % pre-parsed data
%}
function abrik_precision_vs_speedup_v2(arg1, arg2, nvargs)
    arguments
        arg1
        arg2 = []
        nvargs.Parent = []   % optional parent (e.g. uitab) for the tiledlayout
    end
    if ~isempty(arg2) && istable(arg1)
        T = arg1;  meta = arg2;
    else
        [T, meta] = parse_abrik_csv(arg1);
    end
    T = select_best_runs(T);

    if ~isempty(nvargs.Parent)
        parent = nvargs.Parent;
    else
        parent = gcf;
    end

    % Always 2x3: ABRIK, RSVD, Spectra (unified format always includes RSVD)
    tl = tiledlayout(parent, 2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

    % Colorblind-safe palette (Wong 2011, Nature Methods) for block sizes.
    % Supports up to 7 block sizes; each gets a unique color + marker.
    colors = [0.00 0.45 0.70;   % blue
              0.90 0.60 0.00;   % orange
              0.00 0.62 0.45;   % bluish green
              0.80 0.40 0.00;   % vermillion
              0.35 0.70 0.90;   % sky blue
              0.80 0.60 0.70;   % reddish purple
              0.95 0.90 0.25];  % yellow
    markers = {'-o', '-s', '-^', '-d', '-v', '-p', '-h'};
    spectra_color = [0.00 0.00 0.00];  % black for Spectra

    % Get unique block sizes for shared legend
    unique_bsz = unique(T.b_sz);

    % ---- Row 1: digits vs matvec budget (log scale) ----

    nexttile(tl);
    plot_budget_by_bsz(T, "ABRIK", unique_bsz, colors, markers);
    title('ABRIK', 'FontSize', 18);
    ylabel('Digits of accuracy', 'FontSize', 16);
    xlabel('Matrix-vector products', 'FontSize', 16);

    nexttile(tl);
    plot_budget_by_bsz(T, "RSVD", unique_bsz, colors, markers);
    title('RSVD', 'FontSize', 18);
    xlabel('Matrix-vector products', 'FontSize', 16);
    set(gca, 'YTickLabel', []);

    nexttile(tl);
    plot_spectra_budget(T, spectra_color);
    title('Spectra', 'FontSize', 18);
    xlabel('Matrix-vector products', 'FontSize', 16);
    set(gca, 'YTickLabel', []);

    % ---- Row 2: digits vs time (log scale) ----

    nexttile(tl);
    plot_time_by_bsz(T, "ABRIK", unique_bsz, colors, markers);
    ylabel('Digits of accuracy', 'FontSize', 16);
    xlabel('Time (s)', 'FontSize', 16);

    nexttile(tl);
    plot_time_by_bsz(T, "RSVD", unique_bsz, colors, markers);
    xlabel('Time (s)', 'FontSize', 16);
    set(gca, 'YTickLabel', []);

    nexttile(tl);
    plot_spectra_time(T, spectra_color);
    xlabel('Time (s)', 'FontSize', 16);
    set(gca, 'YTickLabel', []);

    % ---- Uniform axes across all tiles ----
    all_digits = log10(1 ./ T.error);
    yl = [min(all_digits) - 0.5, max(all_digits) + 0.5];

    all_mvps = T.b_sz .* T.num_matmuls;
    budget_lim = [min(all_mvps) * 0.7, max(all_mvps) * 1.4];

    all_times = T.duration_us / 1e6;
    time_lim = [min(all_times) * 0.7, max(all_times) * 1.4];

    ax_list = findobj(tl, 'Type', 'axes');
    for a = 1:numel(ax_list)
        ylim(ax_list(a), yl);
    end

    % Apply uniform x-axis: top row = budget, bottom row = time
    n_cols = 3;

    % Precompute shared log2 ticks for the bottom row (time axis)
    shared_time_ticks = compute_log2_ticks(time_lim);
    shared_time_labels = arrayfun(@(v) sprintf('%.3g', v), shared_time_ticks, 'UniformOutput', false);

    for idx = 1:(2 * n_cols)
        ax = nexttile(tl, idx);
        if idx <= n_cols
            xlim(ax, budget_lim);
        else
            xlim(ax, time_lim);
            set(ax, 'XTick', shared_time_ticks, 'XTickLabel', shared_time_labels);
        end
    end

    % ---- Shared legend on top-right (Spectra) tile ----
    % The Spectra budget tile is tile n_cols (top-right)
    ax_spectra = nexttile(tl, n_cols);
    hold(ax_spectra, 'on');
    h_leg = gobjects(numel(unique_bsz) + 1, 1);
    leg_labels = arrayfun(@(b) sprintf('b=%d', b), unique_bsz, 'UniformOutput', false);
    leg_labels{end+1} = 'Spectra';
    for i = 1:numel(unique_bsz)
        ci = min(i, size(colors, 1));
        mk = markers{min(i, numel(markers))};
        h_leg(i) = plot(ax_spectra, NaN, NaN, mk, 'Color', colors(ci,:), ...
                        'MarkerFaceColor', colors(ci,:), 'MarkerSize', 10, 'LineWidth', 1.5);
    end
    h_leg(end) = plot(ax_spectra, NaN, NaN, '-p', 'Color', spectra_color, ...
                      'MarkerFaceColor', spectra_color, 'MarkerSize', 10, 'LineWidth', 1.5);
    legend(ax_spectra, h_leg, leg_labels, 'Location', 'southeast', 'FontSize', 11);

    % ---- Build informative figure title ----
    title_parts = {};
    if meta.input_matrix ~= ""
        [~, fname, ~] = fileparts(meta.input_matrix);
        title_parts{end+1} = fname;
    end
    if meta.input_size ~= ""
        title_parts{end+1} = meta.input_size;
    end
    if meta.is_sparse
        title_parts{end+1} = 'sparse';
    else
        title_parts{end+1} = 'dense';
    end
    if ~isempty(title_parts)
        title(tl, strjoin(title_parts, '  |  '), 'FontSize', 18, 'Interpreter', 'none');
    end
end

%% -----------------------------------------------------------------------
function plot_budget_by_bsz(T, algorithm, unique_bsz, colors, markers)
    rows = T(T.algorithm == algorithm, :);
    hold on; grid on;

    for i = 1:numel(unique_bsz)
        bsz = unique_bsz(i);
        sub = rows(rows.b_sz == bsz, :);
        if isempty(sub), continue; end
        sub = sortrows(sub, 'num_matmuls');
        mvps = sub.b_sz .* sub.num_matmuls;
        digits = log10(1 ./ sub.error);
        ci = min(i, size(colors, 1));
        mk = markers{min(i, numel(markers))};
        plot(mvps, digits, mk, 'Color', colors(ci,:), ...
             'MarkerFaceColor', colors(ci,:), 'MarkerSize', 10, 'LineWidth', 1.5);
    end
    % Set x-ticks to actual matrix-vector product counts
    tick_vals = sort(unique(rows.b_sz .* rows.num_matmuls));
    set(gca, 'XScale', 'log', 'XTick', tick_vals, 'XTickLabel', arrayfun(@num2str, tick_vals, 'UniformOutput', false), 'FontSize', 14);
    xtickangle(45);
end

%% -----------------------------------------------------------------------
function plot_time_by_bsz(T, algorithm, unique_bsz, colors, markers)
    rows = T(T.algorithm == algorithm, :);
    hold on; grid on;

    for i = 1:numel(unique_bsz)
        bsz = unique_bsz(i);
        sub = rows(rows.b_sz == bsz, :);
        if isempty(sub), continue; end
        sub = sortrows(sub, 'num_matmuls');
        time_s = sub.duration_us / 1e6;
        digits = log10(1 ./ sub.error);
        ci = min(i, size(colors, 1));
        mk = markers{min(i, numel(markers))};
        plot(time_s, digits, mk, 'Color', colors(ci,:), ...
             'MarkerFaceColor', colors(ci,:), 'MarkerSize', 10, 'LineWidth', 1.5);
    end
    set(gca, 'XScale', 'log', 'FontSize', 14);
end

%% -----------------------------------------------------------------------
function plot_spectra_budget(T, color)
    rows = T(T.algorithm == "SVDS", :);
    if isempty(rows), return; end
    hold on; grid on;

    % For Spectra, x-axis = b_sz * num_matmuls (actual iteration budget),
    % since SVDS uses the full budget as single-vector Lanczos iterations.
    budget = rows.b_sz .* rows.num_matmuls;
    digits = log10(1 ./ rows.error);

    % Deduplicate: keep best per unique budget
    [budget_u, ~, ic] = unique(budget);
    digits_u = zeros(size(budget_u));
    for i = 1:numel(budget_u)
        digits_u(i) = max(digits(ic == i));
    end

    plot(budget_u, digits_u, '-p', 'Color', color, ...
         'MarkerFaceColor', color, 'MarkerSize', 10, 'LineWidth', 1.5);
    set(gca, 'XScale', 'log', 'XTick', budget_u, 'XTickLabel', arrayfun(@num2str, budget_u, 'UniformOutput', false), 'FontSize', 14);
    xtickangle(45);
    xtickangle(45);
end

%% -----------------------------------------------------------------------
function plot_spectra_time(T, color)
    rows = T(T.algorithm == "SVDS", :);
    if isempty(rows), return; end
    hold on; grid on;

    budget = rows.b_sz .* rows.num_matmuls;
    time_s = rows.duration_us / 1e6;
    digits = log10(1 ./ rows.error);

    % Deduplicate by budget (same as top plot): keep best accuracy per budget,
    % use the corresponding time for x-axis.
    [budget_u, ~, ic] = unique(budget);
    time_u   = zeros(size(budget_u));
    digits_u = zeros(size(budget_u));
    for i = 1:numel(budget_u)
        mask = (ic == i);
        [digits_u(i), best] = max(digits(mask));
        times_i = time_s(mask);
        time_u(i) = times_i(best);
    end

    % Sort by time for clean line drawing
    [time_u, order] = sort(time_u);
    digits_u = digits_u(order);

    plot(time_u, digits_u, '-p', 'Color', color, ...
         'MarkerFaceColor', color, 'MarkerSize', 10, 'LineWidth', 1.5);
    set(gca, 'XScale', 'log', 'FontSize', 14);
end

%% -----------------------------------------------------------------------
function ticks = compute_log2_ticks(xl)
    % Compute tick marks at powers of 2 for a given [lo hi] range
    lo = floor(log2(xl(1)));
    hi = ceil(log2(xl(2)));
    ticks = 2.^(lo:hi);
    % Also include half-powers if range is small
    if hi - lo <= 3
        ticks = 2.^(lo:0.5:hi);
    end
    ticks = ticks(ticks >= xl(1) & ticks <= xl(2));
end
