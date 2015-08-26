ArrayList<PVector> pixels = new ArrayList<PVector>();
ArrayList<PVector> raw = new ArrayList<PVector>();
ArrayList<Path> hatchPaths;
PGraphics hatchImage = null;
int dindex = 0;

PImage simage;
PImage oimg;
PImage sqImage;

boolean plottingImage = false;
boolean plottingHatch = false;
boolean plottingSquare = false;
boolean plottingDiamond = false;

int pixelSize = 8;
int skipColor;
int lastPixel;

int alpha = 255;
float penWidth = 0.5;
int range = 255/(int)((float)(pixelSize)/penWidth);
int DIR_NE = 1;
int DIR_SE = 2;
int DIR_SW= 3;
int DIR_NW = 4;
int pixelDir = DIR_NE;


int HATCH = 0;
int DIAMOND = 1;
int SQUARE = 2;
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
  pixels.clear();
  raw.clear();
  
  resetImage();
}

void resetImage()
{
    plottingImage = false;
    plottingHatch = false;
    plottingDiamond = false;
    plottingSquare = false;
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

  for (int x=0; x<cols; x++) {
    for (int y=0; y<rows; y++) {
      int ps = y*cols+(cols-1-x);
      int pd = y*cols+x;
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

  for (int x=0; x<cols; x++) {
    for (int y=0; y<rows; y++) {
      int ps = cols*(rows-1-y)+x;
      int pd = y*cols+x;
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
    {
     // hatchImage = createGraphics(simage.width,simage.height);
      calculateImage();
    }
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
    pixelSize = value;

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


void plotImage()
{
  plottingImage = true;

  if(imageMode == DIAMOND)
    plotDiamondImage();
  else if(imageMode == HATCH)
    plotHatch();
  else if(imageMode == SQUARE)
    plotSquareImage();
  else if(imageMode == STIPPLE)
    plotStipples();
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

int getHue(PImage image, int x, int y, int size)
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
        totalB += hue(c);
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

void plotHatch()
{
  dindex = 0;
  plottingHatch = true;
  plottingStarted();
  plotNextHatch();
}

void plotSquareImage()
{
  dindex = 0; 
  plottingSquare = true;
  plottingStarted();
  plotNextSquarePixel();
}

void plotDiamondImage()
{
  dindex = 0;
  plottingDiamond = true;
  plottingStarted();
  pixelDir = DIR_NE;
  plotNextDiamondPixel();
}

void plotNextSquarePixel()
{
  if (dindex < pixels.size()) 
  {
      PVector p = pixels.get(dindex);  
      if (dindex == 0)
      {  
        sendPenUp();
        sendMoveG0((p.x+offX),(p.y+offY));
        sendPenDown();
        sendSqPixel((p.x+offX),(p.y+offY),pixelSize,(int)p.z);
      }
      else
      {
         sendSqPixel((p.x+offX),(p.y+offY),pixelSize,(int)p.z);
      }
      dindex++;
  }
  else
  {
    sendMotorOff();
    plottingStopped();
  }
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

void drawSquarePixel(int i,int a)
{
  if(i < pixels.size())
  {
    PVector r = pixels.get(i);

    fill(color(r.z, r.z, r.z, a));
    stroke(color(r.z, r.z, r.z, a));
    rect(scaleX(r.x+offX),scaleY(r.y+offY),pixelSize*zoomScale,pixelSize*zoomScale);
  }
}

void drawSquarePixels()
{
  for(int i = 0;i<pixels.size();i++)
  {
    if(i < dindex)
      drawSquarePixel(i,255);
    else
      drawSquarePixel(i,alpha);
  }
}


void drawDiamonPixel(int i, int a)
{
    if(i < pixels.size())
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
}


void drawDiamondPixels()
{
  for (int i = 0; i<pixels.size (); i++)
  {
    if(i < dindex)
      drawDiamonPixel(i, 255);
    else
      drawDiamonPixel(i, alpha);
  }
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

    dindex++;
  }
  else
  {
    plotDone();
    alpha = 255;
    plottingHatch = false;
  }
  drawHatchImage();
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
void drawHatch()
{
  if(hatchImage != null)
    image(hatchImage,scaleX(offX+homeX-simage.width/2),scaleY(offY+homeY),hatchImage.width*zoomScale, hatchImage.height*zoomScale);
}
void newdrawHatch()
{
  if(hatchPaths == null) return;
  Path p;

  strokeWeight(0.1);
  
  stroke(color(0, 0, 0, 255));  
  beginShape(LINES);
  for(int i =0;i<dindex;i++)
  {
        p = hatchPaths.get(i);
        vertex(scaleX(p.first().x*userScale+homeX+offX), scaleY(p.first().y*userScale+homeY+offY));
        vertex(scaleX(p.last().x*userScale+homeX+offX), scaleY(p.last().y*userScale+homeY+offY));
  }
  endShape();
  
  stroke(color(0, 0, 0, alpha));
  beginShape(LINES);
  for(int i = dindex;i<hatchPaths.size();i++)
  {
        p = hatchPaths.get(i);
        vertex(scaleX(p.first().x*userScale+homeX+offX), scaleY(p.first().y*userScale+homeY+offY));
        vertex(scaleX(p.last().x*userScale+homeX+offX), scaleY(p.last().y*userScale+homeY+offY));
  }
  endShape();
}

void drawHatchImage()
{

  if(hatchPaths == null) return;

  Path p;

  hatchImage.beginDraw();
  hatchImage.clear();
  hatchImage.strokeWeight(0.1);
  
   hatchImage.stroke(color(0, 0, 0, 255));  
   hatchImage.beginShape(LINES);
  for(int i =0;i<dindex;i++)
  {
        p = hatchPaths.get(i);
         //hatchImage.vertex(scaleX(p.first().x*userScale+homeX), scaleY(p.first().y*userScale+homeY));
        // hatchImage.vertex(scaleX(p.last().x*userScale+homeX), scaleY(p.last().y*userScale+homeY));
    hatchImage.vertex(p.first().x*userScale, p.first().y*userScale);
    hatchImage.vertex(p.last().x*userScale, p.last().y*userScale);
       
  }
   hatchImage.endShape();
  
   hatchImage.stroke(color(0, 0, 0, alpha));
   hatchImage.beginShape(LINES);
  for(int i = dindex;i<hatchPaths.size();i++)
  {
        p = hatchPaths.get(i);
         hatchImage.vertex(p.first().x*userScale, p.first().y*userScale);
         hatchImage.vertex(p.last().x*userScale, p.last().y*userScale);
  }
   hatchImage.endShape();
   hatchImage.endDraw();
}


void olddrawHatch()
{
  if(hatchPaths == null) return;
  Path p;

  for(int i =0;i<hatchPaths.size();i++)
  {
    p = hatchPaths.get(i);
    if(i < dindex)
        stroke(color(0, 0, 0, 255));
     else
       stroke(color(0, 0, 0, alpha));
       
     sline(p.first().x*userScale+homeX+offX,p.first().y*userScale+homeY+offY,p.last().x*userScale+homeX+offX,p.last().y*userScale+homeY+offY);
   
  }
}




void calculateImage()
{
  plottingStopped();
  if(imageMode == DIAMOND)
    calculateDiamondPixels(simage, pixelSize);
  else if(imageMode == HATCH)
    calculateHatch(simage);
  else if(imageMode == SQUARE)
    calculateSquarePixels(simage,pixelSize);  
  else if(imageMode == STIPPLE)
    calculateStippleImage(); 
}

public void  calculateHatch(PImage image)
{
  int size = pixelSize;
  hatchPaths = new  ArrayList<Path>();
  ArrayList<Path> paths = new  ArrayList<Path>();

  int threshold;

  threshold = (int)t1Slider.getValue(); 
  //diag down right
  
  boolean reverse = false;

  for(int x = ((image.width-1)/size)*size;x>=0;x-=size)
  {     
     if(image.height >= image.width) 
     { 
         paths = findPaths(image,x,image.width-1-x,image.width+1,threshold);  
     }
     else
     {
         if(x >= image.width-image.height)
             paths = findPaths(image,x,image.width-1-x,image.width+1,threshold);  
          else
             paths = findPaths(image,x,image.height-1,image.width+1,threshold);  
          
     }    
     reverse = addPaths(paths,reverse);

  }
  

  for(int y = size; y < image.height;y+=size)
  {

     if(image.height <= image.width)
     {
         paths = findPaths(image,y*image.width,image.height-1-y,image.width+1,threshold);
     }
     else
     {
       if(y >= image.height-image.width)
          paths = findPaths(image,y*image.width,image.height-1-y,image.width+1,threshold);
       else
         paths = findPaths(image,y*image.width,image.width-1,image.width+1,threshold);
     }
     reverse = addPaths(paths,reverse);    
  }
  

  // diag down left
  threshold = (int)t2Slider.getValue(); 

  for(int x = 0;x<image.width;x+=size)
  {    
      if(image.height >= image.width) 
      { 
         paths = findPaths(image,x,x,image.width-1,threshold);      
      }
      else
      {
        if(x >= image.width-image.height)
        {
           paths = findPaths(image,x,image.height-1,image.width-1,threshold); 
        }
        else
        {
           paths = findPaths(image,x,image.height-1-x,image.width-1,threshold); 
        }
      }
      reverse = addPaths(paths,reverse);
  }
  

  for(int y = size; y < image.height;y+=size)
  {    
     if(image.height <= image.width)
     { 
           paths = findPaths(image,y*image.width-1,image.height-1-y,image.width-1,threshold);       
     }
     else
     {
      if(y >= image.height-image.width)
          paths = findPaths(image,y*image.width-1,image.height-1-y,image.width-1,threshold);
       else
         paths = findPaths(image,y*image.width-1,image.width-1,image.width-1,threshold);
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
     paths = findPaths(image,y*image.width,image.width-1,1,threshold);      
     reverse = addPaths(paths,reverse); 
  }

  drawHatchImage();
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
  if(!up)
  {
    x = p%image.width;
    y = p/image.width;
    path.addPoint(x,y);
    paths.add(path); 
  }
  return paths;
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

  int as = (int)getMachineA(homeX-image.width/2, homeY);
  int ae = (int)getMachineA(homeX+image.width/2, homeY+image.height);
  int bss = (int)getMachineB(homeX+image.width/2, homeY);
  int bee = (int)getMachineB(homeX-image.width/2, homeY+image.height);

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

void  calculateSquarePixels(PImage image, int size)
{
  int width = image.width;
  int height = image.height;
  int d;
  int shade;
  pixels.clear();
  
  int sx = homeX-image.width/2;
  int sy = homeY;
  boolean reverse = true;
  int skipColor = getBrightness(image, 0, 0, size);
  int skipHue = getHue(image,0,0,size);
  int hue;
  
  for (int y = 0; y<height; y+=size)
  {
    reverse = !reverse;
    if(!reverse)
    {
      for (int x = 0; x<width; x+=size)
      {
        d = getBrightness(image, x, y, size);
        hue = getHue(image,x,y,size);

        if(hue != skipHue || d != skipColor)
        {
          shade = (d/range)*range;
          pixels.add(new PVector(sx+x, sy+y, shade)); 
        }
      }
    }
    else
    {
      for (int x = ((width-1)/size)*size; x>=0; x-=size)
      {
        d = getBrightness(image, x, y, size);
        hue = getHue(image,x,y,size);
        if(hue!= skipHue || d != skipColor)
        {
          shade = (d/range)*range;
          pixels.add(new PVector(sx+x, sy+y, shade)); 
        }
      }
    }
  }
}

void plottingStarted()
{
  plottingImage = true;
  alpha = 64;
}

void plottingStopped()
{
  dindex = 0;
  plottingHatch = false;
  plottingImage = false;
  plottingDiamond = false;
  plottingSquare = false;
  plotDone();
  alpha = 255;
  goHome();
}
