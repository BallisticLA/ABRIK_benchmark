function rank_deficiency_grid()
% rank_deficiency_grid - which rank-deficiency strategy makes ABRIK most robust?
%
% Supersedes min_repair{,2,3}.m (2026-08-11), which were throwaway probes.
%
% WHY THIS SHAPE. The 2026-07-29 C++ attempt removed BK's rank-deficiency exit
% and nine tests failed, which was read as "continuing past deficiency corrupts
% the factorization". Reading test_abrik.cc settles it differently:
% test_ABRIK_general sets max_krylov_iters = 2*target_rank/b_sz, i.e. EXACTLY the
% saturation count, so every non-adaptive test marches to subspace exhaustion and
% relies on that exit to stop it. The exit is doing two jobs at once:
%   (1) detecting a rank-deficient block, and
%   (2) acting as the de facto SATURATION guard.
% Removing it removed (2). Every strategy below therefore keeps an explicit
% saturation guard and varies only (1), which is the question actually asked.
%
% Strategies (all keep the saturation guard):
%   S0  trailing diagonal < sqrt(eps) -> discard the WHOLE block, stop
%   S0p ACTUAL C++ BEHAVIOUR: commit the whole block, junk columns included, stop.
%       Verified 2026-08-11 in rl_bk.hh: the break at :572 skips the "Grow R buffer"
%       step, but that step sizes the buffer for the NEXT block. end_cols is derived
%       from `iter` at :753, and ++iter is at :730, AFTER the break -- so breaking at
%       iter = 2m+1 gives end_cols = (m+1)k, which counts the flagged block. S0 above
%       is therefore NOT the current code; it was my misreading. Kept as a comparison.
%   S1  commit the healthy leading columns, then stop
%   S2  prune deficient columns, continue with a narrower block
%   S3  Rob's red 303: prune, replace with fresh random draws, continue
%   S4  prune, replace with M*g (stays inside range(M)), continue
%   S5  no deficiency detection at all; only the saturation guard stops it
%   S7  Balabanov RRRCholQR criterion: pivot, trailing-BLOCK Frobenius test,
%       threshold relative to ||M|| with tau = n*eps (see the S7 case for why)
%   S6  S3 plus a STOPPING RULE, so continuation is not wasted where nothing remains.
%       Replace as S3 does, then ask whether the operator does anything with the
%       replacements: if every replaced direction v has ||M'v|| below tol*||M||, the
%       operator annihilates them, so there is genuinely no content left. Drop those
%       columns and stop. Otherwise commit and continue. Costs nothing extra: M'*Qi is
%       already computed to form the next block.
%
% REQUEST SIZE. kreq is deliberately LARGE (150). At kreq = 10 the leading triplets
% converge long before deficiency handling has any effect, which is what made an earlier
% pass of this grid rank stopping above continuing. The question Rob's comment actually
% raises is whether a FALSE deficiency signal stops the algorithm before it has delivered
% what was asked, and only a demanding request can see that.
%
% Reported per cell: triplets delivered vs available, leading-triplet residual
% (eq. 2.4, per-triplet normalized), basis orthogonality, a NOISE COUNT (returned
% triplets whose true singular value is ~0 -- padding output with noise is worse
% than honest under-delivery), and cost in operator applications.

    strategies = {'S0','S0p','S1','S2','S3','S4','S5','S6','S7','S8','S9','S10'};
    seeds = 1:5;                        % robustness: one seed is not evidence
    tests = build_tests();
    fprintf('\n%-24s %-4s %6s %8s %6s %8s %10s %7s\n', ...
            'matrix', 'strat', 'owed', 'MET', 'GOODmd', 'resid10mx', 'orthMAX', 'opsMd');
    for t = 1:numel(tests)
        T = tests{t};
        owed = min(T.kreq, T.avail);
        for s = 1:numel(strategies)
            g = zeros(1,numel(seeds)); rr = g; oo = g; pp = g;
            for q = 1:numel(seeds)
                r = run_case(T, strategies{s}, seeds(q));
                g(q) = r.claim - r.bogus; rr(q) = r.resid; oo(q) = r.orth; pp(q) = r.ops;
            end
            fprintf('%-24s %-4s %6d %8s %6d %8.1e %10.1e %7d\n', ...
                    T.name, strategies{s}, owed, ...
                    sprintf('%d/%d', sum(g >= owed), numel(seeds)), ...
                    round(median(g)), max(rr), max(oo), round(median(pp)));
        end
        fprintf('\n');
    end
    fprintf(['claim   = triplets the algorithm reports (ABRIK singular_triplets_found = end_cols)\n' ...
             'GOOD    = of those, how many CERTIFY: eq.(2.4) residual below 1e-8. A fabricated\n' ...
             '          direction cannot pass a two-sided test, so this is real content only.\n' ...
             'owed    = min(requested = 150, mathematically available). What success means here.\n' ...
             'MET     = on how many of 5 seeds did the strategy deliver everything it owed?\n' ...
             'GOODmd  = median certified triplets across seeds\n' ...
             'resid10mx / orthMAX = WORST case across seeds, not the median\n\n']);
