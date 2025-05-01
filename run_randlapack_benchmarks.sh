


<output_directory_path> <input_matrix_path> <lowrank_matrix_path> <num_runs> <num_rows> <num_cols> <custom_rank> <num_block_sizes> <num_matmul_sizes> <block_sizes> <mat_sizes>
numactl --interleave=all env OMP_NUM_THREADS=128 ./RBKI_speed_comparisons /lustre/isaac/scratch/mmelnic1/BALLISTIC_RNLA_2025/build/benchmark-build/ABRIK_benchmark/benchmark_output_abrik_paper/SapphireRapids/abrik_precision_vs_speedup/ /lustre/isaac/scratch/mmelnic1/BALLISTIC_RNLA_2025/build/benchmark-build/ABRIK_benchmark/test_matrices/test_mat_10k_rank_2k/ABRIK_test_mat1.txt /lustre/isaac/scratch/mmelnic1/BALLISTIC_RNLA_2025/build/benchmark-build/ABRIK_benchmark/test_matrices/test_mat_10k_rank_2k/A_lowrank_mat1.txt 3 10000 10000 10 6 4 4 8 16 32 64 128 2 4 8 16


<output_directory_path> <input_matrix_path> <lowrank_matrix_path> <num_runs> <num_rows> <num_cols> <custom_rank> <num_block_sizes> <num_matmul_sizes> <block_sizes> <mat_sizes>
numactl --interleave=all env OMP_NUM_THREADS=448 ./RBKI_speed_comparisons /lustre/isaac/scratch/mmelnic1/BALLISTIC_RNLA_2025/build/benchmark-build/ABRIK_benchmark/benchmark_output_abrik_paper/Zen4c/abrik_precision_vs_speedup/ /lustre/isaac/scratch/mmelnic1/BALLISTIC_RNLA_2025/build/benchmark-build/ABRIK_benchmark/test_matrices/test_mat_10k_rank_2k/ABRIK_test_mat1.txt /lustre/isaac/scratch/mmelnic1/BALLISTIC_RNLA_2025/build/benchmark-build/ABRIK_benchmark/test_matrices/test_mat_10k_rank_2k/A_lowrank_mat1.txt 3 10000 10000 10 6 4 4 8 16 32 64 128 2 4 8 16
