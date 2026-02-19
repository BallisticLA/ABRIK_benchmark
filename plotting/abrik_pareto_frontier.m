%{
Option B: Pareto Frontier — minimum time to reach each accuracy level.

For each algorithm, sweeps over digit levels (0.5 step) and finds the
fastest configuration that achieves >= that accuracy.

  X = target accuracy (digits)
  Y = minimum time to reach it (seconds, log scale)
  One curve per algorithm (ABRIK, RSVD, SVDS)
  GESDD as horizontal reference line

Usage:
  abrik_pareto_frontier('path/to/file.csv')
%}
function abrik_pareto_frontier(filename)
    [T, meta] = parse_abrik_csv(filename);
    T = select_best_runs(T);

    figure('Position', [100 100 900 600]);
    hold on; grid on;

    legend_entries = {};
    legend_handles = [];

    % Define accuracy levels to probe
    digit_levels = 0.5:0.5:16;

    % ---- ABRIK Pareto ----
    abrik_rows = T(T.algorithm == "ABRIK", :);
    if ~isempty(abrik_rows)
        [d, t] = compute_pareto(abrik_rows, digit_levels);
        if ~isempty(d)
            h = semilogy(d, t, '-o', 'Color', [0 0.45 0.74], ...
                         'MarkerSize', 10, 'LineWidth', 2, 'MarkerFaceColor', [0 0.45 0.74]);
            legend_handles(end+1) = h;
            legend_entries{end+1} = 'ABRIK';
        end
    end

    % ---- RSVD Pareto ----
    rsvd_rows = T(T.algorithm == "RSVD", :);
    if ~isempty(rsvd_rows)
        [d, t] = compute_pareto(rsvd_rows, digit_levels);
        if ~isempty(d)
            h = semilogy(d, t, '-s', 'Color', [0.85 0.33 0.10], ...
                         'MarkerSize', 10, 'LineWidth', 2, 'MarkerFaceColor', [0.85 0.33 0.10]);
            legend_handles(end+1) = h;
            legend_entries{end+1} = 'RSVD';
        end
    end

    % ---- SVDS Pareto ----
    svds_rows = T(T.algorithm == "SVDS", :);
    if ~isempty(svds_rows)
        [d, t] = compute_pareto(svds_rows, digit_levels);
        if ~isempty(d)
            h = semilogy(d, t, '-^', 'Color', [0.47 0.67 0.19], ...
                         'MarkerSize', 10, 'LineWidth', 2, 'MarkerFaceColor', [0.47 0.67 0.19]);
            legend_handles(end+1) = h;
            legend_entries{end+1} = 'SVDS';
        end
    end

    % ---- GESDD reference line ----
    gesdd_rows = T(T.algorithm == "GESDD", :);
    if ~isempty(gesdd_rows)
        gesdd_time = gesdd_rows.duration_us(1) / 1e6;
        h = yline(gesdd_time, '--k', 'LineWidth', 2);
        legend_handles(end+1) = h;
        legend_entries{end+1} = sprintf('GESDD (%.2fs)', gesdd_time);
    end

    xlabel('Target accuracy (digits)', 'FontSize', 18);
    ylabel('Minimum time to reach accuracy (s)', 'FontSize', 18);
    ax = gca; ax.FontSize = 16;

    if ~isempty(legend_handles)
        legend(legend_handles, legend_entries, 'Location', 'northeast', 'FontSize', 14);
    end

    if meta.input_matrix ~= ""
        title(meta.input_matrix, 'FontSize', 18, 'Interpreter', 'none');
    end
end

%% -----------------------------------------------------------------------
function [digits_out, times_out] = compute_pareto(rows, digit_levels)
% For each digit level, find the fastest configuration that achieves it.
    digits_all = log10(1 ./ rows.error);
    times_all  = rows.duration_us / 1e6;

    digits_out = [];
    times_out  = [];

    for d = digit_levels
        mask = digits_all >= d;
        if any(mask)
            digits_out(end+1) = d;
            times_out(end+1) = min(times_all(mask));
        end
    end
end
