function[] = abrik_runtime_breakdown(filename, num_b_sizes, num_matmuls, num_iters, b_sz_show, num_matrices_to_process, show_lables)
    
    % The first two entries in the dataset are: num_matmuls, b_sz
    Data_in = readfile(filename, 6);
    plot_position = 1;

    tiledlayout(1, num_matrices_to_process,"TileSpacing","loose");
    for i = 1:num_matrices_to_process
        nexttile
        process_and_plot(Data_in(num_iters*num_matmuls*num_b_sizes*(i-1)+1:num_iters*num_matmuls*num_b_sizes*i, :), num_iters, num_b_sizes, num_matmuls, show_lables, b_sz_show, plot_position, num_matrices_to_process)
        plot_position = plot_position + 1;
    end
end

function[] = process_and_plot(Data_in, num_iters, num_b_sizes, num_matmuls, show_lables, b_sz_show, plot_position, num_matrices_to_process)

    % Below gives us the fastest iteration for each given blocksize and
    % #matmuls combination.
    [Data_in] = data_preprocessing_best(Data_in, num_b_sizes, num_matmuls, num_iters);

    % It probably only makes sense to plot data for a single block size &
    % all of the matmuls associated with that block size.
    Data_in = Data_in(Data_in(:,1) == b_sz_show, :);
    Data_out = [];

    for j = 1 : num_matmuls
        Data_out(j, 1) = 100 * Data_in(j, 3)                     /Data_in(j, 15); %#ok<AGROW> % Preallocation
        Data_out(j, 2) = 100 * Data_in(j, 4)                     /Data_in(j, 15); %#ok<AGROW> % SVD factors
        Data_out(j, 3) = 100 * Data_in(j, 5)                     /Data_in(j, 15); %#ok<AGROW> % ORGQR()
        Data_out(j, 4) = 100 * Data_in(j, 6)                     /Data_in(j, 15); %#ok<AGROW> % Reorth
        Data_out(j, 5) = 100 * Data_in(j, 7)                     /Data_in(j, 15); %#ok<AGROW> % QR
        Data_out(j, 6) = 100 * Data_in(j, 8)                     /Data_in(j, 15); %#ok<AGROW> % GEMM(A)
        %Data_out(j, 7) = 100 * Data_in(j, 9)                    /Data_in(j, 15); %#ok<AGROW> % EXCLUDE THIS - Main Loop  
        %Data_out(j, 7) = 100 * Data_in(j, 10)                   /Data_in(j, 15); %#ok<AGROW> % Sketching
        %Data_out(j, 7) = 100 * (Data_in(j, 11) + Data_in(j, 12)) /Data_in(j, 15); %#ok<AGROW> % R_cpy + S_cpy
        %Data_out(j, 11) = 100 * Data_in(j, 13)                  /Data_in(j, 15); %#ok<AGROW> % Norm
        %Data_out(j, 5) = 100 * Data_in(j, 14)                   /Data_in(j, 15); %#ok<AGROW> % Rest
        
        Data_out(j, 7) = 100 * (Data_in(j, 10) + Data_in(j, 11) + Data_in(j, 12) + Data_in(j, 13) + Data_in(j, 14)) /Data_in(j, 15); %#ok<AGROW> % rest
    end

    color_array = {'b', 'r', 'g', 'm', 'c', 'k', [0.5, 0.5, 0.5], [1, 0.647, 0]};

    bplot = bar(Data_out,'stacked');
    bplot(1).FaceColor = color_array{1};
    bplot(2).FaceColor = color_array{2};
    bplot(3).FaceColor = color_array{3};
    bplot(4).FaceColor = color_array{4};
    bplot(5).FaceColor = color_array{5};
    bplot(6).FaceColor = color_array{6};
    bplot(7).FaceColor = color_array{7};

    bplot(1).FaceAlpha = 0.8;
    bplot(2).FaceAlpha = 0.8;
    bplot(3).FaceAlpha = 0.8;
    bplot(4).FaceAlpha = 0.8;
    bplot(5).FaceAlpha = 0.8;
    bplot(6).FaceAlpha = 0.8;
    bplot(7).FaceAlpha = 0.8;

    % We want to place #singular triplets approximated on the x-axis
    x_axis_vector = Data_in(:, 1) .* Data_in(:, 2) ./ 2;
    set(gca,'XTickLabel', x_axis_vector);

    if plot_position == num_matrices_to_process
        set(gca,'Yticklabel',[])
        lgd = legend('Data Alloc','SVD+Factors', 'ORGQR', 'Reorth', 'QR', 'GEMM(M)', 'Other');
        legend('Location','northeastoutside'); 
    end

    ylim([0 100]);
    ax = gca;
    ax.FontSize = 23; 
    lgd.FontSize = 20;

    if show_lables
        title(['ABRIK Runtime Breakdown b\_sz = ' num2str(b_sz_show)], 'FontSize', 20);
        if plot_position == 1
            ylabel('Runtime %', 'FontSize', 20);
        end
        xlabel('#triplets', 'FontSize', 20);
    end
end

function[Data_out] = data_preprocessing_best(Data_in, num_b_sizes, num_matmuls, num_iters)
    
    Data_out = [];

    i = 1;
    distinct_ops_in_dataset = num_matmuls * num_b_sizes;
    % Iterating over all rows for a given algorithm.
    while i < distinct_ops_in_dataset * num_iters
        best_speed         = intmax;
        best_speed_row_idx = i;
        % Iterating over the runs for a given block size of a given
        % algorithm.
        for j = 1:num_iters
            % If a timing of zero is encountered, it is ignored.
            if (Data_in(i, 15) < best_speed) && (Data_in(i, 15) ~= 0)
                best_speed = Data_in(i, 15);
                best_speed_row_idx = i;
            end
            i = i + 1;
        end
        Data_out = [Data_out; Data_in(best_speed_row_idx, :)]; %#ok<AGROW>
    end
end
