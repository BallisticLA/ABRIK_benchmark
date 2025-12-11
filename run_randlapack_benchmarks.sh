


<output_directory_path> <input_matrix_path> <lowrank_matrix_path> <num_runs> <num_rows> <num_cols> <custom_rank> <num_block_sizes> <num_matmul_sizes> <block_sizes> <mat_sizes>
# Intel CPU
# Dense speed
numactl --interleave=all env OMP_NUM_THREADS=128 ./ABRIK_speed_comparisons /lustre/isaac24/scratch/mmelnic1/ABRIK_benchmark/benchmark_output_abrik_paper/SapphireRapids/dense/ /lustre/isaac24/scratch/mmelnic1/ABRIK_benchmark/test_matrices/test_mat_10k_rank_2k/ABRIK_test_mat1.txt /lustre/isaac24/scratch/mmelnic1/ABRIK_benchmark/test_matrices/test_mat_10k_rank_2k/A_lowrank_mat1.txt 3 10000 10000 10 6 3 4 8 16 32 64 128 8 16 32;
numactl --interleave=all env OMP_NUM_THREADS=128 ./ABRIK_speed_comparisons /lustre/isaac24/scratch/mmelnic1/ABRIK_benchmark/benchmark_output_abrik_paper/SapphireRapids/dense/ /lustre/isaac24/scratch/mmelnic1/ABRIK_benchmark/test_matrices/test_mat_10k_rank_2k/ABRIK_test_mat2.txt /lustre/isaac24/scratch/mmelnic1/ABRIK_benchmark/test_matrices/test_mat_10k_rank_2k/A_lowrank_mat2.txt 3 10000 10000 10 6 3 4 8 16 32 64 128 8 16 32;
numactl --interleave=all env OMP_NUM_THREADS=128 ./ABRIK_speed_comparisons /lustre/isaac24/scratch/mmelnic1/ABRIK_benchmark/benchmark_output_abrik_paper/SapphireRapids/dense/ /lustre/isaac24/scratch/mmelnic1/ABRIK_benchmark/test_matrices/test_mat_10k_rank_2k/ABRIK_test_mat3.txt /lustre/isaac24/scratch/mmelnic1/ABRIK_benchmark/test_matrices/test_mat_10k_rank_2k/A_lowrank_mat3.txt 3 10000 10000 10 6 3 4 8 16 32 64 128 8 16 32;
numactl --interleave=all env OMP_NUM_THREADS=128 ./ABRIK_speed_comparisons /lustre/isaac24/scratch/mmelnic1/ABRIK_benchmark/benchmark_output_abrik_paper/SapphireRapids/dense/ /lustre/isaac24/scratch/mmelnic1/ABRIK_benchmark/test_matrices/test_mat_10k_rank_2k/ABRIK_test_mat4.txt /lustre/isaac24/scratch/mmelnic1/ABRIK_benchmark/test_matrices/test_mat_10k_rank_2k/A_lowrank_mat4.txt 3 10000 10000 10 6 3 4 8 16 32 64 128 8 16 32;
numactl --interleave=all env OMP_NUM_THREADS=128 ./ABRIK_speed_comparisons /lustre/isaac24/scratch/mmelnic1/ABRIK_benchmark/benchmark_output_abrik_paper/SapphireRapids/dense/ /lustre/isaac24/scratch/mmelnic1/ABRIK_benchmark/test_matrices/test_mat_10k_rank_2k/ABRIK_test_mat5.txt /lustre/isaac24/scratch/mmelnic1/ABRIK_benchmark/test_matrices/test_mat_10k_rank_2k/A_lowrank_mat5.txt 3 10000 10000 10 6 3 4 8 16 32 64 128 8 16 32;
numactl --interleave=all env OMP_NUM_THREADS=128 ./ABRIK_speed_comparisons /lustre/isaac24/scratch/mmelnic1/ABRIK_benchmark/benchmark_output_abrik_paper/SapphireRapids/dense/ /lustre/isaac24/scratch/mmelnic1/ABRIK_benchmark/test_matrices/test_mat_10k_rank_2k/ABRIK_test_mat6.txt /lustre/isaac24/scratch/mmelnic1/ABRIK_benchmark/test_matrices/test_mat_10k_rank_2k/A_lowrank_mat6.txt 3 10000 10000 10 6 3 4 8 16 32 64 128 8 16 32;

