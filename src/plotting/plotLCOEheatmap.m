%--------------------------------------------------------------------------
% plotLCOEheatmap.m
%
% Author: Gerhard Hofer
% Affiliation: Arizona State University
% Date: March 2026
%
% Purpose:
%   Generate a publication‑ready three‑panel heatmap summarizing TEA median
%   levelized cost of energy (LCOE) outcomes. Panel (a) reports absolute
%   medians; panel (b) shows absolute changes relative to the corresponding
%   no‑CCS validation baselines; and panel (c) shows percentage changes
%   relative to the same baselines.
%
% Notes:
%   - Panel labels (a)–(c) are embedded directly in the heatmap titles.
%   - X‑axis labels are suppressed for visual compactness.
%   - Uses a unified custom colormap for all three panels.
%   - Export handled by saveFigure().
%--------------------------------------------------------------------------

function plotLCOEheatmap(LCOEsummary, ValidationLCOE)

%% --- Scenario ordering ---
tags = {'Coal_PSC','Coal_DAC','NG_PSC','NG_DAC','NGCC_PSC','NGCC_DAC'};
labels = {'Coal + PSC','Coal + DAC','NG + PSC','NG + DAC','NGCC + PSC','NGCC + DAC'};
n = numel(tags);

%% --- Map CCS → no‑CCS baseline ---
baselineMap = containers.Map( ...
    {'Coal_PSC','Coal_DAC','NG_PSC','NG_DAC','NGCC_PSC','NGCC_DAC'}, ...
    {'Coal_Validation','Coal_Validation','NG_Validation','NG_Validation','NGCC_Validation','NGCC_Validation'} ...
);

%% --- Extract absolute medians ---
Abs = arrayfun(@(i) LCOEsummary.(tags{i}).median, 1:n)';

%% --- Compute absolute deltas ---
DeltaAbs = arrayfun(@(i) ...
    LCOEsummary.(tags{i}).median - ValidationLCOE.(baselineMap(tags{i})).median, ...
    1:n)';

%% --- Compute percentage deltas ---
baselineVals = arrayfun(@(i) ValidationLCOE.(baselineMap(tags{i})).median, 1:n)';
DeltaPct = 100 * DeltaAbs ./ baselineVals;

%% --- Unified color limits for ALL panels ---
CLim = [0 650];

%% --- Choose ONE colormap for all panels ---
% --- Custom colormap: brighter deep green → blue → warm yellow → brighter deep red → black
baseColors = [
    0.20 0.70 0.20   % brighter NGCC green (was 0.20 0.60 0.20)
    % 0.00 0.45 0.70   % NG blue (unchanged)
    0.98 0.98 0.30   % slightly brighter warm yellow (was 0.95 0.85 0.20)
    0.80 0.10 0.10   % brighter deep red (was 0.55 0.00 0.00)
    0.00 0.00 0.00   % black
];

% Interpolate to 256 colors
x  = linspace(0, 1, size(baseColors,1));
xi = linspace(0, 1, 256);
cust_cmap = interp1(x, baseColors, xi);

cmap = cust_cmap;   % or: hot, parula, turbo, etc.

%% --- Figure layout ---
fig = newFigure(3.75, 3.75);
tiledlayout(1,3,'Padding','compact','TileSpacing','compact');

set(groot,'defaultAxesFontName','Times New Roman');
set(groot,'defaultTextFontName','Times New Roman');
fs = 22;

%% ============================================================
%  PANEL 1 — Absolute medians ($/MWh)
% ============================================================
nexttile;
h1 = heatmap({'($/MWh)'}, labels, Abs, ...
    'Colormap', cmap, ...
    'ColorLimits', CLim, ...
    'ColorbarVisible','off');
h1.XLabel = '';
h1.Title = {'(a)'};
% h1.XDisplayLabels = repmat({'($/MWh)'}, 1, size(Abs,2));
h1.CellLabelFormat = '%.0f';
h1.FontSize = fs;

%% ============================================================
%  PANEL 2 — Absolute Δ vs baseline ($/MWh)
% ============================================================
nexttile;
h2 = heatmap({'($/MWh)'}, labels, DeltaAbs, ...
    'Colormap', cmap, ...
    'ColorLimits', CLim, ...
    'ColorbarVisible','off');
h2.XLabel = '';
h2.Title = {'(b)'};
% h2.XDisplayLabels = repmat({'($/MWh)'}, 1, size(Abs,2));
h2.CellLabelFormat = '%.0f';
h2.FontSize = fs;
h2.YDisplayLabels = repmat({''}, n, 1);

%% ============================================================
%  PANEL 3 — Percentage Δ vs baseline (%)
% ============================================================
nexttile;
h3 = heatmap({'LCOE'}, labels, DeltaPct, ...
    'Colormap', cmap, ...
    'ColorLimits', CLim, ...
    'ColorbarVisible','on');
h3.XLabel = '';
h3.Title = {'(c)'};
h3.XDisplayLabels = repmat({''}, 1, size(Abs,2));
h3.CellLabelFormat = '%.0f%%';
h3.FontSize = fs;
h3.YDisplayLabels = repmat({''}, n, 1);   % remove labels

%% --- Export ---
saveFigure(fig, 'LCOEheatmap');

end
