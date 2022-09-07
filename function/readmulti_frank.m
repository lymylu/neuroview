function [eeg,fb] = readmulti_frank(fname,numchannel,chselect,read_start,read_until,precision,b_skip)
% eeg is output, fb is size of file in bytes
% Reads multi-channel recording file to a matrix
% last argument is optional (if omitted, it will read all the 
% channels.
%
% From the Buzsaki lab (obtained 4/5/2010).
% revised by zifang zhao @ 2014-5-1 increased 2 input to
% control the range of file reading

if nargin<6 %precision and skip 
    precision='int16';
end
if nargin<7 %skip
    b_skip=0;
end
 fileinfo = dir(fname);
if nargin == 2
 datafile = fopen(fname,'r');
 eeg = fread(datafile,[numchannel,inf],'int16');
 fclose(datafile);
 eeg = eeg';
 return
end
fb=fileinfo(1).bytes;
numel_all=floor(fb/2/numchannel);
fb=numel_all*2*numchannel;
if nargin >= 3
 % the real buffer will be buffersize * numch * 2 bytes
 % (int16 = 2bytes)
 if nargin<4
     read_until=numel_all;
 end
 buffersize = 4096;
 % get file size, and calculate the number of samples per channel
 if read_start<0
     read_start=read_start+numel_all-1;
     if read_until==0
         read_until=numel_all;
     end
 end
 
read_start(read_start<0)=0;
read_until=read_until+1;
read_until(read_until>numel_all)=numel_all;
read_start_byte=read_start*2*numchannel;
read_until_byte=read_until*2*numchannel;
numel=read_until-read_start;
%  mmm = sprintf('%d elements',numel);
%  disp(mmm);  

 eeg=zeros(numel,length(chselect));
 
% tic
%% original method
numel1=0;
%  numelm=0;
datafile = fopen(fname,'r');
state= fseek(datafile,read_start_byte,'bof');
%  while ~feof(datafile),
 while ftell(datafile)<read_until_byte && ~feof(datafile) && state==0
     len_left=read_until_byte-ftell(datafile);
     if len_left>=buffersize*numchannel*2
         [data,count] = fread(datafile,[numchannel,buffersize],precision,b_skip);  %can be improved,vectorize,arrayfun,multi-threading, zifangzhao@4.24
     else
         [data,count] = fread(datafile,[numchannel,ceil(len_left/numchannel/2)],precision,b_skip);  %can be improved,vectorize,arrayfun,multi-threading, zifangzhao@4.24
     end
   numelm = (count/numchannel); %numelm = count/numchannel;
   if numelm > 0
%        if(numel+numelm)>size(eeg,2)
%        pause;
%        end
     eeg(numel1+1:numel1+numelm,:) = data(chselect,:)';
     numel1 = numel1+numelm;
   end
end
% toc

%  %% vectorize reading zifang zhao
% tic
% for idx=1:length(chselect)
%     fseek(datafile,(chselect(idx)-1)*2,'bof');
%     data=fread(datafile,ceil(fileinfo(1).bytes / 2 / numchannel),'int16',2*(numchannel-1));
%     eeg(idx,:)=data;
% end
% toc

end
fclose(datafile);
