%*******************************************************************************
% BatchRun.m
%
% Run all of the simulations corresponding to a given batch number, as
% defined in this script.
% This is used to simplify the process of running all specifications that
% are reported in the paper.
%*******************************************************************************

function [] = BatchRun(BatchNumber, SaveDir)

if ~exist('SaveDir', 'var')
    SaveDir = [];
end

%*******************************************************************************
% Define batches
%*******************************************************************************
NList = [3 3; 3 5; 5 3; 5 5; 7 3];
for b = 1:1:3
    Batch{b} = [b*ones(size(NList, 1), 1), NList, zeros(size(NList, 1), 1)];
end

NList = [3 3; 3 5; 5 3; 5 5];
for b = 4:1:7
    Batch{b} = [b*ones(size(NList, 1), 1), NList, zeros(size(NList, 1), 1)];
end

NList1 = [3 3; 5 5];
NList2 = [3 5; 5 3];
Batch{8} = [8*ones(size(NList1, 1), 1), NList1, zeros(size(NList1, 1), 1)];
Batch{9} = [8*ones(size(NList2, 1), 1), NList2, zeros(size(NList2, 1), 1)];

Batch{10} = [9*ones(size(NList1, 1), 1), NList1, zeros(size(NList1, 1), 1)];
Batch{11} = [9*ones(size(NList2, 1), 1), NList2, zeros(size(NList2, 1), 1)];

S = 5;
NList  = [3 4; 3 9; 3 14];
Batch{12} = [S*ones(size(NList, 1), 1), NList, ones(size(NList, 1), 1)];

NList = [3 19];
Batch{13} = [S*ones(size(NList, 1), 1), NList, ones(size(NList, 1), 1)];

NList = [3 24];
Batch{14} = [S*ones(size(NList, 1), 1), NList, ones(size(NList, 1), 1)];

assert(BatchNumber <= length(Batch));

for s = 1:1:size(Batch{BatchNumber}, 1)
    SaveDir = Run(  Batch{BatchNumber}(s,1),...
                    Batch{BatchNumber}(s,2),...
                    Batch{BatchNumber}(s,3),...
                    Batch{BatchNumber}(s,4),...
                    SaveDir);
end

end
