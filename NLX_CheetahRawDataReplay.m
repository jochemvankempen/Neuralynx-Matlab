function [NRD,NCS,NSE,newSF,numSpikes] = NLX_CheetahRawDataReplay(RawDataPath,TimeWin,ReplayPar,OutputDir,TimeLabel)

% extract *.ncs and *.nse file from cheetah raw-data files (*.nrd)
%
% [NRD,NCS,NSE,newSF,numSpikes] = NLX_CheetahRawDataReplay(RawDataPath,TimeWin,ReplayPar,OutputDir)
%
% RawDataPath ... path to *.nrd file OR NRD structure
% TimeWin .......
% ReplayPar ..... Structure with replay settings. Structure can be an array
%                 each of which will be replayed sequentially.
% OutputDir .....
%

NRD = [];
NCS = [];
NSE = [];
newSF = [];
numSpikes = 0;

%%  settings
if nargin<4
    OutputDir = '';
end

TimeWinNum = size(TimeWin,1);

% Just read
if nargin<3
    ReplayPar.Tag = '';
    ReplayPar.ADChannel = 0;
    ReplayPar.reloadRawdata = true;
    ReplayPar.writeNCS = false;
    ReplayPar.writeNSE = false;
    ReplayPar.FilterDesign = {};
    ReplayPar.SignalInverted = false;
    ReplayPar.SamplingFreq = [];
    ReplayPar.SpikeDetection = false;
    
elseif nargin>2 && isempty(ReplayPar)
    
    % LFP settings
    iRep = 1;
    ReplayPar(iRep).Tag = 'LFP';
    ReplayPar(iRep).ADChannel = 0;
    ReplayPar(iRep).reloadRawdata = false;
    ReplayPar(iRep).writeNCS = true;
    ReplayPar(iRep).writeNSE = false;
    ReplayPar(iRep).NSEName = 'SE1';
    ReplayPar(iRep).NCSName = 'CSC1';
    ReplayPar(iRep).FilterDesign = {'butter' 'butter'};
    ReplayPar(iRep).FilterPassFreq = {[3] [300]};
    ReplayPar(iRep).FilterPassOrder = {[3] [3]};
    ReplayPar(iRep).FilterPassType = {'high' 'low'};
    ReplayPar(iRep).FilterFunction = {'filtfilt' 'filtfilt'};
    ReplayPar(iRep).SignalInverted = true;
    ReplayPar(iRep).SamplingFreq = 1000;
    ReplayPar(iRep).SpikeDetection = false;
    ReplayPar(iRep).SpikeThreshold = [];
    ReplayPar(iRep).SpikeFeature = '';
    ReplayPar(iRep).SpikeWaveformLength = [];
    ReplayPar(iRep).SpikeWaveformAlign = [];
    
    % NSE settings
    iRep = 2;
    ReplayPar(iRep).Tag = 'spikes';
    ReplayPar(iRep).ADChannel = 0;
    ReplayPar(iRep).reloadRawdata = false;
    ReplayPar(iRep).writeNCS = false;
    ReplayPar(iRep).writeNSE = true;
    ReplayPar(iRep).NSEName = 'SE1';
    ReplayPar(iRep).NCSName = 'CSC1';
    ReplayPar(iRep).FilterDesign = {'butter' 'butter'};
    ReplayPar(iRep).FilterPassFreq = {[600] [9000]};
    ReplayPar(iRep).FilterPassOrder = {[3] [3]};
    ReplayPar(iRep).FilterPassType = {'high' 'low'};
    ReplayPar(iRep).FilterFunction = {'filtfilt' 'filtfilt'};
    ReplayPar(iRep).SignalInverted = true;
    ReplayPar(iRep).SamplingFreq = [];
    ReplayPar(iRep).SpikeDetection = true;
    ReplayPar(iRep).SpikeThreshold = 1000;
    ReplayPar(iRep).SpikeFeature = 'Peak';
    ReplayPar(iRep).SpikeWaveformLength = 32;
    ReplayPar(iRep).SpikeWaveformAlign = 8;
    ReplayPar(iRep).SpikeMinISI = 2.5*1e3;% retrigger in microseconds
    
