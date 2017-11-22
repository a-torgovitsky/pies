%*******************************************************************************
% MultiBatchRun.m
%
% Run all batches in BatchList, each one on a separate instance of Matlab.
% Save them all in the same directory "SaveDir" which is required in
% this routine.
%*******************************************************************************
function [] = MultiBatchRun(BatchList, SaveDir)

    errstr = 'Need to pass nonempty SaveDir for this routine.';
    if ~exist('SaveDir', 'var')
        error(errstr);
    else
        if isempty(SaveDir)
            error(errstr);
        end
    end


    sbase = ['!matlab -nodesktop -nosplash -singleCompThread'...
         ' -r "BatchRun(%d, ''%s'')" &'];

    for b = 1:1:length(BatchList)
        s = sprintf(sbase, BatchList(b), SaveDir)
        eval(s)
        pause(10);
    end
end
