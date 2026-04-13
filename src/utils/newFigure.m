%======================================================================
% newFigure.m
%
% Author: Gerhard Hofer
% Affiliation: Arizona State University
% Date: February 2026
%
% Purpose:
%   Create a MATLAB figure with a specified physical size (in inches),
%   while correcting the on‑screen display size for HiDPI / Retina
%   environments. Ensures that exported vector graphics (PDF/SVG) have
%   the exact requested dimensions, and that the on‑screen window
%   visually matches the intended size.
%
% Syntax:
%   fig = newFigure(width, height)
%
% Inputs:
%   width   - Figure width in inches
%   height  - Figure height in inches
%
% Outputs:
%   fig     - Handle to the created figure
%
% Notes:
%   - MATLAB assumes 72 DPI for figure units; Retina/HiDPI displays use
%     higher pixel densities. The scaling correction adjusts only the
%     on‑screen window size; exported files remain true to the requested
%     physical dimensions.
%   - Renderer is set to 'painters' for publication‑quality vector output.
%======================================================================

function fig = newFigure(width, height)

    % Create figure at logical size
    fig = figure('Units','inches', ...
                 'Position',[1 1 width height], ...
                 'PaperUnits','inches', ...
                 'Renderer','painters');

    % Retina / HiDPI correction for on-screen display
    dpi = fig.ScreenPixelsPerInch;   % e.g., 110, 120, 144 depending on scaling
    scale = dpi / 72;                % MATLAB assumes 72 DPI
    fig.Position(3:4) = [width height] * scale;

end