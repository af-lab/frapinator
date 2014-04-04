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
function [bin_time bin_rec] = calculator_log_binning (bl_avg, times, nPre_bleach, nFrames, bin_start);

  ## Remove pre-bleach and set time start to zero
  times   = times(nPre_bleach+1:end) - times(nPre_bleach+1);
  bl_avg  = bl_avg(nPre_bleach+1:end);

  ## Calculate last time when bleach

  ## Get log of time
  log_times = log10(times);
  ## Skip binning of bin_start frames
  bin_rec(1:bin_start)  = bl_avg(1:bin_start);  bin_time(1:bin_start) = times(1:bin_start);

  ## Length of binning interval on logarithmic scale  bin_int = abs(log_times(bin_start)-log_times(bin_start+1));  ## Logarithmic binning  cur_int     = 0;  iBin_rec    = bin_start+1;  iBin_start  = bin_start+1;  iBin_end    = bin_start+1;  for i = bin_start+1: (length(log_times)-1)    cur_int = cur_int + abs(log_times(i)-log_times(i+1));
    if cur_int > bin_int      iBin_end = i;
      bin_rec(iBin_rec)   = mean(bl_avg(iBin_start:iBin_end));      bin_time(iBin_rec)  = (times(iBin_start) + times(iBin_end)) / 2;
      iBin_start  = i+1;
      cur_int     = 0;
      iBin_rec    = iBin_rec +1;    endif  endfor
endfunction
