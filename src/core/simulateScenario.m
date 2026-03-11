%--------------------------------------------------------------------------
% simulateScenario.m
%
% Author: Gerhard Hofer
% Affiliation: Arizona State University
% Date: November 2025 (updated March 2026)
%
% Purpose:
%   Monte Carlo simulation for any scenario (Coal/NG/NGCC + PSC/DAC).
%   Uses modular parameter blocks and dual-run architecture to compare
%   outcomes with and without 45Q credit.
%
% Inputs:
%   N               - number of Monte Carlo samples
%   scenarioTag     - string label for scenario (e.g., 'Coal + PSC')
%   decommissioning - boolean flag
%   validate_mode   - boolean flag
%   params (optional) - parameter struct (if omitted, defineParams() is used)
%
% Output:
%   results         - struct containing scenario results
%--------------------------------------------------------------------------

function results = simulateScenario(N, scenarioTag, decommissioning, validate_mode, params)

%--------------------------------------------------------------------------
% Step 0: Parameter handling
%--------------------------------------------------------------------------
if nargin < 5 || isempty(params)
    params = defineParams();
end

paramConst = params.const;

%--------------------------------------------------------------------------
% Step 1: Select parameter blocks based on scenario tag
%--------------------------------------------------------------------------
switch scenarioTag
    case 'Coal + PSC'
        paramDefs = [params.general; params.coal; params.psc];

    case 'Coal + DAC'
        paramDefs = [params.general; params.coal; params.dac];

    case 'NG + PSC'
        paramDefs = [params.general; params.ng; params.psc];

    case 'NG + DAC'
        paramDefs = [params.general; params.ng; params.dac];

    case 'NGCC + PSC'
        paramDefs = [params.general; params.ngcc; params.psc];

    case 'NGCC + DAC'
        paramDefs = [params.general; params.ngcc; params.dac];

    otherwise
        error('Unknown scenario tag: %s', scenarioTag);
end

%--------------------------------------------------------------------------
% Step 2: Sample inputs
%--------------------------------------------------------------------------
inputs = sampleInputs(paramDefs, N);

% Inject validate_mode
if nargin >= 4 && ~isempty(validate_mode)
    inputs.validate_mode = repmat(validate_mode, N, 1);
end

% Inject decommissioning
if nargin >= 3 && ~isempty(decommissioning)
    inputs.decommissioning = repmat(decommissioning, N, 1);
end

%--------------------------------------------------------------------------
% Step 3: Create two input sets (with and without 45Q credit)
%--------------------------------------------------------------------------
inputs_noCredit = inputs;
inputs_noCredit.credit_value = zeros(N,1);

%--------------------------------------------------------------------------
% Step 4: Run both simulations
%--------------------------------------------------------------------------
results_nocred = runSimulation(inputs_noCredit, paramConst, N);
results_cred   = runSimulation(inputs,          paramConst, N);

%--------------------------------------------------------------------------
% Step 5: Package results
%--------------------------------------------------------------------------
results.scenario = scenarioTag;

fields = fieldnames(results_nocred);
for f = 1:length(fields)
    results.([fields{f}, '_nocred']) = results_nocred.(fields{f});
    results.([fields{f}, '_cred'])   = results_cred.(fields{f});
end

results.inputs          = inputs;
results.paramConst      = paramConst;
results.params_used     = params;
results.validate_mode   = validate_mode;
results.decommissioning = decommissioning;

end

%--------------------------------------------------------------------------
% Internal simulation logic
%--------------------------------------------------------------------------

function results = runSimulation(inputs, paramConst, N)

% Preallocate variables
results = struct();
pow_CRF = zeros(N,1);
ccs_CRF = zeros(N,1);
isDACservice = zeros(N,1);
fuel_cost = zeros(N,1);
power_plant_capex = zeros(N,1);
power_plant_decom_cost = zeros(N,1);
ccs_plant_capex = zeros(N,1);
ccs_plant_decom_cost = zeros(N,1);
CO2_captured = zeros(N,1);
CO2_uncaptured = zeros(N,1);
CO2_transport_cost = zeros(N,1);
cost_total = zeros(N,1);
ccs_cost = zeros(N,1);
ccs_driver_cost = zeros(N,1);
credit_effect = zeros(N,1);
LCOE = zeros(N,1);
LCOC = zeros(N,1);
LCOS = zeros(N,1);
breakeven_credit = zeros(N,1);

