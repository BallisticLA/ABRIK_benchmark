%{
Below code plots the results of RBKI_speed_comp_sparse benchmark from RandLAPACK.
The following layout of an input data file is assumed by default:
Data column 1 (block size) varies from 2 to 'max_b_sz' in powers of 2.
Data column 2 (number of krylov iterations) varies from 2 to 
'max_krylov_iters' in powers of 2 per block size.
%}

function[] = abrik_precision_vs_speedup_sparse(filename, num_b_sizes, num_krylov_iters, num_iters, test_matrix_number, plot_all_b_sz, show_lables)

    Data_in = readfile(filename, 6);
    
    switch test_matrix_number
        case 0
            rows = 11083;	
            cols = 11083;
        case 1
            rows = 226451;	
            cols = 226451;
        case 2
            rows = 806529;	
            cols = 806529;
        case 3
            rows = 1219574;	
            cols = 1219574;
        case 4
            rows = 2380515;	
            cols = 2380515;
    end

    % We have a total of 6 synthetic test matrices.
    %i = test_matrix_number;
    i = 1;
    tiledlayout(2, 2,"TileSpacing","loose");

    % Plots ABRIK digits of accuracy vs number of singular triplets estimated.
    nexttile
    process_and_plot(Data_in(num_iters*num_krylov_iters*num_b_sizes*(i-1)+1:num_iters*num_krylov_iters*num_b_sizes*i, :), rows, cols, num_iters, num_b_sizes, num_krylov_iters, 5, "num_triplets", plot_all_b_sz, show_lables);
    % Plots SVDS digits of accuracy vs Number of singular triplets we're hunting for.
    nexttile
    process_and_plot(Data_in(num_iters*num_krylov_iters*num_b_sizes*(i-1)+1:num_iters*num_krylov_iters*num_b_sizes*i, :), rows, cols, num_iters, num_b_sizes, num_krylov_iters, 7, "num_triplets", plot_all_b_sz, show_lables);

    % Plots ABRIK digits of accuracy vs speedup over SVD.
    nexttile
    process_and_plot(Data_in(num_iters*num_krylov_iters*num_b_sizes*(i-1)+1:num_iters*num_krylov_iters*num_b_sizes*i, :), rows, cols, num_iters, num_b_sizes, num_krylov_iters, 5, "gflops", plot_all_b_sz, show_lables);
    % Plots SVDS digits of accuracy vs speedup over SVD.
    nexttile
    process_and_plot(Data_in(num_iters*num_krylov_iters*num_b_sizes*(i-1)+1:num_iters*num_krylov_iters*num_b_sizes*i, :), rows, cols, num_iters, num_b_sizes, num_krylov_iters, 7, "gflops", plot_all_b_sz, show_lables);
end

