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
################# Complain about the exit of zenity functions
function complain (status, what)

  if (status != 0)
    message = sprintf("You must select .", what);
    mes = zenity_message (message,
                          "type", "question",
                          "title", "FRAPINATOR analysis",
                          "width", 250,
                          "ok button", "pick again",
                          "cancel button", "exit");
    if (mes == 1)
      exit
    endif
  endif

endfunction
################# Set the type of comparison
function option = comparison_selector()
  cols    = {"", "secret values", "Type of comparison"};
  choices = {"true" , "1", "all time points",
             "false", "2", "limit by data points",
             "false", "3", "limit by seconds",
             "false", "4", "compare models",
             "false", "5", "scatterplot (change models)",
             "false", "6", "scatterplot (change files)",
             "false", "7", "\"bar\" plots for parameters"};
  do
    [option, ex_sta] = zenity_list(cols, choices,
                                   "text", "Select the type of comparison to be made",
                                   "radiolist",
                                   "hide column", 2,
                                   "print column", 2,
                                   "height", 140 + (rows(choices)*25),
                                   "title", "FRAPINATOR analysis",
                                   "numeric output", "error");
    complain (ex_sta, "a comparison type");
  until (ex_sta == 0)
endfunction
################# Pick the number of graphs to make
function [nRow, nCol] = pick_graph_number()

  cols    = {"", "Graphs", "Rows", "Columns"};
  choices = {"false", "1", "1", "1",
             "true" , "2", "1", "2",
             "false", "2", "2", "1",
             "false", "3", "1", "3",
             "false", "4", "2", "2",
             "false", "6", "2", "3",
             "false", "6", "3", "2"};
  do
    [template, ex_sta] = zenity_list(cols, choices,
                                     "text", "Select the number of graphs you want",
                                     "title", "FRAPINATOR analysis",
                                     "radiolist",
                                     "print column", [3,4],
                                     "height", 140 + (rows(choices)*25),
                                     "numeric output", "error");
    complain (ex_sta, "the number of graphs to see");
  until (ex_sta != 1)

  nRow = template(1);
  nCol = template(2);

endfunction
################# Pick interval of the graphs
function Int = pick_interval(comparison)

  do
    [interval, ex_sta] = zenity_entry("Set the interval in the format start-final, eg.: 1-100.",
                                      "title", "FRAPINATOR analysis",
                                      "width", 250);
    complain (ex_sta, "a time interval");
  until (ex_sta != 1)

  ind   = index (interval, "-");
  Int = [str2double(interval(1:ind-1)), str2double(interval(ind+1:end))];

endfunction

################# Pick number of bars in the bar plots
function bars = pick_bar_numel

  do
    [bars, ex_sta] = zenity_entry("Set the number of \"bars\" in the plot.",
                                  "title", "FRAPINATOR analysis",
                                  "width", 250);
    complain (ex_sta, "a number");
    [bars, ex_sta] = str2double(bars);
    complain (ex_sta, "a valid number");
  until (ex_sta != 1)

endfunction

################# Pick the model to show
function model = pick_model(comparison);

  cols    = {"", "secret values", "Data"};
  choices = {"false",  "1", "Raw data",
             "false",  "2", "Profile",
             "false",  "3", "Pure diffusion",
             "false",  "4", "Full model (kon and koff)",
             "false",  "5", "Full model (Df, kon and koff)",
             "false",  "6", "Kon/Koff",
             "false",  "7", "Koff/Df",
             "false",  "8", "Bound/Df",
             "false",  "9", "tr/Df",
             "false", "10", "Kon (fitting 3)",
             "false", "11", "Koff (fitting 3)",
             "false", "12", "Df (pure diffusion)",
             "false", "13", "Bound fraction (fitting 3)",
             "false", "14", "Residence time (fitting 3)"};

  switch comparison
    case { 1, 2, 3, 4 }
      choices = choices(1:5,:);
    case { 5, 6 }
      choices = choices(6:9,:);
    case { 7, 8 }
      choices = choices(10:14,:);
    otherwise
      error("Unknown comparison '%i' to select model", comparison)
  endswitch

  do
    [model, ex_sta] = zenity_list(cols, choices,
                                   "title", "FRAPINATOR analysis",
                                   "text", "Select the model you want to see",
                                   "radiolist",
                                   "hide column", 2,
                                   "print column", 2,
                                   "height", 140 + (rows(choices)*25),
                                   "numeric output", "error");
    complain (ex_sta, "a model");
  until (ex_sta != 1)

