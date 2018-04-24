function NLX_determineRecordingStability(penInfo, NAME, file_path, areaTXT, target_path)
%
%
areaTXT = {'V1','V4'}
NAME = {'grcjdru1.'}

plot_stability = true; %if false, it does compute the filese. this takes some time, so this function allows you to compute the files for several recordings and come back to the plots later.
CAR_correction  = false; % this can spuriously increase the snr of channels that without CAR have an snr of ~0

close all
plot_visible = 'on';

SET = getSettings_corticalState;



%%% directories
fig_path = [target_path filesep 'figures' filesep 'stability' filesep];
if ~exist(fig_path,'dir')
    mkdir(fig_path)
end

% get channels for both V1 and V4, so that the maximal duration across both
% areas can be determined
chans2=[];
for iarea = 1:length(areaTXT)
    [tmp, recDepths] = chanInclusion(penInfo, target_path, areaTXT{iarea}, 'ALL');
    
    chans2 = [chans tmp];
end

%%% file paths
NCSPaths = cell(length(chans),1); % original NCS paths. In case MUAe doesn't exist, it is created
LFPPaths = cell(length(chans),1); % original LFP paths
NSEPaths = cell(length(chans),1); % CAR corrected NSE paths
NSE_targetPaths = cell(length(chans),1); % we create new NSE files, just for the stability estimation
MUAePaths = cell(length(chans),1); % to create MUAe

for i=1:length(chans)
    NCSPaths{i,1} = fullfile(file_path,sprintf('CSC%u.ncs',chans(i)));
end

for i=1:length(chans)
    LFPPaths{i,1} = fullfile(file_path,sprintf('LFP%u.ncs',chans(i)));
end

for i=1:length(chans)
    NSEPaths{i,1} = fullfile(target_path,sprintf('CSC_CAR(%s)_SE%u.nse',SET.channelSelection.CAR,chans(i)));
end

ext = ['_CAR(' SET.channelSelection.CAR ')'];
for i=1:length(chans)
    NSE_targetPaths{i,1} = fullfile(target_path,sprintf('SE%u%s_stability.nse',chans(i),ext));
end

ext = '';
if CAR_correction
    ext = '_CAR';
end
for i=1:length(chans)
    MUAePaths{i,1} = fullfile(target_path,sprintf('MUAe%u%s.ncs',chans(i),ext));
end


%%% EXTRACTION SETTINGS
% Computational times
tlim.extract        = [-600 800];
tlim.spontaneous    = [-500 -50];
tlim.stim           = [20 150];
tlim.sustained      = [150 400];

figext = [''];
savefilename2 = ['stability_allChan.mat'  ];
savefilename = ['stability_allChan_trExcl.mat'  ];
%%

