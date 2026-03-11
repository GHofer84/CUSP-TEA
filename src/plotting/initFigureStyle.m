%--------------------------------------------------------------------------
% initFigureStyle.m
%
% Author: Gerhard Hofer
% Affiliation: Arizona State University
% Date: February 2026
%
% Purpose:
%   Set global default figure styling for consistent publication-quality
%   plots across the entire CUSP‑TEA codebase. This configures typography,
%   font sizes, line widths, and axis layout behavior using MATLAB's root
%   graphics object (groot).
%
% Notes:
%   - These defaults apply to all subsequently created figures.
%   - Intended to be called once at the beginning of a run.
%--------------------------------------------------------------------------

function initFigureStyle()

    % Font settings
    set(groot, 'DefaultAxesFontName', 'Times New Roman');
    set(groot, 'DefaultTextFontName', 'Times New Roman');
    set(groot, 'DefaultAxesFontSize', 18);
    set(groot, 'DefaultTextFontSize', 18);
    set(groot, 'DefaultLegendFontSize', 14);

    % Line widths
    set(groot, 'DefaultLineLineWidth', 1.2);
    set(groot, 'DefaultAxesLineWidth', 1.0);

    % Tight layout
    set(groot, 'DefaultAxesLooseInset', [0.02 0.02 0.02 0.02]);

end