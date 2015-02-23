## Copyright (C) 2008-2010 Florian Mueller
## Copyright (C) 2008-2010 Davide Mazza <shiner80@gmail.com>
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

function [ind, boundaries] = finder_background(image_here, bg_size)

  # Sanity checks
  nRow = rows(image_here);
  nCol = columns(image_here);

  if (bg_size > nRow || bg_size > nCol)
    error("Size choosen for background area is larger than image. Image has %g[px] of width and %g[px] of heigth while the background area is asked to have %g[px] of size", nCol, nRow, bg_size)
  elseif (nRow == bg_size)
    warning("Heigth of the image (%g) is the same as the heigth of the background area (%g).", nRow, bg_size)
  elseif (nCol == bg_size)
    warning("Width of the image (%g) is the same as the width of the background area (%g).", nRow, bg_size)
  endif

  # Make convolution matrix
  bg_mask     = ones(bg_size);
  conv_matrix = conv2(double(image_here), bg_mask, 'valid');

  # Find minimum of the convolution matrix
  # If there's more than one vale in the convuluted matrix with the minimum value,
  # it gives only the first one
  conv_min = min(conv_matrix(:));
  [coord(1), coord(2)] = find(conv_matrix == conv_min, 1, 'first');
  fRow = coord(1)+bg_size-1;
  fCol = coord(2)+bg_size-1;


  # Create mask and get the index for background
  im_mask = zeros(nRow, nCol);
  im_mask (coord(1):fRow, coord(2):fCol) = 1;
  ind = find(im_mask > 0);

  boundaries = bwconncomp (im_mask);
  boundaries = boundaries.PixelIdxList{1};
endfunction
