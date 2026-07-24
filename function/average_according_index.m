function datamean_all=average_according_index(datamatrix,indexgroup,dimension,blackindex)
    % average datamatrix from given dimensions according the corresponding
    % index group is logical ,[], or cell(logical)
    if nargin<4
        blackindex=[];
    end
    if ~iscell(indexgroup)
        indexgroup={indexgroup};
    end
    dimnum=ndims(datamatrix);
    if isa(dimnum,'tall')
        dimnum=gather(dimnum);
    end
    S.type='()';
    datamean_all = cell(length(indexgroup),1);
    noaverage=false;
    for j=1:length(indexgroup)
        for i = 1:dimnum
            if i==dimension
                if isempty(indexgroup{j})
                    if ~isempty(blackindex)
                        idx_cell{i}=~blackindex;
                    else
                        idx_cell{i}=':';
                    end 
                    noaverage=true;
                else
                     if ~isempty(blackindex)
                        idx_cell{i}=indexgroup{j}&~blackindex;
                     else
                        idx_cell{i}=indexgroup{j};
                     end
                end
                %idx_cell2{i}=j;
            else
                idx_cell{i} = ':';
                %idx_cell2{i}=1;
            end
        end
        S.subs=idx_cell;
       % S2.subs=idx_cell2;
       if ~noaverage
        datamean_all{j}=mean(subsref(datamatrix,S),dimension);
       else
           datamean_all{j}=subsref(datamatrix,S);
       end
    end
    datamean_all=cat(dimension,datamean_all{:});
    end