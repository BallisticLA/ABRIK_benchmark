%{
Plots the results of the ABRIK_speed_comparisons_sparse benchmark.

Usage:
  abrik_precision_vs_speedup_sparse('path/to/_ABRIK_speed_comparisons_sparse.csv')
  abrik_precision_vs_speedup_sparse('path/to/file.csv', 'PlotAllBlockSizes', false)

All benchmark parameters (block sizes, matmul counts, runs per config,
input matrix name) are parsed from the '#'-prefixed metadata header.

Optional name-value arguments:
  'PlotAllBlockSizes' — plot every block size, not just odd-indexed (default: true)
  'ShowLabels'        — show axis labels and titles (default: true)

Output: 2x2 subplot grid.
  Top row:    digits of accuracy vs #singular triplets (ABRIK, SVDS)
  Bottom row: digits of accuracy vs time in seconds    (ABRIK, SVDS)
%}
function abrik_precision_vs_speedup_sparse(filename, options)
    arguments
        filename           string
        options.PlotAllBlockSizes (1,1) logical = true
        options.ShowLabels        (1,1) logical = true
    end

    % ---- Parse metadata from '#'-prefixed header lines ----
    [num_b_sizes, num_matmul_sizes, num_runs, matrix_name] = parse_metadata(filename);

    % ---- Read numeric data (readmatrix skips '#' lines and text header) ----
    Data_in = readmatrix(filename, 'CommentStyle', '#');

    % Pick fastest run per (b_sz, num_matmuls) configuration — done once.
    Data = select_best_runs(Data_in, num_b_sizes, num_matmul_sizes, num_runs);

    % Algorithm timing-column indices: ABRIK=5, SVDS=7.
    % Each algorithm occupies 2 columns: err, dur.
    % Error column = timing_col - 1.
    ALG_COLS = [5 7];

    tiledlayout(2, 2, "TileSpacing", "loose");

    for mode = ["num_triplets", "wall_clock"]
        for col = ALG_COLS
            nexttile;
            plot_algorithm(Data, num_matmul_sizes, col, mode, ...
                           options.PlotAllBlockSizes, options.ShowLabels);
        end
    end

    % Figure supertitle from the input matrix name.
    if matrix_name ~= ""
        sgtitle(matrix_name, 'FontSize', 22, 'Interpreter', 'none');
    end
end

%% -----------------------------------------------------------------------
function [num_b_sizes, num_matmul_sizes, num_runs, matrix_name] = parse_metadata(filename)
% Reads '#'-prefixed header lines and extracts benchmark parameters.
%
% Expected lines (produced by ABRIK_speed_comparisons_sparse.cc):
%   # Input matrix: /path/to/matrix.mtx
%   # Krylov block sizes: 2, 4, 8, 16,
%   # Matmul counts: 4, 8, 16, 32,
%   # Runs per configuration: 3

    num_b_sizes      = 0;
    num_matmul_sizes = 0;
    num_runs         = 0;
    matrix_name      = "";

    fid = fopen(filename, 'r');
    cleanup = onCleanup(@() fclose(fid));

    while ~feof(fid)
        line = fgetl(fid);
        if ~startsWith(line, '#')
            break;  % Past the metadata header.
        end
        if contains(line, 'Input matrix:')
            tokens = regexp(line, 'Input matrix:\s*(.*)', 'tokens');
            matrix_name = strtrim(tokens{1}{1});
        elseif contains(line, 'Krylov block sizes:')
            num_b_sizes = count_csv_values(line);
        elseif contains(line, 'Matmul counts:')
            num_matmul_sizes = count_csv_values(line);
        elseif contains(line, 'Runs per configuration:')
            tokens = regexp(line, 'Runs per configuration:\s*(\d+)', 'tokens');
            num_runs = str2double(tokens{1}{1});
        end
    end

    assert(num_b_sizes > 0,      'Could not parse "Krylov block sizes" from metadata.');
    assert(num_matmul_sizes > 0,  'Could not parse "Matmul counts" from metadata.');
    assert(num_runs > 0,          'Could not parse "Runs per configuration" from metadata.');
end

%% -----------------------------------------------------------------------
function n = count_csv_values(line)
% Counts comma-separated numeric values after the colon in a metadata line.
% Handles trailing comma: "# Krylov block sizes: 2, 4, 8, 16, " → 4.
    after_colon = regexp(line, ':\s*(.*)', 'tokens');
    vals = strsplit(strtrim(after_colon{1}{1}), ',');
    vals = vals(strtrim(vals) ~= "");  % Drop empty tokens from trailing comma.
    n = numel(vals);
end

