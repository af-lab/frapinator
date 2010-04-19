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
##

function [nc_ind, boundaries] = finder_nucleus(image_here, bl_coord, thres_value, thres_flag)

  # Make threshold
  switch thres_flag
    case 0
      level = graythresh(image_here);
      thres_image = im2bw(image_here, level);
    case 1
      thres_image = image_here > thres_value;
    otherwise
      error("WTF?")
endswitch

  # Erode, dilate, dilate, fill holes
  thres_image = bwmorph (thres_image, 'erode');
  thres_image = bwmorph (thres_image, 'dilate');
  thres_image = bwmorph (thres_image, 'dilate');
  thres_image = bwmorph (thres_image, 'erode');
  thres_image = bwfill (thres_image, "holes");

  # Create mask for the bleached cell nucleus using the bleach coordinates to find the right object
  nc_mask = bwselect(thres_image, bl_coord(2), bl_coord(1));
  nc_ind = find(nc_mask > 0);

  boundaries = bwconncomp (nc_mask);
  boundaries = boundaries.PixelIdxList{1};
endfunction
