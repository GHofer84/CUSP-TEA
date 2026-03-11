%--------------------------------------------------------------------------
% RUNcomputeSimulation.m
%
% Author: Gerhard Hofer
% Affiliation: Arizona State University
% Date: January 2026
%
% Purpose:
%   Master driver script to run Monte Carlo simulations across all defined
%   scenarios (Coal/NG/NGCC + PSC/DAC). Produces scenario-specific plots,
%   combined breakeven credit CDFs, and optional PDF reports. Also supports
%   validation mode for comparing model LCOE ranges against Lazard baselines.
%
% Workflow:
%   1. Run validation scenarios (Coal/NG/NGCC PSC without CCS) and store results.
%   2. Run full CCS scenarios (Coal/NG/NGCC + PSC/DAC).
%   3. Plot scenario-specific results and breakeven credit CDFs.
%   4. Summarize validation ranges and Lazard baselines in comparison chart.
%   5. Optionally export all figures into a single PDF report.
%   6. Optionally save full run snapshot for reproducibility.
%--------------------------------------------------------------------------

close all
clearvars
clc

initFigureStyle;

%======================================================================
% Simulation Settings
%======================================================================

% Monte Carlo sampling
N = 10000;                   % Number of Latin Hypercube samples

% Scenario configuration
decommissioning   = false;   % true: include plant decommissioning costs
validate_mode     = true;    % true: run PSC-only baseline for Lazard comparison (Step 1)

% Reporting & outputs
Lazard_comparison = true;    % true: include Lazard ranges in LCOE summary plot
pdf_report        = true;    % true: export all charts into a timestamped PDF
save_run          = true;    % true: save full snapshot of this run for reproducibility

%======================================================================
% Banner + RNG initialization
%======================================================================

rng('shuffle');
rngState = rng;   % store full RNG state for reproducibility

params = defineParams; % capture the full parameter set for this run

runTimestamp = datestr(now,'yyyymmdd_HHMMSS');

fprintf('\n===============================================================\n');
fprintf('  CUSP Monte Carlo Simulation\n');
fprintf('  Run started at: %s\n', datestr(now,'yyyy-mm-dd HH:MM:SS'));
fprintf('===============================================================\n\n');

fprintf('Settings:\n');
fprintf('  Samples (N):            %d\n', N);
fprintf('  Decommissioning:        %d\n', decommissioning);
fprintf('  Validation mode:        %d\n', validate_mode);
fprintf('  Lazard comparison:      %d\n', Lazard_comparison);
fprintf('  PDF report:             %d\n', pdf_report);
fprintf('  Save run snapshot:      %d\n', save_run);
fprintf('  RNG seed:               %d\n', rngState.Seed);
fprintf('\n');


%--------------------------------------------------------------------------
% Step 1: Run validation scenarios (Coal/NG/NGCC PSC without CCS)
%--------------------------------------------------------------------------
validationScenarios = {'Coal + PSC','NG + PSC','NGCC + PSC'};
valResults = struct();

for s = 1:length(validationScenarios)
    scenario = validationScenarios{s};
    baseName  = strrep(scenario,' + PSC','');   % e.g. 'Coal'
    fieldName = [baseName '_Validation'];       % e.g. 'Coal_Validation'

    valResults.(fieldName) = simulateScenario(N, scenario, decommissioning, validate_mode, params);
    disp(['Validation run for ', scenario, ' completed.']);
end

ValidationLCOE = extractLCOEvalidate(valResults);


%--------------------------------------------------------------------------
% Step 2: Run full CCS scenarios
%--------------------------------------------------------------------------
validate_mode = false;

scenarios = {'Coal + PSC','Coal + DAC', ...
             'NG + PSC','NG + DAC', ...
             'NGCC + PSC','NGCC + DAC'};

results = struct();

for s = 1:length(scenarios)
    scenario = scenarios{s};
    fieldName = matlab.lang.makeValidName(scenario);

    results.(fieldName) = simulateScenario(N, scenario, decommissioning, validate_mode, params);
    disp(['Simulation run for ', scenario, ' completed.']);

    plotResultsDual(results.(fieldName));
