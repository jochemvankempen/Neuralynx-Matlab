function [Hd,FileBytes] = NLX_readHeader(fPath)

% reads the 16kb ascii header only
% 1 Byte = 8 Bit
% 1 Kilobyte = 1024 Bytes
% 1 Megabyte = 1048576 Bytes
% 1 Gigabyte = 1073741824 Bytes

% open file
fid = fopen(fPath,'r');

% get size
status = fseek(fid,0,'eof');
FileBytes = ftell(fid);
status = fseek(fid,0,'bof');

% read header
Hd = '';
[Hd,Hdcount] = fread(fid, 1024*16, 'uint8=>char');
Hd = textscan(Hd,'%s','delimiter','\n');
Hd  = Hd{1};

% close file
fclose(fid);


% HdBytes = 1024*16;
% RecordBytes = (64 + 32 + 32 + 32*8 + 16*32)/8;
% N = (FileBytes-HdBytes)/RecordBytes;
