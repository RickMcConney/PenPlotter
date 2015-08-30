class Export extends Com
{
  BufferedWriter writer;
  public void listPorts() {}

    public void disconnect() {}

    public void connect(int port) {}

    public void connect(String name) {
    }

    public void sendMotorOff() {}

    public void moveDeltaX(float x) {
        send("G0 X" + (x-homeX) + "\n");
    }

    public void moveDeltaY(float y) {
        send("G0 Y" + (y-homeY) + "\n");
    }

    public void sendMoveG0(float x, float y) {
        send("G0 X" + (x-homeX) + " Y" + (y-homeY) + "\n");
    }

    public void sendMoveG1(float x, float y) {
        send("G1 X" + (x-homeX) + " Y" + (y-homeY) + "\n");
    }

    public void sendG2(float x, float y, float i, float j) {
        send("G2 X" + (x-homeX) + " Y" + (y-homeY) + " I" + i + " J" + j + "\n");
    }

    public void sendG3(float x, float y, float i, float j) {
        send("G3 X" + (x-homeX) + " Y" + (y-homeY) + " I" + i + " J" + j + "\n");
    }

    public void sendSpeed(int speed) {
        send("G0 F" + speed + "\n");
    }

    public void sendHome() {}

    public void sendSpeed() {
        send("G0 F" + speedValue + "\n");
    }

    public void sendPenWidth() {}

    public void sendSpecs() {}

    public void sendPenUp() {
        send("G0 Z"+cncSafeHeight+"\n");
    }

    public void sendPenDown() {
        send("G0 Z0\n");
    }

    public void sendAbsolute() {
        send("G90\n");
    }

    public void sendRelative() {
        send("G91\n");
    }

    public void sendPixel(float da, float db, int pixelSize, int shade, int pixelDir) {}


    public void initArduino() {}

    public void clearQueue() {}

    public void queue(String msg) {}

    public void nextMsg() {}

    public void send(String msg) {
        try{
          writer.write(msg);
        } catch(Exception e)
        {
          e.printStackTrace();
          System.out.println(e);
        }
    }

    public void oksend(String msg) {}

    public void serialEvent() {}
    
    public void export(File file)
    {
          try {
               writer = new BufferedWriter(new FileWriter(file));
                writer.write("G21\n"); //mm
                writer.write("G90\n"); // absolute
                
                currentPlot.plot();
                while(currentPlot.isPlotting())
                  currentPlot.nextPlot(false);
                        
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
}
