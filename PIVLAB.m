classdef PIVLAB

    properties
        directory
        files
        options
    end

    methods
        function obj = PIVLAB(directory,args)
            arguments
                directory                
                args.options (1,1) pivlab.options =pivlab.options
            end
            obj.directory = directory;
            obj.files = obj.getFiles();
            obj.options = args.options;

        end

        function outT = analysis(obj)
            outT = obj.SetOuputDefault();
            [slicedfilename1, slicedfilename2] = obj.preloadImageNames();

            if obj.options.noCores > 1
            	if pivparpool('size')<obj.options.noCores
            		pivparpool('open',obj.options.noCores);
            	end

            	parfor i=1:size(slicedfilename1,2)  % index must increment by 1

            		[x, y, u, v, typevector,correlation_map] = ...
            			obj.analysisWrapper(slicedfilename1{i}, slicedfilename2{i}, false);
                    outT(i, :) = {x, y, u, v, typevector,correlation_map};
            	end
                ... Sequential loop
            else % sequential loop

            	for i=1:size(slicedfilename1,2)  % index must increment by 1

            		[x, y, u, v, typevector,correlation_map] = ...
            			obj.analysisWrapper(slicedfilename1{i}, slicedfilename2{i}, true);
                    outT(i, :) = {x, y, u, v, typevector,correlation_map};

            	end
            end
        end

    end

    methods (Access=private)
        function setupParellelProcessing(obj)
            if obj.options.noCores > 1
                try
                    local_cluster=parcluster('local'); % single node
                    corenum =  local_cluster.NumWorkers ; % fix : get the number of cores available
                catch
                    warning('on');
                    warning('parallel local cluster can not be created, assigning number of cores to 1');
                    obj.options.noCores = 1;
                end
            end
        end

        function outT = SetOuputDefault(obj)
            filenames = obj.files;
            amount = length(filenames);
            if obj.options.pairWise == 1
                if mod(amount,2) == 1 %Uneven number of images?
                    disp('Image folder should contain an even number of images.')
                    %remove last image from list
                    amount=amount-1;
                    filenames(size(filenames,1))=[];
                end

                disp(['Found ' num2str(amount) ' images (' num2str(amount/2) ' image pairs).'])
                x=cell(amount/2,1);
                y=x;
                u=x;
                v=x;
            else
                disp(['Found ' num2str(amount) ' images'])
                x=cell(amount-1,1);
                y=x;
                u=x;
                v=x;
            end

            typevector=x; %typevector will be 1 for regular vectors, 0 for masked areas
            correlation_map=x; % correlation coefficient

            outT = table(x,y,u,v, typevector, correlation_map);
        end

        function [slicedfilename1, slicedfilename2] = preloadImageNames(obj)

            filenames = obj.files;
            amount = length(filenames);
            if obj.options.pairWise == 1
                if mod(amount,2) == 1 %Uneven number of images?
                    disp('Image folder should contain an even number of images.')
                    %remove last image from list
                    amount=amount-1;
                    filenames(size(filenames,1))=[];
                end
            end
            filenames = obj.files;
            slicedfilename1=cell(0);
            slicedfilename2=cell(0);
            j = 1;
            for i=1:1+obj.options.pairWise:amount-1
                slicedfilename1{j}=filenames{i}; % begin
                slicedfilename2{j}=filenames{i+1}; % end
                j = j+1;
            end
        end

        function [x, y, u, v, typevector,correlation_map] = analysisWrapper(obj, slicedfilename1, slicedfilename2, graph)

            [pivSettings, preprocSettings] = obj.convertOptionstoCell();
            [x, y, u, v, typevector,correlation_map] = piv_analysis(obj.directory, slicedfilename1, slicedfilename2,preprocSettings,pivSettings,obj.options.noCores,graph);
        end
        function [pivSettings, preprocSettings] = convertOptionstoCell(obj)
            f = fields(obj.options);
            pivSettings = cell(15, 2);
            preprocSettings = cell(10,2);
            for idx = 1:15
                pivSettings{idx,1} = f{idx};
                pivSettings{idx,2} = obj.options.(f{idx});
            end
            preprocSettings{1,1} = f{5};
            preprocSettings{1,2} = obj.options.(f{5});
            for idx = 2:10
                preprocSettings{idx,1} = f{14+idx};
                preprocSettings{idx,2} = obj.options.(f{14+idx});
            end
        end

        function filenames = getFiles(obj)
            folder= obj.directory ; %directory containing the images you want to analyze
            % default directory: PIVlab/Examples

            suffix='*.jpg'; %*.bmp or *.tif or *.jpg or *.tiff or *.jpeg
            disp(['Looking for ' suffix ' files in the selected directory.']);
            direc = dir([folder,filesep,suffix]); filenames={};
            [filenames{1:length(direc),1}] = deal(direc.name);
            filenames = sortrows(filenames); %sort all image files
        end
    end

    methods (Static)

    end
end