%%%
if ~exist([target_path savefilename],'file') && ~exist([target_path savefilename2],'file')
    
    %%% load trial info
     [allTr, ModeArray] = loadTrialInfo_grcjdru1(penInfo, target_path, file_path, []);

    if CAR_correction
        NCSCARPath = [target_path areaTXT '_CAR_' SET.channelSelection.CAR '.ncs'];
        fprintf('%s ','loading existing CAR:', NCSCARPath);
        NCSCAR  = NLX_LoadNCS(NCSCARPath,'FULL', 4, ModeArray);
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% load MUAe data.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    for iNCS = 1:length(NCSPaths)
        
        [PATHSTR,FILENAME,EXT] = fileparts(MUAePaths{iNCS});
        altFilename = [PATHSTR filesep FILENAME '.mat'];
        
        if ~exist(MUAePaths{iNCS}, 'file') && ~exist(altFilename, 'file')
            
            fprintf('loading #%u(%u) %s ... \n',iNCS,length(NCSPaths),NCSPaths{iNCS});
            NCS       = NLX_LoadNCS(NCSPaths{iNCS},'FULL', 4, ModeArray);
            ncsHeader = NLX_Head2Cell(NCS.Header);
            ADMaxValue = ncsHeader{strcmp(ncsHeader(:,1),'ADMaxValue'),2};
            %         ADBitVolts = ncsHeader{strcmp(ncsHeader(:,1),'ADBitVolts'),2};
            
            if CAR_correction
                fprintf('%40s ... \n','referencing');
                NCS.Samples = NCS.Samples-NCSCAR.Samples;
                NCS.Samples(NCS.Samples>ADMaxValue) = ADMaxValue;
                NCS.Samples(NCS.Samples<-ADMaxValue) = -ADMaxValue;
            end
            
            MUAe = NLX_NCS2MUAe(NCS, [], true, MUAePaths{iNCS}); % saved in NCS data structure
        else
            if plot_stability
                if exist(MUAePaths{iNCS}, 'file')
                    disp(['loading ' MUAePaths{iNCS}])
                    load(MUAePaths{iNCS});
                else
                    disp(['loading ' altFilename])
                    load(altFilename, 'MUAe');
                end
            end
        end
        
        if plot_stability
            [allMUAe(iNCS,:,:), allTr, MuaeTimestamps] = alignData_grcjdru(MUAe, 'NCS', allTr, 'stim', tlim.extract);
        end        %             allMUAe(iNCS,:,:) = scaleVar(Samples, 'minmax');
    end
    
    %     figure
    %     plot(MuaeTimestamps,squeeze(mean(allMUAe,2)))
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% load LFP data
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if plot_stability
        
        for iNCS = 1:length(LFPPaths)
            disp(['loading ' LFPPaths{iNCS}])
            
            LFP       = NLX_LoadNCS(LFPPaths{iNCS},'FULL', 4, ModeArray);
            
            [allLFP(iNCS,:,:), allTr, LFPTimestamps] = alignData_grcjdru(LFP, 'NCS', allTr, 'stim', tlim.extract);
        end
    end
    %         figure
    %         plot(LFPTimestamps,squeeze(mean(allLFP,2)))
    %
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% load NSE data
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    if plot_stability
        plotDataX = cell(length(NSEPaths),1);
        plotDataY = cell(length(NSEPaths),1);
        histos = zeros(length(NSEPaths), length(allTr), length(tlim.extract(1):tlim.extract(end)));
    end
    
    for iNSE = 1:length(NSEPaths)
        if exist(NSE_targetPaths{iNSE},'file')
            if plot_stability
                disp(['loading ' NSE_targetPaths{iNSE}])
                NSE = NLX_LoadNSE(NSE_targetPaths{iNSE}, 'FULL', 1, []);
            end
        else
            disp(['computing ' NSE_targetPaths{iNSE}])
            % load CAR corrected NSE file
            NSE = NLX_LoadNSE(NSEPaths{iNSE}, 'FULL', 1, []);
            
            nCluster = length(unique(NSE.ClusterNr));
            
            % define time window (parts of trials) where to base the spike threshold on, in
            % order to get a decent idea what the stability of the
            % recording is, we determine the threshold based on the desired
            % firing rate.
            timewin = zeros(length(allTr),2);
            for itrial = 1:length(allTr)
                fix_start   = min(allTr(itrial).evnt_t_orig(allTr(itrial).evnt==4));
                first_dim   = min(allTr(itrial).evnt_t_orig(allTr(itrial).evnt==25));
                timewin(itrial,:) = [fix_start first_dim] + ([200 0] * 1e3);
            end
            timewin(sum(timewin,2)==0,:) = [];
            
            [NSE,i] = NLX_Freq2Threshold_max2min(NSE, 0 , [95 105], timewin, nCluster);
            
            if i ~= 0 %
                NSE.TimeStamps      = NSE.TimeStamps(NSE.ClusterNr ~= nCluster);
                NSE.ScNr            = NSE.ScNr(NSE.ClusterNr ~= nCluster);
                NSE.SpikeFeatures   = NSE.SpikeFeatures(:,NSE.ClusterNr ~= nCluster);
                NSE.SpikeWaveForm   = NSE.SpikeWaveForm(:,:,NSE.ClusterNr ~= nCluster);
                NSE.ClusterNr       = NSE.ClusterNr(NSE.ClusterNr ~= nCluster);
                
                %%% save NSE file
                NSE.Path = NSE_targetPaths{iNSE};
                disp(['saving ' NSE.Path])
                NLX_SaveNSE(NSE,[],1);
            end
        end
        
        if plot_stability
            [sps(iNSE,:), allTr, firingrate] = alignData_grcjdru(NSE, 'NSE', allTr, 'stim', tlim.extract);
            
            for itrial = 1:length(allTr)
                [xdata, ydata]  = computeRaster(sps{iNSE,itrial}, itrial);
                [trialdata]     = computeHistogram(sps{iNSE,itrial}, tlim.extract(1):tlim.extract(end), 100);
                
                plotDataX{iNSE} = [plotDataX{iNSE}; xdata(:)];
                plotDataY{iNSE} = [plotDataY{iNSE}; ydata(:)];
                
                histos(iNSE, itrial, 1:length(trialdata)) = trialdata;
                
            end
        end
    end
    
    %% plot stability for all channels before time window correction
    if plot_stability
        for iarea = 1:length(areaTXT)
            [tmp, ~] = chanInclusion(penInfo, target_path, areaTXT{iarea}, 'ALL');
            
            chan2use = ismember(chans,tmp);
            
            savefigname = [fig_path areaTXT{iarea} '_stability_trial(all)'];
            
            plotRaster(sps(chan2use,:), ...
                tlim.extract(1):1:tlim.extract(2) , SET.binSize, ...
                'laminar_stability',...
                {'plothisto', false ; 'smoothHisto', true ; 'allTr' , allTr ; 'savefigname', savefigname})
            
            
        end
    end
    
    %% Plot stability based on MUA, MUAe and LFP
    
    if plot_stability
        times = tlim.extract(1):tlim.extract(end);
        
        col     = distinguishable_colors(length(NSEPaths));
        
        XLIM    = tlim.extract;
        
        trialInclusion = false(length(NSEPaths), length(allTr));
        
        fig2 = figure(2);clf
            set(gcf,'position',[-1192 323 921 746],'visible',plot_visible)
%         set(gcf,'position',[1050 504 754 589],'visible',plot_visible)
        
        ncol = 6;
        nrow = 1;
        
        meanAct = NaN(length(NSEPaths),1);
        stdAct = NaN(length(NSEPaths),1);
%         trialExl = false(length(NSEPaths), length(allTr));
        %%
