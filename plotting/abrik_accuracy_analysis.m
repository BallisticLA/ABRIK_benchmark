function [] = abrik_accuracy_analysis(csv_path, options)
    arguments
        csv_path = ''
        options.CreateFigure (1,1) logical = true
        options.ShowLabels (1,1) logical = true
    end
% ABRIK_ACCURACY_ANALYSIS  Plot per-triplet accuracy metrics from
% ABRIK_accuracy_analysis benchmark output.
%
% Produces a semilogy plot with three series:
%   1. Per-triplet SVD residual for ABRIK (blue circles)
%   2. Relative singular value difference (yellow crosses)
%   3. Singular vector angular difference via QR-based sin(angle) (purple diamonds)
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
% Options:
%   'CreateFigure' — true (default) creates a new figure; false plots into current axes
%   'ShowLabels'   — true (default) shows axis labels and title; false omits them (for paper)
%
% Usage:
%   abrik_accuracy_analysis('path/to/ABRIK_accuracy_analysis.csv')
%   abrik_accuracy_analysis('...', 'ShowLabels', false)  % paper-ready (no labels/title)
%   abrik_accuracy_analysis()  % opens file picker

    if nargin < 1
        [f, p] = uigetfile('*.csv', 'Select ABRIK accuracy analysis CSV');
        if isequal(f, 0), return; end
        csv_path = fullfile(p, f);
    end

    % --- Parse metadata from # comment lines ---
    fid = fopen(csv_path, 'r');
    b_sz = 0; num_matmuls = 0; num_runs = 1;
    input_matrix = ''; input_size = '';
    while true
        line = fgetl(fid);
        if ~startsWith(line, '#'), break; end
        if contains(line, 'b_sz:')
            b_sz = sscanf(line, '# b_sz: %d');
        elseif contains(line, 'num_matmuls:')
            num_matmuls = sscanf(line, '# num_matmuls: %d');
        elseif contains(line, 'Num runs:')
            tok = regexp(line, 'Num runs:\s*(\d+)', 'tokens');
            if ~isempty(tok), num_runs = str2double(tok{1}{1}); end
        elseif contains(line, 'Input matrix:')
            input_matrix = strtrim(extractAfter(line, 'Input matrix:'));
        elseif contains(line, 'Input size:')
            input_size = strtrim(extractAfter(line, 'Input size:'));
        end
    end
    fclose(fid);

    % Extract matrix name from path
    [~, mat_name, ~] = fileparts(input_matrix);

    % --- Read data (auto-detect legacy 5-col vs new 6-col layout) ---
    T_raw = readtable(csv_path, 'CommentStyle', '#');
    if width(T_raw) == 6
        % New: run, i, res_err_abrik, res_err_gesdd, sval_diff, svec_diff
        T_raw.Properties.VariableNames = {'run', 'i', 'res_err_abrik', ...
                                          'res_err_gesdd', 'sval_diff', 'svec_diff'};
    else
        % Legacy: i, res_err_abrik, res_err_gesdd, sval_diff, svec_diff
        T_raw.Properties.VariableNames = {'i', 'res_err_abrik', 'res_err_gesdd', ...
                                          'sval_diff', 'svec_diff'};
        T_raw.run = zeros(height(T_raw), 1);
    end

    % Aggregate across runs: median per triplet i.
    % For single-run (legacy) CSVs this is a no-op.
    [G, i_unique] = findgroups(T_raw.i);
    T = table(i_unique, ...
              splitapply(@median, T_raw.res_err_abrik, G), ...
              splitapply(@median, T_raw.res_err_gesdd, G), ...
              splitapply(@median, T_raw.sval_diff,    G), ...
              splitapply(@median, T_raw.svec_diff,    G), ...
              'VariableNames', {'i', 'res_err_abrik', 'res_err_gesdd', ...
                                'sval_diff', 'svec_diff'});

    x = T.i;
    num_triplets = length(x);

    % Replace exact zeros with NaN so semilogy skips them gracefully
    % (log(0) = -inf causes gaps; NaN produces a clean break in the line).
    T.sval_diff(T.sval_diff == 0)       = NaN;
    T.svec_diff(T.svec_diff == 0)       = NaN;
    T.res_err_abrik(T.res_err_abrik == 0) = NaN;

    % Total matvecs per run (for figure title, replacing the matmuls label).
    total_matvecs = b_sz * num_matmuls;

    % --- Plot ---
    colors = [ ...
        0.00 0.45 0.74;   % blue
        0.93 0.69 0.13;   % yellow/gold
        0.49 0.18 0.56;   % purple
    ];

    if options.CreateFigure
        fig_name = sprintf('%s (b_{sz} = %d, matvecs = %d)', mat_name, b_sz, total_matvecs);
        figure('Name', fig_name, 'NumberTitle', 'off', ...
               'Position', [100 100 1400 500]);
    end

    semilogy(x, T.res_err_abrik,  '-o', 'Color', colors(1,:), 'MarkerSize', 4, 'LineWidth', 1.5);
    hold on
    semilogy(x, T.sval_diff,      '-x', 'Color', colors(2,:), 'MarkerSize', 5, 'LineWidth', 1.5);
    semilogy(x, T.svec_diff,      '-d', 'Color', colors(3,:), 'MarkerSize', 4, 'LineWidth', 1.5);
    hold off

    ax = gca;
    ax.XAxis.FontSize = 16;
    ax.YAxis.FontSize = 16;
    grid on

    xlim([1 num_triplets]);

    if options.ShowLabels
        ylabel('accuracy', 'FontSize', 18);
        xlabel('i', 'FontSize', 18);
        if num_runs > 1
            title(sprintf('ABRIK results (b_{sz} = %d, matvecs = %d, median over %d runs)', ...
                          b_sz, total_matvecs, num_runs), 'FontSize', 18);
        else
            title(sprintf('ABRIK results (b_{sz} = %d, matvecs = %d)', ...
                          b_sz, total_matvecs), 'FontSize', 18);
        end
    end

    lgd = legend({ ...
        'standard computable error', ...
        'Singular value error', ...
        'singular vector errors' ...
        }, ...
        'NumColumns', 1, ...
        'Location', 'southeast' ...
    );
    lgd.FontSize = 14;
end
