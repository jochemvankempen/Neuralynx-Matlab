function nlxPostProcess_ART_CAR(NCSPaths,targetDir,deleteTempFiles, carSET,artSET,spikeSET)
% NLXPOSTPROCESS_ART_CAR 
%
% Common-Average Referencing, Artefact-removal, spike extraction from NCS
% files
%
% _input_
%
%     NCSPaths          [cell] array of filepaths
%     targetDir         [char] directory to store new files
%     deleteTempFiles   [logic] delete temporarily created files
%     carSET            [struct] settings for Common-Average-Referencing
%                           computeCARFlag
%                           NCSname
%                           segmentSize
%                           maxSegmentNum
%     artSET            [struct] settings for monitor artefact removal
%                           removeArtefactFlag
%                           NEVpath
%     spikeSET          [struct] settings for spike extraction
%                           detectSpikesFlag
%                           NSEPaths
%                           carPath
%                           Threshold
%                           nWaveform
%                           StampMode
%                           WaveformAlign
%                           MinISI


%% preparations
fid = 1; % prints messages

if ~exist(targetDir,'dir')
    fprintf(fid,'creating %s\n',targetDir);
    mkdir(targetDir);
end

nNCS = length(NCSPaths);

%% remove Artefact
if artSET.removeArtefactFlag
    
    % create [temporary] paths for artefact free files
    NCSSavePaths = cell(nChan,1);
    for iNCS = 1:nNCS
        [fDir,fName,fExt] = fileparts(NCSPaths);
        NCSSavePaths{iNCS} = fullfile(targetDir,sprintf('%s%s',fName,fExt));
    end

    % reconstructs monitor refresh timestamps and find matching bin index
    fprintf(fid,'%40s ... \n','reconstructing monitor refresh');
    monitorTs    = NLX_getMonitorRefresh(artSET.NEVpath, refreshEventTTLs, [], refreshPrd, inf);
    NCS          = NLX_LoadNCS(NCSPaths{1},'NOSAMPLES',1,[]);
    monitorIndex = NLX_findNCSIndex(NCS, monitorTs,'matrix');
    % NaN index defines timestamps in between recording breaks
    % monitorTs(isnan(monitorIndex)) = [];
    clear monitorTs
    monitorIndex(isnan(monitorIndex)) = [];

    % remove artefacts
    for iNCS = 1:nNCS
        fprintf(fid,'loading #%u(%u) %s ... \n',iNCS,nNCS,NCSPaths{iNCS});
        NCS = NLX_LoadNCS(NCSPaths{iNCS},'FULL', 1, []);
        %         [ncsFileDir,ncsFileName, ncsFileExt] = fileparts(NCSPaths{iChan});

        % remove artefact
        fprintf(fid,'%40s ... \n', 'removing artefact');
        [artWave{iNCS}, artTime{iNCS}, NCS] = NLX_removeArtefactFromNCS(NCS, [], monitorIndex, refreshPrd, true, true);

        NCS.Path = NCSSavePaths{iNCS};
        if exist(NCS.Path,'file');delete(NCS.Path);end
        fprintf(fid,'save #%u(%u) %s ... \n',iNCS,nNCS,NCS.Path);
        NLX_SaveNCS(NCS,false);
    end

    NCSPaths = NCSSavePaths;
end

%% compute CAR-file
if carSET.computeCARFlag
    NCSCARPath = fullfile(targetDir, carSET.NCSname);
    fprintf(fid,'%40s ... ', 'compute CAR file');
    ok = NLX_CommonReferenceAverage(NCSPaths,[],NCSCARPath,carSET);
    fprintf(fid,'done\n');
end

    
%% extract spikes
if spikeSET.detectSpikesFlag
    
    if isempty(spikeSET.NSEPaths)
        for iNCS = 1:nNCS
            spikeSET.NSEPaths{iNCS}     = fullfile(targetDir,sprintf('spikes-%u.nse',iNCS));
        end
    end
    
    if carSET.computeCARFlag
        fprintf(fid,'%s %s \n','loading existing  CAR', NCSCARPath);
        NCSCAR  = NLX_LoadNCS(NCSCARPath,'FULL',1,[]);
    elseif ~isempty(spikeSET.carPath)
        fprintf(fid,'%s %s \n','loading existing  CAR', NCSCARPath);
        NCSCAR  = NLX_LoadNCS(spikeSET.carPath,'FULL',1,[]);
    else
        NCSCAR = [];
    end
    
    for iNCS = 1:nNCS
        fprintf(fid,'loading #%u(%u) %s ... \n',iNCS,nNCS,NCSPaths{iNCS});
        NCS       = NLX_LoadNCS(NCSPaths{iNCS},'FULL', 1, []);
        ncsHeader = NLX_Head2Cell(NCS.Header);
        ADMaxValue = ncsHeader{strcmp(ncsHeader(:,1),'ADMaxValue'),2};
        ADBitVolts = ncsHeader{strcmp(ncsHeader(:,1),'ADBitVolts'),2};
        
        % re-reference
        if ~isempty(NCSCAR)
            fprintf(fid,'%40s ... \n','referencing');
            NCS.Samples = NCS.Samples-NCSCAR.Samples;
            NCS.Samples(NCS.Samples>ADMaxValue) = ADMaxValue;
            NCS.Samples(NCS.Samples<-ADMaxValue) = -ADMaxValue;
        end
        
        fprintf(fid,'%40s ... \n','extracting spikes');
        currThreshold     = round(spikeSET.Threshold * 0.000001 / ADBitVolts);
        
        if exist(spikeSET.NSEPaths{iNCS},'file')
            delete(spikeSET.NSEPaths{iNCS});
        end
        fprintf(fid,'writing %s\n',spikeSET.NSEPaths{iNCS});
        NLX_detectSpikes2(NCS,[],currThreshold,spikeSET.nWaveform,spikeSET.StampMode,spikeSET.WaveformAlign,spikeSET.MinISI,spikeSET.NSEPaths{iNCS}, true);
        
        clear NCS
    end
end

%% deleting temporary files
if deleteTempFiles && artSET.removeArtefactFlag
    for iNCS = 1:nNCS
        if exist(NCSSavePaths{iNCS},'file')
            fprintf(fid,'deleting %s ...',NCSSavePaths{iNCS});
            delete(NCSSavePaths{iNCS});
            fprintf(fid,'done\n');
        end
    end
end



