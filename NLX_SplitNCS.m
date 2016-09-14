function splitNCS = NLX_SplitNCS(NCS,CuttingWins,SplitOption,SaveFilePrefix)

% Splits a *.NCS file
%
% NCS ............... structure (see NLX_loadNCS.m)
% CuttingWins ....... [lower time , upper time], every row cuts a new file
% SplitOption ....... 'SINGLE' - separate new NCS files; 'MERGE' - one new NCS file
% SaveFilePrefix ... cell array of strings, prefix for save files, suffix of files is the original
%                     *.NCS file name, if empty no files will be saved

if isempty(NCS)
	disp('Load *.NCS file');
	NCS = NLX_LoadNCS([],'FULL',1,[]);
	if isempty(NCS.Path);return;end
end

[NumSamples,FieldArray] = NLX_CheckNCS(NCS);

% extract
switch SplitOption
    
    case 'SINGLE'
        for i = 1:size(CuttingWins,1);
            splitNCS(i) = NLX_extractNCS(NCS,CuttingWins(i,:));
        end
        
%     case 'MERGE'
%         for i = 1:size(CuttingWins,1);
%             Index(NLX_findEvents(NCS,'TIMEWINDOW',CuttingWins(i,:))) = 1;
%         end
%         splitNCS = NLX_ExtractNCS(NCS,Index);
        
end


% save files
if nargin<4 | isempty(SaveFilePrefix);return;end
[currNLXDir,currNLXName,currNLXExt] = fileparts(NCS.Path);
for i=1:length(splitNCS)
    splitNCS(i).Path = [SaveFilePrefix{i} '.' currNLXName currNLXExt];
	fprintf(1,['Write ' strrep(splitNCS(i).Path,'\','\\') ' ...\n']);
	NLX_SaveNCS(splitNCS(i),0);
end
fprintf(1,'Done\n');
