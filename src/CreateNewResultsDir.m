%*******************************************************************************
% CreateNewResultsDir
%
% Create a new results directory (numbered sequentially) and cd to it.
%*******************************************************************************
function [DirName] = CreateNewResultsDir(DirName)
    CurrentDirectory = pwd;
    [path namestr] = fileparts(CurrentDirectory);

    % Make sure we are either in results or some directory directly below it
    if ~strcmp(namestr, 'results')
        cd('..');
        [path namestr] = fileparts(pwd);
        if ~strcmp(namestr, 'results')
            error('Something is wrong: not results or a subdirectory?');
        end
    end

    DirNumber = [];
    if ~exist('DirName', 'var')
        for i = 0:1:999
            DirName = sprintf('%03d', i + 1);
            if ~exist(DirName, 'dir')
                DirNumber = i;
                break;
            end
        end
    end

    mkdir(DirName);
    cd(DirName);
    addpath(genpath('../../'));
end
