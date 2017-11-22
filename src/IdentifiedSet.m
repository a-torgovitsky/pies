%*******************************************************************************
% IdentifiedSet.m
%
% The main routine.
%*******************************************************************************
function [] = IdentifiedSet(SettingsIn, AssumptionsIn)

%*******************************************************************************
% Define default settings
%*******************************************************************************
Settings.N1 = 3;
Settings.N2 = 3;
Settings.Continuous = 0;
Settings.Beta0 = .5;
Settings.Beta1 = -.75;
Settings.Beta2 = 1;
Settings.Pi0 = .3;
Settings.Pi1 = 1;
Settings.Pi2 = .2;
Settings.Sigma1 = 1;
Settings.Sigma2 = 1;
Settings.Theta = 1; % Parameter of the Gumbel Copula (1 = independence)
Settings.ParametricFS = 0;

Settings.Beta0GridLB = -1.5;
Settings.Beta0GridUB = 3;
Settings.Beta1GridLB = -3;
Settings.Beta1GridUB = 2;
Settings.Pi0GridLB = -.5;
Settings.Pi0GridUB = 1.5;
Settings.Pi2GridLB = -1.5;
Settings.Pi2GridUB = 1.5;

%Settings.Beta0GridStep = .5; % Testing
%Settings.Beta1GridStep = .5;
%Settings.Pi0GridStep = .2;
%Settings.Pi2GridStep = .2;

%Settings.Beta0GridStep = .2; % Coarse Beta
%Settings.Beta1GridStep = .2;
%Settings.Pi0GridStep = .2;
%Settings.Pi2GridStep = .2;

Settings.Beta0GridStep = .05; % Production
Settings.Beta1GridStep = .05;
Settings.Pi0GridStep = .05;
Settings.Pi2GridStep = .05;

Settings.SpecNumber = [];
Settings.LPSolver = 'gurobi';
Settings.Noisy = 0;
Settings.VisualDisplayEachIter = 1;
Settings.RecordEachColumn = 1;
Settings.VisualDisplayEnd = 1;

Settings.Grayscale = .7;
Settings.FontsizeTitle = 20;
Settings.FontsizeLabel = 20;
Settings.FontsizeAxis = 20;
Settings.FontSizeTickLabels = 6;
Settings.MarkersizeBig = 7;
Settings.MarkersizeSmall = 2;
Settings.FigHeight = 7;
Settings.FigWidth = 6;

Assumptions.U1MedZeroGivenY2X1 = 0;
Assumptions.U1IndY2X1 = 0;
Assumptions.U1SymmetricGivenY2X1 = 0;
Assumptions.U1MedZeroGivenY2X1X2 = 0;
Assumptions.U1IndY2X1X2 = 0;
Assumptions.U1IndY2GivenX1X2 = 0;
Assumptions.U1SymmetricGivenY2X1X2 = 0;
Assumptions.U1MedZeroGivenX1X2 = 0;
Assumptions.U1IndX1X2 = 0;
Assumptions.U1SymmetricGivenX1X2 = 0;
Assumptions.U1U2IndX1X2 = 0;
Assumptions.U2MedZeroGivenX1X2 = 0;
Assumptions.U2SymmetricGivenX1X2 = 0;

if isempty(SettingsIn)
    warning('Empty structure for input. Using defaults.');
    SettingsIn = Settings;
end
if ~isstruct(SettingsIn)
    error('Expected structure for input. Quitting.');
else
    Settings = UpdateStruct(Settings, SettingsIn, 1);
end

Assumptions = UpdateStruct(Assumptions, AssumptionsIn, 1);


%*******************************************************************************
% Different grid settings for the continuous case
%*******************************************************************************
if Settings.Continuous
    Settings.Beta0GridLB = -1.5;
    Settings.Beta0GridUB = 2;
    Settings.Beta1GridLB = -2;
    Settings.Beta1GridUB = 1.5;

    Settings.Beta0GridStep = .1;
    Settings.Beta1GridStep = Settings.Beta0GridStep;
