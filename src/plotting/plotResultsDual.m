%--------------------------------------------------------------------------
% plotResultsDual.m
%
% Author: Gerhard Hofer
% Affiliation: Arizona State University
% Date: January 2026
%
% Purpose:
%   Generate visualizations comparing Monte Carlo results with and without
%   45Q credit. Includes optional PSC reference line for DAC scenarios.
%
% Notes:
%   - PSC reference line appears ONLY for DAC scenarios.
%   - Default PSC line uses nocred to match LCOE summary plot.
%--------------------------------------------------------------------------

function plotResultsDual(results)

% --- User toggles ---
showPSCmaxLine      = true;    % draw PSC max line on DAC charts
useCreditForPSCline = false;   % default: nocred (consistent with Lazard)

% Get scenario styles
style = getScenarioStyle(results.scenario);

% Determine if this is a DAC scenario
isDAC = contains(results.scenario, 'DAC');

%% --- LCOE Histogram ---
fig = newFigure(3.25, 3.25);
hold on;

histogram(results.LCOE_nocred, 50, ...
    'FaceColor', style.color, ...
    'FaceAlpha', style.alpha_noCred);

histogram(results.LCOE_cred, 50, ...
    'FaceColor', style.color, ...
    'FaceAlpha', style.alpha_withCred);

xlabel('LCOE ($/MWh)');
ylabel('Frequency');
legend('No Credit', 'With 45Q Credit', 'Location', 'NorthWest');
grid on;
xlim(dynamicLimit([results.LCOE_nocred; results.LCOE_cred]));

% --- Add PSC max line (DAC scenarios only) ---
if isDAC && showPSCmaxLine
    maxPSC = getPSCmax(results, useCreditForPSCline);
    if ~isnan(maxPSC)
        xline(maxPSC, 'k--', 'LineWidth', 2, ...
            'Label', 'PSC max', ...
            'LabelVerticalAlignment', 'bottom', ...
            'HandleVisibility', 'off');
    end
end

saveFigure(fig, ['LCOE_' results.scenario]);


%% --- LCOC Histogram ---
fig = newFigure(3.25, 3.25);
hold on;

histogram(results.LCOC_nocred, 50, ...
    'FaceColor', style.color, ...
    'FaceAlpha', style.alpha_noCred);

histogram(results.LCOC_cred, 50, ...
    'FaceColor', style.color, ...
    'FaceAlpha', style.alpha_withCred);

xlabel('LCOC ($/t_{CO2})');
ylabel('Frequency');
legend('No Credit', 'With 45Q Credit', 'Location', 'NorthWest');
grid on;
xlim(dynamicLimit([results.LCOC_nocred; results.LCOC_cred]));

saveFigure(fig, ['LCOC_' results.scenario]);


%% --- LCOS Histogram ---
fig = newFigure(3.25, 3.25);
hold on;

histogram(results.LCOS_nocred, 50, ...
    'FaceColor', style.color, ...
    'FaceAlpha', style.alpha_noCred);

histogram(results.LCOS_cred, 50, ...
    'FaceColor', style.color, ...
    'FaceAlpha', style.alpha_withCred);

xlabel('LCOS ($/t_{CO2})');
ylabel('Frequency');
legend('No Credit', 'With 45Q Credit', 'Location', 'NorthWest');
grid on;
xlim(dynamicLimit([results.LCOS_nocred; results.LCOS_cred]));

saveFigure(fig, ['LCOS_' results.scenario]);


%% --- Breakeven Credit Histogram ---
fig = newFigure(3.25, 3.25);
hold on;

histogram(results.breakeven_credit_cred, 50, ...
    'FaceColor', style.color, ...
    'FaceAlpha', style.alpha_withCred);

xlabel('Breakeven Credit ($/t_{CO2})');
ylabel('Frequency');
grid on;
xlim(dynamicLimit(results.breakeven_credit_cred));

saveFigure(fig, ['Breakeven_' results.scenario]);


%% --- Tornado Charts (LCOE, LCOC, LCOS) ---
isPSC = contains(results.scenario, 'PSC');
isDAC = contains(results.scenario, 'DAC');
dacService = isDAC && all(results.inputs.capture_tech == 1 & results.inputs.service_mode == 1);

% Build input matrix and one-line labels
if isPSC
    X_raw = [results.fuel_cost_cred, ...
             results.inputs.capacity_factor, ...
             results.power_plant_capex_cred + results.power_plant_decom_cost_cred, ...
             results.inputs.power_plant_opex, ...
             results.ccs_plant_capex_cred .* results.CO2_captured_cred + ...
                 results.ccs_plant_decom_cost_cred .* results.CO2_captured_cred, ...
             results.inputs.ccs_plant_opex .* results.CO2_captured_cred];

    labels = {'Fuel Cost', ...
              'Capacity Factor', ...
              'Power Plant CAPEX', ...
              'Power Plant OPEX', ...
              'PSC CAPEX', ...
              'PSC OPEX'};

elseif isDAC && ~dacService
    X_raw = [results.fuel_cost_cred, ...
             results.inputs.capacity_factor, ...
             results.power_plant_capex_cred + results.power_plant_decom_cost_cred, ...
             results.inputs.power_plant_opex, ...
             results.ccs_plant_capex_cred .* results.CO2_captured_cred + ...
                 results.ccs_plant_decom_cost_cred .* results.CO2_captured_cred, ...
             results.inputs.ccs_plant_opex .* results.CO2_captured_cred];

    labels = {'Fuel Cost', ...
              'Capacity Factor', ...
              'Power Plant CAPEX', ...
              'Power Plant OPEX', ...
              'DAC CAPEX', ...
              'DAC OPEX'};