%                 chan2adjust = 2;
%                 trialInclusion(chan2adjust,:) = false;
%         
        
        %
%                 for iNSE = chan2adjust:length(NSEPaths)
        for iNSE = 1:length(NSEPaths)
            disp(['checking channel ' num2str(chans(iNSE))])

            SNR = computeSNR(allMUAe(iNSE,:,:), MuaeTimestamps);

            
            fig1 = figure(1); clf
            set(gcf,'position',[11 83 1883 1042],'visible',plot_visible)
            suptitle(['channel ' num2str(chans(iNSE)) ', SNR = ' num2str(SNR, '%1.2f')])
            %%% plot all MUA data
            %     currsubplot = iNSE * 2 - 1;
            currsubplot = 1;
            test = subplot(nrow,ncol, currsubplot);
            plot(plotDataX{iNSE}, plotDataY{iNSE}, 'color', 'k')
            
            xlim(XLIM)
            ylim([1 length(allTr)])
            xlabel('time (ms), stim-locked')
            ylabel('#trials')
            title('MUA')
            
            %%% plot spontaneous, stimulus induced and sustained activity
            test2 = subplot(nrow,ncol, currsubplot+1);
            
            hold on
            tIdx.spontaneous    = (times > tlim.spontaneous(1)  & times < tlim.spontaneous(2));
            tIdx.stim           = (times > tlim.stim(1)         & times < tlim.stim(2));
            tIdx.sustained      = (times > tlim.sustained(1)    & times < tlim.sustained(2));
            
            histo2plot.spontaneous  = squeeze(mean(histos(iNSE,:,tIdx.spontaneous),3));
%             histo2plot.stim         = squeeze(mean(histos(iNSE,:,tIdx.stim),3));
%             histo2plot.sustained    = squeeze(mean(histos(iNSE,:,tIdx.sustained),3));
            
%             histo2plot.spontaneous  = gaussfit(3,0,histo2plot.spontaneous);
%             histo2plot.stim         = gaussfit(3,0,histo2plot.stim);
%             histo2plot.sustained    = gaussfit(3,0,histo2plot.sustained);
            
            HistoEnergies_baseline  = squeeze(sum(abs(histos(iNSE,:,tIdx.spontaneous)).^2,3));
