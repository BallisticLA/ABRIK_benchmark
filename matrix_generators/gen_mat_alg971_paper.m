%{
Generates and/or plots the six test matrices from the Algorithm 971 paper.

Usage:
  gen_mat_alg971_paper(10000, 5000, 50, 499, 'generate')
  gen_mat_alg971_paper(10000, 5000, 50, 499, 'plot')
  gen_mat_alg971_paper(100000, 100000, 5000, 4999, 'generate', 'BlockRows', 1000)

Arguments:
  m                 — number of rows
  n                 — number of columns (and spectrum length)
  low_rank          — rank parameter k used by generators 2–5
  plotting_interval — stride for spectrum plot (e.g. 49, 499, 4999)
  operation_mode    — "generate" to build matrices, "plot" to read & plot

Optional name-value:
  BlockRows         — rows per write block (default 2000). Controls peak
                      memory usage: full A is never formed; only one block
                      of size BlockRows×n is held at a time. Tune down for
                      tight RAM, up for fewer fwrite calls.

Output is saved to:
  ../input_matrices/<m>x<n>_rank_<low_rank>/

Write path: row-blocked GEMM + sprintf/fwrite (much faster than writematrix
for large matrices). Format is unchanged: space-separated rows, so the C++
reader in rl_gen.hh::process_input_mat works without modification.
%}
function gen_mat_alg971_paper(m, n, low_rank, plotting_interval, operation_mode, options)
    arguments
        m                 (1,1) double
        n                 (1,1) double
        low_rank          (1,1) double
        plotting_interval (1,1) double
        operation_mode    (1,1) string
        options.BlockRows (1,1) double = 2000
    end

    script_dir = fileparts(mfilename('fullpath'));
    base_dir   = fullfile(script_dir, '..', 'input_matrices');
    sub_dir    = sprintf("%dx%d_rank_%d", m, n, low_rank);
    file_path  = fullfile(base_dir, sub_dir);
    if ~exist(file_path, 'dir')
        mkdir(file_path);
    end

    if operation_mode == "generate"

        fprintf('Generating U (%d x %d) ...\n', m, n);
        U = randn(m, n);
        [U, ~] = qr(U, 0);

        fprintf('Generating V (%d x %d) ...\n', n, n);
        V = randn(n, n);
        [V, ~] = qr(V, 0);

        % Precompute V' once — reused for all 6 matrices.
        Vt = V';

        Sigma = zeros(6, n);
        Sigma(1, :) = gen_mat_1(n);
        Sigma(2, :) = gen_mat_2(n, low_rank);
        Sigma(3, :) = gen_mat_3(n, low_rank);
        Sigma(4, :) = gen_mat_4(n, low_rank);
        Sigma(5, :) = gen_mat_5(n, low_rank);
        Sigma(6, :) = sort(abs(randn(1, n)), 'descend');

        for i = 1:size(Sigma, 1)
            A_file = fullfile(file_path, "ABRIK_test_mat" + i + ".txt");
            S_file = fullfile(file_path, "Spectrum_mat"   + i + ".txt");

            fprintf('Writing matrix %d to %s ...\n', i, A_file);
            write_matrix_blocked(A_file, U, Sigma(i, :), Vt, options.BlockRows);
            writematrix(Sigma(i, :), S_file, 'Delimiter', ' ');
            fprintf('Matrix %d done.\n', i);
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
function write_matrix_blocked(filename, U, sigma, Vt, block_rows)
% Write A = (U .* sigma) * Vt to a space-separated text file, one row per
% line.  A is never formed in full — only one block of block_rows rows is
% allocated at a time.
%
% sprintf + fwrite is ~5-10x faster than writematrix for large matrices
% because it builds the whole text block in memory and issues one write.

    [m, n] = size(U);

    % Pre-build format string for one row: "v1 v2 ... vn\n"
    fmt_row = [repmat('%.17g ', 1, n - 1), '%.17g\n'];

    fid = fopen(filename, 'w');
    if fid == -1
        error('Cannot open file for writing: %s', filename);
    end

    for j1 = 1 : block_rows : m
        j2 = min(j1 + block_rows - 1, m);
        B  = j2 - j1 + 1;

        % Compute this block of rows: (B x n) = (B x n) .* sigma  *  (n x n)
        % Fuse scale + GEMM to avoid a separate B×n allocation for US.
        Ablock = bsxfun(@times, U(j1:j2, :), sigma) * Vt;  % B × n

        % Build text for all B rows at once.
        % repmat(fmt_row, 1, B) gives a format for B*n values.
        % Ablock' is n × B column-major, so sprintf reads it row-by-row of Ablock.
        str = sprintf(repmat(fmt_row, 1, B), Ablock');
        fwrite(fid, str, 'char');
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
