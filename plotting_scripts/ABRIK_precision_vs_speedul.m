%{
Below code plots the results of RBKI_speed_comp benchmark from RandLAPACK.
The following layout of an input data file is assumed by default:
Data column 1 (block size) varies from 2 to 'max_b_sz' in powers of 2.
Data column 2 (number of krylov iterations) varies from 2 to 
'max_krylov_iters' in powers of 2 per block size.
The file contains data for 5 input matrices from "Algorithm 971" paper, 
controlled by 'matrix_number' parameter.
%}

function[] = ABRIK_precision_vs_speedul()

    matrix_number = 1;
    num_b_sizes = 5;
    num_krylov_iters = 4;
    numiters = 2;
    err_type = 2;
    name = '2024_10_14_RBKI_speed_comp_SVDS_m_10000_n_10000_b_sz_start_4_b_sz_stop_64_num_matmuls_start_2_num_matmuls_stop_16_rank_10';
    Data_in = readmatrix(['../benchmark_output_abrik_paper/Zen2/' name]);
    
    Data_in = data_preprocessing_best(Data_in, num_b_sizes, num_krylov_iters, numiters);

    fig = tiledlayout(1, 2,"TileSpacing","tight")
    nexttile
    plot_2d(Data_in, name, matrix_number, num_b_sizes, num_krylov_iters, 6, err_type, 0, 1);
    nexttile
    plot_2d(Data_in, name, matrix_number, num_b_sizes, num_krylov_iters, 6, err_type, 1, 1);
    %nexttile
    %plot_2d(Data_in, name, matrix_number, num_b_sizes, num_krylov_iters, 9, err_type, 1, 0);
    %nexttile
    %plot_2d(Data_in, name, matrix_number, num_b_sizes, num_krylov_iters, 12, err_type, 1, 0);
end

% alg_idx is 6, 9 or 12 - signifies which alg we will be comparing against
% SVD.
% err_type - 1 for lowrank_err and 2 for residual_err.
function[] = plot_2d(Data, name, matrix_number, num_b_sizes, num_krylov_iters, alg_idx, err_type, x_axis, disp_metric)

    legend_entries = [];
    marker_array = {'-o', '-diamond' '-s', '-^', '-v', '-+', '-*', '-s'};
%{
    if alg_idx == 12
        [min_time, min_idx] = min(Data(:, alg_idx));
        x_axis_entry = Data(1, 15) / min_time;
        error_entry = Data(min_idx, alg_idx - err_type);
        plot(x_axis_entry, error_entry, marker_array{1}, MarkerSize=18, LineWidth=1.8);
        legend_entries{1} = ['Best speedup'];
        hold on

        [min_error, min_idx] = min(Data(:, alg_idx - err_type));
        x_axis_entry = Data(1, 15) / Data(min_idx, alg_idx);
        error_entry = min_error;
        plot(x_axis_entry, error_entry, marker_array{2}, MarkerSize=20, LineWidth=1.8);
        legend_entries{2} = ['Best accuracy'];
        hold on
    
    else 
%}
        ctr = 1;
        lgd_ctr = 1;
        for i = 1:num_krylov_iters:size(Data, 1)
            % Speedup over SVD for all krylov iterations using a given block
            % size for a given algorithm
            if x_axis == 1 || alg_idx ~= 6
                    % Speedup over SVD on the x_axis 
                    x_axis_vector = Data(i:(i+num_krylov_iters-1), 15) ./ Data(i:(i+num_krylov_iters-1), alg_idx);
            else
                % Num_matmuls on the x_axis 
                x_axis_vector = Data(i:(i+num_krylov_iters-1), 2);
            end
            error_vector = log10(1 ./ Data(i:(i+num_krylov_iters-1), alg_idx - err_type));
            if (mod(ctr, 2) ~= 0)
                plot(x_axis_vector, error_vector, marker_array{ctr}, MarkerSize=18, LineWidth=1.8);
                legend_entries{lgd_ctr} = ['b_{sz}=', num2str(Data(i, 1))]; %#ok<AGROW>
                hold on
                lgd_ctr = lgd_ctr + 1;
            end
            ctr = ctr+1;
        end
    %end

    % Plot params
    switch alg_idx
        case 6
            title('RandLAPACK ABRIK', 'FontSize', 20);
            if x_axis == 1
                title('RandLAPACK ABRIK', 'FontSize', 20);
            end
        case 9
            title('RandLAPACK RSVD', 'FontSize', 20);
        case 12
            title('Spectra SVDS', 'FontSize', 20);
            lgd = legend(legend_entries, 'Location', 'southeast');
    end

    if x_axis == 1 || alg_idx ~= 6
        xlim([0 1200]);
        xlabel('Speedup over SVD', 'FontSize', 20);  
    else
        xlim([Data(1, 2), Data(end, 2)]);
        xlabel('#Large Matmuls', 'FontSize', 20);
        lgd = legend(legend_entries, 'Location', 'northwest');
        xticks(Data(1:num_krylov_iters, 2));
    end

    if alg_idx == 12
        xlim([0 180]);
        %set(gca,'Yticklabel',[])
    end

    if alg_idx == 9
        xlim([0 600]);
        %set(gca,'Yticklabel',[])
    end


    %ylim([10^-15 1]);
    if disp_metric
        %ylabel('sqrt(||AV - ΣU||^2 + ||A^TU-VSΣ||^2)', 'FontSize', 20);
        ylabel('Digits of accuracy', 'FontSize', 20);
    end
    grid on
    lgd.FontSize = 20;
    %set(gca,'XScale','log');
    ax = gca;
    ax.XAxis.FontSize = 20;
    ax.YAxis.FontSize = 20;
    ylim([0 16]);
    yticks([0,  1, 5, 10, 15]);
    %xlim([0 1050]);
    %xticks([0,  100, 200, 500, 1000]);
