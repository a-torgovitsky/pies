%*******************************************************************************
% PrintStructure.m
%
% Recurse through a structure and print its contents to fid
%*******************************************************************************
function PrintStructure(s, fid)

    fields = repmat(fieldnames(s), numel(s), 1);
    values = struct2cell(s);

    for i = 1:1:length(fields)
        if isstruct(s.(fields{i}))
            fprintf(fid, '-----------------\n');
            fprintf(fid, '%s\n', fields{i});
            fprintf(fid, '-----------------\n');
            PrintStructure(s.(fields{i}), fid); % Recursion -- so clever :)
        else
            if isnumeric(values{i})
                values{i} = num2str(values{i}(:)', '%4.3f');
            end
            if isa(values{i}, 'function_handle')
                values{i} = func2str(values{i});
            end
            stringout = [fields{i} ': '];
            if iscell(values{i})
                stringout = [stringout strjoin(values{i})];
            else
                stringout = [stringout values{i}];
            end

            fprintf(fid, '%s\n', stringout);
        end
    end
    fprintf(fid, '-----------------\n');
end
