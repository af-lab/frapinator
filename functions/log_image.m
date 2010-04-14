function log_image (avg, pre, post, bleach, bd_bkg, bd_bl, bd_nc, filedir, filename);

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
  imwrite (canvas, [filedir, filesep, "masks_", filename, ".tif"]);

endfunction