end


%--------------------------------------------------------------------------
% Step 3: Plot combined breakeven credit CDFs
%--------------------------------------------------------------------------
allResults = cell(1, numel(scenarios));
for s = 1:numel(scenarios)
    fieldName = matlab.lang.makeValidName(scenarios{s});
    allResults{s} = results.(fieldName);
end

plotBreakevenCDF(allResults);


%--------------------------------------------------------------------------
% Step 4: Lazard comparison (with validation baselines)
%--------------------------------------------------------------------------
LCOEsummary = [];
LazardLCOE  = struct();

if Lazard_comparison
    LazardLCOE.Coal.min = 71;   LazardLCOE.Coal.max = 173;
    LazardLCOE.NGCC.min = 48;   LazardLCOE.NGCC.max = 109;
    LazardLCOE.NGP.min  = 149;  LazardLCOE.NGP.max  = 251;
    LazardLCOE.USN.min  = 141;  LazardLCOE.USN.max  = 220;
    LazardLCOE.SPVU.min = 38;   LazardLCOE.SPVU.max = 78;
    LazardLCOE.SPVSU.min= 50;   LazardLCOE.SPVSU.max= 131;
    LazardLCOE.WO.min   = 37;   LazardLCOE.WO.max   = 86;
    LazardLCOE.WSO.min  = 44;   LazardLCOE.WSO.max  = 123;

    LCOEsummary = extractLCOEsummary(results, scenarios);

    plotLCOEsummary(LCOEsummary, LazardLCOE, ValidationLCOE);
else
    LCOEsummary = extractLCOEsummary(results, scenarios);
end

%--------------------------------------------------------------------------
% Step 5: Generate PDF with all plots
%--------------------------------------------------------------------------
if pdf_report

    % Determine project root (this file lives in src/drivers)
    thisFile    = mfilename('fullpath');
    driversDir  = fileparts(thisFile);     % .../src/drivers
    srcDir      = fileparts(driversDir);   % .../src
    projectRoot = fileparts(srcDir);       % .../CUSP-TEA

    % Ensure snapshots directory exists
    snapshotDir = fullfile(projectRoot, 'snapshots');
    if ~exist(snapshotDir, 'dir')
        mkdir(snapshotDir);
    end

    % Construct full PDF path
    pdfName = fullfile(snapshotDir, ['Scenario_Comparison_Plots_' runTimestamp '.pdf']);

    disp('Plotting charts and exporting figures to PDF; please wait...');

    % Collect all figure handles in creation order
    figHandles = findall(0, 'Type', 'figure');
    [~, idx] = sort([figHandles.Number]);
    figHandles = figHandles(idx);

    % Append each figure to the PDF
    for i = 1:length(figHandles)
        fig = figHandles(i);
        figure(fig);
        exportgraphics(fig, pdfName, 'Append', i > 1, 'ContentType', 'vector');
        disp(['  Adding figure ' num2str(fig.Number) ' to PDF...']);
    end

    disp(['PDF export complete: ' pdfName]);
end

%--------------------------------------------------------------------------
% Step 6: Save full run snapshot for reproducibility
%--------------------------------------------------------------------------
if save_run
    saveRunSnapshot(results, valResults, LCOEsummary, ValidationLCOE, ...
                LazardLCOE, N, decommissioning, runTimestamp, ...
                validate_mode, Lazard_comparison, pdf_report, ...
                save_run, rngState, params);
end


%--------------------------------------------------------------------------
% Step 7: Final message
%--------------------------------------------------------------------------
disp(' ');
disp('===================================================================');
disp(' Simulation complete.');
disp(' ');
disp(' You can now run RUNcomputeOverlap to compute:');
disp('   • PSC–DAC overlap metrics for NG and NGCC');
disp('   • Full median summary (TEA + Validation + Lazard)');
disp('   • Additional diagnostic outputs');
disp(' ');
disp(' Example:');
disp('   >> RUNcomputeOverlap');
disp(' ');
disp('===================================================================');