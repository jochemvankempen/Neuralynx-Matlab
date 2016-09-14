function x = NLX_setPath(x,newFolder,newFileName,newExt)

% set the path field of structure

[cDir,cName,cExt] = fileparts(x.Path);

if isempty(newFolder);newFolder = cDir;end

if nargin<4
    if isempty(newFileName)
        newFileName = sprintf('%s%s',cName,cExt);
    end
elseif nargin>=4
    if isempty(newFileName) && isempty(newExt)
         newFileName = sprintf('%s%s',cName,cExt);
    elseif ~isempty(newFileName) && isempty(newExt)
        newFileName = sprintf('%s%s',newFileName,cExt);
    elseif isempty(newFileName) && ~isempty(newExt)
        newFileName = sprintf('%s%s',cName,newExt);
    else
        newFileName = sprintf('%s%s',newFileName,newExt);
    end
end    
    
x.Path = fullfile(newFolder,newFileName);
