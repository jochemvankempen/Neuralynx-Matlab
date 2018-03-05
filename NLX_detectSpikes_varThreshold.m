function NSE = NLX_detectSpikes_varThreshold(NCS,NLXTime,Threshold,nWaveform,StampMode,WaveformAlign,MinISI,NSEPath, NSE_targetfilesize, appendToFile)

% detect spikes from continous sampled data (*.nrd,*.ncs)
% [TS,WF] = NLX_detectSpikes2(NCS,NLXTime,Threshold,nWaveform,StampMode,WaveformAlign,MinISI,NSEPath, appendToFile)
%
% NCS .............
% NLXTime .........
% Threshold ....... in units of NCS.Samples (digital)
% nWaveform ....... number of waveform samples to take
% StampMode ....... 'Peak'
%                   'Onset'
% WaveformAlign ... aligment sample nr for waveforms
% MinISI .......... retrigger in microseconds
% NSEPath ......... filename attached to the new NSE structure
% appendToFile .... true/false write while extracting
%                   important when working in Linux or with low memory
%
% NSE ... structure, ready to save as *.nse file


if nargin<1
%     NCS = NLX_LoadNCS('D:\Alwin\Analysis\monkey_data\Richards2\pen162\Neuralynx-offline\Cheetah-Replay\e2CSE1.ncs','FULL', 1, []);
    NCS = NLX_LoadNCS('M:\share\Stanford-Collaboration\Richards-Replay\pen129\2016-01-06_11-27-13\e2CSE1.ncs','FULL', 1, []);
    ncsHeadCells = NLX_Head2Cell(NCS.Header); 
    NLXTime       = [];
    Threshold     = 16;
    Threshold     = round(Threshold * 0.000001 / ncsHeadCells{strcmp(ncsHeadCells(:,1),'ADBitVolts'),2});
    nWaveform     = 32;
    StampMode     = 'Peak';
    WaveformAlign = 8;
    MinISI        = 500;% in micro seconds
    chanFilename  = '';
%     NSEPath       = 'D:\Alwin\Analysis\monkey_data\Richards2\pen162\Neuralynx-offline\Cheetah-Replay\test2.nse'; 
    NSEPath       = 'D:\Alwin\temp\test2.nse'; 
    appendToFile  = true;
end

%% check input
if nargin<9
    detectionOffset = [-inf inf];
end
if nargin<4 || isempty(StampMode)
    StampMode = 'Peak';
end


%% 
if all(Threshold<0)
    % for convenience keep a positive sign for thresholding
    NCS.Samples = NCS.Samples.*(-1);
    Threshold   = Threshold.*(-1);
end

cSF                = unique(NCS.SF);
RetriggerSampleNum = ceil(MinISI / (1e6/cSF));
[nRows,nCols]      = size(NCS.Samples);
isWinDiscrim       = length(Threshold)>1;

% diagnostics
tsRecWinIndex      = NLX_getRecPeriodsNCS(NCS);
NCSTimeRange       = [min(NCS.TimeStamps)  max(NCS.TimeStamps)];
tsRecWinTime       = NCS.TimeStamps(tsRecWinIndex);

%% initialise NSE
ncsHeadCells = NLX_Head2Cell(NCS.Header); 
nseHeadCells = ncsHeadCells;
nseHeadCells{strcmp(nseHeadCells(:,1),'FileType'),2}   = 'Spike';
nseHeadCells{strcmp(nseHeadCells(:,1),'RecordSize'),2} = '112';
try 
    nseHeadCells{strcmp(nseHeadCells(:,1),'CheetahRev'),2} = '0.0.0';
    % works for recordings replayed in cheetah version 5.6.3
catch
    nseHeadCells{strcmp(nseHeadCells(:,1),'ApplicationName'),2} = '0.0.0';
    % works for recordings that have been replayed in cheetah version 5.7.4
end

