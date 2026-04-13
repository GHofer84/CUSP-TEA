%--------------------------------------------------------------------------
% RUNreproduceSnapshot.m
%
% Author: Gerhard Hofer
% Affiliation: Arizona State University
% Date: February 2026
%
% Purpose:
%   Reproduce a previous simulation run either:
%     (1) EXACTLY using the parameters stored in the snapshot, or
%     (2) Using UPDATED parameters from defineParams.m while keeping the
%         original RNG state and settings.
%
%   Fully project-root aware:
%     - Loads snapshots from /snapshots
%     - Saves reproduced snapshots into /snapshots
%     - Saves reproduced PDFs into /snapshots
%
% Usage:
%   >> RUNreproduceSnapshot
%--------------------------------------------------------------------------

close all
clearvars
clc

initFigureStyle;

disp('===============================================================');
disp('  Reproduce Previous CUSP Simulation Run');
disp('===============================================================');
disp(' ');

%% ------------------------------------------------------------------------
% Step 0: Resolve project root and snapshot directory
% -------------------------------------------------------------------------
thisFile    = mfilename('fullpath');   % .../src/drivers/RUNreproduceSnapshot.m
driversDir  = fileparts(thisFile);     % .../src/drivers
srcDir      = fileparts(driversDir);   % .../src
projectRoot = fileparts(srcDir);       % .../CUSP-TEA

snapshotDir = fullfile(projectRoot, 'snapshots');

if ~exist(snapshotDir, 'dir')
    error('Snapshot directory not found: %s', snapshotDir);
end

%% ------------------------------------------------------------------------
% Step 1: Let user select a snapshot to reproduce
% -------------------------------------------------------------------------
files = dir(fullfile(snapshotDir, 'runSnapshot_*.mat'));

if isempty(files)
    disp(['No snapshot files found in: ' snapshotDir]);
    return;
end

% Sort newest first
[~, idx] = sort([files.datenum], 'descend');
files = files(idx);

disp('Available snapshots:');
for i = 1:length(files)
    fprintf('  [%d] %s   (%s)\n', i, files(i).name, files(i).date);
end

choice = input('\nSelect a snapshot to reproduce (number): ');

if isempty(choice) || choice < 1 || choice > length(files)
    disp('Invalid selection. Aborting.');
    return;
end

selectedFile = fullfile(snapshotDir, files(choice).name);
fprintf('\nLoading snapshot: %s\n', selectedFile);

data = load(selectedFile);

% Support both original and reproduced snapshots
if isfield(data, 'runInfo')
    runInfo = data.runInfo;
elseif isfield(data, 'runInfo_reproduced')
    runInfo = data.runInfo_reproduced;
else
    error('Snapshot does not contain runInfo or runInfo_reproduced. Cannot reproduce.');
end

originalTS = runInfo.timestamp;

fprintf('Original run timestamp: %s\n', originalTS);
fprintf('Restoring RNG state and settings...\n');


%% ------------------------------------------------------------------------
% Step 2: Restore RNG state and settings
% -------------------------------------------------------------------------
if isfield(runInfo, 'rngState')
    rng(runInfo.rngState);
else
    warning('Snapshot predates RNG-state saving. Using default RNG.');
    rng('default');
end

N                 = runInfo.N;
decommissioning   = runInfo.decommissioning;
validate_mode     = runInfo.validate_mode;
Lazard_comparison = runInfo.Lazard_comparison;
pdf_report        = runInfo.pdf_report;
save_run          = runInfo.save_run;


%% ------------------------------------------------------------------------
% Step 3: Parameter mode selection
% -------------------------------------------------------------------------
fprintf('\nParameter handling options:\n');
fprintf('  [1] Use parameters stored in snapshot (exact reproduction)\n');
fprintf('  [2] Use current parameters from defineParams.m (updated run)\n');

paramChoice = input('Select parameter mode (1 or 2): ');

if paramChoice == 1
    if isfield(runInfo, 'params')
        params = runInfo.params;
        fprintf('Using parameters stored in snapshot.\n\n');

    elseif isfield(runInfo, 'params_used')
        params = runInfo.params_used;
        fprintf('Using parameters stored in reproduced snapshot.\n\n');

    else
        warning('Snapshot does not contain parameters. Using defineParams.m instead.');
        params = defineParams;
    end