endfunction
################# Pick the title
function gTitle = pick_title(iGraph);

  graph.entry = sprintf("Enter the title for the graph %g", iGraph);
  do
    [gTitle, ex_sta] = zenity_entry (graph.entry, 
                                      "title", "FRAPINATOR analysis",
                                      "width", 250);
    complain (ex_sta, "a title, even if empty");
  until (ex_sta == 0)

endfunction
################# Pick the files
function files = pick_files();

  do
    [files, ex_sta] = zenity_file_selection ("multiple",
                                             "title", "FRAPINATOR analysis",
                                             "filter", "*.txt",
                                             "filter", "*");
    complain (ex_sta, "at least one file")
  until (ex_sta == 0)

endfunction
################# Read data from the text files
function data = data_reader (files, model)
## Models:
##  1 - Raw data
##  2 - Profile
##  3 - Pure diffusion
##  4 - Full model (kon and koff)
##  5 - Full model (Df, kon and koff)
##  6 - Scatterplot Kon / Koff
##  7 - Scatterplot Koff / Df
##  8 - Scatterplot Bound fraction / Df
##  9 - Scatterplot residence time / Df
## 10 - Bar: Kon (fitting 3)
## 11 - Bar: Koff (fitting 3)
## 12 - Bar: Df (pure diffusion)
## 13 - Bar: bound fraction (fitting 3)
## 14 - Bar: residence time (fitting 3)

  for i = 1:numel(files)
    if( isempty(files{i}) )   # When comparison is 7, some file list may have empty entries at the end
      break
    endif
    load ("-text", files{i});
    data(i).filename    = files{i};

    switch model
      case 1
        data(i).raw_times  = image.timestamps(options.nPre_bleach+1:end);
        data(i).bin_times  = log_bin.timestamps;
        data(i).raw_frap    = bleach.normalized_xy_mean(options.nPre_bleach+1:end);
        data(i).bin_frap    = log_bin.normalized_xy_mean;
      case 2
        data(i).profile     = profile.normalized_intensities(options.nSkip_profile:end,options.nPre_bleach+1);
        data(i).profile_fit = profile.fitted;
        data(i).rCon        = profile.rCon;
        data(i).sigma       = profile.sigma;
        data(i).theta       = profile.theta;
        data(i).nr          = profile.nuclear_radius;

      case 3
        data(i).raw_times  = image.timestamps(options.nPre_bleach+1:end);
        data(i).bin_times  = log_bin.timestamps;
        data(i).PD_fit      = pure_diffusion.yFitted;
        data(i).PD_Df       = pure_diffusion.Df * 0.01;

      case 4
        data(i).raw_times  = image.timestamps(options.nPre_bleach+1:end);
        data(i).bin_times  = log_bin.timestamps;
        data(i).FM2_fit     = full_model_2.yFitted;
        data(i).FM2_Df      = full_model_2.Df * 0.01;
        data(i).FM2_kon     = full_model_2.kon;
        data(i).FM2_koff    = full_model_2.koff;