# Dense runtime breakdown
<output_directory_path> <input_matrix_path> <num_runs> <num_rows> <num_cols> <custom_rank> <num_block_sizes> <num_matmul_sizes> <block_sizes> <mat_sizes>
numactl --interleave=all env OMP_NUM_THREADS=128 ./ABRIK_runtime_breakdown /lustre/isaac24/scratch/mmelnic1/ABRIK_benchmark/benchmark_output_abrik_paper/SapphireRapids/dense/ /lustre/isaac24/scratch/mmelnic1/ABRIK_benchmark/test_matrices/test_mat_10k_rank_2k/ABRIK_test_mat1.txt 3 10000 10000 10 6 3 4 8 16 32 64 128 8 16 32;
numactl --interleave=all env OMP_NUM_THREADS=128 ./ABRIK_runtime_breakdown /lustre/isaac24/scratch/mmelnic1/ABRIK_benchmark/benchmark_output_abrik_paper/SapphireRapids/dense/ /lustre/isaac24/scratch/mmelnic1/ABRIK_benchmark/test_matrices/test_mat_10k_rank_2k/ABRIK_test_mat6.txt 3 10000 10000 10 6 3 4 8 16 32 64 128 8 16 32;

# Sparse speed
<output_directory_path> <input_matrix_path> <num_runs> <target_rank> <num_block_sizes> <num_matmul_sizes> <block_sizes> <mat_sizes>
numactl --interleave=all env OMP_NUM_THREADS=128 ./ABRIK_speed_comparisons_sparse /lustre/isaac24/scratch/mmelnic1/ABRIK_benchmark/benchmark_output_abrik_paper/SapphireRapids/sparse/ /lustre/isaac24/scratch/mmelnic1/ABRIK_benchmark/test_matrices/suitsparse/CurlCurl_0/CurlCurl_0.mtx 3 10 6 4 16 32 64 128 256 512 8 16 32 64;
numactl --interleave=all env OMP_NUM_THREADS=128 ./ABRIK_speed_comparisons_sparse /lustre/isaac24/scratch/mmelnic1/ABRIK_benchmark/benchmark_output_abrik_paper/SapphireRapids/sparse/ /lustre/isaac24/scratch/mmelnic1/ABRIK_benchmark/test_matrices/suitsparse/CurlCurl_1/CurlCurl_1.mtx 3 10 6 4 16 32 64 128 256 512 8 16 32 64;
numactl --interleave=all env OMP_NUM_THREADS=128 ./ABRIK_speed_comparisons_sparse /lustre/isaac24/scratch/mmelnic1/ABRIK_benchmark/benchmark_output_abrik_paper/SapphireRapids/sparse/ /lustre/isaac24/scratch/mmelnic1/ABRIK_benchmark/test_matrices/suitsparse/CurlCurl_2/CurlCurl_2.mtx 3 10 6 4 16 32 64 128 256 512 8 16 32 64;
numactl --interleave=all env OMP_NUM_THREADS=128 ./ABRIK_speed_comparisons_sparse /lustre/isaac24/scratch/mmelnic1/ABRIK_benchmark/benchmark_output_abrik_paper/SapphireRapids/sparse/ /lustre/isaac24/scratch/mmelnic1/ABRIK_benchmark/test_matrices/suitsparse/CurlCurl_3/CurlCurl_3.mtx 3 10 6 4 16 32 64 128 256 512 8 16 32 64;
numactl --interleave=all env OMP_NUM_THREADS=128 ./ABRIK_speed_comparisons_sparse /lustre/isaac24/scratch/mmelnic1/ABRIK_benchmark/benchmark_output_abrik_paper/SapphireRapids/sparse/ /lustre/isaac24/scratch/mmelnic1/ABRIK_benchmark/test_matrices/suitsparse/CurlCurl_4/CurlCurl_4.mtx 3 10 6 4 16 32 64 128 256 512 8 16 32 64;

