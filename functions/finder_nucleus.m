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
  thres_image = bwfill(thres_image, "holes");

  # Create mask for the bleached cell nucleus using the bleach coordinates to find the right object
  nc_mask = bwselect(thres_image, bl_coord(2), bl_coord(1));
  nc_ind = find(nc_mask > 0);

  boundaries = bwconncomp (nc_mask);
  boundaries = boundaries.PixelIdxList{1};
endfunction
