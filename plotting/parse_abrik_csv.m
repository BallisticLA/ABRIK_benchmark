%{
Parses the new unified ABRIK benchmark CSV format.

Reads '#'-prefixed metadata into a struct, then reads data rows into a
MATLAB table with columns: algorithm, b_sz, num_matmuls, p, target_rank,
error, duration_us.

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
    meta.p_values     = [];

    fid = fopen(filename, 'r');
    if fid == -1
        error('parse_abrik_csv:FileNotFound', 'Cannot open file: %s', filename);
    end
    cleanup = onCleanup(@() fclose(fid));

    while ~feof(fid)
        line = fgetl(fid);
        if ~startsWith(line, '#')
            break;
        end
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
        elseif contains(line, 'Krylov block sizes:')
            meta.block_sizes = parse_csv_values(line);
        elseif contains(line, 'Matmul counts:')
            meta.matmul_counts = parse_csv_values(line);
        elseif contains(line, 'RSVD p values:')
            meta.p_values = parse_csv_values(line);
        end
    end

    % ---- Read data rows ----
    % Re-open and use textscan to read the unified format.
    fid2 = fopen(filename, 'r');
    if fid2 == -1
        error('parse_abrik_csv:FileNotFound', 'Cannot open file: %s', filename);
    end
    cleanup2 = onCleanup(@() fclose(fid2));

    % Skip all '#' lines and the column header line
    while ~feof(fid2)
        pos = ftell(fid2);
        line = fgetl(fid2);
        if ~startsWith(strtrim(line), '#') && ~startsWith(strtrim(line), 'algorithm')
            fseek(fid2, pos, 'bof');
            break;
        end
    end

    % Read: algorithm(string), b_sz, num_matmuls, p, target_rank, error, duration_us
    C = textscan(fid2, '%s %f %f %f %f %f %f', 'Delimiter', ',', 'TreatAsEmpty', 'NA');

    % Strip trailing commas from algorithm names
    alg_names = strtrim(C{1});

    T = table(alg_names, C{2}, C{3}, C{4}, C{5}, C{6}, C{7}, ...
              'VariableNames', {'algorithm', 'b_sz', 'num_matmuls', 'p', ...
                                'target_rank', 'error', 'duration_us'});
end

%% -----------------------------------------------------------------------
function vals = parse_csv_values(line)
% Parses comma-separated numeric values after the colon in a metadata line.
    after_colon = regexp(line, ':\s*(.*)', 'tokens');
    parts = strsplit(strtrim(after_colon{1}{1}), ',');
    parts = parts(strtrim(parts) ~= "");
    vals = cellfun(@str2double, parts);
end
