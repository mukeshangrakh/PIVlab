function [OutputError,ima,framerate_max] = PIVlab_capture_pco(nr_of_images,exposure_time,TriggerModeString,ImagePath,framerate,do_realtime,ROI_live,binning,ROI_general,camera_type,measure_framerate_max)
if measure_framerate_max == 1
	OutputError=0;
	glvar=struct('do_libunload',1,'do_close',0,'camera_open',0,'out_ptr',[]);
	pco_camera_load_defines();
	subfunc=pco_camera_subfunction();
	[errorCode,glvar]=pco_camera_open_close(glvar);
	pco_errdisp('pco_camera_setup',errorCode);
	out_ptr=glvar.out_ptr;
	try
		act_recstate = uint16(10);
		[errorCode,~,act_recstate] = calllib('PCO_CAM_SDK', 'PCO_GetRecordingState',out_ptr,act_recstate);
		if(errorCode)
			pco_errdisp('PCO_GetRecordingState',errorCode);
		end
		%% Set to double image
		[errorCode] = calllib('PCO_CAM_SDK', 'PCO_SetDoubleImageMode', out_ptr,1);
		if(errorCode)
			pco_errdisp('PCO_SetDoubleImageMode',errorCode);
		end
		
		%% camera description
		cam_desc=libstruct('PCO_Description');
		set(cam_desc,'wSize',cam_desc.structsize);
		[errorCode,~,cam_desc] = calllib('PCO_CAM_SDK', 'PCO_GetCameraDescription', out_ptr,cam_desc);
		pco_errdisp('PCO_GetCameraDescription',errorCode);
		%% Pixel Binning
		%binning funktioniert nur wenn gleichzeitig ROI gesetzt wird.
		h_binning=binning; %1,2,4
		v_binning=binning; %1,2,4
		
		xmin=ROI_general(1);
		ymin=ROI_general(2);
		xmax=ROI_general(1)+ROI_general(3)-1;
		ymax=ROI_general(2)+ROI_general(4)-1;
		
		[errorCode] = calllib('PCO_CAM_SDK', 'PCO_SetBinning', out_ptr,h_binning,v_binning); %2,4, etc.
		pco_errdisp('PCO_SetBinning',errorCode);
		%% ROI selection
		if strcmp(camera_type,'pco_panda')
			[errorCode] = calllib('PCO_CAM_SDK', 'PCO_SetROI', out_ptr,xmin,ymin,xmax,ymax);
			pco_errdisp('PCO_SetROI',errorCode);
		end
		%stop camera
		subfunc.fh_stop_camera(out_ptr);
		
		bitpix=uint16(cam_desc.wDynResDESC);
		%set bitalignment LSB
		bitalign=uint16(BIT_ALIGNMENT_LSB);
		errorCode = calllib('PCO_CAM_SDK', 'PCO_SetBitAlignment', out_ptr,bitalign);
		pco_errdisp('PCO_SetBitAlignment',errorCode);
		
		errorCode = calllib('PCO_CAM_SDK', 'PCO_SetRecorderSubmode',out_ptr,RECORDER_SUBMODE_RINGBUFFER);
		pco_errdisp('PCO_SetRecorderSubmode',errorCode);
		
		%set default Pixelrate
		subfunc.fh_set_pixelrate(out_ptr,2);
		
		%set triggermode (auto)
		subfunc.fh_set_triggermode(out_ptr,0);
		
		%change timebase for camera
		subfunc.fh_set_exposure_times(out_ptr,exposure_time,1,0,1); %us 	%subfunc.fh_set_exposure_times(out_ptr,exposure_time,2,0,2); %ms
		
		%if PCO_ArmCamera does fail no images can be grabbed
		errorCode = calllib('PCO_CAM_SDK', 'PCO_ArmCamera', out_ptr);
		if(errorCode~=PCO_NOERROR)
			pco_errdisp('PCO_ArmCamera',errorCode);
			ME = MException('PCO_ERROR:ArmCamera','Cannot continue script with not armed camera');
			subfunc.fh_lasterr(errorCode);
			throw(ME);
		end
		
		%adjust transfer parameter if necessary
		subfunc.fh_set_transferparameter(out_ptr);
		
		act_xsize=uint16(0);
		act_ysize=uint16(0);
		ccd_xsize=uint16(0);
		ccd_ysize=uint16(0);
		
		%use PCO_GetSizes because this always returns accurate image size for next recording
		[errorCode,~,act_xsize,act_ysize]  = calllib('PCO_CAM_SDK', 'PCO_GetSizes', out_ptr,act_xsize,act_ysize,ccd_xsize,ccd_ysize);
		if(errorCode)
			pco_errdisp('PCO_GetSizes',errorCode);
		end
		disp(['sizes: horizontal ',int2str(act_xsize),' vertical ',int2str(act_ysize)]);
		
		%% Measure time to acquire 1 image
		dwSec=uint32(0);
		dwNanoSec=uint32(0);
		[errorCode,~,dwSec,dwNanoSec] = calllib('PCO_CAM_SDK', 'PCO_GetCOCRuntime', out_ptr,dwSec,dwNanoSec);
		if(errorCode)
			pco_errdisp('PCO_GetCOCRuntime',errorCode);
		end
		disp(['Max double image capture freq: ' num2str(round(1/(double(dwNanoSec)/1000/1000/1000),3)) ' Hz.'])
		capture_time=(double(dwNanoSec)/1000/1000/1000);
		disp(['Double image capture time: ' num2str(round(capture_time,2)) ' seconds.'])
		%disp(['Double image capture max framerate: ' num2str(round(1/capture_time,2)) ' Hz.'])
		%testwrite dummy image data to measure speed
		imgA_path=fullfile(ImagePath,'PIVlab_dummy_A.tif');
		imgB_path=fullfile(ImagePath,'PIVlab_dummy_B.tif');
		dummy_image=uint16(rand(act_ysize/2,act_xsize)*65530);
		img_save_time=tic;
		for im_write_test=1:3
			imwrite(dummy_image,imgA_path,'compression','none');
			imwrite(dummy_image,imgB_path,'compression','none');
		end
		test_data_write_time=toc(img_save_time)/im_write_test;
		delete (fullfile(ImagePath,'PIVlab_dummy_A.tif'));
		delete (fullfile(ImagePath,'PIVlab_dummy_B.tif'));
		disp(['Double image save time: ' num2str(test_data_write_time) ' seconds.']);
		disp(['Double image total time: ' num2str(test_data_write_time + capture_time) ' seconds.'])
		framerate_max=1/(test_data_write_time + capture_time);
		disp(['Max. frame rate: ' num2str(framerate_max) ' Hz.'])
		if framerate_max < framerate
			disp('Frames will be skipped!')
		end
		ima=[];
		errorCode = calllib('PCO_CAM_SDK', 'PCO_CancelImages', out_ptr);
		subfunc.fh_stop_camera(out_ptr);
		glvar.do_close=1;
		glvar.do_libunload=1;
		pco_camera_open_close(glvar);
	catch ME
		disp(ME)
	end
	
