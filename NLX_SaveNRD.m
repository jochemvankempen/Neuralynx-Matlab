function NRD = NLX_SaveNRD(NRD,AppendToFile,OverwriteFlag)

% Writes data to an *.NRD file
% NRDE ............ structure (see NLX_loadNRD.m)
% AppendToFile ... if is not set to 0 or 1, appends to an existing file

if nargin<3
    OverwriteFlag = 0;
end

if isempty(NRD.Path)
    [filename,pathname] = uiputfile('*.nrd','write to *.NRD file');
    if filename==0;return;end
    NRD.Path = fullfile(pathname,filename);
end

FileDoesExist = exist(NRD.Path,'file');

if nargin<2 || isempty(AppendToFile)
    AppendToFile = 0;
end

if OverwriteFlag~= 1 && FileDoesExist && AppendToFile==0
    % 	button = questdlg(['REPLACE ' strrep(strrep(NSE.Path,'_','\_'),'\','\\') ' ???']);
    button = questdlg(['REPLACE ' NRD.Path ' ???']);
    switch upper(button)
        case 'YES'
        case 'NO'
            [filename,pathname] = uiputfile('*.nrd','write to *.NRD file');
            if filename==0;return;end
            NRD.Path = fullfile(pathname,filename);
        case 'CANCEL';return;
        otherwise
            return;
    end
end

ChannelNumber = 0;
ExportMode = 1;
ExportModeVector = [1];
FieldSelectionFlags = [1 1 1];

Mat2NlxNRD(NRD.Path, ChannelNumber, AppendToFile, ...
    ExportMode,ExportModeVector, ...
    FieldSelectionFlags,NRD.TimeStamps(:)',NRD.Samples(:)',NRD.Header);