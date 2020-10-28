function [informationtype, information, DataTaglist]=Taginfoappend(DataTaglist)
check=0;
DataTaglistDlg=vertcat({'输出一个新的标签名:值'}, DataTaglist);
while check==0
[output,check]=listdlg('PromptString','选取一个标签名和值','SelectionMode','Multiple','ListString', DataTaglistDlg);
   if check==0
    informationtype=[]; information=[]; 
   elseif output==1
    NewTag=inputdlg('输入一个新的标签名:值, 标签名(必须是英文)和值间用分号隔开，多个值用逗号隔开','New tag');
    try
        tmp = regexpi(NewTag{:},':','split');
        informationtype=tmp(1);
        information=tmp(2);
    catch
        disp('输入的标签名：值不符合规范');
        informationtype=[];
        information=[];
        NewTag=[];
    end
        DataTaglist=vertcat(DataTaglist,NewTag);
   else
        tmp = cellfun(@(x) regexpi(x,':','split'),DataTaglistDlg(output),'UniformOutput',0);
        informationtype=cellfun(@(x) x{1}, tmp, 'UniformOutput',0);
        information=cellfun(@(x) x{2},tmp,'UniformOutput',0);
  end 
end
end