%             HistoEnergies_stim      = squeeze(sum(abs(histos(iNSE,:,tIdx.stim)).^2,3));
%             HistoEnergies_sust      = squeeze(sum(abs(histos(iNSE,:,tIdx.sustained)).^2,3));
            
            
            %         plot(histo2plot.spontaneous,    1:length(histo2plot.spontaneous), 'm')
            %         plot(histo2plot.stim,           1:length(histo2plot.stim), 'r')
            %         plot(histo2plot.sustained,      1:length(histo2plot.sustained), 'b')
            plot(histo2plot.spontaneous,    1:length(histo2plot.spontaneous), 'm')
            %         plot(HistoEnergies_stim,           1:length(histo2plot.stim), 'r')
            %         plot(HistoEnergies_sust,      1:length(histo2plot.sustained), 'b')
            
            ylim([1 length(allTr)])
            xlabel('average MUA')
            title('MUA energy')
            
            %%% plot MUAe data
            test3 = subplot(nrow,ncol, currsubplot+2);
            imagesc(MuaeTimestamps, 1:length(allTr), squeeze(allMUAe(iNSE,:,:)))
            xlim(XLIM)
            ylim([1 length(allTr)])
            axis xy
            
            xlabel('time (ms), stim-locked')
            title('MUAe')
            
            % MUAe TIMESTAMPS
            MUAe_baseline_idx(1)  = find(MuaeTimestamps>=tlim.spontaneous(1),1,'first');
            MUAe_baseline_idx(2)  = find(MuaeTimestamps>=tlim.spontaneous(2),1,'first');
            
            MUAe_stim_idx(1)  = find(MuaeTimestamps>=tlim.stim(1),1,'first');
            MUAe_stim_idx(2)  = find(MuaeTimestamps>=tlim.stim(2),1,'first');
            
            MUAe_sust_idx(1)  = find(MuaeTimestamps>=tlim.sustained(1),1,'first');
            MUAe_sust_idx(2)  = find(MuaeTimestamps>=tlim.sustained(2),1,'first');
            
            Muaes_baseline  = squeeze(mean(allMUAe(iNSE,:,MUAe_baseline_idx(1):MUAe_baseline_idx(2)),3));
            Muaes_stim      = squeeze(mean(allMUAe(iNSE,:,MUAe_stim_idx(1):MUAe_stim_idx(2)),3));
            Muaes_sust      = squeeze(mean(allMUAe(iNSE,:,MUAe_sust_idx(1):MUAe_sust_idx(2)),3));
            
            MuaesEnergies_baseline  = squeeze(sum(abs(allMUAe(iNSE,:,MUAe_baseline_idx(1):MUAe_baseline_idx(2))).^2,3));
            MuaesEnergies_stim      = squeeze(sum(abs(allMUAe(iNSE,:,MUAe_stim_idx(1):MUAe_stim_idx(2))).^2,3));
            MuaesEnergies_sust      = squeeze(sum(abs(allMUAe(iNSE,:,MUAe_sust_idx(1):MUAe_sust_idx(2))).^2,3));
            
            Muaes_baseline  = gaussfit(3,0,Muaes_baseline);
            Muaes_stim      = gaussfit(3,0,Muaes_stim);
            Muaes_sust      = gaussfit(3,0,Muaes_sust);
            
            
            
            
            %     MuaesEnergies_baseline  = gaussfit(3,0,MuaesEnergies_baseline);
            %     MuaesEnergies_stim      = gaussfit(3,0,MuaesEnergies_stim);
            %     MuaesEnergies_sust      = gaussfit(3,0,MuaesEnergies_sust);
            %
            %     MuaesEnergies_baseline    = scaleVar(MuaesEnergies_baseline, 'max');
            %     MuaesEnergies_stim        = scaleVar(MuaesEnergies_stim, 'max');
            %     MuaesEnergies_sust        = scaleVar(MuaesEnergies_sust, 'max');
            %
            
            
            test4 = subplot(nrow,ncol, currsubplot+3);
            hold on
            plot(MuaesEnergies_baseline,  1:length(Muaes_baseline), 'm')
            %         plot(MuaesEnergies_stim,      1:length(Muaes_baseline), 'r')
            %         plot(MuaesEnergies_sust,      1:length(Muaes_baseline), 'b')
            ylim([1 length(allTr)])
            xlabel('average MUAe')
            title('MUAe energy')
            
            
            %%%%%%% LFP
            test5 = subplot(nrow,ncol, currsubplot+4);
            imagesc(LFPTimestamps, 1:length(allTr), squeeze(allLFP(iNSE,:,:)))
            xlim(XLIM)
            ylim([1 length(allTr)])
            axis xy
            
            xlabel('time (ms), stim-locked')
            title('raw LFP')
            
            LFP_baseline_idx(1)  = find(LFPTimestamps>=tlim.spontaneous(1),1,'first');
            LFP_baseline_idx(2)  = find(LFPTimestamps>=tlim.spontaneous(2),1,'first');
            
            LFP_stim_idx(1)  = find(LFPTimestamps>=tlim.stim(1),1,'first');
            LFP_stim_idx(2)  = find(LFPTimestamps>=tlim.stim(2),1,'first');
            
            LFP_sust_idx(1)  = find(LFPTimestamps>=tlim.sustained(1),1,'first');
            LFP_sust_idx(2)  = find(LFPTimestamps>=tlim.sustained(2),1,'first');
            
            LFP_baseline  = squeeze(mean(allLFP(iNSE,:,LFP_baseline_idx(1):LFP_baseline_idx(2)),3));
            LFP_stim      = squeeze(mean(allLFP(iNSE,:,LFP_stim_idx(1):LFP_stim_idx(2)),3));
            LFP_sust      = squeeze(mean(allLFP(iNSE,:,LFP_sust_idx(1):LFP_sust_idx(2)),3));
            
            LFPEnergies_baseline  = squeeze(sum(abs(allLFP(iNSE,:,LFP_baseline_idx(1):LFP_baseline_idx(2))).^2,3));
            LFPEnergies_stim      = squeeze(sum(abs(allLFP(iNSE,:,LFP_stim_idx(1):LFP_stim_idx(2))).^2,3));
            LFPEnergies_sust      = squeeze(sum(abs(allLFP(iNSE,:,LFP_sust_idx(1):LFP_sust_idx(2))).^2,3));
            
            LFP_baseline  = gaussfit(3,0,LFP_baseline);
            LFP_stim      = gaussfit(3,0,LFP_stim);
            LFP_sust      = gaussfit(3,0,LFP_sust);
            
            LFPEnergies_baseline  = gaussfit(3,0,LFPEnergies_baseline);
            LFPEnergies_stim      = gaussfit(3,0,LFPEnergies_stim);
            LFPEnergies_sust      = gaussfit(3,0,LFPEnergies_sust);
            %
            %     MuaesEnergies_baseline    = scaleVar(MuaesEnergies_baseline, 'max');
            %     MuaesEnergies_stim        = scaleVar(MuaesEnergies_stim, 'max');
            %     MuaesEnergies_sust        = scaleVar(MuaesEnergies_sust, 'max');
            %
            
            
            test6 = subplot(nrow,ncol, currsubplot+5);
            hold on
            h = plot(LFPEnergies_baseline,  1:length(LFP_baseline), 'm');
            %         h(2) = plot(LFPEnergies_stim,      1:length(LFP_stim), 'r');
            %         h(3) = plot(LFPEnergies_sust,      1:length(LFP_sust), 'b');
            %         legend(h,{'spont','stim','sust'})
            ylim([1 length(allTr)])
            xlabel('average LFP')
            title('LFP energy')
            
            
            %     c = 0;
            %     figure(fig1)
            c   = uicontrol(fig1, 'Style', 'pushbutton', 'String', 'Start/Continue', 'Value',1,'Position', [20 840 100 50],'Callback','uiresume(gcbf)');
            c2  = uicontrol(fig1, 'Style', 'pushbutton', 'String', 'Exit', 'Value',1, 'Position', [20 770 100 50],'Callback','uiresume(gcbf)');
            c3  = uicontrol(fig1, 'Style', 'pushbutton', 'String', 'ResetLine', 'Value',1,'Position', [20 700 100 50],'Callback','uiresume(gcbf)');
            c4  = uicontrol(fig1, 'Style', 'pushbutton', 'String', 'ResetAll', 'Value',1,'Position', [20 630 100 50],'Callback','uiresume(gcbf)');
            c5  = uicontrol(fig1, 'Style', 'pushbutton', 'String', 'selectAll', 'Value',1,'Position', [20 560 100 50],'Callback','uiresume(gcbf)');
