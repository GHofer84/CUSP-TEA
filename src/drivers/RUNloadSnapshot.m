%--------------------------------------------------------------------------
% RUNloadSnapshot.m
%
% Author: Gerhard Hofer
% Affiliation: Arizona State University
% Date: March 2026
%
% Purpose:
%   Load a previously saved simulation snapshot from the project-level
%   /snapshots directory. Returns all stored variables as function outputs
%   and assigns them into the base workspace for compatibility.
%--------------------------------------------------------------------------

function [results, valResults, LCOEsummary, ValidationLCOE, LazardLCOE, runInfo] = RUNloadSnapshot()

    % Determine project root (this file lives in src/utils)
    thisFile    = mfilename('fullpath');
    utilsDir    = fileparts(thisFile);
    srcDir      = fileparts(utilsDir);
    projectRoot = fileparts(srcDir);

    % Snapshot directory
    snapshotDir = fullfile(projectRoot, 'snapshots');

    % Find snapshot files
    files = dir(fullfile(snapshotDir, 'runSnapshot_*.mat'));

    if isempty(files)
        error('No snapshot files found in %s', snapshotDir);
    end

    % Sort by date (newest first)
    [~, idx] = sort([files.datenum], 'descend');
    files = files(idx);

    % Display menu
    fprintf('Available run snapshots:\n');
    for i = 1:length(files)
        fprintf('  [%d] %s   (%s)\n', i, files(i).name, files(i).date);
    end

    % Prompt user
    choice = input('\nSelect a snapshot to load (number): ');

    if isempty(choice) || choice < 1 || choice > length(files)
        error('Invalid selection.');
    end

    selectedFile = fullfile(snapshotDir, files(choice).name);
    fprintf('\nLoading snapshot: %s\n', selectedFile);

    % Load into struct
    data = load(selectedFile);

    % Extract expected fields
    results        = data.results;
    valResults     = data.valResults;
    LCOEsummary    = data.LCOEsummary;
    ValidationLCOE = data.ValidationLCOE;
    LazardLCOE     = data.LazardLCOE;

    % --- Modular runInfo handling ---
    runInfoField = '';
    if isfield(data, 'runInfo')
        runInfoField = 'runInfo';
    elseif isfield(data, 'runInfo_reproduced')
        runInfoField = 'runInfo_reproduced';
    else
        error('Snapshot does not contain runInfo or runInfo_reproduced.');
    end

    runInfo = data.(runInfoField);

    % Clear base workspace before loading snapshot variables
    evalin('base','clearvars');

    % Assign into base workspace
    assignin('base','results',results);
    assignin('base','valResults',valResults);
    assignin('base','LCOEsummary',LCOEsummary);
    assignin('base','ValidationLCOE',ValidationLCOE);
    assignin('base','LazardLCOE',LazardLCOE);

    % Canonical name
    assignin('base','runInfo',runInfo);

    % Preserve original name if reproduced
    if strcmp(runInfoField,'runInfo_reproduced')
        assignin('base','runInfo_reproduced',runInfo);
    end

    fprintf('\nSnapshot loaded successfully.\n\n');
end