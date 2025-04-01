% Matrix from Rob's very first example in the paper
function[] = gen_mat_rob_paper(folder_name, m, n, plotting_interval)

    file_path = "../test_matrices/" + folder_name;
    if ~exist(file_path, 'dir')
        mkdir(file_path);
    end

    U = randn(m, n);
    [U, ~] = qr(U, 0);
    V = randn(n, n);
    [V, ~] = qr(V, 0);

    Sigma = zeros(2, n);
    Sigma(1, :) = gen_mat_1(n);
    Z = 0.002^2 * randn(m, n);

    Mat1_file = "Mat_simple.txt";
    Mat2_file = "Mat_hard.txt";

    Mat1_file_id = fopen(file_path + Mat1_file, 'w');  
    Mat2_file_id = fopen(file_path + Mat2_file, 'w'); 
    fclose(Mat1_file_id);
    fclose(Mat2_file_id);

    writematrix(U * diag(Sigma(1, :)) * V',     file_path + Mat1_file,'delimiter',' ');
    writematrix(U * diag(Sigma(1, :)) * V' + Z, file_path + Mat2_file,'delimiter',' ');

    %plot(Sigma, n, plotting_interval, file_path) 
end

function[] = plot(Sigma, n, plotting_interval, file_path) 
    marker_array = {'-+', '-o', '-s', '-^', '-v', '-diamond', '-*'};
    x = 1:plotting_interval:n;
    hold on
    semilogy(x, Sigma(1, 1:plotting_interval:end), marker_array{1}, MarkerSize=18, LineWidth=1.8)
    hold on
    semilogy(x, Sigma(2, 1:plotting_interval:end), marker_array{2}, MarkerSize=18, LineWidth=1.8)
    
    grid on
    xlabel('k', 'FontSize', 20);
    ylabel('sigma[k]', 'FontSize', 20);
    lgd = legend('Mat 1', 'Mat 2');
    lgd.FontSize = 20;
    ax.XAxis.FontSize = 20;
    ax.YAxis.FontSize = 20;

    saveas(gcf, file_path + 'specta_plot.fig')
end

function[Sigma] = gen_mat_1(n)
    Sigma = zeros(1, n);
    for j = 0:n-1
        Sigma(1, j+1) = exp(1)^(-0.1 * j);
    end
end