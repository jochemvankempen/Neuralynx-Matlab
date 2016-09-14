function NRD = NLX_SplitNRD(NRDPath,ChannelNumber,CuttingWins,savePath,SaveFilePrefix,SaveFileSuffix)

% Splits a *.NSE file
%
% NSEPath ............... structure (see NLX_loadNSE.m)
% CuttingWins ....... [lower time , upper time], every row cuts a new file

if nargin<5 || isempty(SaveFilePrefix), MakePrefix = true;else MakePrefix = false;end
if nargin<6 || isempty(SaveFileSuffix), MakeSuffix = true;else MakeSuffix = false;end
SplitOption = 'SINGLE';

[currNLXDir,currNLXName,currNLXExt] = fileparts(NRDPath);
nCh = length(ChannelNumber);

nCW = size(CuttingWins,1);
fprintf(1,['Cut ' sprintf('%1.0f',nCW) ' time windows ...\n']);
% extract
switch SplitOption
    
    case 'SINGLE'
        for i = 1:nCW;
            for iCh = 1:nCh
                NRD = NLX_LoadNRD(NRDPath,ChannelNumber(iCh),'FULL',4,[CuttingWins(i,:)]);
                if MakePrefix
                    SaveFilePrefix{i} = '';
                end
                if MakeSuffix
                    SaveFileSuffix{i} = sprintf('.%1.0f-%1.0f',CuttingWins(i,1),CuttingWins(i,2));
                end
                NRD.Path = fullfile(savePath,sprintf('%s%s.AD%1.0f%s%s',SaveFilePrefix{i},currNLXName,ChannelNumber(iCh),SaveFileSuffix{i},currNLXExt));
                fprintf(1,['Write ' strrep(NRD.Path,'\','\\') ' ...\n']);
                NRD = NLX_SaveNRD(NRD,0,0);
            end
        end
        
    case 'MERGE'
        error('Not implemented in the moment!');
%         for i = 1:size(CuttingWins,1);
%             Index(NLX_findSpikes(NSE,'TIME',CuttingWins(i,:))) = 1;
%         end
%         splitNSE = NLX_ExtractNSE(NSE,Index);
        
end