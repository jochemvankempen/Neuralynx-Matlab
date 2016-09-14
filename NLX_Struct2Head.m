function NLX = NLX_Struct2Head(NLX,s)

if isfield(s,'hash')
    NLX.Header = s.hash;
else
    NLX.Header{1,1} = '######## ';
    NLX.Header{2,1} = '## ';
    NLX.Header{3,1} = '## ';
    NLX.Header{4,1} = '## ';
end
n = length(NLX.Header);

HeaderProperties = fieldnames(s);
HeaderProperties(strcmp(HeaderProperties,'hash')) = [];
for i=1:length(HeaderProperties)
    if ischar(s.(HeaderProperties{i}))
        NLX.Header{n+i,1} = sprintf('-%s %s',HeaderProperties{i},s.(HeaderProperties{i}));
    elseif isnumeric(s.(HeaderProperties{i}))
        NLX.Header{n+i,1} = sprintf('-%s %s',HeaderProperties{i},num2str(s.(HeaderProperties{i})));
    end
end