for i = 1:N
    %% --- General Calc ---
    % Capital Recovery Factors
    r_pow = inputs.discount_rate(i);
    if inputs.power_plant_lifetime(i) == 0
        n_pow = 1;
    else
        n_pow = inputs.power_plant_lifetime(i);
    end
    pow_CRF(i) = (r_pow * (1 + r_pow)^n_pow) / ((1 + r_pow)^n_pow - 1);

    r_ccs = inputs.discount_rate(i);
    if inputs.ccs_plant_lifetime(i) == 0
        n_ccs = 1;
    else
        n_ccs = inputs.ccs_plant_lifetime(i);
    end
    ccs_CRF(i) = (r_ccs * (1 + r_ccs)^n_ccs) / ((1 + r_ccs)^n_ccs - 1);

    % DAC service flag: 1 if capture_tech == 1 (i.e. DAC) and service_mode == 1
    isDAC       = (inputs.capture_tech(i) == 1);
    serviceOn   = (inputs.service_mode(i) == 1);
    dacService  = (isDAC && serviceOn);
    isDACservice(i) = dacService;
    
    % CO2 quantities captured and uncaptured in tCO2/MWhel
    if inputs.validate_mode(i) == false
        CO2_captured(i)   = inputs.carbon_intensity(i) * inputs.capture_rate(i);
        CO2_uncaptured(i) = inputs.carbon_intensity(i) * (1 - inputs.capture_rate(i));
    else
        CO2_captured(i)   = 0;
        CO2_uncaptured(i) = 0;
    end   

    %% --- Power Plant Specific Calc ---
    % Fuel cost in $/MWhel
    if isfield(inputs, 'coal_HHV')
        coal_LHV = inputs.coal_HHV(i) * paramConst.LHV_per_HHV;
        
        coal_per_MWh = paramConst.MJ_per_MWh / ...
                        (coal_LHV * paramConst.kg_per_ton * inputs.power_plant_net_eff(i));
        
        fuel_cost(i) = inputs.fuel_price(i) * coal_per_MWh;
    elseif isfield(inputs, 'NG_LHV')
        fuel_cost(i) = inputs.fuel_price(i) / ...
                        (inputs.NG_LHV(i) * paramConst.MWh_per_MBtu * inputs.power_plant_net_eff(i));
    else
        error('Fuel type not recognized');
    end

    % Power plant CAPEX and decommissioning cost in $/MWhel
    if inputs.power_cost_is_levelized(i)
        power_plant_capex(i) = inputs.power_plant_cost(i); % $/MWhel
    else
        power_plant_capex(i) = inputs.power_plant_cost(i) * pow_CRF(i) / ...
                                (8760 * inputs.capacity_factor(i)); % $/MWhel
    end
    
    % Power plant decommissioning cost in $/MWhel
    if inputs.decommissioning(i) == false
        power_plant_decom_cost(i) = 0;
    else
        if inputs.power_decom_cost_is_levelized(i)
            power_plant_decom_cost(i) = inputs.power_plant_decom_cost(i); % $/MWhel
        else
            power_plant_decom_cost(i) = inputs.power_plant_decom_cost(i) * pow_CRF(i) / ...
                                         (8760 * inputs.capacity_factor(i)); % $/MWhel
        end
    end 
    
    %% --- LCOE - Levelized Cost Of Electricity ---
    if dacService
        % DAC as a service: single contracted price in $/MWhel
        dac_service_cost = inputs.ccs_plant_cost(i) * CO2_captured(i);  
        cost_total(i) = fuel_cost(i) + ...
                        power_plant_capex(i) + ...
                        power_plant_decom_cost(i) + ...
                        inputs.power_plant_opex(i) + ...
                        dac_service_cost + ...
                        inputs.offset_cost(i)   * CO2_uncaptured(i) - ...
                        inputs.credit_value(i)  * CO2_captured(i);
    else
        % Detailed CCS accounting
        % CCS CAPEX in $/MWhel
        if inputs.ccs_cost_is_levelized(i)
            ccs_plant_capex(i) = inputs.ccs_plant_cost(i) * CO2_captured(i);
        else
            % CCS CAPEX = upfront cost in $/MW capacity > annualized and normalized
            ccs_plant_capex(i) = inputs.ccs_plant_cost(i) * ccs_CRF(i) / ...
                                 (8760 * inputs.capacity_factor(i));
        end

        % CCS decommissioning cost in $/MWhel
        if inputs.decommissioning(i) == false
            ccs_plant_decom_cost(i) = 0;
        else
            ccs_plant_decom_cost(i) = inputs.ccs_plant_decom_cost(i) * CO2_captured(i);
        end

        % CO2 transport cost in $/tCO2
        CO2_transport_cost(i) = inputs.transport_cost(i) * inputs.pipeline_length(i);

        % Total cost per MWhel delivered
        cost_total(i) = fuel_cost(i) + ...
                        power_plant_capex(i) + ...
                        power_plant_decom_cost(i) + ...
                        inputs.power_plant_opex(i) + ...
                        ccs_plant_capex(i) + ...
                        ccs_plant_decom_cost(i) + ...
                        inputs.ccs_plant_opex(i) * CO2_captured(i) + ...
                        CO2_transport_cost(i)    * CO2_captured(i) + ...
                        inputs.storage_cost(i)   * CO2_captured(i) + ...
                        inputs.offset_cost(i)    * CO2_uncaptured(i) - ...
                        inputs.credit_value(i)   * CO2_captured(i) * ...
                         paramConst.credit_lifetime / inputs.ccs_plant_lifetime(i);
    end

    % CCS penalty detection
    if inputs.validate_mode(i) == false
        if isfield(inputs, 'psc_penalty')
            ccs_penalty = inputs.psc_penalty(i);
        elseif isfield(inputs, 'dac_penalty')
            ccs_penalty = inputs.dac_penalty(i);
        else
            ccs_penalty = 0;
        end
    else
        ccs_penalty = 0;
    end

    % Net electricity cost per MWel delivered ($/MWhel)
    LCOE(i) = cost_total(i) / (1 - ccs_penalty);

    %% --- LCOC - Levelized Cost Of Capture ---
    % Guard lifetime for amortization (avoid division by zero)
    lifetime_eff = max(inputs.ccs_plant_lifetime(i), 1);
    
    if dacService
        % DAC as a service: contracted price is the full capture cost, no amortization
        ccs_cost(i)      = inputs.ccs_plant_cost(i);
        credit_effect(i) = inputs.credit_value(i);
    else
        % Detailed CCS accounting
        ccs_cost(i)      = ccs_plant_capex(i) / CO2_captured(i) + ...
                           inputs.ccs_plant_decom_cost(i) + ...
                           inputs.ccs_plant_opex(i) + ...
                           CO2_transport_cost(i) + ...
                           inputs.storage_cost(i) + ...
                           inputs.offset_cost(i) * ...
                            CO2_uncaptured(i) / CO2_captured(i);
        credit_effect(i) = inputs.credit_value(i) * ...
                            (paramConst.credit_lifetime / lifetime_eff);
    end

    % Levelized Cost Of Capture in $/tCO2
    LCOC(i) = ccs_cost(i) - credit_effect(i);

    %% --- LCOS - Levelized Cost Of Storage ---
    % If capture is zero (i.e., in validate_mode), avoid 0 division
    if CO2_captured(i) > 0
        % Capture + generating system cost per ton CO2 captured in $/tCO2
        ccs_driver_cost(i) = (fuel_cost(i) + ...
                              power_plant_capex(i) + ...
                              power_plant_decom_cost(i) + ...
                              inputs.power_plant_opex(i)) * ...
                               (ccs_penalty / CO2_captured(i));
        LCOS(i) = LCOC(i) + ccs_driver_cost(i);
        breakeven_credit(i) = LCOS(i);
    else
        LCOS(i)             = NaN;
        breakeven_credit(i) = NaN;
    end

end

% Package outputs
results.pow_CRF                 = pow_CRF;
results.ccs_CRF                 = ccs_CRF;
results.fuel_cost               = fuel_cost;
results.power_plant_capex       = power_plant_capex;
results.power_plant_decom_cost  = power_plant_decom_cost;
results.ccs_plant_capex         = ccs_plant_capex;
results.ccs_plant_decom_cost    = ccs_plant_decom_cost;
results.CO2_captured            = CO2_captured;
results.CO2_uncaptured          = CO2_uncaptured;
results.CO2_transport_cost      = CO2_transport_cost;
results.cost_total              = cost_total;
results.ccs_cost                = ccs_cost;
results.ccs_driver_cost         = ccs_driver_cost;
results.credit_effect           = credit_effect;
results.LCOE                    = LCOE;
results.LCOC                    = LCOC;
results.LCOS                    = LCOS;
results.breakeven_credit        = breakeven_credit;

end