function indexgroup =resolveindex(indexinput,indexdescription)
            % transfer indexinput to logical index according to
            % indexdescription
            % indexinput :  'none' -> [];
            % 'all'->:true(length(indexdescription))
          
            % 'str'->logical(ismember(indexdescription),str)
            % matrix,-> logical (matrix==true)
            % logical -> logical
            % cell input->recursive
              % 'separate' ->
              % obj=resolveindex(unique(indexdescription),indedescription)
              % cell('str')->obj=resolveindex(str,indedescription)
              %...
            if ischar(indexinput)
                if strcmp(indexinput,'all')
                    indexgroup=true(size(indexdescription));
                    return
                elseif strcmp(indexinput,'none')
                   indexgroup=[];
                elseif strcmp(indexinput,'separate')
                    indexgroup=cellfun(@(x) resolveindex(x,indexdescription),unique(indexdescription),'UniformOutput',0);
                else
                    indexgroup=ismember(indexdescription,indexinput);
                end
            elseif islogical(indexinput)
                indexgroup=indexinput;
            elseif isnumeric(indexinput)
                if length(indexinput)==2 && isnumeric(indexdescription) % for frequency band
                    indexgroup=false(size(indexdescription));
                    indexgroup(indexdescription>=indexinput(1)&indexdescription<=indexinput(2))=true;
                else
                     indexgroup=false(size(indexdescription));
                     indexgroup(indexinput)=true;
                end
            elseif iscell(indexinput)
                 indexgroup=cellfun(@(x) resolveindex(x,indexdescription),indexinput,'UniformOutput',0);
            end          
end
                                    



              