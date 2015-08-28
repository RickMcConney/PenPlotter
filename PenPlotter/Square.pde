  class SquarePlot extends Plot {
    ArrayList<PVector> pixels = new ArrayList<PVector>();
    ArrayList<PVector> raw = new ArrayList<PVector>();

    int dindex = 0;



    int alpha = 255;

    public void showControls()
    {
        filterDropList.setVisible(true);

        pixelSizeSlider.setVisible(true);
        penSlider.setVisible(true);

    }


    public void clear() {
        oimg = null;
        simage = null;

        pixels.clear();
        raw.clear();
        loaded = false;

        reset();
    }

    public void reset() {
        plotting = false;
        dindex = 0;
        plotDone();
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

    public boolean isLoaded()
    {
        return simage != null;
    }
    public void load(String fileName) {
        oimg = loadImage(fileName);

        if (oimg.width > oimg.height) {
            imageWidth = 200;
            imageHeight = 200 * oimg.height / oimg.width;
        } else {
            imageWidth = 200 * oimg.width / oimg.height;
            imageHeight = 200;
        }
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





    public void plot() {
        dindex = 0;
        plotting = true;
        plottingStarted();
        nextPlot();
    }

    public void nextPlot() {
        if (dindex < pixels.size()) {
            PVector p = pixels.get(dindex);
            if (dindex == 0) {
                com.sendPenUp();
                com.sendMoveG0((p.x + offX), (p.y + offY));
                com.sendPenDown();
                com.sendSqPixel((p.x + offX), (p.y + offY), pixelSize, (int) p.z);
            } else {
                com.sendSqPixel((p.x + offX), (p.y + offY), pixelSize, (int) p.z);
            }
            dindex++;
        } else {
            com.sendMotorOff();
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

    public void draw() {
        for (int i = 0; i < pixels.size(); i++) {
            if (i < dindex)
                drawSquarePixel(i, 255);
            else
                drawSquarePixel(i, alpha);
        }
    }


    public void calculate() {
        PImage image = simage;
        int size = pixelSize;
        int width = image.width;
        int height = image.height;
        int d;
        int shade;
        pixels.clear();

        int sx = homeX - image.width / 2;
        int sy = homeY;
        boolean reverse = true;
        int skipColor = getBrightness(image, 0, 0, size);
        int skipHue = getHue(image, 0, 0, size);
        int hue;

        for (int y = 0; y < height; y += size) {
            reverse = !reverse;
            if (!reverse) {
                for (int x = 0; x < width; x += size) {
                    d = getBrightness(image, x, y, size);
                    hue = getHue(image, x, y, size);

                    if (hue != skipHue || d != skipColor) {
                        shade = (d / range) * range;
                        pixels.add(new PVector(sx + x, sy + y, shade));
                    }
                }
            } else {
                for (int x = ((width - 1) / size) * size; x >= 0; x -= size) {
                    d = getBrightness(image, x, y, size);
                    hue = getHue(image, x, y, size);
                    if (hue != skipHue || d != skipColor) {
                        shade = (d / range) * range;
                        pixels.add(new PVector(sx + x, sy + y, shade));
                    }
                }
            }
        }
    }

    public void plottingStarted() {
        plotting = true;
        alpha = 64;
    }

    public void plottingStopped() {
        dindex = 0;
        plotting = false;
        plotDone();
        alpha = 255;
        goHome();
    }

}