end

function[Data_out] = data_preprocessing_best(Data_in, num_b_sizes, num_krylov_iters, numiters)
    
    Data_out = [];

    i = 1;
    num_columns_in_dataset = 15;
    distinct_ops_in_dataset = num_krylov_iters * num_b_sizes;
    % Iterating over the algorithms
    for k = 6:3:num_columns_in_dataset
        Data_out_alg = [];
        % Iterating over all rows for a given algorithm.
        while i < distinct_ops_in_dataset * numiters
            best_speed         = intmax;
            best_speed_row_idx = i;
            best_speed_col_idx = k;
            % Iterating over the runs for a given block size of a given
            % algorithm.
            for j = 1:numiters
                if Data_in(i, k) < best_speed
                    best_speed = Data_in(i, k);
                    best_speed_row_idx = i;
                    best_speed_col_idx = k;
                end
                i = i + 1;
            end
            % In case with RBKI set, we also need to add the accuracy
            % associated with the best speed idx.
            if k == 6
            Data_out_alg = [Data_out_alg; ...
                Data_in(best_speed_row_idx, 1), ...
                Data_in(best_speed_row_idx, 2), ...
                Data_in(best_speed_row_idx, 3), ...
                Data_in(best_speed_row_idx, best_speed_col_idx - 2), ...
                Data_in(best_speed_row_idx, best_speed_col_idx - 1), ...
                Data_in(best_speed_row_idx, best_speed_col_idx)]; %#ok<AGROW>
            else 
            Data_out_alg = [Data_out_alg; ...
                Data_in(best_speed_row_idx, best_speed_col_idx - 2), ...
                Data_in(best_speed_row_idx, best_speed_col_idx - 1), ...
                Data_in(best_speed_row_idx, best_speed_col_idx)]; %#ok<AGROW>
            end
        end
        i = 1;
        Data_out = [Data_out, Data_out_alg]; %#ok<AGROW>
    end

    % After the initial processing is done, we need to populate the set
    % with the best SVD speed & accuracy and the best SVDS speed and
    % accuracy
    Data_out(:, 15) = Data_out(1, 15) * ones(size(Data_out, 1), 1);
    Data_out(:, 14) = Data_out(1, 14) * ones(size(Data_out, 1), 1);
    Data_out(:, 13) = Data_out(1, 13) * ones(size(Data_out, 1), 1);
    %{
    for i = 1:num_krylov_iters:size(Data_out, 1)
        Data_out(i:(i+num_krylov_iters-1), 12) = Data_out(i, 12) * ones(num_krylov_iters, 1);
        Data_out(i:(i+num_krylov_iters-1), 11) = Data_out(i, 11) * ones(num_krylov_iters, 1);
        Data_out(i:(i+num_krylov_iters-1), 10) = Data_out(i, 10) * ones(num_krylov_iters, 1);
    end
    %}
end