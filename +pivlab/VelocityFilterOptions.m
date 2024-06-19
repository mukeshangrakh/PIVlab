classdef VelocityFilterOptions
    %pivlab.VelocityFileringOptions class to create a pivlab options object.
    %   This class contains configuration variables used in velocity
    %   filtering.

    properties (Access=public)
        xCalibrationFactor(1,1) double = 1.0
        yCalibrationFactor(1,1) double = 1.0
        VelocityRange(1,:) double
        StandardDeviation double = nan
        MedianThreshold double = nan
    end
end
