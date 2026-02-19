%{
Option C: Improved 2x3 grid — same layout as original but with
independent parameter sweeps per algorithm.

  Columns: ABRIK, RSVD, SVDS
  Row 1:   digits vs parameter (#triplets for ABRIK, p for RSVD, single point for SVDS)
  Row 2:   digits vs time (seconds)

Key improvements over v1:
  - RSVD sweeps its own p values instead of inheriting ABRIK's grid
  - SVDS is a single accurate point (nev=target_rank) instead of a wasteful sweep

Usage:
  abrik_precision_vs_speedup_v2('path/to/file.csv')
%}
function abrik_precision_vs_speedup_v2(filename)
    [T, meta] = parse_abrik_csv(filename);
    T = select_best_runs(T);

    figure('Position', [100 100 1400 700]);
    tiledlayout(2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

    % ---- Row 1: digits vs parameter ----

    % ABRIK: digits vs #triplets (b_sz * num_matmuls / 2)
    nexttile;
    plot_abrik_param(T);
    title('ABRIK', 'FontSize', 18);
    ylabel('Digits of accuracy', 'FontSize', 16);
    xlabel('#triplets', 'FontSize', 16);

    % RSVD: digits vs p
    nexttile;
    plot_rsvd_param(T);
    title('RSVD', 'FontSize', 18);
    xlabel('Power iterations (p)', 'FontSize', 16);

    % SVDS: single point
    nexttile;
    plot_svds_param(T);
    title('SVDS', 'FontSize', 18);
    xlabel('nev = target\_rank', 'FontSize', 16);

    % ---- Row 2: digits vs time ----

    % ABRIK: digits vs time
    nexttile;
    plot_abrik_time(T);
    ylabel('Digits of accuracy', 'FontSize', 16);
    xlabel('Time (s)', 'FontSize', 16);

    % RSVD: digits vs time
    nexttile;
    plot_rsvd_time(T);
    xlabel('Time (s)', 'FontSize', 16);

    % SVDS: digits vs time
    nexttile;
    plot_svds_time(T);
    xlabel('Time (s)', 'FontSize', 16);

    if meta.input_matrix ~= ""
        sgtitle(meta.input_matrix, 'FontSize', 20, 'Interpreter', 'none');
    end
end

%% -----------------------------------------------------------------------
function plot_abrik_param(T)
    markers = {'-o', '-d', '-s', '-^', '-v', '-+', '-*'};
    rows = T(T.algorithm == "ABRIK", :);
    unique_bsz = unique(rows.b_sz);
    hold on; grid on;

    for i = 1:numel(unique_bsz)
        bsz = unique_bsz(i);
        sub = rows(rows.b_sz == bsz, :);
        triplets = sub.b_sz .* sub.num_matmuls / 2;
        digits = log10(1 ./ sub.error);
        mk = markers{min(i, numel(markers))};
        plot(triplets, digits, mk, 'MarkerSize', 10, 'LineWidth', 1.5);
    end

    if ~isempty(unique_bsz)
        lgd = legend(arrayfun(@(b) sprintf('b=%d', b), unique_bsz, 'UniformOutput', false), ...
                     'Location', 'southeast', 'FontSize', 11);
    end
    set(gca, 'FontSize', 14);
    ylim_auto();
end

%% -----------------------------------------------------------------------
function plot_rsvd_param(T)
    rows = T(T.algorithm == "RSVD", :);
    hold on; grid on;

    if ~isempty(rows)
        digits = log10(1 ./ rows.error);
        plot(rows.p, digits, '-o', 'MarkerSize', 10, 'LineWidth', 1.5, ...
             'Color', [0.85 0.33 0.10], 'MarkerFaceColor', [0.85 0.33 0.10]);
    end
    set(gca, 'FontSize', 14);
    ylim_auto();
end

%% -----------------------------------------------------------------------
function plot_svds_param(T)
    rows = T(T.algorithm == "SVDS", :);
    hold on; grid on;

    if ~isempty(rows)
        digits = log10(1 ./ rows.error);
        nev = rows.target_rank(1);
        scatter(nev, mean(digits), 200, [0.47 0.67 0.19], 'p', 'filled', ...
                'MarkerEdgeColor', [0 0.5 0], 'LineWidth', 1.5);
    end
    set(gca, 'FontSize', 14);
    ylim_auto();
end

%% -----------------------------------------------------------------------
function plot_abrik_time(T)
    markers = {'-o', '-d', '-s', '-^', '-v', '-+', '-*'};
    rows = T(T.algorithm == "ABRIK", :);
    unique_bsz = unique(rows.b_sz);
    hold on; grid on;

    for i = 1:numel(unique_bsz)
        bsz = unique_bsz(i);
        sub = rows(rows.b_sz == bsz, :);
        time_s = sub.duration_us / 1e6;
        digits = log10(1 ./ sub.error);
        mk = markers{min(i, numel(markers))};
        semilogx(time_s, digits, mk, 'MarkerSize', 10, 'LineWidth', 1.5);
    end
    set(gca, 'XScale', 'log', 'FontSize', 14);
    ylim_auto();
end

%% -----------------------------------------------------------------------
function plot_rsvd_time(T)
    rows = T(T.algorithm == "RSVD", :);
    hold on; grid on;

    if ~isempty(rows)
        time_s = rows.duration_us / 1e6;
        digits = log10(1 ./ rows.error);
        semilogx(time_s, digits, '-o', 'MarkerSize', 10, 'LineWidth', 1.5, ...
                 'Color', [0.85 0.33 0.10], 'MarkerFaceColor', [0.85 0.33 0.10]);
    end
    set(gca, 'XScale', 'log', 'FontSize', 14);
    ylim_auto();
end

%% -----------------------------------------------------------------------
function plot_svds_time(T)
    rows = T(T.algorithm == "SVDS", :);
    hold on; grid on;

    if ~isempty(rows)
        time_s = rows.duration_us / 1e6;
        digits = log10(1 ./ rows.error);
        scatter(time_s, mean(digits), 200, [0.47 0.67 0.19], 'p', 'filled', ...
                'MarkerEdgeColor', [0 0.5 0], 'LineWidth', 1.5);
    end
    set(gca, 'XScale', 'log', 'FontSize', 14);
    ylim_auto();
end

%% -----------------------------------------------------------------------
function ylim_auto()
% Set a reasonable y-axis range for digits of accuracy.
    yl = ylim;
    ylim([max(0, yl(1) - 0.5), min(16, yl(2) + 0.5)]);
end