nseHeadCells = cat(1, nseHeadCells, {'', ''});
nseHeadCells = cat(1, nseHeadCells, {'WaveformLength', nWaveform});
nseHeadCells = cat(1, nseHeadCells, {'AlignmentPt', WaveformAlign});
nseHeadCells = cat(1, nseHeadCells, {'ThreshVal', Threshold / 0.000001 * ncsHeadCells{strcmp(ncsHeadCells(:,1),'ADBitVolts'),2}});
nseHeadCells = cat(1, nseHeadCells, {'MinRetriggerSamples', RetriggerSampleNum});
nseHeadCells = cat(1, nseHeadCells, {'SpikeRetriggerTime', MinISI});
nseHeadCells = cat(1, nseHeadCells, {'DualThresholding', 'False'});
nseHeadCells = cat(1, nseHeadCells, {'', ''});
nseHeadCells = cat(1, nseHeadCells, {'Feature NthSample', '0 0 8'}); 
nseHeadCells = cat(1, nseHeadCells, {'Feature NthSample', '1 0 16'}); 
nseHeadCells = cat(1, nseHeadCells, {'Feature NthSample', '2 0 18'}); 
nseHeadCells = cat(1, nseHeadCells, {'Feature NthSample', '3 0 14'}); 
nseHeadCells = cat(1, nseHeadCells, {'Feature Peak',      '4 0'}); 
nseHeadCells = cat(1, nseHeadCells, {'Feature Valley',    '5 0'}); 
nseHeadCells = cat(1, nseHeadCells, {'Feature Energy',    '6 0'}); 
nseHeadCells = cat(1, nseHeadCells, {'Feature Height',    '7 0'}); 


NSE.Path          = NSEPath;
NSE.Header        = [];        
NSE               = NLX_Cell2Head(NSE,nseHeadCells);

NSE.TimeStamps    = [];
NSE.ScNr          = [];
NSE.ClusterNr     = [];
NSE.SpikeFeatures = [];
NSE.SpikeWaveForm = [];

%% detect threshold in chunks

NSE_filesize = 0;
iloop = 0;
iDecr = 1;
Step = 0;
currStepDir = NaN;

