%--------------------------------------------------------------------------
% saveRunSnapshot.m
%
% Author: Gerhard Hofer
% Affiliation: Arizona State University
% Date: January 2026
%
% Purpose:
%   Save a complete snapshot of a simulation run, including:
%     - full scenario results
%     - validation results
%     - LCOE summaries
%     - Lazard comparison data
%     - all run settings
%     - RNG state for reproducibility
%
% Inputs:
%   results            - struct of full scenario results
%   valResults         - struct of validation scenario results
%   LCOEsummary        - struct of LCOE summary statistics
%   ValidationLCOE     - struct of validation LCOE summary statistics
%   LazardLCOE         - struct of Lazard baseline ranges
%   N                  - number of Monte Carlo samples
%   decommissioning    - boolean flag
%   runTimestamp       - timestamp string for filenames
%   validate_mode      - boolean flag
%   Lazard_comparison  - boolean flag
%   pdf_report         - boolean flag
%   save_run           - boolean flag
%   rngState           - struct returned by rng()
%
% Outputs:
%   Saves a .mat file containing all inputs and a runInfo struct.
%
%--------------------------------------------------------------------------

function saveRunSnapshot(results, valResults, LCOEsummary, ValidationLCOE, ...
                         LazardLCOE, N, decommissioning, runTimestamp, ...
                         validate_mode, Lazard_comparison, pdf_report, ...
                         save_run, rngState, params)

    % Determine project root (two levels above this file)
    thisFile    = mfilename('fullpath');
    utilsDir    = fileparts(thisFile);          % .../src/utils
    srcDir      = fileparts(utilsDir);          % .../src
    projectRoot = fileparts(srcDir);            % .../CUSP-TEA

    % Ensure snapshots directory exists
    snapshotDir = fullfile(projectRoot, 'snapshots');
    if ~exist(snapshotDir, 'dir')
        mkdir(snapshotDir);
    end

    % Construct filename
    filename = fullfile(snapshotDir, ['runSnapshot_' runTimestamp '.mat']);

    % Build runInfo struct
    runInfo = struct();
    runInfo.timestamp         = runTimestamp;
    runInfo.N                 = N;
    runInfo.decommissioning   = decommissioning;
    runInfo.validate_mode     = validate_mode;
    runInfo.Lazard_comparison = Lazard_comparison;
    runInfo.pdf_report        = pdf_report;
    runInfo.save_run          = save_run;
    runInfo.rngState          = rngState;
    runInfo.params            = params;

    % Save snapshot
    save(filename, ...
        'results', ...
        'valResults', ...
        'LCOEsummary', ...
        'ValidationLCOE', ...
        'LazardLCOE', ...
        'runInfo');

    fprintf('\nSaved full run snapshot to: %s\n', filename);
end