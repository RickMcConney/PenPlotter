ArrayList<PVector> pixels = new ArrayList<PVector>();
ArrayList<PVector> raw = new ArrayList<PVector>();
int dindex = 0;

PImage simage;
PImage oimg;
boolean plottingImage = false;
float imageScale = 0.75; 
int pixelSize = 8;
int skipColor;
int lastPixel;
int xinc = 1;
int alpha = 255;
float penWidth = 0.5;
int range = 255/(int)((float)(pixelSize)/penWidth);
int DIR_NE = 1;
int DIR_SE = 2;
int DIR_SW= 3;
int DIR_NW = 4;
int pixelDir = DIR_NE;

int xindex = 0;
int yindex = 0;

void setPenWidth(float width)
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
void clearImage()
{
  oimg = null;
  plottingImage = false;
}

void rotateImg()
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

void cropImage(int x1, int y1, int x2, int y2)
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
void setImageScale(float value)
{
  imageScale= value;
  cropImage(cropLeft, cropTop, cropRight, cropBottom);
}

void setPixelSize(int value)
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




void loadImageFile(String fileName)
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

void plotImage()
{
  plottingImage = true;
  xindex = 0;
  yindex = 0;
  xinc = 1;
  nextPixel();
}

void nextPixel()
{
  int width = oimg.width;
  int offset = width/2;
  int x = (xindex*pixelSize)+machineWidth/2-offset;
  int y = (yindex*pixelSize)+homeY;
  plotImagePixel(oimg, pixelSize, x, y);
}

int getBrightness(PImage image, int x, int y, int size)
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
        color c = image.pixels[p];
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

float getCartesianX(float aPos, float bPos)
{
  float calcX = (machineWidth*machineWidth - bPos*bPos + aPos*aPos) / (machineWidth*2);
  return calcX;
}

float getCartesianY(float cX, float aPos) {
  float calcY = sqrt(aPos*aPos-cX*cX);
  return calcY;
}

float getMachineA(float cX, float cY)
{
  return sqrt(cX*cX+cY*cY);
}
float getMachineB(float cX, float cY)
{
  return sqrt(sq((machineWidth-cX))+cY*cY);
}


void plotDiamondImage()
{

  plottingStarted();
  dindex = 0;
  pixelDir = DIR_NE;
  plotNextDiamondPixel();
}

int getDir(long targetA, long targetB, long sourceA, long sourceB)
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

void plotNextDiamondPixel()
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

void drawDiamonPixel(int i, int a)
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

void drawPlottedPixels()
{
  for (int i = 0; i<dindex; i++)
  {
    drawDiamonPixel(i, 255);
  }
}

void drawDiamondPixels()
{
  for (int i = 0; i<pixels.size (); i++)
  {
    drawDiamonPixel(i, alpha);
  }
}

void calculateDiamondPixels(PImage image, int size)
{
  int inc = size;
  float hh = (float)(size)*1.4/2;
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

void plotImagePixel(PImage image, int size, int x, int y)
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

PImage getPixels(PImage image, int size)
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
          color c = output.pixels[p];
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

void plottingStarted()
{
  plottingImage = true;
  alpha = 64;
}

void plottingStopped()
{
  plottingImage = false;
  alpha = 255;
}

