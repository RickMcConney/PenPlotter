ArrayList<PVector> pixels = new ArrayList<PVector>();
ArrayList<PVector> raw = new ArrayList<PVector>();
ArrayList<Path> hatchPaths;
int dindex = 0;

PImage simage;
PImage oimg;
boolean plottingImage = false;
boolean plottingHatch = false;

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
int HATCH = 0;
int PIXEL = 1;
int imageMode = HATCH;

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
      calculateImage();
  }
}
void clearImage()
{
  oimg = null;
  simage = null;
  hatchPaths = null;
  
  resetImage();
}

void resetImage()
{
    plottingImage = false;
    plottingHatch = false;
    xindex = 0;
    yindex = 0;
    dindex = 0;
    plotDone();
}

void flipImgX()
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

void flipImgY()
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
    simage = new PImage((int)(cropWidth*userScale), (int)(cropHeight*userScale));
    simage.copy(oimg, (x1-ox)*width/imageWidth, (y1-oy)*height/imageHeight, cropWidth, cropHeight, 0, 0, simage.width, simage.height);
    simage.loadPixels();
    if (simage != null)
      calculateImage();
  }
}
void setImageScale()
{
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
    {
      calculateImage();
    }
  }
}

void calculateImage()
{
  if(imageMode == PIXEL)
    calculateDiamondPixels(simage, pixelSize);
  else if(imageMode == HATCH)
    hatch(simage);
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
      sendMoveG0((p.x+offX),(p.y+offY));
      sendPenDown();
      sendPixel(da,db,pixelSize,(int)p.z,pixelDir);

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
      sendPixel(da,db,pixelSize,(int)p.z,pixelDir);

    }

    updatePos(p.x+offX, p.y+offY);
    dindex++;
  } else
  {
    sendMotorOff();
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

void plotHatch()
{
  dindex = 0;
  plottingHatch = true;
  plotNextHatch();
  alpha = 64;
}

void plotNextHatch()
{
  if(dindex <hatchPaths.size())
  {
    Path  p = hatchPaths.get(dindex);
    sendPenUp();
    sendMoveG0(p.first().x*userScale+homeX+offX,p.first().y*userScale+homeY+offY);
    sendPenDown();
    sendMoveG1(p.last().x*userScale+homeX+offX,p.last().y*userScale+homeY+offY);
    updatePos(p.last().x*userScale+homeX+offX, p.last().y*userScale+homeY+offY);
    dindex++;
  }
  else
  {
    plotDone();
    alpha = 255;
    plottingHatch = false;
  }
}

void exportHatch(File file)
{
  if (hatchPaths == null) return;
  Path p;
  BufferedWriter writer = null;
  try {
    writer = new BufferedWriter( new FileWriter( file));

   for(int i =0;i<hatchPaths.size();i++)
   {
      p = hatchPaths.get(i);

      if (i == 0)
      {
        writer.write("G21\n"); //mm
        writer.write("G90\n"); // absolute
        writer.write("G0 F"+speedValue+"\n");
      }
      for (int j = 0; j<p.size ()-1; j++)
      {

        float x1 = p.getPoint(j).x*userScale+offX;
        float y1 =  p.getPoint(j).y*userScale+offY;
        float x2 = p.getPoint(j+1).x*userScale+offX;
        float y2 =  p.getPoint(j+1).y*userScale+offY;


        if (j == 0)
        {
          // pen up
          writer.write("G0 Z"+cncSafeHeight+"\n");
          writer.write("G0 X"+nf(x1, 0, 3) +" Y"+nf(y1, 0, 3)+"\n");
          //pen Down
          writer.write("G0 Z0\n");
        }

        writer.write("G1 X"+nf(x2, 0, 3) +" Y"+nf(y2, 0, 3)+"\n");
      }
    }


    float x1 = 0;
    float y1 = 0;

    writer.write("G0 Z"+cncSafeHeight+"\n");
    writer.write("G0 X"+x1 +" Y"+y1+"\n");
  }
  catch ( IOException e)
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

  
void drawPlottedHatch()
{
    if(hatchPaths == null) return;
  Path p;
  stroke(color(0, 0, 0, 255));
  for(int i =0;i<dindex;i++)
  {
    if(dindex < hatchPaths.size())
    {
      p = hatchPaths.get(i);
      sline(p.first().x*userScale+homeX+offX,p.first().y*userScale+homeY+offY,p.last().x*userScale+homeX+offX,p.last().y*userScale+homeY+offY);
    }
  }
}
void drawHatch()
{
  if(hatchPaths == null) return;
  Path p;
  stroke(color(0, 0, 0, alpha));
  for(int i =0;i<hatchPaths.size();i++)
  {
    p = hatchPaths.get(i);

    sline(p.first().x*userScale+homeX+offX,p.first().y*userScale+homeY+offY,p.last().x*userScale+homeX+offX,p.last().y*userScale+homeY+offY);
  }
}



boolean addPaths(ArrayList<Path> paths,boolean reverse)
{
  if(paths.size() > 0)
  {
      if(reverse)
      {
          for(int i = paths.size()-1;i>=0;i--)
          {
            paths.get(i).reverse();
            hatchPaths.add(paths.get(i));
          }
      }
      else
      {
          for(int i = 0;i<paths.size();i++)
            hatchPaths.add(paths.get(i));
      }
      return !reverse;
  }
  return reverse;
}

ArrayList<Path> findPaths(PImage image,int start,int len,int step,int threshold)
{
  boolean up = true;
  color c;
  int x;
  int y;
  Path path = null;
  ArrayList<Path> paths = new ArrayList<Path>(); 
  int p = start;
  for(int i = 0;i<len;i++)
  {
    if(p >= image.pixels.length) return paths;
     c = image.pixels[p];
     if(up && brightness(c) < threshold)
     {
         path = new Path();
         x = p%image.width;
         y = p/image.width;
         path.addPoint(x,y);
         up = false;
     }
     else if(!up && brightness(c) > threshold)
     {
         x = p%image.width;
         y = p/image.width;
         path.addPoint(x,y);
         paths.add(path);          
         up = true;           
     } 
     p+=step;  
        
  }
  return paths;
}

public void  hatch(PImage image)
{
  int size = pixelSize;
  hatchPaths = new  ArrayList<Path>();
  ArrayList<Path> paths = new  ArrayList<Path>();
  Path path=null;
  int threshold;

  threshold = (int)t1Slider.getValue(); 
  //diag down right
  
  boolean reverse = false;

  for(int x = image.width-1;x>=0;x-=size)
  {      
     paths = findPaths(image,x,image.width-1-x,image.width+1,threshold);      
     reverse = addPaths(paths,reverse);

  }
  

  for(int y = 0; y < image.height;y+=size)
  {

     if(image.height <= image.width)
       paths = findPaths(image,y*image.width,image.height-1-y,image.width+1,threshold);
     else
     {
       if(y >= image.width)
          paths = findPaths(image,y*image.width,image.height-1-y,image.width+1,threshold);
       else
         paths = findPaths(image,y*image.width,image.width,image.width+1,threshold);
     }
     reverse = addPaths(paths,reverse);    
  }
  
  
  // diag down left
  threshold = (int)t2Slider.getValue(); 

  for(int x = 0;x<image.width;x+=size)
  {      
     paths = findPaths(image,x,x,image.width-1,threshold);      
     reverse = addPaths(paths,reverse);

  }
  

  for(int y = 1; y < image.height;y+=size)
  {
    
     if(image.height <= image.width)
       paths = findPaths(image,y*image.width-1,image.height-1-y,image.width-1,threshold);
     else
     {
      if(y >= image.width)
          paths = findPaths(image,y*image.width-1,image.height-1-y,image.width-1,threshold);
       else
         paths = findPaths(image,y*image.width-1,image.width,image.width-1,threshold);
     }
     reverse = addPaths(paths,reverse); 
     
  }

  // vertical
  threshold = (int)t3Slider.getValue();

  for(int x = 0;x<image.width;x+=size)
  {
     paths = findPaths(image,x,image.height,image.width,threshold);      
     reverse = addPaths(paths,reverse);
  }
  
  // horizontal
  threshold = (int)t4Slider.getValue();

  for(int y = 0;y<image.height;y+=size)
  {
     paths = findPaths(image,y*image.width,image.width,1,threshold);      
     reverse = addPaths(paths,reverse); 
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
    plotDone();
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
    sendSqPixel(x,y,size,(int)b);
    fill((int)b);
    rect(scaleX(x), scaleY(y), size*zoomScale, size*zoomScale);
  } else if (lastPixel != skipColor && skipColor == (int)b)
  {
    lastPixel = (int)b;
    sendSqPixel(x,y,size,(int)b);
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
  plotDone();
  alpha = 255;
}

