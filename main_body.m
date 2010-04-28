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

################################################################################
################################ Start settings ################################
## Prepare workspace
close all;
clear all;
clc;
more off;
page_output_immediately (1);
pkg unload all;

pkg load zenity;
pkg load image;
pkg load optim; # leasqr belongs to optim package


## Get octave, loaded packages, and frapinator versions 
# Octave version
main.octave_version = version;

# Loaded packages version
[pkg_des, pkg_status] = pkg ("describe", "all");
pkg_store_i = 1;
for pkg_i = 1:columns(pkg_des)
  if ( strcmpi(pkg_status{pkg_i}, "loaded") )
    main.packages{pkg_store_i} = sprintf("%s: %s", pkg_des{pkg_i}.name, pkg_des{pkg_i}.version);
    pkg_store_i++;
  endif
endfor

# Frapinator version
bzr_cmd                   = sprintf("bzr version-info");
[bzr_status, main.revno]  = system (bzr_cmd);
if (bzr_status != 0)
  error ("Error when checking revision number with command '%s'. Exit code was '%g'", brz_cmd, bzr_status)
endif

## Set paths
cur_dir         = pwd;
paths.functions = [cur_dir, filesep, "functions", filesep];
paths.code      = [cur_dir, filesep, "code", filesep];
paths.files     = [cur_dir, filesep, "files", filesep];
addpath (paths.functions);

## Load user options
source ([paths.files, "options"]);

## Sanity checks
if (options.nNorm > options.nPre_bleach)
  error("The number of frames to use for normalization of values (%g) is larger than the number of pre-bleach frames (%g)", options.nNorm, options.nPre_bleach);
elseif (options.binning_start < 0 )
  error ("The number of frames that should be skipped before start binning is lower than zero (%g)", options.binning_start)
elseif (options.avg_start > options.avg_end)
  error ("The frame number to start averaging for finding background (%g), is after the frame number to end (%g)", options.avg_start, optons.avg_end)
elseif (options.pre_start > options.pre_end)
  error ("The frame number to start averaging for the pre-bleach image (%g), is after the frame number to end (%g)", options.pre_start, optons.pre_end)
elseif (options.post_start > options.post_end)
  error ("The frame number to start averaging for the post-bleach image (%g), is after the frame number to end (%g)", options.ost_start, optons.post_end)
endif

################################################################################
############################## Start user input ################################

source ([paths.code, "user_input"]);

paths.bar_handle = zenity_progress("title", "FRAPINATOR", ...
                                    "auto close", ...
                                    "width", 400);
######################## Start of the big loop #################################
for iGeneral = 1:length(main.file_list)

  file.path                             = main.file_list{iGeneral};
  [file.dir, file.name, file.extension] = fileparts(file.path);
  file.log_path                         = [file.dir, filesep, "masks_", file.name, ".tif"];
  file.extracted_path                   = [file.dir, filesep, "extracted_data_", file.name, ".txt"];
  file.plots_path                       = [file.dir, filesep, "plots_", file.name, ".png"];

  message = sprintf("Starting image %s", file.path);
  disp (message)

  try
    z_message = sprintf("Image %d of %d, processing", iGeneral, numel(main.file_list));
    zenity_progress(paths.bar_handle, ...
                    "text", z_message,
                    "percentage",  ((iGeneral-1)/numel(main.file_list))*100 );

    ## Read image, times and creates slices
    source([paths.code, "data_extraction"]);
    ## Finds ROIs, calculate averages, make corrections to data and calculate profile
    source([paths.code, "image_processing"]);
    ## Get rid of the image
    image = rmfield (image, "here");

    z_message = sprintf("Image %d of %d, fitting", iGeneral, numel(main.file_list));
    zenity_progress(paths.bar_handle, ...
                    "text", z_message,
                    "percentage",  ((iGeneral-0.5)/numel(main.file_list))*100 );


    ## Do all the fitting
    source([paths.code, "data_fitting"]);
  catch
    msg     = lasterror.message;
    message = sprintf("Error: %s \n Skipping image %s", msg, file.path);
    disp (message)
    clear -exclusive options main paths;
    continue
  end_try_catch

  # Save processed data (list of variables to save)
  save ("-text", file.extracted_path,
    "main", ...
    "options", ...
    "image", ...
    "backg", ...
    "nucleus", ...
    "bleach", ...
    "log_bin", ...
    "profile", ...
    "pure_diffusion", ...
    "full_model_2", ...
    "full_model_3")

  figure (1, "visible", "off")
  subplot(2, 3, 1)
  plot (image.timestamps, [backg.xy_mean; bleach.xy_mean; nucleus.xy_mean])
  title("Background, bleach and nucleus intensity")
  axis ([0 (image.timestamps(end)+1) 0 40])

  subplot(2, 3, 2)
  plot (image.timestamps, bleach.normalized_xy_mean)
  title("Normalized average of bleach intensity")
  axis ([0 (image.timestamps(end)+1) 0.2 1.2])

  subplot(2, 3, 3)
  plot (profile.distances(options.nSkip_profile+1:end), [profile.normalized_intensities(options.nSkip_profile+1:end,options.nPre_bleach+1), profile.fitted])
  title("Profile of the bleach spot")
  text (3,0.9, ["rCon = ", num2str(profile.rCon)])
  text (3,0.8, ["sigma = ", num2str(profile.sigma)])
  text (3,0.7, ["theta = ", num2str(profile.theta)])
  axis ([0 (profile.distances(end)) 0 1.2])

  subplot(2, 3, 4)
  plot (fitting_times, [fitting_intensities; pure_diffusion.yFitted'])
  title("Fitting for Pure Diffusion")
  text (20,0.5, ["Df = ", num2str(pure_diffusion.Df)])
  axis ([0 fitting_times(end) 0.2 1])

  subplot(2, 3, 5)
  plot (fitting_times, [fitting_intensities; full_model_2.yFitted'])
  title("Fitting with Full Model (Kon Koff)")
  text (20,0.4, ["Kon = ", num2str(full_model_2.kon)])
  text (20,0.3, ["Koff = ", num2str(full_model_2.koff)])
  axis ([0 fitting_times(end) 0.2 1])

  subplot(2, 3, 6)
  plot (fitting_times, [fitting_intensities; full_model_3.yFitted'])
  title("Fitting with Full Model (Kon Koff Df)")
  text (20,0.5, ["Df = ", num2str(full_model_3.Df)])
  text (20,0.4, ["Kon = ", num2str(full_model_3.kon)])
  text (20,0.3, ["Koff = ", num2str(full_model_3.koff)])
  axis ([0 fitting_times(end) 0.2 1])

  print (file.plots_path, "-dpng", "-S1680,1050")

  message = sprintf("Finished image %s", file.path);
  disp (message)
  clear -exclusive options main paths;

endfor
zenity_progress(paths.bar_handle, "close");
