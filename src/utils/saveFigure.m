%--------------------------------------------------------------------------
% saveFigure.m
%
% Author: Gerhard Hofer
% Affiliation: Arizona State University
% Date: February 2026
%
% Purpose:
%   Save a figure as an SVG into the project-level "figures" directory,
%   independent of the current working directory or script location.
%
% Inputs:
%   fig   - figure handle
%   name  - filename without extension (string)
%
% Outputs:
%   Saves an SVG file in /CUSP-TEA/figures
%
%--------------------------------------------------------------------------

function saveFigure(fig, name)

    % Determine project root (two levels above this file)
    thisFile    = mfilename('fullpath');   % .../src/plotting/saveFigure.m
    plottingDir = fileparts(thisFile);     % .../src/plotting
    srcDir      = fileparts(plottingDir);  % .../src
    projectRoot = fileparts(srcDir);       % .../CUSP-TEA

    % Ensure figures directory exists
    figDir = fullfile(projectRoot, 'figures');
    if ~exist(figDir, 'dir')
        mkdir(figDir);
    end

    % Get figure size (set by newFigure)
    pos = get(fig, 'Position');
    width  = pos(3);
    height = pos(4);

    % Match export size to figure size
    set(fig, 'PaperUnits', 'inches');
    set(fig, 'PaperPosition', [0 0 width height]);
    set(fig, 'PaperSize', [width height]);

    % Enforce Times New Roman
    ax = findall(fig, '-property', 'FontName');
    set(ax, 'FontName', 'Times New Roman');

    % Construct full output path
    outFile = fullfile(figDir, [name '.svg']);

    % Export as SVG
    print(fig, outFile, '-dsvg');

    fprintf('\nSaved figure to: %s\n', outFile);
end