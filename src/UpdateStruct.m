%*******************************************************************************
% UpdateStruct.m
%
% Struct is a default structure to be updated (usually default settings)
% StructIn is the new structure (usually user-inputted settings)
%
% Different behavior depending on the flags EnforceSubset and KeepUnknown:
%
% E=0, K=0:
% Don't throw an error if StructIn has fields that Struct does
% not, but don't keep any of these unrecognized fields.
%
% E=0, K=1:
% Don't throw an error if StructIn has fields that Struct does
% not, and add any of the unknown fields to Struct
%
% E=1
% Throw an error if StructIn has fields that Struct does not
%*******************************************************************************
function Struct = ...
    UpdateStruct(Struct, StructIn, EnforceSubset, KeepUnknown)
%*******************************************************************************
    if ~isstruct(StructIn)
        error('Expected structure for input. Quitting.');
    end

    StructNamesDefault = fieldnames(Struct);
    StructNamesIn = fieldnames(StructIn);

    for i = 1:1:length(StructNamesIn)
        CurOption = StructNamesIn{i};

        % Overwrite default with input
        if any(strcmp(CurOption, StructNamesDefault))
            Struct.(CurOption) = StructIn.(CurOption);
        else
            if EnforceSubset
                error([ '%s is not a recognized field '...
                        'of the structure to be updated.'], CurOption);
            elseif KeepUnknown
                Struct.(CurOption) = StructIn.(CurOption);
            end
        end
    end
end
