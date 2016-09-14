function ok = NLX_SpikeExtractor(ncsPaths,nsePaths,settings)

% wrapper/batch for NLX_detectSpikes.m
% loads files in segment to reduce load on working memory
% 
% ok = NLX_SpikeExtractor(ncsSavePath,nseSavePath,settings)
%
%

nFiles = length(ncsPaths);
ok = false;

%% check settings
defaults.segmentSize    = 30000;% 30000 max recommended
defaults.maxSegmentNum  = inf;
defaults.timeWin        = [];
defaults.Threshold      = 16; % in µV
defaults.nWaveform      = 32;
defaults.StampMode      = 'Peak';
defaults.WaveformAlign  = 8;
defaults.MinISI         = 500;% in µs
defaults.chanFilename   = '';
settings = StructUpdate(defaults,settings);

%% loop file stack
fprintf(1,'\n');
waitBarSpaceNum = WaitbarAtPrompt('extracting spikes from NCS','',20);
waitBarLength = 0;
for iFile = 1:nFiles
    
    % explore current NCS file
    waitBarSpaceNum = WaitbarAtPrompt(waitBarLength,waitBarSpaceNum,sprintf('File#%u(%u): check NCS data ...',iFile,nFiles));
    NCS        = NLX_LoadNCS(ncsPaths{iFile},'NOSAMPLES',1,[]);
    nRecsTotal = length(NCS.TimeStamps);
    Fs         = unique(NCS.SF);
    for iFs = 1:length(Fs)
        nFs(iFs) = sum(NCS.SF==Fs(iFs));
    end
    ncsHeader          = NLX_Head2Struct(NCS.Header);
    currThreshold = round(settings.Threshold * 0.000001 / ncsHeader.ADBitVolts);
    
    % loop segments
    nSegments      = min([settings.maxSegmentNum ceil(nRecsTotal/settings.segmentSize)]);
    for iSeg = 1:nSegments
        waitBarLength = ((iFile-1)*nSegments+iSeg)/(nSegments*nFiles);
        currRecIndex   = [1:settings.segmentSize] + settings.segmentSize .* (iSeg-1);
        currRecIndex   = currRecIndex(currRecIndex<=nRecsTotal);
        
        % load segment
        waitBarSpaceNum = WaitbarAtPrompt(waitBarLength,waitBarSpaceNum,sprintf('File#%u(%u): loading segment#%u(%u)',iFile,nFiles,iSeg,nSegments));
        NCS = NLX_LoadNCS(ncsPaths{iFile},'FULL',3,currRecIndex);

        % extract spike timestamps and/or waveforms
        waitBarSpaceNum = WaitbarAtPrompt(waitBarLength,waitBarSpaceNum,sprintf('File#%u(%u) segment#%u(%u): detecting spikes',iFile,nFiles,iSeg,nSegments));
        if iSeg>1 && ~isempty(NSE.TimeStamps)
            timeWin = [NSE.TimeStamps(end)+settings.MinISI inf];% retrigger time here
        else
            timeWin = [];
        end
        NSE = NLX_detectSpikes(NCS,timeWin,currThreshold,settings.nWaveform,settings.StampMode,settings.WaveformAlign,settings.MinISI,'');
        nSpikesDetected = length(NSE.TimeStamps);
        if nSpikesDetected==0
            WaitbarAtPrompt([]);
            error('no spikes detected');
        end

        % save spike segments
        waitBarSpaceNum = WaitbarAtPrompt(waitBarLength,waitBarSpaceNum,sprintf('File#%u(%u) segment#%u(%u): writing %u spikes to *.nse ...',iFile,nFiles,iSeg,nSegments,nSpikesDetected));
        NSE.Path = nsePaths{iFile};
        if iSeg==1
            AppendToFile  = false;
            OverwriteFlag = true;
        else
            AppendToFile  = true;
            OverwriteFlag = false;
        end
        NLX_SaveNSE(NSE,AppendToFile,OverwriteFlag);
        
    end
end
WaitbarAtPrompt([]);
ok = true;