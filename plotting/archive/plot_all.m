%{
Master plotting script — generates all ABRIK benchmark figures.

Auto-discovers all timestamped CSVs in the results/ directory and
generates two plot types per speed-comparison CSV:
  1. Convergence profile  (scatter: time vs digits, all algorithms overlaid)
  2. Per-algorithm grid   (2x3 dense or 2x2 sparse, parameter + time rows)

Usage:
  run('/home/mymel/data/ABRIK_benchmark/plotting/plot_all.m')

  % Or with options:
  results_path = '/home/mymel/data/ABRIK_benchmark/results';
  save_figures = true;   % set to true to save PNGs
  run('plot_all.m')
%}

script_dir  = fileparts(mfilename('fullpath'));
repo_root   = fileparts(script_dir);

if ~exist('results_path', 'var')
    results_path = fullfile(repo_root, 'results');
end
if ~exist('save_figures', 'var')
    save_figures = false;
end

addpath(script_dir);

%% ---- Auto-discover speed comparison CSVs ----
speed_files = dir(fullfile(results_path, '*_speed_comparisons*.csv'));

fprintf('=== ABRIK Benchmark Plots ===\n');
fprintf('Results directory: %s\n', results_path);
fprintf('Found %d speed-comparison CSV(s)\n\n', numel(speed_files));

for k = 1:numel(speed_files)
    csv_path = fullfile(speed_files(k).folder, speed_files(k).name);
    fprintf('[%d/%d] %s\n', k, numel(speed_files), speed_files(k).name);

    [T, meta] = parse_abrik_csv(csv_path);
    label = speed_files(k).name;

    % 1. Convergence profile
    fig1 = figure('Name', [label ' — Convergence Profile'], ...
                  'Position', [100 100 900 600]);
    abrik_convergence_profile(T, meta);
    if save_figures
        exportgraphics(fig1, fullfile(results_path, ...
            strrep(label, '.csv', '_convergence.png')), 'Resolution', 200);
    end
    drawnow;

    % 2. Per-algorithm grid (adaptive 2x3 or 2x2)
    is_sparse = ~any(T.algorithm == "RSVD");
    if is_sparse
        fig2 = figure('Name', [label ' — Per-Algorithm Grid'], ...
                      'Position', [100 100 1000 700]);
    else
        fig2 = figure('Name', [label ' — Per-Algorithm Grid'], ...
                      'Position', [100 100 1400 700]);
    end
    abrik_precision_vs_speedup_v2(T, meta);
    if save_figures
        exportgraphics(fig2, fullfile(results_path, ...
            strrep(label, '.csv', '_grid.png')), 'Resolution', 200);
    end
    drawnow;

    fprintf('       Generated 2 figures.\n');
end

fprintf('\n=== Done ===\n');
fprintf('    %d speed-comparison CSVs x 2 plots each = %d figures\n', ...
    numel(speed_files), 2 * numel(speed_files));
