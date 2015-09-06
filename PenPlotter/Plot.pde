class Plot {
        boolean loaded;
        boolean plotting;
        boolean isImage;
        int plotColor = previewColor;
        int penIndex;
        ArrayList<Path> penPaths = new ArrayList<Path>();
        PGraphics preview = null;
        
        String progress()
        {
          return penIndex+"/"+penPaths.size();
        }
        void init(){}
        void showControls() {}
        void hideControls() {}

        boolean isLoaded()
        {
            return loaded;
        }
        boolean isPlotting()
        {
            return plotting;
        }
        boolean isImage()
        {
            return isImage;
        }

        public void clear() {
            oimg = null;
            simage = null;
            penPaths.clear();
            loaded = false;
            preview = null;
            reset();
        }

        public void reset() {
            plotColor = previewColor;
            plotting = false;
            penIndex = 0;
            plotDone();
            com.clearQueue();
        }
        
        void rotate() {}
        void flipX() {}
        void flipY() {}
        void calculate() {}
        void crop(int cropLeft, int cropTop, int cropRight, int cropBottom){}

        public void plot() {
          plotting = true;
          penIndex = 0;
          plotColor = whilePlottingColor;
          com.sendSpecs();
          com.sendHome();
          com.sendMM();
          com.sendAbsolute();
          com.sendSpeed(speedValue);
          nextPlot(true);
        }
        
        public void plottingStopped() {
          plotting = false;
          penIndex = 0;
          plotColor = previewColor;
          plotDone();
          goHome();
          com.sendMotorOff();
      }
        
        void nextPlot(boolean preview) {}
        void load() {}
        void load(String fileName) {}
        void draw() {}
    }
