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

close all;
clear all;
clc;
more off;
page_output_immediately (1);
pkg unload all;

file_list = zenity_file_selection ("Select files to make the report", 'multiple');

for i = 1:length(file_list)
  load ("-text", [file_list{i}]);
  [DIR, NAME, EXT]= fileparts (file_list{i});
  NAME            = strrep (NAME, "octave_extracted_", "");
  if (numel(NAME) == 6)
    NAME          = strrep (NAME, "mage", "mage0");
  endif
  rep.file_name{i}= NAME;
  rep.rCon(i)     = profile.rCon*0.1;
  rep.sigma(i)    = profile.sigma*0.1;
  rep.theta(i)    = profile.theta;
  rep.nr(i)       = profile.nuclear_radius*0.1;
  rep.fInt(i)     = bleach.full_recovery;
  rep.PD_Df(i)    = pure_diffusion.Df;
  rep.FM2_Df(i)   = full_model_2.Df;
  rep.FM2_kon(i)  = full_model_2.kon;
  rep.FM2_koff(i) = full_model_2.koff;
  rep.FM2_ssr(i)  = full_model_2.grid(1,6);
  rep.FM3_Df(i)   = full_model_3.Df;
  rep.FM3_kon(i)  = full_model_3.kon;
  rep.FM3_koff(i) = full_model_3.koff;
  rep.BoundF(i)   = (rep.FM3_kon(i)/(rep.FM3_kon(i)+rep.FM3_koff(i)))*100;

  clear -exclusive rep file_list
endfor

PD_Df     = mean (rep.PD_Df);
FM2_Df    = mean (rep.FM2_Df);
FM2_kon   = mean (rep.FM2_kon);
FM2_koff  = mean (rep.FM2_koff);
FM2_ssr   = mean (rep.FM2_ssr);
FM3_Df    = mean (rep.FM3_Df);
FM3_kon   = mean (rep.FM3_kon);
FM3_koff  = mean (rep.FM3_koff);
BoundF    = mean (rep.BoundF);

sdPD_Df   = std (rep.PD_Df);
sdFM2_Df  = std (rep.FM2_Df);
sdFM2_kon = std (rep.FM2_kon);
sdFM2_koff= std (rep.FM2_koff);
sdFM2_ssr = std (rep.FM2_ssr);
sdFM3_Df  = std (rep.FM3_Df);
sdFM3_kon = std (rep.FM3_kon);
sdFM3_koff= std (rep.FM3_koff);
sdBoundF  = std (rep.BoundF);

[DIR, NAME, EXT] = fileparts (file_list{1});
filename = [DIR, filesep, "final_report.txt"];

if (exist (filename, "file"))
  error("File '%s' already exists. Will not overwrite.\n", filename);
elseif (exist (filename, "dir"))
  error("Directory with name '%s' already exists. File not created.\n", filename);
else
  [FID, MSG] = fopen (filename, "a");
  if (FID == -1)
    error ("Could not fopen file '%s': '%s'", filename, MSG);
  endif
endif

fdisp (FID, ["Final report from logs in directory ", DIR]);
fdisp (FID, "");
fdisp (FID, "------------------------------------------------------------------");
fdisp (FID, "  Image |   Final  |  Nucleus  |           |           |          ");
fdisp (FID, "   Name |   Value  |   size    |    rCon   |   sigma   |   theta  ");
fdisp (FID, "------------------------------------------------------------------");

for i = 1:length(file_list)
  fprintf (FID, "%s | % 8.5f | % 9.5f | %9.5f | %9.5f | %8.5f\n", rep.file_name{i}, rep.fInt(i), rep.nr(i), rep.rCon(i), rep.sigma(i), rep.theta(i));
endfor

fdisp (FID, "");
fdisp (FID, "---------------------------------------------------------------------------------------------------|----------");
fdisp (FID, "  Image |   Pure D  |          Full Model 2 parameteres          |       Full Model 3 parameters   |   Bound  ");
fdisp (FID, "   Name |     Df    |     Df    |    Kon   |    koff  |    ssr   |     Df    |    Kon   |    koff  | Fraction ");
fdisp (FID, "---------------------------------------------------------------------------------------------------|----------");

for i = 1:length(file_list)
  fprintf (FID, "%s | % 9.5f | % 9.5f | %8.5f | %8.5f | %8.5f | % 9.5f | % 8.5f | % 8.5f | % 6.1f%%\n", rep.file_name{i}, rep.PD_Df(i), rep.FM2_Df(i), rep.FM2_kon(i), rep.FM2_koff(i), rep.FM2_ssr(i), rep.FM3_Df(i), rep.FM3_kon(i), rep.FM3_koff(i), rep.BoundF(i));

endfor

fdisp (FID, "---------------------------------------------------------------------------------------------------|----------");

fprintf (FID, "  Mean  | % 9.5f | % 9.5f | %8.5f | %8.5f | %8.5f | % 9.5f | % 8.5f | % 8.5f | % 6.1f%%\n", PD_Df, FM2_Df, FM2_kon, FM2_koff, FM2_ssr, FM3_Df, FM3_kon, FM3_koff, BoundF);

fprintf (FID, " StdDev | % 9.5f | % 9.5f | %8.5f | %8.5f | %8.5f | % 9.5f | % 8.5f | % 8.5f | % 6.1f%%\n", sdPD_Df, sdFM2_Df, sdFM2_kon, sdFM2_koff, sdFM2_ssr, sdFM3_Df, sdFM3_kon, sdFM3_koff, sdBoundF);

fclose (FID);
