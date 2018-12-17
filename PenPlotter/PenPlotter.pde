import processing.core.*;
import processing.event.*;

import controlP5.*;
import geomerative.*;
import processing.serial.*;
import java.util.Properties;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.InputStreamReader;
import java.io.BufferedWriter;
import java.io.FileWriter;
import javax.swing.SwingUtilities;
import javax.swing.JFileChooser;
import java.util.Map;
import java.util.Collections;
import java.util.Enumeration;
import java.util.Vector;
import toxi.geom.*;
import toxi.geom.mesh2d.*;
import toxi.processing.*;
import java.util.ArrayList;
import java.io.File;
import javax.swing.filechooser.FileFilter;
import java.beans.PropertyChangeListener;
import java.beans.PropertyChangeEvent;
import java.io.BufferedReader;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.IOException;

import java.awt.event.ActionEvent;
import java.awt.event.WindowEvent;
import java.awt.event.ActionListener;
import java.awt.event.WindowListener;
import java.awt.event.WindowAdapter;
import javax.swing.*;
import java.util.logging.*;
import java.text.*;
import java.util.*;
import java.io.*;
import java.awt.Dimension;
import java.awt.Toolkit;
import java.awt.BorderLayout;

    final static String ICON  = "icons/penDown.png";
    final static String TITLE = "PenPlotter v0.8";

    ControlP5 cp5;
    Handle[] handles;
    float cncSafeHeight = 5;  // safe height for cnc export
    float flipX = 1;          // mirror around X if set to -1
    float flipY = 1;          // mirror around Y if set to -1
    float scaleX = 1;         // combined scale svgScale*userScale*flipX
    float scaleY = 1;         // combined scale svgScale*userScale*flipY
    float userScale = 1;      // user controlled scale from slider


    int jogX;                 // set if jog X button pressed
    int jogY;                 // set if jog Y button pressed

    int machineWidth = 840;   // Width of machine in mm
    int homeX = machineWidth/2; //X Home position
    int machineHeight = 800;    //machine Height only used to draw page height
    int homeY = 250;          // location of homeY good location is where gondola hangs with motor power off

    float currentX = homeX;   // X location of gondola
    float currentY = homeY;   // X location of gondola

    int speedValue = 500;     // speed of motors controlled with speed slider


    float stepsPerRev = 6400; // number of steps per rev includes microsteps
    float mmPerRev = 80;      // mm per rev

    float zoomScale = 0.75f;   // screen scale controlle with mouse wheel
    float shortestSegment = 0;    // cull out svg segments shorter that is.


    int menuWidth = 110;
    int originX = (machineWidth+menuWidth)/2; // screen X offset of page will change if page dragged
    int originY = 200;                        // screen Y offset of page will change if page dragged

    int oldOriginX;          // old location page when drag starts
    int oldOriginY;
    int oldOffX;             // old offset when right drag starts
    int oldOffY;

    int offX = 0;            // offset of drawing from origin
    int offY = 0;

    int startX;              // start location of mouse drag
    int startY;

    int imageX = 130;        // location to draw image overlay
    int imageY = 10;

    int imageWidth = 200;   // size of image overlay
    int imageHeight = 200;

    int cropLeft = imageX;
    int cropTop = imageY;
    int cropRight = imageX+imageWidth;
    int cropBottom = imageY+imageHeight;

    String currentFileName = "";

    boolean overLeft = false;
    boolean overRight = false;
    boolean overTop = false;
    boolean overBottom = false;
    boolean motorsOn = false;
    boolean draw = true;


    int pageColor = color(255, 255, 255);
    int machineColor = color(250,250,250);
    int backgroundColor = color(192, 192, 192);
    int gridColor = color(128, 128, 128);
    int cropColor = color(0, 255, 0);
    int textColor = color(0, 0, 255);
    int gondolaColor = color(0, 0, 0,128);
    int statusColor = color(0, 0, 0);
    int motorOnColor = color(255, 0, 0);
    int motorOffColor = color(0, 0, 255);
    
    int penColor = color(0, 0, 0,255);    
    int previewColor = color(0,0,0,255);
    int whilePlottingColor = color(0,0,0,64);
    int rapidColor = color(0,255,0,64);
    
    int buttonPressColor = color(227, 230, 255);
    int buttonHoverColor = color(201, 206, 255);
    int buttonUpColor = color(115, 117, 216);
    int buttonTextColor = color(0,0,0);
    int buttonBorderColor = color(0,0,0);

    Plot currentPlot = new Plot();
    float lastX = 0;
    float lastY = 0;
    PApplet applet = this;
    PImage simage;
    PImage oimg;
    StipplePlot stipplePlot = new StipplePlot();
    DiamondPlot diamondPlot = new DiamondPlot();
    HatchPlot hatchPlot = new HatchPlot();
    SquarePlot squarePlot = new SquarePlot();
    float svgDpi = 72;
    float svgScale = 25.4f / svgDpi;

    float penWidth = 0.5f;
    int pixelSize = 8;
    int range = 255 / (int) ((float) (pixelSize) / penWidth);

    int HATCH = 0;
    int DIAMOND = 1;
    int SQUARE = 2;
    int STIPPLE = 3;
    int imageMode = HATCH;
    long lastTime = millis();
    long freeMemory;
    long totalMemory;
    boolean useSolenoid = false; //If used solinoid as lifting pen
    int solenoidUP = 1;//Solinoid on or off when UP 
    int servoDwell = 250;
    int servoUpValue = 2350;
    int servoDownValue = 1500;
    int rate;
    int tick;
    
    float paperWidth = 8.5;
    float paperHeight = 11;
    public static Console console;
    Com com = new Com();

    private void prepareExitHandler () {

        Runtime.getRuntime().addShutdownHook(new Thread(new Runnable() {

            public void run() {
                println("SHUTDOWN HOOK");
            }
        }
        ));
    }

    public void exit()
    {
        println("exit");
        com.sendMotorOff();
        delay(1000);
        super.exit();
    }

    public void changeAppIcon(PImage img) {
        final PGraphics pg = createGraphics(16, 16, JAVA2D);

        pg.beginDraw();
        pg.image(img, 0, 0, 16, 16);
        pg.endDraw();
        frame.setIconImage(pg.image);
    }

    public void changeAppTitle(String title) {
        //surface.setTitle(title);
        frame.setTitle(title);
    }

    public void setup() {

        size(840, 680, JAVA2D);
        //surface.setResizable(true);
        frame.setResizable(true);
        changeAppIcon( loadImage(ICON) );
        changeAppTitle(TITLE);
        prepareExitHandler();


        getProperties();


        machineWidth = Integer.parseInt(props.getProperty("machine.width"));
        machineHeight = Integer.parseInt(props.getProperty("machine.height"));
        homeX = machineWidth/2;

        homeY = Integer.parseInt(props.getProperty("machine.homepoint.y"));
        mmPerRev = Float.parseFloat(props.getProperty("machine.motors.mmPerRev"));
        stepsPerRev = Float.parseFloat(props.getProperty("machine.motors.stepsPerRev"));

        currentX = homeX;
        currentY = homeY;

        penWidth = Float.parseFloat(props.getProperty("machine.penSize"));

        svgDpi = Float.parseFloat(props.getProperty("svg.pixelsPerInch"));
        svgScale = 25.4f/svgDpi;

        currentFileName = props.getProperty("svg.name");

        cncSafeHeight = Float.parseFloat(props.getProperty("cnc.safeHeight"));


        com.baudRate = Long.parseLong(props.getProperty("com.baudrate"));
        //todo lastPort not used

        com.lastPort = Integer.parseInt(props.getProperty("com.serialPort"));

        offX = Integer.parseInt(props.getProperty("machine.offX"));
        offY = Integer.parseInt(props.getProperty("machine.offY"));

        zoomScale = Float.parseFloat(props.getProperty("machine.zoomScale"));

        cropLeft = Integer.parseInt(props.getProperty("image.cropLeft"));
        if(cropLeft < imageX) cropLeft = imageX;
        cropRight = Integer.parseInt(props.getProperty("image.cropRight"));
        if(cropRight > imageX+imageWidth) cropRight = imageX+imageWidth;
        cropTop = Integer.parseInt(props.getProperty("image.cropTop"));
        if(cropTop < imageY) cropTop = imageY;
        cropBottom = Integer.parseInt(props.getProperty("image.cropBottom"));
        if(cropBottom > imageY+imageHeight) cropBottom = imageY+imageHeight;

        shortestSegment = Float.parseFloat(props.getProperty("svg.shortestSegment"));

        com.listPorts();

        RG.init(this);
        RG.ignoreStyles(true);
        RG.setPolygonizer(RG.ADAPTATIVE);

        createcp5GUI();

        speedValue = Integer.parseInt(props.getProperty("machine.motors.maxSpeed"));
        speedSlider.setValue(speedValue);

        pixelSize = Integer.parseInt(props.getProperty("image.pixelSize"));
        pixelSizeSlider.setValue(pixelSize);

        userScale = Float.parseFloat(props.getProperty("svg.UserScale"));
        scaleSlider.setValue(userScale);
        
        servoDwell = Integer.parseInt(props.getProperty("servo.dwell"));
        servoUpValue = Integer.parseInt(props.getProperty("servo.upValue"));
        servoDownValue = Integer.parseInt(props.getProperty("servo.downValue"));
        
        paperWidth = Float.parseFloat(props.getProperty("paper.width.inches"));
        paperHeight = Float.parseFloat(props.getProperty("paper.height.inches"));
        
        updateScale();

        handles = new Handle[6];
        handles[0] = new Handle("homeY", 0, homeY, 0, 10, handles, false, true, 128);
        handles[1] = new Handle("mWidth", machineWidth, machineHeight/2, 0, 10, handles, true, false, 64);
        handles[2] = new Handle("mHeight", homeX, machineHeight, 0, 10, handles, false, true, 64);
        handles[3] = new Handle("gondola", (int)currentX, (int)currentY, 0, 10, handles, true, true, 2);
        handles[4] = new Handle("pWidth", Math.round(homeX+(paperWidth/2)*25.4), Math.round(homeY+(paperHeight/2)*25.4f), 0, 10, handles, true, false, 64);
        handles[5] = new Handle("pHeight", homeX, Math.round(homeY+(paperHeight)*25.4), 0, 10, handles, false, true, 64);
    }

    public void mousePressed()
    {
        startX = mouseX;
        startY = mouseY;
        oldOriginX = originX;
        oldOriginY = originY;
        oldOffX = offX;
        oldOffY = offY;
    }

    public void mouseDragged()
    {
        if (mouseButton == CENTER) {
            originX = oldOriginX + mouseX -startX;
            originY = oldOriginY + mouseY -startY;
        } else if (mouseButton == RIGHT)
        {
            offX = oldOffX + (int)((mouseX -startX)/zoomScale);
            offY = oldOffY + (int)((mouseY -startY)/zoomScale);
        }
    }

    public void mouseReleased() {

        if (overLeft || overRight || overTop || overBottom)
        {

            currentPlot.crop(cropLeft, cropTop, cropRight, cropBottom);
        }
        overLeft = false;
        overRight = false;
        overTop = false;
        overBottom = false;
        startX = 0;
        startY = 0;

        for (Handle handle : handles) {
            if (handle.wasActive()) {
                if (handle.id.equals("gondola")) {

                    com.sendMoveG0(currentX, currentY);
                }
                if (handle.id.equals("homeY")) {
                    com.sendHome();
                }
                if (handle.id.equals("mWidth")) {
                    com.sendSpecs();
                }
            }
            handle.releaseEvent();
        }
    }

    public void mouseWheel(MouseEvent event) {

        float e = event.getCount();

        if (e > 0)
            setZoom(zoomScale+=0.1f);
        else if(zoomScale > 0.1f)
            setZoom(zoomScale-=0.1f);
    }



    public void keyPressed() {
        if (key == 'x') {
            flipX *= -1;
            updateScale();
        } else if (key == 'y') {
            flipY *= -1;
            updateScale();
        }
        
        if (key == 'c')
         {
           println("control");
           initLogging();
         }
         
         if (key == 'd')
         {
           println("draw");
           draw = true;
         }
         if (key == 'n')
         {
           println("no draw");
           draw = false;
         }        
         
    }
