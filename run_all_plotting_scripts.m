addpath('plotting_scripts/');
CPU_path_1        = "benchmark_output_abrik_paper/SapphireRapids/";
fig_path          = "output_figures/";
benchmarking_date = "";

show_lables = 1;


% Dense synthetic cases
%{
for i = 1:6
    figure('Name', ['abrik_precision_vs_performance_dense_mat_' num2str(i)], 'NumberTitle', 'off');
    filename = CPU_path_1 + "dense/" + benchmarking_date + "_ABRIK_speed_comparisons_num_info_lines_6.txt";
    abrik_precision_vs_speedup(filename, 10000, 10000, 6, 3, 3, 2, i, 1, 0);
    fig_save(gcf, fig_path, 14, 9);
end
%}
%{
% Matrix 1 and 6
figure('Name', 'abrik_runtime_breakdown_dense', 'NumberTitle', 'off');
filename = CPU_path_1 + "dense/" + benchmarking_date + "_ABRIK_runtime_breakdown_num_info_lines_6.txt";
abrik_runtime_breakdown(filename, 6, 3, 3, 16, 2, 0);
fig_save(gcf, fig_path, 14, 5);
%}

% Sparse real-world cases

%{
figure('Name', 'abrik_runtime_breakdown_sparse', 'NumberTitle', 'off');
filename = CPU_path_1 + "sparse/" + benchmarking_date + "_ABRIK_runtime_breakdown_sparse_num_info_lines_6.txt";
abrik_runtime_breakdown(filename, 4, 4, 3, 32, 1, 1);
fig_save(gcf, fig_path, 14, 5);
%}


% Sparse model reduction Mat 1-3 speed
figure('Name', ['abrik_precision_vs_speedup_mat_' num2str(1)], 'NumberTitle', 'off');
filename = CPU_path_1 + "sparse/" + benchmarking_date + "Mat1_ABRIK_speed_comparisons_sparse_num_info_lines_6.txt";
abrik_precision_vs_speedup_sparse(filename, 4, 4, 3, 1, 1, 1);
fig_save(gcf, fig_path, 10, 10);

figure('Name', ['abrik_precision_vs_speedup_mat_' num2str(2)], 'NumberTitle', 'off');
filename = CPU_path_1 + "sparse/" + benchmarking_date + "Mat2_ABRIK_speed_comparisons_sparse_num_info_lines_6.txt";
abrik_precision_vs_speedup_sparse(filename, 4, 5, 3, 2, 1, 1);
fig_save(gcf, fig_path, 10, 10);

figure('Name', ['abrik_precision_vs_speedup_mat_' num2str(3)], 'NumberTitle', 'off');
filename = CPU_path_1 + "sparse/" + benchmarking_date + "Mat3_ABRIK_speed_comparisons_sparse_num_info_lines_6.txt";
abrik_precision_vs_speedup_sparse(filename, 4, 5, 3, 3, 1, 1);
fig_save(gcf, fig_path, 10, 10);

% Sparse model reduction Mat 1-3 breakdown
figure('Name', 'abrik_runtime_breakdown_sparse', 'NumberTitle', 'off');
filename = CPU_path_1 + "sparse/" + benchmarking_date + "_ABRIK_runtime_breakdown_sparse_num_info_lines_6.txt";
abrik_runtime_breakdown(filename, 4, 6, 3, 32, 3, 1);
fig_save(gcf, fig_path, 14, 5);

% HM3 dataset from Rob's paper
figure('Name', 'abrik_precision_vs_performance_dense_mat_HM3', 'NumberTitle', 'off');
filename = CPU_path_1 + "dense/" + benchmarking_date + "HM3_ABRIK_speed_comparisons_num_info_lines_6.txt";
abrik_precision_vs_speedup(filename, 957, 6453, 7, 7, 3, 2, 1, 1, 0);
fig_save(gcf, fig_path, 14, 9);