end

% ---------------------------------------------------------------- test matrices
function tests = build_tests()
    rng(0,'twister'); tests = {};
    n = 200; b = 10; kreq = 150;   % demanding on purpose; see REQUEST SIZE in the header

    tests{end+1} = mk('T1 identity',        eye(n),                 n, b, kreq, n);

    r = 25;  tests{end+1} = mk('T2 exact rank 25',  lowrank(n,r),   n, b, kreq, r);
    r = 40;  tests{end+1} = mk('T3 exact rank 40',  lowrank(n,r),   n, b, kreq, r);

    % T4: full rank on paper, 15 directions numerically dead
    s = [logspace(0,-3,n-15), 1e-18*ones(1,15)];
    tests{end+1} = mk('T4 15 dead directions', withspec(n,s), n, b, kreq, n-15);

    % T5: full rank, ill-conditioned, NO true deficiency
    s = logspace(0,-10,n);
    tests{end+1} = mk('T5 kappa 1e10 full rank', withspec(n,s), n, b, kreq, n);

    % T6: repeated singular value with multiplicity 15 > b
    s = [ones(1,15), logspace(-1,-4,n-15)];
    tests{end+1} = mk('T6 multiplicity 15 > b', withspec(n,s), n, b, kreq, n);
end

function T = mk(name, M, n, b, kreq, avail)
    [~,S,~] = svd(M,'econ'); s = diag(S);
    T = struct('name',name,'M',M,'n',n,'b',b,'kreq',kreq,'avail',avail,'strue',s);
