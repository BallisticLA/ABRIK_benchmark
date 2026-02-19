%{
Generates and/or plots the six test matrices from the Algorithm 971 paper.

Usage:
  gen_mat_alg971_paper(10000, 5000, 50, 499, 'generate')
  gen_mat_alg971_paper(10000, 5000, 50, 499, 'plot')

Arguments:
  m                 — number of rows
  n                 — number of columns (and spectrum length)
  low_rank          — rank parameter k used by generators 2–5 (can equal n for full rank)
  plotting_interval — stride for spectrum plot (e.g. 49, 499, 4999)
  operation_mode    — "generate" to build matrices, "plot" to read & plot

Output is saved to:
  /home/mymel/data/ABRIK/input_matrices/<m>x<n>_rank_<low_rank>/
%}
function gen_mat_alg971_paper(m, n, low_rank, plotting_interval, operation_mode)

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
            A_file = fullfile(file_path, "ABRIK_test_mat" + i + ".txt");
            S_file = fullfile(file_path, "Spectrum_mat"   + i + ".txt");

            writematrix(U * diag(Sigma(i, :)) * V', A_file, 'Delimiter', ' ');
            writematrix(Sigma(i, :),                 S_file, 'Delimiter', ' ');
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
function plot_spectra(Sigma, n, plotting_interval, file_path)
% Plots all six spectra on a single semilog axis.

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
% sigma_j = 1/j.
    Sigma = 1 ./ (1:n);
end

%% -----------------------------------------------------------------------
function Sigma = gen_mat_2(n, k)
% sigma_1 = 1, sigma_2..k = 2e-5, sigma_{k+1..n} = 1e-5*(k+1)/j.
    j = 1:n;
    Sigma = 1e-5 * (k + 1) ./ j;
    Sigma(1) = 1;
    Sigma(2:k) = 2e-5;
end

%% -----------------------------------------------------------------------
function Sigma = gen_mat_3(n, k)
% Exponential decay to rank k, then 1e-5*(k+1)/j tail.
    j = 1:n;
    Sigma = 1e-5 * (k + 1) ./ j;
    Sigma(1:k) = 10 .^ (-5 * ((1:k) - 1) / (k - 1));
end

%% -----------------------------------------------------------------------
function Sigma = gen_mat_4(n, k)
% Exponential decay to rank k, sigma_{k+1} = 1e-5, then zeros.
    Sigma = zeros(1, n);
    Sigma(1:k) = 10 .^ (-5 * ((1:k) - 1) / (k - 1));
    if k < n
        Sigma(k + 1) = 1e-5;
    end
end

%% -----------------------------------------------------------------------
function Sigma = gen_mat_5(n, k)
% Linear decay to rank k, then 1e-5*sqrt((k+1)/j) tail.
    j = 1:n;
    Sigma = 1e-5 * sqrt((k + 1) ./ j);
    Sigma(1:k) = 1e-5 + (1 - 1e-5) * (k - (1:k)) / (k - 1);
end
