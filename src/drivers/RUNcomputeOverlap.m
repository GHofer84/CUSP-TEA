%--------------------------------------------------------------------------
% RUNcomputeOverlap.m
%
% Author: Gerhard Hofer
% Affiliation: Arizona State University
% Date: January 2026
%
% Purpose:
%   Compute distribution-overlap metrics between PSC and DAC cases for NG
%   and NGCC, and print a consolidated summary including:
%       - TEA medians
%       - Validation medians
%       - Lazard baseline ranges
%       - Overlap metrics (Definition A)
%       - Breakeven credit probabilities
%
% Inputs:
%   results        - struct of full scenario results (from RUNcomputeSimulation or snapshot)
%   LCOEsummary    - struct of TEA LCOE medians
%   ValidationLCOE - struct of validation medians
%   LazardLCOE     - struct of Lazard baseline ranges
%
% Notes:
%   - No longer depends on base workspace variables.
%   - Fully compatible with MATLAB Projects and snapshot-based workflows.
%--------------------------------------------------------------------------

function RUNcomputeOverlap(results, LCOEsummary, ValidationLCOE, LazardLCOE)

% Pull required variables from base workspace
results        = evalin('base','results');
LCOEsummary    = evalin('base','LCOEsummary');
ValidationLCOE = evalin('base','ValidationLCOE');
LazardLCOE     = evalin('base','LazardLCOE');

useCredit = false;   % overlap uses nocred (consistent with Lazard)

fprintf('\n===================================================================\n');
fprintf(' LCOE + BREAKEVEN SUMMARY\n');
fprintf('===================================================================\n');

%% ------------------------------------------------------------
% 1. Print ALL medians from LCOEsummary / Validation / Lazard
% -------------------------------------------------------------

fprintf(['\nMEDIANS FOR ALL SCENARIOS\n' ...
    ' (as used in Figure ''Validation of Model LCOE vs Lazard Baseline''):\n']);
fprintf('-------------------------------------------------------------------\n');

% TEA + Validation + Lazard tags
allTags = [fieldnames(LCOEsummary); fieldnames(ValidationLCOE); fieldnames(LazardLCOE)];

for i = 1:numel(allTags)
    tag = allTags{i};

    if isfield(LCOEsummary, tag)
        med = LCOEsummary.(tag).median;
    elseif isfield(ValidationLCOE, tag)
        med = ValidationLCOE.(tag).median;
    else
        med = NaN; % Lazard has no medians
    end

    if isnan(med)
        fprintf('%-30s : (no median)\n', tag);
    else
        fprintf('%-30s : %.1f $/MWh\n', tag, med);
    end
end

%% ------------------------------------------------------------
% 2. Overlap metrics (Definition A)
% -------------------------------------------------------------

stats_NG   = computeOverlapDefA(results,'NG',useCredit);
stats_NGCC = computeOverlapDefA(results,'NGCC',useCredit);

fprintf('\nOVERLAP METRICS (nocred only):\n');
fprintf('-------------------------------------------------------------------\n');
fprintf('NG   – DAC within PSC range      : %.1f %%\n', stats_NG.pctWithinPSC);
fprintf('NG   – DAC below PSC median      : %.1f %%\n', stats_NG.pctBelowPSCmedian);
fprintf('NGCC – DAC within PSC range      : %.1f %%\n', stats_NGCC.pctWithinPSC);
fprintf('NGCC – DAC below PSC median      : %.1f %%\n', stats_NGCC.pctBelowPSCmedian);

%% ------------------------------------------------------------
% 3. Cumulative probability that breakeven credit ≤ scenario's 45Q
% -------------------------------------------------------------

fprintf('\nBREAKEVEN PROBABILITY (breakeven ≤ credit_value):\n');
fprintf('-------------------------------------------------------------------\n');

scenarioList = {'Coal_PSC','Coal_DAC','NG_PSC','NG_DAC','NGCC_PSC','NGCC_DAC'};

for i = 1:numel(scenarioList)
    tag = scenarioList{i};

    if isfield(results, tag) && isfield(results.(tag), 'breakeven_credit_cred')

        % Extract breakeven credit samples
        vec = results.(tag).breakeven_credit_cred(:);
        vec = vec(~isnan(vec));

        % Extract scalar credit_value (avoid vector!)
        if isfield(results.(tag), 'inputs') && isfield(results.(tag).inputs, 'credit_value')
            credit_vec = results.(tag).inputs.credit_value;
            credit_value = credit_vec(1);   % <-- FIX
        else
            fprintf('%-30s : (credit_value missing)\n', tag);
            continue;
        end

        % Compute cumulative probability
        p = mean(vec <= credit_value) * 100;

        fprintf('%-30s : %.1f %%  (credit = %.1f $/tCO2)\n', ...
                tag, p, credit_value);

    else
        fprintf('%-30s : (no breakeven data)\n', tag);
    end
end

fprintf('\n===================================================================\n');
fprintf(' End of summary\n');
fprintf('===================================================================\n\n');

end


%% ------------------------------------------------------------------------
% Helper: Overlap calculation (unchanged)
% ------------------------------------------------------------------------
function stats = computeOverlapDefA(results, tech, useCredit)

    fieldPSC = matlab.lang.makeValidName([tech ' + PSC']);
    fieldDAC = matlab.lang.makeValidName([tech ' + DAC']);

    if useCredit
        LCOE_PSC = results.(fieldPSC).LCOE_cred(:);
        LCOE_DAC = results.(fieldDAC).LCOE_cred(:);
    else
        LCOE_PSC = results.(fieldPSC).LCOE_nocred(:);
        LCOE_DAC = results.(fieldDAC).LCOE_nocred(:);
    end

    minPSC = min(LCOE_PSC);
    maxPSC = max(LCOE_PSC);

    idx_inRange = (LCOE_DAC >= minPSC) & (LCOE_DAC <= maxPSC);
    stats.pctWithinPSC = 100 * sum(idx_inRange) / numel(LCOE_DAC);

    medianPSC = median(LCOE_PSC);
    idx_belowMedian = (LCOE_DAC < medianPSC);
    stats.pctBelowPSCmedian = 100 * sum(idx_belowMedian) / numel(LCOE_DAC);
end