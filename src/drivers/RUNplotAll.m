%--------------------------------------------------------------------------
% RUNplotAll.m
%
% Author: Gerhard Hofer
% Affiliation: Arizona State University
% Date: March 2026
%
% Purpose:
%   Generate all scenario‑specific and combined plots from a previously
%   saved simulation snapshot, without re‑running any Monte Carlo sampling.
%
%   This script is fully snapshot‑driven:
%     • Loads a selected runSnapshot_*.mat file from /snapshots
%     • Reconstructs all scenario‑level plots (LCOE/LCOC/LCOS histograms,
%       breakeven credit histograms, tornado charts)
%     • Reconstructs the combined breakeven credit CDF
%     • Reconstructs the LCOE summary plot (if Lazard + validation data
%       were stored in the snapshot)
%
%   This enables:
%     • Reproducible figure generation independent of simulation runtime
%     • Consistent post‑processing for reports, manuscripts, and diagnostics
%     • Clean separation between simulation and visualization workflows
%
% Workflow:
%   1. Resolve project root and locate /snapshots directory
%   2. List available runSnapshot_*.mat files (newest first)
%   3. User selects a snapshot to visualize
%   4. Load stored results, validation data, and summary structs
%   5. Generate all scenario‑specific plots via plotResultsDual
%   6. Generate combined breakeven credit CDF
%   7. Generate LCOE summary plot (if available)
%
% Usage:
%   >> RUNplotAll
%
% Requirements:
%   • Snapshot must contain: results, valResults, LCOEsummary,
%     ValidationLCOE, LazardLCOE (depending on run settings)
%   • plotResultsDual must accept (scenarioResult, allResults)
%     for PSC‑reference line reconstruction
%
% Notes:
%   • No simulation is performed; all data come from the snapshot.
%   • Figures are saved automatically via saveFigure() using the same
%     naming conventions as RUNcomputeSimulation.
%--------------------------------------------------------------------------

function RUNplotAll
    close all;
    clc;

    initFigureStyle;

    %----------------------------------------------------------------------
    % Resolve project root and snapshot directory
    %----------------------------------------------------------------------
    thisFile    = mfilename('fullpath');   % .../src/drivers/RUNplotAll.m
    driversDir  = fileparts(thisFile);     % .../src/drivers
    srcDir      = fileparts(driversDir);   % .../src
    projectRoot = fileparts(srcDir);       % .../CUSP-TEA

    snapshotDir = fullfile(projectRoot, 'snapshots');

    if ~exist(snapshotDir, 'dir')
        error('Snapshot directory not found: %s', snapshotDir);
    end

    %----------------------------------------------------------------------
    % Step 1: Let user select a snapshot (same UX as RUNreproduceSnapshot)
    %----------------------------------------------------------------------
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

    choice = input('\nSelect a snapshot to plot (number): ');

    if isempty(choice) || choice < 1 || choice > length(files)
        disp('Invalid selection. Aborting.');
        return;
    end

    selectedFile = fullfile(snapshotDir, files(choice).name);
    fprintf('\nLoading snapshot: %s\n', selectedFile);

    data = load(selectedFile);

    %----------------------------------------------------------------------
    % Step 2: Extract stored results
    %----------------------------------------------------------------------
    if isfield(data, 'results')
        results = data.results;
    else
        error('Snapshot does not contain results.');
    end

    if isfield(data, 'valResults')
        valResults = data.valResults;
    else
        valResults = struct();
    end

    if isfield(data, 'LCOEsummary')
        LCOEsummary = data.LCOEsummary;
    else
        LCOEsummary = [];
    end

    if isfield(data, 'ValidationLCOE')
        ValidationLCOE = data.ValidationLCOE;
    else
        ValidationLCOE = [];
    end

    if isfield(data, 'LazardLCOE')
        LazardLCOE = data.LazardLCOE;
    else
        LazardLCOE = struct();
    end

    %----------------------------------------------------------------------
    % Step 3: Plot scenario-specific results
    %----------------------------------------------------------------------
    scenarioNames = fieldnames(results);

    for i = 1:numel(scenarioNames)
        plotResultsDual(results.(scenarioNames{i}), results);
    end

    %----------------------------------------------------------------------
    % Step 4: Plot combined breakeven CDF
    %----------------------------------------------------------------------
    allResults = struct2cell(results);
    plotBreakevenCDF(allResults);

    %----------------------------------------------------------------------
    % Step 5: Plot LCOE summary (if available)
    %----------------------------------------------------------------------
    if ~isempty(LCOEsummary)
        plotLCOEsummary(LCOEsummary, LazardLCOE, ValidationLCOE);
    end

    disp(' ');
    disp('===============================================================');
    disp(' All plots generated from selected snapshot.');
    disp('===============================================================');
    disp(' ');
end