n = 10;
p = 4;
k = 2;

S = zeros(n, n);
S(1, 1) = 1;
A = orth(randn(n, n)) * S * orth(randn(n, n));
Qi = A * randn(n, k);
%Qi = randn(n, k);

Q = orth(randn(n, p));

R1 = Q' * Qi;
Qi = Qi - Q * R1;
Qi = Qi- Q * Q' * Qi;
[Qi, R2] = qr(Qi, 0);

fprintf("Error before the fancy tool %f\n", norm(eye(p + k, p + k) - [Q Qi]' * [Q Qi], 'fro'));

min_diag_val = realmax('double');
for i = 1:k
    min_diag_val = min(min_diag_val, abs(R2(i, i)));
end

%R2
%min_diag_val
%k * eps('double')

if min_diag_val < k * eps('double')
    U = orth(R2);
    Qi = Qi * U;
    Omega = randn(n, k - size(U, 2));
    Omega = Omega - [Q Qi] * [Q Qi]' * Omega;
    Omega = Omega - [Q Qi] * [Q Qi]' * Omega;
    [Qii, ~] = qr(Omega, 0);
    Qi = [Qi Qii];
    R2 = [U' * R2; zeros(k - size(U, 2), k)];
end

fprintf("Error after the fancy tool %f\n", norm(eye(p + k, p + k) - [Q Qi]' * [Q Qi], 'fro'));