%{
Per-algorithm grid: digits of accuracy vs matvec budget (top row) and
vs wall-clock time (bottom row).

Dense data (ABRIK + RSVD + Spectra): 2x3 layout.
Sparse data (ABRIK + Spectra only):  2x2 layout.

  Row 1: digits vs matvec budget (b_sz * num_matmuls), log scale
  Row 2: digits vs time (seconds), log scale

ABRIK and RSVD show one curve per block size.
Spectra (SVDS) is single-vector Lanczos — shown as one merged curve.

Usage:
  abrik_precision_vs_speedup_v2('path/to/file.csv')
  abrik_precision_vs_speedup_v2(T, meta)               % pre-parsed data
%}
function abrik_precision_vs_speedup_v2(arg1, arg2)
    if nargin == 2 && istable(arg1)
        T = arg1;  meta = arg2;
    else
        [T, meta] = parse_abrik_csv(arg1);
    end
    T = select_best_runs(T);

    has_rsvd = any(T.algorithm == "RSVD");

    if has_rsvd
        tiledlayout(2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
    else
        tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
    end

    % Shared colors/markers for block sizes
    colors = [0.00 0.45 0.74;   % blue
              0.85 0.33 0.10;   % orange
              0.93 0.69 0.13;   % yellow
              0.49 0.18 0.56];  % purple
    markers = {'-o', '-d', '-s', '-^'};
    spectra_color = [0 0.5 0];

    % Get unique block sizes for shared legend
    unique_bsz = unique(T.b_sz);

    % ---- Row 1: digits vs matvec budget (log scale) ----

    nexttile;
    plot_budget_by_bsz(T, "ABRIK", unique_bsz, colors, markers);
    title('ABRIK', 'FontSize', 18);
    ylabel('Digits of accuracy', 'FontSize', 16);
    xlabel('Matvec budget', 'FontSize', 16);

    if has_rsvd
        nexttile;
        plot_budget_by_bsz(T, "RSVD", unique_bsz, colors, markers);
        title('RSVD', 'FontSize', 18);
        xlabel('Matvec budget', 'FontSize', 16);
    end

    nexttile;
    plot_spectra_budget(T, spectra_color);
    title('Spectra', 'FontSize', 18);
    xlabel('Matvec budget', 'FontSize', 16);

    % ---- Row 2: digits vs time (log scale) ----

    nexttile;
    plot_time_by_bsz(T, "ABRIK", unique_bsz, colors, markers);
    ylabel('Digits of accuracy', 'FontSize', 16);
    xlabel('Time (s)', 'FontSize', 16);

    if has_rsvd
        nexttile;
        plot_time_by_bsz(T, "RSVD", unique_bsz, colors, markers);
        xlabel('Time (s)', 'FontSize', 16);
    end

    nexttile;
    plot_spectra_time(T, spectra_color);
    xlabel('Time (s)', 'FontSize', 16);

    % ---- Uniform axes across all tiles ----
    all_digits = log10(1 ./ T.error);
    yl = [min(all_digits) - 0.5, max(all_digits) + 0.5];

    all_budgets = T.b_sz .* T.num_matmuls;
    budget_lim = [min(all_budgets) * 0.7, max(all_budgets) * 1.4];

    all_times = T.duration_us / 1e6;
    time_lim = [min(all_times) * 0.7, max(all_times) * 1.4];

    ax_list = findobj(gcf, 'Type', 'axes');
    for a = 1:numel(ax_list)
        ylim(ax_list(a), yl);
    end

    % Apply uniform x-axis: top row = budget, bottom row = time
    n_cols = 3 - ~has_rsvd;
    tl = gcf().Children(end);  % the tiledlayout
    for idx = 1:(2 * n_cols)
        ax = nexttile(tl, idx);
        if idx <= n_cols
            xlim(ax, budget_lim);
        else
            xlim(ax, time_lim);
            set_log2_ticks(ax);  % recompute ticks after uniform xlim
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

    if meta.input_matrix ~= ""
        [~, fname, fext] = fileparts(meta.input_matrix);
        sgtitle([fname fext], 'FontSize', 20, 'Interpreter', 'none');
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
        budget = sub.b_sz .* sub.num_matmuls;
        digits = log10(1 ./ sub.error);
        ci = min(i, size(colors, 1));
        mk = markers{min(i, numel(markers))};
        plot(budget, digits, mk, 'Color', colors(ci,:), ...
             'MarkerFaceColor', colors(ci,:), 'MarkerSize', 10, 'LineWidth', 1.5);
    end
    % Set x-ticks to actual budget values used
    all_budgets = rows.b_sz .* rows.num_matmuls;
    tick_vals = sort(unique(all_budgets));
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
    % Use log base-2 ticks for time axis
    set_log2_ticks(gca);
end

%% -----------------------------------------------------------------------
function plot_spectra_budget(T, color)
    rows = T(T.algorithm == "SVDS", :);
    if isempty(rows), return; end
    hold on; grid on;

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
    % Set x-ticks to actual budget values
    set(gca, 'XScale', 'log', 'XTick', budget_u, 'XTickLabel', arrayfun(@num2str, budget_u, 'UniformOutput', false), 'FontSize', 14);
    xtickangle(45);
end

%% -----------------------------------------------------------------------
function plot_spectra_time(T, color)
    rows = T(T.algorithm == "SVDS", :);
    if isempty(rows), return; end
    hold on; grid on;

    rows = sortrows(rows, 'duration_us');
    time_s = rows.duration_us / 1e6;
    digits = log10(1 ./ rows.error);

    % Deduplicate: keep best per unique time bucket
    [time_u, ~, ic] = unique(round(time_s, 2));
    digits_u = zeros(size(time_u));
    for i = 1:numel(time_u)
        digits_u(i) = max(digits(ic == i));
    end

    plot(time_u, digits_u, '-p', 'Color', color, ...
         'MarkerFaceColor', color, 'MarkerSize', 10, 'LineWidth', 1.5);
    set(gca, 'XScale', 'log', 'FontSize', 14);
    % Use log base-2 ticks for time axis
    set_log2_ticks(gca);
end

%% -----------------------------------------------------------------------
function set_log2_ticks(ax)
    % Set tick marks at powers of 2 on a log-scale axis
    xl = xlim(ax);
    lo = floor(log2(xl(1)));
    hi = ceil(log2(xl(2)));
    ticks = 2.^(lo:hi);
    % Also include half-powers if range is small
    if hi - lo <= 3
        ticks = 2.^(lo:0.5:hi);
    end
    ticks = ticks(ticks >= xl(1) & ticks <= xl(2));
    labels = arrayfun(@(v) sprintf('%.3g', v), ticks, 'UniformOutput', false);
    set(ax, 'XTick', ticks, 'XTickLabel', labels);
end
