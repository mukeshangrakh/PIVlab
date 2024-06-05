classdef options < handle
    %pivlab.options class to create a pivlab options object.
    %   This class contains the piv image analysis configurations as its
    %   properties.

    properties (Access=public)
        noCores(1,1) int64
        filesRegExp(1,1) string
        files(:,1) string
        pairWise(1,1) logical
        windowSize(1,:) int64
        stepSize(1,1) double
        subPixelFinder(1,1) string
        roi(1,4) double
        windowDeformation(1,1) string 
        maskfile(1,1) string
        repeatCorrelation(1,1) logical
        autoCorrelation(1,1) logical
        correlationStyle(1,1) string {mustBeMember(correlationStyle,["Circular","Linear"])}
        multiplePass(1,1) logical
        qualitySlope(1,1) double
        clipping(1,1) logical
        contrastEnhancementWindow(1,1) double
        highPassWindow(1,1) double
        wienerWindow(1,1) double
        minIntensity(1,1) double
        maxIntensity(1,1) double
    end

    methods
        function obj = options(args)
            arguments
                args.?pivlab.options
            end
            % Set default arguments
            obj.noCores = 1;
            
            % Override the default arguments with custom inputs
            mFields = fields(args);
            if ~isempty(mFields)
                for idx = 1:numel(mFields)
                    obj.(mFields{idx}) = args.(mFields{idx});
                end
            end
        end

        function update(obj, args)
             arguments
                obj(1,1) pivlab.options
                args.?pivlab.options
             end

             % Override the default arguments with custom inputs
            mFields = fields(args);
            if ~isempty(mFields)
                for idx = 1:numel(mFields)
                    obj.(mFields{idx}) = args.(mFields{idx});
                end
            end
        end

    end
end

