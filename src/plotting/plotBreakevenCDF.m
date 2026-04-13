%--------------------------------------------------------------------------
% plotBreakevenCDF.m
%
% Author: Gerhard Hofer
% Affiliation: Arizona State University
% Date: January 2026
%
% Purpose:
%   Plot empirical CDFs of breakeven credit for all scenarios on one figure.
%
% Notes:
%   - Uses scenario-specific colors and linestyles via getScenarioStyle().
%   - No title (Stephanie trims titles in the report).
%   - Export handled by saveFigure().
%--------------------------------------------------------------------------

function plotBreakevenCDF(allResults)

fig = newFigure(6.25, 5);
hold on;

for k = 1:length(allResults)
    res = allResults{k};

    % Skip if missing data
    if ~isfield(res, 'breakeven_credit_cred') || isempty(res.breakeven_credit_cred)
        warning('Missing breakeven_credit_cred for scenario: %s', res.scenario);
        continue;
    end

    % Compute empirical CDF
    [f, x] = ecdf(res.breakeven_credit_cred);

    % Unified style
    style = getScenarioStyle(res.scenario);

    % Plot curve
    plot(x, f, ...
        'LineWidth', 2, ...
        'Color', style.color, ...
        'LineStyle', style.linestyle, ...
        'DisplayName', res.scenario);
end

xlabel('Breakeven Credit ($/t_{CO2})');
ylabel('Cumulative Probability');
legend('show', 'Location', 'best');
grid on;

% Export (6.5 × 5 inches)
saveFigure(fig, 'BreakevenCDF_All');

end