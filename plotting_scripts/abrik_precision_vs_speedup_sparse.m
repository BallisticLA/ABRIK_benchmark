%{
Below code plots the results of RBKI_speed_comp_sparse benchmark from RandLAPACK.
The following layout of an input data file is assumed by default:
Data column 1 (block size) varies from 2 to 'max_b_sz' in powers of 2.
Data column 2 (number of krylov iterations) varies from 2 to 
'max_krylov_iters' in powers of 2 per block size.
%}

function[] = abrik_precision_vs_speedup_sparse(filename, num_b_sizes, num_krylov_iters, num_iters, test_matrix_number, plot_all_b_sz, show_lables)

    Data_in = readfile(filename, 6);
    
    % We have a total of 5 real test matrices.
    plot_position = 1;
    i = test_matrix_number;
    tiledlayout(1, 3,"TileSpacing","tight");
    % Plots ABRIK digits of accuracy vs #matmuls.
    nexttile
    plot_2d(Data_in(num_iters*num_krylov_iters*num_b_sizes*(i-1)+1:num_iters*num_krylov_iters*num_b_sizes*i, :), num_iters, num_b_sizes, num_krylov_iters, 5, "num_matmuls", plot_all_b_sz, show_lables, 1);
    plot_position = plot_position + 1;
    % Plots ABRIK digits of accuracy vs speedup over SVD.
    nexttile
    plot_2d(Data_in(num_iters*num_krylov_iters*num_b_sizes*(i-1)+1:num_iters*num_krylov_iters*num_b_sizes*i, :), num_iters, num_b_sizes, num_krylov_iters, 5, "speedup_over_svd", plot_all_b_sz, show_lables, 2);
    plot_position = plot_position + 1;
    % Plots SVDS digits of accuracy vs speedup over SVD.
    nexttile
    plot_2d(Data_in(num_iters*num_krylov_iters*num_b_sizes*(i-1)+1:num_iters*num_krylov_iters*num_b_sizes*i, :), num_iters, num_b_sizes, num_krylov_iters, 7, "speedup_over_svd", plot_all_b_sz, show_lables, 3);
end

% alg_column_idx is 6, 9 or 12 - signifies which alg we will be comparing against
% SVD.
function[] = plot_2d(Data, num_iters, num_b_sizes, num_krylov_iters, alg_column_idx, plot_mode, plot_all_b_sz, show_lables, plot_position)

    legend_entries = [];
    marker_array = {'-o', '-diamond' '-s', '-^', '-v', '-+', '-*', '-s'};

    % Grab the best time for each algorithm for all block sizes and Krylov
    % iterations out of num_iters.
    % Additionally, since we only run SVD once, populate the set with SVD
    % results.
    Data = data_preprocessing_best(Data, num_b_sizes, num_krylov_iters, num_iters)

    ctr = 1;
    lgd_ctr = 1;
    for i = 1:num_krylov_iters:size(Data, 1)
        % Speedup over SVD for all krylov iterations using a given block
        % size for a given algorithm.
        if plot_mode == "speedup_over_svd"
                % Wall clock time on the X-axis (cannot measure direct SVD
                % speed for large sparse data).
                x_axis_vector =  1894162900 ./ Data(i:(i+num_krylov_iters-1), alg_column_idx);
        elseif plot_mode == "num_matmuls"
            % Num_matmuls on the x_axis 
            x_axis_vector = Data(i:(i+num_krylov_iters-1), 2);
        end
        
        error_vector = log10(1 ./ Data(i:(i+num_krylov_iters-1), alg_column_idx - 1));
        
        % If "plot_all_b_sz" parameter is set to 0, we shall only plot
        % the results for every other block size.
        if (mod(ctr, 2) ~= 0 || plot_all_b_sz)
            Data(:, 1)
            plot(x_axis_vector, error_vector, marker_array{ctr}, MarkerSize=18, LineWidth=1.8);
            legend_entries{lgd_ctr} = ['b_{sz}=', num2str(Data(i, 1))]; %#ok<AGROW>
            hold on
            lgd_ctr = lgd_ctr + 1;
        end
        ctr = ctr + 1;
    end

    % Additional labels info control.
    if show_lables == 1
        if plot_position == 1
            ylabel('Digits of accuracy', 'FontSize', 20)
        end

        if plot_mode == "speedup_over_svd"
            xlabel('Speedup over SVD', 'FontSize', 20)
        elseif plot_mode == "num_matmuls"
            xlabel('#Large Matmuls', 'FontSize', 20)
        end

        switch alg_column_idx
            case 6
                title('RandLAPACK ABRIK', 'FontSize', 20);
            case 9
                title('RandLAPACK RSVD', 'FontSize', 20);
            case 12
                title('Spectra SVDS', 'FontSize', 20);
        end
    end

    % Legend control.
    if plot_position == 1
        lgd = legend(legend_entries, 'Location', 'southwest');
    end

    % X-axis control.
    if plot_mode == "num_matmuls"
        % Flip the order of rows in the data matrix so that the
        % matmuls-based subplot matches the speedup-based subplots
        % (best accuracy on the left, worst on the right). 
        set(gca, 'XDir', 'reverse');

        xticks(Data(1:num_krylov_iters, 2));
    else
        switch alg_column_idx
            case 6
                %xlim([0 180]);
            case 9
                %xlim([0 180]);
            case 12
                %xlim([0 180]);
        end
        %xlim([0 100]);
    end

    grid on
    lgd.FontSize = 20;
    ax = gca;
    ax.XAxis.FontSize = 20;
    ax.YAxis.FontSize = 20;
    ylim([-16 16]);
    yticks([0,  1, 5, 10, 15]);
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
