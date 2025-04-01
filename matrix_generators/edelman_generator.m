% Code from "FAST COMPUTATION OF THE PRINCIPAL COMPONENTS OF
% GENOTYPE MATRICES IN JULIA" suggested by Rob Webber on 04/02/2024.
function A = edelman_generator(m, n, r, nsignal, rkins)
    A = zeros(m, n);

    % Model population admixing
    % by randomly setting a subblock to the same value, k
    for i = 1:r
        k = randi([0,2]);
        r1 = randi([1, m]);
        r2 = randi([1, n]);
        A(r1, r2) = k;
    end

    % Model signal
    for i = 1:nsignal
        A(randi([1, m]), randi([1, n])) = randi([0,2]);
    end

    % Model kinship by duplicating rows
    nkins = round(rkins * m);
    for i = 1:nkins
        row_to_duplicate = randi([1, m]);
        A(row_to_duplicate, :) = A(row_to_duplicate, :);
    end
    writematrix(A, 'RBKI_test_mat1.txt','delimiter',' ');
end

function indices = randrange(n)
    i1 = randi([1, n]);
    i2 = randi([1, n]);
    if i1 > i2
        indices = i2:i1;
    else
        indices = i1:i2;
    end
end