%{
Plots ABRIK runtime breakdown as a stacked bar chart.

Usage:
  abrik_runtime_breakdown('path/to/_ABRIK_runtime_breakdown.csv')
  abrik_runtime_breakdown('path/to/file.csv', 'BlockSize', 8)

All benchmark parameters (block sizes, matmul counts, runs per config,
input matrix name) are parsed from the '#'-prefixed metadata header.

Optional name-value arguments:
  'BlockSize'  — which Krylov block size to display (default: first from data)
  'ShowLabels' — show axis labels and titles (default: true)

Output: single stacked bar chart showing percentage of total runtime
  per ABRIK component for each matmul count at the selected block size.

CSV columns (15 total, produced by ABRIK_runtime_breakdown.cc):
  1: b_sz, 2: num_matmuls,
  3: allocation_t, 4: get_factors_t, 5: ungqr_t, 6: reorth_t,
  7: qr_t, 8: gemm_A_t, 9: main_loop_t, 10: sketching_t,
  11: r_cpy_t, 12: s_cpy_t, 13: norm_t, 14: t_rest, 15: total_t.
%}
function abrik_runtime_breakdown(filename, options)
    arguments
        filename           string
        options.BlockSize  (1,1) double  = 0
        options.ShowLabels (1,1) logical = true
    end

    % ---- Parse metadata from '#'-prefixed header lines ----
    [num_b_sizes, num_matmul_sizes, num_runs, matrix_name] = parse_metadata(filename);

    % ---- Read numeric data (readmatrix skips '#' lines and text header) ----
    Data_in = readmatrix(filename, 'CommentStyle', '#');

    % Pick fastest run per (b_sz, num_matmuls) configuration — done once.
    Data = select_best_runs(Data_in, num_b_sizes, num_matmul_sizes, num_runs);

    % ---- Determine which block size to show ----
    b_sizes = unique(Data(:, 1));
    if options.BlockSize == 0
        b_sz_show = b_sizes(1);
    else
        b_sz_show = options.BlockSize;
        assert(ismember(b_sz_show, b_sizes), ...
            'BlockSize %d not found in data. Available: %s', ...
            b_sz_show, mat2str(b_sizes'));
    end

    % Filter to the selected block size.
    Data = Data(Data(:, 1) == b_sz_show, :);
    num_rows = size(Data, 1);

    % ---- Compute percentages of total time (col 15) ----
    % Breakdown categories (column → percentage of total_t):
    %   3:  allocation_t    → "Data Alloc"
    %   4:  get_factors_t   → "SVD+Factors"
    %   5:  ungqr_t         → "ORGQR"
    %   6:  reorth_t        → "Reorth"
    %   7:  qr_t            → "QR"
    %   8:  gemm_A_t        → "GEMM(M)"
    %   10+11+12+13+14      → "Other" (sketching + copies + norm + rest)
    % Column 9 (main_loop_t) is excluded — it's the aggregate of 3–8.
    total = Data(:, 15);
    Pct = zeros(num_rows, 7);
    Pct(:, 1) = 100 * Data(:, 3)           ./ total;  % Data Alloc
    Pct(:, 2) = 100 * Data(:, 4)           ./ total;  % SVD+Factors
    Pct(:, 3) = 100 * Data(:, 5)           ./ total;  % ORGQR
    Pct(:, 4) = 100 * Data(:, 6)           ./ total;  % Reorth
    Pct(:, 5) = 100 * Data(:, 7)           ./ total;  % QR
    Pct(:, 6) = 100 * Data(:, 8)           ./ total;  % GEMM(M)
    Pct(:, 7) = 100 * sum(Data(:, 10:14), 2) ./ total;  % Other

    % ---- Plot stacked bar chart ----
    colors = {'b', 'r', 'g', 'm', 'c', 'k', [0.5, 0.5, 0.5]};
    bplot = bar(Pct, 'stacked');
    for k = 1:numel(colors)
        bplot(k).FaceColor = colors{k};
        bplot(k).FaceAlpha = 0.8;
    end

    % X-axis: #singular triplets = b_sz * num_matmuls / 2.
    set(gca, 'XTickLabel', Data(:, 1) .* Data(:, 2) ./ 2);

    % ---- Legend & axis formatting ----
    lgd = legend('Data Alloc', 'SVD+Factors', 'ORGQR', 'Reorth', ...
                 'QR', 'GEMM(M)', 'Other', 'Location', 'northeastoutside');
    lgd.FontSize = 20;

    ylim([0 100]);
    ax = gca;
    ax.FontSize = 23;

    if options.ShowLabels
        title(['ABRIK Runtime Breakdown  b\_sz = ' num2str(b_sz_show)], 'FontSize', 20);
        ylabel('Runtime %', 'FontSize', 20);
        xlabel('#triplets', 'FontSize', 20);
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
% Expected lines (produced by ABRIK_runtime_breakdown.cc):
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
function Data_out = select_best_runs(Data_in, num_b_sizes, num_matmul_sizes, num_runs)
% For each (b_sz, num_matmuls) configuration, keep the run with the
% fastest total time (col 15).  All breakdown columns come from the same
% run to keep percentages self-consistent.
%
% Input:  (num_b_sizes * num_matmul_sizes * num_runs) x 15 matrix.
% Output: (num_b_sizes * num_matmul_sizes)            x 15 matrix.

    num_configs = num_b_sizes * num_matmul_sizes;
    num_cols    = size(Data_in, 2);
    Data_out    = zeros(num_configs, num_cols);

    for cfg = 1:num_configs
        rows  = (cfg - 1) * num_runs + 1 : cfg * num_runs;
        block = Data_in(rows, :);

        % Pick the run with the shortest nonzero total_t (col 15).
        nonzero = block(:, 15) > 0;
        if any(nonzero)
            valid = block(nonzero, :);
            [~, best] = min(valid(:, 15));
            Data_out(cfg, :) = valid(best, :);
        else
            Data_out(cfg, :) = block(1, :);
        end
    end
end
