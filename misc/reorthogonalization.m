% This is a simple procedure to illustrate orthogonalization wrt the past
% iterates.
A = randn(6, 2);
B = randn(6, 4);

[QA, ~] = qr(A, 0);
[QB, ~] = qr(B, 0);

QC = [QB, QA];
QC' * QC

Q = orth(QA - (QB(:, 1:2) * QB(:, 1:2)' * QA + QB(:, 3:4) * QB(:, 3:4)' * QA ));

QC = [QB, Q];
QC' * QC

% Different formulation of the same procedure

Q = orth(QA - (QB * QB' * QA ));

QC = [QB, Q];
QC' * QC