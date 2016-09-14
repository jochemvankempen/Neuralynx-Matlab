function s = NLX_readNSE(fPath)

% reads an *.NSE file using fread
% 1 Byte = 8 Bit
% 1 Kilobyte = 1024 Bytes
% 1 Megabyte = 1048576 Bytes
% 1 Gigabyte = 1073741824 Bytes

% open file
fid = fopen(fPath,'r');
HdBytes = 1024*16;
RecordBytes = (64 + 32 + 32 + 32*8 + 16*32)/8;
status = fseek(fid,0,'eof');
FileBytes = ftell(fid);
N = (FileBytes-HdBytes)/RecordBytes;

% allocation
s.Hd = '';
s.TimeStamp = zeros(N,1);
s.ScNr = zeros(N,1);
s.CellNr = zeros(N,1);
s.Params = zeros(N,8);
s.Data = zeros(N,32);

% reading the header
wbh = waitbar(0,'reading header');
status = fseek(fid,0,'bof');
s.Hd = fread(fid, 1024*16, 'uint8=>char')';

% reading data
status = fseek(fid,1024*16,'bof');
cnt = 0;
while cnt<N
    cnt = cnt+1;
    s.TimeStamp(cnt,1) = fread(fid,1,'uint64=>double');
    s.ScNr(cnt,1) = fread(fid,1,'uint32=>double');
    s.CellNr(cnt,1) = fread(fid,1,'uint32=>double');
    s.Params(cnt,:) = fread(fid,8,'int32=>double');
    s.Data(cnt,:) = fread(fid,32,'int16=>double');
    p = ftell(fid);
    waitbar(p/FileBytes,wbh,['reading data ' sprintf('%1.0f',cnt) ' of ' sprintf('%1.0f',N)]);
    if feof(fid)
        break;
    end
end
fclose(fid);
close(wbh);