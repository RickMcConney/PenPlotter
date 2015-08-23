
import controlP5.*;
import geomerative.*;

import processing.serial.*; //import the Serial library
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

final static String ICON  = "icons/penDown.png";
final static String TITLE = "PenPlotter v0.4";

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

float stepsPerRev = 1600; // number of steps per rev includes microsteps
float mmPerRev = 80;      // mm per rev

float zoomScale = 0.75;   // screen scale controlle with mouse wheel
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

color penColor = color(0, 0, 255);
color pageColor = color(255, 255, 255);
color backgroundColor = color(192, 192, 192);
color gridColor = color(128, 128, 128);
color selectColor = color(0, 255, 0);
color textColor = color(0, 0, 255);
color motorOnColor = color(255, 0, 0);
color motorOffColor = color(0, 0, 255);


private void prepareExitHandler () {

  Runtime.getRuntime().addShutdownHook(new Thread(new Runnable() {

    public void run () {
      println("SHUTDOWN HOOK");
    }
  }
  ));
}

void exit()
{
  println("exit");
  sendMotorOff();
  delay(1000);
  super.exit();
}

void changeAppIcon(PImage img) {
  final PGraphics pg = createGraphics(16, 16, JAVA2D);

  pg.beginDraw();
  pg.image(img, 0, 0, 16, 16);
  pg.endDraw();

  frame.setIconImage(pg.image);

}

void changeAppTitle(String title) {
  //surface.setTitle(title);
  frame.setTitle(title);  
}


void setup() {

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
  
  currentX = homeX;
  currentY = homeY;

  penWidth = Float.parseFloat(props.getProperty("machine.penSize"));

  svgDpi = Float.parseFloat(props.getProperty("svg.pixelsPerInch"));
  svgScale = 25.4f/svgDpi;
 
  currentFileName = props.getProperty("svg.name");
  
  cncSafeHeight = Float.parseFloat(props.getProperty("cnc.safeHeight"));


  baudRate = Long.parseLong(props.getProperty("com.baudrate"));
  //todo lastPort not used

  lastPort = Integer.parseInt(props.getProperty("com.serialPort"));

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

  listPorts();

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

  updateScale();

  handles = new Handle[4];
  handles[0] = new Handle("homeY", 0, homeY, 0, 10, handles, false, true, 128);
  handles[1] = new Handle("mWidth", machineWidth, machineHeight/2, 0, 10, handles, true, false, 64);
  handles[2] = new Handle("mHeight", homeX, machineHeight, 0, 10, handles, false, true, 64);
  handles[3] = new Handle("gondola", (int)currentX, (int)currentY, 0, 10, handles, true, true, 2);
  // handles[4] = new Handle("mmPerRev",0,0,0,10,handles,false,true,64);
  // handles[5] = new Handle("stepsPerRev",machineWidth,0,0,10,handles,false,true,64);
} 

