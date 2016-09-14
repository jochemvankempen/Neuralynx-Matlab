function varargout = NLX_NSE2NCS(NSEpath,NCSpath)

% converts waveforms to a continous signal

varargout = cell(1,nargout);

NSE = NLX_LoadNSE(NSEpath,'FULL',1,[]);
Header = NLX_Head2Struct(NSE.Header);

%% construct signal
SamplePeriod = 1000000/Header.SamplingFrequency;
nWaveSamples = size(NSE.SpikeWaveForm,1);
nSpikes = size(NSE.SpikeWaveForm,3);
WaveAlignIndex = [-Header.AlignmentPt+1 : nWaveSamples-Header.AlignmentPt]';
FirstSpike = min(NSE.TimeStamps);
LastSpike = max(NSE.TimeStamps);

Tstart = FirstSpike+WaveAlignIndex(1)*SamplePeriod;
Tstop = LastSpike+WaveAlignIndex(end)*SamplePeriod;
nBins = (Tstop-Tstart)/SamplePeriod;

BinIndex = round((NSE.TimeStamps-Tstart)./SamplePeriod)+1;
BinIndex = permute(BinIndex,[3 2 1]);
BinIndex = repmat(BinIndex,[nWaveSamples 1 1]) + repmat(WaveAlignIndex,[1 1 nSpikes]);

Signal = zeros(nBins,1).*NaN;
Signal(BinIndex(:)) = NSE.SpikeWaveForm(:);

varargout{1} = Signal;

%% build NCS
% NCS.Path ............ Full path of the original data file
% NCS.Header .......... Cellarray of strings [NumRows x 1], amplification
%                       parameter
% NCS.TimeStamps ....... [1 x NumSamples] microseconds (10^-6s)
% NCS.ChNr ............. [1 x NumSamples] 
% NCS.SF ............... [1 x NumSamples] Sample frequency for every
%                                         NCS.Samples column
% NCS.ValidSampleNum ... [1 x NumSamples] valid samples in every NCS.Samples column
% NCS.Samples .......... [(512) x NumSamples] 

NCS.Path = [];
NCS.Header = [];
NCS.TimeStamps = [];
NCS.ChNr = [];
NCS.SF = [];
NCS.ValidSampleNum = [];
NCS.Samples = [];

if nargin<2
    NCSpath = '';
else
    NCS.Path = NCSpath;
end

NCS.Header = NSE.Header;
ValidSampleNum = 512;
nCols = floor(nBins/ValidSampleNum)+1;
Signal(end+1:nCols*ValidSampleNum) = NaN;
NCS.Samples = reshape(Signal,[ValidSampleNum,nCols]);
nNCSSamples = size(NCS.Samples,2);
NCS.SF = ones(1,nNCSSamples).*Header.SamplingFrequency;
NCS.ChNr = ones(1,nNCSSamples);
NCS.TimeStamps = linspace(Tstart,SamplePeriod*512*nCols,nCols);
NCS.ValidSampleNum = ones(1,nCols).*ValidSampleNum;

NCS.Samples(isnan(NCS.Samples))==0;

if nargin>=2
    NCS = NLX_SaveNCS(NCS,false);
end

varargout{2} = NCS;

