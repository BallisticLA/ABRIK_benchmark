% A small script for saving PDF figures with specified width/height
% properties.
function[] = fig_save(fig, fig_path, width, height)

if isempty(fig.Name)
    fig_basename = 'figure';
else
    % Clean fig.Name in case it has illegal characters for filename
    fig_basename = regexprep(fig.Name, '[\/:*?"<>|]', '_');
end

set(fig, 'Units', 'inches');
fig.Position = [1, 1, width, height]; 
set(fig, 'PaperUnits', 'inches');
set(fig, 'PaperPosition', [0, 0, width, height]);
set(fig, 'PaperSize', [width, height]);

filename = fullfile(fig_path, [fig_basename, '.pdf']);
exportgraphics(fig, filename, 'ContentType','image', 'Resolution',300);
end