end


%% Loop trough replay's
ReplayNum = length(ReplayPar);
AppendToFile = 0;
OverwriteFile = 0;

for iTW = 1:TimeWinNum
    fprintf(1,'\n>>>>>>>>>>>>>>>>>>> read RAW data <<<<<<<<<<<<<<<<<<<<<<<<<<\n');
    
    % check if current time window has been read in earlier go
    if iTW>1 && ~isempty(isempty(TimeWin(iTW,:))) ...
            && min(TimeWin(iTW,:))>=min(NRDTimeLim) ...
            && max(TimeWin(iTW,:))<=max(NRDTimeLim)
        TimeWasRead = true;
    else
        TimeWasRead = false;
    end
    
    if ischar(RawDataPath) && ...
            (iRep==1 || isempty(TimeWin)  || ~TimeWasRead  || (TimeWasRead && ReplayPar(iRep).reloadRawdata))
        fid = fopen(RawDataPath,'r');
        fseek(fid,0,'eof');
        fBytes = ftell(fid);
        fclose(fid);
        fprintf(1,'%s\n',RawDataPath);
        fprintf(1,'file size: %1.0f bytes (%1.3f Gb)\n',fBytes,fBytes.*9.31323e-10);
        
        if isempty(TimeWin)
            % read the entire file
            ButtonName = questdlg('Reading ALL of the file takes ages. Are you sure to proceed?','cheetah Rawdata-file', 'No');
            if ~strcmp(ButtonName,'Yes');
                fprintf(1,'cancelled\n');
                return;
            end
            fprintf(1,'reading ALL ...');
            NRD = NLX_LoadNRD(RawDataPath,ReplayPar(iRep).ADChannel,'FULL',1,[]);
        else
            % read some of the file
            tRec = abs(diff(TimeWin(iTW,:)));
            tRec = tRec * 1e-6  * (1/60);
            fprintf(1,'reading %1.2f min of recording ...',tRec);
            NRD = NLX_LoadNRD(RawDataPath,ReplayPar(iRep).ADChannel,'FULL',4,TimeWin(iTW,:));
        end
        fprintf(1,'done\n');
        
    elseif isstruct(RawDataPath)
        % input is NRD structure already;
        NRD = RawDataPath;
        fprintf(1,'use raw data from workspace\n');
    end
    
    fprintf(1,'\n');
    
    for iRep=1:ReplayNum
        fprintf(1,'>>>>>>>>>>>>>>>>>>> started Replay #%u of %u <<<<<<<<<<<<<<<<<<<<<<<<<<\n',iRep,ReplayNum);

        LoIndex = find(NRD.TimeStamps>=TimeWin(iTW,1),1,'first');
        HiINdex = find(NRD.TimeStamps<=TimeWin(iTW,2),1,'last');
        xNRD = NRD;
        xNRD.TimeStamps = xNRD.TimeStamps(LoIndex:HiINdex,1);
        xNRD.Samples = xNRD.Samples(LoIndex:HiINdex,1);
        Header = NLX_Head2Struct(xNRD);
        NRDTimeLim = xNRD.TimeStamps([1 end]);
        fprintf(1,'current time window - Duration: %4.0f min %2.3f sec Start: %u\n',floor((NRDTimeLim(2)-NRDTimeLim(1))*1e-6/60),rem((NRDTimeLim(2)-NRDTimeLim(1))*1e-6,60),NRDTimeLim(1));

        %% filter
        FilterNum = length(ReplayPar(iRep).FilterDesign);
        if FilterNum>0;fprintf(1,'applying %u filters:\n',FilterNum);end
        for j = 1:FilterNum
            
            fprintf(1,'#%u: "%s" %u %6.1f Hz %s-pass ... ',j,ReplayPar(iRep).FilterDesign{j},ReplayPar(iRep).FilterPassOrder{j},ReplayPar(iRep).FilterPassFreq{j},ReplayPar(iRep).FilterPassType{j});
            
            switch ReplayPar(iRep).FilterDesign{j}
                case 'butter'
                    [b,a] = butter( ...
                        ReplayPar(iRep).FilterPassOrder{j}, ...
                        ReplayPar(iRep).FilterPassFreq{j} ./ (Header.SamplingFrequency/2), ...
                        ReplayPar(iRep).FilterPassType{j});
            end
            
            switch ReplayPar(iRep).FilterFunction{j}
                case 'filtfilt'
                    xNRD.Samples = filtfilt(b,a,xNRD.Samples);
                    
            end
            
            fprintf(1,'done\n');
        end
        
        %% invert signal
        if ReplayPar(iRep).SignalInverted
            xNRD.Samples = xNRD.Samples.*-1;
            fprintf(1,'signal inverted\n');
        end
        
        %% DownSample
        if ~isempty(ReplayPar(iRep).SamplingFreq) && Header.SamplingFrequency>ReplayPar(iRep).SamplingFreq
            n = length(xNRD.Samples);
            fprintf(1,'Trying to sample down to %1.2f Hz ',ReplayPar(iRep).SamplingFreq);
            NewIncr = floor(Header.SamplingFrequency/ReplayPar(iRep).SamplingFreq);
            xNRD.TimeStamps = xNRD.TimeStamps(1:NewIncr:n,1);
            xNRD.Samples = xNRD.Samples(1:NewIncr:n,1);
            newSF(iRep) = Header.SamplingFrequency/NewIncr;
            Header.SamplingFrequency = newSF(iRep);
            xNRD = NLX_Struct2Head(xNRD,Header);
            fprintf(1,'-> %1.2f Hz\n',newSF(iRep));
        else
            newSF(iRep) = Header.SamplingFrequency;
            fprintf(1,'keep sampling @%1.2f Hz\n',newSF(iRep));
        end
        
        %% create NCS
        NCS = NLX_NRD2NCS(xNRD,ReplayPar(iRep).NCSName,[]);
        NCS = NLX_setPath(NCS,OutputDir,sprintf('%s.%s',TimeLabel{iTW},ReplayPar(iRep).NCSName),'.ncs');
        if ReplayPar(iRep).writeNCS
            fprintf(1,'save  *.ncs to %s\n',NCS.Path);
            NCS = NLX_SaveNCS(NCS,AppendToFile);
        end
        
        %% detect spikes
        if ReplayPar(iRep).SpikeDetection
            
            fprintf(1,'Detect spikes       : Threshold=%u Feature=''%s''\n',ReplayPar(iRep).SpikeThreshold,ReplayPar(iRep).SpikeFeature);
            fprintf(1,'Extracting Waveforms: nSamples=%u alignedto=%u\n',ReplayPar(iRep).SpikeWaveformLength,ReplayPar(iRep).SpikeWaveformAlign);
            numSpikes(iRep) = 0;
            cTimeWin = [];
            NSE = NLX_detectSpikes(NCS,cTimeWin, ...
                ReplayPar(iRep).SpikeThreshold,ReplayPar(iRep).SpikeWaveformLength,ReplayPar(iRep).SpikeFeature,ReplayPar(iRep).SpikeWaveformAlign,ReplayPar(iRep).SpikeMinISI,ReplayPar(iRep).NSEName);
            numSpikes(iRep) = length(NSE.TimeStamps);
            fprintf(1,'-> %u spikes detected\n',numSpikes(iRep));
            NSE = NLX_setPath(NSE,OutputDir,sprintf('%s.%s',TimeLabel{iTW},ReplayPar(iRep).NSEName),'.nse');
%             NSE = NLX_setPath(NSE,OutputDir,sprintf('%s',ReplayPar(iRep).NSEName),'.nse');
            
            if ReplayPar(iRep).writeNSE
                fprintf(1,'save  *.nse to %s\n',NSE.Path);
                NSE = NLX_SaveNSE(NSE,AppendToFile,OverwriteFile);
            end
        end
        fprintf(1,'\n');
    end
end

