%{
Generates and/or plots the six test matrices from the Algorithm 971 paper.

Usage:
  gen_mat_alg971_paper(10000, 5000, 50, 499, 'generate')
  gen_mat_alg971_paper(10000, 5000, 50, 499, 'plot')
  gen_mat_alg971_paper(100000, 100000, 5000, 4999, 'generate', 'WriteBinary', true)

Arguments:
  m                 — number of rows
  n                 — number of columns (and spectrum length)
  low_rank          — rank parameter k used by generators 2–5 (can equal n for full rank)
  plotting_interval — stride for spectrum plot (e.g. 49, 499, 4999)
  operation_mode    — "generate" to build matrices, "plot" to read & plot

Optional name-value:
  WriteBinary (false) — write .bin instead of .txt. Format: int64 header [m n]
                        then m*n doubles row-major. Much faster for large matrices
                        (fwrite, no number-to-string conversion, ~8x smaller files).
                        Requires ABRIK benchmark from winter-2025-abrik-clean branch;
                        ext_matrix_io.hh auto-detects .bin and calls read_bin_matrix.
  BlockRows   (2000)  — rows computed per block (WriteBinary only). Avoids forming
                        the full m×n matrix; only one (BlockRows × n) slice allocated
                        at a time.

Output is saved to:
  ../input_matrices/<m>x<n>_rank_<low_rank>/
%}
function gen_mat_alg971_paper(m, n, low_rank, plotting_interval, operation_mode, options)
    arguments
        m                   (1,1) double
        n                   (1,1) double
        low_rank            (1,1) double
        plotting_interval   (1,1) double
        operation_mode      (1,1) string
        options.WriteBinary (1,1) logical = false
        options.BlockRows   (1,1) double  = 2000
    end

    script_dir = fileparts(mfilename('fullpath'));
    base_dir   = fullfile(script_dir, '..', 'input_matrices');
    sub_dir    = sprintf("%dx%d_rank_%d", m, n, low_rank);
    file_path  = fullfile(base_dir, sub_dir);
    if ~exist(file_path, 'dir')
        mkdir(file_path);
    end

    if operation_mode == "generate"

        U = randn(m, n);
        [U, ~] = qr(U, 0);
        V = randn(n, n);
        [V, ~] = qr(V, 0);

        Sigma = zeros(6, n);
        Sigma(1, :) = gen_mat_1(n);
        Sigma(2, :) = gen_mat_2(n, low_rank);
        Sigma(3, :) = gen_mat_3(n, low_rank);
        Sigma(4, :) = gen_mat_4(n, low_rank);
        Sigma(5, :) = gen_mat_5(n, low_rank);
        Sigma(6, :) = sort(abs(randn(1, n)), 'descend');

        for i = 1:size(Sigma, 1)
            S_file = fullfile(file_path, "Spectrum_mat" + i + ".txt");

            if options.WriteBinary
                A_file = fullfile(file_path, "ABRIK_test_mat" + i + ".bin");
                write_binary_blocked(A_file, U, Sigma(i, :), V', options.BlockRows);
            else
                A_file = fullfile(file_path, "ABRIK_test_mat" + i + ".txt");
                % writematrix is faster than fprintf-based alternatives for text output.
                % U .* Sigma scales each column of U by the corresponding singular value,
                % avoiding an n-by-n diagonal matrix allocation.
                writematrix((U .* Sigma(i, :)) * V', A_file, 'Delimiter', ' ');
            end

            writematrix(Sigma(i, :), S_file, 'Delimiter', ' ');
            fprintf("Matrix %d processed\n", i);
        end

    elseif operation_mode == "plot"
        Sigma = zeros(6, n);
        for i = 1:6
            Sigma(i, :) = readmatrix(fullfile(file_path, "Spectrum_mat" + i + ".txt"));
        end
    end

    plot_spectra(Sigma, n, plotting_interval, file_path);
end

%% -----------------------------------------------------------------------
function write_binary_blocked(filename, U, sigma, Vt, block_rows)
% Write A = (U .* sigma) * Vt as binary: int64 header [m n] then m*n
% doubles in row-major order. Full matrix A is never formed — only one
% block of block_rows rows is allocated at a time.
%
% fwrite(Ablock', 'double') writes Ablock' column-major = Ablock row-major,
% matching the layout expected by read_bin_matrix in rl_matrix_io.hh.

    [m, n] = size(U);
    fid = fopen(filename, 'wb');
    if fid == -1
        error('Cannot open file for writing: %s', filename);
    end
    fwrite(fid, int64([m, n]), 'int64');

    for j1 = 1 : block_rows : m
        j2     = min(j1 + block_rows - 1, m);
        Ablock = bsxfun(@times, U(j1:j2, :), sigma) * Vt;  % (j2-j1+1) × n
        fwrite(fid, Ablock', 'double');  % Ablock' col-major = Ablock row-major
    end

    fclose(fid);
end

%% -----------------------------------------------------------------------
function plot_spectra(Sigma, n, plotting_interval, file_path)
    markers = {'-+', '-o', '-s', '-^', '-v', '-diamond'};
    x = 1:plotting_interval:n;

    for i = 1:size(Sigma, 1)
        semilogy(x, Sigma(i, 1:plotting_interval:end), markers{i}, ...
                 'MarkerSize', 18, 'LineWidth', 1.8);
        hold on;
    end

    grid on;
    lgd = legend('Mat 1', 'Mat 2', 'Mat 3', 'Mat 4', 'Mat 5', 'Mat 6', ...
                 'NumColumns', 2, 'Location', 'northeastoutside');
    lgd.FontSize = 20;
    ax = gca;
    ax.XAxis.FontSize = 20;
    ax.YAxis.FontSize = 20;
    xticks(round(linspace(0, n, 6)));

    saveas(gcf, fullfile(file_path, 'generated_matrices_spectra_plots.fig'));
end

%% -----------------------------------------------------------------------
function Sigma = gen_mat_1(n)
    Sigma = 1 ./ (1:n);
end

%% -----------------------------------------------------------------------
function Sigma = gen_mat_2(n, k)
    j = 1:n;
    Sigma = 1e-5 * (k + 1) ./ j;
    Sigma(1) = 1;
    Sigma(2:k) = 2e-5;
end

%% -----------------------------------------------------------------------
function Sigma = gen_mat_3(n, k)
    j = 1:n;
    Sigma = 1e-5 * (k + 1) ./ j;
    Sigma(1:k) = 10 .^ (-5 * ((1:k) - 1) / (k - 1));
end

%% -----------------------------------------------------------------------
function Sigma = gen_mat_4(n, k)
    Sigma = zeros(1, n);
    Sigma(1:k) = 10 .^ (-5 * ((1:k) - 1) / (k - 1));
    if k < n
        Sigma(k + 1) = 1e-5;
    end
end

%% -----------------------------------------------------------------------
function Sigma = gen_mat_5(n, k)
    j = 1:n;
    Sigma = 1e-5 * sqrt((k + 1) ./ j);
    Sigma(1:k) = 1e-5 + (1 - 1e-5) * (k - (1:k)) / (k - 1);
end