# Sparse runtime breakdown                                                                                                                                                                                                                                                     
numactl --interleave=all env OMP_NUM_THREADS=128 ./ABRIK_runtime_breakdown_sparse /lustre/isaac24/scratch/mmelnic1/ABRIK_benchmark/benchmark_output_abrik_paper/SapphireRapids/sparse/ /lustre/isaac24/scratch/mmelnic1/ABRIK_benchmark/test_matrices/suitsparse/CurlCurl_1/CurlCurl_1.mtx 3 10 6 4 16 32 64 128 256 512 8 16 32 64;
numactl --interleave=all env OMP_NUM_THREADS=128 ./ABRIK_runtime_breakdown_sparse /lustre/isaac24/scratch/mmelnic1/ABRIK_benchmark/benchmark_output_abrik_paper/SapphireRapids/sparse/ /lustre/isaac24/scratch/mmelnic1/ABRIK_benchmark/test_matrices/suitsparse/CurlCurl_2/CurlCurl_2.mtx 3 10 6 4 16 32 64 128 256 512 8 16 32 64;
numactl --interleave=all env OMP_NUM_THREADS=128 ./ABRIK_runtime_breakdown_sparse /lustre/isaac24/scratch/mmelnic1/ABRIK_benchmark/benchmark_output_abrik_paper/SapphireRapids/sparse/ /lustre/isaac24/scratch/mmelnic1/ABRIK_benchmark/test_matrices/suitsparse/CurlCurl_3/CurlCurl_3.mtx 3 10 6 4 16 32 64 128 256 512 8 16 32 64;
numactl --interleave=all env OMP_NUM_THREADS=128 ./ABRIK_runtime_breakdown_sparse /lustre/isaac24/scratch/mmelnic1/ABRIK_benchmark/benchmark_output_abrik_paper/SapphireRapids/sparse/ /lustre/isaac24/scratch/mmelnic1/ABRIK_benchmark/test_matrices/suitsparse/CurlCurl_4/CurlCurl_4.mtx 3 10 6 4 16 32 64 128 256 512 8 16 32 64;


# HM3 small dataset
numactl --interleave=all env OMP_NUM_THREADS=128 ./ABRIK_speed_comparisons /lustre/isaac24/scratch/mmelnic1/ABRIK_benchmark/benchmark_output_abrik_paper/SapphireRapids/dense/HM3 /lustre/isaac24/scratch/mmelnic1/ABRIK_benchmark/test_matrices/H3_normalized_small.txt . 3 957 14079 5 7 7 4 8 16 32 64 128 256 4 8 16 32 64 128 256;

# Densified CurlCurl_0
numactl --interleave=all env OMP_NUM_THREADS=128 ./ABRIK_speed_comparisons /lustre/isaac24/scratch/mmelnic1/ABRIK_benchmark/benchmark_output_abrik_paper/SapphireRapids/dense/CurlCurl0_densified /lustre/isaac24/scratch/mmelnic1/ABRIK_benchmark/test_matrices/CurlCurl_0_dense.txt . 3 11083 11083 10 6 4 16 32 64 128 256 512 8 16 32 64;

numactl --interleave=all env OMP_NUM_THREADS=128 ./ABRIK_speed_comparisons_sparse /lustre/isaac24/scratch/mmelnic1/ABRIK_benchmark/benchmark_output_abrik_paper/SapphireRapids/sparse/CurlCurl0 /lustre/isaac24/scratch/mmelnic1/ABRIK_benchmark/test_matrices/suitsparse/CurlCurl_0/CurlCurl_0.mtx 3 10 6 4 16 32 64 128 256 512 8 16 32 64;


