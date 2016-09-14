function NLX_appendNSEFiles(MergePath,NSEpaths,ReLabelFlag)

% Merge two *.nse files. Relabels cluster in case double labeling 
% Retain header and path information of first file. 
% MergePath ......... 
% NSEpaths ......... 
% ReLabelFlag .. 1 - creates new cluster labels.
%                0 - keeps cluster labels
%               -1 - resets (all=0) cluster labels

[fDir,fName,fExt] = fileparts(MergePath);
if isempty(NSEpaths)
    [NSEnames,NSEdir] = uigetfile(fullfile(fDir,'*.nse'), 'select Neuralynx SE files', 'MultiSelect', 'on');
    if isnumeric(NSEnames) && NSEnames==0;
        return;
    end
    NSEpaths = {};
    for i=1:length(NSEnames)
        NSEpaths{i,1} = fullfile(NSEdir,NSEnames{i});
    end
end
    
n = length(NSEpaths);
LastClNr = 0;
    
for i=1:n
    NSE = NLX_LoadNSE(NSEpaths{i},'FULL',1,[]);
    NSE.Path = MergePath;
    
    if ReLabelFlag
        NonZeroI = [NSE.ClusterNr~=0];
        NSE.ClusterNr(NonZeroI) = NSE.ClusterNr(NonZeroI)+LastClNr;
        LastClNr = max(NSE.ClusterNr);
    end
    
    if i==1;
        fprintf(1,['Save ' strrep(MergePath,'\','\\') '\n']);
        fprintf(1,['Append ' strrep(NSEpaths{i},'\','\\') '\n']);
        NLX_SaveNSE(NSE,0);
    elseif i>1
        fprintf(1,['Append ' strrep(NSEpaths{i},'\','\\') '\n']);
        NLX_SaveNSE(NSE,1);
    end
end