#        data(i).FM2_ssr     = full_model_2.grid(1,6);

      case 5
        data(i).raw_times  = image.timestamps(options.nPre_bleach+1:end);
        data(i).bin_times  = log_bin.timestamps;
        data(i).FM3_fit     = full_model_3.yFitted;
        data(i).FM3_Df      = full_model_3.Df * 0.01;
        data(i).FM3_kon     = full_model_3.kon;
        data(i).FM3_koff    = full_model_3.koff;

      case { 6, 7, 8, 9, 10, 11, 12, 13, 14 }
        data(i).PD_Df       = pure_diffusion.Df * 0.01;
        data(i).FM2_kon     = full_model_2.kon;
        data(i).FM2_koff    = full_model_2.koff;
        data(i).FM3_Df      = full_model_3.Df;
        data(i).FM3_kon     = full_model_3.kon;
        data(i).FM3_koff    = full_model_3.koff;
        data(i).bound_frac  = ( data(i).FM3_kon / (data(i).FM3_kon + data(i).FM3_koff) )*100;
        data(i).resid_time  = (1 / data(i).FM3_koff);

      otherwise
        error("Unknown model value '%g'", model)
    endswitch
    clear -exclusive files data model;
  endfor
endfunction
################# Show the loaded data and remove some
function data = data_show (data, model);
## Models:
##  1 - Raw data
##  2 - Profile
##  3 - Pure diffusion
##  4 - Full model (kon and koff)
##  5 - Full model (Df, kon and koff)
##  6 - Scatterplot Kon / Koff
##  7 - Scatterplot Koff / Df
##  8 - Scatterplot Bound fraction / Df
##  9 - Scatterplot residence time / Df
## 10 - Bar: Kon (fitting 3)
## 11 - Bar: Koff (fitting 3)
## 12 - Bar: Df (pure diffusion)
## 13 - Bar: bound fraction (fitting 3)
## 14 - Bar: residence time (fitting 3)

  switch model
    case 3
      cols    = {"", "secret values", "Df", "filenames"};
      choices = cell(4, numel(data));
      for i=1:numel(data)
        choices(:,i) = {"false", num2str(i), num2str(data(i).PD_Df), data(i).filename};
      endfor
      choices = choices';
    case 4
      cols    = {"", "secret values", "Kon", "Koff", "Df", "filenames"};
      choices = cell(6, numel(data));
      for i=1:numel(data)
        choices(:,i) = {"false", num2str(i), num2str(data(i).FM2_kon), num2str(data(i).FM2_koff), num2str(data(i).FM2_Df), data(i).filename};
      endfor
      choices = choices';
    case 5
      cols    = {"", "secret values", "Kon", "Koff", "Df", "filenames"};
      choices = cell(6, numel(data));
      for i=1:numel(data)
        choices(:,i) = {"false", num2str(i), num2str(data(i).FM3_kon), num2str(data(i).FM3_koff), num2str(data(i).FM3_Df), data(i).filename};
      endfor
      choices = choices';
    otherwise
      error ("Unknow value for model. Received '%g'", model);
  endswitch

  ## Does not check exit status because it is either 0, 1 or 256
  ##   0 - User pressed OK (that's good)
  ##   1 - User pressed cancel (he doesn't want to remove any file, returns empty, that's good)
  ## 256 - User pressed OK (that's good)
  [indexes, ex_sta] = zenity_list(cols, choices,
                                 "title", "FRAPINATOR analysis",
                                 "text", "Select any value to be removed from the graph",
                                 "checklist",
                                 "hide column", [2,columns(choices)], # Hide the second (secret values) and the last (filenames) column
                                 "print column", 2,
                                 "height", 140 + (rows(choices)*25),
                                 "numeric output", "error");
  if (ex_sta == 0)
    data(indexes) = [];
  endif

