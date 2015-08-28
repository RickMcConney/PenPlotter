 class HatchPlot extends SquarePlot
    {
        ArrayList<Path> hatchPaths;
        PGraphics hatchImage = null;



        public void showControls()
        {
            filterDropList.setVisible(true);
            pixelSizeSlider.setVisible(true);
            t1Slider.setVisible(true);
            t2Slider.setVisible(true);
            t3Slider.setVisible(true);
            t4Slider.setVisible(true);

        }

        void init()
        {
            makeHatchImage();
        }
        public void makeHatchImage()
        {
            hatchImage = createGraphics(machineWidth,machineHeight);
            hatchImage.beginDraw();
            hatchImage.clear();
            hatchImage.endDraw();
        }

        public void clear()
        {
            super.clear();
            hatchPaths = null;
        }

        public void calculate() {
            PImage image = simage;
            int size = pixelSize;
            hatchPaths = new ArrayList<Path>();
            ArrayList<Path> paths;

            int threshold;

            threshold = (int) t1Slider.getValue();
            //diag down right

            boolean reverse = false;

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


            // diag down left
            threshold = (int) t2Slider.getValue();

            for (int x = 0; x < image.width; x += size) {
                if (image.height >= image.width) {
                    paths = findPaths(image, x, x, image.width - 1, threshold);
                } else {
                    if (x >= image.width - image.height) {
                        paths = findPaths(image, x, image.height - 1, image.width - 1, threshold);
                    } else {
                        paths = findPaths(image, x, image.height - 1 - x, image.width - 1, threshold);
                    }
                }
                reverse = addPaths(paths, reverse);
            }


            for (int y = size; y < image.height; y += size) {
                if (image.height <= image.width) {
                    paths = findPaths(image, y * image.width - 1, image.height - 1 - y, image.width - 1, threshold);
                } else {
                    if (y >= image.height - image.width)
                        paths = findPaths(image, y * image.width - 1, image.height - 1 - y, image.width - 1, threshold);
                    else
                        paths = findPaths(image, y * image.width - 1, image.width - 1, image.width - 1, threshold);
                }
                reverse = addPaths(paths, reverse);

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


        }

        public boolean addPaths(ArrayList<Path> paths, boolean reverse) {
            if (paths.size() > 0) {
                if (reverse) {
                    for (int i = paths.size() - 1; i >= 0; i--) {
                        paths.get(i).reverse();
                        hatchPaths.add(paths.get(i));
                    }
                } else {
                    for (Path path : paths) hatchPaths.add(path);
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
                if (p >= image.pixels.length) return paths;
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

        public void plotHatch() {
            dindex = 0;
            plotting = true;
            plottingStarted();
            nextPlot();
        }
        public void nextPlot() {
            if (dindex < hatchPaths.size()) {
                Path p = hatchPaths.get(dindex);
                com.sendPenUp();
                com.sendMoveG0(p.first().x + homeX - simage.width / 2 + offX, p.first().y + homeY + offY);
                com.sendPenDown();
                com.sendMoveG1(p.last().x + homeX - simage.width / 2 + offX, p.last().y + homeY + offY);

                dindex++;
            } else {
                plotDone();
                alpha = 255;
                plotting = false;
            }

        }

        public void export(File file) {
            if (hatchPaths == null) return;
            Path p;
            BufferedWriter writer = null;
            try {
                writer = new BufferedWriter(new FileWriter(file));

                for (int i = 0; i < hatchPaths.size(); i++) {
                    p = hatchPaths.get(i);

                    if (i == 0) {
                        writer.write("G21\n"); //mm
                        writer.write("G90\n"); // absolute
                        writer.write("G0 F" + speedValue + "\n");
                    }
                    for (int j = 0; j < p.size() - 1; j++) {

                        float x1 = p.getPoint(j).x - simage.width / 2 + offX;
                        float y1 = p.getPoint(j).y + offY;
                        float x2 = p.getPoint(j + 1).x - simage.width / 2 + offX;
                        float y2 = p.getPoint(j + 1).y + offY;


                        if (j == 0) {
                            // pen up
                            writer.write("G0 Z" + cncSafeHeight + "\n");
                            writer.write("G0 X" + nf(x1, 0, 3) + " Y" + nf(y1, 0, 3) + "\n");
                            //pen Down
                            writer.write("G0 Z0\n");
                        }

                        writer.write("G1 X" + nf(x2, 0, 3) + " Y" + nf(y2, 0, 3) + "\n");
                    }
                }


                float x1 = 0;
                float y1 = 0;

                writer.write("G0 Z" + cncSafeHeight + "\n");
                writer.write("G0 X" + x1 + " Y" + y1 + "\n");
            } catch (IOException e) {
                System.out.print(e);
            } finally {
                try {
                    if (writer != null)
                        writer.close();
                } catch (IOException e) {
                }
            }
        }

        public void imgdrawHatch() {
            if (hatchImage != null)
                image(hatchImage, scaleX(offX + homeX - simage.width / 2), scaleY(offY + homeY), hatchImage.width * zoomScale, hatchImage.height * zoomScale);
        }

        public void draw() {
            if (hatchPaths == null) return;
            Path p;

            strokeWeight(0.1f);

            stroke(color(0, 0, 0, 255));
            beginShape(LINES);
            for (int i = 0; i < dindex; i++) {
                p = hatchPaths.get(i);
                vertex(scaleX(p.first().x + homeX - simage.width / 2 + offX), scaleY(p.first().y + homeY + offY));
                vertex(scaleX(p.last().x + homeX - simage.width / 2 + offX), scaleY(p.last().y + homeY + offY));
            }
            endShape();

            stroke(color(0, 0, 0, alpha));
            beginShape(LINES);
            for (int i = dindex; i < hatchPaths.size(); i++) {
                p = hatchPaths.get(i);
                vertex(scaleX(p.first().x + homeX - simage.width / 2 + offX), scaleY(p.first().y + homeY + offY));
                vertex(scaleX(p.last().x + homeX - simage.width / 2 + offX), scaleY(p.last().y + homeY + offY));
            }
            endShape();
        }

        public void hatchImgdraw() {

            if (hatchPaths == null) return;

            Path p;

            hatchImage.beginDraw();
            hatchImage.clear();
            hatchImage.strokeWeight(0.1f);

            hatchImage.stroke(color(0, 0, 0, 255));
            hatchImage.beginShape(LINES);
            for (int i = 0; i < dindex; i++) {
                p = hatchPaths.get(i);
                //hatchImage.vertex(scaleX(p.first().x*userScale+homeX), scaleY(p.first().y*userScale+homeY));
                // hatchImage.vertex(scaleX(p.last().x*userScale+homeX), scaleY(p.last().y*userScale+homeY));
                hatchImage.vertex(p.first().x * userScale, p.first().y * userScale);
                hatchImage.vertex(p.last().x * userScale, p.last().y * userScale);

            }
            hatchImage.endShape();

            hatchImage.stroke(color(0, 0, 0, alpha));
            hatchImage.beginShape(LINES);
            for (int i = dindex; i < hatchPaths.size(); i++) {
                p = hatchPaths.get(i);
                hatchImage.vertex(p.first().x * userScale, p.first().y * userScale);
                hatchImage.vertex(p.last().x * userScale, p.last().y * userScale);
            }
            hatchImage.endShape();
            hatchImage.endDraw();
        }


        public void olddrawHatch() {
            if (hatchPaths == null) return;
            Path p;

            for (int i = 0; i < hatchPaths.size(); i++) {
                p = hatchPaths.get(i);
                if (i < dindex)
                    stroke(color(0, 0, 0, 255));
                else
                    stroke(color(0, 0, 0, alpha));

                sline(p.first().x * userScale + homeX + offX, p.first().y * userScale + homeY + offY, p.last().x * userScale + homeX + offX, p.last().y * userScale + homeY + offY);

            }
        }

    }