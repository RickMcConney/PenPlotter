import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

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
import java.util.Set; 
import java.util.HashSet; 
import java.util.LinkedList; 
import java.util.List; 
import java.util.Collections; 
import java.util.Enumeration; 
import java.util.Vector; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class PenPlotter extends PApplet {





 //import the Serial library

















final static String ICON  = "icons/penDown.png";
final static String TITLE = "PenPlotter v0.2";

ControlP5 cp5;
Handle[] handles;
float cncSafeHeight = 5;
float cncScaleX = 1;
float cncScaleY = -1;
float scaleX = 1;
float scaleY = 1;

float currentX = 420;
float currentY = 250;
int stickX;
int stickY;

int machineWidth = 840;
int homeX = machineWidth/2;
int machineHeight = 800;
int homeY = 250;

int speedValue = 500;

float stepsPerRev = 1600;
float mmPerRev = 20;

float zoomScale = 0.75f;


int menuWidth = 110;
int originX = (machineWidth+menuWidth)/2;
int originY = 200;
int oldOriginX;
int oldOriginY;
int oldOffX;
int oldOffY;

int offX = 0;
int offY = 0;
int startX;
int startY;

int imageX = 120;
int imageY = 20;
;
int imageWidth = 200;
int imageHeight = 200;

int cropLeft = imageX;
int cropTop = imageY;
int cropRight = imageX+imageWidth;
int cropBottom = imageY+imageHeight;

boolean overLeft = false;
boolean overRight = false;
boolean overTop = false;
boolean overBottom = false;
boolean motorsOn = false;

int penColor = color(0, 0, 255);
int pageColor = color(255, 255, 255);
int backgroundColor = color(192, 192, 192);
int gridColor = color(128, 128, 128);
int selectColor = color(0, 255, 0);
int textColor = color(0, 0, 255);
int motorOnColor = color(255, 0, 0);
int motorOffColor = color(0, 0, 255);
int dirty = 0;

private void prepareExitHandler () {

  Runtime.getRuntime().addShutdownHook(new Thread(new Runnable() {

    public void run () {
      println("SHUTDOWN HOOK");
    }
  }
  ));
}

public void exit()
{
  println("exit");
  send("M84\n");
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

  size(840, 650);
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

  penWidth = Float.parseFloat(props.getProperty("machine.penSize"));

  svgDpi = Float.parseFloat(props.getProperty("svg.pixelsPerInch"));
  svgScale = 25.4f/svgDpi;
  svgName = props.getProperty("svg.name");
  cncSafeHeight = Float.parseFloat(props.getProperty("cnc.safeHeight"));


  baudRate = Long.parseLong(props.getProperty("com.baudrate"));
  //todo lastPort not used

  lastPort = Integer.parseInt(props.getProperty("com.serialPort"));

  offX = Integer.parseInt(props.getProperty("machine.offX"));
  offY = Integer.parseInt(props.getProperty("machine.offY"));

  zoomScale = Float.parseFloat(props.getProperty("machine.zoomScale"));

  cropLeft = Integer.parseInt(props.getProperty("image.cropLeft"));
  cropRight = Integer.parseInt(props.getProperty("image.cropRight"));
  cropTop = Integer.parseInt(props.getProperty("image.cropTop"));
  cropBottom = Integer.parseInt(props.getProperty("image.cropBottom"));


  //make our canvas 200 x 200 pixels big
  listPorts();

  RG.init(this);
  RG.ignoreStyles(true);
  RG.setPolygonizer(RG.ADAPTATIVE);
  //  RG.setPolygonizerAngle(80*PI/180);

  createcp5GUI();

  speedValue = Integer.parseInt(props.getProperty("machine.motors.maxSpeed"));
  speedSlider.setValue(speedValue);

  pixelSize = Integer.parseInt(props.getProperty("image.pixelSize"));
  pixelSizeSlider.setValue(pixelSize);

  svgUserScale = Float.parseFloat(props.getProperty("svg.UserScale"));
  scaleSlider.setValue(svgUserScale);

  updateScale();

  handles = new Handle[4];
  handles[0] = new Handle("homeY", 0, homeY, 0, 10, handles, false, true, 128);
  handles[1] = new Handle("mWidth", machineWidth, machineHeight/2, 0, 10, handles, true, false, 64);
  handles[2] = new Handle("mHeight", homeX, machineHeight, 0, 10, handles, false, true, 64);
  handles[3] = new Handle("gondola", (int)currentX, (int)currentY, 0, 10, handles, true, true, 2);
  // handles[4] = new Handle("mmPerRev",0,0,0,10,handles,false,true,64);
  // handles[5] = new Handle("stepsPerRev",machineWidth,0,0,10,handles,false,true,64);
} 

public void mouseReleased() { 

  if (overLeft || overRight || overTop || overBottom)
  {
    cropImage(cropLeft, cropTop, cropRight, cropBottom);
  }
  overLeft = false;
  overRight = false;
  overTop = false;
  overBottom = false;
  startX = 0;
  startY = 0;

  for (int i = 0; i < handles.length; i++) {
    if (handles[i].wasActive())
    {
      if (handles[i].id.equals("gondola"))
      {
        send("G0 X"+currentX+" Y"+currentY+"\n");
      }
      if (handles[i].id.equals("homeY"))
      {
        sendHome();
      }
      if (handles[i].id.equals("mWidth"))
      {
        sendSpecs();
      }
    }
    handles[i].releaseEvent();
  }
}

public void handleMoved(String id, int x, int y)
{
  if (id.equals("homeY"))
    homeY = y;
  if (id.equals("gondola"))
  {
    currentX =  x;
    currentY =  y;
  } else if (id.equals("mWidth"))
  {
    machineWidth = x;
    homeX = machineWidth/2;
    handles[2].x = homeX;
  } else if (id.equals("mHeight"))
  {
    machineHeight = y;
    handles[1].y = y/2;
  }
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

public boolean overImage(int x, int y)
{
  int x1 = imageX;
  int x2 = x1+imageWidth;
  int y1 = imageY;
  int y2 = y1+imageHeight;

  if (x < x1) return false;
  if (x > x2) return false;
  if (y < y1) return false;
  if (y > y2) return false;

  return true;
}

public boolean overCropLeft(int x, int y)
{
  if (overLeft) return true;

  int x1 = cropLeft;
  int x2 = x1+10;
  int y1 = cropTop+(cropBottom-cropTop)/2;
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
  int y1 = cropTop+(cropBottom-cropTop)/2;
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
public void mouseDragged() 
{
  // if(mouseX < menuWidth) return;
  // if(overImage(startX,startY)) return;


  if (mouseButton == CENTER) {

    originX = oldOriginX + mouseX -startX;
    originY = oldOriginY + mouseY -startY;
  } else if (mouseButton == RIGHT)
  {

    offX = oldOffX + (int)((mouseX -startX)/zoomScale);
    offY = oldOffY + (int)((mouseY -startY)/zoomScale);
  }
}

public void mouseWheel(MouseEvent event) {

  float e = event.getCount();

  if (e > 0)
    setZoom(zoomScale*1.1f);
  else
    setZoom(zoomScale*0.9f);
}

public void keyPressed() {
  if (key == 'x') {
    cncScaleX *= -1;
    updateScale();
  } else if (key == 'y') {
    cncScaleY *= -1;
    updateScale();
  }
}

public void setSpeed(int value)
{
  speedValue = value;
  send("G0 F"+speedValue+"\n");
}

public void updateScale()
{
  scaleX = svgScale*svgUserScale*cncScaleX;
  scaleY = svgScale*svgUserScale*cncScaleY;
  
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
}

public void sline(float x1, float y1, float x2, float y2)
{
  strokeWeight(0.5f);
  line(scaleX(x1), scaleY(y1), scaleX(x2), scaleY(y2));
  //updatePos(x2,y2);
}

public void setZoom(float value)
{
  zoomScale = value;
}



public void draw() {

  // dirty++;
  // if(dirty >=4)
  //   dirty = 0;
  if (dirty == 0)
  {
    background(backgroundColor);

    drawPage();
    drawPaper();
    drawOrigin();
    drawTicks();
    drawGondola(); 
    for (int i = 0; i < handles.length; i++) {
      handles[i].update();
      handles[i].display();
    }

    if (sh != null)
    {
      drawSvg();
      drawPlottedLine();
    }

    if (oimg != null)
    {
      drawDiamondPixels();
      drawPlottedPixels();
      image(oimg, imageX, imageY, imageWidth, imageHeight);
      drawImageFrame();
      drawSelector();
      // drawMachineGrid(pixelSize);
    }

    if (gcodeData != null)
    {
      drawPath();
    }




    // drawMenu();
  }

  if (stickX != 0)
  {
    send("G0 X"+stickX+"\n");
    updatePos(currentX += stickX, currentY);
  }
  if (stickY != 0)
  {
    send("G0 Y"+stickY+"\n");
    updatePos(currentX, currentY += stickY);
  }
}

public void drawMenu()
{
  fill(128, 128, 128);
  noStroke();
  rect(0, 0, 120, 545);
}
public void drawGondola()
{
  stroke(textColor);
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
  fill(pageColor);
  rect(scaleX(0), scaleY(0), machineWidth*zoomScale, machineHeight*zoomScale);
  fill(textColor);
  String status = ""+machineWidth+" X "+machineHeight +" "+nf(zoomScale, 0, 2);
  status += " X "+nf(currentX, 0, 2)+" Y "+nf(currentY, 0, 2);
  status += " A "+nf(getMachineA(currentX, currentY), 0, 2);
  status += " B "+nf(getMachineB(currentX, currentY), 0, 2); 
  text(status, scaleX(machineWidth)-textWidth(status)-30, scaleY(0)+15);
}

public void drawPaper()
{
  noFill();
  stroke(gridColor);
  strokeWeight(0.4f);
  float pWidth = 8.5f*25.4f;
  float pHeight = 11*25.4f;
  rect(scaleX(homeX-pWidth/2), scaleY(homeY), pWidth*zoomScale, pHeight*zoomScale);
  rect(scaleX(homeX-pHeight/2), scaleY(homeY), pHeight*zoomScale, pWidth*zoomScale);
  strokeWeight(0.4f);
  pWidth = 18*25.4f;
  pHeight = 24*25.4f;
  rect(scaleX(homeX-pWidth/2), scaleY(homeY), pWidth*zoomScale, pHeight*zoomScale);
}

public void drawImageFrame()
{
  noFill();
  stroke(selectColor);
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

    cropLeft = mouseX;
    if (cropLeft < imageX)
      cropLeft = imageX;
    if (cropLeft > cropRight-20)
      cropLeft = cropRight-20;
  } else if (overCropRight(startX, startY))
  {

    cropRight = mouseX;
    if (cropRight < imageX+20)
      cropRight = imageX+20;
    if (cropRight > imageX+imageWidth)
      cropRight = imageX+imageWidth;
  } else if (overCropTop(startX, startY))
  {

    cropTop = mouseY;
    if (cropTop < imageY)
      cropTop = imageY;
    if (cropTop > imageY+imageHeight-20)
      cropTop = imageY+imageHeight-20;
  } else if (overCropBottom(startX, startY))
  {

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

    line(scaleX(homeX-5), scaleY(y), scaleX(homeX+5), scaleY(y));
  }
}

public void drawMachineGrid(int step)
{

  float aLen = (int)getMachineA(machineWidth/2-simage.width/2+offX, homeY+offY);
  float bss = (int)getMachineB(machineWidth/2+simage.width/2+offX, homeY+offY);
  float bLen = (int) getMachineB(machineWidth/2-simage.width/2+offX, homeY+offY);
  while (bLen > bss)
  {
    bLen -= pixelSize;
  } 

  strokeWeight(0.1f);
  stroke(0);
  noFill();
  for (int i = 0; i<80; i++)
  {

    arc(scaleX(0), scaleY(0), 2*(aLen+i*step)*zoomScale, 2*(aLen+i*step)*zoomScale, PI/8, PI/3);
    arc(scaleX(machineWidth), scaleY(0), 2*(bLen+i*step)*zoomScale, 2*(bLen+i*step)*zoomScale, PI-PI/3, PI-PI/8);
  }
}
float lastX = 0;
float lastY = 0;
float lastZ = 0;
private ArrayList<String> gcodeData = null;
private float toInch = 0.0393701f;
private float toMm = 1f;
private float conversion = toMm;
final int RED = 0;
final int GREEN = 1;
final int BLUE = 2;
final int WHITE = 3;
final int MAXCOLOR = 4;
Path gcodePath = null;
ArrayList<Path> gcodePaths;
int gcodeIndex = 0;
boolean plottingGcode = false;

public void clearGcode()
{
  gcodeData = null;
  gcodePaths = null;
  resetGcode();
}

public void resetGcode()
{
    plottingGcode = false;  
}

public void loadGcode(String fileName)
{
  lastX = homeX;
  lastY = homeY;
  lastZ = 0;
  try {
    gcodeData = getStringFromFile(fileName);
    gcodePaths = new ArrayList<Path>();
    renderData(gcodeData);
  }
  catch(Exception e)
  {  
    println(e);
    e.printStackTrace();
  }
  println("Loaded "+gcodePaths.size()+" Paths");
  for (int i = 0; i<gcodePaths.size (); i++)
  {
    println("Path "+i+" len "+gcodePaths.get(i).size());
  }
}

public static ArrayList<String> convertStreamToArray(InputStream is) throws Exception {
  ArrayList<String> list = new ArrayList<String>();
  BufferedReader reader = new BufferedReader(new InputStreamReader(is));
  String line = null;
  while ( (line = reader.readLine ()) != null) {
    list.add(line+"\n");
  }
  reader.close();
  return list;
}

public static ArrayList<String> getStringFromFile (String filePath) throws Exception {
  File fl = new File(filePath);
  FileInputStream fin = new FileInputStream(fl);
  ArrayList<String> ret = convertStreamToArray(fin);
  //Make sure you close all streams.
  fin.close();        
  return ret;
}


public void renderData(ArrayList<String> data)
{
  for (int i = 0; i<data.size (); i++)
  {
    renderData(i);
  }
}

private void renderData(int i)
{
  String cmd = "";
  int step = i;
  float x = lastX;
  float y = lastY;
  float z = lastZ;

  float I = Float.NaN;
  float J = Float.NaN;
  double R = 0;

  if (gcodeData.get(i).startsWith("("))
    return;

  String[] tokens = gcodeData.get(i).split(" ");
  for (int t = 0; t < tokens.length; t++)
  {
    String token = tokens[t];
    // Log.d("cnc",token);

    if (token.startsWith("G"))
      cmd = token;
    if ("G20".equals(cmd)) conversion = toInch;
    if ("G21".equals(cmd)) conversion = toMm;

    if (token.startsWith("X"))
      x = Float.parseFloat(token.substring(1))*conversion;
    else if (token.startsWith("Y"))
      y = Float.parseFloat(token.substring(1))*conversion;
    else if (token.startsWith("Z"))
      z = -Float.parseFloat(token.substring(1))*conversion;
    else if (token.startsWith("I"))
      I = Float.parseFloat(token.substring(1))*conversion;
    else if (token.startsWith("J"))
      J = Float.parseFloat(token.substring(1))*conversion;
    else if (token.startsWith("R"))
      R = Double.parseDouble(token.substring(1))*conversion;
  }

  if (cmd.equals(""))
    return;

  if (x != lastX || y != lastY )
  {

    if (cmd.equals("G0"))
    {

      addLine(step, BLUE, lastX, lastY, lastZ, x, y, z);
    } else if (cmd.equals("G1"))
    {
      addLine(step, GREEN, lastX, lastY, lastZ, x, y, z);
    } else if (cmd.equals("G2") || cmd.equals("G3"))
    {
      boolean isCW = cmd.equals("G2");
      if (Float.isNaN(I) && Float.isNaN(J)) { // todo only supports
        // relative
        float[] center = convertRToCenter(lastX, lastY, x, y, R, false, isCW);

        generatePointsAlongArcBDring(step, RED, lastX, lastY, lastZ, x, y, z, center[0], 
        center[1], isCW, R, 5);
      } else
      {

        generatePointsAlongArcBDring(step, RED, lastX, lastY, lastZ, x, y, z, I + lastX, J
          + lastY, isCW, R, 5);
      }
    }

    lastX = x;
    lastY = y;
    lastZ = z;
  }
}

private float[] convertRToCenter(float sx, float sy, float ex, float ey, double radius, boolean absoluteIJK, boolean clockwise) {
  double R = radius;
  float cx;
  float cy;

  // This math is copied from GRBL in gcode.c
  double x = ex - sx;
  double y = ey - sy;

  double h_x2_div_d = 4 * R*R - x*x - y*y;
  if (h_x2_div_d < 0) { 
    System.out.println("Error computing arc radius.");
  }
  h_x2_div_d = (-Math.sqrt(h_x2_div_d)) / Math.hypot(x, y);

  if (clockwise == false) {
    h_x2_div_d = -h_x2_div_d;
  }

  // Special message from gcoder to software for which radius
  // should be used.
  if (R < 0) {
    h_x2_div_d = -h_x2_div_d;
    // TODO: Places that use this need to run ABS on radius.
    radius = -radius;
  }

  double offsetX = 0.5f*(x-(y*h_x2_div_d));
  double offsetY = 0.5f*(y+(x*h_x2_div_d));

  if (!absoluteIJK) {
    cx = (float)(sx + offsetX);
    cy = (float)(sy + offsetY);
  } else {
    cx = (float)offsetX;
    cy = (float)offsetY;
  }
  //        Log.d("cnc","R = "+R+" sx = "+sx+" sy = "+sy+" cx = "+cx+" cy = "+cy+" ex = "+ex+" ey = "+ey);       
  float[] center = new float[2];
  center[0] = cx;
  center[1] = cy;
  return center;
}

private double getAngle(float sx, float sy, float ex, float ey) {
  double deltaX = ex - sx;
  double deltaY = ey - sy;

  double angle = 0.0f;

  if (deltaX != 0) { // prevent div by 0
    // it helps to know what quadrant you are in
    if (deltaX > 0 && deltaY >= 0) {  // 0 - 90
      angle = Math.atan(deltaY/deltaX);
    } else if (deltaX < 0 && deltaY >= 0) { // 90 to 180
      angle = Math.PI - Math.abs(Math.atan(deltaY/deltaX));
    } else if (deltaX < 0 && deltaY < 0) { // 180 - 270
      angle = Math.PI + Math.abs(Math.atan(deltaY/deltaX));
    } else if (deltaX > 0 && deltaY < 0) { // 270 - 360
      angle = Math.PI * 2 - Math.abs(Math.atan(deltaY/deltaX));
    }
  } else {
    // 90 deg
    if (deltaY > 0) {
      angle = Math.PI / 2.0f;
    }
    // 270 deg
    else {
      angle = Math.PI * 3.0f / 2.0f;
    }
  }

  return angle;
} 

public void generatePointsAlongArcBDring(int step, int c, float sx, float sy, float sz, float ex, float ey, float ez, float cx, float cy, boolean isCw, double R, int arcResolution) {
  double radius = R;
  double sweep;

  // Calculate radius if necessary.
  if (radius == 0) {
    radius = Math.sqrt(Math.pow(sx - cx, 2.0f) + Math.pow(sy - cy, 2.0f));
  }
  //        Log.d("cnc","R1 = "+R+" radius = "+radius+" cx = "+cx+" cy = "+cy);
  // Calculate angles from center.
  double startAngle = getAngle(cx, cy, sx, sy);
  double endAngle = getAngle(cx, cy, ex, ey);

  // Fix semantics, if the angle ends at 0 it really should end at 360.
  if (endAngle == 0) {
    endAngle = Math.PI * 2;
  }

  // Calculate distance along arc.
  if (!isCw && endAngle < startAngle) {
    sweep = ((Math.PI * 2 - startAngle) + endAngle);
  } else if (isCw && endAngle > startAngle) {
    sweep = ((Math.PI * 2 - endAngle) + startAngle);
  } else {
    sweep = Math.abs(endAngle - startAngle);
  }

  generatePointsAlongArcBDring(step, c, sx, sy, sz, ex, ey, ez, cx, cy, isCw, radius, startAngle, endAngle, sweep, arcResolution);
}

/**
 * Generates the points along an arc including the start and end points.
 */
private void generatePointsAlongArcBDring(int step, int c, float sx, float sy, float sz, float ex, float ey, float ez, float cx, float cy, boolean isCw, double radius, 
double startAngle, double endAngle, double sweep, int numPoints) {


  double angle;
  float x = ex;
  float y = ey;
  float z = ez;
  float lastX = sx;
  float lastY = sy;
  float lastZ = sz;

  double zIncrement = (ez - sz) / numPoints;
  for (int i=0; i<=numPoints; i++)
  {
    if (isCw) {
      angle = (startAngle - i * sweep/numPoints);
    } else {
      angle = (startAngle + i * sweep/numPoints);
    }

    if (angle >= Math.PI * 2) {
      angle = angle - Math.PI * 2;
    }

    x = (float) (Math.cos(angle) * radius + cx);
    y = (float) (Math.sin(angle) * radius + cy);
    z += zIncrement;

    addLine(step, c, lastX, lastY, lastZ, x, y, z);
    lastX = x;
    lastY = y;
    lastZ = z;
  }
}   
public void addLine(int step, int c, float lastX, float lastY, float lastZ, float x, float y, float z) 
{

  if (c == BLUE || gcodePath == null)
  {
    gcodePath = new Path();
    gcodePaths.add(gcodePath);
  }
    
  gcodePath.addPoint(x, y);

}

public void rotateGcode(int rotation)
{
  if (gcodePaths == null) return;

  for ( int i=0; i<gcodePaths.size (); i++)
  {
    Path p = gcodePaths.get(i);
    for (int j = 0; j<p.size (); j++)
    {
      float x = p.getPoint(j).x;
      float y = p.getPoint(j).y;

      p.getPoint(j).x = -y;
      p.getPoint(j).y = x;
    }
  }
}

public void drawPath()
{
  float lastX = -offX/(svgUserScale*cncScaleX);
  float lastY = -offY/(svgUserScale*cncScaleY);
  RPoint cur;
  for ( int i=0; i<gcodePaths.size (); i++)
  {
    Path p = gcodePaths.get(i);
    for (int j = 0; j<p.size (); j++)
    {
      if (j == 0)
        stroke(0, 255, 0);
      else
        stroke(255, 0, 0);
      cur = p.getPoint(j);
      sline(lastX*svgUserScale*cncScaleX+offX+homeX, lastY*svgUserScale*cncScaleY+offY+homeY, cur.x*svgUserScale*cncScaleX+offX+homeX, cur.y*svgUserScale*cncScaleY+offY+homeY);
      lastX = cur.x;
      lastY = cur.y;
    }
  }
  stroke(0, 255, 0);
  sline(lastX*svgUserScale*cncScaleX+offX+homeX, lastY*svgUserScale*cncScaleY+offY+homeY, homeX, homeY);
}

public void plotGcode()
{
  gcodeIndex = 0;
  plottingGcode = true;
  lastX = 0;
  lastY = 0;
  lastZ = 0;
  send("G0 F"+speedValue+"\n");
  nextGcode();
}

public void nextGcode()
{

  String cmd = "";
  float x = lastX;
  float y = lastY;
  float z = lastZ;

  float I = Float.NaN;
  float J = Float.NaN;
  double R = 0;
  boolean sent = false;


  while (!sent)
  {
    if (gcodeIndex >= gcodeData.size())
    {
      plottingGcode = false;
      sendPenUp();
      send("G0 X"+homeX+" Y"+homeY);
      currentX = homeX;
      currentY = homeY;
      send("M84\n");

      return;
    }
    if (gcodeData.get(gcodeIndex).startsWith("("))
    {
      gcodeIndex++;
      continue;
    }


    String[] tokens = gcodeData.get(gcodeIndex).split(" ");
    for (int t = 0; t < tokens.length; t++)
    {
      String token = tokens[t];
      // Log.d("cnc",token);
      if (token.startsWith("G"))
        cmd = token;
      if ("G20".equals(cmd)) conversion = toInch;
      if ("G21".equals(cmd)) conversion = toMm;
      if (token.startsWith("X"))
        x = Float.parseFloat(token.substring(1))*conversion*svgUserScale*cncScaleX;
      else if (token.startsWith("Y"))
        y = Float.parseFloat(token.substring(1))*conversion*svgUserScale*cncScaleY;
      else if (token.startsWith("Z"))
        z = -Float.parseFloat(token.substring(1))*conversion*svgUserScale;
      else if (token.startsWith("I"))
        I = Float.parseFloat(token.substring(1))*conversion*svgUserScale*cncScaleX;
      else if (token.startsWith("J"))
        J = Float.parseFloat(token.substring(1))*conversion*svgUserScale*cncScaleY;
      else if (token.startsWith("R"))
        R = Double.parseDouble(token.substring(1))*conversion*svgUserScale;
    }

    if (cmd.equals(""))
    {
      gcodeIndex++;
      continue;
    }


    if (x != lastX || y != lastY )
    {

      if (cmd.equals("G0"))
      {
        sendPenUp();
        send("G0 X"+(x+offX+homeX)+" Y"+(y+offY+homeY)+"\n");
        sendPenDown();
        sent= true;
      } else if (cmd.equals("G1"))
      {
        send("G1 X"+(x+offX+homeX)+" Y"+(y+offY+homeY)+"\n");
        sent= true;
      } else if (cmd.equals("G2"))
      {
        if (!Float.isNaN(I) && !Float.isNaN(J))
        { 
          send("G2 X"+(x+offX+homeX)+" Y"+(y+offY+homeY)+" I"+I+" J"+J+"\n");
          sent= true;
        }
      } else if (cmd.equals("G3"))
      {
        if (!Float.isNaN(I) && !Float.isNaN(J))
        { 
          send("G3 X"+(x+offX+homeX)+" Y"+(y+offY+homeY)+" I"+I+" J"+J+"\n");
          sent = true;
        }
      }

      currentX = x+offX+homeX;
      currentY = y+offY+homeY;
      lastX = x;
      lastY = y;
      lastZ = z;
    } 
    gcodeIndex++;
  }
}




class Handle {

  String id;
  float x, y;
  int boxx, boxy;
  int stretch;
  int size;
  boolean over;
  boolean press;
  boolean locked = false;
  boolean otherslocked = false;
  boolean followsX;
  boolean followsY;
  float trackSpeed;
  Handle[] others;

  Handle(String aid, int ix, int iy, int il, int is, Handle[] o, boolean followX, boolean followY, float speed) {
    id = aid;
    x = ix;
    y = iy;
    stretch = il;
    size = is;
    boxx = (int)scaleX(x+stretch) - size/2;
    boxy = (int)scaleY(y) - size/2;
    trackSpeed = speed;
    others = o;
    followsX = followX;
    followsY = followY;
  }
  public boolean wasActive()
  {
    return locked;
  }

  public void update() {
    boxx = (int)scaleX(x+stretch)-size/2;
    boxy = (int)scaleY(y) - size/2;

    for (int i=0; i<others.length; i++) {
      if (others[i].locked == true) {
        otherslocked = true;
        break;
      } else {
        otherslocked = false;
      }
    }

    if (otherslocked == false) {
      overEvent();
      pressEvent();
    }

    if (press) {

      if (followsX)
      {
        float dx = (unScaleX(mouseX) -x)/trackSpeed;
        x+=dx;
      }
      if (followsY)
      { 
        float dy = (unScaleY(mouseY) -y)/trackSpeed ;
        y += dy;
      }
      handleMoved(id, (int)x, (int)y);
    }
  }

  public void overEvent() {
    if (overRect(boxx, boxy, size, size)) {
      over = true;
    } else {
      over = false;
    }
  }

  public void pressEvent() {
    if (over && mousePressed || locked) {
      press = true;
      locked = true;
    } else {
      press = false;
    }
  }

  public void releaseEvent() {

    locked = false;
  }

  public void display() {

    fill(255);
    stroke(0);
    rect(boxx, boxy, size, size);
    if (over || press) {
      fill(textColor);

      rect(boxx, boxy, size, size);

      int offx = 20;
      if (x > homeX)
        offx = -40;
      if (followsX && followsY)
        text("X "+(int)x+" Y "+(int)y, boxx-30, boxy+30);
      else if (followsX)
        text("X "+(int)x, boxx+offx, boxy);
      else if (followsY)
        text("Y "+(int)y, boxx+offx, boxy-10);
    }
  }
}

public boolean overRect(int x, int y, int width, int height) {
  if (mouseX >= x && mouseX <= x+width && 
    mouseY >= y && mouseY <= y+height) {
    return true;
  } else {
    return false;
  }
}

public int lock(int val, int minv, int maxv) { 
  return  min(max(val, minv), maxv);
} 

class Path {
  ArrayList<RPoint> points = new ArrayList<RPoint>();

  public void addPoint(float x, float y)
  {
    points.add(new RPoint(x, y));
  }

  public RPoint getPoint(int index)
  {
    return points.get(index);
  }

  public int size()
  {
    return points.size();
  }

  public RPoint first()
  {
    return points.get(0);
  }

  public RPoint last()
  {
    return points.get(points.size()-1);
  }

  public void merge(Path p)
  {
    for (int i = 0; i<p.size (); i++)
    {
      points.add(p.getPoint(i));
    }
  }

  public void reverse()
  {
    ArrayList<RPoint> reverse = new ArrayList<RPoint>();
    for (int i = points.size ()-1; i>=0; i--)
      reverse.add(points.get(i));
    points = reverse;
  }

  public void removeShort(float len)
  {
    ArrayList<RPoint> clean = new ArrayList<RPoint>();
    RPoint last = points.get(0);
    clean.add(last);
    for (int i = 1; i<points.size (); i++)
    {
      RPoint cur = points.get(i);
      if (dist(last.x, last.y, cur.x, cur.y) >= len)
      {
        clean.add(cur);
        last = cur;
      }
    }
    points = clean;
  }
}

Serial myPort;  //the Serial port object
String val;
ArrayList<String> buf = new ArrayList<String>();

ArrayList<String> comPorts = new ArrayList<String>();
long baudRate = 115200;
int lastPort;
int okCount = 0;

public void listPorts()
{
  //  initialize your serial port and set the baud rate to 9600

  comPorts.add("Connect");
  comPorts.add("Disconnect");

  for (int i = 0; i<Serial.list().length; i++)
  {
    String name = Serial.list()[i];
    int dot = name.indexOf('.');
    if (dot >= 0)
      name = name.substring(dot+1);
    if(name.indexOf("luetooth") <0) 
    {
        comPorts.add(name);
        println(name);
    }
  }
}
public void disconnect()
{
  clearQueue();
  if (myPort != null)
    myPort.stop();
  myPort = null;
  //  myTextarea.setVisible(false);
}
public void connect(int port)
{
  clearQueue();
  try {
    myPort = new Serial(this, Serial.list()[port], (int)baudRate);
    lastPort = port;
    //      myTextarea.setVisible(true);
  }
  catch(Exception exp)
  {
    println("Failed to open serial port");
  }
}

public void connect(String name)
{
  for (int i = 0; i<Serial.list().length; i++)
  {
    if (Serial.list()[i].indexOf(name) >=0)
    {
      connect(i);
      return;
    }
  }
  disconnect();
}

public void sendHome()
{
  send("M1 Y"+homeY+"\n");
}

public void sendSpeed()
{
  send("G0 F"+speedValue+"\n");
}

public void sendPenWidth()
{
  send("M4 E"+penWidth+"\n");
}

public void sendSpecs()
{
  send("M4 X"+machineWidth+" E"+penWidth+" S"+stepsPerRev+" P"+mmPerRev+"\n");
}

public void sendPenUp()
{
  send("G4 P250\n");
  send("M340 P3 S2350\n");
  send("G4 P250\n");
}

public void sendPenDown()
{
  send("G4 P250\n");
  send("M340 P3 S1500\n");
  send("G4 P250\n");
}

public void initArduino()
{
  sendHome();
  sendSpeed();
  sendSpecs();
}

public void clearQueue()
{
  buf.clear();
  okCount = 0;
}
public void queue(String msg)
{
  print("Q "+msg);
  buf.add(msg);
}

public void nextMsg()
{
  if (buf.size() > 0)
  {
    String msg = buf.get(0);
    //print("sending "+msg);
    oksend(msg);
    buf.remove(0);
  } else
  {
    if (plotting)
      plotLine();
    if (plottingImage)
      plotNextDiamondPixel();
    if (plottingGcode)
      nextGcode();
  }
}
public void send(String msg)
{
  if (okCount >=0)
    oksend(msg);
  else
    queue(msg);
}

public void oksend(String msg)
{
  okCount--;
  print(msg);

  if (myPort != null)
  {
    if (msg.indexOf("G") >= 0)
      motorsOn = true;
    else if (msg.indexOf("M84") >=0)
      motorsOn = false;

    myPort.write(msg);
    myTextarea.setText(" "+msg);
  }
}

public void serialEvent( Serial myPort) {

  if (myPort == null || myPort.available() <=0) return;

  val = myPort.readStringUntil('\n');
  if (val != null) {
    val = trim(val);

    if (val.indexOf("wait") >= 0)
      okCount = 0;
    else               
      println(val);
    String[] tokens = val.split(" ");
    if (tokens[0].startsWith("Free"))
    {
      initArduino();
      okCount++;
      nextMsg();
    }

    if (tokens[0].startsWith("ok"))
    {
      okCount++;
      nextMsg();
    }
  }
}

DropdownList connectDropList;
Textlabel myTextarea;
int leftMargin = 10;
int posY = 10;
int ySpace = 40;
int rotation = 0;

//Println console;
Slider pixelSizeSlider;
Slider speedSlider;
Slider scaleSlider;
Slider penSlider;
PImage penUpImg; 
PImage penDownImg; 
PImage loadImg; 
PImage clearImg;
PImage pauseImg;
PImage plotImg;

class MyButton extends Button {
  public PImage img;

  MyButton(ControlP5 cp5, String theName) {
    super(cp5, theName);
  }
  public void setImg(PImage img)
  {
    this.img = img;
  }
}

public MyButton addButton(String name, String label, int x, int y)
{

  PImage img = loadImage("icons/"+name+".png"); 
  MyButton b = new MyButton(cp5, name);
  b.setPosition(x, y)
    .setSize(menuWidth, 34)
      .setCaptionLabel(label)
        .setView(new myView())
          ;

  b.setImg(img);
  b.getCaptionLabel().setFont(createFont("", 10));
  return b;
}

public Slider addSlider(String name, String label, float min, float max, float value)
{
  Slider s = cp5.addSlider(name)                       
    .setCaptionLabel(label)
      .setPosition(leftMargin, posY+=ySpace/2)
        .setSize(menuWidth, 17)
          .setRange(min, max) 
            .setColorBackground(color(115, 117, 216))
              .setColorActive(color(201, 206, 255))
                .setColorForeground(color(201, 206, 255))
                  .setColorCaptionLabel(color(0))
                    .setColorValue(color(0))
                      .setScrollSensitivity(1)
                        .setValue(value)      
                          ;
  controlP5.Label l = s.getCaptionLabel();
  l.getStyle().marginTop = 0; 
  l.getStyle().marginLeft = -(int)textWidth(label);
  return s;
}

class myView implements ControllerView<Button> {

  public void display(PGraphics theApplet, Button theButton) {
    theApplet.pushMatrix();
    if (theButton.isInside()) {
      if (theButton.isPressed()) { // button is pressed
        theApplet.fill(227, 230, 255);
      } else { // mouse hovers the button
        theApplet.fill(201, 206, 255);
      }
    } else { // the mouse is located outside the button area
      theApplet.fill(115, 117, 216);
    }

    stroke(0);
    strokeWeight(0.5f); 

    theApplet.rect(0, 0, theButton.getWidth(), theButton.getHeight(), 8);   


    // center the caption label 
    int x = theButton.getWidth()/2 - theButton.getCaptionLabel().getWidth()/2-10;
    int y = theButton.getHeight()/2 - theButton.getCaptionLabel().getHeight()/2;

    translate(x, y);
    theButton.getCaptionLabel().setColor(0);
    theButton.getCaptionLabel().draw(theApplet);

    translate(-x, -y);
    PImage img = ((MyButton)theButton).img;
    if (img != null)
    {
      if ("".equals(theButton.getCaptionLabel().getText()))
        theApplet.image(img, theButton.getWidth()/2-16, 0, 32, 32);
      else
        theApplet.image(img, theButton.getWidth()-34, 1, 32, 32);
    }
    theApplet.popMatrix();
  }
}


public void createcp5GUI()
{

  cp5 = new ControlP5(this);

  penUpImg= loadImage("icons/penUp.png"); 
  penDownImg= loadImage("icons/penDown.png"); 
  loadImg= loadImage("icons/load.png"); 
  clearImg= loadImage("icons/clear.png");
  pauseImg = loadImage("icons/pause.png");
  plotImg = loadImage("icons/plot.png");
  
  connectDropList = cp5.addDropdownList("dropListConnect")
    .setPosition(leftMargin, posY)
      .setCaptionLabel("Connect")
        .onEnter(toFront)
          .onLeave(close)
            .setBackgroundColor(color(115, 117, 216))
              .setColorBackground(color(115, 117, 216))
                .setColorForeground(color(201, 206, 255))
                  .setColorActive(color(201, 206, 255))
                    .setColorCaptionLabel(color(0))
                      .setColorValue(color(0))
                        .setItemHeight(20)
                          .setBarHeight(20)
                            .setOpen(false)
                                .addItems(comPorts)
                                  ;


  myTextarea = cp5.addTextlabel("txt")
    .setPosition(leftMargin, posY+=30)
      .setSize(menuWidth, 30)
        .setFont(createFont("", 10))
          .setLineHeight(14)
            .setColor(textColor)
              .setColorBackground(gridColor)
                .setColorForeground(textColor)
                  ;

  addButton("setHome", "Set Home", leftMargin, posY+=ySpace);
  addButton("up", "", leftMargin+30, posY+=ySpace).onPress(press).onRelease(release).setSize(40, 30);
  addButton("left", "", leftMargin+10, posY+=30).onPress(press).onRelease(release).setSize(40, 30);
  addButton("right", "", leftMargin+50, posY).onPress(press).onRelease(release).setSize(40, 30);

  addButton("down", "", leftMargin+30, posY+=30).onPress(press).onRelease(release).setSize(40, 30);

  addButton("load", "Load", leftMargin, posY+=ySpace);
  addButton("plot", "Plot", leftMargin, posY+=ySpace);
  addButton("dorotate", "Rotate", leftMargin, posY+=ySpace);
  addButton("mirrorX","Flip X",leftMargin,posY+=ySpace);
  addButton("mirrorY","Flip Y",leftMargin,posY+=ySpace);

  posY += ySpace;
  scaleSlider = addSlider("scale", "SCALE", 0.1f, 5, svgUserScale);
  pixelSizeSlider = addSlider("pixelSlider", "PIXEL SIZE", 2, 16, pixelSize);

  penSlider = addSlider("penWidth", "PEN WIDTH", 0.1f, 5, 0.5f);
  penSlider.onRelease(penrelease)
    .onReleaseOutside(penrelease);        
  speedSlider = addSlider("speedChanged", "SPEED", 100, 2000, 500);
  speedSlider.onRelease(speedrelease)
    .onReleaseOutside(speedrelease);       
  addButton("penUp", "Pen Up", leftMargin, posY+=ySpace);

  addButton("goHome", "Go Home", leftMargin, posY+=ySpace);
  addButton("off", "Motors Off", leftMargin, posY+=ySpace);
  addButton("save", "Save", leftMargin, posY+=ySpace);
  addButton("export", "Export",leftMargin, posY+=ySpace);




  //console = cp5.addConsole(myTextarea);

  // myTextarea.setVisible(false);
}

CallbackListener toFront = new CallbackListener() {
  public void controlEvent(CallbackEvent theEvent) {
    theEvent.getController().bringToFront();
    ((DropdownList)theEvent.getController()).open();
  }
};

CallbackListener close = new CallbackListener() {
  public void controlEvent(CallbackEvent theEvent) {
    ((DropdownList)theEvent.getController()).close();
  }
};

CallbackListener press = new CallbackListener() {
  public void controlEvent(CallbackEvent theEvent) {
    Button b = (Button)theEvent.getController();
    if (b.getName().equals("left"))
      jog(true, -1, 0);
    else if (b.getName().equals("right"))
      jog(true, 1, 0);
    else if (b.getName().equals("up"))
      jog(true, 0, -1);
    else if (b.getName().equals("down"))
      jog(true, 0, 1);
  }
};

CallbackListener release = new CallbackListener() {
  public void controlEvent(CallbackEvent theEvent) {
    Button b = (Button)theEvent.getController();
    if (b.getName().equals("left"))
      jog(false, 0, 0);
    else if (b.getName().equals("right"))
      jog(false, 0, 0);
    else if (b.getName().equals("up"))
      jog(false, 0, 0);
    else if (b.getName().equals("down"))
      jog(false, 0, 0);
  }
};

CallbackListener speedrelease = new CallbackListener() {
  public void controlEvent(CallbackEvent theEvent) {
    setSpeed((int)speedSlider.getValue());
  }
};

CallbackListener penrelease = new CallbackListener() {
  public void controlEvent(CallbackEvent theEvent) {
    setPenWidth(penSlider.getValue());
  }
};

public void controlEvent(ControlEvent theEvent) {
  // DropdownList is of type ControlGroup.
  // A controlEvent will be triggered from inside the ControlGroup class.
  // therefore you need to check the originator of the Event with
  // if (theEvent.isGroup())
  // to avoid an error message thrown by controlP5.

  if (theEvent.isGroup()) {
    // check if the Event was triggered from a ControlGroup
    //println("event from group : "+theEvent.getGroup().getValue()+" from "+theEvent.getGroup());
  } else if (theEvent.isController()) {
    //println("event from controller : "+theEvent.getController().getValue()+" from "+theEvent.getController());

    if ((""+theEvent.getController()).indexOf("dropListConnect") >=0)
    {
      Map m = connectDropList.getItem((int)theEvent.getController().getValue());
      println(m.get("name"));
      connect((String)m.get("name"));
    }
  }
}

public void setHome()
{
  sendHome();
  updatePos(homeX, homeY);
}

public void load(ControlEvent theEvent)
{
  Button b = (Button) theEvent.getController();  

  if (b.getCaptionLabel().getText().startsWith("Load"))
  {
    b.setCaptionLabel("Clear");
    ((MyButton)b).setImg(clearImg);
    loadVectorFile();
  } else
  {
    clearSvg();
    clearGcode();
    clearImage();
    send("M84\n");
    b.setCaptionLabel("Load");
    ((MyButton)b).setImg(loadImg);
  }
}

public void plot(ControlEvent theEvent)
{
    Button b = (Button) theEvent.getController(); 
    if (b.getCaptionLabel().getText().indexOf("Step") >= 0)
   {
      if (plotting)
      {
        int index = iindex;
        while(index == iindex)
          plotLine();
        
      } 
      else if (plottingImage)
        plotNextDiamondPixel();

      else if (plottingGcode)
        nextGcode();
   }
   else if (b.getCaptionLabel().getText().indexOf("Abort") >= 0)
    {
       b.setCaptionLabel("Plot");
      ((MyButton)b).setImg(plotImg);
    // oksend("M112\n");
     resetSvg();
     resetImage();
     resetGcode();   
    }
    else
    {  
       if(myPort == null) 
           b.setCaptionLabel("Step");
       else
       {
          b.setCaptionLabel("Abort");
          ((MyButton)b).setImg(pauseImg);
       }
  
    if (sh != null)
      plotSvg();
    else if (gcodeData != null)
      plotGcode();
    else if (oimg != null)
      plotDiamondImage();
  }
}

public void dorotate()
{
  rotation += 90;
  if (rotation >= 360)
    rotation = 0;
  println("do rotate "+rotation);

  rotateSvg(rotation);
  rotateGcode(rotation);
  rotateImg();
}

public void mirrorX()
{
  cncScaleX *= -1;
  updateScale();
  flipImgX();
}
public void mirrorY()
{
  cncScaleY *= -1;
  updateScale();
  flipImgY();
}

public void penUp(ControlEvent theEvent)
{
  Button b = (Button) theEvent.getController();  

  if (b.getCaptionLabel().getText().indexOf("Up") > 0)
  {
    sendPenUp();
    b.setCaptionLabel("Pen Down");
    ((MyButton)b).setImg(penDownImg);
  } else
  {
    sendPenDown();
    b.setCaptionLabel("Pen Up");
    ((MyButton)b).setImg(penUpImg);
  }
}

public void goHome()
{
  send("G90\n");
  sendPenUp();
  send("G0 X"+homeX+" Y"+homeY+"\n");
  updatePos(homeX, homeY);
}

public void off()
{
  send("M84\n");
}

public void save()
{
  saveProperties();
}

public void export()
{
  exportGcode();
}

public void speedChanged(int speed)
{
  int s = (speed/10)*10;    
  if (s != speed)
    speedSlider.setValue(s);
}

public void penWidth(float width)
{
  int w = (int)(width*10);
  float f = ((float)w)/10;   
  if (f != width)
    penSlider.setValue(f);
}

public void pixelSlider(int size)
{
  // int s = (size/2)*2;

  setPixelSize(size);
  // if(s != size)
  //  pixelSizeSlider.setValue(s);
}

public void scale(float scale)
{

  setSvgUserScale(scale);
  setImageScale(scale);
}

public void jog(boolean jog, int x, int y)
{
  if (jog) {  
    send("G91\n");
    stickX = x;
    stickY = y;
  } else
  {
    send("G90\n");
    stickX = 0;
    stickY = 0;
  }
}
ArrayList<PVector> pixels = new ArrayList<PVector>();
ArrayList<PVector> raw = new ArrayList<PVector>();
int dindex = 0;

PImage simage;
PImage oimg;
boolean plottingImage = false;
float imageScale = 0.75f; 
int pixelSize = 8;
int skipColor;
int lastPixel;
int xinc = 1;
int alpha = 255;
float penWidth = 0.5f;
int range = 255/(int)((float)(pixelSize)/penWidth);
int DIR_NE = 1;
int DIR_SE = 2;
int DIR_SW= 3;
int DIR_NW = 4;
int pixelDir = DIR_NE;

int xindex = 0;
int yindex = 0;

public void setPenWidth(float width)
{
  penWidth = width;
  sendPenWidth();

  if (!plottingImage)
  {
    int levels = (int)((float)(pixelSize)/penWidth);
    if (levels < 1) levels = 1;
    if (levels > 255) levels = 255;
    range = 255/levels;
    if (simage != null)
      calculateDiamondPixels(simage, pixelSize);
  }
}
public void clearImage()
{
  oimg = null;
  resetSvg();
}

public void resetImage()
{
    plottingImage = false;
}

public void flipImgX()
{
  if (oimg == null) return;
  int cols = oimg.width;
  int rows = oimg.height;

  oimg.loadPixels();
  PImage rimage = new PImage(cols, rows);
  rimage.loadPixels();

  for (int i=0; i<cols; i++) {
    for (int j=0; j<rows; j++) {
      int ps = i*cols+(cols-1-j);
      int pd = i*cols+j;
      if (pd < rimage.pixels.length && ps < oimg.pixels.length)
        rimage.pixels[pd] = oimg.pixels[ps];
    }
  }
  rimage.updatePixels();
  oimg = rimage;
  cropImage(cropLeft, cropTop, cropRight, cropBottom);
} 

public void flipImgY()
{
  if (oimg == null) return;
  int cols = oimg.width;
  int rows = oimg.height;

  oimg.loadPixels();
  PImage rimage = new PImage(cols, rows);
  rimage.loadPixels();

  for (int i=0; i<cols; i++) {
    for (int j=0; j<rows; j++) {
      int ps = cols*(cols-1-i)+j;
      int pd = i*cols+j;
      if (pd < rimage.pixels.length && ps < oimg.pixels.length)
        rimage.pixels[pd] = oimg.pixels[ps];
    }
  }
  rimage.updatePixels();
  oimg = rimage;
  cropImage(cropLeft, cropTop, cropRight, cropBottom);
}

public void rotateImg()
{
  if (oimg == null) return;
  int cols = oimg.width;
  int rows = oimg.height;

  oimg.loadPixels();
  PImage rimage = new PImage(rows, cols);
  rimage.loadPixels();

  for (int i=0; i<cols; i++) {
    for (int j=0; j<rows; j++) {
      int ps = (rows-1-j)*cols+i;
      int pd = i*rows+j;
      if (pd < rimage.pixels.length && ps < oimg.pixels.length)
        rimage.pixels[pd] = oimg.pixels[ps];
    }
  }
  rimage.updatePixels();
  oimg = rimage;
  cropImage(cropLeft, cropTop, cropRight, cropBottom);
}

public void cropImage(int x1, int y1, int x2, int y2)
{
  if (!plottingImage  && oimg != null)
  { 
    int ox = imageX;
    int oy = imageY;

    int width = oimg.width;
    int height = oimg.height;
    int cropWidth = (x2-x1)*width/imageWidth;
    int cropHeight = (y2-y1)*height/imageHeight;
    simage = new PImage((int)(cropWidth*imageScale), (int)(cropHeight*imageScale));
    simage.copy(oimg, (x1-ox)*width/imageWidth, (y1-oy)*height/imageHeight, cropWidth, cropHeight, 0, 0, simage.width, simage.height);
    simage.loadPixels();
    if (simage != null)
      calculateDiamondPixels(simage, pixelSize);
  }
}
public void setImageScale(float value)
{
  imageScale= value;
  cropImage(cropLeft, cropTop, cropRight, cropBottom);
}

public void setPixelSize(int value)
{

  if (!plottingImage)
  {
    pixelSize = value;//(value/2)*2;
    //pixelLabel.setText("Pixel Size "+pixelSize);
    int levels = (int)((float)(pixelSize)/penWidth);
    if (levels < 1) levels = 1;
    if (levels > 255) levels = 255;
    range = 255/levels;
    if (simage != null)
      calculateDiamondPixels(simage, pixelSize);
  }
}




public void loadImageFile(String fileName)
{
  oimg = loadImage(fileName);

  if (oimg.width > oimg.height)
  {
    imageWidth = 200;
    imageHeight = 200*oimg.height/oimg.width;
  } else
  {
    imageWidth = 200*oimg.width/oimg.height;
    imageHeight = 200;
  }
  cropRight = imageX+imageWidth;
  cropBottom = imageY+imageHeight;
  cropImage(cropLeft, cropTop, cropRight, cropBottom);
}

class ImageFileFilter extends javax.swing.filechooser.FileFilter 
{
  public boolean accept(File file) {
    String filename = file.getName();
    filename.toLowerCase();
    if (file.isDirectory() || filename.endsWith(".png") || filename.endsWith(".jpg") || filename.endsWith(".jpeg")) 
      return true;
    else
      return false;
  }
  public String getDescription() {
    return "Image files (PNG or JPG)";
  }
}

public void plotImage()
{
  plottingImage = true;
  xindex = 0;
  yindex = 0;
  xinc = 1;
  nextPixel();
}

public void nextPixel()
{
  int width = oimg.width;
  int offset = width/2;
  int x = (xindex*pixelSize)+machineWidth/2-offset;
  int y = (yindex*pixelSize)+homeY;
  plotImagePixel(oimg, pixelSize, x, y);
}

public int getBrightness(PImage image, int x, int y, int size)
{
  int width = image.width;
  int height = image.height;
  int totalB = 0;
  int count = 0;
  if (x <0 || x > width-1 || y < 0 || y> height-1) return -1;
  for (int j=0; j<size; j++)
  {
    for (int k = 0; k<size; k++)
    { 
      int p = (y+k)*width+x+j;
      if (p >= 0 && p <image.pixels.length)
      {
        int c = image.pixels[p];
        totalB += brightness(c);
        count++;
      }
    }
  }
  if (count > 0) 
    return totalB/count;
  else
    return 0;
}

public float getCartesianX(float aPos, float bPos)
{
  float calcX = (machineWidth*machineWidth - bPos*bPos + aPos*aPos) / (machineWidth*2);
  return calcX;
}

public float getCartesianY(float cX, float aPos) {
  float calcY = sqrt(aPos*aPos-cX*cX);
  return calcY;
}

public float getMachineA(float cX, float cY)
{
  return sqrt(cX*cX+cY*cY);
}
public float getMachineB(float cX, float cY)
{
  return sqrt(sq((machineWidth-cX))+cY*cY);
}


public void plotDiamondImage()
{

  plottingStarted();
  dindex = 0;
  pixelDir = DIR_NE;
  plotNextDiamondPixel();
}

public int getDir(long targetA, long targetB, long sourceA, long sourceB)
{
  int dir = DIR_SW;

  if (targetA<sourceA && targetB<sourceB)
  {
    dir = DIR_NW;
  } else if (targetA>sourceA && targetB>sourceB)
  {
    dir = DIR_SE;
  } else if (targetA<sourceA && targetB>sourceB)
  {
    dir = DIR_SW;
  } else if (targetA>sourceA && targetB<sourceB)
  {
    dir = DIR_NE;
  } else if (targetA==sourceA && targetB<sourceB)
  {
    dir = DIR_NE;
  } else if (targetA==sourceA && targetB>sourceB)
  {
    dir = DIR_SW;
  } else if (targetA<sourceA && targetB==sourceB)
  {
    dir = DIR_NW;
  } else if (targetA>sourceA && targetB==sourceB)
  {
    dir = DIR_SE;
  }

  return dir;
}

public void plotNextDiamondPixel()
{
  if (dindex < pixels.size()-1) // todo skips last pixel
  {
    float da = 0;
    float db = 0;


    PVector p = pixels.get(dindex);
    PVector r = raw.get(dindex);
    PVector next = raw.get(dindex+1);
    if (dindex == 0)
    {  
      if (next.y - r.y > 0) // todo no check for one pixel row
        pixelDir = DIR_SW;
      else
        pixelDir = DIR_NE;
      sendPenUp();
      send("G0 X"+(p.x+offX)+" Y"+(p.y+offY)+" F"+speedValue+"\n");
      sendPenDown();
      send("M3 X"+da+" Y"+db+" P"+pixelSize+" S"+p.z+" E"+pixelDir+"\n");
    } else
    {
      PVector last = raw.get(dindex-1);
      da = r.x - last.x;
      db = r.y - last.y;
      if (last.x < r.x) // new row
      {

        if (next.y - r.y > 0) //todo no check for one pixel row
          pixelDir = DIR_SW;
        else
          pixelDir = DIR_NE;
      }

      send("M3 X"+da+" Y"+db+" P"+pixelSize+" S"+p.z+" E"+pixelDir+"\n");
      //println(r.x+" "+r.y);
    }

    updatePos(p.x+offX, p.y+offY);
    dindex++;
  } else
  {
    send("M84\n");
    plottingStopped();
  }
}

public void drawDiamonPixel(int i, int a)
{
  PVector r = raw.get(i);
  float tx = getCartesianX(r.x, r.y);
  float ty = getCartesianY(tx, r.x);
  float lx = getCartesianX(r.x, r.y+pixelSize);
  float ly = getCartesianY(lx, r.x);
  float bx = getCartesianX(r.x+pixelSize, r.y+pixelSize);
  float by = getCartesianY(bx, r.x+pixelSize);
  float rx = getCartesianX(r.x+pixelSize, r.y);
  float ry = getCartesianY(rx, r.x+pixelSize);

  fill(color(r.z, r.z, r.z, a));
  stroke(color(r.z, r.z, r.z, a));
  quad(scaleX(tx+offX), scaleY(ty+offY), scaleX(rx+offX), scaleY(ry+offY), scaleX(bx+offX), scaleY(by+offY), scaleX(lx+offX), scaleY(ly+offY));
}

public void drawPlottedPixels()
{
  for (int i = 0; i<dindex; i++)
  {
    drawDiamonPixel(i, 255);
  }
}

public void drawDiamondPixels()
{
  for (int i = 0; i<pixels.size (); i++)
  {
    drawDiamonPixel(i, alpha);
  }
}

public void calculateDiamondPixels(PImage image, int size)
{
  int inc = size;
  float hh = (float)(size)*1.4f/2;
  pixels.clear();
  raw.clear();
  int skipColor = getBrightness(image, size, size, size);
  int lastColor = skipColor;
  boolean draw = false;

  int as = (int)getMachineA(machineWidth/2-image.width/2, homeY);
  int ae = (int)getMachineA(machineWidth/2+image.width/2, homeY+image.height);
  int bss = (int)getMachineB(machineWidth/2+image.width/2, homeY);
  int bee = (int)getMachineB(machineWidth/2-image.width/2, homeY+image.height);

  // make b a multiple of size from a
  int bas = (int)getMachineB(machineWidth/2-image.width/2, homeY);
  while (bas > bss)
  {
    bas -= size;
  }

  bss = bas;

  while (bas < bee)
  {
    bas += size;
  } 
  bee = bas;

  int blen = (bee-bss)/size;
  int bs;

  for (int a=as; a<ae; a+=size)
  {
    if (inc < 0)
    {
      bs = bss;
      inc = size;
    } else
    {
      bs = bee;
      inc = -size;
    }  
    int b = bs;

    for (int i=0; i<blen; i++)
    {
      float cx = getCartesianX(a, b);      
      float cy = getCartesianY(cx, a);

      if (!Float.isNaN(cy))
      {

        int ix = (int) (cx-(machineWidth-image.width)/2);
        int iy = (int)(cy-homeY+hh);
        int d = getBrightness(image, ix, iy, size);
        draw = false;
        if (d >=0)
        {
          if (d!= skipColor)
          {
            draw = true;
          } else if (lastColor != skipColor && skipColor == d)
          {
            draw = true;
          }
        } else
        {
          lastColor = skipColor;
        }
        if (draw)
        {
          lastColor = d;

          int shade = (d/range)*range;

          pixels.add(new PVector(cx, cy, shade)); 
          raw.add(new PVector(a, b, shade));
        }
      }
      b+=inc;
    }
  }
}

public void plotImagePixel(PImage image, int size, int x, int y)
{
  boolean skipped = false;
  int width = image.width;
  int height = image.height; 
  if (yindex >=height/size)
  {
    plottingImage = false;
    return;
  }

  int b = getBrightness(image, xindex*size, yindex*size, size);

  if (xindex == 0 && yindex == 0)
  {
    skipColor = (int)b;
    lastPixel = skipColor;
  }
  if (skipColor != (int)b)
  {
    lastPixel = (int)b;
    send("M2 X"+x+" Y"+y+" P"+size+" S"+(int)b+"\n");
    fill((int)b);
    rect(scaleX(x), scaleY(y), size*zoomScale, size*zoomScale);
  } else if (lastPixel != skipColor && skipColor == (int)b)
  {
    lastPixel = (int)b;
    send("M2 X"+x+" Y"+y+" P"+size+" S"+(int)b+"\n");
    fill((int)b);
    rect(scaleX(x), scaleY(y), size*zoomScale, size*zoomScale);
  } else
  {
    skipped = true;
  }


  xindex+= xinc;
  if (xindex >= width/size)
  {
    xindex = width/size-1;
    xinc = -1;
    yindex++;
    lastPixel = skipColor;
  } else if (xindex <0)
  {
    xindex = 0;
    xinc = 1;
    yindex++;
    lastPixel = skipColor;
  }
  if (skipped)
  {
    nextPixel();
  }
}

public PImage getPixels(PImage image, int size)
{
  int width = image.width;
  int height = image.height;
  PImage output = new PImage(width, height);
  output.copy(image, 0, 0, width, height, 0, 0, width, height);  
  output.loadPixels();

  for (int x = 0; x<width; x+=size)
  {
    for (int y = 0; y<height; y+=size)
    {
      float totalB = 0;
      float count = 0;
      for (int j=0; j<size; j++)
      {
        for (int k = 0; k<size; k++)
        { 
          int p = (y+k)*width+x+j;
          int c = output.pixels[p];
          totalB += brightness(c);
          count++;
        }
      }
      float b = totalB/count;
      for (int j=0; j<size; j++)
      {
        for (int k = 0; k<size; k++)
        { 
          int p = (y+k)*width+x+j;
          output.pixels[p] = color((int)b);
        }
      }
    }
  }
  output.updatePixels();
  return output;
}

public void plottingStarted()
{
  plottingImage = true;
  alpha = 64;
}

public void plottingStopped()
{
  plottingImage = false;
  alpha = 255;
}

RShape sh = null;
RPoint[][] pointPaths;
ArrayList <Path> remainingPaths;
ArrayList<Path> optimizedPaths;

int iindex = -1;
int jindex = -1;
boolean plotting = false;
float svgDpi = 72;
float svgScale = 25.4f/svgDpi;
String svgName = "";
//float svgScale = 100f/283.465f;
float svgUserScale = 1;

public void setSvgUserScale(float value)
{
	svgUserScale = value;
        imageScale = value;
	//svgValue.setText("Scale "+nf(value,0,2));
        updateScale();
}
public void clearSvg()
{
	sh = null;
        optimizedPaths = null;
        resetSvg();

}

public void resetSvg()
{
  plotting = false;
  iindex = -1;
  jindex = -1;
  clearQueue();
}

public void drawPlottedLine()
{
	if(iindex < 0)
	{
		return;
	}
	currentX = 420;
	currentY = 250;
	for(int i = 0;i<optimizedPaths.size();i++)
	{
		for(int j = 0; j<optimizedPaths.get(i).size()-1;j++)
		{
                        if(i > iindex || (i == iindex && j > jindex)) return;
			float x1 = optimizedPaths.get(i).getPoint(j).x*scaleX+machineWidth/2+offX;
			float y1 =  optimizedPaths.get(i).getPoint(j).y*scaleY+homeY+offY;
			float x2 = optimizedPaths.get(i).getPoint(j+1).x*scaleX+machineWidth/2+offX;
			float y2 =  optimizedPaths.get(i).getPoint(j+1).y*scaleY+homeY+offY;


			if(j == 0)
			{
				// pen up

				stroke(0,255,0); //green
				sline(currentX, currentY,x1,y1);
				updatePos(x1,y1);

			}

			stroke(255,0,0); //red
			sline(currentX, currentY,x2,y2);
			updatePos(x2,y2);


			if(i == iindex && j == jindex)
				return;  
		}

	}

}

public void plotLine()
{
	if(iindex < 0)
	{
		plotting = false;
		return;
	}

	if(iindex == 0 && jindex == 0) // first line
	{
		send("G90\n"); // absolute
		send("G0 F"+speedValue+"\n");
	}
	if(iindex < optimizedPaths.size())
	{
		if(jindex< optimizedPaths.get(iindex).size()-1)
		{

			float x1 = optimizedPaths.get(iindex).getPoint(jindex).x*scaleX+machineWidth/2+offX;
			float y1 =  optimizedPaths.get(iindex).getPoint(jindex).y*scaleY+homeY+offY;
			float x2 = optimizedPaths.get(iindex).getPoint(jindex+1).x*scaleX+machineWidth/2+offX;
			float y2 =  optimizedPaths.get(iindex).getPoint(jindex+1).y*scaleY+homeY+offY;


			if(jindex == 0)
			{
				// pen up
				sendPenUp();
				send("G0 X"+x1 +" Y"+y1+"\n");
				//pen Down
				sendPenDown();
			}

			send("G1 X"+x2 +" Y"+y2+"\n");
			jindex++;
		}
		else
		{
			iindex++;
			jindex = 0;
                        plotLine();
		}

	}
	else // finished
	{
                plotting = false;
		float x1 = homeX;
		float y1 = homeY;
                updatePos(x1,y1);
		sendPenUp();
		send("G0 X"+x1 +" Y"+y1+"\n");
		send("M84\n");
		jindex = -1;
		iindex = -1;

	}
}

public void exportSvg(File file)
{
    if(optimizedPaths == null) return;
    BufferedWriter writer = null;
    try{
     writer = new BufferedWriter( new FileWriter( file));

  for(int i = 0;i<optimizedPaths.size();i++)
  {
    Path p = optimizedPaths.get(i);
    if(i == 0)
    {
      writer.write("G21\n"); //mm
      writer.write("G90\n"); // absolute
      writer.write("G0 F"+speedValue+"\n");
    }
    for(int j = 0;j<p.size()-1;j++)
    {

      float x1 = p.getPoint(j).x*scaleX+offX;
      float y1 =  p.getPoint(j).y*scaleY+offY;
      float x2 = p.getPoint(j+1).x*scaleX+offX;
      float y2 =  p.getPoint(j+1).y*scaleY+offY;


      if(j == 0)
      {
        // pen up
        writer.write("G0 Z"+cncSafeHeight+"\n");
        writer.write("G0 X"+nf(x1,0,3) +" Y"+nf(y1,0,3)+"\n");
        //pen Down
        writer.write("G0 Z0\n");
      }

      writer.write("G1 X"+nf(x2,0,3) +" Y"+nf(y2,0,3)+"\n");
    }
  }


  float x1 = 0;
  float y1 = 0;

    writer.write("G0 Z"+cncSafeHeight+"\n");
    writer.write("G0 X"+x1 +" Y"+y1+"\n");

    }catch ( IOException e)
    {
      System.out.print(e);
    }
  finally
{
    try
    {
        if ( writer != null)
        writer.close( );
    }
    catch ( IOException e)
    {
    }
}

}

public void plotSvg()
{
	if(sh != null)
	{
		plotting = true;
		iindex = 0;
		jindex = 0;
		plotLine();
	}
}

public void rotateSvg(int rotation)
{
  if(optimizedPaths == null) return;
  
  for(int i = 0; i<optimizedPaths.size(); i++){
    Path p = optimizedPaths.get(i);
    for(int j = 0; j<p.size(); j++){
      float x = p.getPoint(j).x;
      float y = p.getPoint(j).y;
      
        p.getPoint(j).x = -y;
        p.getPoint(j).y = x;

    }
  }
}

public void drawSvg()
{
        lastX = homeX;
        lastY = homeY;
	strokeWeight(0.1f);
	noFill();
	for(int i = 0; i<optimizedPaths.size(); i++){
		Path p = optimizedPaths.get(i);
    
                stroke(0,255,0);

                sline(lastX*scaleX+homeX+offX,lastY*scaleY+homeY+offY,p.getPoint(0).x*scaleX+homeX+offX,p.getPoint(0).y*scaleY+homeY+offY);
                
                stroke(penColor);
		beginShape();
		for(int j = 0; j<p.size(); j++){
			vertex(scaleX(p.getPoint(j).x*scaleX+homeX+offX), scaleY(p.getPoint(j).y*scaleY+homeY+offY));
		}
		endShape();
                lastX = p.getPoint(p.size()-1).x;
                lastY = p.getPoint(p.size()-1).y;

	}
}


public RShape loadShapeFromFile(String filename) {

	RShape shape = null;
	File file = new File(filename);
	if (file.exists())
	{
		shape = RG.loadShape(filename);
		// shape.centerIn(g, 100, 1, 1);
		pointPaths = shape.getPointsInPaths();
		println("loaded "+filename);
		optimize();
	}
	else
		println("Failed to load file "+filename);

	return shape;
}

public void loadTestFile()
{
	sh = loadShapeFromFile(svgName);
}

public void exportGcode()
{
  SwingUtilities.invokeLater(new Runnable() 
  {
    public void run() {
      JFileChooser fc = new JFileChooser();
      if(svgName != null)
      {
        String name = svgName;
        int dot = svgName.indexOf('.');
        if(dot > 0)
          name = svgName.substring(0,dot)+".gcode";
        fc.setSelectedFile(new File(name));
      }
      fc.setDialogTitle("Export file...");

      int returned = fc.showSaveDialog(frame);
      if (returned == JFileChooser.APPROVE_OPTION) 
      {
        File file = fc.getSelectedFile();
        exportSvg(file);
      }
    }
  });
}

public void loadVectorFile()
{

	SwingUtilities.invokeLater(new Runnable() 
	{
		public void run() {
			JFileChooser fc = new JFileChooser();
			fc.setFileFilter(new VectorFileFilter());
			if(svgName != null)
				fc.setSelectedFile(new File(svgName));
			fc.setDialogTitle("Choose a vector file...");

			int returned = fc.showOpenDialog(frame);
			if (returned == JFileChooser.APPROVE_OPTION) 
			{
				File file = fc.getSelectedFile();
				if(file.getPath().endsWith(".svg"))
					sh = loadShapeFromFile(file.getPath());
				else if(gcodeFile(file.getPath()))
					loadGcode(file.getPath());
				else if(imageFile(file.getPath()))
					loadImageFile(file.getPath());
				svgName = file.getPath();
				
			}


		}
	}
			);
}
public boolean gcodeFile(String filename)
{
	if(filename.endsWith(".gco") || filename.endsWith(".g") ||
			filename.endsWith(".nc") || filename.endsWith(".cnc") ||
			filename.endsWith(".gcode"))
		return true;
	return false;
}
public boolean imageFile(String filename)
{
	if(filename.endsWith(".png") || filename.endsWith(".jpg") ||
			filename.endsWith(".gif") || filename.endsWith(".tga"))
		return true;
	return false;
}
class VectorFileFilter extends javax.swing.filechooser.FileFilter 
{
	public boolean accept(File file) {
		String filename = file.getName();
		filename.toLowerCase();
		if (file.isDirectory() || filename.endsWith(".svg") || gcodeFile(filename) || imageFile(filename)

				)
			return true;
		else
			return false;
	}
	public String getDescription() {
		return "Vector graphic files (SVG, GCode)";
	}
}

public void totalPathLength()
{
    long total = 0;
    for(int i = 0; i<optimizedPaths.size(); i++){
      Path p = optimizedPaths.get(i);
      for(int j = 1; j<p.size(); j++){
        RPoint p1 = p.getPoint(j-1);
        RPoint p2 = p.getPoint(j);
        total += dist(p1.x,p1.y,p2.x,p2.y);
      }
    }
    System.out.println("total Path length "+total);
}
public void optimize()
{
	optimizedPaths = new ArrayList<Path>();
	remainingPaths = new ArrayList<Path>();

	for(int i = 0; i<pointPaths.length; i++){
		if (pointPaths[i] != null) 
		{
			Path path = new Path();

			for(int j =0;j<pointPaths[i].length;j++)
			{
				path.addPoint(pointPaths[i][j].x,pointPaths[i][j].y);
			}
			remainingPaths.add(path);
		}
	}

	println("number of paths "+remainingPaths.size());

	Path path = nearestPath(homeX,homeY);
	optimizedPaths.add(path); 

	int numPaths = remainingPaths.size();
	for(int i = 0;i<numPaths;i++)
	{
		RPoint last = path.last();
		path = nearestPath(last.x,last.y);
		optimizedPaths.add(path); 
	}


          remainingPaths = optimizedPaths;
          optimizedPaths = new ArrayList<Path>();

	  mergePaths(3);
	  println("number of optimized paths "+optimizedPaths.size());

	  println("number of points "+totalPoints(optimizedPaths));  
	  removeShort(1);
	  println("number of opt points "+totalPoints(optimizedPaths));

          totalPathLength();
          
 
}

public void removeShort(float len)
{
	for(int i = 0;i<optimizedPaths.size();i++)
		optimizedPaths.get(i).removeShort(len);
}

public int totalPoints(ArrayList<Path> list)
{
	int total = 0;
	for(int i = 0;i<list.size();i++)
	{
		total += list.get(i).size();
	}
	return total;
}

public void mergePaths(float len)
{

	optimizedPaths.add(remainingPaths.get(0));
	Path cur = optimizedPaths.get(0);

	for(int i = 1;i<remainingPaths.size();i++)
	{
		Path p = remainingPaths.get(i);
		if(dist(cur.last().x, cur.last().y,p.first().x,p.first().y) < len)
		{
			cur.merge(p);
		}
		else
		{
			optimizedPaths.add(p);
			cur = p;
		}
	}
}

public Path nearestPath(float x, float y)
{
  boolean reverse = false;
  float min = Float.MAX_VALUE;
  int index = 0;
  for(int i = 0; i<remainingPaths.size(); i++)     
  {
    Path path = remainingPaths.get(i);
    RPoint first = path.first();
    float sx = first.x;
    float sy = first.y;

    float ds = dist(x,y,sx,sy);
    
    RPoint last = path.last();
    sx = last.x;
    sy = last.y;

    float de =  dist(x,y,sx,sy);
    float d = ds+de;
    if(d < min)
    {
      if(de < ds)
        reverse = true;
      else
        reverse = false;
       min = d;
      index = i;
    }
    
  }

  Path p = remainingPaths.remove(index);
  if(reverse)
    p.reverse();
  return p;
}


public Path oldnearestPath(float x, float y)
{
	boolean reverse = false;
	float min = Float.MAX_VALUE;
	int index = 0;
	for(int i = 0; i<remainingPaths.size(); i++)     
	{
		Path path = remainingPaths.get(i);
		RPoint first = path.first();
		float sx = first.x;
		float sy = first.y;

		float d = dist(x,y,sx,sy);
		if(d < min)
		{
			reverse = false;
			min = d;
			index = i;
		}

		RPoint last = path.last();
		sx = last.x;
		sy = last.y;

		d = dist(x,y,sx,sy);
		if(d < min)
		{
			reverse = true;
			min = d;
			index = i;
		}
	}

	Path p = remainingPaths.remove(index);
	if(reverse)
		p.reverse();
	return p;
}



SortedProperties props = null;
public static String propertiesFilename = "default.properties.txt";

public void saveProperties() {

        if(props == null)
          props = new SortedProperties();
	if(props != null)
	{
		try {
			props.setProperty("machine.motors.maxSpeed",""+speedValue);
			props.setProperty("machine.width",""+machineWidth);
			props.setProperty("machine.height",""+machineHeight);
			props.setProperty("machine.homepoint.y",""+homeY);
			props.setProperty("machine.motors.mmPerRev",""+mmPerRev);
			props.setProperty("machine.motors.stepsPerRev",""+stepsPerRev);

			props.setProperty("machine.penSize",""+penWidth );
			props.setProperty("svg.pixelsPerInch",""+svgDpi);
			props.setProperty("svg.name",svgName);
			props.setProperty("svg.UserScale",""+svgUserScale);

			props.setProperty("image.pixelSize",""+pixelSize);
			props.setProperty("image.scale",""+imageScale);
			
			props.setProperty("com.baudrate",""+baudRate);
			props.setProperty("com.serialPort",""+lastPort);

			props.setProperty("machine.offX",""+offX);
			props.setProperty("machine.offY",""+offY);
			props.setProperty("machine.zoomScale",""+zoomScale);

			props.setProperty("image.cropLeft",""+cropLeft);
			props.setProperty("image.cropRight",""+cropRight);
			props.setProperty("image.cropTop",""+cropTop);
			props.setProperty("image.cropBottom",""+cropBottom);


			String fileToSave = sketchPath(propertiesFilename);
			File f = new File(fileToSave);
			OutputStream out = new FileOutputStream( f );
			props.store(out, "Polar Properties");
			out.close();
			println("Saved Properties "+propertiesFilename);
		}
		catch (Exception e ) {
			e.printStackTrace();
		}
	}
}


public Properties getProperties()
{
	if (props == null)
	{
		FileInputStream propertiesFileStream = null;
		try
		{
			props = new SortedProperties();
			String fileToLoad = sketchPath(propertiesFilename);

                        File propertiesFile = new File(fileToLoad);
                        if (!propertiesFile.exists())
                        {
                            println("saving.");
                            saveProperties();
                            println("saved.");
                        }
                        else
                        {
			  propertiesFileStream = new FileInputStream(propertiesFile);
			  props.load(propertiesFileStream);
			  println("Successfully loaded properties file " + fileToLoad);
		       }
                }
		catch (IOException e)
		{
			println("Couldn't read the properties file - will attempt to create one.");
			println(e.getMessage());
		}
		finally
		{
			try 
			{ 
				propertiesFileStream.close();
			}
			catch (Exception e) 
			{
				println("Exception: "+e.getMessage());
			};
		}
	}
	return props;
}

class SortedProperties extends Properties {
	public Enumeration keys() {
		Enumeration keysEnum = super.keys();
		Vector<String> keyList = new Vector<String>();
		while(keysEnum.hasMoreElements()){
			keyList.add((String)keysEnum.nextElement());
		}
		Collections.sort(keyList);
		return keyList.elements();
	}

}

  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "PenPlotter" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
