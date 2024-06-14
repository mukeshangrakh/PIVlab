function [x,y,u,v,typeVector, correlationMap] = pivImageAnalysis(regExp, pivOptions)
arguments
    regExp string
    pivOptions(1,1) pivlab.options = pivlab.options()
end

% Process the input regular expression
imFiles = dir(regExp);
if isempty(imFiles)
    error("Did not find files to analyse.")
end
noImages = numel(imFiles);

% Determine the no of time slices
if ~pivOptions.pairWise
    noSteps = noImages-1;
    imRelation = zeros(noSteps, 2);
    imRelation(:,1) = 1:1:noSteps;
    imRelation(:,2) = 2:1:noImages;
else
    % If the no of images is odd, the last image will be removed from the.
    noSteps = 0.5*(noImages-mod(noImages,2));
    imRelation = zeros(noSteps, 2);
    imRelation(:,1) = 1:2:(2*noSteps);
    imRelation(:,2) = 2:2:noImages;
end

% Setup the parallel cluster locally
% if (pivOptions.noCores>1)
%     try
%         localCluster=parcluster('local');
%     catch
%         pivOptions.noCores = 1;
%         warning('on');
%         warning('Did not find Parallel Computing Toolbox. No. of cores set to 1.');
%     end
% end

% Create the cell options so that the old API can be used
[s,p] = createBCCells(pivOptions);

% Initialize the output variables
x = cell(noSteps,1);
y = cell(noSteps,1); 
u = cell(noSteps,1);
v = cell(noSteps,1);
typeVector = cell(noSteps,1);
correlationMap = cell(noSteps,1);

% Run the analysis
for i =1:noSteps
    [x{i},y{i},u{i},v{i}, typeVector{i}, correlationMap{i}] = piv_analysis(imFiles(1).folder, imFiles(imRelation(i,1)).name, imFiles(imRelation(i,2)).name,p,s,pivOptions.noCores,true);
end


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

% function [s,p] =createBCCells()
% %% Standard PIV Settings
% s = cell(15,2); % To make it more readable, let's create a "settings table"
% %Parameter                          %Setting			%Options
% s{1,1}= 'Int. area 1';              s{1,2}=64;			% window size of first pass
% s{2,1}= 'Step size 1';              s{2,2}=32;			% step of first pass
% s{3,1}= 'Subpix. finder';           s{3,2}=1;			% 1 = 3point Gauss, 2 = 2D Gauss
% s{4,1}= 'Mask';                     s{4,2}=[];			% If needed, supply a binary image mask with the same size as the PIV images
% s{5,1}= 'ROI';                      s{5,2}=[];			% Region of interest: [x,y,width,height] in pixels, may be left empty to process the whole image
% s{6,1}= 'Nr. of passes';            s{6,2}=2;			% 1-4 nr. of passes
% s{7,1}= 'Int. area 2';              s{7,2}=32;			% second pass window size
% s{8,1}= 'Int. area 3';              s{8,2}=16;			% third pass window size
% s{9,1}= 'Int. area 4';              s{9,2}=16;			% fourth pass window size
% s{10,1}='Window deformation';       s{10,2}='*linear';	% '*spline' is more accurate, but slower
% s{11,1}='Repeated Correlation';     s{11,2}=0;			% 0 or 1 : Repeat the correlation four times and multiply the correlation matrices.
% s{12,1}='Disable Autocorrelation';  s{12,2}=0;			% 0 or 1 : Disable Autocorrelation in the first pass.
% s{13,1}='Correlation style';        s{13,2}=0;			% 0 or 1 : Use circular correlation (0) or linear correlation (1).
% s{14,1}='Repeat last pass';			s{14,2}=0;			% 0 or 1 : Repeat the last pass of a multipass analyis
% s{15,1}='Last pass quality slope';  s{15,2}=0.025;		% Repetitions of last pass will stop when the average difference to the previous pass is less than this number.
% 
% 
% %% Standard image preprocessing settings
% p = cell(10,1);
% %Parameter                       %Setting           %Options
% p{1,1}= 'ROI';                   p{1,2}=s{5,2};     % same as in PIV settings
% p{2,1}= 'CLAHE';                 p{2,2}=1;          % 1 = enable CLAHE (contrast enhancement), 0 = disable
% p{3,1}= 'CLAHE size';            p{3,2}=50;         % CLAHE window size
% p{4,1}= 'Highpass';              p{4,2}=0;          % 1 = enable highpass, 0 = disable
% p{5,1}= 'Highpass size';         p{5,2}=15;         % highpass size
% p{6,1}= 'Clipping';              p{6,2}=0;          % 1 = enable clipping, 0 = disable
% p{7,1}= 'Wiener';                p{7,2}=0;          % 1 = enable Wiener2 adaptive denoise filter, 0 = disable
% p{8,1}= 'Wiener size';           p{8,2}=3;          % Wiener2 window size
% p{9,1}= 'Minimum intensity';     p{9,2}=0.0;        % Minimum intensity of input image (0 = no change)
% p{10,1}='Maximum intensity';     p{10,2}=1.0;       % Maximum intensity on input image (1 = no change)
% 
% end

