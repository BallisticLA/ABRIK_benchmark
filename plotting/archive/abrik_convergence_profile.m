%{
Convergence Profile — accuracy vs time for all algorithms.

Each ABRIK block_size is a connected curve (one point per num_matmuls).
RSVD is shown per block size similarly.
SVDS is a single curve (single-vector Lanczos — b_sz only affects budget,
not the algorithm), so we merge all SVDS rows by time.

  X = time (seconds, log scale)
  Y = digits of accuracy (log10(1/error))

Usage:
  abrik_convergence_profile('path/to/file.csv')
  abrik_convergence_profile(T, meta)               % pre-parsed data
%}
function abrik_convergence_profile(arg1, arg2)
    if nargin == 2 && istable(arg1)
        T = arg1;  meta = arg2;
    else
        [T, meta] = parse_abrik_csv(arg1);
    end
    T = select_best_runs(T);

    hold on; grid on;

    % Color palette for block sizes
    abrik_colors = [0.00 0.45 0.74;   % blue
                    0.30 0.75 0.93;   % light blue
                    0.00 0.00 0.55;   % dark blue
                    0.49 0.18 0.56];  % purple
    rsvd_colors  = [0.85 0.33 0.10;   % orange
                    1.00 0.60 0.20;   % light orange
                    0.70 0.20 0.00;   % dark orange
                    0.80 0.50 0.30];  % tan
    markers_abrik = {'o', 'd', 's', '^', 'v', '+', '*'};
    markers_rsvd  = {'s', 'd', '^', 'v', 'o', '+', '*'};

    legend_entries = {};
    legend_handles = [];

    % ---- ABRIK: one connected curve per block size ----
    abrik_rows = T(T.algorithm == "ABRIK", :);
    unique_bsz = unique(abrik_rows.b_sz);
    for i = 1:numel(unique_bsz)
        bsz = unique_bsz(i);
        sub = abrik_rows(abrik_rows.b_sz == bsz, :);
        sub = sortrows(sub, 'num_matmuls');
        digits = log10(1 ./ sub.error);
        time_s = sub.duration_us / 1e6;

        ci = min(i, size(abrik_colors, 1));
        mk = markers_abrik{min(i, numel(markers_abrik))};
        h = plot(time_s, digits, ['-' mk], ...
                 'Color', abrik_colors(ci, :), 'MarkerFaceColor', abrik_colors(ci, :), ...
                 'MarkerSize', 10, 'LineWidth', 1.8);
        legend_handles(end+1) = h;
        legend_entries{end+1} = sprintf('ABRIK b=%d', bsz);
    end

    % ---- RSVD: one connected curve per block size ----
    rsvd_rows = T(T.algorithm == "RSVD", :);
    if ~isempty(rsvd_rows)
        unique_bsz_rsvd = unique(rsvd_rows.b_sz);
        for i = 1:numel(unique_bsz_rsvd)
            bsz = unique_bsz_rsvd(i);
            sub = rsvd_rows(rsvd_rows.b_sz == bsz, :);
            sub = sortrows(sub, 'num_matmuls');
            digits = log10(1 ./ sub.error);
            time_s = sub.duration_us / 1e6;

            ci = min(i, size(rsvd_colors, 1));
            mk = markers_rsvd{min(i, numel(markers_rsvd))};
            h = plot(time_s, digits, ['-' mk], ...
                     'Color', rsvd_colors(ci, :), 'MarkerFaceColor', rsvd_colors(ci, :), ...
                     'MarkerSize', 10, 'LineWidth', 1.8);
            legend_handles(end+1) = h;
            legend_entries{end+1} = sprintf('RSVD b=%d', bsz);
        end
    end

    % ---- SVDS: single curve (merge all b_sz, sort by time) ----
    svds_rows = T(T.algorithm == "SVDS", :);
    if ~isempty(svds_rows)
        svds_rows = sortrows(svds_rows, 'duration_us');
        digits = log10(1 ./ svds_rows.error);
        time_s = svds_rows.duration_us / 1e6;

        h = plot(time_s, digits, '-p', ...
                 'Color', [0 0.5 0], 'MarkerFaceColor', [0 0.5 0], ...
                 'MarkerSize', 10, 'LineWidth', 1.8);
        legend_handles(end+1) = h;
        legend_entries{end+1} = 'SVDS';
    end

    % ---- GESDD: single reference point ----
    gesdd_rows = T(T.algorithm == "GESDD", :);
    if ~isempty(gesdd_rows)
        digits = log10(1 ./ gesdd_rows.error);
        time_s = gesdd_rows.duration_us / 1e6;
        h = scatter(mean(time_s), mean(digits), 200, 'k', 'p', 'filled', ...
                    'MarkerEdgeColor', 'k', 'LineWidth', 1.5);
        legend_handles(end+1) = h;
        legend_entries{end+1} = sprintf('GESDD (%.1fs)', mean(time_s));
    end

    set(gca, 'XScale', 'log');
    xlabel('Time (seconds)', 'FontSize', 18);
    ylabel('Digits of accuracy', 'FontSize', 18);
    ax = gca; ax.FontSize = 16;

    if ~isempty(legend_handles)
        legend(legend_handles, legend_entries, 'Location', 'northwest', 'FontSize', 13);
    end

    if meta.input_matrix ~= ""
        title(meta.input_matrix, 'FontSize', 18, 'Interpreter', 'none');
    end
end
