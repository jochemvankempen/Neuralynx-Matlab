function splitNEV = NLX_SplitNEV(NEV,CuttingWins,SplitOption,SaveFilePrefix)

% Splits a *.NEV file
%
% NEV ............... structure (see NLX_loadNEV.m)
% CuttingWins ....... [lower time , upper time], every row cuts a new file
% SplitOption ....... 'SINGLE' - separate new NEV files; 'MERGE' - one new NEV file
% SaveFilePrefix ... cell array of strings, prefix for save files, suffix of files is the original
%                     *.NEV file name, if empty no files will be saved

if isempty(NEV)
	disp('Load *.NEV file');
	NEV = NLX_LoadNEV([],'FULL',1,[]);
	if isempty(NEV.Path);return;end
end

[NumEvents,FieldArray] = NLX_CheckNEV(NEV);
Index = logical(zeros(1,NumEvents));

% extract
switch SplitOption
    
    case 'SINGLE'
        for i = 1:size(CuttingWins,1);
            [ts,ix] = NLX_findEvents(NEV,'TIMEWINDOW',CuttingWins(i,:));
            splitNEV(i) = NLX_ExtractNEV(NEV,ix);
        end
        
%     case 'MERGE'
%         for i = 1:size(CuttingWins,1);
%             Index(NLX_findEvents(NEV,'TIMEWINDOW',CuttingWins(i,:))) = 1;
%         end
%         splitNEV = NLX_ExtractNEV(NEV,Index);
        
end


% save files
if nargin<4 | isempty(SaveFilePrefix);return;end
[currNLXDir,currNLXName,currNLXExt] = fileparts(NEV.Path);
for i=1:length(splitNEV)
    splitNEV(i).Path = [SaveFilePrefix{i} '.' currNLXName currNLXExt];
	fprintf(1,['Write ' strrep(splitNEV(i).Path,'\','\\') ' ...\n']);
	NLX_SaveNEV(splitNEV(i),0);
end
fprintf(1,'Done\n');
