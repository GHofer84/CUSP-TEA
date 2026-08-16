%======================================================================
% defineParams.m
%
% Author: Gerhard Hofer
% Affiliation: Arizona State University
% Date: November 2025
%
% Purpose:
%   Define sampling parameters and fixed constants for scenario-based
%   techno-economic assessment (TEA) simulations. Returns a structured
%   parameter block for modular access across scenarios.
%
% Syntax:
%   params = defineParams()
%
% Outputs:
%   params : struct containing parameter definitions organized by category
%       .general   → General economic parameters
%       .coal      → Coal-specific parameters
%       .ng        → Natural gas–refired coal parameters
%       .ngcc      → Natural gas combined cycle parameters
%       .psc       → Post-combustion capture (PSC) retrofit parameters
%       .dac       → Direct air capture (DAC) parameters
%       .const     → Fixed conversion constants
%
% Parameter Definition Conventions:
%   {'name', fixedValue}              → constant value
%   {'name', [v1, v2]}                → discrete pick between values
%   {'name', min, max, uType}         → sampled distribution
%       uType = 'u' (uniform), 's' (skewed toward lower values), or numeric
%               mode value (triangular distribution)
%
% Notes:
%   - Parameters are scenario-specific where indicated (coal, NG, NGCC).
%   - Shared CCS/DAC parameters are grouped separately for clarity.
%   - Constants provide unit conversions and fixed values used across all
%     scenarios.
%   - This function is the entry point for defining the sampling space in
%     Monte Carlo TEA simulations.
%======================================================================

function params = defineParams()

%% --- General Parameters ---
params.general = {
    {'electricity_price',       84,   158,  'u'}        % $/MWhel; AZ range between industrial and residential
    {'discount_rate',           0.05, 0.10, 0.07}       % dimensionless; ranging from 5% to 10%; mode = 7%
};

%% --- Coal (scenario specific parameters) ---
params.coal = {
    {'fuel_price',              65,   100,  'u'}        % $/tCoal
    {'coal_HHV',                           25.1}        % MJ/kg; source: EIA, 10800 Btu/lb
    {'carbon_intensity',        0.85, 1.05, 0.94}       % tCO2/MWhel; source: EPA, Coronado & Springerville avg.
    {'power_plant_net_eff',                0.33}        % fraction
    {'power_plant_cost',                      0}        % EOL; 0 = existing plant
    {'power_cost_is_levelized',               1}        % 1 = $/MWhel (already levelized), 0 = $/MW (needs CRF)
    {'power_plant_decom_cost',  10,   20,   'u'}        % $/MWhel; assumption; likely not taken into account
    {'power_decom_cost_is_levelized',         1}        % 1 = $/MWhel (already levelized), 0 = $/MW (needs CRF)
    {'power_plant_opex',        37,   48,   's'}        % $/MWhel; (29...40 + 8) $/MWhel
    {'power_plant_lifetime',                  0}        % years; 0 = existing plant
    {'capacity_factor',         0.5,  0.8,  's'}        % fraction; Power plant capacity factor
    {'psc_penalty',             0.20, 0.35, 0.30}       % fraction, MWhel loss
    {'dac_penalty',                           0}        % fraction, MWhel loss; 0 = DAC not parasitic on plant
};

%% --- Natural Gas Refired Coal (scenario specific parameters) ---
params.ng = {
    {'fuel_price',              5,    15,   'u'}        % $/Mcf; approx. AZ price range, source: EIA
    {'NG_LHV',                             1.02}        % MBtu/Mcf; approx. AZ NG LHV range, source: EIA
    {'carbon_intensity',        0.55, 0.68, 'u'}        % tCO2/MWhel; NG-refired coal, ~40% of coal baseline
    {'power_plant_net_eff',     0.35, 0.37, 0.37}       % fraction; idea: slightly better than coal, lower than NGCC 
    {'power_plant_cost',        32,   54,   'u'}        % in $/MWhel with lifetime and discounting inactive or in $/MWel with lifetime and discounting active
    {'power_cost_is_levelized',               1}        % 1 = $/MWhel (already levelized), 0 = $/MW (needs CRF)
    {'power_plant_decom_cost',  10,   20,   'u'}        % $/MWhel; same as coal, assumption
    {'power_decom_cost_is_levelized',         1}        % 1 = $/MWhel (already levelized), 0 = $/MW (needs CRF)
    {'power_plant_opex',        6,    8,    'u'}        % $/MWhel; (2...3 + 4...5) $/MWhel
    {'power_plant_lifetime',    15,   20,   'u'}        % years; assumption
    {'capacity_factor',         0.5,  0.8,  's'}        % fraction; same as coal
    {'psc_penalty',             0.20, 0.35, 0.30}       % fraction, MWhel loss; same as coal
    {'dac_penalty',                           0}        % fraction, MWhel loss; 0 = DAC not parasitic on plant
};

