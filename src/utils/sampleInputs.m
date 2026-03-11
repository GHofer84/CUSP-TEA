%======================================================================
% sampleInputs.m
% 
% Author: Gerhard Hofer
% Affiliation: Arizona State University
% Date: November 2025
%
% Purpose:
%   Generate sampled input values for techno-economic assessment (TEA)
%   simulations using Latin Hypercube Sampling (LHS).
%   Supports fixed values, discrete picks, and continuous distributions
%   (uniform, skewed, triangular).
%
% Syntax:
%   inputs = sampleInputs(paramDefs, N)
%
% Inputs:
%   paramDefs : cell array of parameter definitions
%               Each entry is a cell {name, value(s)} or {name, min, max, type}
%               - Fixed value: {name, scalar}
%               - Discrete picks: {name, [vector of values]}
%               - Distribution: {name, minVal, maxVal, uType}
%                   uType = 'u' (uniform), 's' (skewed), or numeric mode (triangular)
%
%   N         : number of samples to generate
%
% Outputs:
%   inputs    : struct containing sampled values for each parameter
%               Each field corresponds to a parameter name, with N rows.
%
% Method:
%   - Identify which parameters require sampling
%   - Generate Latin Hypercube samples in [0,1]
%   - Map uniform samples to appropriate distributions
%   - Return structured array of sampled inputs
%
% Notes:
%   - Ensures probabilistic coverage of parameter ranges
%   - Used in Monte Carlo TEA framework to propagate input uncertainty
%   - Companion function: sampleDistribution.m
%======================================================================


function inputs = sampleInputs(paramDefs, N)

% Identify sampled parameters (i.e., which parameters need sampling)
% Triangular or uniform/skewed distributions (length == 4)
% Discrete picks (length == 2 and second element is a vector)

sampledFlags = cellfun(@(d) (length(d) == 4) || (length(d) == 2 && isvector(d{2})), paramDefs);
U = lhsdesign(N, sum(sampledFlags));

inputs = struct();
sampleIndex = 1;

for k = 1:length(paramDefs)
    def = paramDefs{k};
    name = def{1};

    if length(def) == 2 && isnumeric(def{2}) && isscalar(def{2})
        % Fixed value
        inputs.(name) = repmat(def{2}, N, 1);

    elseif length(def) == 2 && isvector(def{2})
        % Discrete pick
        values = def{2};
        inputs.(name) = values(ceil(length(values) * U(:,sampleIndex)));
        sampleIndex = sampleIndex + 1;

    elseif length(def) == 4
        % Sampled distribution
        minVal = def{2};
        maxVal = def{3};
        uType  = def{4};
        inputs.(name) = sampleDistribution(U(:,sampleIndex), minVal, maxVal, uType);
        sampleIndex = sampleIndex + 1;

    else
        error(['Invalid parameter definition for: ', name]);
    end
end
end