% alg_column_idx is 6, 9 or 12 - signifies which alg we will be comparing against
% SVD.
function[] = process_and_plot(Data, rows, cols, num_iters, num_b_sizes, num_krylov_iters, alg_column_idx, plot_mode, plot_all_b_sz, show_lables)

    legend_entries = [];
    marker_array = {'-o', '-diamond' '-s', '-^', '-v', '-+', '-*', '-s'};

    % Grab the best time for each algorithm for all block sizes and Krylov
    % iterations out of num_iters.
    % Additionally, since we only run SVD once, populate the set with SVD
    % results.
    Data = data_preprocessing_best(Data, num_b_sizes, num_krylov_iters, num_iters);

    svd_gflop = 4 * rows^2 * cols + 22 * cols^3 / 10^9;
    ctr = 1;
    all_tics = unique(Data(:, 2) .* Data(:, 1) ./2);

    if alg_column_idx == 7
        % SVDS does not have a notion of block size, yet we use the
        % block size to benchmark it.
        % Because of that, the data points for SVDS associated with different
        % block size algorithm runs but resulting in the same number of 
        % approximated triplets woudl ideally sit on top of each other, whcih
        % does not happen exactly in practice due to CPU noise. Because of
        % that, we need to process SVDS separately from other algorithms to
        % make sure that the plot renders with no artifacts.
        
        % Below will have a bunch of non-unique values representing the numbers
        % of singular triplets found.
        Data_SVDS = [Data(:, 1), Data(:, 1) .* Data(:, 2) ./2, Data(:, 6), Data(:, 7)];
        
        % Keep the first occurrence of each unique value in column 1
        [~, Data_SVDS_unique_idx, ~] = unique(Data_SVDS(:,2), 'first');
        % Extract those rows
        Data_SVDS = Data_SVDS(sort(Data_SVDS_unique_idx), :);
        % Block sizes in column one will not be unique because there is a
        % smaller set of block sizes than the number of singular triplets.
        original_len = size(Data_SVDS, 1);           % Original number of rows
        unique_vals = unique(Data_SVDS(:, 1));       % Unique values
        padded_vals = [unique_vals; zeros(original_len - numel(unique_vals), 1)];  % Pad with zeros
        Data_SVDS(:, 1) = padded_vals;
        % Y-axis vector
        Data_SVDS(:, 3) = log10(1 ./ Data_SVDS(:, 3));

        % We want to disregard all results that achieved below one
        % digit of accuracy.
        
        valid_idx = Data_SVDS(:,3) >= 1;
        Data_SVDS = Data_SVDS(valid_idx, :);
        if isempty(Data_SVDS)
            Data_SVDS = nan(1, 4);  
        end
        

        % Since the SVDS subplot plot occupies the least amount of space, we will
        % place the legend here.
        % For that, we will have to mimic plotting the rest of the data.
        if plot_mode == "num_triplets"
            for i = 1:num_b_sizes
                if plot_mode == "gflops"
                    plot(nan, nan, marker_array{i}, MarkerSize=18, LineWidth=1.8);
                elseif plot_mode == "num_triplets"
                    semilogx(nan, nan, marker_array{i}, MarkerSize=18, LineWidth=1.8);
                end
                hold on
                legend_entries{i} = ['b_{sz}=', num2str(Data_SVDS(i, 1))]; %#ok<AGROW>
            end
        end

        % Plot SVDS.
        if plot_mode == "gflops"
            Data_SVDS(:, 4) = (svd_gflop ./ Data_SVDS(:, 4)) ./ 10^6;
            plot(Data_SVDS(:, 4), Data_SVDS(:, 3), '-*' , 'Color', 'black', MarkerSize=18, LineWidth=1.8);
        elseif plot_mode == "num_triplets"
            semilogx(Data_SVDS(:, 2), Data_SVDS(:, 3), '-*' , 'Color', 'black', MarkerSize=18, LineWidth=1.8);
        end

        % Add an SVDS legend entry.
        if plot_mode == "num_triplets"
            legend_entries{i+1} = 'SVDS'; %#ok<AGROW>
            lgd = legend(legend_entries, 'Location', 'northeast');
        end
    else
        for i = 1:num_krylov_iters:size(Data, 1)
            % Speedup over SVD for all krylov iterations using a given block
            % size for a given algorithm.
            if plot_mode == "gflops"
                    x_axis_vector = (svd_gflop ./ Data(i:(i+num_krylov_iters-1), alg_column_idx)) ./ 10^6;
            elseif plot_mode == "num_triplets"
                % Number of singular triplets estimated (num_matmuls * b_sz) / 2 on the x_axis 
                x_axis_vector = Data(i:(i+num_krylov_iters-1), 2) .* Data(i:(i+num_krylov_iters-1), 1) ./2;
            end
            % The input file recors two types of error metric: (2) assesses the
            % quality of singular triplets (1) standard low-rank reconstruction 
            % error. Using log10 below to show digits of accuracy rather than the
            % scientific notation error.
            error_vector = log10(1 ./ Data(i:(i+num_krylov_iters-1), alg_column_idx - 1));
            
            % We want to disregard all results that achieved below one
            % digit of accuracy.
            
            valid_idx = error_vector >= 1;
            error_vector = error_vector(valid_idx);
            x_axis_vector = x_axis_vector(valid_idx);
            if isempty(error_vector)
                error_vector = nan;
                x_axis_vector = nan;
            end
            

            % If "plot_all_b_sz" parameter is set to 0, we shall only plot
            % the results for every other block size.
            if (mod(ctr, 2) ~= 0 || plot_all_b_sz)
                if plot_mode == "num_triplets"
                    semilogx(x_axis_vector, error_vector, marker_array{ctr}, MarkerSize=18, LineWidth=1.8);
                elseif plot_mode == "gflops"
                    plot(x_axis_vector, error_vector, marker_array{ctr}, MarkerSize=18, LineWidth=1.8);
                end
                hold on
            end
            ctr = ctr + 1;
        end
    end

    % Additional labels info control.
    if show_lables == 1
        if alg_column_idx == 6
            ylabel('Digits of accuracy', 'FontSize', 20)
        end

        if plot_mode == "num_triplets"
            switch alg_column_idx
                case 6
                    title('RandLAPACK ABRIK', 'FontSize', 20);
                case 9
                    title('RandLAPACK RSVD', 'FontSize', 20);
                case 12
                    title('Spectra SVDS', 'FontSize', 20);
            end
            xlabel('#triplets found', 'FontSize', 20)
        elseif plot_mode == "gflops"
            xlabel('#GigaFLOPS/s', 'FontSize', 20)
        end
    end
    
    xtickangle(45)
    switch alg_column_idx
        case 9
            set(gca,'Yticklabel',[])
        case 12
            set(gca,'Yticklabel',[])
    end
    
    % X-axis control.
    if plot_mode == "num_triplets"
        % Flip the order of rows in the data matrix so that the
        % matmuls-based subplot matches the speedup-based subplots
        % (best accuracy on the left, worst on the right). 
        %set(gca, 'XDir', 'reverse');
        
        % The number of estimated singular triplets would be repeating for
        % different combinations of block sizes and numbers of matmuls,
        % hence I'm using "unique()" function to remove repetitions.
        %all_tics = unique(Data(:, 2) .* Data(:, 1) ./2);
        odd_tics = all_tics(1:2:end);
        xticks(odd_tics);

        xlim([min(odd_tics) max(all_tics)]);
    elseif plot_mode == "gflops"
        % Set jist the lower limit in the x-axis.
        curr_lim = xlim;
        xlim([0, curr_lim(2)]);
    end

    grid on
    lgd.FontSize = 15;
    ax = gca;
    ax.XAxis.FontSize = 20;
    ax.YAxis.FontSize = 20;
    ylim([1 5]);
    yticks([0,  1, 3, 5, 10, 15]);