%             c6  = uicontrol(fig1, 'Style', 'pushbutton', 'String', 'SNR', 'Value',1,'Position', [20 490 100 50],'Callback','uiresume(gcbf)');
            
            iloop = 0;
            clear h1 h2 h3
            while (c2.Value==1) && (c.Value==1)
                iloop = iloop+1;
                figure(fig1)
                
                if iloop==1
                    uiwait(fig1) % press either continue, exit or selectAll
                    
                end
                
                if c5.Value == 0
                    tmp = [1 length(allTr)];
                    
                    c2.Value = 0;
                elseif c2.Value == 0
                    tmp = [NaN NaN];
                else
                    [~, Y] = ginput(2);
                    
                    tmp = [floor(Y(1)) ceil(Y(2))];
                    tmp(tmp<0) = 1;
                    tmp(tmp>length(allTr)) = length(allTr);
                    
                end
                
                subplot(test)
                hold on
                if isempty(find(isnan(tmp)))
                    h1(iloop) = plot([XLIM(1) XLIM(1)]+5, tmp, 'linewidth', 5, 'color', [0.5 0 0 0.5]);
                    
                    
                    tmpSNR = computeSNR(allMUAe(iNSE,tmp(1):tmp(2),:), MuaeTimestamps);
                    disp(['trial window ' num2str(tmp(1)) '-' num2str(tmp(2)) ', SNR = ' num2str(tmpSNR)])

                    meanAct(iNSE,1) = mean(histo2plot.spontaneous(tmp(1):tmp(2)));
                    stdAct(iNSE,1) = std(histo2plot.spontaneous(tmp(1):tmp(2)));
                    fprintf('mean activity %1.2f, +/- %1.2f\n',meanAct(iNSE,1),stdAct(iNSE,1))
                    
                    switch SET.recordingStability.method
                        case 'cutPeriod'
                            trialInclusion(iNSE,tmp(1):tmp(2)) = true;
                        case 'trialExclusion'
                            cutoff = [meanAct(iNSE,1) - 3*stdAct(iNSE,1) meanAct(iNSE,1) + 3*stdAct(iNSE,1)];
                            trialInclusion(iNSE,histo2plot.spontaneous >= cutoff(1) & histo2plot.spontaneous <= cutoff(2)) = true;
                    end
                end
                
                figure(fig2)
                subplot(2,1,2)
                hold on
                
                h2(iloop) = plotBrokenVector(1:length(allTr), iNSE, trialInclusion(iNSE,:), 'color', col(iNSE,:), 'linewidth', 4);

                xlim([1 length(allTr)])
                ylim([1 length(NSEPaths)])
                xlabel('# trial')
                ylabel('# chan')
                title('included trials per chan')
                subplot(2,1,1)
                hold on
                h3(iloop) = plot(1:length(allTr), sum(trialInclusion), 'color', col(iNSE,:), 'linewidth', 2);
                xlim([1 length(allTr)])
                ylim([1 length(NSEPaths)])
                title('number of channels of which trials are included')
                
                figure(fig1)
                uiwait(fig1) % press either continue or exit
                %             c.Value
                %             c2.Value
                if c.Value==0
                    c.Value=1;
                end
                
                if c3.Value == 0;
                    trialInclusion(iNSE,tmp(1):tmp(2)) = false;
                    
                    delete(h1(iloop))
                    delete(h2(iloop))
                    delete(h3(iloop))
                    c3.Value = 1;
                    
                end
                
                if c4.Value == 0;
                    trialInclusion(iNSE,:) = false;
                    
                    for iiloop = 1:iloop
                        delete(h1(iiloop))
                        delete(h2(iiloop))
                        delete(h3(iiloop))
                    end
                    c4.Value = 1;
                end