end

%*******************************************************************************
% Prepare to record
%*******************************************************************************
if ~isempty(Settings.SpecNumber)
    Settings.DirName = [ sprintf('Spec-%03d', Settings.SpecNumber) ...
                '-X1-' sprintf('%d', Settings.N1) ...
                '-X2-' sprintf('%d', Settings.N2)];
    if Settings.Continuous
        Settings.DirName = [Settings.DirName '-continuous'];
    end
    CreateNewResultsDir(Settings.DirName);
else
    Settings.DirName = CreateNewResultsDir;
end
fid = fopen('Settings.out', 'w');
PrintStructure(Settings, fid);
fclose(fid);
fid = fopen('Assumptions.out', 'w');
PrintStructure(Assumptions, fid);
fclose(fid);
diary('Log.out');

%*******************************************************************************
% Quit if this simulation has already been done
% (useful for batching)
%*******************************************************************************
DONEFN = './Done.out';
if exist(DONEFN, 'file') == 2
    disp(sprintf('Found %s, so quitting.', DONEFN));
    return;
end

STATUSFN = './Status.out';
if exist(STATUSFN, 'file') == 2
    disp(sprintf(['Found %s, so quitting. ' ...
                  'To overwrite, delete this file and retry.'], STATUSFN));
    return;
end

%*******************************************************************************
% Initialize AMPL instance
% Set some solver options
%*******************************************************************************
[ampl, CleanUpAMPL] = InitializeAMPL({'BivBinResp.mod'});

ampl.setOption('TMPDIR', './');
ampl.setOption('presolve_eps', '1e-5');
ampl.setOption('presolve_warnings', '-1');
ampl.setOption('solver_msg', '0');
ampl.setOption('print_precision', '6');
ampl.setOption('show_stats', '0');
ampl.setOption('show_boundtol', '0');
ampl.setOption('solver', Settings.LPSolver);

%*******************************************************************************
% Send data parameters to AMPL
%*******************************************************************************
DGP = GenerateDGP(Settings);

IdxX1X2 = [];
ValPX = [];
IdxX2X1 = [];
ValPX2GX1 = [];
IdxYX = [];
ValFYGX = [];
for k1 = 1:1:length(DGP.X1)
    for k2 = 1:1:length(DGP.X2)
        IdxX1X2 = [IdxX1X2; k1 k2];
        ValPX = [ValPX; DGP.PX(k1,k2)];
        IdxX2X1 = [IdxX2X1; k2 k1];
        ValPX2GX1 = [ValPX2GX1; DGP.PX2GX1(k2,k1)];

        for j1 = 1:1:2
            for j2 = 1:1:2
                IdxYX = [IdxYX; j1 j2 k1 k2];
                ValFYGX = [ValFYGX; DGP.FYGX(j1,j2,k1,k2)];
            end
        end
    end
end

