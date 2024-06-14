function [u_filt, v_filt,typevector_filt] = pivVelocityFilter(u,v,typevector,velOpt)
% wrapper function for PIVlab_postproc

% INPUT
% u, v: u and v components of vector fields
% typevector: type vector
% post_proc_setting: post processing setting
% paint_nan: bool, whether to interpolate missing data

% OUTPUT
% u_filt, v_filt: post-processed u and v components of vector fields
% typevector_filt: post-processed type vector
arguments
    u(:,1) cell
    v(:,1) cell
    typevector(:,1) cell
    velOpt pivlab.VelocityFileringOptions = pivlab.VelocityFileringOptions()
end
noSteps = size(u,1);
u_filt = cell(noSteps,1);
v_filt = cell(noSteps,1);
opt = createOldOptions(velOpt);
for i = 1:noSteps
    [u_filt{i},v_filt{i}] = PIVlab_postproc(u{i},v{i}, ...
    	opt{1,2},...
    	opt{2,2},...
    	opt{3,2},...
    	opt{4,2},...
    	opt{5,2},...
    	opt{6,2},...
    	opt{7,2});

    typevector_filt{i} = typevector{i}; % initiate
    typevector_filt{i}(isnan(u_filt{i}))=2;
    typevector_filt{i}(isnan(v_filt{i}))=2;
    typevector_filt{i}(typevector{i}==0)=0; %restores typevector for mask
end
% if paint_nan
% 	u_filt=inpaint_nans(u_filt,4);
% 	v_filt=inpaint_nans(v_filt,4);
% end

end
function a = tv(val)
if isnan(val)
    a = 0;
else
    a = val;
end
end

function a=tf(val)
if isnan(val)
    a = 0;
else
    a = 1;
end

end
function r = createOldOptions(velOptions)
arguments
    velOptions pivlab.VelocityFileringOptions
end

r = cell(6,1);
%Parameter     %Setting                                     %Options
r{1,1}= 'Calibration factor, 1 for uncalibrated data';      r{1,2}=velOptions.xCalibrationFactor;                   % Calibration factor for u
r{2,1}= 'Calibration factor, 1 for uncalibrated data';      r{2,2}=velOptions.xCalibrationFactor;                   % Calibration factor for v
r{3,1}= 'Valid velocities [u_min; u_max; v_min; v_max]';    r{3,2}=velOptions.velocityRange;  % Maximum allowed velocities, for uncalibrated data: maximum displacement in pixels
r{4,1}= 'Stdev check?';                                     r{4,2}=tf(velOptions.standardDeviation);                   % 1 = enable global standard deviation test
r{5,1}= 'Stdev threshold';                                  r{5,2}=tv(velOptions.standardDeviation);                   % Threshold for the stdev test
r{6,1}= 'Local median check?';                              r{6,2}=tf(velOptions.medianThreshold);                   % 1 = enable local median test
r{7,1}= 'Local median threshold';                           r{7,2}=tv(velOptions.medianThreshold);                   % Threshold for the local median test
end