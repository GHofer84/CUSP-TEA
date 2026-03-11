function plotLCOEsummary(LCOEsummary, LazardLCOE, ValidationLCOE)
%--------------------------------------------------------------------------
% plotLCOEsummary.m
%
% Author: Gerhard Hofer
% Affiliation: Arizona State University
% Date: January 2026
%
% Purpose:
%   Plot min–max ranges and medians for TEA scenarios, validation baselines,
%   and Lazard technologies in a unified horizontal range chart.
%
% Notes:
%   - No title (Stephanie trims titles in the report).
%   - Export handled by saveFigure().
%   - Uses getScenarioStyle() for TEA scenario colors.
%--------------------------------------------------------------------------

%% --- Define TEA scenarios ---
teaTags   = {'Coal_PSC','Coal_DAC','NG_PSC','NG_DAC','NGCC_PSC','NGCC_DAC'};
teaLabels = {'Coal + PSC','Coal + DAC','NG + PSC','NG + DAC','NGCC + PSC','NGCC + DAC'};

%% --- Validation scenarios ---
valTags   = {'Coal_Validation','NG_Validation','NGCC_Validation'};
valLabels = {'Coal','NG','NGCC'};

%% --- Lazard technologies ---
lazardTags   = {'Coal','NGCC','NGP','USN','SPVU','SPVSU','WO','WSO'};
lazardLabels = {'Coal','NGCC','NG Peaker', ...
                'U.S. Nuclear','Solar PV - Utility', ...
                'Solar PV + Storage - Utility','Wind (Onshore)', ...
                'Wind + Storage (Onshore)'};

%% --- Combine all tags and labels ---
allTags   = [teaTags, valTags, lazardTags];
allLabels = [teaLabels, valLabels, lazardLabels];
n = numel(allTags);

%% --- Collect ranges ---
mins    = NaN(n,1);
maxs    = NaN(n,1);
medians = NaN(n,1);

for i = 1:n
    tag = allTags{i};

    if isfield(LCOEsummary, tag)
        mins(i)    = LCOEsummary.(tag).min;
        maxs(i)    = LCOEsummary.(tag).max;
        medians(i) = LCOEsummary.(tag).median;

    elseif isfield(ValidationLCOE, tag)
        mins(i)    = ValidationLCOE.(tag).min;
        maxs(i)    = ValidationLCOE.(tag).max;
        medians(i) = ValidationLCOE.(tag).median;

    elseif isfield(LazardLCOE, tag)
        mins(i) = LazardLCOE.(tag).min;
        maxs(i) = LazardLCOE.(tag).max;
    end
end

%% --- Plot ---
fig = newFigure(6.25, 5);
hold on;

for i = n:-1:1
    y = n - i + 1;

    if isnan(mins(i))
        continue;
    end

    tag = allTags{i};

    % --- Determine bar color ---
    if isfield(LCOEsummary, tag)
        style     = getScenarioStyle(tag);
        bar_color = style.color;

    elseif isfield(ValidationLCOE, tag)
        bar_color = [0.25 0.25 0.25];   % dark grey

    elseif isfield(LazardLCOE, tag)
        bar_color = [0.6 0.6 0.6];      % light grey

    else
        bar_color = [0.5 0.5 0.5];
    end

    % --- Range bar ---
    plot([mins(i), maxs(i)], [y,y], '-', ...
        'Color', bar_color, 'LineWidth', 6);

    % --- Min/max labels ---
    text(mins(i)-1, y, sprintf('%.0f', mins(i)), ...
        'HorizontalAlignment','right', ...
        'VerticalAlignment','middle', ...
        'FontSize', 12);

    text(maxs(i)+1, y, sprintf('%.0f', maxs(i)), ...
        'HorizontalAlignment','left', ...
        'VerticalAlignment','middle', ...
        'FontSize', 12);

    % --- Median marker (TEA + validation only) ---
    if ~isnan(medians(i))
        plot([medians(i), medians(i)], [y-0.3, y+0.3], '-', ...
             'Color','r','LineWidth',2);
    end
end

set(gca,'YTick',1:n,'YTickLabel',flip(allLabels));
xlabel('LCOE ($/MWh)');
ylabel('Scenario / Technology');
grid on;
xlim([0, max(maxs)*1.1]);

%% --- Legend handles ---
coalStyle = getScenarioStyle('Coal + PSC');
ngStyle   = getScenarioStyle('NG + PSC');
ngccStyle = getScenarioStyle('NGCC + PSC');

hCoal = plot(NaN, NaN, '-', 'Color', coalStyle.color, 'LineWidth', 6);
hNG   = plot(NaN, NaN, '-', 'Color', ngStyle.color,   'LineWidth', 6);
hNGCC = plot(NaN, NaN, '-', 'Color', ngccStyle.color, 'LineWidth', 6);

hVal  = plot(NaN, NaN, '-', 'Color', [0.25 0.25 0.25], 'LineWidth', 6);
hLaz  = plot(NaN, NaN, '-', 'Color', [0.6 0.6 0.6],    'LineWidth', 6);
hMed  = plot(NaN, NaN, '-', 'Color','r','LineWidth',2);

legend([hCoal,hNG,hNGCC,hVal,hLaz,hMed], ...
       {'TEA: Coal','TEA: NG','TEA: NGCC', ...
        'Validation (no CCS)','Lazard ranges','Median'}, ...
       'Location','SouthEast');

%% --- Export (6.5 × 5 inches) ---
saveFigure(fig, 'LCOEsummary');

end