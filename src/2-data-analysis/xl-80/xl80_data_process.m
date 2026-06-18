%[text] # 处理XL-80导出的数据
filePath = "D:\WorkingDir\Experiments\202406-mms-dynamics\xl80 results\20240530 xl80\XD-Y0_A3J80.csv";
fid = fopen(filePath);
for ii = 1:100
    tline = fgetl(fid);
    if contains(tline,'Time,Measurement')
        break;
    end
end

% 设置导入选项并导入数据
opts = detectImportOptions(filePath,"FileType","delimitedtext","NumHeaderLines",ii - 1);

xl80Data = readtable(filePath,opts);

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline","rightPanelPercent":40}
%---
