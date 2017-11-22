%*******************************************************************************
% Run.m
%
% Should generally pass the following (or else defaults will be used):
%   Spec Number: 1 through 9 as in the paper
%   N1: Number of support points for X1
%   N2: Number of points for X2
%   Continuous: Flag to treat X2 as continuous
%
% Optional:
%   SaveDir: Name of the directory to save the simulation in
%       If not passed then a name will be generated with a time stamp
%*******************************************************************************
function [SaveDir] = Run(SpecNumber, N1, N2, Continuous, SaveDir)

addpath('../src');

if ~exist('SaveDir', 'var');
    SaveDir = [];
end

[CleanUpPath, SaveDir] = Setup('pies', SaveDir);

if exist('N1', 'var')
    Settings.N1 = N1;
end
if exist('N2', 'var')
    Settings.N2 = N2;
end
if exist('Continuous', 'var')
    Settings.Continuous = Continuous;
end
if ~exist('SpecNumber', 'var')
    SpecNumber = 1;
end

switch SpecNumber
    case 1
        Assumptions.U1MedZeroGivenY2X1 = 1;

    case 2
        Assumptions.U1MedZeroGivenY2X1 = 1;
        Assumptions.U1SymmetricGivenY2X1 = 1;

    case 3
        Assumptions.U1MedZeroGivenY2X1 = 1;
        Assumptions.U1SymmetricGivenY2X1 = 1;
        Assumptions.U1IndY2X1 = 1;

    case 4
        Assumptions.U1MedZeroGivenX1X2 = 1;

    case 5
        Assumptions.U1MedZeroGivenX1X2 = 1;
        Assumptions.U1IndX1X2 = 1;

    case 6
        Assumptions.U1MedZeroGivenX1X2 = 1;
        Assumptions.U1IndX1X2 = 1;
        Assumptions.U1SymmetricGivenX1X2 = 1;

    case 7
        Assumptions.U1MedZeroGivenX1X2 = 1;
        Assumptions.U1U2IndX1X2 = 1;

    case 8
        Assumptions.U1MedZeroGivenX1X2 = 1;
        Assumptions.U2MedZeroGivenX1X2 = 1;
        Assumptions.U1U2IndX1X2 = 1;
        Settings.ParametricFS = 1;

    case 9
        Assumptions.U1MedZeroGivenX1X2 = 1;
        Assumptions.U1SymmetricGivenX1X2 = 1;
        Assumptions.U2MedZeroGivenX1X2 = 1;
        Assumptions.U2SymmetricGivenX1X2 = 1;
        Assumptions.U1U2IndX1X2 = 1;
        Settings.ParametricFS = 1;

    otherwise
        error('SpecNumber not recognized.');
end

Settings.SpecNumber = SpecNumber;
IdentifiedSet(Settings, Assumptions);
