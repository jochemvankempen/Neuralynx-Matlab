function Header = NLX_Head2Struct(NLXHeader)

% converts the header cell array to a structure
% NLXHeader can be a structure with the field x.Header or a cell array with
% thr rows of the header in vertical cells

Header = struct;

if isstruct(NLXHeader)
    NLXHeader = NLXHeader.Header;
end

NumRows = length(NLXHeader);
for i = 1:NumRows
    if isempty(NLXHeader{i})
        continue;
    elseif strcmp(NLXHeader{i}(1),'#')
        Header.hash{i,1} = NLXHeader{i};
    elseif ~isempty(strfind(NLXHeader{i},'-'))
        k = strfind(NLXHeader{i},'-');
        [ValName,remainder] = strtok(NLXHeader{i}(k+1:end));
        try
            if isempty(str2num(remainder))
                Header = setfield(Header,ValName,strrep(remainder,' ',''));
            else
                Header = setfield(Header,ValName,str2num(remainder));
            end
        catch
            ValName = sprintf('unknown%u',i);
            if isempty(str2num(remainder))
                Header = setfield(Header,ValName,strrep(remainder,' ',''));
            else
                Header = setfield(Header,ValName,str2num(remainder));
            end
        end
    else
        continue;
    end
end