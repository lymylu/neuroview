function [informationtype, information, DataTaglist]=Taginfoappend(DataTaglist,option)
if nargin<2
    option=1;
end
check=0;
DataTaglistDlg=vertcat({'Add a new tag name:ֵ'}, DataTaglist);
while check==0
[output,check]=listdlg('PromptString','TagDefinedֵ','SelectionMode','Multiple','ListString', DataTaglistDlg);
if option==1 %tag/tagvalue
   if check==0
    informationtype=[]; information=[]; 
   elseif output==1
    NewTag=inputdlg('����һ���µı�ǩ��:ֵ, ��ǩ��(������Ӣ��)��ֵ���÷ֺŸ��������ֵ�ö��Ÿ���','New tag');
    try
        tmp = regexpi(NewTag{:},':','split');
        informationtype=tmp(1);
        information=tmp(2);
    catch
        disp('����ı�ǩ����ֵ�����Ϲ淶');
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
elseif option==2 % only tag
    information=[];
    if check==0
        informationtype=[]; 
    elseif output==1
        NewTag=inputdlg('Please input the tag name','New tag');
        informationtype=NewTag{:};
        DataTaglist=vertcat(DataTaglist,NewTag);
    else
        informationtype=DataTaglistDlg{output};
    end
end
end
end
