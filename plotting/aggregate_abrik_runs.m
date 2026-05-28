%{
Reduces a multi-run ABRIK speed-comparison table to one row per
(method, b_sz, total_matvecs) cell.

Inputs:
  T : table from parse_abrik_csv with columns
      run, method, b_sz, total_matvecs, err, elapsed_us
  opts (optional name/value pairs):
      'TimeReduction' : 'median' (default) | 'min' | 'mean'
      'ErrReduction'  : 'median' (default) | 'min' | 'mean'
                        (err is mostly deterministic up to RNG so the choice
                         rarely matters; median is robust to occasional spikes)

Output:
  T_agg : table with the same column names as T plus 'n_runs' (count per cell).
          'run' column is replaced with NaN (no longer meaningful after reduction);
          it is retained so downstream code that expects the 6-column layout
          still parses.

Usage:
  T = parse_abrik_csv(file);
  T_agg = aggregate_abrik_runs(T);

For single-run (legacy) CSVs, T_agg is structurally identical to T except for
the n_runs=1 column.
%}
function T_agg = aggregate_abrik_runs(T, varargin)
    p = inputParser;
    addParameter(p, 'TimeReduction', 'median');
    addParameter(p, 'ErrReduction',  'median');
    parse(p, varargin{:});
    time_fn = pick_reducer(p.Results.TimeReduction);
    err_fn  = pick_reducer(p.Results.ErrReduction);

    [G, methods, b_sz, total_matvecs] = findgroups(T.method, T.b_sz, T.total_matvecs);
    err_agg     = splitapply(@(x) err_fn(double(x)),       T.err,        G);
    elapsed_agg = splitapply(@(x) round(time_fn(double(x))), T.elapsed_us, G);
    n_runs      = splitapply(@numel, T.err, G);

    T_agg = table( ...
        nan(size(methods), 'double'), ...     % run placeholder
        methods, ...
        int64(b_sz), ...
        int64(total_matvecs), ...
        err_agg, ...
        int64(elapsed_agg), ...
        int64(n_runs), ...
        'VariableNames', {'run', 'method', 'b_sz', 'total_matvecs', 'err', 'elapsed_us', 'n_runs'});
end

function f = pick_reducer(name)
    switch lower(name)
        case 'median', f = @median;
        case 'min',    f = @min;
        case 'mean',   f = @mean;
        otherwise
            error('aggregate_abrik_runs:badReduction', 'Unknown reducer: %s', name);
    end
end
