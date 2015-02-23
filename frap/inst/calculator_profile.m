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

function [pf_matrix pf_distances] = calculator_profile (image_here, nFrames, nPre_bleach, nNorm, coord, radius)

  nCol = columns(image_here);
  nRow = rows(image_here);

  row_center	= coord(1);
  col_center	= coord(2);

  ## This creates a mask, the same size as a frame, with each value being the distance
  ## to the center of the bleach spot (and profile). This is calculated from the circle
  ## equation (x - a)^2 + (y - b)^2 = radius^2 where (a,b) is the center coordinates
  ## The distance is rounded before being placed in the matrix for later to be able to
  ## iterate through them.
  ## Note: On a memory efficient note, it could be better to use int16 instead of round
  ## which keeps the value as double integer.

  pf_mask = zeros(nRow, nCol);

  for iRow = 1:nRow
    for iCol = 1:nCol
      dist_center         = sqrt( ((iRow-row_center)^2) + ((iCol-col_center)^2) );
      pf_mask(iRow, iCol) = round(dist_center);
    endfor
  endfor


  ## This creates a matrix with average intensity values. Each column corresponds to a
  ## frame(time) and each row to the distance from the center.
  ## For this, it searches in the mask for the index of all elements that have a certain
  ## distance from the center and passes that index to another loop that gets the mean
  ## for each frame

  # It's more likely to use pf_matrix all values from a specific timeframe that all distances
  # since it's faster to read down a column than through a row, it makes more sense to have each
  # column correspond to a time frame. To make it easier to associate, all of pf_distances are 
  # also placed in one column
  pf_distances = (0:radius)';

  # The thing here is that you can't have an index for the matrix of value zero
  # so, the number of the row is not really the same value of the distance, but
  # the number of the row of the matrix, is the index to find the distance in
  # pf_distances

  zeros(rows(radius),nFrames);

  for iDistance = 0:radius(end)
    pf_ind = find(pf_mask == iDistance);
    for iImg = 1:nFrames
      cur_frame                   = image_here(:,:,iImg);
      pf_matrix(iDistance+1,iImg) = mean(cur_frame(pf_ind));
    endfor
  endfor

  ## Normalize the intensity values
  # This gets the average radial profile of nNorm pre-bleach frames. It is then used to divide
  # the post-bleach radial profile and "clean" whatever irregularities there could be there
  # from the start
  norm_factor   = mean(pf_matrix(:,nPre_bleach-nNorm+1 : nPre_bleach),2);

  for iImg = 1:nFrames
    pf_matrix(:,iImg) = pf_matrix(:,iImg) ./ norm_factor;
  endfor

endfunction
