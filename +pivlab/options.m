classdef options < handle
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here

    properties (Access=public)
        noCores(1,1) int64
        filesRegExp(1,1) string
        files(:,1) string
    end

    methods
        function opt = options(args)
            arguments
                args.?options
            end
            % Set default arguments
            opt.noCores = 1;
            
            % Override the default arguments with custom inputs
            mFields = fields(args);
            if ~isempty(mFields)
                for idx = 1:numel(mFields)
                    opt.(mFields{idx}) = argStruct.(mFields{idx});
                end
            end
            
        end
    end
end

