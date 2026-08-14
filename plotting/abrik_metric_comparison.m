function abrik_metric_comparison(csv_path, ax, panel_title)
% abrik_metric_comparison - the three residual metrics of C4 on one axes.
%
% Per-triplet medians across runs, semilogy vs triplet index:
%   eq. (2.4)  ours: two-sided, per-triplet normalized      (res_err_abrik)
%   eq. (14)   Hartwig/Tomas: one-sided, normalized          (res_1s_abrik)
%   eq. (6.1)  Rob/Tropp-Webber: two-sided, unstandardized   (res_sw_abrik)
% plus the GESDD eq. (2.4) baseline (should sit at O(eps)).
%
% Purpose (2026-08-03): turn the S2.3 / App A metric contrast into a measured
% figure. Needs the res_sw_*/res_1s_* columns added to ABRIK_accuracy_analysis
% on 2026-08-03; errors loudly on CSVs that predate them.
    fid = fopen(csv_path, 'r'); n_skip = 0; l = fgetl(fid);
    while ischar(l) && ~isempty(l) && l(1) == '#', n_skip = n_skip + 1; l = fgetl(fid); end
    fclose(fid);
    opts = detectImportOptions(csv_path, 'NumHeaderLines', n_skip, 'VariableNamingRule', 'preserve', 'Delimiter', ',');
    T = readtable(csv_path, opts);
    T.Properties.VariableNames = strtrim(T.Properties.VariableNames);
    need = {'res_err_abrik','res_1s_abrik','res_sw_abrik','res_err_gesdd'};
    assert(all(ismember(need, T.Properties.VariableNames)), ...
        'abrik_metric_comparison: %s lacks the C4 metric columns (pre-2026-08-03 CSV?)', csv_path);
    G = groupsummary(T, 'i', 'median', need);
    semilogy(ax, G.i, G.median_res_err_abrik, '-',  'LineWidth', 2); hold(ax, 'on');
    semilogy(ax, G.i, G.median_res_1s_abrik,  '--', 'LineWidth', 2);
    semilogy(ax, G.i, G.median_res_sw_abrik,  ':',  'LineWidth', 2);
    semilogy(ax, G.i, G.median_res_err_gesdd, '-',  'LineWidth', 1, 'Color', [0.6 0.6 0.6]);
    grid(ax, 'on'); xlabel(ax, 'triplet index i'); ylabel(ax, 'residual metric (median over runs)');
    legend(ax, {'ours eq.(2.4): 2-sided normalized', ...
                'Hartwig/Tomas eq.(14): 1-sided normalized', ...
                'Rob/Tropp-Webber eq.(6.1): 2-sided unstandardized', ...
                'GESDD baseline, eq.(2.4)'}, 'Location', 'best');
    title(ax, panel_title);
end