void initLogging()
{
  try
  {
      console = new Console();
  }
  catch(Exception e)
  {
    println("Exception setting up logger: " + e.getMessage());
  }
}
    public void handleMoved(String id, int x, int y)
    {
        if (id.equals("homeY"))
            homeY = y;
        else if(id.equals("gondola")) {

            currentX = x;
            currentY = y;
        }
        else if(id.equals("mWidth")) {
            machineWidth = x;
            homeX = machineWidth / 2;
            handles[2].x = homeX;
            //makeHatchImage();

        }
        else if(id.equals("mHeight")) {
            machineHeight = y;
            handles[1].y = y / 2;
           // makeHatchImage();
        }
        else if(id.equals("pWidth"))
        {
          paperWidth = (x-homeX)*2/25.4;
        }
        else if(id.equals("pHeight"))
        {
          paperHeight = (y-homeY)/25.4;
        }
    }

    public boolean overCropLeft(int x, int y)
    {
        if (overLeft) return true;

        int x1 = cropLeft;
        int x2 = x1+10;
        int y1 = cropTop+(cropBottom-cropTop)/2-5;
        int y2 = y1+10;

        if (x < x1) return false;
        if (x > x2) return false;
        if (y < y1) return false;
        if (y > y2) return false;

        overLeft = true;
        return true;
    }

    public boolean overCropRight(int x, int y)
    {
        if (overRight) return true;

        int x1 = cropRight-10;
        int x2 = x1+10;
        int y1 = cropTop+(cropBottom-cropTop)/2-5;
        int y2 = y1+10;

        if (x < x1) return false;
        if (x > x2) return false;
        if (y < y1) return false;
        if (y > y2) return false;

        overRight = true;
        return true;
    }

    public boolean overCropTop(int x, int y)
    {
        if (overTop) return true;

        int x1 = cropLeft+(cropRight-cropLeft)/2-5;
        int x2 = x1+10;
        int y1 = cropTop;
        int y2 = y1+10;

        if (x < x1) return false;
        if (x > x2) return false;
        if (y < y1) return false;
        if (y > y2) return false;

        overTop = true;
        return true;
    }

    public boolean overCropBottom(int x, int y)
    {
        if (overBottom) return true;

        int x1 = cropLeft+(cropRight-cropLeft)/2-5;
        int x2 = x1+10;
        int y1 = cropBottom-10;
        int y2 = y1+10;

        if (x < x1) return false;
        if (x > x2) return false;
        if (y < y1) return false;
        if (y > y2) return false;

        overBottom = true;
        return true;
    }

    public void setSpeed(int value)
    {
        speedValue = value;
        com.sendSpeed(speedValue);
    }

    public void setuserScale(float value) {
        userScale = value;
        updateScale();
        setImageScale();
    }

    public void updateScale()
    {
        scaleX = svgScale*userScale*flipX;
        scaleY = svgScale*userScale*flipY;
    }

    public void setImageScale() {
        currentPlot.crop(cropLeft, cropTop, cropRight, cropBottom);
    }

    public void setZoom(float value)
    {
        zoomScale = value;
    }

    public void setPenWidth(float width) {
        penWidth = width;
        com.sendPenWidth();

        if (!currentPlot.isPlotting()) {
            int levels = (int) ((float) (pixelSize) / penWidth);
            if (levels < 1) levels = 1;
            if (levels > 255) levels = 255;
            range = 255 / levels;

            currentPlot.calculate();
        }
    }

    public void setPixelSize(int value) {

        if (!currentPlot.isPlotting()) {
            pixelSize = value;

            int levels = (int) ((float) (pixelSize) / penWidth);
            if (levels < 1) levels = 1;
            if (levels > 255) levels = 255;
            range = 255 / levels;

            currentPlot.calculate();

        }
    }

    public float unScaleX(float x)
    {
        return (x-originX)/zoomScale+homeX;
    }

    public float unScaleY(float y)
    {
        return (y-originY)/zoomScale+homeY;
    }

    public float scaleX(float x)
    {
        return (x-homeX)*zoomScale + originX;
    }

    public float scaleY(float y)
    {
        return (y-homeY)*zoomScale + originY;
    }

    public void updatePos(float x, float y)
    {
        currentX = x;
        currentY = y;
        handles[3].x = x;
        handles[3].y = y;
        motorsOn = true;
    }

    public void sline(float x1, float y1, float x2, float y2)
    {
        strokeWeight(0.5f);
        line(scaleX(x1), scaleY(y1), scaleX(x2), scaleY(y2));
    }

    public void draw()
    {
        background(backgroundColor);
        // I put the if(draw) arround all the drawing routines see if just placing it around the drawing of the image 
        // below is enough
        if(draw)
        {


          drawPage();
          drawOrigin();
          drawTicks(); 
          drawPaper();

          for (Handle handle : handles) {
              handle.update();
              handle.display();
          }
        
          if (currentPlot.isLoaded())
          {
              currentPlot.draw();
          }
      
          drawGondola();


          // try just skipping the image draw here
          if (oimg != null)
          {
            image(oimg, imageX, imageY, imageWidth, imageHeight);
            drawImageFrame();
            drawSelector();
          }

        }

        if (jogX != 0)
        {
            com.moveDeltaX(jogX);
        }
        if (jogY != 0)
        {
            com.moveDeltaY(jogY);
        }
        com.serialEvent();
        tick++;
        if(millis() > lastTime+1000)
        {
          rate = tick;
          tick = 0;
          freeMemory = Runtime.getRuntime().freeMemory()/1000000;
          totalMemory = Runtime.getRuntime().totalMemory()/1000000;
          lastTime = millis();
        }
        stroke(statusColor);
        fill(statusColor);
        text("FPS: "+nf(rate,2,0) +"  Mem: "+freeMemory+"/"+totalMemory+"M",10,height-4);
        String status = " Size: "+machineWidth+"x"+machineHeight +" Zoom: "+nf(zoomScale, 0, 2);
        status += " X: "+nf(currentX, 0, 2)+" Y: "+nf(currentY, 0, 2);
        status += " A: "+nf(getMachineA(currentX, currentY), 0, 2);
        status += " B: "+nf(getMachineB(currentX, currentY), 0, 2);
        if(currentPlot.isLoaded())
          status += " Plot: "+currentPlot.progress();
        text(status, 160, height-4);
    }

    public void drawGondola()
    {
        stroke(gondolaColor);
        strokeWeight(2);
        line(scaleX(0), scaleY(0), scaleX(currentX), scaleY(currentY));
        line(scaleX(machineWidth), scaleY(0), scaleX(currentX), scaleY(currentY));
        fill(textColor);
        stroke(gridColor);
        if (motorsOn)
            fill(motorOnColor);
        else
            fill(motorOffColor);
        ellipse(scaleX(0), scaleY(0), 20, 20);
        ellipse(scaleX(machineWidth), scaleY(0), 20, 20);
    }

    public void drawPage()
    {
        stroke(gridColor);
        strokeWeight(2);
        fill(machineColor);
        rect(scaleX(0), scaleY(0), machineWidth*zoomScale, machineHeight*zoomScale);

    }

    public void drawPaper()
    {
        fill(pageColor);
        stroke(gridColor);
        strokeWeight(0.4f);
        float pWidth = paperWidth*25.4f;
        float pHeight = paperHeight*25.4f;
        rect(scaleX(homeX - pHeight / 2), scaleY(homeY), pHeight * zoomScale, pWidth * zoomScale);
        rect(scaleX(homeX - pWidth / 2), scaleY(homeY), pWidth * zoomScale, pHeight * zoomScale);
     //   noFill();
     //   rect(scaleX(homeX - pWidth / 2), scaleY(homeY), pWidth * zoomScale, pHeight * zoomScale);
     //   rect(scaleX(homeX - pHeight / 2), scaleY(homeY), pHeight * zoomScale, pWidth * zoomScale);
        

    }

    public void drawImageFrame()
    {
        noFill();
        stroke(cropColor);
        strokeWeight(2);
        line(cropLeft, cropTop, cropRight, cropTop);
        line(cropRight, cropTop, cropRight, cropBottom);
        line(cropRight, cropBottom, cropLeft, cropBottom);
        line(cropLeft, cropBottom, cropLeft, cropTop);
        rect(cropLeft, cropTop+(cropBottom-cropTop)/2-5, 10, 10);
        rect(cropLeft+(cropRight-cropLeft)/2-5, cropTop, 10, 10);
        rect(cropRight-10, cropTop+(cropBottom-cropTop)/2-5, 10, 10);
        rect(cropLeft+(cropRight-cropLeft)/2-5, cropBottom-10, 10, 10);
    }

    public void drawSelector()
    {
        if (overCropLeft(startX, startY))
        {
          fill(cropColor);
          stroke(cropColor);
          rect(cropLeft, cropTop+(cropBottom-cropTop)/2-5, 10, 10);
            cropLeft = mouseX;
            if (cropLeft < imageX)
                cropLeft = imageX;
            if (cropLeft > cropRight-20)
                cropLeft = cropRight-20;
        } else if (overCropRight(startX, startY))
        {
          fill(cropColor);
          stroke(cropColor);
          rect(cropRight-10, cropTop+(cropBottom-cropTop)/2-5, 10, 10);
          
            cropRight = mouseX;
            if (cropRight < imageX+20)
                cropRight = imageX+20;
            if (cropRight > imageX+imageWidth)
                cropRight = imageX+imageWidth;
        } else if (overCropTop(startX, startY))
        {
          fill(cropColor);
          stroke(cropColor);
          rect(cropLeft+(cropRight-cropLeft)/2-5, cropTop, 10, 10);
            cropTop = mouseY;
            if (cropTop < imageY)
                cropTop = imageY;
            if (cropTop > imageY+imageHeight-20)
                cropTop = imageY+imageHeight-20;
        } else if (overCropBottom(startX, startY))
        {
          fill(cropColor);
          stroke(cropColor);
          rect(cropLeft+(cropRight-cropLeft)/2-5, cropBottom-10, 10, 10);
            cropBottom = mouseY;
            if (cropBottom < imageY-20)
                cropBottom = imageY-20;
            if (cropBottom > imageY+imageHeight)
                cropBottom = imageY+imageHeight;
        }
    }

    public void drawOrigin()
    {
        noFill();
        stroke(gridColor);
        strokeWeight(0.1f);
        line(scaleX(0), scaleY(homeY), scaleX(machineWidth), scaleY(homeY));
        line(scaleX(homeX), scaleY(0), scaleX(homeX), scaleY(machineHeight));
    }

    public void drawTicks()
    {
        stroke(gridColor);
        strokeWeight(0.1f);
        for (int x = 0; x<machineWidth; x+=10)
        {
            line(scaleX(x), scaleY(homeY-5), scaleX(x), scaleY(homeY+5));
        }
        for (int y = 0; y<machineHeight; y+=10)
        {

            line(scaleX(homeX - 5), scaleY(y), scaleX(homeX + 5), scaleY(y));
        }
    }
