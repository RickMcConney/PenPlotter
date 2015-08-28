class Plot {
        boolean loaded;
        boolean plotting;
        boolean isImage;

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

        void clear() {}
        void reset() {}
        void rotate() {}
        void flipX() {}
        void flipY() {}
        void calculate() {}
        void export(File file){}
        void crop(int cropLeft, int cropTop, int cropRight, int cropBottom){}

        void plot() {}
        void nextPlot() {}
        void load() {}
        void load(String fileName) {}
        void draw() {}
    }