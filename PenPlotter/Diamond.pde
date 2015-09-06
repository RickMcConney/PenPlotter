 class DiamondPlot extends SquarePlot
    {
        int DIR_NE = 1;
        int DIR_SE = 2;
        int DIR_SW = 3;
        int DIR_NW = 4;
        int pixelDir = DIR_NE;


    public String toString()
    {
      return "type:DIAMOND, pixelSize:"+pixelSize+", penWidth:"+penWidth;
    }
    
        public void plot() {
            pixelDir = DIR_NE;
            super.plot();
        }

        String progress()
        {
          return penIndex+"/"+pixels.size();
        }
        public void nextPlot(boolean preview) {
            if (penIndex < pixels.size() - 1) // todo skips last pixel
            {
                float da = 0;
                float db = 0;


                PVector p = pixels.get(penIndex);
                PVector r = raw.get(penIndex);
                PVector next = raw.get(penIndex + 1);
                if (penIndex == 0) {
                    if (next.y - r.y > 0) // todo no check for one pixel row
                        pixelDir = DIR_SW;
                    else
                        pixelDir = DIR_NE;
                    com.sendPenUp();
                    com.sendMoveG0((p.x + offX), (p.y + offY));
                    com.sendPenDown();
                    com.sendPixel(da, db, pixelSize, (int) p.z, pixelDir);

                } else {
                    PVector last = raw.get(penIndex - 1);
                    da = r.x - last.x;
                    db = r.y - last.y;
                    if (last.x < r.x) // new row
                    {

                        if (next.y - r.y > 0) //todo no check for one pixel row
                            pixelDir = DIR_SW;
                        else
                            pixelDir = DIR_NE;
                    }
                    com.sendPixel(da, db, pixelSize, (int) p.z, pixelDir);

                }

                updatePos(p.x + offX, p.y + offY);
                penIndex++;
            } else {
                
                plottingStopped();
            }
        }

        public void drawDiamonPixel(int i, int a) {
            if (i < pixels.size()) {
                PVector r = raw.get(i);
                float tx = getCartesianX(r.x, r.y);
                float ty = getCartesianY(tx, r.x);
                float lx = getCartesianX(r.x, r.y + pixelSize);
                float ly = getCartesianY(lx, r.x);
                float bx = getCartesianX(r.x + pixelSize, r.y + pixelSize);
                float by = getCartesianY(bx, r.x + pixelSize);
                float rx = getCartesianX(r.x + pixelSize, r.y);
                float ry = getCartesianY(rx, r.x + pixelSize);

                fill(color(r.z, r.z, r.z, a));
                stroke(color(r.z, r.z, r.z, a));
                quad(scaleX(tx + offX), scaleY(ty + offY), scaleX(rx + offX), scaleY(ry + offY), scaleX(bx + offX), scaleY(by + offY), scaleX(lx + offX), scaleY(ly + offY));
            }
        }


        public void draw() {
            for (int i = 0; i < pixels.size(); i++) {
                if (i < penIndex)
                    drawDiamonPixel(i, 255);
                else
                    drawDiamonPixel(i, 64);
            }
        }
        
        public void calculate() {
            PImage image = simage;
            int size = pixelSize;
            int inc = size;
            float hh = (float) (size) * 1.4f / 2;
            pixels.clear();
            raw.clear();
            int skipColor = getBrightness(image, size, size, size);
            int lastColor = skipColor;
            boolean draw;

            int as = (int) getMachineA(homeX - image.width / 2, homeY);
            int ae = (int) getMachineA(homeX + image.width / 2, homeY + image.height);
            int bss = (int) getMachineB(homeX + image.width / 2, homeY);
            int bee = (int) getMachineB(homeX - image.width / 2, homeY + image.height);

            // make b a multiple of size from a
            int bas = (int) getMachineB(machineWidth / 2 - image.width / 2, homeY);
            while (bas > bss) {
                bas -= size;
            }

            bss = bas;

            while (bas < bee) {
                bas += size;
            }
            bee = bas;

            int blen = (bee - bss) / size;
            int bs;

            for (int a = as; a < ae; a += size) {
                if (inc < 0) {
                    bs = bss;
                    inc = size;
                } else {
                    bs = bee;
                    inc = -size;
                }
                int b = bs;

                for (int i = 0; i < blen; i++) {
                    float cx = getCartesianX(a, b);
                    float cy = getCartesianY(cx, a);

                    if (!Float.isNaN(cy)) {

                        int ix = (int) (cx - (machineWidth - image.width) / 2);
                        int iy = (int) (cy - homeY + hh);
                        int d = getBrightness(image, ix, iy, size);
                        draw = false;
                        if (d >= 0) {
                            if (d != skipColor) {
                                draw = true;
                            } else if (lastColor != skipColor) {
                                draw = true;
                            }
                        } else {
                            lastColor = skipColor;
                        }
                        if (draw) {
                            lastColor = d;

                            int shade = (d / range) * range;

                            pixels.add(new PVector(cx, cy, shade));
                            raw.add(new PVector(a, b, shade));
                        }
                    }
                    b += inc;
                }
            }
            loaded = true;
        }
    }
