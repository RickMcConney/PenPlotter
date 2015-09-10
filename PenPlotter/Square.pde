  class SquarePlot extends Plot {
    ArrayList<PVector> pixels = new ArrayList<PVector>();
    ArrayList<PVector> raw = new ArrayList<PVector>();

    boolean top;
    
    public String toString()
    {
      return "type:SQUARE, pixelSize:"+pixelSize+", penWidth:"+penWidth;
    }
  
    public void showControls()
    {
        filterDropList.setVisible(true);

        pixelSizeSlider.setVisible(true);
        penSlider.setVisible(true);

    }


    public void clear() 
    {
        pixels.clear();
        raw.clear();
        super.clear();
    }
   
    public void flipX() {
        if (oimg == null) return;
        int cols = oimg.width;
        int rows = oimg.height;

        oimg.loadPixels();
        PImage rimage = new PImage(cols, rows);
        rimage.loadPixels();

        for (int x = 0; x < cols; x++) {
            for (int y = 0; y < rows; y++) {
                int ps = y * cols + (cols - 1 - x);
                int pd = y * cols + x;
                if (pd < rimage.pixels.length && ps < oimg.pixels.length)
                    rimage.pixels[pd] = oimg.pixels[ps];
            }
        }
        rimage.updatePixels();
        oimg = rimage;
        crop(cropLeft, cropTop, cropRight, cropBottom);
    }

    public void flipY() {
        if (oimg == null) return;
        int cols = oimg.width;
        int rows = oimg.height;

        oimg.loadPixels();
        PImage rimage = new PImage(cols, rows);
        rimage.loadPixels();

        for (int x = 0; x < cols; x++) {
            for (int y = 0; y < rows; y++) {
                int ps = cols * (rows - 1 - y) + x;
                int pd = y * cols + x;
                if (pd < rimage.pixels.length && ps < oimg.pixels.length)
                    rimage.pixels[pd] = oimg.pixels[ps];
            }
        }
        rimage.updatePixels();
        oimg = rimage;
        crop(cropLeft, cropTop, cropRight, cropBottom);
    }

    public void rotate() {
        if (oimg == null) return;
        int cols = oimg.width;
        int rows = oimg.height;

        oimg.loadPixels();
        PImage rimage = new PImage(rows, cols);
        rimage.loadPixels();

        for (int i = 0; i < cols; i++) {
            for (int j = 0; j < rows; j++) {
                int ps = (rows - 1 - j) * cols + i;
                int pd = i * rows + j;
                if (pd < rimage.pixels.length && ps < oimg.pixels.length)
                    rimage.pixels[pd] = oimg.pixels[ps];
            }
        }
        rimage.updatePixels();
        oimg = rimage;
        crop(cropLeft, cropTop, cropRight, cropBottom);
    }

    public void crop(int x1, int y1, int x2, int y2) {
        if (!plotting && oimg != null) {
            int ox = imageX;
            int oy = imageY;

            int width = oimg.width;
            int height = oimg.height;
            int cropWidth = (x2 - x1) * width / imageWidth;
            int cropHeight = (y2 - y1) * height / imageHeight;
            simage = new PImage((int) (cropWidth * userScale), (int) (cropHeight * userScale));
            simage.copy(oimg, (x1 - ox) * width / imageWidth, (y1 - oy) * height / imageHeight, cropWidth, cropHeight, 0, 0, simage.width, simage.height);
            simage.loadPixels();
            if (simage != null) {
                // hatchImage = createGraphics(simage.width,simage.height);
                calculate();
            }
        }
    }


    public void load(String fileName) {
        
        oimg = loadImage(fileName);
        int limitWidth;
        int limitHeight;

        if (oimg.width > oimg.height) {
            imageWidth = 200;
            imageHeight = 200 * oimg.height / oimg.width;
            limitWidth = machineWidth/2;
            limitHeight = machineWidth/2 * oimg.height / oimg.width;
        } else {
            imageWidth = 200 * oimg.width / oimg.height;
            imageHeight = 200;
            limitWidth = machineHeight/2 * oimg.width / oimg.height;
            limitHeight = machineHeight/2;
        }
        PImage limit = new PImage(limitWidth, limitHeight);
        limit.copy(oimg, 0,0, oimg.width, oimg.height, 0, 0, limit.width, limit.height);
        oimg = limit;

        cropRight = imageX + imageWidth;
        cropBottom = imageY + imageHeight;
        crop(cropLeft, cropTop, cropRight, cropBottom);
        isImage = true;
    }


    public int getBrightness(PImage image, int x, int y, int size) {
        int width = image.width;
        int height = image.height;
        int totalB = 0;
        int count = 0;
        if (x < 0 || x > width - 1 || y < 0 || y > height - 1) return -1;
        for (int j = 0; j < size; j++) {
            for (int k = 0; k < size; k++) {
                int p = (y + k) * width + x + j;
                if (p >= 0 && p < image.pixels.length) {
                    int c = image.pixels[p];
                    totalB += brightness(c);
                    count++;
                }
            }
        }
        if (count > 0)
            return totalB / count;
        else
            return 0;
    }

    public int getHue(PImage image, int x, int y, int size) {
        int width = image.width;
        int height = image.height;
        int totalB = 0;
        int count = 0;
        if (x < 0 || x > width - 1 || y < 0 || y > height - 1) return -1;
        for (int j = 0; j < size; j++) {
            for (int k = 0; k < size; k++) {
                int p = (y + k) * width + x + j;
                if (p >= 0 && p < image.pixels.length) {
                    int c = image.pixels[p];
                    totalB += hue(c);
                    count++;
                }
            }
        }
        if (count > 0)
            return totalB / count;
        else
            return 0;
    }



    public void nextPlot(boolean preview) {
        if (penIndex < penPaths.size()) {
                     
            Path wave = penPaths.get(penIndex);
            for(int j = 0;j<wave.size();j++)
            {                   
              if (penIndex == 0 && j == 0) {
                com.sendPenUp();
                com.sendMoveG0(wave.getPoint(j).x+ homeX - simage.width / 2 + offX, wave.getPoint(j).y+ homeY + offY);
                com.sendPenDown();
                com.sendMoveG1(wave.getPoint(j).x+ homeX - simage.width / 2 + offX, wave.getPoint(j).y+ homeY + offY);
              } else {
                com.sendMoveG1(wave.getPoint(j).x+ homeX - simage.width / 2 + offX, wave.getPoint(j).y+ homeY + offY);
              }
            }
            if(preview)
              drawPreview();
            penIndex++;
        } else {
            plottingStopped();
        }
    }

    public void drawSquarePixel(int i, int a) {
        if (i < pixels.size()) {
            PVector r = pixels.get(i);

            fill(color(r.z, r.z, r.z, a));
            stroke(color(r.z, r.z, r.z, a));
            rect(scaleX(r.x + offX), scaleY(r.y + offY), pixelSize * zoomScale, pixelSize * zoomScale);
        }
    }

    public Path wavePath(float x,float y,float  shade, boolean reverse)
        {
            int n  = int(((255-shade) * pixelSize / penWidth) / 255f);
            float inc = (float)pixelSize/(float)n; 
     
            if(reverse) 
            { 
              x += pixelSize;  
              inc = -inc;
            }    
            Path path = new Path();
            path.addPoint(x , y+pixelSize/2f);

            for(float i = 0;i<n;i++) {
                if(top)
                {
                  path.addPoint(x + i * inc, y+pixelSize);
                  path.addPoint(x + (i+1) * inc, y+pixelSize);
                }
                else
                {
                  path.addPoint(x + i * inc, y);
                  path.addPoint(x + (i+1) * inc, y);
                }
                top = !top;
            }
            if(reverse)
              x-=pixelSize;
            else
              x+=pixelSize;
              
            if(top)
              path.addPoint(x , y);
            else
              path.addPoint(x , y+pixelSize);
              
             path.addPoint(x , y+pixelSize/2f  );
            return path;
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
            preview.beginShape();
            for (int i = 0; i < penIndex; i++) {
               Path p = penPaths.get(i);
               for(int j = 0;j<p.size();j++)
               {
                preview.vertex(p.getPoint(j).x , p.getPoint(j).y );
               }
            }
            preview.endShape();
            
            preview.stroke(plotColor);
            preview.beginShape();
            for (int i = penIndex; i < penPaths.size(); i++) {
               Path p = penPaths.get(i);
               for(int j = 0;j<p.size();j++)
               {
                preview.vertex(p.getPoint(j).x , p.getPoint(j).y );
               }
            }
            preview.endShape();
            
            preview.endDraw();
            loaded = true;
        }
        
        public void draw() {
            if(preview != null)
              image(preview, scaleX(offX+ homeX - simage.width / 2), scaleY(offY +homeY), preview.width * zoomScale, preview.height * zoomScale);
            
        }


    public void calculate() {
        PImage image = simage;
        int size = pixelSize;
        int width = image.width;
        int height = image.height;
        int d;
        int shade;
        pixels.clear();

        int sx = 0;
        int sy = 0;
        boolean reverse = true;
        int skipColor = getBrightness(image, 0, 0, size);
        int skipHue = getHue(image, 0, 0, size);
        int hue;

        penPaths.clear();

        for (int y = 0; y < height; y += size) {
            reverse = !reverse;
            top = true;
            if (!reverse) {
                for (int x = 0; x < width; x += size) {
                    d = getBrightness(image, x, y, size);
                    hue = getHue(image, x, y, size);

                    if (hue != skipHue || d != skipColor) {
                        shade = (d / range) * range;
                       // pixels.add(new PVector(sx + x, sy + y, shade));
                         penPaths.add(wavePath(sx + x,sy + y,shade,reverse));
                    }
                }
            } else {
                for (int x = ((width - 1) / size) * size; x >= 0; x -= size) {
                    d = getBrightness(image, x, y, size);
                    hue = getHue(image, x, y, size);
                    if (hue != skipHue || d != skipColor) {
                        shade = (d / range) * range;
                        
                       // pixels.add(new PVector(sx + x, sy + y, shade));
                         penPaths.add(wavePath(sx + x,sy + y,shade,reverse));
                    }
                }
            }
        }
        drawPreview();
    }




}