%*******************************************************************************
% InitializeAMPL.m
%
% Start an AMPL instance and create a destructor that will automatically kill
% the instance when it is cleared.
%*******************************************************************************
function [ampl, CleanUpAMPL] = InitializeAMPL(ModelFiles)
    ampl = AMPL;

    CleanUpAMPL = onCleanup(@()ampl.close());

    for m = 1:1:length(ModelFiles)
        if ~exist(ModelFiles{m}, 'file')
            error('Model file %d could not be found.', m);
        else
            % The exist looks through the path--but need to translate for AMPL
            fn = which(ModelFiles{m});
            ampl.read(fn);
        end
    end
end