end

function[Data_out] = data_preprocessing_best(Data_in, num_b_sizes, num_krylov_iters, num_iters)
    
    Data_out = [];

    i = 1;
    num_columns_in_dataset = 7;
    distinct_ops_in_dataset = num_krylov_iters * num_b_sizes;
    % Iterating over the algorithms
    for k = 5:2:num_columns_in_dataset
        Data_out_alg = [];
        % Iterating over all rows for a given algorithm.
        while i < distinct_ops_in_dataset * num_iters
            best_speed         = intmax;
            best_speed_row_idx = i;
            best_speed_col_idx = k;
            % Iterating over the runs for a given block size of a given
            % algorithm.
            for j = 1:num_iters
                % If a timing of zero is encountered, it is ignored.
                if (Data_in(i, k) < best_speed) && (Data_in(i, k) ~= 0)
                    best_speed = Data_in(i, k);
                    best_speed_row_idx = i;
                    best_speed_col_idx = k;
                end
                i = i + 1;
            end
            % RBKI set goes first, hence we also need to append the data
            % about num_krylov_iters, num_matmuls and target_rank, stored
            % in the first three columns of the set.
            if k == 5
            Data_out_alg = [Data_out_alg; ...
                Data_in(best_speed_row_idx, 1), ...
                Data_in(best_speed_row_idx, 2), ...
                Data_in(best_speed_row_idx, 3), ...
                Data_in(best_speed_row_idx, best_speed_col_idx - 1), ...
                Data_in(best_speed_row_idx, best_speed_col_idx)]; %#ok<AGROW>
            else 
            Data_out_alg = [Data_out_alg; ...
                Data_in(best_speed_row_idx, best_speed_col_idx - 1), ...
                Data_in(best_speed_row_idx, best_speed_col_idx)]; %#ok<AGROW>
            end
        end
        i = 1;
        Data_out = [Data_out, Data_out_alg]; %#ok<AGROW>
    end
end