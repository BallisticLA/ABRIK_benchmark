function mmwrite(filename, A, comment)
% MMWRITE  Write a matrix to a Matrix Market file.
%
%   mmwrite(filename, A)
%   mmwrite(filename, A, comment)
%
%   Writes dense matrices in "array" format and sparse matrices in
%   "coordinate" format. Values are written as real general (double).
%
%   Compatible with fast_matrix_market (C++) and mmread (MATLAB).

    if nargin < 3
        comment = '';
    end

    fid = fopen(filename, 'w');
    if fid == -1
        error('Cannot open file: %s', filename);
    end

    [m, n] = size(A);

    if issparse(A)
        % Coordinate format for sparse matrices
        fprintf(fid, '%%%%MatrixMarket matrix coordinate real general\n');
        if ~isempty(comment)
            fprintf(fid, '%% %s\n', comment);
        end

        [rows, cols, vals] = find(A);
        nnz_count = length(vals);
        fprintf(fid, '%d %d %d\n', m, n, nnz_count);
        % Vectorized write — much faster than per-element fprintf
        fprintf(fid, '%d %d %.17g\n', [rows'; cols'; vals']);
    else
        % Array (dense column-major) format
        fprintf(fid, '%%%%MatrixMarket matrix array real general\n');
        if ~isempty(comment)
            fprintf(fid, '%% %s\n', comment);
        end

        fprintf(fid, '%d %d\n', m, n);
        % Convert to string in bulk, then write once.
        % sprintf is ~5x faster than fprintf for large arrays.
        str = sprintf('%.17g\n', A(:));
        fwrite(fid, str, 'char');
    end

    fclose(fid);
end