function [s,p] = createBCCells(pivOpt)
arguments
    pivOpt pivlab.options
end
s = cell(15,2); % To make it more readable, let's create a "settings table"
%Parameter                          %Setting			%Options
s{1,1}= 'Int. area 1';              s{1,2}=pivOpt.windowSize(1);			% window size of first pass
s{2,1}= 'Step size 1';              s{2,2}=32;			% step of first pass

switch pivOpt.subPixelFinder
    case "3P Gauss"
        val = 1;
    case "2D Gauss"
        val = 2;
    otherwise
end
s{3,1}= 'Subpix. finder';           s{3,2}=val;			% 1 = 3point Gauss, 2 = 2D Gauss
s{4,1}= 'Mask';                     s{4,2}=pivOpt.mask;			% If needed, supply a binary image mask with the same size as the PIV images
s{5,1}= 'ROI';                      s{5,2}=pivOpt.roi;			% Region of interest: [x,y,width,height] in pixels, may be left empty to process the whole image
s{6,1}= 'Nr. of passes';            s{6,2}=2;			% 1-4 nr. of passes
s{7,1}= 'Int. area 2';              s{7,2}=pivOpt.windowSize(2);			% second pass window size
s{8,1}= 'Int. area 3';              s{8,2}=pivOpt.windowSize(3);		% third pass window size
s{9,1}= 'Int. area 4';              s{9,2}=pivOpt.windowSize(4);		% fourth pass window size

switch pivOpt.windowDeformation
    case "Linear"
        val = '*linear';
    case "Spline"
        val = '*spline';
    otherwise
end
s{10,1}='Window deformation';       s{10,2}=val;	% '*spline' is more accurate, but slower
s{11,1}='Repeated Correlation';     s{11,2}=int64(pivOpt.repeatCorrelation);			% 0 or 1 : Repeat the correlation four times and multiply the correlation matrices.
s{12,1}='Disable Autocorrelation';  s{12,2}=int64(pivOpt.autoCorrelation);			% 0 or 1 : Disable Autocorrelation in the first pass.
switch pivOpt.correlationStyle
    case "Circular"
        val = 0;
    case "Linear"
        val = 1;
    otherwise
end
s{13,1}='Correlation style';        s{13,2}=val;			% 0 or 1 : Use circular correlation (0) or linear correlation (1).
s{14,1}='Repeat last pass';		    s{14,2}=int64(pivOpt.multiplePass);			% 0 or 1 : Repeat the last pass of a multipass analyis
s{15,1}='Last pass quality slope';  s{15,2}=pivOpt.qualitySlope;		% Repetitions of last pass will stop when the average difference to the previous pass is less than this number.



p = cell(10,1);
%Parameter                       %Setting           %Options
p{1,1}= 'ROI';                   p{1,2}=s{5,2};     % same as in PIV settings
p{2,1}= 'CLAHE';                 p{2,2}=tf(pivOpt.contrastEnhancementWindow);          % 1 = enable CLAHE (contrast enhancement), 0 = disable
p{3,1}= 'CLAHE size';            p{3,2}=tv(pivOpt.contrastEnhancementWindow);          % CLAHE window size
p{4,1}= 'Highpass';              p{4,2}=tf(pivOpt.highPassWindow);          % 1 = enable highpass, 0 = disable
p{5,1}= 'Highpass size';         p{5,2}=tv(pivOpt.highPassWindow);         % highpass size
p{6,1}= 'Clipping';              p{6,2}=int64(pivOpt.clipping);          % 1 = enable clipping, 0 = disable
p{7,1}= 'Wiener';                p{7,2}=tf(pivOpt.wienerWindow);          % 1 = enable Wiener2 adaptive denoise filter, 0 = disable
p{8,1}= 'Wiener size';           p{8,2}=tv(pivOpt.wienerWindow);          % Wiener2 window size
p{9,1}= 'Minimum intensity';     p{9,2}=pivOpt.minIntensity;         % Minimum intensity of input image (0 = no change)
p{10,1}='Maximum intensity';     p{10,2}=pivOpt.maxIntensity;       % Maximum intensity on input image (1 = no change)
end