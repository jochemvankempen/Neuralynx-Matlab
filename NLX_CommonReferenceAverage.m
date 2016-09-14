function ok = NLX_CommonReferenceAverage(SourcePaths,SavePaths,CARPath, settings)

% Compute the Common-Average-Reference and re-reference a stack of analog
% channel data. Data are neuralynx continous sampled (*.ncs) files
% 
% use as
% NLX_CommonReferenceAverage(SourcePaths,SavePaths,CARPath)
% SourcePaths ... cell array of filepaths to *.ncs files of channels
% SavePaths ..... cell array of filepaths to referenced *.ncs files
% CARPath ....... char array to save the reference signal as *.ncs file
% settings ...... settings structure
%                 segmentSize   : [30000]
%                 maxSegmentNum : [inf]
%
% Writing NCS file in Linux from custom-matlab replayed files doesn't work
% in the moment.
% - test if cheetah replayed files works with Linux

nFiles = length(SourcePaths);
ok = false;

%% check settings
defaults.segmentSize    = 30000;% 30000 max recommended
defaults.maxSegmentNum  = inf;
settings = StructUpdate(defaults,settings);

%% ask user to proceed
% fprintf(1,'\n================================================================\n');
% fprintf(1,'Source Data:\n');
% for iFile = 1:nFiles
%     fprintf(1,'#%2u : %s\n',iFile,SourcePaths{iFile});
% end
% fprintf(1,'\nCAR file:\n%s\n',CARPath);
% fprintf(1,'\nSave Data:\n');
% for iFile = 1:nFiles
%     fprintf(1,'#%2u : %s\n',iFile,SavePaths{iFile});
% end
% 
% answer = input('Do you want to proceed? Y[N] ','s');
% if ~strcmpi(answer,'y')
%     return;
% end


%% get general recording information form the first file
fprintf(1,'loading first NCS files of stack in "NOSAMPLES" mode\n');
fprintf(1,'%s\n',SourcePaths{1});
NCS = NLX_LoadNCS(SourcePaths{1},'NOSAMPLES',1,[]);
nRecsTotal = length(NCS.TimeStamps);
Fs = unique(NCS.SF);
for iFs = 1:length(Fs)
    nFs(iFs) = sum(NCS.SF==Fs(iFs));
end

fprintf(1,'%20s : %u\n','N records',nRecsTotal);
for iFs=1:length(Fs)
    fprintf(1,'%20s : %1.3f Hz ( %1.3f µs) in %u records\n','sampling frequency',Fs(iFs),1000000/Fs(iFs),nFs(iFs));
end
fprintf(1,'\n');


%% loading data samples
% Load data in segments of record-indices to restrict load on working
% memory. 
nSegments      = min([settings.maxSegmentNum ceil(nRecsTotal/settings.segmentSize)]);
segmentCounter = 0;
BackSpaceNum = WaitbarAtPrompt('computing CAR from NCS','',20);
for iSeg = 1:nSegments
    currRecIndex   = [1:settings.segmentSize] + settings.segmentSize .* (iSeg-1);
    currRecIndex   = currRecIndex(currRecIndex<=nRecsTotal);
    
    % load file stack
    for iFile = 1:nFiles
        tic;
        ncsData(iFile) = NLX_LoadNCS(SourcePaths{iFile},'FULL',3,currRecIndex);
        t = toc;
        waitBarString = sprintf('segment#%u(%u): loading file#%u(%u) (n=%u %u-%u) took %1.3fs',iSeg,nSegments,iFile,nFiles,length(currRecIndex),currRecIndex(1),currRecIndex(end),t);
        waitBarLength = ((iSeg-1)*nFiles+iFile)/(nSegments*nFiles);
        BackSpaceNum = WaitbarAtPrompt(waitBarLength,BackSpaceNum,waitBarString);
    end
    
    % compute CAR
    BackSpaceNum = WaitbarAtPrompt(waitBarLength,BackSpaceNum,sprintf('segment#%u(%u): computing CAR ...' ,iSeg,nSegments));
    ncsCAR      = ncsData(1);
    ncsCAR.Path = CARPath;
%     ncsCAR.Path = [sprintf('seg%u_',iSeg) CARPath];
    for iFile = 2:nFiles
        ncsCAR.Samples = ncsCAR.Samples+ncsData(iFile).Samples;
    end
    ncsCAR.Samples = ncsCAR.Samples./nFiles;
    
    % write to CAR file
    % writing NCS files doesn't work in Linux!!!
    if ~isempty(CARPath)
        BackSpaceNum = WaitbarAtPrompt(waitBarLength,BackSpaceNum,sprintf('segment#%u(%u): writing to CAR-*.ncs ...',iSeg,nSegments));
        if iSeg==1
            NLX_SaveNCS(ncsCAR,false);
        else
            NLX_SaveNCS(ncsCAR,true);
        end
    end
    
    % reference data and write
    if ~isempty(SavePaths)
        for iFile = 1:nFiles
            ncsData(iFile).Path    = SavePaths{iFile};
            ncsData(iFile).Samples = ncsData(iFile).Samples-ncsCAR.Samples;
            if iSeg==1
                NLX_SaveNCS(ncsData(iFile),false);
            else
                NLX_SaveNCS(ncsData(iFile),true);
            end
            BackSpaceNum = WaitbarAtPrompt(waitBarLength,BackSpaceNum,sprintf('segment#%u(%u): writing re-references of file#%u(%u) *.ncs ...',iSeg,nSegments,iFile,nFiles));
        end
    end
    
end
WaitbarAtPrompt([])

ok = true;