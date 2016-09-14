function NEV = NLX_SaveNEV(NEV,AppendToFile)

% Writes data to an *.NEV file
% NEV ............ structure (see NLX_loadNEV.m)
% AppendToFile ... if is not set to 0 or 1, appends to an existing file

if isempty(NEV.Path)
	[filename,pathname] = uiputfile('*.nev','write to *.NEV file');
	if filename==0;return;end
	NEV.Path = fullfile(pathname,filename);
end

if nargin<2 | isempty(AppendToFile)
	AppendToFile = 0;
end

if exist(NEV.Path) & AppendToFile==0
% 	button = questdlg(['REPLACE ' strrep(strrep(NEV.Path,'_','\_'),'\','\\') ' ???']);
	button = questdlg(['REPLACE ' NEV.Path ' ???']);
	switch upper(button)
		case 'YES'
		case 'NO'
			[filename,pathname] = uiputfile('*.nse','write to *.NEV file');
			if filename==0;return;end
			NEV.Path = fullfile(pathname,filename);
		case 'CANCEL';return;
		otherwise
			return;
	end
end

ExtractionMode = 1; % write all data to file
ExtractionModeArray = 1;
[NumEvents,FieldArray,FieldCells] = NLX_CheckNEV(NEV);

Mat2NlxEV(NEV.Path,AppendToFile,ExtractionMode,ExtractionModeArray,NumEvents,[FieldArray 1],FieldCells{:}, NEV.Header);
