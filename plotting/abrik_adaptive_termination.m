function abrik_adaptive_termination(csv_path, ax, panel_title)
% abrik_adaptive_termination - B2 (Rob red 656): non-adaptive sweep vs the
% adaptive driver on one axes.
%
%   sweep rows    -> median residual vs matvecs across runs (the non-adaptive
%                    config: what a fixed budget buys)
%   adaptive rows -> one marker per run at (matvecs, residual) where the driver
%                    stopped, labeled with its status (converged / max_retries)
%   dashed line   -> the requested tolerance (read from the '# tol:' header)
%
% 2026-08-03; consumes ABRIK_adaptive_hard CSVs (absolute-tol mode, b38ca8e).
    fid = fopen(csv_path, 'r'); n_skip = 0; l = fgetl(fid); tol = NaN;
    while ischar(l) && ~isempty(l) && l(1) == '#'
        t = regexp(l, '^# tol:\s*([0-9.eE+-]+)', 'tokens', 'once');
        if ~isempty(t), tol = str2double(t{1}); end
        n_skip = n_skip + 1; l = fgetl(fid);
    end
    fclose(fid);
    opts = detectImportOptions(csv_path, 'NumHeaderLines', n_skip, ...
        'VariableNamingRule', 'preserve', 'Delimiter', ',');
    T = readtable(csv_path, opts);
    T.Properties.VariableNames = strtrim(T.Properties.VariableNames);
    T.mode = strtrim(string(T.mode)); T.status = strtrim(string(T.status));

    S = T(T.mode == "sweep", :);
    G = groupsummary(S, 'matvecs', 'median', 'residual');
    loglog(ax, G.matvecs, G.median_residual, '-o', 'LineWidth', 2, ...
           'DisplayName', 'non-adaptive sweep (median)'); hold(ax, 'on');

    % Requested tolerance, and where the sweep FIRST meets it: that budget is the
    % ideal stopping point, so the horizontal distance between it and the adaptive
    % marker IS the overshoot. Drawing both on the same curve makes that readable;
    % the earlier version left the marker floating with nothing near it.
    if ~isnan(tol)
        yline(ax, tol, '--', sprintf('requested tol = %.0e', tol), ...
              'HandleVisibility', 'off', 'LabelHorizontalAlignment', 'left');
        hit = find(G.median_residual <= tol, 1);
        if ~isempty(hit)
            xline(ax, G.matvecs(hit), ':', sprintf('ideal stop: %d mv', G.matvecs(hit)), ...
                  'HandleVisibility', 'off', 'LabelVerticalAlignment', 'bottom');
        end
    end

    A = T(T.mode == "adaptive", :);
    ok = A.status == "converged";
    if any(ok)
        loglog(ax, A.matvecs(ok), A.residual(ok), 'p', 'MarkerSize', 16, ...
               'LineWidth', 2, 'DisplayName', 'adaptive stop (certified)');
    end
    if any(~ok)
        loglog(ax, A.matvecs(~ok), A.residual(~ok), 'x', 'MarkerSize', 12, ...
               'LineWidth', 2, 'DisplayName', 'adaptive stop (not certified)');
    end
    % State the overshoot in the panel rather than leaving it to be eyeballed.
    if ~isnan(tol) && any(ok)
        hit = find(G.median_residual <= tol, 1);
        if ~isempty(hit)
            f = median(A.matvecs(ok)) / G.matvecs(hit);
            text(ax, 0.03, 0.06, sprintf('overshoot: %.1f\\times the ideal budget', f), ...
                 'Units', 'normalized', 'FontSize', 11, 'FontWeight', 'bold');
        end
    end

    grid(ax, 'on'); xlabel(ax, 'matvecs'); ylabel(ax, 'residual (eq. 2.4)');
    legend(ax, 'Location', 'southwest'); title(ax, panel_title);
end
