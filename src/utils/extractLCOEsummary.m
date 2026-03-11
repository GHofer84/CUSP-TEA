%--------------------------------------------------------------------------
% extractLCOEsummary.m
%
% Author: Gerhard Hofer
% Affiliation: Arizona State University
% Date: January 2026
%
% Purpose:
%   Extract summary statistics (median, p5, p95, min, max) for LCOE_nocred
%   from full scenario simulation results (PSC and DAC cases).
%
% Inputs:
%   results   - struct containing scenario outputs
%   scenarios - cell array of scenario names (e.g., 'Coal + PSC')
%
% Outputs:
%   LCOEsummary - struct with summary statistics and raw data for each
%                 scenario, using tags like 'Coal_PSC', 'NG_DAC', etc.
%
%--------------------------------------------------------------------------

function LCOEsummary = extractLCOEsummary(results, scenarios)

    LCOEsummary = struct();

    for s = 1:length(scenarios)
        scenario = scenarios{s};
        fieldName = matlab.lang.makeValidName(scenario);

        if isfield(results, fieldName)
            res = results.(fieldName);

            if ~isfield(res, 'LCOE_nocred')
                continue
            end

            data = res.LCOE_nocred;
            data = data(~isnan(data));

            if ~isempty(data)
                tag = strrep(scenario, ' + ', '_');  % e.g. 'Coal + PSC' → 'Coal_PSC'

                LCOEsummary.(tag).min    = min(data);
                LCOEsummary.(tag).max    = max(data);
                LCOEsummary.(tag).median = median(data);
                LCOEsummary.(tag).p5     = prctile(data, 5);
                LCOEsummary.(tag).p95    = prctile(data, 95);
                LCOEsummary.(tag).raw    = data;
            end
        end
    end
end