elseif isDAC && dacService
    X_raw = [results.fuel_cost_cred, ...
             results.inputs.capacity_factor, ...
             results.power_plant_capex_cred + results.power_plant_decom_cost_cred, ...
             results.inputs.power_plant_opex, ...
             results.inputs.ccs_plant_cost .* results.CO2_captured_cred];

    labels = {'Fuel Cost', ...
              'Capacity Factor', ...
              'Power Plant CAPEX', ...
              'Power Plant OPEX', ...
              'DAC Service Cost'};

else
    warning('Unknown scenario type. Tornado chart skipped.');
    return;
end

% Filter out constant/NaN columns
stds = std(X_raw);
valid_cols = stds > 0 & all(~isnan(X_raw));
X_raw = X_raw(:, valid_cols);
labels = labels(valid_cols);

% Normalize inputs (z-score style)
X = (X_raw - median(X_raw,1)) ./ std(X_raw,0,1);

negPlot = true;

% Tornado: LCOE
fig = plotTornado(results.LCOE_cred, X, labels, 'LCOE', results.scenario, negPlot, style.color);
saveFigure(fig, ['Tornado_LCOE_' results.scenario]);

% Tornado: LCOC
fig = plotTornado(results.LCOC_cred, X, labels, 'LCOC', results.scenario, negPlot, style.color);
saveFigure(fig, ['Tornado_LCOC_' results.scenario]);

% Tornado: LCOS
fig = plotTornado(results.LCOS_cred, X, labels, 'LCOS', results.scenario, negPlot, style.color);
saveFigure(fig, ['Tornado_LCOS_' results.scenario]);

end


%% ------------------------------------------------------------------------
% Helper: Get PSC max LCOE (cred or nocred)
% -------------------------------------------------------------------------
function maxPSC = getPSCmax(results, useCredit)

    % Determine PSC scenario name
    if contains(results.scenario, 'NGCC')
        pscField = 'NGCC_PSC';
    elseif contains(results.scenario, 'NG')
        pscField = 'NG_PSC';
    elseif contains(results.scenario, 'Coal')
        pscField = 'Coal_PSC';
    else
        maxPSC = NaN;
        return;
    end

    % Access base workspace results struct
    base = evalin('base', 'results');

    % Select LCOE field
    if useCredit
        vec = base.(pscField).LCOE_cred;
    else
        vec = base.(pscField).LCOE_nocred;
    end

    maxPSC = max(vec(:));
end


%% ------------------------------------------------------------------------
% Helper: dynamic axis limits
% -------------------------------------------------------------------------
function lim = dynamicLimit(data, padFactor)
    if nargin < 2, padFactor = 1.1; end
    data = data(~isnan(data));
    if isempty(data)
        lim = [0, 1];
        return;
    end
    minVal = min(data(:));
    maxVal = max(data(:));
    if minVal == maxVal
        lim = [minVal - 0.5, maxVal + 0.5];
    elseif minVal >= 0
        lim = [0, maxVal * padFactor];
    else
        range = maxVal - minVal;
        lim = [minVal - 0.05 * range, maxVal + 0.05 * range];
    end
end


%--------------------------------------------------------------------------
% Helper function for tornado charts with watchdog
%--------------------------------------------------------------------------
function fig = plotTornado(y_all, X, labels, metricName, scenario, allowNegative, barColor)

    % Apply mask for this metric (remove NaNs in y)
    valid = ~isnan(y_all);
    y = y_all(valid);
    X = X(valid,:);

    if isempty(X) || isempty(y)
        disp(['No valid data for ',metricName,' tornado chart.']);
        fig = [];
        return;
    end

    % Regression with rank guard
    rankX = rank(X);
    if rankX == 0
        disp(['Regression skipped for ',metricName,': input matrix is rank deficient.']);
        fig = [];
        return;
    end

    % Linear regression: y = b0 + X*b
    b = regress(y, [ones(size(X,1),1), X]);
    coeffs = b(2:end);  % drop intercept

    % Watchdog: expected positive signs (can be refined per input later)
    expectedSigns = +ones(size(coeffs));

    for k = 1:numel(coeffs)
        if ~allowNegative && sign(coeffs(k)) ~= expectedSigns(k)
            fprintf('Watchdog: "%s" inverted (%.3f). Set to 0.\n', labels{k}, coeffs(k));
            coeffs(k) = 0;
        end
    end

    % Sort by absolute impact (largest first)
    [~, idx] = sort(abs(coeffs),'descend');
    coeffs_sorted = coeffs(idx);
    labels_sorted = labels(idx);

    % Toggle: true = relative impact (0–1)
    useRelative = true;

    % Create figure and return handle
    fig = newFigure(3.25, 3.25);

    if useRelative
        coeffs_sorted = coeffs_sorted ./ max(abs(coeffs_sorted));
    end

    % Plot horizontal bars
    barh(coeffs_sorted, 'FaceColor', barColor);

    % Configure y-axis ticks and labels
    ax = gca;
    n = numel(labels_sorted);
    set(ax, 'YTick', 1:n);
    set(ax, 'YTickLabel', labels_sorted);  % one-line labels
    set(ax, 'YDir', 'reverse');            % largest at top

    % Axis label and grid
    if useRelative
        xlabel(['Relative Impact on ',metricName]);
        xlim([-1 1]);
    else
        xlabel(['Change in ',metricName,' per 1σ Input Increase']);
    end

    grid on;
end