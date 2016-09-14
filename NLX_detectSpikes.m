function NSE = NLX_detectSpikes(NCS,NLXTime,Threshold,nWaveform,StampMode,WaveformAlign,MinISI,chanFilename)

% detect spikes from continous sampled data (*.nrd,*.ncs)
% [TS,WF] = NLX_detectSpikes(NCS,NLXTime,Threshold,StampMode,WaveformPar)
%
% NCS .............
% NLXTime .........
% Threshold ....... in units of NCS.Samples (digital)
% nWaveform ....... number of waveform samples to take
% StampMode ....... 'Peak'
%                   'Onset'
% WaveformAlign ... aligment sample nr for waveforms
% MinISI .......... retrigger in microseconds
% chanFilename .... filename of attached to the new NSE structure
%
% NSE ... structure, ready to save as *.nse file

%% initialise NSE
NSE.Path = '';
NSE.Header = [];
NSE.TimeStamps = [];
NSE.ScNr = [];
NSE.ClusterNr = [];
NSE.SpikeFeatures = [];
NSE.SpikeWaveForm = [];
% NSE.Path ............ Full path of the original data file
% NSE.Header .......... Cellarray of strings [NumRows x 1], amplification
%                       parameter
% NSE.TimeStamps ...... [1 x NumSpikes] microseconds (10^-6s)
% NSE.ScNr ............ [1 x NumSpikes] Nr of Sc-Channel (Electrode)
% NSE.ClusterNr ....... [1 x NumSpikes] Nr of Cluster
% NSE.SpikeFeatures ... [8 x NumSpikes] Featurvalues for each spike
% NSE.SpikeWaveForm ... [32 x 1 x NumSpikes] 32 point sample of each spike

cSF = unique(NCS.SF);

if nargin<9
    detectionOffset = [-inf inf];
end

%%
if all(size(NCS.Samples)>1)
    [NCS,cAnalogData,cTimeBins] = NLX_ExtractNCS(NCS,NLXTime);
    cAnalogData = cAnalogData(:)';
    cTimeBins = cTimeBins(:)';
else
    cAnalogData = NCS.Samples(:)';
    cTimeBins = NCS.TimeStamps(:)';
end

if all(Threshold<0)
    cAnalogData = cAnalogData.*(-1);
    Threshold = Threshold.*(-1);
end
if nargin<4 || isempty(StampMode)
    StampMode = 'Peak';
end
    
[TrDummy,nBins] = size(cAnalogData);

%% detect
% get threshold crossing
if length(Threshold)>1
    % window discriminator
    isThresh = cAnalogData>=Threshold(1) & cAnalogData<=Threshold(2);
else
    isThresh = cAnalogData>Threshold & cTimeBins>=detectionOffset(1);
end


% detect peaks
isPeak = false(TrDummy,nBins);
isPeak(:,2:end-1) = diff(cAnalogData(:,1:end-1),1,2)>0 & diff(cAnalogData(:,2:end),1,2)<0;

isSpike = isThresh & isPeak;

nSpikes = sum(isSpike);

% retrigger
RetriggerSampleNum = floor(MinISI / (1e6/cSF));
for i=1:nSpikes
    if isSpike(i) && i>RetriggerSampleNum && any(isSpike(i-RetriggerSampleNum:i-1))
        isSpike(i) = false;
    end
end
nSpikes = sum(isSpike);

%% extract waveforms
WaveformIndex = repmat(find(isSpike(:)) - (WaveformAlign-1),[1 nWaveform]) + repmat([0:nWaveform-1],[nSpikes 1]);
WaveformIndex(WaveformIndex<1) = 1;
WaveformIndex(WaveformIndex>nBins) = nBins;
NSE.SpikeWaveForm = permute(cAnalogData(WaveformIndex),[2 3 1]);
NSE.TimeStamps = cTimeBins(isSpike);
NSE.TimeStamps = NSE.TimeStamps(:);

% path
NSE.Path = NCS.Path;
NSE = NLX_setPath(NSE,[],chanFilename,'.nse');

NSE.ScNr = ones(nSpikes,1).*unique(NCS.ChNr);
NSE.ClusterNr = zeros(nSpikes,1);
NSE.SpikeFeatures = zeros(8,nSpikes);

%% Header
Header = NLX_Head2Struct(NCS);
%     '######## Neuralynx Data File Header '
%     '## File Name C:\CheetahData\2013-04-26_14-15-40\SE1.nse '
%     '## Time Opened (m/d/y): 4/26/2013  At Time: 14:15:49.546 '
%     '## Time Closed (m/d/y): 4/26/2013  At Time: 16:47:39.875 '
%     '-CheetahRev 5.3.1 '
%     ''
%     '-AcqEntName SE1 '
%     '-FileType: Spike '
%     '-RecordSize 112 '
%     ''
%     '-HardwareSubSystemName AcqSystem1 '
%     '-HardwareSubSystemType DigitalLynx '
%     '-SamplingFrequency 32556.000000 '
%     '-ADMaxValue 32767 '
%     '-ADBitVolts 0.0000000031'
%     ''
%     '-NumADChannels 1 '
%     '-ADChannel 0'
%     '-InputRange 100'
%     '-InputInverted True '
%     '-DspLowCutFrequency 600.000000 '
%     '-DspLowCutNumTaps 64 '
%     '-DspLowCutFilterType FIR '
%     ''
%     '-DspHighCutFrequency 9000.000000 '
%     '-DspHighCutNumTaps 32 '
%     '-DspHighCutFilterType FIR '
%     ''
%     '-WaveformLength 32'
%     '-AlignmentPt 8'
%     '-ThreshVal 25 '
%     '-MinRetriggerSamples 25 '
%     '-SpikeRetriggerTime 750 '
%     '-DualThresholding False '
%     ''
%     '-Feature Peak 0 0 '
%     '-Feature Valley 1 0 '
%     '-Feature Energy 2 0 '
%     '-Feature Height 3 0 '
%     '-Feature NthSample 4 0 4 '
%     '-Feature NthSample 5 0 16 '
%     '-Feature NthSample 6 0 24 '
%     '-Feature NthSample 7 0 28 '
%     ''
NSE.Header = [];        
newHeader.hash = Header.hash;
newHeader.CheetahRev = Header.CheetahRev;

newHeader.AcqEntName = Header.HardwareSubSystemName;
newHeader.FileType = 'Spike';

newHeader.SamplingFrequency  = Header.SamplingFrequency;
        
NSE = NLX_Struct2Head(NSE,newHeader);


