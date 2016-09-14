function NCS = NLX_SaveNCS(NCS,AppendToFile)

% Writes data to an *.NCS file
% NCS ............ structure (see NLX_loadNCS.m)
% AppendToFile ... if is not set to 0 or 1, appends to an existing file

if isempty(NCS.Path)
	[filename,pathname] = uiputfile('*.NCS','write to *.NCS file');
	if filename==0;return;end
	NCS.Path = fullfile(pathname,filename);
end

if nargin<2 | isempty(AppendToFile)
	AppendToFile = 0;
end
if islogical(AppendToFile)
    AppendToFile = double(AppendToFile);
end

% check value range
ncsHeader = NLX_Head2Cell(NCS.Header);
headIndex = strcmp(ncsHeader(:,1),'ADMaxValue');
if any(headIndex)
    ADMaxValue = ncsHeader{headIndex,2};
    NCS.Samples(NCS.Samples>ADMaxValue) = ADMaxValue;
    NCS.Samples(NCS.Samples<-ADMaxValue) = -ADMaxValue;
else
    ADMaxValue = 32767;
    if any(NCS.Samples>ADMaxValue | NCS.Samples<-ADMaxValue)
        error('Values out of range!!!');
    end
end

if exist(NCS.Path,'file') && AppendToFile==0
% 	button = questdlg(['REPLACE ' strrep(strrep(NCS.Path,'_','\_'),'\','\\') ' ???']);
	button = questdlg(['REPLACE ' NCS.Path ' ???']);
	switch upper(button)
		case 'YES'
		case 'NO'
			[filename,pathname] = uiputfile('*.ncs','write to *.NCS file');
			if filename==0;return;end
			NCS.Path = fullfile(pathname,filename);
		case 'CANCEL';return;
		otherwise
			return;
	end
end

ExtractionMode = 1; % write all data to file
ExtractionModeArray = 1;
[NumSamples,FieldArray,FieldCells] = NLX_CheckNCS(NCS);

% this for Linux
% Mat2NlxCSC(NCS.Path,AppendToFile,ExtractionMode,ExtractionModeArray, ...
%     NumSamples, ...
%     [FieldArray 1], FieldCells{:}, ...
%     NCS.Header);

% this for windows
Mat2NlxCSC(NCS.Path,AppendToFile,ExtractionMode,ExtractionModeArray, ...
    [FieldArray 1], FieldCells{:}, ...
    NCS.Header);

