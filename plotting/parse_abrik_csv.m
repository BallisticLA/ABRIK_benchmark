%{
Parses the ABRIK benchmark CSV (budgeted checkpointing format).

Format:
  # ... metadata comment lines ...
  method, b_sz, total_matvecs, err, elapsed_us
  ABRIK, 4, 4, 1.23e-02, 12345
  ...
  Spectra, 0, 4, 4.56e-01, 67890
  RSVD, 32, 4, 9.99e-01, 11111
  GESDD, 0, 0, 1.11e-14, 999999

Returns a table T with columns:
  method        (string)
  b_sz          (int64)
  total_matvecs (int64)
  err           (double)
  elapsed_us    (int64)

and a meta struct with fields:
  input_matrix, input_size, target_rank, budget, block_sizes, is_sparse

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
        elseif contains(line, 'Block sizes:', 'IgnoreCase', true)
            meta.block_sizes = parse_csv_values(line);
        elseif contains(line, 'sparse', 'IgnoreCase', true)
            meta.is_sparse = true;
        end
    end

    % ---- Read data rows (skip remaining comment/header lines) ----
    fid2 = fopen(filename, 'r');
    if fid2 == -1
        error('parse_abrik_csv:FileNotFound', 'Cannot open: %s', filename);
    end
    cleanup2 = onCleanup(@() fclose(fid2));

    while ~feof(fid2)
        pos = ftell(fid2);
        line = fgetl(fid2);
        trimmed = strtrim(line);
        if ~startsWith(trimmed, '#') && ~startsWith(trimmed, 'method')
            fseek(fid2, pos, 'bof');
            break;
        end
    end

    % Read: method(string), b_sz, total_matvecs, err, elapsed_us
    C = textscan(fid2, '%s %d %d %f %d', 'Delimiter', ',', 'CollectOutput', false);

    methods       = string(C{1});
    b_sz_col      = int64(C{2});
    matvecs_col   = int64(C{3});
    err_col       = C{4};
    elapsed_col   = int64(C{5});

    T = table(methods, b_sz_col, matvecs_col, err_col, elapsed_col, ...
              'VariableNames', {'method', 'b_sz', 'total_matvecs', 'err', 'elapsed_us'});
end

%% -----------------------------------------------------------------------
function vals = parse_csv_values(line)
    after_colon = regexp(line, ':\s*(.*)', 'tokens');
    parts = strsplit(strtrim(after_colon{1}{1}), ',');
    parts = parts(strtrim(parts) ~= "");
    vals = cellfun(@str2double, parts);
end
