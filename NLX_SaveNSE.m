function NSE = NLX_SaveNSE(NSE,AppendToFile,OverwriteFlag)

% Writes data to an *.NSE file
% NSE ............ structure (see NLX_loadNSE.m)
% AppendToFile ... if is not set to 0 or 1, appends to an existing file

if nargin<3
    OverwriteFlag = 0;
end

if isempty(NSE.Path)
	[filename,pathname] = uiputfile('*.nse','write to *.NSE file');
	if filename==0;return;end
	NSE.Path = fullfile(pathname,filename);
end

FileDoesExist = exist(NSE.Path,'file');

if nargin<2 || isempty(AppendToFile)
	AppendToFile = 0;
end

% value range
nseHeader = NLX_Head2Cell(NSE.Header);
headIndex = strcmp(nseHeader(:,1),'ADMaxValue');
if any(headIndex)
    ADMaxValue = nseHeader{headIndex,2};
    NSE.SpikeWaveForm(NSE.SpikeWaveForm>ADMaxValue)  = ADMaxValue;
    NSE.SpikeWaveForm(NSE.SpikeWaveForm<-ADMaxValue) = -ADMaxValue;
else
    ADMaxValue = 32767;
    if any(NSE.SpikeWaveForm(:)>ADMaxValue | NSE.SpikeWaveForm(:)<-ADMaxValue)
        error('Values out of range!!!');
    end
end

if OverwriteFlag~= 1 && FileDoesExist && AppendToFile==0
% 	button = questdlg(['REPLACE ' strrep(strrep(NSE.Path,'_','\_'),'\','\\') ' ???']);
	button = questdlg(['REPLACE ' NSE.Path ' ???']);
	switch upper(button)
		case 'YES'
		case 'NO'
			[filename,pathname] = uiputfile('*.nse','write to *.NSE file');
			if filename==0;return;end
			NSE.Path = fullfile(pathname,filename);
		case 'CANCEL';return;
		otherwise
			return;
	end
end

% make save for Linux MatToNLX writer
if isunix && FileDoesExist;
    fprintf('Unix detected, deleting existing version of %s ...',NSE.Path);
    delete(NSE.Path);
    fprintf('done\n');
end
                


ExtractionMode = 1; % write all data to file
ExtractionModeArray = 1;
[NumSpikes,FieldArray,FieldCells] = NLX_CheckNSE(NSE);

Mat2NlxSE(NSE.Path,AppendToFile,ExtractionMode,ExtractionModeArray,NumSpikes,[FieldArray 1],FieldCells{:}, NSE.Header);
