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
