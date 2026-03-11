%--------------------------------------------------------------------------
% extractLCOEvalidate.m
%
% Author: Gerhard Hofer
% Affiliation: Arizona State University
% Date: January 2026
%
% Purpose:
%   Extract summary statistics (median, p5, p95, min, max) for LCOE_nocred
%   from validation-mode simulation results.
%
% Inputs:
%   results   - struct containing validation scenario outputs
%               (Coal_Validation, NG_Validation, NGCC_Validation)
%
% Outputs:
%   LCOEvalidate - struct with summary statistics and raw data for each
%                  validation scenario
%
%--------------------------------------------------------------------------

function LCOEvalidate = extractLCOEvalidate(results)

    scenarioTags = {'Coal_Validation','NG_Validation','NGCC_Validation'};
    LCOEvalidate = struct();

    for s = 1:length(scenarioTags)
        tag = scenarioTags{s};

        if isfield(results, tag)
            res = results.(tag);

            if ~isfield(res, 'LCOE_nocred')
                continue
            end

            data = res.LCOE_nocred;
            data = data(~isnan(data));

            if ~isempty(data)
                LCOEvalidate.(tag).median = median(data);
                LCOEvalidate.(tag).p5     = prctile(data, 5);
                LCOEvalidate.(tag).p95    = prctile(data, 95);
                LCOEvalidate.(tag).min    = min(data);
                LCOEvalidate.(tag).max    = max(data);
                LCOEvalidate.(tag).raw    = data;
            end
        end
    end
end