%{
Option A: Convergence Profile — scatter plot of accuracy vs time.

All algorithms overlaid on a single plot:
  X = time (seconds, log scale)
  Y = digits of accuracy (log10(1/error))
  ABRIK: blue markers, one shape per b_sz
  RSVD:  red markers, one shape per p
  SVDS:  green star
  GESDD: black hexagon (reference)

Usage:
  abrik_convergence_profile('path/to/file.csv')
%}
function abrik_convergence_profile(filename)
    [T, meta] = parse_abrik_csv(filename);
    T = select_best_runs(T);

    figure('Position', [100 100 900 600]);
    hold on; grid on;

    markers_abrik = {'o', 'd', 's', '^', 'v', '+', '*'};
    markers_rsvd  = {'o', 'd', 's', '^', 'v', '+', '*'};
    legend_entries = {};
    legend_handles = [];

    % ---- ABRIK ----
    abrik_rows = T(T.algorithm == "ABRIK", :);
    unique_bsz = unique(abrik_rows.b_sz);
    for i = 1:numel(unique_bsz)
        bsz = unique_bsz(i);
        mask = abrik_rows.b_sz == bsz;
        sub = abrik_rows(mask, :);
        digits = log10(1 ./ sub.error);
        time_s = sub.duration_us / 1e6;

        valid = digits >= 0.5;
        mk = markers_abrik{min(i, numel(markers_abrik))};
        h = scatter(time_s(valid), digits(valid), 120, 'b', mk, 'filled', ...
                    'MarkerEdgeColor', 'b', 'LineWidth', 1.2);
        if any(valid)
            legend_handles(end+1) = h;
            legend_entries{end+1} = sprintf('ABRIK b=%d', bsz);
        end
    end

    % ---- RSVD ----
    rsvd_rows = T(T.algorithm == "RSVD", :);
    unique_p = unique(rsvd_rows.p);
    for i = 1:numel(unique_p)
        pval = unique_p(i);
        mask = rsvd_rows.p == pval;
        sub = rsvd_rows(mask, :);
        digits = log10(1 ./ sub.error);
        time_s = sub.duration_us / 1e6;

        valid = digits >= 0.5;
        mk = markers_rsvd{min(i, numel(markers_rsvd))};
        h = scatter(time_s(valid), digits(valid), 120, 'r', mk, 'filled', ...
                    'MarkerEdgeColor', 'r', 'LineWidth', 1.2);
        if any(valid)
            legend_handles(end+1) = h;
            legend_entries{end+1} = sprintf('RSVD p=%d', pval);
        end
    end

    % ---- SVDS ----
    svds_rows = T(T.algorithm == "SVDS", :);
    if ~isempty(svds_rows)
        digits = log10(1 ./ svds_rows.error);
        time_s = svds_rows.duration_us / 1e6;
        h = scatter(time_s, digits, 200, 'g', 'p', 'filled', ...
                    'MarkerEdgeColor', [0 0.5 0], 'LineWidth', 1.5);
        legend_handles(end+1) = h;
        legend_entries{end+1} = 'SVDS';
    end

    % ---- GESDD ----
    gesdd_rows = T(T.algorithm == "GESDD", :);
    if ~isempty(gesdd_rows)
        digits = log10(1 ./ gesdd_rows.error);
        time_s = gesdd_rows.duration_us / 1e6;
        h = scatter(time_s, digits, 200, 'k', 'h', 'filled', ...
                    'MarkerEdgeColor', 'k', 'LineWidth', 1.5);
        legend_handles(end+1) = h;
        legend_entries{end+1} = 'GESDD';
    end

    set(gca, 'XScale', 'log');
    xlabel('Time (seconds)', 'FontSize', 18);
    ylabel('Digits of accuracy', 'FontSize', 18);
    ax = gca; ax.FontSize = 16;

    if ~isempty(legend_handles)
        legend(legend_handles, legend_entries, 'Location', 'northwest', ...
               'FontSize', 13, 'NumColumns', 2);
    end

    if meta.input_matrix ~= ""
        title(meta.input_matrix, 'FontSize', 18, 'Interpreter', 'none');
    end
end
