classdef options
    %pivlab.options class to create a pivlab options object.
    %   This class contains the piv image analysis configurations as its
    %   properties.

    properties (Access=public)
        NoCores(1,1) int64 = 1
        PairWise(1,1) logical = false

        WindowSize(1,:) double = [64, 32, 16, 16]
        StepSize(1,1) double = 32
        SubPixelFinder(1,1) string {mustBeMember(SubPixelFinder,["3P Gauss","2D Gauss"])} = "3P Gauss"
        Mask(:,:) double = []
        WindowDeformation(1,1) string {mustBeMember(WindowDeformation,["Linear","Spline"])} = "Linear"

        RepeatCorrelation(1,1) logical = false
        AutoCorrelation(1,1) logical = false
        CorrelationStyle(1,1) string {mustBeMember(CorrelationStyle,["Circular","Linear"])} = "Circular"
        MultiplePass(1,1) logical = false
        QualitySlope(1,1) double = 0.025
        
        ROI(1,:) double = []
        ContrastWindow(1,1) double = 50
        HighPassWindow(1,1) double = NaN
        Clipping(1,1) logical = false
        WienerWindow(1,1) double = NaN
        MinIntensity(1,1) double = 0.0
        MaxIntensity(1,1) double = 1.0
    end
end

