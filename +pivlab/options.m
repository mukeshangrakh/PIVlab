classdef options
    %pivlab.options class to create a pivlab options object.
    %   This class contains the piv image analysis configurations as its
    %   properties.

    properties (Access=public)
        noCores(1,1) int64 = 1
        pairWise(1,1) logical = false

        windowSize(1,:) double = [64, 32, 16, 16]
        stepSize(1,1) double = 32
        subPixelFinder(1,1) string {mustBeMember(subPixelFinder,["3P Gauss","2D Gauss"])} = "3P Gauss"
        mask(:,:) double = []
        windowDeformation(1,1) string {mustBeMember(windowDeformation,["Linear","Spline"])} = "Linear"

        repeatCorrelation(1,1) logical = false
        autoCorrelation(1,1) logical = false
        correlationStyle(1,1) string {mustBeMember(correlationStyle,["Circular","Linear"])} = "Circular"
        multiplePass(1,1) logical = false
        qualitySlope(1,1) double = 0.025
        
        roi(1,:) double = []
        contrastEnhancementWindow(1,1) double = 50
        highPassWindow(1,1) double = NaN
        clipping(1,1) logical = false
        wienerWindow(1,1) double = NaN
        minIntensity(1,1) double = 0.0
        maxIntensity(1,1) double = 1.0
    end
end

