function [] = abrik_accuracy_analysis(csv_path)
% ABRIK_ACCURACY_ANALYSIS  Plot per-triplet accuracy metrics from
% ABRIK_accuracy_analysis benchmark output.
%
% Produces a semilogy plot with four series:
%   1. Per-triplet SVD residual for ABRIK (blue circles)
%   2. Per-triplet SVD residual for GESDD (red squares) — baseline at O(eps)
%   3. Relative singular value difference (yellow crosses)
%   4. Singular vector angular difference via QR-based sin(angle) (purple diamonds)
%
% The residual metric uses the "correct" a-posteriori error estimator:
%   sqrt(||E_left||^2 + ||E_right||^2)
% where E_left = inv(s_i)*A*v_i - u_i,  E_right = v_i - A^T*u_i*inv(s_i).
% This can be driven to machine precision (unlike the Sigma-scaled variant).
%
% The svec_diff metric uses sin(angle) computed via Householder QR of [x1, x2],
% avoiding the catastrophic cancellation in sqrt(1 - cos^2(theta)) that would
% floor at sqrt(eps) ~ 1e-8 for well-converged triplets.
%
% Usage:
%   abrik_accuracy_analysis('path/to/ABRIK_accuracy_analysis.csv')
%   abrik_accuracy_analysis()  % opens file picker

    if nargin < 1
        [f, p] = uigetfile('*.csv', 'Select ABRIK accuracy analysis CSV');
        if isequal(f, 0), return; end
        csv_path = fullfile(p, f);
    end

    % --- Parse metadata from # comment lines ---
    fid = fopen(csv_path, 'r');
    b_sz = 0; num_matmuls = 0; input_matrix = ''; input_size = '';
    while true
        line = fgetl(fid);
        if ~startsWith(line, '#'), break; end
        if contains(line, 'b_sz:')
            b_sz = sscanf(line, '# b_sz: %d');
        elseif contains(line, 'num_matmuls:')
            num_matmuls = sscanf(line, '# num_matmuls: %d');
        elseif contains(line, 'Input matrix:')
            input_matrix = strtrim(extractAfter(line, 'Input matrix:'));
        elseif contains(line, 'Input size:')
            input_size = strtrim(extractAfter(line, 'Input size:'));
        end
    end
    fclose(fid);

    % Extract matrix name from path
    [~, mat_name, ~] = fileparts(input_matrix);

    % --- Read data ---
    T = readtable(csv_path, 'CommentStyle', '#');
    T.Properties.VariableNames = {'i', 'res_err_abrik', 'res_err_gesdd', ...
                                  'sval_diff', 'svec_diff'};

    x = T.i;
    num_triplets = length(x);

    % Replace exact zeros with NaN so semilogy skips them gracefully
    % (log(0) = -inf causes gaps; NaN produces a clean break in the line).
    T.sval_diff(T.sval_diff == 0)       = NaN;
    T.svec_diff(T.svec_diff == 0)       = NaN;
    T.res_err_abrik(T.res_err_abrik == 0) = NaN;
    T.res_err_gesdd(T.res_err_gesdd == 0) = NaN;

    % --- Plot ---
    colors = [ ...
        0.00 0.45 0.74;   % blue
        0.85 0.33 0.10;   % red/orange
        0.93 0.69 0.13;   % yellow/gold
        0.49 0.18 0.56;   % purple
    ];

    fig_name = sprintf('%s (b_{sz} = %d, matmuls = %d)', mat_name, b_sz, num_matmuls);
    figure('Name', fig_name, 'NumberTitle', 'off', ...
           'Position', [100 100 1400 500]);

    semilogy(x, T.res_err_abrik,  '-o', 'Color', colors(1,:), 'MarkerSize', 4, 'LineWidth', 1.5);
    hold on
    semilogy(x, T.res_err_gesdd,  '-s', 'Color', colors(2,:), 'MarkerSize', 4, 'LineWidth', 1.5);
    semilogy(x, T.sval_diff,      '-x', 'Color', colors(3,:), 'MarkerSize', 5, 'LineWidth', 1.5);
    semilogy(x, T.svec_diff,      '-d', 'Color', colors(4,:), 'MarkerSize', 4, 'LineWidth', 1.5);
    hold off

    ax = gca;
    ax.XAxis.FontSize = 16;
    ax.YAxis.FontSize = 16;
    grid on

    xlim([1 num_triplets]);
    ylabel('accuracy', 'FontSize', 18);
    xlabel('i', 'FontSize', 18);
    title(sprintf('ABRIK results (b_{sz} = %d, matmuls = %d)', b_sz, num_matmuls), ...
          'FontSize', 18);

    lgd = legend({ ...
        'residual\_abrik:  sqrt(||E_L||^2 + ||E_R||^2)', ...
        'residual\_gesdd', ...
        'sval\_diff:  |\sigma_{abrik} - \sigma_{gesdd}| / \sigma_1', ...
        'svec\_diff:  \sqrt{(sin^2\angle(u) + sin^2\angle(v))/2}' ...
        }, ...
        'NumColumns', 1, ...
        'Location', 'northeastoutside' ...
    );
    lgd.FontSize = 14;
end
