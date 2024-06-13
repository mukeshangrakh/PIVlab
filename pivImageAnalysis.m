function [x,y,u,v,typeVector, correlationMap] = pivImageAnalysis(regExp, pivOptions)
arguments
    regExp string
    pivOptions(1,1) pivlab.options = pivlab.options()
end

% Process the input regular expression
imStruct = dir(regExp);
if isempty(imStruct)
    error("Did not find files to analyse.")
end

imFiles = string([]);
for i = 1:numel(imStruct)
    fName = fullfile(imStruct(i).folder, imStruct(i).name);
    imFiles(end+1) = string(fName);
end
imFiles = sort(imFiles);

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
    imRelation(:,1) = 1:2:noImages;
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

% Run the analysis



end

function [s,p] = createBCCells(pivOpt)
arguments
    pivOpt pivlab.options
end
s = cell(15,2); % To make it more readable, let's create a "settings table"
%Parameter                          %Setting			%Options
s{1,1}= 'Int. area 1';              s{1,2}=64;			% window size of first pass
s{2,1}= 'Step size 1';              s{2,2}=32;			% step of first pass
s{3,1}= 'Subpix. finder';           s{3,2}=1;			% 1 = 3point Gauss, 2 = 2D Gauss
s{4,1}= 'Mask';                     s{4,2}=[];			% If needed, supply a binary image mask with the same size as the PIV images
s{5,1}= 'ROI';                      s{5,2}=[];			% Region of interest: [x,y,width,height] in pixels, may be left empty to process the whole image
s{6,1}= 'Nr. of passes';            s{6,2}=2;			% 1-4 nr. of passes
s{7,1}= 'Int. area 2';              s{7,2}=32;			% second pass window size
s{8,1}= 'Int. area 3';              s{8,2}=16;			% third pass window size
s{9,1}= 'Int. area 4';              s{9,2}=16;			% fourth pass window size
s{10,1}='Window deformation';       s{10,2}='*linear';	% '*spline' is more accurate, but slower
s{11,1}='Repeated Correlation';     s{11,2}=0;			% 0 or 1 : Repeat the correlation four times and multiply the correlation matrices.
s{12,1}='Disable Autocorrelation';  s{12,2}=0;			% 0 or 1 : Disable Autocorrelation in the first pass.
s{13,1}='Correlation style';        s{13,2}=0;			% 0 or 1 : Use circular correlation (0) or linear correlation (1).
s{14,1}='Repeat last pass';			s{14,2}=0;			% 0 or 1 : Repeat the last pass of a multipass analyis
s{15,1}='Last pass quality slope';  s{15,2}=0.025;		% Repetitions of last pass will stop when the average difference to the previous pass is less than this number.



p = cell(10,1);
%Parameter                       %Setting           %Options
p{1,1}= 'ROI';                   p{1,2}=s{5,2};     % same as in PIV settings
p{2,1}= 'CLAHE';                 p{2,2}=1;          % 1 = enable CLAHE (contrast enhancement), 0 = disable
p{3,1}= 'CLAHE size';            p{3,2}=50;         % CLAHE window size
p{4,1}= 'Highpass';              p{4,2}=0;          % 1 = enable highpass, 0 = disable
p{5,1}= 'Highpass size';         p{5,2}=15;         % highpass size
p{6,1}= 'Clipping';              p{6,2}=int64(pivOpt.enableClipping);          % 1 = enable clipping, 0 = disable
p{7,1}= 'Wiener';                p{7,2}=0;          % 1 = enable Wiener2 adaptive denoise filter, 0 = disable
p{8,1}= 'Wiener size';           p{8,2}=3;          % Wiener2 window size
p{9,1}= 'Minimum intensity';     p{9,2}=pivOpt.minIntensity;         % Minimum intensity of input image (0 = no change)
p{10,1}='Maximum intensity';     p{10,2}=pivOpt.maxIntensity;       % Maximum intensity on input image (1 = no change)
end