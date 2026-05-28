%{
Parses the ABRIK benchmark CSV (budgeted checkpointing format).

Supports two CSV column layouts (auto-detected from the header line):
  Legacy (pre-2026-05-27):
    method, b_sz, total_matvecs, err, elapsed_us
  Multi-run (2026-05-27 onward, num_runs CLI arg):
    run, method, b_sz, total_matvecs, err, elapsed_us

Returns a table T with columns:
  run           (int64; always present; 0 for legacy single-run files)
  method        (string)
  b_sz          (int64)
  total_matvecs (int64)
  err           (double)
  elapsed_us    (int64)

and a meta struct with fields:
  input_matrix, input_size, target_rank, budget, num_runs, block_sizes, is_sparse

Usage:
  [T, meta] = parse_abrik_csv('path/to/file.csv')
%}
function [T, meta] = parse_abrik_csv(filename)

    % ---- Parse '#'-prefixed metadata ----
    meta = struct();
    meta.input_matrix = "";
    meta.input_size   = "";
    meta.target_rank  = 0;
    meta.budget       = 0;
    meta.num_runs     = 1;
    meta.block_sizes  = [];
    meta.is_sparse    = false;

    fid = fopen(filename, 'r');
    if fid == -1
        error('parse_abrik_csv:FileNotFound', 'Cannot open: %s', filename);
    end
    cleanup = onCleanup(@() fclose(fid));

    while ~feof(fid)
        line = fgetl(fid);
        if ~startsWith(strtrim(line), '#'), break; end
        if contains(line, 'Input matrix:')
            tok = regexp(line, 'Input matrix:\s*(.*)', 'tokens');
            meta.input_matrix = strtrim(tok{1}{1});
        elseif contains(line, 'Input size:')
            tok = regexp(line, 'Input size:\s*(.*)', 'tokens');
            meta.input_size = strtrim(tok{1}{1});
        elseif contains(line, 'Target rank:')
            tok = regexp(line, 'Target rank:\s*(\d+)', 'tokens');
            meta.target_rank = str2double(tok{1}{1});
        elseif contains(line, 'Budget (total matvecs):')
            tok = regexp(line, 'Budget \(total matvecs\):\s*(\d+)', 'tokens');
            meta.budget = str2double(tok{1}{1});
        elseif contains(line, 'Num runs:')
            tok = regexp(line, 'Num runs:\s*(\d+)', 'tokens');
            meta.num_runs = str2double(tok{1}{1});
        elseif contains(line, 'Block sizes:', 'IgnoreCase', true)
            meta.block_sizes = parse_csv_values(line);
        elseif contains(line, 'sparse', 'IgnoreCase', true)
            meta.is_sparse = true;
        end
    end

    % ---- Locate header row + detect column layout ----
    fid2 = fopen(filename, 'r');
    if fid2 == -1
        error('parse_abrik_csv:FileNotFound', 'Cannot open: %s', filename);
    end
    cleanup2 = onCleanup(@() fclose(fid2));

    has_run_col = false;
    while ~feof(fid2)
        pos = ftell(fid2);
        line = fgetl(fid2);
        trimmed = strtrim(line);
        if startsWith(trimmed, '#'), continue; end
        if startsWith(trimmed, 'run,') || startsWith(trimmed, 'run ,')
            has_run_col = true;
            break;
        end
        if startsWith(trimmed, 'method')
            has_run_col = false;
            break;
        end
        % unrecognized non-comment line before header (shouldn't happen)
        fseek(fid2, pos, 'bof');
        break;
    end

    if has_run_col
        % run, method, b_sz, total_matvecs, err, elapsed_us
        C = textscan(fid2, '%d %s %d %d %f %d', 'Delimiter', ',', ...
                     'CollectOutput', false, 'CommentStyle', '#');
        run_col       = int64(C{1});
        methods       = string(C{2});
        b_sz_col      = int64(C{3});
        matvecs_col   = int64(C{4});
        err_col       = C{5};
        elapsed_col   = int64(C{6});
    else
        % method, b_sz, total_matvecs, err, elapsed_us (legacy)
        C = textscan(fid2, '%s %d %d %f %d', 'Delimiter', ',', ...
                     'CollectOutput', false, 'CommentStyle', '#');
        methods       = string(C{1});
        b_sz_col      = int64(C{2});
        matvecs_col   = int64(C{3});
        err_col       = C{4};
        elapsed_col   = int64(C{5});
        run_col       = zeros(numel(methods), 1, 'int64');
    end

    T = table(run_col, methods, b_sz_col, matvecs_col, err_col, elapsed_col, ...
              'VariableNames', {'run', 'method', 'b_sz', 'total_matvecs', 'err', 'elapsed_us'});
end

%% -----------------------------------------------------------------------
function vals = parse_csv_values(line)
    after_colon = regexp(line, ':\s*(.*)', 'tokens');
    parts = strsplit(strtrim(after_colon{1}{1}), ',');
    parts = parts(strtrim(parts) ~= "");
    vals = cellfun(@str2double, parts);
end
