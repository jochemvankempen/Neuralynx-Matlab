function [MUAe] = NLX_NCS2MUAe(NCS, settings)
%
% Computes MUAe from NCS data, with optional downsampling.
% MUAe data is saved in the original NCS data structure. Downsampling is
% applied over 
%
% Note: it computes MUAe in segments, so this script is most useful for
% entire datasets, not e.g. single trials. Data is filtered in segments,
% but the ends of the segments are chopped off to account for filter
% artifacts. This is applied over all segments, except for the beginning
% and end of the first and last segment, respectively. 
%
% 
% INPUT:
% NCS data structure
% settings, optional. Structure with fields:
%   - segmentSize
%   - segmentOverlap
%   - maxSegmentNum
%   - downsample
%   - downsample_SF
%
% OUTPUT
% MUAe data, in NCS data structure
%
%
% Jochem van Kempen, 02-03-2018

%%% MUAe computation settings
defaultsettings.segmentSize     = 1200000;% 
defaultsettings.segmentOverlap  = 10000;% to account for filter artifacts
defaultsettings.maxSegmentNum   = Inf;%

%%% downsample?
defaultsettings.downsample     = true;
defaultsettings.downsample_SF  = 16; % mod(512,settings.downsample_SF) = 0;

if nargin < 2
    settings = defaultsettings;
end

%%% filtersettings
filtSet.order = 3;
filtSet.cutoff = 200;

%%% get info
SampFreq = unique(NCS.SF);
[nsamples, ntimestamp] = size(NCS.Samples);
nsamples_orig = nsamples;

%%% check if selected downsample freq is appropriate, i.e. if nsamples can
%%% be devided by downsample freq. If so, we can keep using the original
%%% timestamps
if mod(nsamples, settings.downsample_SF) ~= 0
    warning('pick an appropriate downsample freq')
    keyboard
end

%%% MUAe is computed in segments for computational purposes.
overlap     = ceil(settings.segmentOverlap / nsamples);
segmentsize = ceil(settings.segmentSize / nsamples);
nSegments   = ceil(ntimestamp / ceil( (settings.segmentSize - settings.segmentOverlap) / nsamples));

%%% change sample numbers and SF if downsampling
if settings.downsample
    disp(['computing MUAe for ' NCS.Path '. Downsample from ' num2str(SampFreq) ' to ' num2str(round(SampFreq/settings.downsample_SF)) ' Hz']);
    nsamples = nsamples/settings.downsample_SF;
    SampFreq = SampFreq/settings.downsample_SF;
else
    disp(['computing MUAe for ' NCS.Path '. No downsampling, using original SF, ' num2str(SampFreq) ' Hz']);    
end

%%% set filter
[b,a] = butter(filtSet.order,[filtSet.cutoff]/(SampFreq/2),'low');

tStart = tic;
for iSeg = 1:nSegments
    currRecIndex   = ([1:segmentsize] + segmentsize .* (iSeg-1)) - overlap .* (iSeg-1) ;
    currRecIndex   = currRecIndex(currRecIndex<=ntimestamp);

    Samples = NCS.Samples(:,currRecIndex);
    Samples = Samples(:);
    
    %%% downsample
    if settings.downsample
        Samples = Samples(1:settings.downsample_SF:end);
    end
    
    %%% compute MUAe
    tmp = abs(Samples);
    tmp_MUAe = filtfilt(b,a,tmp);
    
    %%% remove overlap window
    currSaveIndex1 = currRecIndex;
    currSaveIndex2 = currRecIndex;
    if iSeg>1
        currSaveIndex1(1:ceil(overlap/2)) = [];
        currSaveIndex2 = 1:length(currRecIndex);
        currSaveIndex2 = currSaveIndex2(ceil(overlap/2)+1 : end);
    else
        % intialise new samples field
        MUAe.Samples = zeros(nsamples, length(NCS.TimeStamps));
    end
    
    tmp_MUAe = reshape(tmp_MUAe, [nsamples, length(Samples)/nsamples]);
    
    %%% save in NCS data structure
    MUAe.Samples(:,currSaveIndex1) = tmp_MUAe(:,currSaveIndex2);

%     disp(['segment ' num2str(iSeg) ', idx: ' num2str(currSaveIndex1(1)) ' - ' num2str(currSaveIndex1(end))])

end

% output as NCS data structure
MUAe.Path           = NCS.Path;
MUAe.Header         = NCS.Header;
MUAe.TimeStamps     = NCS.TimeStamps;
MUAe.ChNr           = NCS.ChNr;
MUAe.SF             = zeros(size(NCS.ChNr)) + SampFreq;
MUAe.ValidSampleNum = (NCS.ValidSampleNum == nsamples_orig) * nsamples;

tStop = toc(tStart);
fprintf(1,'Duration: %1.0fm %1.0fs \n',floor(tStop/60),rem(tStop,60));

