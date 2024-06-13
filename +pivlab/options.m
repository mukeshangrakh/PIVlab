classdef options < handle
    %pivlab.options class to create a pivlab options object.
    %   This class contains the piv image analysis configurations as its
    %   properties.

    properties (Access=public)
        windowSize(1,1) double =64
        stepSize(1,1) double =32
        subPixelFinder(1,1) {mustBeMember(subPixelFinder, [1,2])} =1
        maskfile(:,:) double=[]
        roi(:,:) double =[]
        numPasses (1,1) double {mustBeInRange(numPasses, 1,4)} = 2
        windowSizeSecondpass (1,:) double =32
        windowSizeThirdpass (1,:) double =16
        windowSizeForthpass (1,:) double =16
        windowDeformation(1,:) char {mustBeMember(windowDeformation,{'*linear','*spline'})} = '*linear'
        repeatCorrelation(1,1) logical = false
        autoCorrelation(1,1) logical = false
        correlationStyle(1,1) CorrelationStyle
        repeatLastPass(1,1) logical = false
        qualitySlopeLastPass(1,1) double = 0.025

        enableContrastEnhancement(1,1) logical =true
        contrastEnhancementWindow(1,1) double = 50
        enableHighPass (1,1) logical =false
        highPassWindow(1,1) double = 15        
        enableClipping(1,1) logical = false
        enableWienerFilter(1,1) logical =false        
        wienerWindow(1,1) double =3
        minIntensity(1,1) double = 0.0
        maxIntensity(1,1) double = 1.0

        noCores(1,1) int64 = 1
        pairWise(1,1) logical
    end

    properties (Access=private)
        files(:,1) string
        filesRegExp(1,1) string
    end

    methods
        function obj = options(args)
            arguments
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

