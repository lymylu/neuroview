function [informationtype, information, DataTaglist]=Taginfoappend(DataTaglist)
check=0;
DataTaglistDlg=vertcat({'���һ���µı�ǩ��:ֵ'}, DataTaglist);
while check==0
[output,check]=listdlg('PromptString','ѡȡһ����ǩ����ֵ','SelectionMode','Multiple','ListString', DataTaglistDlg);
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
end
end
