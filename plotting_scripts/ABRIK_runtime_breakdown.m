function[] = ABRIK_runtime_breakdown()
    
    % The first two entries in the dataset are: num_krylov_iters, b_sz
    filename = "../benchmark_output_abrik_paper/SapphireRapids/sparse/_ABRIK_runtime_breakdown_sparse_num_info_lines_6.txt";
    Data_in = readfile(filename, 6);
    Data_out = [];

    num_iters = 2;
    num_col_sizes = 1;

    [Data_in] = data_preprocessing_best(Data_in, num_col_sizes, num_iters);

    for j = 1 : 1
        Data_out(j, 1) = 100 * Data_in(j, 3)                     /Data_in(j, 15); %#ok<AGROW> % Preallocation
        Data_out(j, 2) = 100 * Data_in(j, 4)                     /Data_in(j, 15); %#ok<AGROW> % SVD factors
        Data_out(j, 3) = 100 * Data_in(j, 5)                     /Data_in(j, 15); %#ok<AGROW> % UNGQR()
        Data_out(j, 4) = 100 * Data_in(j, 6)                     /Data_in(j, 15); %#ok<AGROW> % Reorth
        Data_out(j, 5) = 100 * Data_in(j, 7)                     /Data_in(j, 15); %#ok<AGROW> % QR
        Data_out(j, 6) = 100 * Data_in(j, 8)                     /Data_in(j, 15); %#ok<AGROW> % GEMM(A)
        %Data_out(j, 7) = 100 * Data_in(j, 9)                    /Data_in(j, 15); %#ok<AGROW> % EXCLUDE THIS - Main Loop  
        %Data_out(j, 7) = 100 * Data_in(j, 10)                   /Data_in(j, 15); %#ok<AGROW> % Sketching
        Data_out(j, 7) = 100 * (Data_in(j, 11) + Data_in(j, 12)) /Data_in(j, 15); %#ok<AGROW> % R_cpy + S_cpy
        %Data_out(j, 11) = 100 * Data_in(j, 13)                  /Data_in(j, 15); %#ok<AGROW> % Norm
        %Data_out(j, 5) = 100 * Data_in(j, 14)                   /Data_in(j, 15); %#ok<AGROW> % Rest
        
        Data_out(j, 8) = 100 * (Data_in(j, 10) + Data_in(j, 13) + Data_in(j, 14)) /Data_in(j, 15); %#ok<AGROW> % rest
    end
    Data_out = [Data_out; Data_out]

    color_array = {'b', 'r', 'g', 'm', 'c', 'k', 'y', [0.5, 0.5, 0.5], [1, 0.647, 0]};

    bplot = bar(Data_out,'stacked');
    bplot(1).FaceColor = color_array{1};
    bplot(2).FaceColor = color_array{2};
    bplot(3).FaceColor = color_array{3};
    bplot(4).FaceColor = color_array{4};
    bplot(5).FaceColor = color_array{5};
    bplot(6).FaceColor = color_array{6};
    bplot(7).FaceColor = color_array{7};
    bplot(8).FaceColor = color_array{8};

    bplot(1).FaceAlpha = 0.8;
    bplot(2).FaceAlpha = 0.8;
    bplot(3).FaceAlpha = 0.8;
    bplot(4).FaceAlpha = 0.8;
    bplot(5).FaceAlpha = 0.8;
    bplot(6).FaceAlpha = 0.8;
    bplot(7).FaceAlpha = 0.8;
    bplot(8).FaceAlpha = 0.8;
    
    lgd = legend('Data Alloc','SVD+Factors', 'UNGQR', 'Reorth', 'QR', 'GEMM(M)', 'Copy', 'Other');
    legend('Location','southeastoutside'); 
    set(gca,'XTickLabel',{'128'});
    ylim([0 100]);
    ax = gca;
    ax.FontSize = 23; 
    lgd.FontSize = 20;

    title('ABRIK Runtime Breakdown', 'FontSize', 20);
    ylabel('Runtime %', 'FontSize', 20);
    xlabel('Block size', 'FontSize', 20);
end

function[Data_out] = data_preprocessing_best(Data_in, num_col_sizes, num_iters)
    
    Data_out = [];
    i = 1;

    Data_out = [];
    while i < num_col_sizes * num_iters
        best_speed = intmax;
        best_speed_idx = i;
        for j = 1:num_iters
            if Data_in(i, 15) < best_speed
                best_speed = Data_in(i, 15);
                best_speed_idx = i;
            end
            i = i + 1;
        end
        Data_out = [Data_out; Data_in(best_speed_idx, :)]; %#ok<AGROW>
    end
end