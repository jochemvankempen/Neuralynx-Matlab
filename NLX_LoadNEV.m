function NEV = NLX_LoadNEV(NEVpath,FieldOption,ExtractMode,ExtractArray)

% Loads a *.nse file into a matlab structure
%
% NEV = NLX_LoadNEV(NEVpath,FieldOption,ExtractMode,ExtractArray)
%
% INPUT:
% NEVpath ... full filepath, windows gui popup if empty
% FieldOption .... 'HEADER' - Only header
%                  'TTL' - Timestamps and TTL
%                  'TTL+' - Timestamps and TTL and EVENTSTRING
%                  'EVENTSTRING' - Timestamps and EVENTSTRING
%                  'FULL' - Loads the full file dataset
% ExtractMode .... 1 Extract All [] 
%                  2 Extract Record Index Range [1stRec-1 lastRec-1]
%                  3 Extract Record Index List [RecNr-1 ...] 
%                  4 Extract Timestamp Range [StartStamp EndStamp] 
%                  5 Extract Timestamp List [StampVal1 StampVal2 ...]
% ExtractArray ... Mode 1  [] 
%                  Mode 2  [1stRec-1 lastRec-1]
%                  Mode 3  [RecNr-1 ...] 
%                  Mode 4  [StartStamp EndStamp] 
%                  Mode 5  [StampVal1 StampVal2 ...]
%
% OUTPUT:
% NEV.Path ............ Full path of the original data file
% NEV.Header .......... Cellarray of strings [NumRows x 1], amplification
%                       parameter
% NEV.TimeStamps ...... [1 x NumEvents] microseconds (10^-6s)
% NEV.EventID ............ [1 x NumEvents] 
% NEV.TTL ....... [1 x NumEvents]
% NEV.Extras ... [8 x NumEvents] Featurvalues for each spike
% NEV.Eventstring ... [NumEvents x 1] cell array of strings

NEV.Path = '';
NEV.Header = [];
NEV.TimeStamps = [];
NEV.EventID = [];
NEV.TTL = [];
NEV.Extras = [];
NEV.Eventstring = {};

ExtractHeader = 1;

% check input
if nargin < 1 | isempty(NEVpath)
	[filename,pathname] = uigetfile('*.nev','load Neuralynx *.NEV data file');
	NEVpath = fullfile(pathname,filename);
	if ~filename;return;end
end
NEV.Path = NEVpath;
if nargin<2 | isempty(FieldOption);FieldOption = 'HEADER';end
if nargin<3 | isempty(ExtractMode);ExtractMode = 1;ExtractArray=[];end
if nargin<5 | isempty(EchoOff);EchoOff = 0;end

switch upper(FieldOption)
	case 'HEADER' ; FieldArray = [0 0 0 0 0];[NEV.Header] = Nlx2MatEV(NEVpath,FieldArray,ExtractHeader,ExtractMode,ExtractArray);
	case 'TTL' ; FieldArray = [1 0 1 0 0];[NEV.TimeStamps,NEV.TTL,NEV.Header] = Nlx2MatEV(NEVpath,FieldArray,ExtractHeader,ExtractMode,ExtractArray);
	case 'TTL+' ; FieldArray = [1 0 1 0 1];[NEV.TimeStamps,NEV.TTL,NEV.Eventstring,NEV.Header] = Nlx2MatEV(NEVpath,FieldArray,ExtractHeader,ExtractMode,ExtractArray);
	case 'EVENTSTRING' ; FieldArray = [1 0 0 0 1];[NEV.TimeStamps,NEV.Eventstring,NEV.Header] = Nlx2MatEV(NEVpath,FieldArray,ExtractHeader,ExtractMode,ExtractArray);
	case 'FULL' ; FieldArray = [1 1 1 1 1];[NEV.TimeStamps,NEV.EventID,NEV.TTL,NEV.Extras,NEV.Eventstring,NEV.Header] = Nlx2MatEV(NEVpath,FieldArray,ExtractHeader,ExtractMode,ExtractArray);
	otherwise
		FieldArray = [0 0 0 0 0];[NEV.Header] = Nlx2MatEV(NEVpath,FieldArray,ExtractHeader,1,ExtractArray);
end

NEV.TimeStamps = NEV.TimeStamps(:);
NEV.TTL = NEV.TTL(:);    
NEV.EventID = NEV.EventID(:);
NEV.Extras = NEV.Extras';

    
