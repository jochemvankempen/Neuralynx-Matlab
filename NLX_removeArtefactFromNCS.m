function [artWave, artT, NCS] = NLX_removeArtefactFromNCS(NCSpath, NLXTimeWin, sampleIndex, refreshPrd, removeFlag, reextractFlag)

% remove an artefact time-locked to the monitor refresh
% MonitorArtefactRemoval(s)
%
%           refreshPrd: 8.3245e+03
%     refreshEventTTLs: [8 16 20 21]
%              NEVpath: '/media/alwin/FREECOM HDD/monkey_data/Richards/pen162/2015-...'
%           NLXTimeWin: [3387853809 3707019474];
%              NCSpath: {1x5 cell}
%              NSEpath: {1x5 cell}
%             maxCycle: Inf
%         plotArtefact: 1
% 

if ischar(NCSpath)
    fprintf('loading %s ... \n',NCSpath);
    if isempty(NLXTimeWin)
        ExtractMode = 1;
    else
        ExtractMode = 4;
    end
    NCS = NLX_LoadNCS(NCSpath,'FULL', ExtractMode, NLXTimeWin);
else
    NCS = NCSpath;
end
ncsHeader = NLX_Head2Struct(NCS.Header);


fprintf('extracting artefact template ... \n');
[artWave, artT] = extractArtefact(NCS, sampleIndex, refreshPrd);

if removeFlag
    fprintf('removing artefact ... \n');
    NCS = removeArtefact(NCS, sampleIndex, artWave, artT);
    if reextractFlag
        fprintf('RE-extracting artefact template ... \n');
        [artWave(2,:), artT] = extractArtefact(NCS, sampleIndex, refreshPrd);
    end
end

artWave = artWave.*(ncsHeader.ADBitVolts.*1000000.0);


function [artefactBits_mean, artefactTimes, artefactBits_std] = extractArtefact(NCS, sampleIndex, refPrd)

sampFreq = unique(NCS.SF);
sampPrd = 1000000.0/sampFreq;
nSamplesPerRefresh = floor(refPrd/sampPrd);

% sample a waveform with onset nearest to a given timestamp
nTs = length(sampleIndex);

getArtefactPopulation = false;
if getArtefactPopulation
    % collect the population of artefact waveforms
    artBits = zeros(nTs,nSamplesPerRefresh).*NaN;
    for its = 1:nTs
        EndSampleNr   = sampleIndex(its)+nSamplesPerRefresh-1;
        artBits(its,:) = NCS.Samples(sampleIndex(its):EndSampleNr);
    end
    artefactBits_mean  = nanmean(artBits);
    artefactBits_std   = nanstd(artBits);
    artefactTimes      = [0:nSamplesPerRefresh-1].*sampPrd;
else
    % sum up the waveform
    artBits = zeros(1,nSamplesPerRefresh);
    for its = 1:nTs
        EndSampleNr   = sampleIndex(its)+nSamplesPerRefresh-1;
        artBits = artBits + NCS.Samples(sampleIndex(its):EndSampleNr);
    end
    artefactBits_mean  = artBits./nTs;
    artefactBits_std   = [];
    artefactTimes      = [0:nSamplesPerRefresh-1].*sampPrd;
end

    
    
function NCS = removeArtefact(NCS, StartSampleNr, artTemp, artT)

NCSHeader = NLX_Head2Struct(NCS.Header);
sampPrd = 1000000.0/NCSHeader.SamplingFrequency;

% analyse artefact
[mxVal,mxInd] = max(artTemp);
[mnVal,mnInd] = min(artTemp);

maxThresh = mean(artTemp)+5*std(artTemp);
minThresh = mean(artTemp)-5*std(artTemp);
if mxVal>maxThresh || mnVal<minThresh
    artLat   = artT(min([mnInd mxInd]));
    % dArtTemp = diff(artTemp);
    fprintf('artefact latency: %1.3f microsec\n', artLat);
else
    fprintf('artefact is not exceeding threshold criterion!\n');
    return;
end

% restrict artefact refresh interval to a waveform
artWaveTimeOffset = artLat-1000;
artWaveTimeLength = 2500;
artWaveBinOffset  = round(artWaveTimeOffset/sampPrd);
artWaveBinNum     = round(artWaveTimeLength/sampPrd);
artWaveIndexOffset = artWaveBinOffset : artWaveBinOffset+artWaveBinNum-1;

for iBin = 1:artWaveBinNum
        NCS.Samples(StartSampleNr+artWaveIndexOffset(iBin)-1) = NCS.Samples(StartSampleNr+artWaveIndexOffset(iBin)-1) - artTemp(artWaveIndexOffset(iBin));
end





