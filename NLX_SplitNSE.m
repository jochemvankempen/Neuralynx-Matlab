function NSE = NLX_SplitNSE(NSEPath,CuttingWins,SplitOption,SaveFilePrefix,SaveFileSuffix)

% Splits a *.NSE file
%
% NSEPath ............... structure (see NLX_loadNSE.m)
% CuttingWins ....... [lower time , upper time], every row cuts a new file
% SplitOption ....... 'SINGLE' - separate new nse files; 'MERGE' - one new nse file
% SaveFilePrefix ... cell array of strings, prefix for save files, suffix of files is the original
%                     *.nse file name, if empty no files will be saved

if nargin<4 || isempty(SaveFilePrefix), MakePrefix = true;else MakePrefix = false;end
if nargin<5 || isempty(SaveFileSuffix), MakeSuffix = true;else MakeSuffix = false;end

nCW = size(CuttingWins,1);
fprintf(1,['Cut ' sprintf('%1.0f',nCW) ' time windows ...\n']);
% extract
switch SplitOption
    
    case 'SINGLE'
        for i = 1:nCW;
            [currNLXDir,currNLXName,currNLXExt] = fileparts(NSEPath);
            NSE = NLX_LoadNSE(NSEPath,'full',4,[CuttingWins(i,:)]);
            if MakePrefix
                SaveFilePrefix{i} = '';
            end
            if MakeSuffix
                SaveFileSuffix{i} = sprintf('.%1.0f-%1.0f',CuttingWins(i,1),CuttingWins(i,2));
            end
            NSE.Path = fullfile(currNLXDir,sprintf('%s%s%s%s',SaveFilePrefix{i},currNLXName,SaveFileSuffix{i},currNLXExt));
            fprintf(1,['Write ' strrep(NSE.Path,'\','\\') ' ...\n']);
            NLX_SaveNSE(NSE,0);
        end
        
    case 'MERGE'
        error('Not implemented in the moment!');
%         for i = 1:size(CuttingWins,1);
%             Index(NLX_findSpikes(NSE,'TIME',CuttingWins(i,:))) = 1;
%         end
%         splitNSE = NLX_ExtractNSE(NSE,Index);
        
end