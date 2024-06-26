function save_Callback(~,~,~)
masks_in_frame=gui.retr('masks_in_frame');
sessionpath=gui.retr('sessionpath');
if isempty(sessionpath)
	sessionpath=gui.retr('pathname');
end
if  ~isempty(masks_in_frame)
	[maskfile,maskpath] = uiputfile('*.mat','Save mask polygon(s)',fullfile(sessionpath, 'PIVlab_mask.mat'));
	if ~isequal(maskfile,0) && ~isequal(maskpath,0)
		save(fullfile(maskpath,maskfile),'masks_in_frame');
	end
end

