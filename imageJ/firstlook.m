#! /usr/bin/octave -qf
##
## Copyright (C) 2010 Carnë Draug <carandraug+dev@gmail.com>
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 3 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program; if not, see <http://www.gnu.org/licenses/>.


% looks at the files from the ImageJ macro and saves the plots for a 1st analysis of the data
clear;

% GUI_file sets the user interface to select files for analysis
% 0 = no GUI, directory must be set in variable dirname
% 1 = GUI asks for directory
% 2 = GUI asks for multiple files
GUI_file = 1;

% GUI_timestamps sets the user interface to select files for analysis
% 0 = no GUI, file is called timestamps and is in current working directory
% 1 = GUI asks for file with timestamps
% 2 = no GUI, file is called timestamps and is in the same directory as FRAP values (incompatible with GUI_file == 2)
GUI_timestamps = 1;

script_version = "1.0.03";
start_dir = pwd;

if (GUI_timestamps == 0)
	load ("timestamps");
endif

switch (GUI_file)
	case 0
		dirname = "/home/carandraug/Documents/2010-02-05 H4 R45H fast recovery"; % sets directory to check
	case 1
		dirname = zenity_file_selection("Choose a directory", 'directory'); %asks for directory
	case 2
		file_list = zenity_file_selection("Choose files to analyze", 'multiple'); %asks for several files
endswitch

if (GUI_timestamps == 1)
	timestamps = zenity_file_selection("Choose files with timestamps");
	load (timestamps);
endif

if (GUI_file == 0 | 1)
	cd (dirname);
	[file_list,err,msg] = readdir (dirname); %If successful, err is 0 and msg is an empty string. Otherwise, err is nonzero and msg contains a system-dependent error message.
	if (GUI_timestamps == 2)
		load ("timestamps");
	endif
endif

for i = 1:1:length(file_list)
	if (regexp (file_list{i}, "txt$"))
		plot_numbers = [dirname, filesep, file_list{i}, "plotted.txt"];
%		plot_control = [dirname, filesep, file_list{i}, "control.png"];
		plot_image =  [dirname, filesep, file_list{i}, "plot.png"];
		data = load (file_list{i});
		background_mean = mean (data(:,3));
		FRAP_treated = (data(:,1) - background_mean)./(data(:,2) - background_mean);
		FRAP_normalized = FRAP_treated ./ mean(FRAP_treated(1:100));
		mt = [timestamps,data,FRAP_normalized];
		%%the first time in the loop will give an error since there's no number of collums
		%%next time in the loop will concatenate the column
		%%same as eval but supposedly more efficient
		try
			all_normalized(:,columns(all_normalized)+1) = mt(:,5);
		catch
			all_normalized = mt(:,5);
		end_try_catch
		if ((!exist (plot_numbers, "file")) & (!exist (plot_numbers, "dir")))
			fid = fopen (plot_numbers, "a");
			fdisp (fid, ["### file created with first look script version ", script_version]);
			fdisp (fid, "### 1st collumn artimestamps");
			fdisp (fid, "### 2nd collumn are intensity values in bleached area");
			fdisp (fid, "### 3nd collumn are intensity values in bleached area during control frames");
			fdisp (fid, "### 4nd collumn are intensity values in background area");
			fdisp (fid, "### 5nd collumn are normalized, post-treatment, intensity values in bleached area");
			fdisp (fid, mt);
			fclose (fid);
		else
			warning ("File %s already exists. Will not save values for text file.\n", plot_numbers);
		endif
		figure (1, "visible", "off")
		%% work subplots here. Maybe just one picture all graphs. Must count number of txt first
		subplot(2, 1, 1)
		plot (mt(:,1), mt(:,5))
		axis ([0 17 0.5 1.2])
		subplot(2, 1, 2)
		plot (mt(:,1), mt(:,2:4))
		axis ([0 17 0 60])
		print (plot_image, "-dpng")
	endif
endfor
print (plot_image, "-dpng")
clf; #cleans options for plotting
plot_final =  [dirname, filesep, "all_average_plot.png"];
all_average = mean (all_normalized, 2);
plot (timestamps, all_average)
		axis ([0 17 0.5 1.2])
print (plot_final, "-dpng")
cd (start_dir);