endfunction
################# Make the graphs
function [xMin, xMax, yMin, yMax] = graph_maker (data, model, top, interval)

  persistent xMin xMax yMin yMax xBar;

  if (strcmpi(data, "clear"))
    xMin = xMax = yMin = yMax = xBar = [];
    return
  endif

  if (isempty(xBar))
    xBar = 1;
  else
    xBar++;
  endif

  if (interval)
    start = interval(1);
    final = interval(2);
  else
    start = 1;
    final = Inf;
  endif

  colors = {"black", "red", "green", "blue", "magenta", "cyan"};
  iColor = 1;
  for i=1:numel(data)

    switch model
      case 1
        plot (data(i).raw_times(start:min(final,end)), data(i).raw_frap(start:min(final,end)), "color", colors{iColor});
        hold on;
        axis ([0 data(i).raw_times(min(final,end)) 0.4 0.9])
      case 3
        plot (data(i).bin_times(start:min(final,end)), data(i).PD_fit(start:min(final,end)), "color", colors{iColor});
        hold on;
        axis ([0 data(i).bin_times(min(final,end)) 0.4 0.9])
      case 4
        plot (data(i).bin_times(start:min(final,end)), data(i).FM2_fit(start:min(final,end)), "color", colors{iColor});
        hold on;
        axis ([0 data(i).bin_times(min(final,end)) 0.4 0.9])
      case 5
        plot (data(i).bin_times(start:min(final,end)), data(i).FM3_fit(start:min(final,end)), "color", colors{iColor});
        hold on;
        axis ([0 data(i).bin_times(min(final,end)) 0.4 0.9])
      case 5
        plot (data(i).bin_times(start:min(final,end)), data(i).FM3_fit(start:min(final,end)), "color", colors{iColor});
        hold on;
        axis ([0 data(i).bin_times(min(final,end)) 0.4 0.9])
      case { 6, 7, 8, 9 }
        switch model
          case { 6 }
            xTag  = "Kon";
            yTag  = "Koff";
            xData = data(i).FM3_kon;
            yData = data(i).FM3_koff;
          case { 7 }
            xTag  = "Koff";
            yTag  = "Df";
            xData = data(i).FM3_koff;
            yData = data(i).PD_Df;
          case { 8 }
            xTag  = "Bound fraction";
            yTag  = "Df";
            xData = data(i).bound_frac;
            yData = data(i).PD_Df;
          case { 9 }
            xTag  = "Residence time";
            yTag  = "Df";
            xData = data(i).resid_time;
            yData = data(i).PD_Df;
        endswitch
        if ( isempty(xMin) ) # so do all the others
          xMin = xData;
          xMax = xData;
          yMin = yData;
          yMax = yData;
        else
          if (xMin > xData) xMin = xData; endif
          if (xMax < xData) xMax = xData; endif
          if (yMin > yData) yMin = yData; endif
          if (yMax < yData) yMax = yData; endif
        endif
        plot(xData, yData, ...
              "MarkerSize", 10, ...
              "color", "red", ...
              "marker", "o", ...
              "LineStyle", "none");
        hold on;
        xlabel(xTag);
        ylabel(yTag);

      case { 10, 11, 12, 13 }
        switch model
          case { 10 }
            yData = data(i).FM3_kon;
          case { 11 }
            yData = data(i).FM3_koff;
          case { 12 }
            yData = data(i).PD_Df;
          case { 13 }
            yData = data(i).bound_frac;
          case { 14 }
            yData = data(i).resid_time;
        endswitch
        xData = xBar;
        plot(xData, yData, ...
              "MarkerSize", 10, ...
              "color", "red", ...
              "marker", "o", ...
              "LineStyle", "none");
        hold on;

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

## Comparisons:
##  1 - all time points
##  2 - limit by points
##  3 - limit by seconds
##  4 - compare models
##  5 - Scatterplots (change models)
##  6 - Scatterplots (change files)
##  7 - Bar plot with dots (change models)
##  8 - Bar plot with dots (change files) Is this really needed?? Use semilogy
##  9 - Kon Koff best guesses
## 10 - Specify variables and draw the function

##
## Models:
##  1 - Raw data
##  2 - Profile
##  3 - Pure diffusion
##  4 - Full model (kon and koff)
##  5 - Full model (Df, kon and koff)
##  6 - Scatterplot Kon / Koff
##  7 - Scatterplot Koff / Df
##  8 - Scatterplot Bound fraction / Df
##  9 - Scatterplot residence time / Df
## 10 - Bar: Kon (fitting 3)
## 11 - Bar: Koff (fitting 3)
## 12 - Bar: Df (pure diffusion)
## 13 - Bar: bound fraction (fitting 3)
## 14 - Bar: residence time (fitting 3)


comparison    = comparison_selector();
if (comparison == 2 || comparison == 3)
  interval = pick_interval (comparison);
else
  interval = [0,0];
endif

