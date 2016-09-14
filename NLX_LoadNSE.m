function [NSE, DelayCompensation] = NLX_LoadNSE(NSEpath,FieldOption,ExtractMode,ExtractArray)

% Loads a *.nse file into a matlab structure.
% Returns empty structure if no input.
%
% NSE = NLX_LoadNSE(NSEpath,FieldOption,ExtractMode,ExtractArray)
%
% INPUT:
% NSEpath ........ full filepath, windows gui popup if empty
% FieldOption .... 'HEADER' - Only header
%                  'TIMES' - Timestamps and Clusterinfo
%                  'WAVEFORMS' - Waveforms
%                  'FULL' - Loads the full file dataset
% ExtractMode .... 1 Extract All 
%                  2 Extract Record Index Range
%                  3 Extract Record Index List 
%                  4 Extract Timestamp Range 
%                  5 Extract Timestamp List
% ExtractArray ... Mode 1  [] 
%                  Mode 2  [1stRec-1 lastRec-1]
%                  Mode 3  [RecNr-1 ...] 
%                  Mode 4  [StartStamp EndStamp] 
%                  Mode 5  [StampVal1 StampVal2 ...]
%
% OUTPUT:
% NSE.Path ............ Full path of the original data file
% NSE.Header .......... Cellarray of strings [NumRows x 1], amplification
%                       parameter
% NSE.TimeStamps ...... [1 x NumSpikes] microseconds (10^-6s)
% NSE.ScNr ............ [1 x NumSpikes] Nr of Sc-Channel (Electrode)
% NSE.ClusterNr ....... [1 x NumSpikes] Nr of Cluster
% NSE.SpikeFeatures ... [8 x NumSpikes] Featurvalues for each spike
% NSE.SpikeWaveForm ... [32 x 1 x NumSpikes] 32 point sample of each spike

NSE.Path = '';
NSE.Header = [];
NSE.TimeStamps = [];
NSE.ScNr = [];
NSE.ClusterNr = [];
NSE.SpikeFeatures = [];
NSE.SpikeWaveForm = [];
if nargin < 1;return;end

ExtractHeader = 1;

% check input
if isempty(NSEpath)
	[filename,pathname] = uigetfile('*.nse','load Neuralynx *.NSE data file','multiselect','off');
	NSEpath = fullfile(pathname,filename);
	if ~filename;return;end
else
    if ~exist(NSEpath,'file')
        error(sprintf('%s does not exist!!',NSEpath));
    end
end
NSE.Path = NSEpath;
if nargin<2 || isempty(FieldOption);FieldOption = 'HEADER';end
if nargin<3 || isempty(ExtractMode);ExtractMode = 1;ExtractArray=[];end
if nargin<5 || isempty(EchoOff);EchoOff = 0;end

% check options
switch upper(FieldOption)
    case 'HEADER' ; FieldArray = [0 0 0 0 0];[NSE.Header] = Nlx2MatSpike(NSEpath,FieldArray,ExtractHeader,ExtractMode,ExtractArray);
    case 'TIMES' ; FieldArray = [1 0 1 0 0];[NSE.TimeStamps,NSE.ClusterNr,NSE.Header] = Nlx2MatSpike(NSEpath,FieldArray,ExtractHeader,ExtractMode,ExtractArray);
    case 'WAVEFORMS' ; FieldArray = [1 0 1 0 1];[NSE.TimeStamps,NSE.ClusterNr,NSE.SpikeWaveForm,NSE.Header] = Nlx2MatSpike(NSEpath,FieldArray,ExtractHeader,ExtractMode,ExtractArray);
    case 'FULL' ; FieldArray = [1 1 1 1 1];[NSE.TimeStamps,NSE.ScNr,NSE.ClusterNr,NSE.SpikeFeatures,NSE.SpikeWaveForm,NSE.Header] = Nlx2MatSpike(NSEpath,FieldArray,ExtractHeader,ExtractMode,ExtractArray);
    otherwise
        FieldArray = [0 0 0 0 0];[NSE.Header] = Nlx2MatSpike(NSEpath,FieldArray,ExtractHeader,1,ExtractArray);
end

NSE.TimeStamps = NSE.TimeStamps(:);
NSE.ClusterNr = NSE.ClusterNr(:);
NSE.ScNr = NSE.ScNr(:);

% DelayCompensation = false;
% switch upper(FieldOption)
%     case {'TIMES' 'WAVEFORMS' 'FULL'};
%         cNLXHeaderCells = NLX_Head2Cell(NSE.Header);
%         delayParNr     = strcmp(cNLXHeaderCells(:,1),'DspFilterDelay_µs');
%         delayCompParNr = strcmp(cNLXHeaderCells(:,1),'DspDelayCompensation');
%         if any(delayParNr) && any(delayCompParNr)
%             cFilterIsComp   = isempty(findstr(cNLXHeaderCells{delayCompParNr,2},'Disabled'));
%             if ~cFilterIsComp
%                 NSE.TimeStamps = NSE.TimeStamps - cNLXHeaderCells{delayParNr,2};
%                 DelayCompensation = true;
%             end
%         end
% end




        
    