%% -----------------------------------------------------------------------
function plot_algorithm(Data, num_matmul_sizes, alg_col, plot_mode, plot_all_b_sz, show_labels)
% Plots one subplot: digits of accuracy vs #triplets or wall-clock time.
%   alg_col  — timing column (5=ABRIK, 7=SVDS).
%   Error column is alg_col - 1.

    markers = {'-o', '-diamond', '-s', '-^', '-v', '-+', '-*'};
    x_min   = Inf;
    x_max   = 0;
    all_tics = unique(Data(:, 2) .* Data(:, 1) ./ 2);
    err_col = alg_col - 1;  % Error column for this algorithm.

    % ---- Data plotting ----
    if alg_col == 7
        % SVDS has no block-size concept: different b_sz runs targeting the
        % same #triplets ideally produce identical results.  Deduplicate.
        num_triplets = Data(:, 1) .* Data(:, 2) ./ 2;
        err_vec      = Data(:, err_col);
        dur_vec      = Data(:, alg_col);
        unique_b_sz  = unique(Data(:, 1));

        [~, uid]     = unique(num_triplets, 'first');
        num_triplets = num_triplets(uid);
        err_vec      = err_vec(uid);
        dur_vec      = dur_vec(uid);

        digits = log10(1 ./ err_vec);
        valid  = digits >= 1;
        num_triplets = num_triplets(valid);
        digits       = digits(valid);
        dur_vec      = dur_vec(valid);

        % Placeholder lines for block-size legend entries.
        legend_entries = cell(1, numel(unique_b_sz) + 1);
        for idx = 1:numel(unique_b_sz)
            semilogx(NaN, NaN, markers{idx}, 'MarkerSize', 18, 'LineWidth', 1.8);
            hold on;
            legend_entries{idx} = ['b=' num2str(unique_b_sz(idx))];
        end

        % Plot SVDS line.
        if isempty(digits)
            semilogx(NaN, NaN, '-*', 'Color', 'black', 'MarkerSize', 18, 'LineWidth', 1.8);
        elseif plot_mode == "wall_clock"
            x_vec = dur_vec ./ 1e6;
            semilogx(x_vec, digits, '-*', 'Color', 'black', 'MarkerSize', 18, 'LineWidth', 1.8);
            x_max = max(x_max, max(x_vec));
            x_min = min(x_min, min(x_vec));
        else
            semilogx(num_triplets, digits, '-*', 'Color', 'black', 'MarkerSize', 18, 'LineWidth', 1.8);
        end

        legend_entries{end} = 'SVDS';
        if plot_mode == "num_triplets"
            lgd = legend(legend_entries, 'Location', 'southwest', 'NumColumns', 2);
            lgd.FontSize = 15;
        end
    else
        % ABRIK: one line per block size.
        b_idx = 0;
        for i = 1:num_matmul_sizes:size(Data, 1)
            b_idx = b_idx + 1;
            rows  = i:(i + num_matmul_sizes - 1);

            if plot_mode == "wall_clock"
                x_vec = Data(rows, alg_col) ./ 1e6;
            else
                x_vec = Data(rows, 2) .* Data(rows, 1) ./ 2;
            end
            digits = log10(1 ./ Data(rows, err_col));

            % Discard results below 1 digit of accuracy.
            valid  = digits >= 1;
            digits = digits(valid);
            x_vec  = x_vec(valid);

            if ~isempty(x_vec)
                x_max = max(x_max, max(x_vec));
                x_min = min(x_min, min(x_vec));
            end

            if mod(b_idx, 2) ~= 0 || plot_all_b_sz
                if isempty(digits)
                    semilogx(NaN, NaN, markers{b_idx}, 'MarkerSize', 18, 'LineWidth', 1.8);
                else
                    semilogx(x_vec, digits, markers{b_idx}, 'MarkerSize', 18, 'LineWidth', 1.8);
                end
                hold on;
            end
        end
    end

    % ---- Axis labels & titles ----
    if show_labels
        if alg_col == 5
            ylabel('Digits of accuracy', 'FontSize', 20);
        end
        if plot_mode == "num_triplets"
            switch alg_col
                case 5, title('RandLAPACK ABRIK', 'FontSize', 20);
                case 7, title('Spectra SVDS',      'FontSize', 20);
            end
            xlabel('#triplets found', 'FontSize', 20);
        else
            xlabel('Time (s)', 'FontSize', 20);
        end
    end

    % ---- Tick & limit formatting ----
    xtickangle(45);
    if alg_col ~= 5
        set(gca, 'Yticklabel', []);
    end

    if plot_mode == "num_triplets"
        odd_tics = all_tics(1:2:end);
        xticks(odd_tics);
        xlim([min(odd_tics) max(all_tics)]);
    elseif plot_mode == "wall_clock" && isfinite(x_min) && isfinite(x_max)
        tick_vals = [0.01 0.02 0.05 0.1 0.2 0.5 1 2 5 10 20 50 100 200 500 1000];
        lo = max(tick_vals(tick_vals < x_min));
        hi = min(tick_vals(tick_vals > x_max));
        if ~isempty(lo) && ~isempty(hi)
            xlim([lo hi]);
        end
        xticks(tick_vals);
    end

    grid on;
    ax = gca;
    ax.XAxis.FontSize = 20;
    ax.YAxis.FontSize = 20;
    ylim([1 16]);
    yticks([0 1 5 10 15]);
end

%% -----------------------------------------------------------------------
function Data_out = select_best_runs(Data_in, num_b_sizes, num_matmul_sizes, num_runs)
% For each (b_sz, num_matmuls) configuration, keep the run with the
% fastest timing per algorithm.
%
% Input:  (num_b_sizes * num_matmul_sizes * num_runs) x 7 matrix.
% Output: (num_b_sizes * num_matmul_sizes)            x 7 matrix.

    num_configs = num_b_sizes * num_matmul_sizes;
    num_cols    = size(Data_in, 2);
    Data_out    = zeros(num_configs, num_cols);

    % Algorithm timing columns: ABRIK=5, SVDS=7.
    % Each algorithm occupies 2 columns (err, dur).
    timing_cols = [5, 7];

    for cfg = 1:num_configs
        rows  = (cfg - 1) * num_runs + 1 : cfg * num_runs;
        block = Data_in(rows, :);

        % Metadata columns (identical across runs of the same configuration).
        Data_out(cfg, 1:3) = block(1, 1:3);

        % For each algorithm, pick the run with the shortest nonzero timing.
        for tc = timing_cols
            ec = tc - 1;  % Error column for this algorithm.
            nonzero = block(:, tc) > 0;
            if any(nonzero)
                valid = block(nonzero, :);
                [~, best] = min(valid(:, tc));
                Data_out(cfg, ec:tc) = valid(best, ec:tc);
            else
                Data_out(cfg, ec:tc) = block(1, ec:tc);
            end
        end
    end
end