WaveMax = 100000;
WaveMin = 1;
fprintf('%1.0f %1.2f MB, waveformsize:  %1.0f to %1.0f\n',iloop, NSE_filesize, WaveMin, WaveMax);
while (NSE_filesize < NSE_targetfilesize(1) || NSE_filesize > NSE_targetfilesize(2))
    
    
    % change threshold
    if NSE_filesize > NSE_targetfilesize(2)
        currStepDir = +1;
        iloop = iloop+1;
        Threshold = WaveMin+Step;
    elseif (iDecr>1 || Step>0) && (NSE_filesize < NSE_targetfilesize(1))
        currStepDir = -1;
        iloop = iloop+1;
        Threshold = WaveMin-Step;
        
        while Threshold<0
            Step = Step/2;
            Threshold = WaveMin-Step;
        end
    elseif NSE_filesize ~=0
        break;
    end

    %%% update header
    nseHeadCells{strcmp(nseHeadCells(:,1),'ThreshVal'),2} = Threshold / 0.000001 * ncsHeadCells{strcmp(ncsHeadCells(:,1),'ADBitVolts'),2};
    
    nRecWin = size(tsRecWinIndex,1);
    fileReadyToAppend = false;
    for iRecWin = 1:nRecWin
        nRecWinCols = diff(tsRecWinIndex(iRecWin,:)) + 1;
        chunkSize = 5000;
        chunkNum  = ceil(nRecWinCols/chunkSize);
        for iChk = 1:chunkNum
            chkTSIndex    = [1 chunkSize] + (iChk-1)*chunkSize;
            chkTSIndex(2) = min([chkTSIndex(2) nRecWinCols]);
            
            % get the actual sample index
            sampleIndex = [sub2ind([nRows,nCols],1,chkTSIndex(1)+tsRecWinIndex(iRecWin,1)-1) sub2ind([nRows,nCols],nRows,chkTSIndex(2)+tsRecWinIndex(iRecWin,1)-1)];
            
            % get threshold crossing
            if isWinDiscrim
                % window discriminator
                isSpike = NCS.Samples(sampleIndex(1):sampleIndex(2)) >=Threshold(1) & NCS.Samples(sampleIndex(1):sampleIndex(2))<=Threshold(2);
            else
                isSpike = NCS.Samples(sampleIndex(1):sampleIndex(2)) > Threshold; % & cTimeBins>=detectionOffset(1);
            end
            % detect peaks (maxima)
            isSpike(:,2:end-1) = isSpike(:,2:end-1) & ...
                diff(NCS.Samples(sampleIndex(1):sampleIndex(2)-1),1,2)>0 & ...
                diff(NCS.Samples(sampleIndex(1)+1:sampleIndex(2)),1,2)<0;
            isSpike([1 end])   = false; % first of this chunk is not considered a peak
            
            % retrigger (impose refractory period)
            isSpike       = find(isSpike);% convert from logical to double
            spikeToDelete = find(diff(isSpike)<RetriggerSampleNum,1,'first');
            spikeDelCount = 0;
            while ~isempty(spikeToDelete)
                spikeDelCount = spikeDelCount+1;
                isSpike(spikeToDelete) = [];
                spikeToDelete = find(diff(isSpike)<RetriggerSampleNum,1,'first');
            end
            
            % convert to real NCS.Samples-Index
            isSpike = sampleIndex(1) + isSpike -1;
            isSpike(isSpike - (WaveformAlign-1) < 1)                           = [];
            isSpike(isSpike - (WaveformAlign-1) + (nWaveform-1) > nRows*nCols) = [];
            nSpikes = length(isSpike);
            
            % extract waveforms
            WaveformIndex    = repmat(isSpike(:) - (WaveformAlign-1),[1 nWaveform]) + repmat([0:nWaveform-1],[nSpikes 1]);
            WaveForms        = NCS.Samples(WaveformIndex);
            [sampleNr, tsNr] = ind2sub([nRows,nCols],isSpike);
            timeStamps       = round(NCS.TimeStamps(tsNr) + (sampleNr-1) .* (1000000./NCS.SF(tsNr))) ;
            
            % append to existing file
            if appendToFile
                if isempty(timeStamps)
                    fprintf('write %u spikes recWin#%u(%u) chk#%u(%u) 1st:%u last:%u tsRange(%u-%u)\n',nSpikes,iRecWin,nRecWin,iChk,chunkNum,-1,-1,NCSTimeRange(1), NCSTimeRange(2));
                else
                    fprintf('write %u spikes recWin#%u(%u) chk#%u(%u) 1st:%u last:%u tsRange(%u-%u)\n',nSpikes,iRecWin,nRecWin,iChk,chunkNum,timeStamps(1),timeStamps(end),NCSTimeRange(1), NCSTimeRange(2));
                end
                NSE.ScNr          = ones(nSpikes,1).*unique(NCS.ChNr);
                NSE.ClusterNr     = zeros(nSpikes,1);
                NSE.SpikeFeatures = zeros(8,nSpikes);
                NSE.SpikeWaveForm = permute(WaveForms,[2 3 1]);
                NSE.TimeStamps    = timeStamps(:);
                if nSpikes>0
                    if ~fileReadyToAppend
                        NSE = NLX_SaveNSE(NSE,false,true);
                        fileReadyToAppend = true;
                    else
                        NSE = NLX_SaveNSE(NSE,true,false);
                    end
                end
            else
                %fprintf('append %u spikes chk#%u(%u)\n',nSpikes,iChk,chunkNum);
                NSE.ScNr          = cat(1,NSE.ScNr,ones(nSpikes,1).*unique(NCS.ChNr));
                NSE.ClusterNr     = cat(1,NSE.ClusterNr,zeros(nSpikes,1));
                NSE.SpikeFeatures = cat(2,NSE.SpikeFeatures,zeros(8,nSpikes));
                NSE.SpikeWaveForm = cat(3,NSE.SpikeWaveForm,permute(WaveForms,[2 3 1]));
                NSE.TimeStamps    = cat(1,NSE.TimeStamps,timeStamps(:));
            end
        end
    end
    
    if ~appendToFile && ~isempty(NSEPath)
        NSE = NLX_SaveNSE(NSE,false,true);
    end
    
    %     [PATHSTR,NAME,EXT] = fileparts(NSE.Path);
    NSE_file = dir(NSE.Path);
    NSE_filesize = NSE_file.bytes/1e6;
    
    WaveAlign = NLX_getWaveAlign(NSE);
    iCluster = NLX_findSpikes(NSE,'CLUSTER',0);
    WaveMax = NLX_WaveformMax(NSE,iCluster,WaveAlign);
    WaveMin = NLX_WaveformMin(NSE,iCluster,WaveAlign);
    
    fprintf('%1.0f %1.2f MB, waveformsize: %1.0f to %1.0f\n',iloop, NSE_filesize, WaveMin, WaveMax);

    if iloop == 0
        Step = 0.5*abs(diff([WaveMax WaveMin]));
    else
        iDecr = iDecr+1;
        Step = Step .* (log(2)./log(iDecr+1));
    end
    StepHistory(iDecr) = Step;

    if Step < 1
        % implemented an extra cycle with different step sizes, to prevent
        % non-convergence to a spike threshold and getting stuck in the
        % while loop with stepsize 0. Jochem van Kempen 01/03/2018
        Step = mean(StepHistory(2:3));
        i = 1;
        iDecr = 1;
    end
