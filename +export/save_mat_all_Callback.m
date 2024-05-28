function save_mat_all_Callback(~, ~, ~)
handles=gui.gethand;
resultslist=gui.retr('resultslist');
currentframe=floor(get(handles.fileselector, 'value'));
if size(resultslist,2)>=currentframe && numel(resultslist{1,currentframe})>0
	[FileName,PathName] = uiputfile('*.mat','Save MATLAB file as...','PIVlab.mat'); %framenummer in dateiname
	if isequal(FileName,0) | isequal(PathName,0)
	else
		export.mat_file_save(currentframe,FileName,PathName,2); %option2 = all frames
	end
end