void mouseReleased() { 

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
        
        sendMoveG0(currentX,currentY);
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

void handleMoved(String id, int x, int y)
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

void mousePressed()
{
  startX = mouseX;
  startY = mouseY;
  oldOriginX = originX;
  oldOriginY = originY;
  oldOffX = offX;
  oldOffY = offY;
}

boolean overImage(int x, int y)
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

boolean overCropLeft(int x, int y)
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

boolean overCropRight(int x, int y)
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

boolean overCropTop(int x, int y)
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

boolean overCropBottom(int x, int y)
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
void mouseDragged() 
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

void mouseWheel(MouseEvent event) {

  float e = event.getCount();

  if (e > 0)
    setZoom(zoomScale+=0.1);
  else if(zoomScale > 0.1)
    setZoom(zoomScale-=0.1);
}

void keyPressed() {
  if (key == 'x') {
    flipX *= -1;
    updateScale();
  } else if (key == 'y') {
    flipY *= -1;
    updateScale();
  }
}

void setSpeed(int value)
{
  speedValue = value;
  sendSpeed(speedValue);

}

void setuserScale(float value)
{
  userScale = value;
  updateScale();
  setImageScale();
}

void updateScale()
{
  scaleX = svgScale*userScale*flipX;
  scaleY = svgScale*userScale*flipY;
  
}
float unScaleX(float x)
{
  return (x-originX)/zoomScale+homeX;
}
float unScaleY(float y)
{
  return (y-originY)/zoomScale+homeY;
}
float scaleX(float x)
{
  return (x-homeX)*zoomScale + originX;
}

float scaleY(float y)
{
  return (y-homeY)*zoomScale + originY;
}

void updatePos(float x, float y)
{
  currentX = x;
  currentY = y;
  handles[3].x = x;
  handles[3].y = y;
}

void sline(float x1, float y1, float x2, float y2)
{
  strokeWeight(0.5);
  line(scaleX(x1), scaleY(y1), scaleX(x2), scaleY(y2));
  //updatePos(x2,y2);
}

void setZoom(float value)
{
  zoomScale = value;
}



void draw() {


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
      if(imageMode == PIXEL)
      {
         drawDiamondPixels();
         drawPlottedPixels();
      }
      else if(imageMode == HATCH)
      {
        drawHatch();
        drawPlottedHatch();
      }
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


  if (jogX != 0)
  {

    moveDeltaX(jogX);
    updatePos(currentX += jogX, currentY);
  }
  if (jogY != 0)
  {
    moveDeltaY(jogY);
    updatePos(currentX, currentY += jogY);
  }
}

void drawMenu()
{
  fill(128, 128, 128);
  noStroke();
  rect(0, 0, 120, 545);
}
void drawGondola()
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
void drawPage()
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
  text(status, scaleX(homeX-textWidth(status)/2), scaleY(0)+15);
}

void drawPaper()
{
  noFill();
  stroke(gridColor);
  strokeWeight(0.4);
  float pWidth = 8.5*25.4;
  float pHeight = 11*25.4;
  rect(scaleX(homeX-pWidth/2), scaleY(homeY), pWidth*zoomScale, pHeight*zoomScale);
  rect(scaleX(homeX-pHeight/2), scaleY(homeY), pHeight*zoomScale, pWidth*zoomScale);
  strokeWeight(0.4);
  pWidth = 18*25.4;
  pHeight = 24*25.4;
  rect(scaleX(homeX-pWidth/2), scaleY(homeY), pWidth*zoomScale, pHeight*zoomScale);
}

void drawImageFrame()
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

void drawSelector()
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

void drawOrigin()
{
  noFill();
  stroke(gridColor);
  strokeWeight(0.1);
  line(scaleX(0), scaleY(homeY), scaleX(machineWidth), scaleY(homeY));
  line(scaleX(homeX), scaleY(0), scaleX(homeX), scaleY(machineHeight)); 
}

void drawTicks()
{
  stroke(gridColor);
  strokeWeight(0.1);
  for (int x = 0; x<machineWidth; x+=10)
  {
    line(scaleX(x), scaleY(homeY-5), scaleX(x), scaleY(homeY+5));
  }
  for (int y = 0; y<machineHeight; y+=10)
  {

    line(scaleX(homeX-5), scaleY(y), scaleX(homeX+5), scaleY(y));
  }
}

void drawMachineGrid(int step)
{

  float aLen = (int)getMachineA(machineWidth/2-simage.width/2+offX, homeY+offY);
  float bss = (int)getMachineB(machineWidth/2+simage.width/2+offX, homeY+offY);
  float bLen = (int) getMachineB(machineWidth/2-simage.width/2+offX, homeY+offY);
  while (bLen > bss)
  {
    bLen -= pixelSize;
  } 

  strokeWeight(0.1);
  stroke(0);
  noFill();
  for (int i = 0; i<80; i++)
  {

    arc(scaleX(0), scaleY(0), 2*(aLen+i*step)*zoomScale, 2*(aLen+i*step)*zoomScale, PI/8, PI/3);
    arc(scaleX(machineWidth), scaleY(0), 2*(bLen+i*step)*zoomScale, 2*(bLen+i*step)*zoomScale, PI-PI/3, PI-PI/8);
  }
}
