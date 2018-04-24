function [MUAe] = NLX_NCS2MUAe(NCS, settings, saveMUAe, target_path)
%
% Computes MUAe from NCS data, with optional downsampling.
% MUAe data is saved in the original NCS data structure. Downsampling is
% applied within a column, this way we can keep using the original
% timestamps.
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
% saveMUAe: logical, default = false. Whether or not to save MUAe data structure.
% target_path: optional, directory where to save MUAe data. Default is
% NCS.Path directory
%
% OUTPUT
% MUAe data, in NCS data structure
%
%
% Jochem van Kempen, 02-03-2018

tStart = tic;

%%% MUAe computation settings
defaultsettings.segmentSize     = 1200000;%
defaultsettings.segmentOverlap  = 10000;% to account for filter artifacts
defaultsettings.maxSegmentNum   = Inf;%

%%% downsample?
% downsampling is applied after MUAe is calculated, so it won't affect the
% accuracy of the computation, just saves space
defaultsettings.downsample     = true;
defaultsettings.downsample_SF  = 32; % mod(512,settings.downsample_SF) = 0;

[PATHSTR,NAME,EXT] = fileparts(NCS.Path);

if isempty(target_path) || nargin < 4
    MUAeName = getMUAeName(NAME);
    target_path = [PATHSTR filesep MUAeName EXT];
end

if isempty(saveMUAe) || nargin < 3
    saveMUAe = false;
end

if isempty(settings) || nargin < 2
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

for iSeg = 1:nSegments
    currRecIndex   = ([1:segmentsize] + segmentsize .* (iSeg-1)) - overlap .* (iSeg-1) ;
    currRecIndex   = currRecIndex(currRecIndex<=ntimestamp);
    
    Samples = NCS.Samples(:,currRecIndex);
    Samples = Samples(:);
        
    %%% compute MUAe
    tmp = abs(Samples); % rectify
    tmp_MUAe = filtfilt(b,a,tmp); % filter
    
    if settings.downsample
        tmp_MUAe = tmp_MUAe(1:settings.downsample_SF:end);
    end
    
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
    
    tmp_MUAe = reshape(tmp_MUAe, [nsamples, length(tmp_MUAe)/nsamples]);
    
    %%% save in NCS data structure
    MUAe.Samples(:,currSaveIndex1) = tmp_MUAe(:,currSaveIndex2);
    
    %     disp(['segment ' num2str(iSeg) ', idx: ' num2str(currSaveIndex1(1)) ' - ' num2str(currSaveIndex1(end))])
    
end

if strfind(NCS.Header{14}, '-SamplingFrequency ')
    NCS.Header{14} = ['-SamplingFrequency ' num2str(SampFreq)];
end

% output as NCS data structure
MUAe.Path           = NCS.Path;
MUAe.Header         = NCS.Header;
MUAe.TimeStamps     = NCS.TimeStamps;
MUAe.ChNr           = NCS.ChNr;
MUAe.SF             = zeros(size(NCS.ChNr)) + SampFreq;
MUAe.ValidSampleNum = (NCS.ValidSampleNum == nsamples_orig) * nsamples;

if saveMUAe
    MUAe.Path = [target_path];
    disp(['saving ' MUAe.Path])
    if defaultsettings.downsample
        %         warning('cannot save file structure in NCS format if downsampling is applied')
        [PATHSTR,NAME,EXT] = fileparts(MUAe.Path);
        save([PATHSTR filesep NAME '.mat'], 'MUAe','filtSet','settings');
        
        
        %%% the below doesn't work anymore. The newer version of Mat2NlxCSC
        %%% does not allow the number of samples in a column to be < 512
%         AppendFile = 0;
%         extractMode = 1;
%         NumRecs = length(MUAe.TimeStamps);
%         TimeStamps = MUAe.TimeStamps;
%         FieldSelection = [1 1 1 1 1];
%         ChannelNumber = NCS.ChNr;
%         SampleFrequencies = MUAe.SF;
%         NumberValidSamples = MUAe.ValidSampleNum;
%         Samples = MUAe.Samples;
%         NlxHeader = NCS.Header;
%         
%         Mat2NlxCSC( MUAe.Path, AppendFile, extractMode, [], [FieldSelection 1], TimeStamps, ChannelNumber, SampleFrequencies, NumberValidSamples, Samples, NlxHeader );

    else
        NLX_SaveNCS(MUAe)
    end
end

tStop = toc(tStart);
fprintf(1,'Duration: %1.0fm %1.0fs \n',floor(tStop/60),rem(tStop,60));
end

function MUAeName = getMUAeName(NAME)
MUAeName = regexprep(NAME,'CSC','MUAe');
end

