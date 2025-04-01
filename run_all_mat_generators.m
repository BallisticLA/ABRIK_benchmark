addpath('matrix_generators/')

figure
gen_mat_alg971_paper("/test_mat_10k_rank_2k/", 10000, 10000, 2000, 49, "generate")

gen_mat_rob_paper("/test_mat_rob_paper/", 10000, 10000, 49)