end
function M = lowrank(n,r)
    [U,~] = qr(randn(n,r),0); [V,~] = qr(randn(n,r),0);
    M = U*diag(logspace(0,-3,r).')*V';
end
function M = withspec(n,s)
    [U,~] = qr(randn(n),0); [V,~] = qr(randn(n),0); M = U*diag(s)*V';
end

% ------------------------------------------------------------------- one case
function out = run_case(T, strat, seed)
    % Reseed per cell. The RNG is otherwise seeded once in build_tests, so each cell would
    % consume a different slice of the stream and no two strategies would see the same
    % starting block or the same replacement draws. That is not a controlled comparison,
    % and it made S3's orthogonality on T5 swing between 2.3e-14 and 7.1e-01 across runs
    % purely from stream drift. Fixed seed here => every strategy faces identical draws,
    % and every cell is reproducible.
    rng(seed,'twister');

    M = T.M; n = T.n; b = T.b; tol = sqrt(eps); pmax = 30;
    Q = zeros(size(M,1),0); ops = 0; repl_idx = []; normM = T.strue(1);
    W = M*randn(n,b); ops = ops + b;

    for blk = 1:pmax
        if ~isempty(Q), W = W - Q*(Q'*W); W = W - Q*(Q'*W); end
        [Qi, Ri] = qr(W, 0);
        d = abs(diag(Ri));  defic = d < tol*max([d(1) 1]);

        % SATURATION GUARD, kept by every strategy: the basis cannot exceed the
        % ambient dimension. This is the job BK's exit was silently also doing.
        if size(Q,2) >= min(size(M)), break; end

        switch strat
            case 'S0'
                if any(defic), break; end                    % discard whole block
            case 'S0p'
                if any(defic)                                % ACTUAL C++: commit all k, stop
                    Q = [Q Qi]; break;                       %#ok<AGROW>
                end
            case 'S1'
                if any(defic)                                % keep healthy prefix
                    last = find(~defic, 1, 'last');
                    keep = false(size(defic)); if ~isempty(last), keep(1:last) = ~defic(1:last); end
                    Qi = Qi(:,keep);
                    if isempty(Qi), break; end
                    Q = [Q Qi]; break;                       %#ok<AGROW>
                end
            case {'S2','S3','S4','S6'}
                if any(defic)
                    idx = find(defic);
                    if strcmp(strat,'S2')
                        Qi = Qi(:,~defic);
                        if isempty(Qi), break; end
                    else
                        repl_idx = idx(:).';        % S6 probes these below
                        for j = idx.'
                            if strcmp(strat,'S4'), v = M*randn(n,1); ops = ops + 1;
                            else,                  v = randn(size(M,1),1); end
                            v = v - Q*(Q'*v);
                            if j > 1, v = v - Qi(:,1:j-1)*(Qi(:,1:j-1)'*v); end
                            v = v - Q*(Q'*v);
                            nv = norm(v);
                            if nv < 1e-300, v = randn(size(M,1),1); v = v - Q*(Q'*v); nv = norm(v); end
                            Qi(:,j) = v/nv;
                        end
                    end
                end
            case 'S5'
                % no detection; saturation guard above is the only stop

            case 'S7'
                % Balabanov, "Randomized Cholesky QR factorizations", arXiv:2210.09953,
                % Algorithm 7 (RRRCholQR) + Theorem 5.6. Three changes from S0:
                %   (a) PIVOT. Without it "the leading healthy run" is a heuristic: a small
                %       interior diagonal does not imply the later columns are junk.
                %       Balabanov pivots the d-by-n SKETCH, not the m-by-n block, so this
                %       is nearly free -- which answers the bottleneck worry directly.
                %   (b) Test the trailing BLOCK's Frobenius norm, not one diagonal entry.
                %   (c) Threshold RELATIVE to the operator scale, not the absolute
                %       sqrt(eps). Theorem 5.6: cond(X(1:r)) <= 10 n^1.5 r / tau, so tau is
                %       a contract on the conditioning we accept, not a guess about the
                %       matrix. sqrt(eps) = 1.5e-8 is far too coarse: it discards T5's
                %       genuine 1e-10 directions. Take tau = n*eps.
                [Qi, Ri, ~] = qr(W, 'econ', 'vector');  % pivoted
                tau_b = n * eps;
                r_keep = size(Ri,2);
                for rr = 0:size(Ri,2)-1
                    if norm(Ri(rr+1:end, rr+1:end), 'fro') <= tau_b * normM
                        r_keep = rr; break;
                    end
                end
                if r_keep == 0, break; end
                Qi = Qi(:,1:r_keep);

            case 'S10'
                % Isolates PIVOTING. Same global-scale trailing-block test as S7/S8, but
                % on an UNPIVOTED QR. If this matches S8, the C++ needs no pivoting at all
                % and the fix is ~10 lines on a diagonal BK already has.
                tau_b = n * eps;
                r_keep = size(Ri,2);
                for rr = 0:size(Ri,2)-1
                    if norm(Ri(rr+1:end, rr+1:end), 'fro') <= tau_b * normM
                        r_keep = rr; break;
                    end
                end
                if r_keep < size(Qi,2)
                    repl_idx = (r_keep+1):size(Qi,2);
                    for j = repl_idx
                        v = randn(size(M,1),1);
                        v = v - Q*(Q'*v);
                        if j > 1, v = v - Qi(:,1:j-1)*(Qi(:,1:j-1)'*v); end
                        v = v - Q*(Q'*v);
                        nv = norm(v);
                        if nv < 1e-300, v = randn(size(M,1),1); v = v - Q*(Q'*v); nv = norm(v); end
                        Qi(:,j) = v/nv;
                    end
                end

            case 'S9'
                % CQRRPT's criterion, transplanted: rl_cqrrpt.hh:315-327. NO PIVOTING.
                % The running max/min makes it order-independent by construction -- the
                % comment at rl_cqrrpt.hh:313 says exactly that ("the diagonal of R_sp may
                % not be sorted"). If this matches S8, pivoting is unnecessary and the fix
                % is ~10 lines on a diagonal BK already has, in both QR paths.
                % cond_threshold = sqrt(eps_tol/u): the accepted orthogonality loss, since
                % loss ~ u*cond^2. eps_tol = 1e-10 -> threshold ~ 2.1e3.
                cond_thr = sqrt(1e-10 / eps);
                rmax = d(1); rmin = d(1); r_keep = numel(d);
                for i2 = 1:numel(d)
                    rmax = max(rmax, d(i2)); rmin = min(rmin, d(i2));
                    if (rmin * cond_thr < rmax) && i2 > 2
                        r_keep = i2 - 1; break;
                    end
                end
                if r_keep < size(Qi,2)
                    repl_idx = (r_keep+1):size(Qi,2);
                    for j = repl_idx
                        v = randn(size(M,1),1);
                        v = v - Q*(Q'*v);
                        if j > 1, v = v - Qi(:,1:j-1)*(Qi(:,1:j-1)'*v); end
                        v = v - Q*(Q'*v);
                        nv = norm(v);
                        if nv < 1e-300, v = randn(size(M,1),1); v = v - Q*(Q'*v); nv = norm(v); end
                        Qi(:,j) = v/nv;
                    end
                end

            case 'S8'
                % SYNTHESIS. S7 and S6 fix disjoint halves of the problem:
                %   S7 (Balabanov's criterion) fixes the FALSE alarms. It solves T6
                %      outright and lifts T5 from 44 to 99, where replacement gets 0/5.
                %   S6 (replace + probe) fixes GENUINE exhaustion. It solves T1, where a
                %      better criterion cannot help: the identity needs new directions,
                %      not a better reading of the old ones.
                % So: use Balabanov's pivoted relative test to decide how many columns of
                % this block are real, and use replacement only for the slots it rejects,
                % with the operator probe to decide whether to carry on at all.
                [Qi, Ri, ~] = qr(W, 'econ', 'vector');
                tau_b = n * eps;
                r_keep = size(Ri,2);
                for rr = 0:size(Ri,2)-1
                    if norm(Ri(rr+1:end, rr+1:end), 'fro') <= tau_b * normM
                        r_keep = rr; break;
                    end
                end
                if r_keep < size(Qi,2)
                    repl_idx = (r_keep+1):size(Qi,2);
                    for j = repl_idx
                        v = randn(size(M,1),1);
                        v = v - Q*(Q'*v);
                        if j > 1, v = v - Qi(:,1:j-1)*(Qi(:,1:j-1)'*v); end
                        v = v - Q*(Q'*v);
                        nv = norm(v);
                        if nv < 1e-300, v = randn(size(M,1),1); v = v - Q*(Q'*v); nv = norm(v); end
                        Qi(:,j) = v/nv;
                    end
                end
        end

        % M'*Qi is needed to form the next block regardless, so S6's probe is free.
        Z = M'*Qi; ops = ops + size(Qi,2);

        if any(strcmp(strat,{'S6','S8','S9','S10'})) && ~isempty(repl_idx)
            % Does the operator do anything with the replacement directions? Judge each one
            % SEPARATELY. An earlier version tested all(...) and committed the whole block
            % unless every replacement was annihilated, which silently readmitted the very
            % defect S0p has: a partially useful block commits its dead columns too. The
            % six test matrices happen to be all-or-nothing, so that bug never fired here.
            img  = sqrt(sum(Z(:,repl_idx).^2, 1));
            dead = repl_idx(img < tol * normM);
            keepc = setdiff(1:size(Qi,2), dead);        % never commit an annihilated column
            if numel(dead) == numel(repl_idx)           % nothing replaceable is productive
                if ~isempty(keepc), Q = [Q Qi(:,keepc)]; end %#ok<AGROW>
                break;
            end
            Qi = Qi(:,keepc); Z = Z(:,keepc);
        end
        repl_idx = [];

        Q = [Q Qi]; %#ok<AGROW>
        W = M*Z; ops = ops + size(Qi,2);
    end

    % extraction, as ABRIK does: SVD of the projection, map back
    if isempty(Q)
        out = struct('claim',0,'bogus',0,'resid',NaN,'orth',NaN,'noise',0,'ops',ops); return;
    end
    B = Q'*M; [Uh,Sh,Vh] = svd(B,'econ');
    claim = size(Uh,2);                 % what ABRIK reports: singular_triplets_found
    Ua = Q*Uh; Va = Vh; sa = diag(Sh);

    % per-triplet residual, eq. (2.4), for EVERY claimed triplet
    r = zeros(claim,1);
    for i = 1:claim
        r(i) = hypot(norm(M*Va(:,i) - sa(i)*Ua(:,i)), ...
                     norm(M'*Ua(:,i) - sa(i)*Va(:,i))) / max(sa(i), realmin);
    end
    res   = max(r(1:min(10, claim)));   % accuracy of the ten leading triplets
    bogus = sum(r > 1e-8);              % claimed triplets that are not triplets
    % noise: claimed triplets beyond the true rank carrying a non-negligible sigma
    cutoff = max(T.strue(1)*1e-12, realmin);
    noise  = sum(sa > cutoff & (1:claim).' > T.avail);

    out = struct('claim', claim, 'bogus', bogus, 'resid', res, ...
                 'orth', norm(Q'*Q - eye(size(Q,2)), 'fro'), 'noise', noise, 'ops', ops);
end
