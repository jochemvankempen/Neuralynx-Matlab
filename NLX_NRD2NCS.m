function [NCS,NewSF] = NLX_NRD2NCS(NRD,ChannelLabel,NewSF)

% convert Raw-Dat format *.nrd to continous sampled format *.ncs
% [NCS] = NLX_NRD2NCS(NRD,ChannelLabel,NewSF)
 
Header = NLX_Head2Struct(NRD);
n = length(NRD.Samples);
NCSSampleSize = 512;

%% Down-Sampling
if ~isempty(NewSF) && Header.SamplingFrequency>NewSF
    NewIncr = floor(Header.SamplingFrequency/NewSF);
    NRD.TimeStamps = NRD.TimeStamps(1:NewIncr:n,1);
    NRD.Samples = NRD.Samples(1:NewIncr:n,1);
    NewSF = Header.SamplingFrequency/NewIncr;
    n = length(NRD.Samples);
else
    NewSF = Header.SamplingFrequency;
end

%%
NumCompleteNCS = floor(n/NCSSampleSize);
SizeInCompleteNCS = rem(n,NCSSampleSize);
if SizeInCompleteNCS>0
    LastNCSSample = zeros(NCSSampleSize,1);
    LastNCSSample(1:SizeInCompleteNCS,1) = NRD.Samples(NumCompleteNCS*NCSSampleSize+1:end,1);
end

%% set structure

% header
NCS.Header = {};
newHeader.hash = Header.hash;
newHeader.CheetahRev = Header.CheetahRev;

newHeader.AcqEntName = Header.HardwareSubSystemName;
newHeader.RecordSize = 1044;
newHeader.FileType = 'CSC';

newHeader.HardwareSubSystemName = Header.HardwareSubSystemName;
newHeader.HardwareSubSystemType = Header.HardwareSubSystemType;
newHeader.SamplingFrequency  = Header.SamplingFrequency;
newHeader.ADMaxValue = Header.MaxADValue;
newHeader.ADBitVolts = 0.0000004578;

%     '######## Neuralynx Data File Header '
%     '## File Name C:\CheetahData\2013-04-25_14-47-53\LFP1.ncs '
%     '## Time Opened (m/d/y): 4/25/2013  At Time: 14:48:2.359 '
%     '## Time Closed (m/d/y): 4/25/2013  At Time: 17:36:20.546 '
%     '-CheetahRev 5.3.1 '
%     ''
%     '-AcqEntName LFP1 '
%     '-FileType: CSC '
%     '-RecordSize 1044 '
%     ''
%     '-HardwareSubSystemName AcqSystem1 '
%     '-HardwareSubSystemType DigitalLynx '
%     '-SamplingFrequency 1017.375000 '
%     '-ADMaxValue 32767 '
%     '-ADBitVolts 0.0000004578'
%     ''
%     '-NumADChannels 1 '
%     '-ADChannel 0'
%     '-InputRange 15000'
%     '-InputInverted True '
%     '-DspLowCutFrequency 1.000000 '
%     '-DspLowCutNumTaps 0 '
%     '-DspLowCutFilterType DCO '
%     ''
%     '-DspHighCutFrequency 300.000000 '
%     '-DspHighCutNumTaps 256 '
%     '-DspHighCutFilterType FIR '
%     ''
NCS = NLX_Struct2Head(NCS,newHeader);

% path
[cDir,cName,cExt] = fileparts(NRD.Path);
NCS.Path = fullfile(cDir,sprintf('%s.ncs',ChannelLabel));

% timestamps
NCS.TimeStamps = NRD.TimeStamps(1:NCSSampleSize:NumCompleteNCS*NCSSampleSize)';
if SizeInCompleteNCS>0
    NCS.TimeStamps(NumCompleteNCS+1) = NRD.TimeStamps(NumCompleteNCS*NCSSampleSize+1,1);
end

% channel nr
NCS.ChNr = ones(1,NumCompleteNCS+1).*NRD.ChNr;

% sample frequency
NCS.SF = repmat(NewSF,[1,NumCompleteNCS+1]);

% valid sample number
NCS.ValidSampleNum = ones(1,NumCompleteNCS+1);
NCS.ValidSampleNum(1:NumCompleteNCS) = NCSSampleSize;
NCS.ValidSampleNum(NumCompleteNCS+1) = SizeInCompleteNCS;

% samples
NCS.Samples = reshape(NRD.Samples(1:NumCompleteNCS*NCSSampleSize,1),NCSSampleSize,NumCompleteNCS);
if SizeInCompleteNCS>0
    NCS.Samples(:,NumCompleteNCS+1) = LastNCSSample;
end
