%--------------------------------------------------------------------------
% getScenarioStyle.m
%
% Author: Gerhard Hofer
% Affiliation: Arizona State University
% Date: December 2025
%
% Purpose:
%   Provides a unified visual style (color, line style, transparency)
%   for TEA scenarios, validation baselines, and Lazard ranges.
%   Centralizes all plotting style logic to ensure consistent
%   appearance across histograms, CDFs, tornado charts, and summary plots.
%
% Input:
%   scenarioName - string specifying the scenario tag
%                  Examples:
%                     'Coal + PSC'
%                     'NG + DAC'
%                     'NGCC_Validation'
%                     'Coal' (Lazard baseline)
%
% Output:
%   style - struct with fields:
%              .color        RGB triplet for scenario color
%              .linestyle    Line style for PSC/DAC/Validation/Lazard
%              .alpha_noCred Transparency for "no credit" histograms
%              .alpha_withCred Transparency for "with credit" histograms
%
% Notes:
%   - TEA scenarios are colored by technology:
%       Coal = deep red, NG = blue, NGCC = green
%   - Capture technology sets line style:
%       PSC = solid, DAC = dashed
%   - Validation scenarios use tech color + dotted line style
%   - Lazard baselines use tech color + solid line style
%   - Unknown scenarios fall back to grey
%--------------------------------------------------------------------------

function style = getScenarioStyle(scenarioName)

    % --- Define colors by power plant technology ---
    techColors = struct( ...
        'Coal',  [0.55 0.00 0.00], ...   % deep red
        'NG',    [0.00 0.45 0.70], ...   % blue
        'NGCC',  [0.20 0.60 0.20] ...    % green
    );

    % --- Define line styles by capture technology ---
    capStyles = struct( ...
        'PSC', '-', ...
        'DAC', '--', ...
        'Validation', ':', ...
        'Lazard', '-' ...
    );

    % --- Transparency for histograms ---
    style.alpha_noCred   = 0.4;
    style.alpha_withCred = 0.7;

    % --- Normalize scenario name ---
    % Remove extra spaces
    clean = strtrim(scenarioName);

    % Replace " + " with "_" so we can reuse the same logic
    clean = strrep(clean, ' + ', '_');

    % Split into parts
    parts = split(clean, '_');

    % ============================================================
    % CASE 1: TEA scenario → "Tech + Capture" becomes "Tech_Capture"
    % ============================================================
    if numel(parts) == 2
        tech = parts{1};   % Coal, NG, NGCC
        cap  = parts{2};   % PSC or DAC

        style.color     = techColors.(tech);
        style.linestyle = capStyles.(cap);
        return
    end

    % ============================================================
    % CASE 2: Validation scenario → "NG Validation"
    % ============================================================
    if contains(clean, 'Validation')
        tech = parts{1};
        style.color     = techColors.(tech);
        style.linestyle = capStyles.Validation;
        return
    end

    % ============================================================
    % CASE 3: Lazard scenario → "Coal", "NGCC", etc.
    % ============================================================
    if isfield(techColors, clean)
        style.color     = techColors.(clean);
        style.linestyle = capStyles.Lazard;
        return
    end

    % ============================================================
    % CASE 4: Fallback (unknown scenario)
    % ============================================================
    style.color     = [0.5 0.5 0.5];
    style.linestyle = '-';
end