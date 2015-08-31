class Plot {
        boolean loaded;
        boolean plotting;
        boolean isImage;
        int alpha = 255;
        int penIndex;
        ArrayList<Path> penPaths = new ArrayList<Path>();
        PGraphics preview = null;
        
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
            alpha = 255;
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
          alpha = 64;
          com.sendMM();
          com.sendAbsolute();
          com.sendSpeed(speedValue);
          nextPlot(true);
        }
        
        public void plottingStopped() {
          plotting = false;
          penIndex = 0;
          alpha = 255;
          plotDone();
          goHome();
          com.sendMotorOff();
      }
        
        void nextPlot(boolean preview) {}
        void load() {}
        void load(String fileName) {}
        void draw() {}
    }