else
    params = defineParams;
    fprintf('Using current parameters from defineParams.m.\n\n');
end

newTS = datestr(now,'yyyymmdd_HHMMSS');

fprintf('New run timestamp: %s\n', newTS);
fprintf('Reproducing simulation...\n\n');


%% ------------------------------------------------------------------------
% Step 4: Run validation scenarios (PSC only)
% -------------------------------------------------------------------------
validationScenarios = {'Coal + PSC','NG + PSC','NGCC + PSC'};
valResults = struct();

for s = 1:length(validationScenarios)
    scenario = validationScenarios{s};
    baseName  = strrep(scenario,' + PSC','');
    fieldName = [baseName '_Validation'];

    valResults.(fieldName) = simulateScenario(N, scenario, decommissioning, true, params);
end

ValidationLCOE = extractLCOEvalidate(valResults);


%% ------------------------------------------------------------------------
% Step 5: Run full CCS scenarios
% -------------------------------------------------------------------------
validate_mode = false;

scenarios = {'Coal + PSC','Coal + DAC', ...
             'NG + PSC','NG + DAC', ...
             'NGCC + PSC','NGCC + DAC'};

results = struct();

for s = 1:length(scenarios)
    scenario = scenarios{s};
    fieldName = matlab.lang.makeValidName(scenario);

    results.(fieldName) = simulateScenario(N, scenario, decommissioning, validate_mode, params);
    plotResultsDual(results.(fieldName));
end

allResults = cell(1, numel(scenarios));
for s = 1:numel(scenarios)
    fieldName = matlab.lang.makeValidName(scenarios{s});
    allResults{s} = results.(fieldName);
end

plotBreakevenCDF(allResults);


%% ------------------------------------------------------------------------
% Step 6: Lazard comparison
% -------------------------------------------------------------------------
LCOEsummary = extractLCOEsummary(results, scenarios);

if Lazard_comparison
    LazardLCOE = data.LazardLCOE;
    plotLCOEsummary(LCOEsummary, LazardLCOE, ValidationLCOE);
else
    LazardLCOE = struct();
end


%% ------------------------------------------------------------------------
% Step 7: Export PDF into /snapshots
% -------------------------------------------------------------------------
if pdf_report
    pdfName = fullfile(snapshotDir, ...
        ['Scenario_Comparison_Plots_' newTS '_duplicateOf_' originalTS '.pdf']);

    disp('Plotting charts and exporting reproduced figures to PDF:');

    figHandles = findall(0, 'Type', 'figure');
    [~, idx] = sort([figHandles.Number]);
    figHandles = figHandles(idx);

    for i = 1:length(figHandles)
        fig = figHandles(i);
        figure(fig);
        exportgraphics(fig, pdfName, 'Append', i > 1, 'ContentType', 'vector');
        fprintf('  Adding figure %d to PDF...\n', fig.Number);
    end

    disp(['PDF export complete: ' pdfName]);
end


%% ------------------------------------------------------------------------
% Step 8: Save reproduced snapshot into /snapshots
% -------------------------------------------------------------------------
if save_run
    snapshotName = fullfile(snapshotDir, ...
        ['runSnapshot_' newTS '_duplicateOf_' originalTS '.mat']);

    runInfo_reproduced = runInfo;
    runInfo_reproduced.reproduced_from = originalTS;
    runInfo_reproduced.reproduced_timestamp = newTS;
    runInfo_reproduced.params_used = params;

    save(snapshotName, ...
        'results', ...
        'valResults', ...
        'LCOEsummary', ...
        'ValidationLCOE', ...
        'LazardLCOE', ...
        'runInfo_reproduced');

    fprintf('\nSaved reproduced snapshot to: %s\n', snapshotName);
end


%% ------------------------------------------------------------------------
% Step 9: Final message
% -------------------------------------------------------------------------
disp(' ');
disp('===============================================================');
disp(' Reproduction complete.');
disp(' ');
disp([' Original timestamp:   ', originalTS]);
disp([' Reproduced timestamp: ', newTS]);
disp(' ');
disp('===============================================================');
disp(' ');