%% --- Natural Gas Combined Cycle (scenario specific parameters) ---
params.ngcc = {
    {'fuel_price',              5,    15,   'u'}        % $/Mcf; approx. AZ price range, source: EIA
    {'NG_LHV',                             1.02}        % MBtu/Mcf; approx. AZ NG LHV range, source: EIA
    {'carbon_intensity',        0.32, 0.36, 0.33}       % tCO2/MWhel; new plant
    {'power_plant_net_eff',     0.55, 0.60, 'u'}        % fraction; idea: slightly better than coal, lower than NGCC 
    {'power_plant_cost',        25,   50,   'u'}        % in $/MWhel with lifetime and discounting inactive or in $/MWel with lifetime and discounting active
    {'power_cost_is_levelized',               1}        % 1 = $/MWhel (already levelized), 0 = $/MW (needs CRF)
    {'power_plant_decom_cost',  5,    15,   'u'}        % $/MWhel; slightly lower as coal, assumption
    {'power_decom_cost_is_levelized',         1}        % 1 = $/MWhel (already levelized), 0 = $/MW (needs CRF)
    {'power_plant_opex',        6,    8,    'u'}        % $/MWhel; same as NG
    {'power_plant_lifetime',    30,   50,   'u'}        % years; assumption
    {'capacity_factor',         0.5,  0.8,  's'}        % fraction; same as coal
    {'psc_penalty',             0.11, 0.20, 0.17}       % fraction, MWhel loss; lower as coal - plant designed for CCS
    {'dac_penalty',                           0}        % fraction, MWhel loss; 0 = DAC not parasitic on plant
};

%% --- PSC Parameters (shared across scenarios) ---
params.psc = {
    {'capture_tech',                          0}        % 0 = PSC, 1 = DAC
    {'service_mode',                          0}        % 0 = CCS is plant owner responsibility, 1 = CCS is contracted service
    {'capture_rate',            0.85, 0.90, 'u'}        % fraction
    {'ccs_plant_cost',          40,   90,   'u'}        % $/tCO2; PSC CAPEX; min/max for coal/gas
    {'ccs_cost_is_levelized',                 1}        % 1 = $/tCO2 (already levelized), 0 = upfront capacity in $/MWel
    {'ccs_plant_decom_cost',    5,    15,   'u'}        % $/tCO2; CCS plant decommissioning cost, assumption
    {'ccs_plant_opex',          25,   60,   'u'}        % $/tCO2; fixed & var., energy cost excluded > coal burden
    {'ccs_plant_lifetime',      30,   50,   's'}        % years; assumption
    {'storage_cost',            1,    20,   'u'}        % $/tCO2
    {'transport_cost',          0.03, 0.22, 'u'}        % $/tCO2/mi
    {'pipeline_length',         1,    50,   'u'}        % mi
    {'offset_cost',             10,   50,   's'}        % $/tCO2; external offset to achieve 100% capture
    {'credit_value',                         85}        % $/tCO2; source: OBBBA
};

%% --- DAC Parameters (shared across scenarios) ---
params.dac = {
    {'capture_tech',                          1}        % 0 = PSC, 1 = DAC
    {'service_mode',                          1}        % 0 = CCS is plant owner responsibility, 1 = CCS is contracted service
    {'capture_rate',                          1}        % fraction; 1 = 100% captured with DAC
    {'ccs_plant_cost',          288,  500,  300}        % $/tCO2; DAC CAPEX or treated as price from contracted service if 'service_mode' == 1
    {'ccs_cost_is_levelized',                 1}        % 1 = $/tCO2 (already levelized), 0 = upfront capacity, which probably does not make sense here
    {'ccs_plant_decom_cost',    10,   20,   'u'}        % $/tCO2; DAC plant decommissioning cost, assumption
    {'ccs_plant_opex',          0,    100,  'u'}        % $/tCO2; DAC plant OPEX, energy cost included
    {'ccs_plant_lifetime',      30,   50,   'u'}        % years; assumption
    {'storage_cost',            1,    20,   'u'}        % $/tCO2
    {'transport_cost',          0.03, 0.22, 'u'}        % $/tCO2/mi
    {'pipeline_length',         0,    2,    'u'}        % mi
    {'offset_cost',                           0}        % $/tCO2; 0 because of 100% internal capture via DAC
    {'credit_value',                        180}        % $/tCO2; source: OBBBA
};

%% --- Fixed Constants (shared across scenarios) ---
params.const.credit_lifetime    = 12;                   % years (IRS 45Q duration)
params.const.MJ_per_MWh         = 3600;                 % conversion
params.const.kg_per_ton         = 1000;                 % kg/t
params.const.LHV_per_HHV        = 0.95;                 % dimensionless; source: EPA
params.const.MWh_per_MBtu       = 0.29307;              % MWh/MBtu

end