ampl.getParameter('N1').setValues(length(DGP.X1));
ampl.getParameter('N2').setValues(length(DGP.X2));
ampl.getParameter('X1').setValues((1:1:length(DGP.X1))', DGP.X1(:));
ampl.getParameter('X2').setValues((1:1:length(DGP.X2))', DGP.X2(:));
ampl.getParameter('PX').setValues(IdxX1X2, ValPX);
ampl.getParameter('PX2GX1').setValues(IdxX2X1, ValPX2GX1);
ampl.getParameter('FYGX').setValues(IdxYX, ValFYGX);

[m1 idx1] = min(abs(DGP.X1));
ampl.getParameter('k1fix').setValues(idx1);
[m2 idx2] = min(abs(DGP.X2));
ampl.getParameter('k2fix').setValues(idx2);
if Settings.Continuous
    if (m1 > 0) | (m2 > 0)
        error('Something is wrong -- should be estimated at (0,0).')
    end
end

fidATEDGP = fopen('ATEDGP.out', 'w');
fprintf(fidATEDGP, '%6.4f', DGP.ATE);
fclose(fidATEDGP);

%*******************************************************************************
% Turn on the correct assumptions in AMPL
%*******************************************************************************
AssumptionNames = fieldnames(Assumptions);
for i = 1:1:length(AssumptionNames)
    if Assumptions.(AssumptionNames{i})
        ampl.getConstraint(AssumptionNames{i}).restore;
    else
        ampl.getConstraint(AssumptionNames{i}).drop;
    end
end

%*******************************************************************************
%*******************************************************************************
%*******************************************************************************
% Construct identified set
%
% Note that the matrices I am storing results in are set up in a graphical way
% So b0/p0 increases with the column, and b1/p2 decreases with the row
%*******************************************************************************
%*******************************************************************************
%*******************************************************************************

%*******************************************************************************
% If using a parametric model for the first stage, then create an
% identified set for its parameters.
% One can then build the identified set for the outcome equation at
% each fixed value of these parameters.
% Should be a bit faster than doing the whole 4 dimensional grid
%*******************************************************************************
disp('Suspending diary for identified set construction.')
diary off;
if Settings.ParametricFS
    ampl.getParameter('ParametricFS').setValues(1);

    Settings.Pi0Grid = ...
        Settings.Pi0GridLB:Settings.Pi0GridStep:Settings.Pi0GridUB;
    Settings.Pi2Grid = ...
        Settings.Pi2GridUB:(-1*Settings.Pi2GridStep):Settings.Pi2GridLB;
    IDSetPi = 2*ones(length(Settings.Pi2Grid), length(Settings.Pi0Grid));
    Str = {'Identified set for (pi0, pi2):'};

    % Set (beta0, beta1) to their true values so that the outcome equation
    % is not the cause of being inside or outside of the identified set.
    % This is just for ease in programming. An alternative would be to
    % just solve a single equation model with only the first stage.
    ampl.getParameter('beta0').setValues(Settings.Beta0);
    ampl.getParameter('beta1').setValues(Settings.Beta1);

    for p0 = 1:1:length(Settings.Pi0Grid)
    for p2 = 1:1:length(Settings.Pi2Grid)
        ampl.getParameter('pi0').setValues(Settings.Pi0Grid(p0));
        ampl.getParameter('pi2').setValues(Settings.Pi2Grid(p2));

        Obj = SolveProgram(ampl, 'Constant', Settings.Noisy);

        idstr = sprintf('Pi0 = %4.3f, Pi2 = %4.3f',...
            Settings.Pi0Grid(p0), Settings.Pi2Grid(p2));
        IDSetPi(p2,p0) = CheckFeasibility(Obj, idstr);

        if Settings.VisualDisplayEachIter
            VisualDisplay(IDSetPi, 1, [], Str);
        end
    end
    end

    [IDSetPi2Idx IDSetPi0Idx] = find(IDSetPi == 1);
    IDListPi = zeros(size(IDSetPi2Idx, 1), 2);
    for p = 1:1:size(IDSetPi2Idx, 1)
        IDListPi(p,:) = [Settings.Pi0Grid(IDSetPi0Idx(p)), ...
                         Settings.Pi2Grid(IDSetPi2Idx(p))];
    end
else
    % Also for coding convenience --- knowing these is not necessary
    IDListPi = [Settings.Pi0, Settings.Pi2];
end

diary on;
if size(IDListPi, 1) == 0
    disp(['Identified set for Pi is empty. '...
          'Maybe the grid is too coarse? '...
          'Nothing to do, so quitting.']);
    WriteDone(DONEFN);
    return;
end

Settings.Beta0Grid = ...
    Settings.Beta0GridLB:Settings.Beta0GridStep:Settings.Beta0GridUB;
Settings.Beta1Grid = ...
    Settings.Beta1GridUB:(-1*Settings.Beta1GridStep):Settings.Beta1GridLB;

IDSetBeta = 2*ones( length(Settings.Beta1Grid), length(Settings.Beta0Grid),...
                    size(IDListPi, 1));
MinATE = inf(size(IDSetBeta));
MaxATE = -1*MinATE;

fidTime = fopen('SolveTime.out', 'w');

Str{1} = 'Identified set for (beta0, beta1):';
diary off;
fidStatus = fopen(STATUSFN, 'w');
StatusStr = '';
for p = 1:1:size(IDListPi, 1)
    ampl.getParameter('pi0').setValues(IDListPi(p,1));
    ampl.getParameter('pi2').setValues(IDListPi(p,2));
    if Settings.ParametricFS
        Str{2} = sprintf('Fixing Pi0 = %4.3f, Pi2 = %4.3f',...
            IDListPi(p,1), IDListPi(p,2));
        Str{2} = [Str{2} sprintf(' -- point %d of %d.', p, size(IDSetBeta,3))];
    else
        Str{2} = [];
    end

    for b0 = 1:1:length(Settings.Beta0Grid)
    for b1 = 1:1:length(Settings.Beta1Grid)
        frewind(fidStatus);
        StatusStr = ...
            sprintf('%s: Beta point %d of %d, for Pi point %d of %d.\n',...
                    datestr(datetime('now')),...
                    (b0-1)*length(Settings.Beta1Grid) + b1,...
                    length(Settings.Beta0Grid)*length(Settings.Beta1Grid),...
                    p, size(IDListPi, 1));
        fprintf(fidStatus, StatusStr);

        SolveTime = nan(3,1);

        ampl.getParameter('beta0').setValues(Settings.Beta0Grid(b0));
        ampl.getParameter('beta1').setValues(Settings.Beta1Grid(b1));

        % Feasibility first
        [Obj, SolveTime(1)] = SolveProgram(ampl, 'Constant', Settings.Noisy);

        idstr = sprintf('Beta0 = %4.3f, Beta1 = %4.3f',...
            Settings.Beta0Grid(b0), Settings.Beta1Grid(b1));
        IDSetBeta(b1,b0,p) = CheckFeasibility(Obj, idstr);

        % If feasible then do the minimization and maximization problems
        if IDSetBeta(b1,b0,p)

            if Settings.Continuous
                ObjName = 'ObjMinATEFixed';
            else
                ObjName = 'ObjMinATE';
            end
            [Obj, SolveTime(2)] = SolveProgram(ampl, ObjName, Settings.Noisy);
            MinATE(b1,b0,p) = Obj.value;

            if Settings.Continuous
                ObjName = 'ObjMaxATEFixed';
            else
                ObjName = 'ObjMaxATE';
            end
            [Obj, SolveTime(3)] = SolveProgram(ampl, ObjName, Settings.Noisy);
            MaxATE(b1,b0,p) = Obj.value;
        end

        if Settings.VisualDisplayEachIter
            VisualDisplay(IDSetBeta(:,:,p), 1, SolveTime, Str);
        end

        fprintf(fidTime, '%5.3f %5.3f %5.3f\n', SolveTime(:));
    end
    end
end
diary on;
fclose(fidStatus);
fclose(fidTime);

Str = {'Final identified set for (beta0, beta1):'};
if (Settings.VisualDisplayEnd & ~Settings.VisualDisplayEachIter)...
    | (Settings.VisualDisplayEnd & Settings.ParametricFS)
        VisualDisplay(max(IDSetBeta, [], 3), 0, [], Str);
end

%*******************************************************************************
% Record in list format
%*******************************************************************************
fid = fopen('BoundsList.out', 'w');
ATEList = [];
for p = 1:1:size(IDListPi, 1)
    [IDSetBeta1Idx IDSetBeta0Idx] = find(IDSetBeta(:,:,p) == 1);

    if Settings.ParametricFS
        fprintf(fid, 'pi0,pi2,beta0,beta1,atemin,atemax\n');
    else
        fprintf(fid, 'beta0,beta1,atemin,atemax\n');
    end

    BoundsList = zeros(size(IDSetBeta1Idx, 1), 4);

    for b = 1:1:size(IDSetBeta1Idx, 1)
        BoundsList(b,:) = [ Settings.Beta0Grid(IDSetBeta0Idx(b)),...
                            Settings.Beta1Grid(IDSetBeta1Idx(b)),...
                            MinATE(IDSetBeta1Idx(b), IDSetBeta0Idx(b)),...
                            MaxATE(IDSetBeta1Idx(b), IDSetBeta0Idx(b))];

        if Settings.ParametricFS
            fprintf(fid, '%4.3f,%4.3f,', IDListPi(p,:));
        end
        fprintf(fid, '%4.3f,%4.3f,%4.3f,%4.3f\n', BoundsList(b,:));

        ATEList = [ATEList; BoundsList(b,3:4)];
    end
end
fclose(fid);

%*******************************************************************************
% Determine the identified set for the ATE
% being careful to look for disconnected sets
%*******************************************************************************
if ~isempty(ATEList)
    fid = fopen('IDSetATE.out', 'w');
    ATEList = unique(round(ATEList, 6), 'rows');
    [MergedLB MergedUB] = MergeBrackets(ATEList(:,1), ATEList(:,2));
    for m = 1:1:length(MergedLB)
        fprintf(fid, '%8.6f %8.6f\n', MergedLB(m), MergedUB(m));
    end
    fclose(fid);
end

%*******************************************************************************
% Make plots for this simulation
%*******************************************************************************
PlotID(max(IDSetBeta, [], 3), MinATE, MaxATE, Settings, 1);
PlotID(max(IDSetBeta, [], 3), MinATE, MaxATE, Settings, 0);

%*******************************************************************************
% Record this simulation as done
%*******************************************************************************
WriteDone(DONEFN);
diary off;
end

%*******************************************************************************
%*******************************************************************************
%*******************************************************************************
% Change objective and solve quietly
function [Obj, SolveTime] = SolveProgram(ampl, ObjectiveName, Noisy)

    ampl.eval(['objective ' ObjectiveName ';']);
    OptStart = tic;

    if Noisy
        eval('ampl.eval(''solve;'')');
    else
        evalc('ampl.eval(''solve;'')');
    end

    SolveTime = toc(OptStart);
    Obj = ampl.getObjective(ObjectiveName);
end

%*******************************************************************************
%*******************************************************************************
%*******************************************************************************
% Recover exit code of objective and check if feasible or solved
function Feasible = CheckFeasibility(Obj, idstr)

    SolveResult = char(Obj.result);

    if ismember(SolveResult, {'solved', 'solved?'})
        Feasible = 1;
    elseif ismember(SolveResult, {'infeasible', 'infeasible?'})
        Feasible = 0;
    else
        warning('Problem in %s: SolveResult is %s', idstr, SolveResult);
        Feasible = 3;
    end

end

%*******************************************************************************
%*******************************************************************************
%*******************************************************************************
% Display the current known identified set on screen
function VisualDisplay(IDSet, Clear, SolveTime, Str)
    if Clear
        clc;
    else
        disp(sprintf(' ')); % Adds a new line for space
    end
    disp(pwd);
    VisualCode = '01?!';
    IDSetPrint = VisualCode(IDSet + ones(size(IDSet)));
    if exist('Str', 'var')
        for j = 1:1:length(Str)
            disp(Str{j});
        end
    end
    disp(IDSetPrint);

    if ~exist('SolveTime', 'var')
        SolveTime = [];
    end
    if ~isempty(SolveTime)
        str = sprintf('Solve times (in seconds):\n');
        str = [str sprintf('  Feasibility: %5.3f\n', SolveTime(1))];
        str = [str sprintf('          Min: %5.3f\n', SolveTime(2))];
        str = [str sprintf('          Max: %5.3f\n', SolveTime(3))];
        disp(str);
    end
end

%*******************************************************************************
%*******************************************************************************
%*******************************************************************************
function WriteDone(DONEFN)
    fiddone = fopen(DONEFN, 'w');
    fprintf(fiddone, '-');
    fclose(fiddone);
    disp('Simulation done.');
end
