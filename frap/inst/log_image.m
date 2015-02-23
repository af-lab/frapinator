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

function log_image (avg, pre, post, bleach, bd_bkg, bd_bl, bd_nc, filepath);

  ##sanity checks
  #should check if slicesd and masks are all the same size

  bleach = uint8(bleach);

  nRow = rows(avg);
  nCol = columns(avg);

  # Calculate the real white
  avg_white     = max(avg(:)) * (3/2);
  pre_white     = max(pre(:)) * (3/2);
  post_white    = max(post(:)) * (3/2);
  bleach_white  = max(bleach(:)) * (3/2);
  white = max([avg_white, pre_white, post_white, bleach_white]);

  # Draw the boundaries on the images
  avg(bd_bkg)   = white;
  avg(bd_nc)    = white;

  pre(bd_bkg)   = white;
  pre(bd_nc)    = white;

  post(bd_bl)   = white;

  bleach(bd_bl) = white;


  horz_line = uint8(ones(10, nCol) * white);
  vert_line = uint8(ones(nRow*2 +10, 10) * white);

  canvas = horzcat( vertcat(avg, horz_line, pre), vert_line, vertcat(bleach, horz_line, post));

  #Adjust the image brightness
  canvas = canvas * (intmax("uint8")/white);
  # Creates and saves log image
  imwrite (canvas, filepath);

endfunction
