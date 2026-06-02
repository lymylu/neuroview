function targetlist=getFromPath(p,ends,targetlist)
    filelist=dir(p);
    for i=3:length(filelist)
        if filelist(i).isdir
            targetlist=getFromPath(fullfile(filelist(i).folder,filelist(i).name),ends,targetlist);
        elseif endsWith(fullfile(filelist(i).folder,filelist(i).name),ends)
            targetlist=cat(1,targetlist,{fullfile(filelist(i).folder,filelist(i).name)});
        end
    end
end
