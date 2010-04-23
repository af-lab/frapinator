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

################################ Prepare workspace #############################
close all;
clear all;
clc;
more off;
page_output_immediately (1);
pkg unload all;
pkg load zenity;
################################ Define functions ##############################
################# Function to set the type of comparison
function option = comparison_selector()
  cols    = {"", "secret values", "Type of comparison"};
  choices = {"true" , "1", "all time points",
             "false", "2", "limit by seconds",
             "false", "3", "limit by points",
             "false", "4", "compare models"};
  do
    [option, ex_sta] = zenity_list(cols, choices,
                                   "text", "Select the type of comparison to be made",
                                   "radiolist",
                                   "hide column", 2,
                                   "print column", 2);
    if (ex_sta != 0)
      mes = zenity_message ("You must select one option. Press cancel to exit the program.",
                            "type", "question",
                            "title", "frapinator");
      if (mes == 1)
        exit
      endif
    endif
  until (ex_sta != 1)
  option = str2num(option);
endfunction
################# Function to read the data from text files
function data = data_reader (files)
for i = 1:numel(files)
  load ("-text", files{i});
  data(i).filename    = files{i};

  data(i).profile     = profile.normalized_intensities(options.nSkip_profile:end,options.nPre_bleach+1);
  data(i).profile_fit = profile.fitted;
  data(i).rCon        = profile.rCon;
  data(i).sigma       = profile.sigma;
  data(i).theta       = profile.theta;
  data(i).nr          = profile.nuclear_radius;

#  switch options.flag_fit_data
#    case 1
      data(i).frap        = log_bin.normalized_xy_mean;
      data(i).timestamps  = log_bin.timestamps;
#    case 2
#      data(i).frap        = bleach.normalized_xy_mean(options.nPre_bleach+1:end);
#      data(i).timestamps  = image.timestamps(options.nPre_bleach+1:end);
#    otherwise
#      error ("Non supported flag for data for fitting.\n")
#  endswitch

  data(i).PD_fit      = pure_diffusion.yFitted;
  data(i).PD_Df       = pure_diffusion.Df;

  data(i).FM2_fit     = full_model_2.yFitted;
  data(i).FM2_Df      = full_model_2.Df;
  data(i).FM2_kon     = full_model_2.kon;
  data(i).FM2_koff    = full_model_2.koff;
  data(i).FM2_ssr     = full_model_2.grid(1,6);

  data(i).FM3_fit     = full_model_3.yFitted;
  data(i).FM3_Df      = full_model_3.Df;
  data(i).FM3_kon     = full_model_3.kon;
  data(i).FM3_koff    = full_model_3.koff;
  data(i).bound_frac  = ( data(i).FM3_kon / (data(i).FM3_kon + data(i).FM3_koff) )*100;
  clear -exclusive files data;
endfor
endfunction
################# Function to pick the model to show
function model = pick_model();

  cols    = {"", "secret values", "Data"};
  choices = {"false", "1", "Profile",
             "false", "2", "Pure diffusion",
             "false", "3", "Full model (kon and koff)",
             "false", "4", "Full model (Df, kon and koff)"};
  do
    [model, ex_sta] = zenity_list(cols, choices,
                                   "text", "Select the model you want to see",
                                   "radiolist",
                                   "hide column", 2,
                                   "print column", 2);
    if (ex_sta != 0)
      mes = zenity_message ("You must select one option.",
                            "type", "warning",
                            "title", "frapinator");
#      if (mes == 1)
#        exit
#      endif
    endif
  until (ex_sta != 1)
  model = str2num (model);

endfunction
################# Function to show the loaded data and remove some
function data = data_show (data, model);

  switch model
    case 4
      cols    = {"", "secret values", "Kon", "Koff", "Df", "filenames"};
      choices = cell(6, numel(data));
      for i=1:numel(data)
        choices(:,i) = {"false", num2str(i), num2str(data(i).FM3_kon), num2str(data(i).FM3_koff), num2str(data(i).FM3_Df), data(i).filename};
      endfor
      choices = choices';
    otherwise
      error ("Unknow value for model. Received '%g'", model);
  endswitch

#  do
    [indexes, ex_sta] = zenity_list(cols, choices,
                                   "text", "Select any value to be removed from the graph",
                                   "checklist",
                                   "hide column", [2,6],
                                   "print column", 2);
#    if (ex_sta != 0 || ex_sta != 256)
#      mes = zenity_message ("You must select at least one file.",
#                            "type", "warning",
#                            "title", "frapinator");
##      if (mes == 1)
##        return
##      endif
#    endif
#  until (ex_sta != 1)

  if (ex_sta == 0)
    for i=1:numel(indexes)
      tmp(i) = str2num(indexes{i});
    endfor
    data(tmp) = [];
  endif

endfunction
################# Function to make the graphs
function graph_maker (data, model, top)

  colors = {"black", "red", "green", "blue", "magenta", "cyan"};
  iColor = 1;
  for i=1:numel(data)

    switch model
      case 4
        plot (data(i).timestamps, data(i).FM3_fit, "color", colors{iColor});
        hold on;
        axis ([0 data(i).timestamps(end) 0.3 1])
      otherwise
        error("Unknown model for graph_maker %g", model)
    endswitch
    iColor++;
    if (iColor > numel(colors))
      iColor = 1;
    endif
  endfor
  title(top)
endfunction

################################### Start code #################################


option = comparison_selector();
model  = pick_model;

## Graph 1
graph.title           = zenity_entry ("Enter the title for the 1st graph",
                                      "title", "Enter title");
[graph.files, ex_sta] = zenity_file_selection ("multiple",
                                                "filter", "*.txt",
                                                "filter", "*");
if (ex_sta != 0)
  error ("No file was selected to make the first graph. Exit code was '%g'.", ex_sta);
endif
graph.data  = data_reader (graph.files);
graph.data  = data_show (graph.data, model);
figure (1, "visible", "off")
subplot(1, 2, 1)
graph_maker (graph.data, model, graph.title);
clear graph;

## Graph 2
graph.title           = zenity_entry ("Enter the title for the 2nd graph",
                                      "title", "Enter title");
[graph.files, ex_sta] = zenity_file_selection ("multiple",
                                                "filter", "*.txt",
                                                "filter", "*");
if (ex_sta != 0)
  error ("No file was selected to make the first graph. Exit code was '%g'.", ex_sta);
endif
graph.data  = data_reader (graph.files);
graph.data  = data_show (graph.data, model);
figure (1, "visible", "off")
subplot(1, 2, 2)
graph_maker (graph.data, model, graph.title);
clear graph;

figure (1, "visible", "on")

to_save = zenity_message ("Save this graph?",
                          "type", "question",
                          "title", "frapinator");
if(to_save == 0)
  save_path = zenity_file_selection ("save", "filter", "*.png");
  if (!regexpi(save_path, "\\.png$"))
    save_path = sprintf("%s.png", save_path);
  endif
  print (save_path, "-dpng", "-S1680,1050")
endif

