function h = NLX_plotTimestamps(NLX,i,yintcpt,varargin)


if nargin<2 || isempty(i)
    i = true(size(NLX.TimeStamps));
end

if nargin<3 || isempty(yintcpt)
    yintcpt = [0 1];
elseif length(yintcpt)==1
    yintcpt = [0 1];
end


[YDATA,XDATA] = ndgrid([yintcpt(1);yintcpt(2);NaN],NLX.TimeStamps(i));% TTL's dot as vertical lines
XDATA(3,:) = NaN;
h = line(XDATA(:),YDATA(:),'color','k','clipping','on',varargin{:});


