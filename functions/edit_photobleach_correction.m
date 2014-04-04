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

function image_here = edit_photobleach_correction (image_here, nPre_bleach, nFrames, nc_avg, flag)

  switch flag
    case 0
      factor = nc_avg(nPre_bleach) ./ nc_avg;
    case 1
      factor(1:nPre_bleach) = nc_avg(nPre_bleach) ./ nc_avg(1:nPre_bleach);
      factor(nPre_bleach+1:nFrames) = nc_avg(nPre_bleach+1) ./ nc_avg(nPre_bleach+1:nFrames);
  endswitch

  for i = 1: nFrames
    image_here(:,:,i) = image_here(:,:,i) * factor(i);
  endfor

endfunction
