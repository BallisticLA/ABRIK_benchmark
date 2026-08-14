%{
Generates the "Wishart lower bound" hard instance for the ABRIK hard-instance
appendix. The singular values follow

    sigma_i = sqrt(1 - (i/n)^2),   i = 1..n,

which approximates the spectrum of I - (1/(5n)) G'G for square Gaussian G, and
is used as a rank-1 low-rank-approximation lower-bound instance by Bakshi,
Clarkson & Woodruff (STOC 2022). The leading singular values are essentially
flat at 1 with no spectral gap, which is the adversarial case for any
matrix-vector-query low-rank-approximation method: ABRIK, Spectra SVD, and RSVD
are all expected to plateau well above machine precision on it.

The construction A = (U .* sigma) * V' matches gen_mat_alg971_paper.m, so the
output drops straight into the ABRIK speed / accuracy benchmarks.

Usage:
  gen_mat_wishart_lower_bound(1000, 'generate')
  gen_mat_wishart_lower_bound(1000, 'generate', 'WriteBinary', true)
  gen_mat_wishart_lower_bound(1000, 'plot')

Arguments:
  n               — matrix dimension (square; paper uses 1000)
  operation_mode  — "generate" to build and write, "plot" to read & plot spectrum

Optional name-value:
  WriteBinary (false) — write .bin (int64 header [m n] then m*n doubles,
                        row-major) instead of .txt, matching read_bin_matrix in
                        ext_matrix_io.hh. Faster and smaller for large n.

Output is saved to:
  ../../matrices/wishart_lb_<n>/
%}
function gen_mat_wishart_lower_bound(n, operation_mode, options)
    arguments
        n                   (1,1) double
        operation_mode      (1,1) string
        options.WriteBinary (1,1) logical = false
    end

    script_dir = fileparts(mfilename('fullpath'));
    file_path  = fullfile(fileparts(fileparts(script_dir)), 'matrices', "wishart_lb_" + n);
    if ~exist(file_path, 'dir'), mkdir(file_path); end

    % sigma_i = sqrt(1 - (i/n)^2), descending; sigma_n = 0 (rank-deficient by one).
    sigma = sqrt(max(0, 1 - ((1:n) / n).^2));

    if operation_mode == "generate"
        % Random orthonormal bases; the hardness lives entirely in the (gapless)
        % spectrum, so U and V are arbitrary orthonormal factors.
        [U, ~] = qr(randn(n), 0);
        [V, ~] = qr(randn(n), 0);

        S_file = fullfile(file_path, "Spectrum_wishart.txt");
        if options.WriteBinary
            A_file = fullfile(file_path, "ABRIK_test_wishart.bin");
            fid = fopen(A_file, 'wb');
            if fid == -1, error('Cannot open file for writing: %s', A_file); end
            fwrite(fid, int64([n, n]), 'int64');
            A = (U .* sigma) * V';
            fwrite(fid, A', 'double');   % A' col-major = A row-major
            fclose(fid);
        else
            A_file = fullfile(file_path, "ABRIK_test_wishart.txt");
            writematrix((U .* sigma) * V', A_file, 'Delimiter', ' ');
        end
        writematrix(sigma, S_file, 'Delimiter', ' ');
        fprintf("Wishart lower-bound instance (n=%d) written to %s\n", n, file_path);

    elseif operation_mode == "plot"
        sigma = readmatrix(fullfile(file_path, "Spectrum_wishart.txt"));
    end

    semilogy(1:n, sigma, '-', 'LineWidth', 1.8);
    grid on;
    xlabel('i'); ylabel('\sigma_i');
    title(sprintf('Wishart lower-bound spectrum (n=%d)', n));
end
