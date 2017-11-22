%*******************************************************************************
% Setup.m
%
% Setup actions at the start of Run
%*******************************************************************************
function [CleanUpPath, DirName] = Setup(ScriptTag, DirName)

    OriginalPath = pwd;
    CleanUpPath = onCleanup(@()cd(OriginalPath));

    addpath('../cfg')
    evalc('Config'); % Load user-defined paths

    if ~exist(SAVEDIRECTORY, 'dir')
        error('SAVEDIRECTORY %s does not exist.', SAVEDIRECTORY);
    end

    % Create a directory path name
    if ~exist('DirName', 'var')
        DirName = [];
    end

    if isempty(DirName)
        [DirPath DirName] = MakeTargetDirName(SAVEDIRECTORY, ScriptTag, 1);
    else
        DirPath = [SAVEDIRECTORY DirName];
    end

    % Create a new directory, copy everything there and cd to it
    CreateSaveDirectory(DirPath);

    % Create a results subdirectory and move there
    if ~exist('./results', 'dir')
        mkdir('results');
    end
    cd('results');

    % Add paths
    addpath(genpath(DirPath));

    % Setup AMPL
    if ~exist(AMPLAPISETUPPATH, 'file')
        error('Path %s for AMPL API SetUp.m file does not exist.',...
                AMPLAPISETUPPATH);
    else
        evalc(['run ' AMPLAPISETUPPATH]);
    end
end

%*******************************************************************************
% MakeTargetDirName
%
% Make a target directory, with option to ask user for a name
%*******************************************************************************
function [DirPath, DirName] ...
    = MakeTargetDirName(BASEDIR, STUB, Interactive, tag)
%*******************************************************************************
    if ~exist('Interactive')
        Interactive = 1;
    end

    if Interactive
        tag = input('Do you want to add a tag to the directory?\n', 's');
    else
        if ~exist('tag')
            tag = [];
        end
    end
    if ~isempty(tag)
        if ~strcmp(tag(1), '-')
            tag = ['-' tag];
        end
    end
    if ~strcmp(BASEDIR(length(BASEDIR)), '/')
        BASEDIR = [BASEDIR '/'];
    end
    DirName = [STUB tag datestr(now, '-mmddyy-HHMMSS')];
    DirPath = [BASEDIR DirName];
end

%*******************************************************************************
% CreateSaveDirectory
%
% Create a directory with a current copy of the code (so that further changes
% don't affect this simulation) and where we can store results.
% Create a subdirectory in that directory to store results.
% And change directories to that subdirectory.
%*******************************************************************************
function [] = CreateSaveDirectory(DirPath)
    if isempty(DirPath)
        error('DirPath is empty!');
    end
    if ~exist(DirPath, 'dir')
        disp(sprintf('Saving in new directory %s.', DirPath));
        success = mkdir(DirPath);
        if ~success
            error('Something is wrong; error creating directory.')
        end
        copyfile('../*', DirPath);

    elseif (exist(DirPath, 'dir') == 7)
        disp(sprintf('Saving in existing directory %s.', DirPath));
        disp(sprintf('\t Directory already exists; not copying code.'));
    end
    cd(DirPath);
end