# TEMPORARY
numactl --interleave=all env OMP_NUM_THREADS=128 ./ABRIK_speed_comparisons /lustre/isaac24/scratch/mmelnic1/ABRIK_benchmark/benchmark_output_abrik_paper/SapphireRapids/dense/Float /lustre/isaac24/scratch/mmelnic1/ABRIK_benchmark/test_matrices/test_mat_10k_rank_2k/ABRIK_test_mat1.txt /lustre/isaac24/scratch/mmelnic1/ABRIK_benchmark/test_matrices/test_mat_10k_rank_2k/A_lowrank_mat1.txt 3 10000 10000 10 6 4 16 32 64 128 256 512 8 16 32 64;














numactl --interleave=all env OMP_NUM_THREADS=128 ./ABRIK_speed_comparisons_sparse /lustre/isaac24/scratch/mmelnic1/ABRIK_benchmark/benchmark_output_abrik_paper/SapphireRapids/sparse/ /lustre/isaac24/scratch/mmelnic1/ABRIK_benchmark/test_matrices/suitsparse/CurlCurl_0/CurlCurl_0.mtx 3 10 5 4 16 32 64 128 256 8 16 32 64;
numactl --interleave=all env OMP_NUM_THREADS=128 ./ABRIK_speed_comparisons_sparse /lustre/isaac24/scratch/mmelnic1/ABRIK_benchmark/benchmark_output_abrik_paper/SapphireRapids/sparse/ /lustre/isaac24/scratch/mmelnic1/ABRIK_benchmark/test_matrices/suitsparse/CurlCurl_1/CurlCurl_1.mtx 3 10 5 4 16 32 64 128 256 8 16 32 64;
numactl --interleave=all env OMP_NUM_THREADS=128 ./ABRIK_runtime_breakdown_sparse /lustre/isaac24/scratch/mmelnic1/ABRIK_benchmark/benchmark_output_abrik_paper/SapphireRapids/sparse/ /lustre/isaac24/scratch/mmelnic1/ABRIK_benchmark/test_matrices/suitsparse/CurlCurl_1/CurlCurl_0.mtx 3 10 5 4 16 32 64 128 256 8 16 32 64;
numactl --interleave=all env OMP_NUM_THREADS=128 ./ABRIK_runtime_breakdown_sparse /lustre/isaac24/scratch/mmelnic1/ABRIK_benchmark/benchmark_output_abrik_paper/SapphireRapids/sparse/ /lustre/isaac24/scratch/mmelnic1/ABRIK_benchmark/test_matrices/suitsparse/CurlCurl_2/CurlCurl_1.mtx 3 10 5 4 16 32 64 128 256 8 16 32 64;












NEW NEW NEW

numactl --interleave=all env OMP_NUM_THREADS=128 ./ABRIK_speed_comparisons_sparse /lustre/isaac24/scratch/mmelnic1/ABRIK_benchmark/benchmark_output_abrik_paper/NEW/sparse/ten_triplets_ /lustre/isaac24/scratch/mmelnic1/ABRIK_benchmark/test_matrices/suitsparse/CurlCurl_0/CurlCurl_0.mtx 3 10 6 4 16 32 64 128 256 512 8 16 32 64;
numactl --interleave=all env OMP_NUM_THREADS=128 ./ABRIK_speed_comparisons_sparse /lustre/isaac24/scratch/mmelnic1/ABRIK_benchmark/benchmark_output_abrik_paper/NEW/sparse/five_triplets_ /lustre/isaac24/scratch/mmelnic1/ABRIK_benchmark/test_matrices/suitsparse/CurlCurl_0/CurlCurl_0.mtx 3 5 6 4 16 32 64 128 256 512 8 16 32 64;
numactl --interleave=all env OMP_NUM_THREADS=128 ./ABRIK_speed_comparisons_sparse /lustre/isaac24/scratch/mmelnic1/ABRIK_benchmark/benchmark_output_abrik_paper/NEW/sparse/one_triplet_ /lustre/isaac24/scratch/mmelnic1/ABRIK_benchmark/test_matrices/suitsparse/CurlCurl_0/CurlCurl_0.mtx 3 1 6 4 16 32 64 128 256 512 8 16 32 64;