[nRow, nCol]  = pick_graph_number();

switch comparison
  case { 1, 2, 3 }                                        # Frap recoveries
    model         = pick_model(comparison);

    for iGraph = 1:(nRow*nCol)
      graph.title = pick_title(iGraph);
      graph.files = pick_files();
      graph.data  = data_reader (graph.files, model);
      if (model != 1)
        graph.data  = data_show (graph.data, model);
      endif

      switch comparison
        case { 2 }
          # Do nothing, it's good
        case { 3 }
          # Calculate times or maybe this should happen in graph_maker
        otherwise
          interval = [0, 0];
      endswitch
      subplot(nRow, nCol, iGraph)
      graph_maker (graph.data, model, graph.title, interval);
      clear graph;
    endfor

  case { 4 }                                              # Compare models (frap recoveries)
    comp.files = pick_files();
    for iGraph = 1:(nRow*nCol)
      model       = pick_model(comparison);
      graph.title = pick_title(iGraph);
      graph.data  = data_reader (graph.files, model);
      subplot(nRow, nCol, iGraph)
      graph_maker (graph.data, model, graph.title);
      clear graph;
    endfor

  case { 5 }                                              # Scatterplots (change models)
    files = pick_files();
    for iGraph = 1:(nRow*nCol)
      graph.model = pick_model(comparison);
      graph.title = pick_title(iGraph);
      graph.data  = data_reader (files, graph.model);
#      graph.data  = data_show (graph.data, model);
      subplot(nRow, nCol, iGraph)
      graph_maker (graph.data, graph.model, graph.title, interval);
      clear graph;
    endfor

  case { 6 }                                              # Scatterplots (change files)
    model = pick_model(comparison);
    for iGraph = 1:(nRow*nCol)
      graph.files = pick_files();
      graph.title = pick_title(iGraph);
      graph.data  = data_reader (graph.files, model);
#      graph.data  = data_show (graph.data, model);
      subplot(nRow, nCol, iGraph)
      [xMin, xMax, yMin, yMax] = graph_maker (graph.data, model, graph.title, interval);
      clear graph;
    endfor
    ## Re-adjust the axis of each plot so they are all on the same scale
    for iGraph = 1:(nRow*nCol)
      subplot(nRow, nCol, iGraph)
      axis([xMin, xMax, yMin, yMax])
    endfor

  case { 7 }                                              # Bar plot with dots
    bars        = pick_bar_numel;
    titles      = cell(1,bars);
    first_time  = 1;
    for iGraph = 1:(nRow*nCol)
      model           = pick_model(comparison);
      titles(iGraph)  = pick_title(iGraph);
      if (first_time)
        for iBar = 1:bars
          files = pick_files();
          if (first_time)
            file_list = files;
          else
            for iCat = 1:numel(files)
              file_list{iCat,iBar} = files{iCat};
            endfor
          endif
          graph.data  = data_reader (file_list(:,iBar), model);
          subplot(nRow, nCol, iGraph)
          graph_maker (graph.data, model, titles{iGraph}, interval);
          clear graph;
          first_time = 0;
        endfor
        graph_maker ("clear");
      else
        for iBar = 1:bars
          graph.data  = data_reader (file_list(:,iBar), model);
          subplot(nRow, nCol, iGraph)
          graph_maker (graph.data, model, titles{iGraph}, interval);
          clear graph;
        endfor
        graph_maker ("clear");
      endif
      axis([0,bars+1])
    endfor

  otherwise
    error("Unrecognized comparison type %i.", comparison);
endswitch

## Save file?
to_save = zenity_message ("Save this graph?",
                          "title", "FRAPINATOR analysis",
                          "ok button", "yes",
                          "cancel button", "no",
                          "type", "question");
if(to_save == 0)
  save_path = zenity_file_selection ("save", "filter", "*.png", "filter", "*");
  if ( isempty(regexpi(save_path, "\\.png$")) )
    save_path = sprintf("%s.png", save_path);
  endif
  print (save_path, "-dpng", "-S1680,1050")
endif
###############################
############### End of the code
###############################