end

% ######## Neuralynx Data File Header
% ## File Name D:\Richards\pen162\2015-12-14_13-03-20\e2SE8.nse
% ## Time Opened (m/d/y): 12/14/2015  (h:m:s.ms) 13:3:21.78
% ## Time Closed (m/d/y): 12/14/2015  (h:m:s.ms) 16:47:39.949
% 
% -FileType Spike
% -FileVersion 3.3.0
% -RecordSize 112
% 
% -CheetahRev 5.6.3 
% 
% -HardwareSubSystemName AcqSystem1
% -HardwareSubSystemType RawDataFile
% -SamplingFrequency 32556
% -ADMaxValue 32767
% -ADBitVolts 0.000000004577776380187970
% 
% -AcqEntName e2SE8
% -NumADChannels 1
% -ADChannel 23
% -InputRange 150
% -InputInverted True
% 
% -DSPLowCutFilterEnabled True
% -DspLowCutFrequency 600
% -DspLowCutNumTaps 64
% -DspLowCutFilterType FIR
% -DSPHighCutFilterEnabled True
% -DspHighCutFrequency 9000
% -DspHighCutNumTaps 32
% -DspHighCutFilterType FIR
% -DspDelayCompensation Disabled
% -DspFilterDelay_µs 1444
% 
% -WaveformLength 32
% -AlignmentPt 8
% -ThreshVal 16
% -MinRetriggerSamples 17
% -SpikeRetriggerTime 500
% -DualThresholding False
% 
% -Feature NthSample 0 0 8 
% -Feature NthSample 1 0 16 
% -Feature NthSample 2 0 18 
% -Feature NthSample 3 0 14 
% -Feature Peak 4 0 
% -Feature Valley 5 0 
% -Feature Energy 6 0 
% -Feature Height 7 0 

% ######## Neuralynx Data File Header
% ## File Name D:\Richards\pen162\2015-12-14_17-39-08\e2CSE8.ncs
% ## Time Opened (m/d/y): 12/14/2015  (h:m:s.ms) 17:39:9.531
% ## Time Closed (m/d/y): 12/15/2015  (h:m:s.ms) 8:37:54.56
% 
% -FileType CSC
% -FileVersion 3.3.0
% -RecordSize 1044
% 
% -CheetahRev 5.6.3 
% 
% -HardwareSubSystemName AcqSystem1
% -HardwareSubSystemType RawDataFile
% -SamplingFrequency 32556
% -ADMaxValue 32767
% -ADBitVolts 0.000000004577776380187970
% 
% -AcqEntName e2CSE8
% -NumADChannels 1
% -ADChannel 23
% -InputRange 150
% -InputInverted True
% 
% -DSPLowCutFilterEnabled True
% -DspLowCutFrequency 600
% -DspLowCutNumTaps 128
% -DspLowCutFilterType FIR
% -DSPHighCutFilterEnabled True
% -DspHighCutFrequency 9000
% -DspHighCutNumTaps 128
% -DspHighCutFilterType FIR
% -DspDelayCompensation Disabled
% -DspFilterDelay_µs 3900