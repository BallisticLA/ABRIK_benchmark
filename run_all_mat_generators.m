addpath('matrix_generators/')

figure
gen_mat_alg971_paper("/test_mat_10k_rank_2k/", 1000, 1000, 200, 49, "generate")

gen_mat_rob_paper("/test_mat_rob_paper/", 1000, 1000, 49)