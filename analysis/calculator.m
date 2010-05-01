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
function data = data_reader (files)
  for i = 1:numel(files)
    load ("-text", files{i});
#    data.filename{i}    = files{i};
#    data.PD_Df(i)       = pure_diffusion.Df * 0.01;
#    data.FM2_kon(i)     = full_model_2.kon;
#    data.FM2_koff(i)    = full_model_2.koff;
#    data.FM3_Df(i)      = full_model_3.Df;
    data.FM3_kon(i)     = full_model_3.kon;
    data.FM3_koff(i)    = full_model_3.koff;
    data.bound_frac(i)  = ( data.FM3_kon(i) / (data.FM3_kon(i) + data.FM3_koff(i)) )*100;
#    data.resid_time(i)  = (1 / data.FM3_koff(i));
    clear -exclusive files data;
  endfor
endfunction
################################ Code starts here ##############################

files = pick_files;
data  = data_reader(files);
## Bound fraction is Koff / (Kon + Koff) therefore its error is (s = sigma)
##
## sKoff/Koff + (sKon + sKoff)/(Kon + Koff)

kon_average   = mean(data.FM3_kon(:));
kon_sigma     = std(data.FM3_kon(:));

koff_average  = mean(data.FM3_koff(:));
koff_sigma    = std(data.FM3_koff(:));

BdFr_average  = mean(data.bound_frac(:));
BdFr_sigma    = ((koff_sigma/koff_average)+((kon_sigma+koff_sigma)/(kon_average+koff_average))) * BdFr_average;

printf("This data has an average bound fraction of %g +/- %g\n", BdFr_average, BdFr_sigma);
###############################
############### End of the code
###############################

