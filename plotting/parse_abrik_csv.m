%{
Parses the ABRIK benchmark CSV format.

Handles both dense and sparse formats:
  Dense:  b_sz, num_matmuls, target_rank, err_ABRIK, dur_ABRIK, err_RSVD, dur_RSVD, err_SVDS, dur_SVDS, err_SVD, dur_SVD
  Sparse: b_sz, num_matmuls, target_rank, err_ABRIK, dur_ABRIK, err_SVDS, dur_SVDS

Reads '#'-prefixed metadata into a struct, then unpivots the wide-format
data rows into a long-format table with columns:
  algorithm, b_sz, num_matmuls, target_rank, error, duration_us

Usage:
  [T, meta] = parse_abrik_csv('path/to/file.csv')
%}
function [T, meta] = parse_abrik_csv(filename)

    % ---- Parse metadata from '#'-prefixed header lines ----
    meta = struct();
    meta.input_matrix = "";
    meta.input_size   = "";
    meta.target_rank  = 0;
    meta.num_runs     = 0;
    meta.block_sizes  = [];
    meta.matmul_counts = [];
    meta.is_sparse    = false;

    fid = fopen(filename, 'r');
    if fid == -1
        error('parse_abrik_csv:FileNotFound', 'Cannot open file: %s', filename);
    end
    cleanup = onCleanup(@() fclose(fid));

    header_line = '';
    while ~feof(fid)
        line = fgetl(fid);
        if startsWith(strtrim(line), '#')
            if contains(line, 'Input matrix:')
                tok = regexp(line, 'Input matrix:\s*(.*)', 'tokens');
                meta.input_matrix = strtrim(tok{1}{1});
            elseif contains(line, 'Input size:')
                tok = regexp(line, 'Input size:\s*(.*)', 'tokens');
                meta.input_size = strtrim(tok{1}{1});
            elseif contains(line, 'Target rank:')
                tok = regexp(line, 'Target rank:\s*(\d+)', 'tokens');
                meta.target_rank = str2double(tok{1}{1});
            elseif contains(line, 'Runs per configuration:')
                tok = regexp(line, 'Runs per configuration:\s*(\d+)', 'tokens');
                meta.num_runs = str2double(tok{1}{1});
            elseif contains(line, 'block sizes:', 'IgnoreCase', true)
                meta.block_sizes = parse_csv_values(line);
            elseif contains(line, 'Matmul counts:')
                meta.matmul_counts = parse_csv_values(line);
            elseif contains(line, 'sparse', 'IgnoreCase', true)
                meta.is_sparse = true;
            end
        else
            % First non-comment line is the column header
            header_line = strtrim(line);
            break;
        end
    end

    % ---- Read data rows ----
    % Unified format (always 11 columns):
    %   b_sz, num_matmuls, target_rank,
    %   err_ABRIK, dur_ABRIK, err_RSVD, dur_RSVD, err_SVDS, dur_SVDS, err_SVD, dur_SVD
    fid2 = fopen(filename, 'r');
    if fid2 == -1
        error('parse_abrik_csv:FileNotFound', 'Cannot open file: %s', filename);
    end
    cleanup2 = onCleanup(@() fclose(fid2));

    % Skip all '#' lines and the column header line
    while ~feof(fid2)
        pos = ftell(fid2);
        line = fgetl(fid2);
        if ~startsWith(strtrim(line), '#') && ~startsWith(strtrim(line), 'b_sz')
            fseek(fid2, pos, 'bof');
            break;
        end
    end

    C = textscan(fid2, '%f %f %f %f %f %f %f %f %f %f %f', 'Delimiter', ',');
    n_rows = length(C{1});

    % Unpivot: each input row -> 4 output rows (ABRIK, RSVD, SVDS, GESDD)
    alg_names = [repmat({"ABRIK"}, n_rows, 1); repmat({"RSVD"}, n_rows, 1); ...
                 repmat({"SVDS"}, n_rows, 1); repmat({"GESDD"}, n_rows, 1)];
    b_sz_col  = repmat(C{1}, 4, 1);
    mm_col    = repmat(C{2}, 4, 1);
    tr_col    = repmat(C{3}, 4, 1);
    err_col   = [C{4}; C{6}; C{8}; C{10}];
    dur_col   = [C{5}; C{7}; C{9}; C{11}];

    T = table(string(alg_names), b_sz_col, mm_col, tr_col, err_col, dur_col, ...
              'VariableNames', {'algorithm', 'b_sz', 'num_matmuls', ...
                                'target_rank', 'error', 'duration_us'});

    % Remove rows where duration is 0 (GESDD only runs on first iteration)
    T = T(T.duration_us > 0, :);
end

%% -----------------------------------------------------------------------
function vals = parse_csv_values(line)
% Parses comma-separated numeric values after the colon in a metadata line.
    after_colon = regexp(line, ':\s*(.*)', 'tokens');
    parts = strsplit(strtrim(after_colon{1}{1}), ',');
    parts = parts(strtrim(parts) ~= "");
    vals = cellfun(@str2double, parts);
end
