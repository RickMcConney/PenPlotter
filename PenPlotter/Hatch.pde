 class HatchPlot extends SquarePlot
    {
      
    public String toString()
    {
      return "type:HATCH, pixelSize:"+pixelSize+", t1:"+t1Slider.getValue()+
      ", t2:"+t2Slider.getValue()+", t3:"+t3Slider.getValue()+", t4:"+t4Slider.getValue();
    }
        public void showControls()
        {
            filterDropList.setVisible(true);
            pixelSizeSlider.setVisible(true);
            t1Slider.setVisible(true);
            t2Slider.setVisible(true);
            t3Slider.setVisible(true);
            t4Slider.setVisible(true);
        }

        public void calculate() {
            PImage image = simage;
            int size = pixelSize;
            penPaths.clear();
            ArrayList<Path> paths;

            int threshold;

            threshold = (int) t1Slider.getValue();
            //diag down right

            boolean reverse = false;
            
            if(image.width >= image.height)
            {
                for (int x = ((image.width - 1) / size) * size; x >= 0; x -= size) {
                  if (x > image.width-image.height) {
                        paths = findPaths(image, x, image.width-x-1, image.width + 1, threshold);
                  }                 
                  else 
                  {
                        paths = findPaths(image, x, image.height - 1, image.width + 1, threshold);
                  }
                  reverse = addPaths(paths, reverse);
                }
                
                for(int y = size;y<image.height;y+=size)
                {
                   paths = findPaths(image, y*image.width, image.height -y- 1, image.width + 1, threshold);
                  reverse = addPaths(paths, reverse);
                }
            }
            else
            {
                for (int x = ((image.width - 1) / size) * size; x >= 0; x -= size) {                  
                        paths = findPaths(image, x, image.width-x-1, image.width + 1, threshold);
                        reverse = addPaths(paths, reverse);
                  } 
                  
                for(int y = size;y<image.height;y+=size)
                {
                  if(y<image.height-image.width)
                  {
                     paths = findPaths(image, y*image.width, image.width-1, image.width + 1, threshold); 
                     reverse = addPaths(paths, reverse);                  
                  }
                  else
                  {
                    paths = findPaths(image, y*image.width, image.height -y- 1, image.width + 1, threshold);
                    reverse = addPaths(paths, reverse);
                  }
                  
                }
            }
   /*         

            for (int x = ((image.width - 1) / size) * size; x >= 0; x -= size) {
                if (image.height >= image.width) {
                    paths = findPaths(image, x, image.width - 1 - x, image.width + 1, threshold);
                } else {
                    if (x >= image.width - image.height)
                        paths = findPaths(image, x, image.width - 1 - x, image.width + 1, threshold);
                    else
                        paths = findPaths(image, x, image.height - 1, image.width + 1, threshold);

                }
                reverse = addPaths(paths, reverse);

            }


            for (int y = size; y < image.height; y += size) {

                if (image.height <= image.width) {
                    paths = findPaths(image, y * image.width, image.height - 1 - y, image.width + 1, threshold);
                } else {
                    if (y >= image.height - image.width)
                        paths = findPaths(image, y * image.width, image.height - 1 - y, image.width + 1, threshold);
                    else
                        paths = findPaths(image, y * image.width, image.width - 1, image.width + 1, threshold);
                }
                reverse = addPaths(paths, reverse);
            }
*/

            // diag down left
            threshold = (int) t2Slider.getValue();

            if(image.width >= image.height)
            {
                for (int x = 0; x < image.width  ; x += size) {
                  if (x < image.height) {
                        paths = findPaths(image, x, x, image.width - 1, threshold);
                  }                 
                  else 
                  {
                        paths = findPaths(image, x, image.height - 1, image.width - 1, threshold);
                  }
                  reverse = addPaths(paths, reverse);
                }
                int remainder = image.width%size;
                for(int y = remainder;y<image.height;y+=size)
                {
                   paths = findPaths(image, y*image.width-1, image.height -y- 1, image.width - 1, threshold);
                  reverse = addPaths(paths, reverse);
                }
            }
            else
            {
                for (int x = 0; x < image.width  ; x += size) {                  
                        paths = findPaths(image, x, x, image.width - 1, threshold);
                        reverse = addPaths(paths, reverse);
                  } 
                  
                int remainder = image.width%size;
                for(int y = remainder;y<image.height;y+=size)
                {
                  if(y<image.height-image.width)
                  {
                     paths = findPaths(image, y*image.width-1, image.width-1, image.width - 1, threshold); 
                     reverse = addPaths(paths, reverse);                  
                  }
                  else
                  {
                    paths = findPaths(image, y*image.width-1, image.height -y- 1, image.width - 1, threshold);
                    reverse = addPaths(paths, reverse);
                  }
                  
                }
            }
            

            // vertical
            threshold = (int) t3Slider.getValue();

            for (int x = 0; x < image.width; x += size) {
                paths = findPaths(image, x, image.height, image.width, threshold);
                reverse = addPaths(paths, reverse);
            }

            // horizontal
            threshold = (int) t4Slider.getValue();

            for (int y = 0; y < image.height; y += size) {
                paths = findPaths(image, y * image.width, image.width - 1, 1, threshold);
                reverse = addPaths(paths, reverse);
            }

            drawPreview();
        }

        public boolean addPaths(ArrayList<Path> paths, boolean reverse) {
            if (paths.size() > 0) {
                if (reverse) {
                    for (int i = paths.size() - 1; i >= 0; i--) {
                        paths.get(i).reverse();
                        penPaths.add(paths.get(i));
                    }
                } else {
                    for (Path path : paths) penPaths.add(path);
                }
                return !reverse;
            }
            return reverse;
        }

        public ArrayList<Path> findPaths(PImage image, int start, int len, int step, int threshold) {
            boolean up = true;
            int c;
            int x;
            int y;
            Path path = null;
            ArrayList<Path> paths = new ArrayList<Path>();
            int p = start;
            for (int i = 0; i < len; i++) {
                if (p >= image.pixels.length || p < 0) return paths;
                c = image.pixels[p];
                if (up && brightness(c) < threshold) {
                    path = new Path();
                    x = p % image.width;
                    y = p / image.width;
                    path.addPoint(x, y);
                    up = false;
                } else if (!up && brightness(c) > threshold) {
                    x = p % image.width;
                    y = p / image.width;
                    path.addPoint(x, y);
                    paths.add(path);
                    up = true;
                }
                p += step;

            }
            if (!up) {
                x = p % image.width;
                y = p / image.width;
                path.addPoint(x, y);
                paths.add(path);
            }
            return paths;
        }


        public void drawPreview()
        {
            if(preview == null)
            {
              preview = createGraphics(machineWidth,machineHeight);
              preview.beginDraw();
              preview.clear();
              preview.endDraw();
            }
            preview.beginDraw();
            preview.clear();
            preview.strokeWeight(0.1);
  
            preview.stroke(penColor);
            preview.beginShape(LINES);
            for (int i = 0; i < penIndex; i++) {
               Path p = penPaths.get(i);
               for(int j = 0;j<p.size()-1;j++)
               {
                preview.vertex(p.getPoint(j).x , p.getPoint(j).y );
                preview.vertex(p.getPoint(j+1).x , p.getPoint(j+1).y );
               }
            }
            preview.endShape();
            
            preview.stroke(plotColor);
            preview.beginShape(LINES);
            for (int i = penIndex; i < penPaths.size(); i++) {
               Path p = penPaths.get(i);
               for(int j = 0;j<p.size()-1;j++)
               {
                preview.vertex(p.getPoint(j).x , p.getPoint(j).y );
                preview.vertex(p.getPoint(j+1).x , p.getPoint(j+1).y );
               }
            }
            preview.endShape();
            
            preview.endDraw();
            loaded = true;
        }
        
        public void nextPlot(boolean preview) {
            if (penIndex < penPaths.size()) {
                Path p = penPaths.get(penIndex);
                com.sendPenUp();
                com.sendMoveG0(p.first().x + homeX - simage.width / 2 + offX, p.first().y + homeY + offY);
                com.sendPenDown();
                com.sendMoveG1(p.last().x + homeX - simage.width / 2 + offX, p.last().y + homeY + offY);
  
                if(preview)
                  drawPreview();
                penIndex++;
            } else {
                plottingStopped();
            }

        }

  
    }
