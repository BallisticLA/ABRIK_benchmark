%{
Selects the best (fastest) run per configuration from benchmark data.

Groups rows by (algorithm, b_sz, num_matmuls, p), keeps the row with
minimum duration_us per group.

Usage:
  T_best = select_best_runs(T)

Input:  table from parse_abrik_csv with columns:
        algorithm, b_sz, num_matmuls, p, target_rank, error, duration_us
Output: table with one row per unique configuration (fastest run).
%}
function T_best = select_best_runs(T)
    % Create a grouping key from (algorithm, b_sz, num_matmuls, p)
    keys = strcat(T.algorithm, '_', string(T.b_sz), '_', ...
                  string(T.num_matmuls), '_', string(T.p));

    unique_keys = unique(keys, 'stable');
    n_configs = numel(unique_keys);

    % Pre-allocate output as cell array of row indices
    best_idx = zeros(n_configs, 1);
    for i = 1:n_configs
        mask = keys == unique_keys(i);
        group_idx = find(mask);
        [~, min_pos] = min(T.duration_us(mask));
        best_idx(i) = group_idx(min_pos);
    end

    T_best = T(best_idx, :);
end
