function numericData = readfile(filename, header_lines)
    % Open the file for reading
    fid = fopen(filename, 'r');
    if fid == -1
        error('Cannot open the file.');
    end

    % Skip the header lines
    for i = 1:header_lines-1
        fgetl(fid); % Read and discard header lines
    end

    % Read the entire file line by line
    numericData = [];
    while ~feof(fid)
        line = fgetl(fid); % Read a line
        if ischar(line) % Ensure it's a valid line
            % Convert the line into numerical values
            values = str2num(line); %#ok<ST2NM> % Converts space/comma-separated numbers
            if ~isempty(values)
                if size(numericData, 2) <= size(values, 2)
                    rows = size(numericData, 1);
                    cols = size(values, 2) - size(numericData, 2);
                    numericData = [numericData, zeros(rows, cols)]; %#ok<AGROW>
                elseif size(numericData, 2) >= size(values, 2)
                    rows = size(values, 1);
                    cols = size(numericData, 2) - size(values, 2);
                    values = [values, zeros(rows, cols)]; %#ok<AGROW>
                end
                numericData = [numericData; values]; %#ok<AGROW> % Append row to matrix
            end
        end
    end

    % Close the file
    fclose(fid);
end