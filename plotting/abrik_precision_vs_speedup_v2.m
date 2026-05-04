%{
Paper-ready convergence plot: 2x1 layout (single column, two rows).

  Row 1: digits of accuracy vs total matrix-vector products
  Row 2: digits of accuracy vs wall-clock time (seconds)

Six curves per subplot:
  - ABRIK b=4, 8, 16, 32  (4 curves)
  - Spectra               (1 curve)
  - RSVD (largest b_sz)   (1 curve)

The reader traces horizontally at a target accuracy to compare which method
reaches it with fewer matvecs / less wall time.

Usage:
  abrik_precision_vs_speedup_v2('path/to/file.csv')
  abrik_precision_vs_speedup_v2(T, meta)               % pre-parsed table
  abrik_precision_vs_speedup_v2(T, meta, 'Parent', tab) % embed in uitab
%}
function abrik_precision_vs_speedup_v2(arg1, arg2, nvargs)
    arguments
        arg1
        arg2 = []
        nvargs.Parent = []
    end
    if ~isempty(arg2) && istable(arg1)
        T = arg1;  meta = arg2;
    else
        [T, meta] = parse_abrik_csv(arg1);
    end

    parent = nvargs.Parent;
    if isempty(parent), parent = gcf; end

    % 2x1 layout: row 1 = matvecs, row 2 = time
    tl = tiledlayout(parent, 2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');

    % Colorblind-safe Wong palette
    colors = [0.00 0.45 0.70;   % blue      — b=4
              0.90 0.60 0.00;   % orange    — b=8
              0.00 0.62 0.45;   % green     — b=16
              0.80 0.40 0.00;   % vermillon — b=32
              0.35 0.70 0.90;   % sky blue  (unused for ABRIK)
              0.80 0.60 0.70];  % purple    (unused)
    markers  = {'-o', '-s', '-^', '-d'};
    spectra_color = [0.00 0.00 0.00];  % black
    rsvd_color    = [0.80 0.60 0.70];  % reddish purple

    abrik_bsizes = unique(T.b_sz(T.method == "ABRIK"));
    rsvd_bsizes  = unique(T.b_sz(T.method == "RSVD"));
    largest_rsvd_b = max(rsvd_bsizes);

    % ---- Row 1: digits vs total matvecs ----
    ax1 = nexttile(tl);
    hold(ax1, 'on'); grid(ax1, 'on');
    plot_all_curves(ax1, T, abrik_bsizes, largest_rsvd_b, ...
                    colors, markers, spectra_color, rsvd_color, 'matvecs');
    ylabel(ax1, 'Digits of accuracy', 'FontSize', 14);
    xlabel(ax1, 'Matrix-vector products', 'FontSize', 14);
    set(ax1, 'XScale', 'log', 'FontSize', 13);

    % ---- Row 2: digits vs wall-clock time ----
    ax2 = nexttile(tl);
    hold(ax2, 'on'); grid(ax2, 'on');
    [h_handles, leg_labels] = plot_all_curves(ax2, T, abrik_bsizes, largest_rsvd_b, ...
                    colors, markers, spectra_color, rsvd_color, 'time');
    ylabel(ax2, 'Digits of accuracy', 'FontSize', 14);
    xlabel(ax2, 'Time (s)', 'FontSize', 14);
    set(ax2, 'XScale', 'log', 'FontSize', 13);

    % Shared legend on bottom subplot
    legend(ax2, h_handles, leg_labels, 'Location', 'southeast', 'FontSize', 11);

    % Uniform y-axis (digits) across both subplots
    all_err = T.err(T.err > 0 & isfinite(T.err));
    if ~isempty(all_err)
        yl = [max(-0.5, min(log10(1 ./ all_err)) - 0.5), ...
              max(log10(1 ./ all_err)) + 0.5];
        ylim(ax1, yl); ylim(ax2, yl);
    end

    % Figure title
    title_parts = {};
    if meta.input_matrix ~= ""
        [~, fname, ~] = fileparts(meta.input_matrix);
        title_parts{end+1} = fname;
    end
    if meta.input_size ~= ""
        title_parts{end+1} = meta.input_size;
    end
    title_parts{end+1} = ternary(meta.is_sparse, 'sparse', 'dense');
    if meta.budget > 0
        title_parts{end+1} = sprintf('budget=%d mv', meta.budget);
    end
    title(tl, strjoin(title_parts, '  |  '), 'FontSize', 14, 'Interpreter', 'none');
end

%% -----------------------------------------------------------------------
function [handles, labels] = plot_all_curves(ax, T, abrik_bsizes, largest_rsvd_b, ...
                                              colors, markers, spectra_color, rsvd_color, mode)
% Plots all 6 curves on ax. mode = 'matvecs' or 'time'.
% Returns handle array and label cell for the legend.
    handles = gobjects(numel(abrik_bsizes) + 2, 1);
    labels  = cell(numel(abrik_bsizes) + 2, 1);

    for i = 1:numel(abrik_bsizes)
        b = abrik_bsizes(i);
        rows = T(T.method == "ABRIK" & T.b_sz == b, :);
        rows = sortrows(rows, 'total_matvecs');
        [x, y] = curve_xy(rows, mode);
        ci = min(i, size(colors, 1));
        mk = markers{min(i, numel(markers))};
        handles(i) = plot(ax, x, y, mk, 'Color', colors(ci,:), ...
                          'MarkerFaceColor', colors(ci,:), 'MarkerSize', 8, 'LineWidth', 1.5);
        labels{i} = sprintf('ABRIK b=%d', b);
    end

    % Spectra
    rows = T(T.method == "Spectra", :);
    rows = sortrows(rows, 'total_matvecs');
    [x, y] = curve_xy(rows, mode);
    n_abrik = numel(abrik_bsizes);
    handles(n_abrik + 1) = plot(ax, x, y, '-p', 'Color', spectra_color, ...
                                'MarkerFaceColor', spectra_color, 'MarkerSize', 8, 'LineWidth', 1.5);
    labels{n_abrik + 1} = 'Spectra';

    % RSVD (largest block size)
    rows = T(T.method == "RSVD" & T.b_sz == largest_rsvd_b, :);
    rows = sortrows(rows, 'total_matvecs');
    [x, y] = curve_xy(rows, mode);
    handles(n_abrik + 2) = plot(ax, x, y, '--v', 'Color', rsvd_color, ...
                                'MarkerFaceColor', rsvd_color, 'MarkerSize', 8, 'LineWidth', 1.5);
    labels{n_abrik + 2} = sprintf('RSVD b=%d', largest_rsvd_b);
end

%% -----------------------------------------------------------------------
function [x, y] = curve_xy(rows, mode)
% Returns (x, y) for a convergence curve. Skips rows with err <= 0 or non-finite.
    mask = rows.err > 0 & isfinite(rows.err);
    rows = rows(mask, :);
    y = log10(1 ./ rows.err);
    if strcmp(mode, 'matvecs')
        x = double(rows.total_matvecs);
    else
        x = double(rows.elapsed_us) / 1e6;  % microseconds -> seconds
    end
end

%% -----------------------------------------------------------------------
function v = ternary(cond, a, b)
    if cond, v = a; else, v = b; end
end
