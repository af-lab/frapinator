function [xy_mean] = calculator_averages(image_here, nFrames, ind)

##Explanation
#creates a 4 dimensional matrix of the mask by repeating it on the 4th dimension.
#Then multiplies (element by element) the 4dimensional image with the 4dimensional mask (which is logical).
#sum of sum creates a 4 dimensional matrix with 1st, 2nd and 3rd dimensions of size 1
#with each frame (4th dimension) holding the sum of pixels values that are true (==1) in the mask
#squeeze gets rids of the extra dimensions and everything ens up in in one array.
#Finally, divides by the number of pixels that are true in the mask to get a by pixel average

# Sanity checks
#should confirm size of masks is the same as size of image



## Calculate average intensity of the thing given an index of one of the frames
  xy_mean = 0;
  for i = 1:nFrames
    cur_frame   = double(image_here(:,:,i));
    xy_mean(i)  = mean(cur_frame(ind));
  endfor

endfunction