%                 if c6.Value == 0;
%                     trialLim(iNSE,:) = false;
%                     
%                     
%                     c6.Value = 0;
%                     
%                     uiwait(fig1) % 
% 
%                 end
            end
            
            
            figure(fig1)
            [~,tmp,~] = fileparts(NSEPaths{iNSE});
            savefigname = ['stability_' tmp '_' SET.recordingStability.method];
            saveas(fig1, [fig_path savefigname '.fig']);
            saveas(fig1, [fig_path savefigname '.png']);
        end
        
        figure(fig2)
        savefigname = ['stability_allChan_' SET.recordingStability.method ];
        saveas(fig2, [fig_path savefigname '.fig']);
        saveas(fig2, [fig_path savefigname '.png']);
        
        
        %%
        
        chan2exclude = chans(find(sum(trialInclusion,2)==0)); % exclude channels that don't have stable periods.
        
        trialLimAllChan = (sum(trialInclusion) == (length(NSEPaths) - length(chan2exclude))); % for which trials do all channels have stable periods
        trialsIncluded = [allTr(trialLimAllChan).trial];
        [trialWindows, durations] = getDuration(trialLimAllChan); % what are the durations of the stable periods?
        [~,idx] = max(durations);
        selectedTrialWindow = trialWindows(idx,:);
        
        PenTimeWindow = [allTr(trialWindows(idx,1)).evnt_t_orig(1) allTr(trialWindows(idx,2)).evnt_t_orig(end)];
        
        % redo figure 2
        figure(fig2),clf
        
        subplot(2,1,2)
        hold on
        for iNSE = 1:length(NSEPaths)
            plotBrokenVector(1:length(allTr), iNSE, trialInclusion(iNSE,:), 'color', col(iNSE,:), 'linewidth', 4);
        end
        xlim([1 length(allTr)])
        ylim([1 length(NSEPaths)])
        xlabel('# trial')
        ylabel('# chan')
        title('included trials per chan')
        subplot(2,1,1)
        hold on
        for iNSE = 1:length(NSEPaths)
            plot(1:length(allTr), sum(trialInclusion(1:iNSE,:)), 'color', col(iNSE,:), 'linewidth', 2)
        end
        xlim([1 length(allTr)])
        ylim([1 length(NSEPaths)])
        title('number of channels of which trials are included')
        
        savefigname = ['stability_allChan'  ];
        saveas(fig2, [fig_path savefigname '.fig']);
        saveas(fig2, [fig_path savefigname '.png']);
        
        save([target_path savefilename],'PenTimeWindow','selectedTrialWindow','trialWindows','trialsIncluded','durations','chan2exclude','trialLimAllChan','trialInclusion','chans','NSEPaths','SET')
        
        
        
        %% plot stability for all channels after time window correction
        for iarea = 1:length(areaTXT)
            [tmp, ~] = chanInclusion(penInfo, target_path, areaTXT{iarea}, 'ALL');
            
            chan2use = ismember(chans,tmp);
            
            savefigname = [fig_path areaTXT{iarea} '_stability_trial(' num2str(selectedTrialWindow(1)) '_' num2str(selectedTrialWindow(2)) ')' '_' SET.recordingStability.method];
            
            plotRaster(sps(chan2use,trialLimAllChan), ...
                tlim.extract(1):1:tlim.extract(2) , SET.binSize, ...
                'laminar_stability',...
                {'plothisto', false ; 'smoothHisto', true ; 'allTr' , allTr(trialLimAllChan) ; 'savefigname', savefigname})
            
            
        end
    

    end
end
%
%
%
%
%

% V1chans = chans(~(chans>16))
% 
% imagesc(LFPTimestamps, 1:length(allTr), squeeze(allLFP(iNSE,:,:)))
% tmp = [1 length(allTr)]
% [CsdSamples, CsdTimestamps, CsdPositions] = getCsd_JvK(allLFP(V1chans,:,:), LFPTimestamps, 0.150, tmp)
% 
% 
% [CsdSamples, CsdTimestamps, CsdPositions] = getCsd_JvK(LfpData, LfpTimestamps, contactSpacing, TrialRanges)



%%

