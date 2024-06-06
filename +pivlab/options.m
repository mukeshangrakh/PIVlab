classdef options < handle
    %pivlab.options class to create a pivlab options object.
    %   This class contains the piv image analysis configurations as its
    %   properties.

    properties (Access=public)
        noCores(1,1) int64 = 1
        pairWise(1,1) logical
        windowSize(1,:) int64
        stepSize(1,1) double
        subPixelFinder(1,1) string {mustBeMember(subPixelFinder,["3P Gauss","2D Gauss"])} = "3P Gauss"
        roi(1,4) double
        windowDeformation(1,1) string {mustBeMember(windowDeformation,["Linear","Spline"])} = "Linear"
        maskfile(1,1) string
        repeatCorrelation(1,1) logical = false
        autoCorrelation(1,1) logical = false
        correlationStyle(1,1) string {mustBeMember(correlationStyle,["Circular","Linear"])} = "Linear"
        multiplePass(1,1) logical = false
        qualitySlope(1,1) double = 0.025
        clipping(1,1) logical = false
        contrastEnhancementWindow(1,1) double = 50
        highPassWindow(1,1) double = NaN
        wienerWindow(1,1) double = NaN
        minIntensity(1,1) double = 0.0
        maxIntensity(1,1) double = 1.0
    end

    properties (Access=private)
        files(:,1) string
        filesRegExp(1,1) string
    end

    methods
        function obj = options(fRegEx, args)
            arguments
                fRegEx(1,1) string
                args.?pivlab.options
            end

            % Check if the files exist
            l = dir(fRegEx);
            if isempty(l)
                error("Files not found.");
            end
            obj.filesRegExp = fRegEx;

            for i=1:numel(l)
                obj.files(end+1,1) = fullfile(l(i).folder, l(i).name);
            end
            sort(obj.files)

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

