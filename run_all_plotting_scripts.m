addpath('plotting_scripts/');
CPU_path_1        = "benchmark_output_abrik_paper/SapphireRapids/";
fig_path          = "output_figures/";
benchmarking_date = "";

show_lables = 1;


for i = 1:6
%% 
    figure('Name', ['abrik_precision_vs_speedup_mat_' num2str(i)], 'NumberTitle', 'off');
    filename = CPU_path_1 + "dense/" + benchmarking_date + "_ABRIK_speed_comparisons_num_info_lines_6.txt";
    abrik_precision_vs_speedup(filename, 6, 4, 3, 2, i, 1, 1);
    fig_save(gcf, fig_path, 17, 4.5);
end