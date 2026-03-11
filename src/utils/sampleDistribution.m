%======================================================================
% sampleDistribution.m
% 
% Author: Gerhard Hofer
% Affiliation: Arizona State University
% Date: November 2025
%
% Purpose:
%   Transform uniform random samples in [0,1] into values drawn from
%   specified probability distributions for TEA simulations.
%   Supports uniform, skewed (bias toward lower values), and triangular
%   distributions.
%
% Syntax:
%   X = sampleDistribution(U, minVal, maxVal, uType)
%
% Inputs:
%   U      : vector of uniform samples in [0,1]
%   minVal : minimum value of distribution
%   maxVal : maximum value of distribution
%   uType  : distribution type
%            - 'u' : uniform distribution
%            - 's' : skewed distribution (sqrt transform, bias toward lower values)
%            - numeric : mode value for triangular distribution
%
% Outputs:
%   X      : vector of sampled values, same size as U
%
% Method:
%   - For uniform: linear scaling between minVal and maxVal
%   - For skewed: square-root transform to bias toward lower values
%   - For triangular: piecewise calculation using mode as breakpoint
%
% Notes:
%   - Companion function to sampleInputs.m
%   - Ensures probabilistic coverage of parameter ranges in Monte Carlo TEA
%   - Errors are raised if mode is outside [minVal, maxVal] or if uType is invalid
%======================================================================


function X = sampleDistribution(U, minVal, maxVal, uType)

X = zeros(size(U));

if ischar(uType)
    switch lower(uType)
        case 'u' % Uniform
            X = minVal + (maxVal - minVal) * U;
        case 's' % Skewed toward lower values
            X = minVal + (maxVal - minVal) * sqrt(U);
        otherwise
            error('Unknown string type for uType. Use ''u'' or ''s''.');
    end
elseif isnumeric(uType)
    % Triangular distribution with mode = numerical uType value
    modeVal = uType;
    if modeVal < minVal || modeVal > maxVal
        error('Mode must be between min and max.');
    end
    Bp = (modeVal - minVal) / (maxVal - minVal); % breakpoint
    for i = 1:length(U)
        if U(i) < Bp
            X(i) = minVal + sqrt(U(i) * (maxVal - minVal) * (modeVal - minVal));
        else
            X(i) = maxVal - sqrt((1 - U(i)) * (maxVal - minVal) * (maxVal - modeVal));
        end
    end
else
    error('uType must be ''u'', ''s'', or a numeric mode value.');
end
end