else
	framerate_max=[];
	hgui=getappdata(0,'hgui');
	crosshair_enabled = getappdata(hgui,'crosshair_enabled');
	sharpness_enabled = getappdata(hgui,'sharpness_enabled');
	if strcmp(TriggerModeString,'Calibration') || strcmp(TriggerModeString,'calibration')
		triggermode=0; %internal trigger
	elseif  strcmp(TriggerModeString,'Synchronizer') || strcmp(TriggerModeString,'synchronizer')
		triggermode=2; %external Trigger
	end
	OutputError=0;
	PIVlab_axis = findobj(hgui,'Type','Axes');
	
	image_handle=imagesc(zeros(1040,1392),'Parent',PIVlab_axis,[0 2^16]);
	if triggermode == 2 && do_realtime==1 %external trigger and realtime
		[X,Y]=meshgrid(1:32:1392,1:32:1040);
		hold on;
		quiver_handle=quiver(X,Y,X*0,Y*0,'autoscale','off','Linewidth',1.5,'Color','g');
		hold off
		set(gca,'ActivePositionProperty','outerposition','Clipping','on')
		int_area=32;
		step=32;
		msg_displayed=0;
		performance_settings_int_area = [16 16 32 32 48 48 64 96];
		performance_settings_step =     [128 64 64 32 32 24 24 16];
		performance_settings_int_area= round(interp1(1:numel(performance_settings_int_area),performance_settings_int_area,1:0.15:numel(performance_settings_int_area)));
		performance_settings_step= round(interp1(1:numel(performance_settings_step),performance_settings_step,1:0.15:numel(performance_settings_step)));
		performance_preset=1;
	end
	frame_nr_display=text(100,100,'Initializing...','Color',[1 1 0]);
	colormap default %reset colormap steps
	new_map=colormap('gray');
	new_map(1:3,:)=[0 0.2 0;0 0.2 0;0 0.2 0];
	new_map(end-2:end,:)=[1 0.7 0.7;1 0.7 0.7;1 0.7 0.7];
	colormap(new_map);axis image;
	set(gca,'ytick',[])
	set(gca,'xtick',[])
	colorbar
	
	
	image_save_number=0;
	glvar=struct('do_libunload',1,'do_close',0,'camera_open',0,'out_ptr',[]);
	pco_camera_load_defines();
	subfunc=pco_camera_subfunction();
	[errorCode,glvar]=pco_camera_open_close(glvar);
	pco_errdisp('pco_camera_setup',errorCode);
	out_ptr=glvar.out_ptr;
	
	try
		act_recstate = uint16(10);
		[errorCode,~,act_recstate] = calllib('PCO_CAM_SDK', 'PCO_GetRecordingState',out_ptr,act_recstate);
		if(errorCode)
			pco_errdisp('PCO_GetRecordingState',errorCode);
		end
		%% Set to double /single image
		if triggermode == 2
			[errorCode] = calllib('PCO_CAM_SDK', 'PCO_SetDoubleImageMode', out_ptr,1);
		elseif triggermode==0
			[errorCode] = calllib('PCO_CAM_SDK', 'PCO_SetDoubleImageMode', out_ptr,0);
		end
		if(errorCode)
			pco_errdisp('PCO_SetDoubleImageMode',errorCode);
		end
		if strcmp(camera_type,'pco_panda')
			%enable external trigger on panda
			hwio_sig=libstruct('PCO_Signal');
			set(hwio_sig,'wSize',hwio_sig.structsize);
			[errorCode,~,hwio_sig] = calllib('PCO_CAM_SDK', 'PCO_GetHWIOSignal', out_ptr,0,hwio_sig);
			pco_errdisp('PCO_GetHWIOSignal',errorCode);
			hwio_sig.wEnabled = 1;
			[errorCode,~,~] = calllib('PCO_CAM_SDK', 'PCO_SetHWIOSignal', out_ptr,0,hwio_sig);
			pco_errdisp('PCO_SetHWIOSignal',errorCode);
			[errorCode,~,hwio_sig] = calllib('PCO_CAM_SDK', 'PCO_GetHWIOSignal', out_ptr,0,hwio_sig);
			if(errorCode)
				pco_errdisp('PCO_GetHWIOSignal',errorCode);
			end
			%disp(['hardware trigger status: ' num2str(hwio_sig.wEnabled)]);
		elseif strcmp(camera_type,'pco_pixelfly')
			%no special treatment
		end
		%% camera description
		cam_desc=libstruct('PCO_Description');
		set(cam_desc,'wSize',cam_desc.structsize);
		[errorCode,~,cam_desc] = calllib('PCO_CAM_SDK', 'PCO_GetCameraDescription', out_ptr,cam_desc);
		pco_errdisp('PCO_GetCameraDescription',errorCode);
		
		%% Pixel Binning
		%binning funktioniert nur wenn gleichzeitig ROI gesetzt wird.
		h_binning=binning; %1,2,4
		v_binning=binning; %1,2,4
		
		[errorCode] = calllib('PCO_CAM_SDK', 'PCO_SetBinning', out_ptr,h_binning,v_binning); %2,4, etc.
		pco_errdisp('PCO_SetBinning',errorCode);
		%% ROI selection
		if strcmp(camera_type,'pco_panda')
			xmin=ROI_general(1);
			ymin=ROI_general(2);
			xmax=ROI_general(1)+ROI_general(3)-1;
			ymax=ROI_general(2)+ROI_general(4)-1;
			[errorCode] = calllib('PCO_CAM_SDK', 'PCO_SetROI', out_ptr,xmin,ymin,xmax,ymax);
			pco_errdisp('PCO_SetROI',errorCode);
		end
		%stop camera
		subfunc.fh_stop_camera(out_ptr);
		%cam_desc=libstruct('PCO_Description');
		%set(cam_desc,'wSize',cam_desc.structsize);
		%[errorCode,~,cam_desc] = calllib('PCO_CAM_SDK', 'PCO_GetCameraDescription', out_ptr,cam_desc);
		%pco_errdisp('PCO_GetCameraDescription',errorCode);
		
		bitpix=uint16(cam_desc.wDynResDESC);
		%set bitalignment LSB
		bitalign=uint16(BIT_ALIGNMENT_LSB);
		errorCode = calllib('PCO_CAM_SDK', 'PCO_SetBitAlignment', out_ptr,bitalign);
		pco_errdisp('PCO_SetBitAlignment',errorCode);
		
		errorCode = calllib('PCO_CAM_SDK', 'PCO_SetRecorderSubmode',out_ptr,RECORDER_SUBMODE_RINGBUFFER);
		pco_errdisp('PCO_SetRecorderSubmode',errorCode);
		
		%disnable ASCII and binary timestamp
		if(bitand(cam_desc.dwGeneralCapsDESC1,GENERALCAPS1_NO_TIMESTAMP)==0)
			subfunc.fh_enable_timestamp(out_ptr,TIMESTAMP_MODE_OFF);
		end
		%disable MetaData if available
		if(bitand(cam_desc.dwGeneralCapsDESC1,GENERALCAPS1_METADATA))
			subfunc.fh_set_metadata_mode(out_ptr,0);
		end
		
		%set default Pixelrate
		subfunc.fh_set_pixelrate(out_ptr,2);
		
		%set triggermode (auto vs. external trigger)
		subfunc.fh_set_triggermode(out_ptr,triggermode);
		
		%change timebase for camera
		subfunc.fh_set_exposure_times(out_ptr,exposure_time,1,0,1); %us 	%subfunc.fh_set_exposure_times(out_ptr,exposure_time,2,0,2); %ms
		
		%if PCO_ArmCamera does fail no images can be grabbed
		errorCode = calllib('PCO_CAM_SDK', 'PCO_ArmCamera', out_ptr);
		if(errorCode~=PCO_NOERROR)
			pco_errdisp('PCO_ArmCamera',errorCode);
			ME = MException('PCO_ERROR:ArmCamera','Cannot continue script with not armed camera');
			subfunc.fh_lasterr(errorCode);
			throw(ME);
		end
		
		%adjust transfer parameter if necessary
		subfunc.fh_set_transferparameter(out_ptr);
		triggermode=subfunc.fh_get_triggermode(out_ptr);
		metadatasize=0;
		if(bitand(cam_desc.dwGeneralCapsDESC1,GENERALCAPS1_METADATA))
			wMetaDataMode=uint16(0);
			wMetaDataSize=uint16(0);
			wMetaDataVersion=uint16(0);
			
			[errorCode,~,wMetaDataMode,wMetaDataSize,wMetaDataVersion] = calllib('PCO_CAM_SDK', 'PCO_GetMetaDataMode',out_ptr,wMetaDataMode,wMetaDataSize,wMetaDataVersion);
			pco_errdisp('PCO_GetMetaDataMode',errorCode);
			if(errorCode)
				pco_errdisp('PCO_GetMetaDataMode',errorCode);
				return;
			end
			if(wMetaDataMode~=0)
				metadatasize=wMetaDataSize;
			end
		end
		
		act_xsize=uint16(0);
		act_ysize=uint16(0);
		ccd_xsize=uint16(0);
		ccd_ysize=uint16(0);
		
		%use PCO_GetSizes because this always returns accurate image size for next recording
		[errorCode,~,act_xsize,act_ysize]  = calllib('PCO_CAM_SDK', 'PCO_GetSizes', out_ptr,act_xsize,act_ysize,ccd_xsize,ccd_ysize);
		if(errorCode)
			pco_errdisp('PCO_GetSizes',errorCode);
		end
		
		flags=2; %IMAGEPARAMETERS_READ_WHILE_RECORDING;
		errorCode = calllib('PCO_CAM_SDK', 'PCO_SetImageParameters', out_ptr,act_xsize,act_ysize,flags,[],0);
		pco_errdisp('PCO_SetImageParameters',errorCode);
		
		lineadd=0;
		if(metadatasize>0)
			xs=uint32(fix((double(bitpix)+7)/8));
			xs=xs*uint32(act_xsize);
			i=uint16(floor((metadatasize*2)/double(xs)));
			lineadd=i+1;
		end
		
		%allocate memory for display, 4 buffers are used
		bufcount=4;
		bufnum=zeros(4,1,'int16');
		
		imas=uint32(fix((double(bitpix)+7)/8));
		imas= imas*uint32(act_xsize)* uint32(act_ysize);
		imasize=imas;
		
		image_stack=zeros(act_xsize,(act_ysize+lineadd),bufcount,'uint16');
		
		%Allocate 4 SDK buffer and set address of buffers from image_stack
		ev_ptr(bufcount) = libpointer('voidPtr');
		im_ptr(bufcount) = libpointer('voidPtr');
		
		buflist=libstruct('PCO_Buflist');
		names=fieldnames(buflist);
		x=1:4:length(names);
		bufnr=names(x);
		x=3:4:length(names);
		statusdll=names(x);
		x=4:4:length(names);
		statusdrv=names(x);
		
		for n=1:bufcount
			sBufNri=int16(-1);
			im_ptr(n) = libpointer('uint16Ptr',image_stack(:,:,n));
			ev_ptr(n) = libpointer('voidPtr');
			
			[errorCode,~,sBufNri]  = calllib('PCO_CAM_SDK','PCO_AllocateBuffer', out_ptr,sBufNri,imasize,im_ptr(n),ev_ptr(n));
			if(errorCode~=PCO_NOERROR)
				pco_errdisp('PCO_AllocateBuffer',errorCode);
				ME = MException('PCO_ERROR:AllocateBuffer','Cannot continue script without allocated Buffers');
				subfunc.fh_lasterr(errorCode);
				throw(ME);
			end
			buflist.(bufnr{n})=int16(sBufNri);
			bufnum(n)=int16(sBufNri);
			e=bitor(buflist.(statusdll{n}),uint32(PCO_BUFFER_EVAUTORES),'uint32');
			buflist.(statusdll{n})=e;
		end
		
		ima=image_stack(:,1:act_ysize,1);
		ima=ima';
		pause(0.005);
		
		%this will remove all pending buffers in the queue and does reset grabber
		errorCode = calllib('PCO_CAM_SDK', 'PCO_CancelImages', out_ptr);
		pco_errdisp('PCO_CancelImages',errorCode);
		errorCode=subfunc.fh_start_camera(out_ptr);
		if(errorCode~=PCO_NOERROR)
			ME = MException('PCO_ERROR:StartCamera','Cannot continue script with stopped camera');
			subfunc.fh_lasterr(errorCode);
			throw(ME);
		end
		
		%setup loop
		for n=1:bufcount
			errorCode = calllib('PCO_CAM_SDK','PCO_AddBufferEx', out_ptr,0,0,bufnum(n),act_xsize,act_ysize,bitpix);
			if(errorCode~=PCO_NOERROR)
				pco_errdisp('PCO_AddBufferEx',errorCode);
				ME = MException('PCO_ERROR:AddBufferEx','Cannot continue script without added buffers');
				subfunc.fh_lasterr(errorCode);
				throw(ME);
			end
		end
		
		[errorCode,~,act_recstate] = calllib('PCO_CAM_SDK', 'PCO_GetRecordingState',glvar.out_ptr,act_recstate);
		if(errorCode)
			pco_errdisp('PCO_GetRecordingState',errorCode);
		end
		
		if(act_recstate==1)
			trigdone=int16(1);
			trigcount=0;
			if(triggermode==1)
				[errorCode,~,trigdone]  = calllib('PCO_CAM_SDK','PCO_ForceTrigger',out_ptr,trigdone);
				if(errorCode)
					pco_errdisp('PCO_ForceTrigger',errorCode);
				else
					trigcount=trigcount+1;
				end
			end
			pause(0.0001);
			tic;
			
			%grab and display loop
			ima_nr=0;
			last_ok=0;
			%lastimage=tic; %initialize
			while(ima_nr<nr_of_images) && getappdata(hgui,'cancel_capture') ~=1
				%toc(lastimage)
				%lastimage=tic;
				drawnow
				%wait for buffers
				[errorCode,~,buflist]  = calllib('PCO_CAM_SDK','PCO_WaitforBuffer', out_ptr,bufcount,buflist,4000); %wait 4000 ms for trigger input
				if(errorCode)
					pco_errdisp('PCO_WaitforBuffer',errorCode);
					OutputError='NoTrigger';
					uiwait(msgbox('Camera did not receive a trigger signal.'))
					break;
				end
				%  disp(['After wait image ',int2str(ima_nr),' last_ok ',num2str(last_ok)]);
				%first image done trigger next
				if(triggermode==1)
					[errorCode,~,trigdone]  = calllib('PCO_CAM_SDK','PCO_ForceTrigger',out_ptr,trigdone);
					if(errorCode)
						pco_errdisp('PCO_ForceTrigger',errorCode);
					else
						trigcount=trigcount+1;
					end
				end
				%test and display buffer
				next=last_ok+1;
				multi=0;
				tic
				for n=1:bufcount
					if(next>bufcount)
						next=1;
					end
					%   disp(['Status buf',int2str(next),' StatusDll ',num2str(buflist.(statusdll{next}),'%08X'),' StatusDrv ',num2str(buflist.(statusdrv{next}),'%08X')]);
					if((bitand(buflist.(statusdll{next}),hex2dec('00008000')))&&(buflist.(statusdrv{next})==0))
						%get data and show image
						last_ok=next;
						ima=get(im_ptr(next),'Value');
						ima_nr=ima_nr+1;
						multi=multi+1;
						
						if(metadatasize>0)
							ima=ima(:,1:act_ysize);
						end
						ima=ima';
						if(bitalign==BIT_ALIGNMENT_MSB)
							s=int16(16-bitpix);
							s=s*-1;
							ima=bitshift(ima,s);
						end
						
						%% Save images with external trigger
						tic
						%0-4095 panda original range
						%0-16000 pixelfly original range
						if strcmp(camera_type,'pco_panda')
							ima=bitshift(ima,4); %12 bit to 16 bit conversion
						elseif strcmp(camera_type,'pco_pixelfly')
							ima=bitshift(ima,2); %14 bit to 16 bit conversion
						end
						if triggermode == 2 %external trigger --> PIV mode
							imgA_path=fullfile(ImagePath,['PIVlab_' sprintf('%4.4d',image_save_number) '_A.tif']);
							imgB_path=fullfile(ImagePath,['PIVlab_' sprintf('%4.4d',image_save_number) '_B.tif']);
							%img_save_time=tic;
							imwrite(ima(1:act_ysize/2  ,  1:act_xsize),imgA_path,'compression','none'); %tif file saving seems to be the fastest method for saving data...
							imwrite(ima(act_ysize/2+1:end  ,  1:act_xsize),imgB_path,'compression','none');
							%toc(img_save_time)
							toggle_image_state=getappdata(hgui,'toggler');
							if toggle_image_state == 0
								set(image_handle,'CData',(ima(1:act_ysize/2  ,  1:act_xsize)));
							else
								set(image_handle,'CData',(ima(act_ysize/2+1:end  ,  1:act_xsize)));
							end
							set(frame_nr_display,'String',['Image nr.: ' int2str(image_save_number)]);
							image_save_number=image_save_number+1;
							sharpness_enabled = getappdata(hgui,'sharpness_enabled');
							if sharpness_enabled == 1 %cross-hair and sharpness indicator
								%% sharpness indicator for particle images
								if strcmp(camera_type,'pco_panda')
									textx=ROI_general(3)-10;
									texty=ROI_general(4)-50;
								else
									textx=1300;
									texty=950;
								end
								[~,~] = sharpness_indicator (ima(1:act_ysize/2  ,  1:act_xsize),textx,texty);
							end
						elseif triggermode==0 %internal trigger --> calibration mode
							%% sharpness indicator for particle images
							sharpness_enabled = getappdata(hgui,'sharpness_enabled');
							if sharpness_enabled == 1
								if strcmp(camera_type,'pco_panda')
									textx=ROI_general(3)-10;
									texty=ROI_general(4)-50;
								else
									textx=1300;
									texty=950;
								end
								[~,sharpness_map] = sharpness_indicator (ima,textx,texty);
								%local sharpness indicator
								%{
								checker=zeros(200,round(size(sharpness_map,2)/size(sharpness_map,1)*200));
								checker(1:2:end,:)=1;
								checker(:,1:2:end)=1;
								checker=imresize(checker,size(ima),'nearest');
								ima=double(ima)   + ((sharpness_map).*checker*double(max(ima(:))));
								%}
							end
							crosshair_enabled = getappdata(hgui,'crosshair_enabled');
							if crosshair_enabled == 1 %cross-hair
								%% cross-hair
								locations=[0.15 0.5 0.85];
								half_thickness=2;
								brightness_incr=3000;
								ima_ed=ima;
								old_max=max(ima(:));
								for loca=locations
									%vertical
									ima_ed(:,round(size(ima,2)*loca)-half_thickness:round(size(ima,2)*loca)+half_thickness)=ima_ed(:,round(size(ima,2)*loca)-half_thickness:round(size(ima,2)*loca)+half_thickness)+brightness_incr;
									%horizontal
									ima_ed(round(size(ima,1)*loca)-half_thickness:round(size(ima,1)*loca)+half_thickness,:)=ima_ed(round(size(ima,1)*loca)-half_thickness:round(size(ima,1)*loca)+half_thickness,:)+brightness_incr;
								end
								ima_ed(ima_ed>old_max)=old_max;
								set(image_handle,'CData',ima_ed);
							else
								set(image_handle,'CData',ima);
							end
							set(frame_nr_display,'String','');
						end
						
						pause(0.0001);
						%% Live preview
						if triggermode == 2 && do_realtime==1%external trigger
							A=adapthisteq(ima(1:act_ysize/2  ,  1:act_xsize)); %0.08s
							B=adapthisteq(ima(act_ysize/2+1:end  ,  1:act_xsize));
							A=A(ROI_live(2):ROI_live(2)+ROI_live(4) , ROI_live(1):ROI_live(1)+ROI_live(3));
							B=B(ROI_live(2):ROI_live(2)+ROI_live(4) , ROI_live(1):ROI_live(1)+ROI_live(3));
							[xtable, ytable, utable, vtable] = piv_quick (A,B,int_area, step);
							xtable=xtable+ROI_live(1);
							ytable=ytable+ROI_live(2);
							%0.008
							[utable,vtable] = PIVlab_postproc (utable,vtable,1,1, [-10 10 -10 10], 1,7, 1,4);
							set(quiver_handle,'Xdata',xtable,'ydata',ytable,'udata',utable*8,'vdata',vtable*8);
						end
						errorCode = calllib('PCO_CAM_SDK','PCO_AddBufferEx', out_ptr,0,0,bufnum(next),act_xsize,act_ysize,bitpix);
						if(errorCode)
							pco_errdisp('PCO_AddBufferEx',errorCode);
							break;
						end
						if triggermode == 2 && do_realtime==1
							time_consumed=toc;
							time_consumed=time_consumed*1.1; %add 10% safety margin
							%computing_effort = int_area^2 / step^2
							if time_consumed > 1/framerate+0.1
								if performance_preset>1
									performance_preset=performance_preset-1;
									disp('Decreasing processor load')
								end
								msg_displayed=0;
							elseif time_consumed < 1/framerate-0.1
								if performance_preset< numel(performance_settings_int_area)
									performance_preset=performance_preset+1;
									disp('Increasing processor load')
								end
								msg_displayed=0;
							else
								if msg_displayed==0
									disp(['Processor load optimal (int_area = ' int2str(int_area) ', step = ' int2str(step) ])
									msg_displayed=1;
								end
							end
							int_area=performance_settings_int_area(performance_preset);
							step=performance_settings_step(performance_preset);
						end
						
					end
					next=next+1;
				end
			end
			% SAVE calibration Image when live view is cancelled
			delete(findobj('tag','sharpness_display_text'));
			if triggermode==0 %calibration
				%{
				numbi = 0;
				imgA_path = fullfile(ImagePath, ['PIVlab_calibration' ,' (',num2str(numbi),')', '.tif']);
				while exist(imgA_path, 'file')
					numbi = numbi+1;
					imgA_path = fullfile(ImagePath, ['PIVlab_calibration' ,' (',num2str(numbi),')', '.tif']);
				end
				imwrite(ima,imgA_path);
				%}
				set(image_handle,'CData',ima);
			end
			
			%this will remove all pending buffers in the queue
			errorCode = calllib('PCO_CAM_SDK', 'PCO_CancelImages', out_ptr);
			pco_errdisp('PCO_CancelImages',errorCode);
			
			[errorCode,~,buflist] = calllib('PCO_CAM_SDK','PCO_WaitforBuffer', out_ptr,bufcount,buflist,500);
			pco_errdisp('PCO_WaitforBuffer',errorCode);
		end
		
		%end %% jump here when user only wants to measure framerate...
		subfunc.fh_stop_camera(out_ptr);
		
		for n=1:bufcount
			errorCode = calllib('PCO_CAM_SDK','PCO_FreeBuffer',out_ptr,bufnum(n));
			if(errorCode)
				pco_errdisp('PCO_FreeBuffer',errorCode);
			end
		end
		
	catch ME
		disp(ME)
		errorCode=subfunc.fh_lasterr();
		txt=blanks(101);
		try
			txt=calllib('PCO_CAM_SDK','PCO_GetErrorTextSDK',pco_uint32err(errorCode),txt,100);
			calllib('PCO_CAM_SDK', 'PCO_CancelImages', out_ptr);
			for n=1:bufcount
				calllib('PCO_CAM_SDK','PCO_FreeBuffer',out_ptr,bufnum(n));
			end
			if(glvar.camera_open==1)
				glvar.do_close=1;
				glvar.do_libunload=1;
				pco_camera_open_close(glvar);
			end
			if strfind(ME.identifier,'PCO_ERROR:')
				msg=[ME.identifier,' ',ME.message];
				warning('off','backtrace')
				warning(msg)
				disp(txt);
				for k=1:length(ME.stack)
					disp(['from file ',ME.stack(k).file,' at line ',num2str(ME.stack(k).line)]);
				end
				close();
				return;
			else
				close();
				rethrow(ME)
			end
		catch
			disp('Could not start camera.')
		end
	end
	
	if(glvar.camera_open==1)
		glvar.do_close=1;
		glvar.do_libunload=1;
		pco_camera_open_close(glvar);
	end
end

function [sharpness,sharpness_map]=sharpness_indicator (input_image,textx,texty)
skip=3;
diff_image=abs(diff(input_image(1:skip:end,1:skip:end))); %process only every 3rd pixel.... still works?
sharpness=std2(single(diff_image));
delete(findobj('tag','sharpness_display_text'));
text(textx,texty,['Sharpness: ' int2str(sharpness)],'Color',[1 1 0],'tag','sharpness_display_text','Horizontalalignment','right');


sharpness_map=[];
%{
fun = @(block_struct) std2(block_struct.data) * ones(size(block_struct.data));
blocksize_r=round(size(diff_image,1)/9);
blocksize_c=round(size(diff_image,2)/9);
sharpness_map = blockproc(diff_image,[blocksize_r blocksize_c],fun);
sharpness_map = rescale(sharpness_map);
sharpness_map=imresize(sharpness_map,size(input_image),'nearest');
%}