% %%% get
% keyboard
% figure
% plot(MuaeTimestamps,squeeze(mean(allMUAe,2)))
%
% % MUAe TIMESTAMPS
% MUAe_baseline_idx(1)  = find(MuaeTimestamps>=MUAe_baseline(1),1,'first');
% MUAe_baseline_idx(2)  = find(MuaeTimestamps>=MUAe_baseline(2),1,'first');
%
% MUAe_stim_idx(1)  = find(MuaeTimestamps>=MUAe_stim(1),1,'first');
% MUAe_stim_idx(2)  = find(MuaeTimestamps>=MUAe_stim(2),1,'first');
%
% MUAe_sust_idx(1)  = find(MuaeTimestamps>=MUAe_sust(1),1,'first');
% MUAe_sust_idx(2)  = find(MuaeTimestamps>=MUAe_sust(2),1,'first');
%
% Muaes_baseline  = sum(squeeze(allMUAe(:,:,MUAe_baseline_idx(1):MUAe_baseline_idx(2))),3);
% Muaes_stim  = sum(squeeze(allMUAe(:,:,MUAe_stim_idx(1):MUAe_stim_idx(2))),3);
% Muaes_sust  = sum(squeeze(allMUAe(:,:,MUAe_sust_idx(1):MUAe_sust_idx(2))),3);
% MuaesNormalised_baseline    = scaleVar(MuaesEnergies_baseline, 'minmaxdim', 1);
% MuaesNormalised_stim    = scaleVar(Muaes_stim, 'minmaxdim', 1);
% MuaesNormalised_sust    = scaleVar(Muaes_sust, 'minmaxdim', 1);
%
% % get energy
% MuaesEnergies_baseline  = sum(abs(squeeze(allMUAe(:,:,MUAe_baseline_idx(1):MUAe_baseline_idx(2)))).^2,3);
% MuaesEnergies_stim      = sum(abs(squeeze(allMUAe(:,:,MUAe_stim_idx(1):MUAe_stim_idx(2)))).^2,3);
% MuaesEnergies_sust      = sum(abs(squeeze(allMUAe(:,:,MUAe_sust_idx(1):MUAe_sust_idx(2)))).^2,3);
%
% MuaesEnergiesNormalised_baseline    = scaleVar(MuaesEnergies_baseline, 'maxdim', 1);
% MuaesEnergiesNormalised_stim        = scaleVar(MuaesEnergies_stim, 'maxdim', 1);
% MuaesEnergiesNormalised_sust        = scaleVar(MuaesEnergies_sust, 'maxdim', 1);
%
%
% %         % normalise
% %         MuaesNormalised_baseline    = MuaesEnergies_baseline ./ repmat(max(MuaesEnergies_baseline,[],2), 1,size(MuaesEnergies_baseline,2));
% %         MuaesNormalised_stim        = MuaesEnergies_stim ./ repmat(max(MuaesEnergies_stim,[],2), 1,size(MuaesEnergies_stim,2));
% %         MuaesNormalised_sust        = MuaesEnergies_sust ./ repmat(max(MuaesEnergies_sust,[],2), 1,size(MuaesEnergies_sust,2));
%
% % smooth
% MuaesSmooth_baseline    = reshape(smooth(MuaesEnergiesNormalised_baseline',20), size(MuaesEnergiesNormalised_baseline,2), size(MuaesEnergiesNormalised_baseline,1) )';
% MuaesSmooth_stim    	= reshape(smooth(MuaesEnergiesNormalised_stim',20), size(MuaesEnergiesNormalised_stim,2), size(MuaesEnergiesNormalised_stim,1) )';
% MuaesSmooth_sust        = reshape(smooth(MuaesEnergiesNormalised_sust',20), size(MuaesEnergiesNormalised_sust,2), size(MuaesEnergiesNormalised_sust,1) )';
%
% %% Based on difference between subsequent channels
% CRITERIA = 0.025 % for smoothed
% CRITERIA = 0.4
% TrialWin1 = zeros(length(NCSPaths),2);
% figure(1),clf
% hold on
% allConsistent = zeros(1, length(allTr));
% for iNCS = 1:length(NCSPaths)
%     chanConsistent = zeros(1, length(allTr));
%
%     CRITERIA = mean(diff(MuaesNormalised_sust(iNCS,:))) + std(diff(MuaesNormalised_sust(iNCS,:)))
%
%     vec = abs(diff(squeeze(MuaesNormalised_sust(iNCS,:)))) < CRITERIA;
%
%     isConstant = vec==1;
%     inconsistent = abs([0 isConstant(2:end)-isConstant(1:end-1) 0]);
%
%     trials = 1:length(allTr);
%     consistentWindows = [1 length(allTr)]; % if there are no inconsistencies, the consistent duration is the whole recording
%     if (any(inconsistent))
%         inconsistentTrials = sort([1 trials(inconsistent==1) trials(inconsistent==1) length(allTr)]);
%
%         consistentWindows   = reshape(inconsistentTrials, 2, length(inconsistentTrials)/2)';
%         consistentDurations = consistentWindows(:,2) - consistentWindows(:,1);
%
%         consistentWindows(consistentDurations<20,:)=[];
%
%     end
%     plot(consistentWindows, [iNCS iNCS])
%
%     for iconst = 1:size(consistentWindows,1)
%         chanConsistent(consistentWindows(iconst,1):consistentWindows(iconst,2)) = 1;
%     end
%
%     allConsistent = allConsistent + chanConsistent;
%
% end
%
% figure(2)
% plot(allConsistent)
%
% isConstant = (allConsistent == length(NCSPaths));
%
% inconsistent = (abs(diff(isConstant))==1);
%
% trIdx = trials(inconsistent==1)+1;
% inconsistentTrials = sort([trIdx trIdx(2:end-1)]);
%
% consistentWindows   = reshape(inconsistentTrials, 2, length(inconsistentTrials)/2)';
% consistentDurations = consistentWindows(:,2) - consistentWindows(:,1);
% [~,idx] = max(consistentDurations);
% trwindow = consistentWindows(idx,:);
% timewindow = [allTr(trwindow(1)).evnt_t_orig(1) allTr(trwindow(2)).evnt_t_orig(1)] + [-1500 1500];
%
% save(savefigname, 'trwindow','timewindow','allConsistent')
%
% if 0
%     for iNCS = 1:length(NCSPaths)
%         figure(1),clf
%         suptitle(['channel ' num2str(iNCS)])
%
%         subplot(2,2,[1 3])
%         imagesc(MuaeTimestamps, 1:length(allTr), squeeze(allMUAe(iNCS,:,:)))
%         axis xy
%
%         subplot(2,2,[2 4])
%         hold on
%         plot(abs(diff(squeeze(MuaesNormalised_sust(iNCS,:)))), 1:length(allTr)-1)
%         %             plot(abs(diff(squeeze(MuaesSmooth_stim(iNCS,:)))), 1:length(allTr)-1)
%         %             plot(abs(diff(squeeze(MuaesSmooth_sust(iNCS,:)))), 1:length(allTr)-1)
%         %             plot((squeeze(MuaesNormalised_baseline(iNCS,:))), 1:length(allTr))
%         %             plot((squeeze(MuaesNormalised_stim(iNCS,:))), 1:length(allTr))
%         %             plot((squeeze(MuaesNormalised_sust(iNCS,:))), 1:length(allTr))
%
%         plot([CRITERIA CRITERIA],  [1 length(allTr)-1])
%         ylim([1 length(allTr)])
%         pause
%     end
% end
%
% %% based on regression over time, stable means no slope
%
% trWindow = 50;
% figure(1),clf
% hold on
% %     histo2plot.spontaneous(iNSE,:)
%
% for iNCS = 1:length(NCSPaths)
%
%     slope = zeros(1,length(allTr));
%     for itrial = 1:length(allTr)
%         trIdx = itrial + [-trWindow/2 trWindow/2];
%         trIdx(trIdx<1) = 1;
%         trIdx(trIdx>length(allTr)) = length(allTr);
%         trIdx = trIdx(1):trIdx(2);
%
%         coef = polyfit(trIdx,histo2plot.spontaneous(iNCS,trIdx),1);
%         slope(itrial)=coef(1);
%
%         %                 designM = [ones(length(trIdx),1) trIdx' ]; %
%         %
%         %                 [b, ~, resid] = regress(MuaesNormalised_baseline(iNCS,trIdx)', designM);
%         %
%         %                 lm = regress([trIdx(1):trIdx(2)]', MuaesNormalised_baseline(iNCS,trIdx(1):trIdx(2)))
%
%     end
%     subplot(2,1,1)
%     plot(1:length(allTr), histo2plot.spontaneous(iNCS,:), '.')
%     subplot(2,1,2)
%     plot(1:length(allTr), slope, '.','color','r')
%
% end
%
%
%
%

%%% extra functions

function NCSPaths = getNCSPaths(NLX_path, chans)
for i=1:length(chans)
    NCSPaths{i,1} = fullfile(NLX_path,sprintf('CSC%u.ncs',chans(i)));
    %     NSEpaths{i,1} = fullfile(targetDir,sprintf('e1SE%u.nse',i));
end
%     end
%
function NSEPaths = getNSEPaths(NLX_path, chans, CAR_correction)
% ext = '';
ext = ['_CAR(' CAR_correction ')'];
for i=1:length(chans)
    NSEPaths{i,1} = fullfile(NLX_path,sprintf('SE%u%s_R.nse',chans(i),ext));
    %     NSEpaths{i,1} = fullfile(targetDir,sprintf('e1SE%u.nse',i));
end
%     end

function MUAePaths = getMUAePaths(target_path, chans, CAR_correction)
ext = '';
if CAR_correction
    ext = '_CAR';
end
for i=1:length(chans)
    MUAePaths{i,1} = fullfile(target_path,sprintf('MUAe%u%s.ncs',chans(i),ext));
    %     NSEpaths{i,1} = fullfile(targetDir,sprintf('e1SE%u.nse',i));
end
%     end

% function plot_stabilityRaster(PlotDataX, PlotDataY, histos, allTr, savefilename, smoothHisto, plot_visible)
% %     plot the subplots and the raster plots
% y_off=0;
% 
% [numchan, numtrial, time ] = size(histos);
% 
% figure(1),clf
% set(gcf,'position',[126 158 1642 964],'visible',plot_visible)
% 
% XLIM    = [-100 300];
% col     = [0.0 0.0 0.0];
% 
% tlim.spontaneous  = [-100 20];
% tlim.stim         = [-30 100];
% tlim.sustained    = [100 300];
% 
% times = histo.t_stim;
% 
% for ichan = 1:numchan
%     
%     
%     currsubplot = ichan * 2 - 1;
%     test = subplot(4,8, currsubplot);
%     plot(PlotDataX{ichan}, PlotDataY{ichan}+y_off, 'color', col)
%     xlim(XLIM)
%     ylim([1 numtrial])
%     
%     test2 = subplot(4,8, currsubplot + 1);
%     hold on
%     
%     tIdx.spontaneous    = (times > tlim.spontaneous(1)  & times < tlim.spontaneous(2));
%     tIdx.stim           = (times > tlim.stim(1)         & times < tlim.stim(2));
%     tIdx.sustained      = (times > tlim.sustained(1)    & times < tlim.sustained(2));
%     
%     histo2plot.spontaneous  = squeeze(mean(histos(ichan,:,tIdx.spontaneous),4));
%     histo2plot.stim         = squeeze(mean(histos(ichan,:,tIdx.stim),4));
%     histo2plot.sustained    = squeeze(mean(histos(ichan,:,tIdx.sustained),4));
%     
%     if smoothHisto
%         histo2plot.spontaneous  = gaussfit(10,0,histo2plot.spontaneous');
%         histo2plot.stim         = gaussfit(10,0,histo2plot.stim');
%         histo2plot.sustained    = gaussfit(10,0,histo2plot.sustained');
%     end
%     
%     plot(histo2plot.spontaneous,    1:length(histo2plot.spontaneous), 'm')
%     plot(histo2plot.stim,           1:length(histo2plot.stim), 'r')
%     plot(histo2plot.sustained,      1:length(histo2plot.sustained), 'b')
%     
%     ylim([1 numtrial])
%     
% end

saveas(gcf, savefilename, figext);

