// Feel free to play with these three default settings:
int STIPPLE = 3;
ToxiclibsSupport gfx;
int maxParticles = 2000;   // Max value is normally 10000.  Press 'x' key to allow 50000 stipples. (SLOW)
float MinDotSize = 1.75; //2;
float DotSizeFactor = 4;  //5;
float cutoff =  0;  // White cutoff value


int cellBuffer = 100;  //Scale each cell to fit in a cellBuffer-sized square window for computing the centroid.


// Display window and GUI area sizes:
int mainwidth; 
int mainheight;
int borderWidth;


float lowBorderX;
float hiBorderX;
float lowBorderY;
float hiBorderY;


float MaxDotSize;
boolean ReInitiallizeArray; 
boolean pausemode;
boolean fileLoaded;
int SaveNow;
String savePath;
String[] FileOutput; 




String StatusDisplay = "Initializing, please wait. :)";
float millisLastFrame = 0;
float frameTime = 0;

String ErrorDisplay = "";
float ErrorTime;
Boolean ErrorDisp = false;


int Generation; 
int particleRouteLength;
int RouteStep; 

boolean showBG;
boolean showPath;
boolean showCells; 
boolean invertImg;
boolean TempShowCells;
boolean FileModeTSP;

int vorPointsAdded;
boolean VoronoiCalculated;

// Toxic libs library setup:
Voronoi voronoi; 
Polygon2D RegionList[];

PolygonClipper2D clip;  // polygon clipper

int cellsTotal, cellsCalculated, cellsCalculatedLast;


// ControlP5 GUI library variables setup
Textlabel  ProgName; 
Button  OrderOnOff, ImgOnOff, CellOnOff, InvertOnOff, PauseButton;

PImage img, imgload, imgblur; 

Vec2D[] particles;
int[] particleRoute;


Slider stipplesSlider;   
Slider minDotSlider; 
Slider dotRangeSlider;
Slider whiteSlider;
boolean plottingStipple = false;

void LoadImageAndScale() {

  int tempx = 0;
  int tempy = 0;
  


  
  img = createImage(mainwidth, mainheight, RGB);
  imgblur = createImage(mainwidth, mainheight, RGB);

  img.loadPixels();

  if (invertImg)
    for (int i = 0; i < img.pixels.length; i++) {
      img.pixels[i] = color(0);
    }
  else
    for (int i = 0; i < img.pixels.length; i++) {
      img.pixels[i] = color(255);
    }

  img.updatePixels();


   if(simage == null) return;
  
  mainwidth = simage.width;
  mainheight = simage.height;
  lowBorderX =  borderWidth; //mainwidth*0.01; 
  hiBorderX = mainwidth - borderWidth; //mainwidth*0.98;
  lowBorderY = borderWidth; // mainheight*0.01;
  hiBorderY = mainheight - borderWidth;  //mainheight*0.98;

  int innerWidth = mainwidth - 2  * borderWidth;
  int innerHeight = mainheight - 2  * borderWidth;

  clip=new SutherlandHodgemanClipper(new Rect(lowBorderX, lowBorderY, innerWidth, innerHeight)); 
  
  img = createImage(mainwidth, mainheight, RGB);
  imgblur = createImage(mainwidth, mainheight, RGB);

  img.loadPixels();

  if (invertImg)
    for (int i = 0; i < img.pixels.length; i++) {
      img.pixels[i] = color(0);
    }
  else
    for (int i = 0; i < img.pixels.length; i++) {
      img.pixels[i] = color(255);
    }

  img.updatePixels();
  
  
  imgload = simage;

  if ((imgload.width > mainwidth) || (imgload.height > mainheight)) {

    if (((float) imgload.width / (float)imgload.height) > ((float) mainwidth / (float) mainheight))
    { 
      imgload.resize(mainwidth, 0);
    }
    else
    { 
      imgload.resize(0, mainheight);
    }
  } 

  if  (imgload.height < (mainheight - 2) ) { 
    tempy = (int) (( mainheight - imgload.height ) / 2) ;
  }
  if (imgload.width < (mainwidth - 2)) {
    tempx = (int) (( mainwidth - imgload.width ) / 2) ;
  }

  img.copy(imgload, 0, 0, imgload.width, imgload.height, tempx, tempy, imgload.width, imgload.height);



  imgblur.copy(img, 0, 0, img.width, img.height, 0, 0, img.width, img.height);
  // This is a duplicate of the background image, that we will apply a blur to,
  // to reduce "high frequency" noise artifacts.

  imgblur.filter(BLUR, 1);  // Low-level blur filter to elminate pixel-to-pixel noise artifacts.
  imgblur.loadPixels();
}


void MainArraysetup() { 
  // Main particle array initialization (to be called whenever necessary):

  LoadImageAndScale();

  // image(img, 0, 0); // SHOW BG IMG

  particles = new Vec2D[maxParticles];


  // Fill array by "rejection sampling"
  int  i = 0;
  while (i < maxParticles)
  {

    float fx = lowBorderX +  random(hiBorderX - lowBorderX);
    float fy = lowBorderY +  random(hiBorderY - lowBorderY);

    float p = brightness(imgblur.pixels[ floor(fy)*imgblur.width + floor(fx) ])/255; 
    // OK to use simple floor_ rounding here, because  this is a one-time operation,
    // creating the initial distribution that will be iterated.

    if (invertImg)
    {
      p =  1 - p;
    }

    if (random(1) >= p ) {  
      Vec2D p1 = new Vec2D(fx, fy);
      particles[i] = p1;  
      i++;
    }
  } 

  particleRouteLength = 0;
  Generation = 0; 
  millisLastFrame = millis();
  RouteStep = 0; 
  VoronoiCalculated = false;
  cellsCalculated = 0;
  vorPointsAdded = 0;
  voronoi = new Voronoi();  // Erase mesh
  TempShowCells = true;
  FileModeTSP = false;
} 

public Slider addSlider(String name,String label,
                        float min,
                        float max,
                        float value,
                        int x,
                        int y
                        )
{
  Slider s = cp5.addSlider(name)                       
    .setCaptionLabel(label)
      .setPosition(x, y)
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

MyButton addMButton(String name, String label, int x, int y)
{

  MyButton b = new MyButton(cp5, name);
  b.setPosition(x, y)
    .setSize(menuWidth, 30)
      .setCaptionLabel(label)
        .setView(new myView())
          ;

  b.getCaptionLabel().setFont(createFont("", 10));
  return b;
}

void stippleSetup()
{

  borderWidth = 6;

  mainwidth = 200;
  mainheight = 200;

  gfx = new ToxiclibsSupport(this);

  MainArraysetup();   // Main particle array setup

  int leftcolumwidth = 225;

  int left= imageX+20;
  int top = imageY+imageHeight+60;
  int locY = top;

  stipplesSlider = addSlider("Stipples","Stipples", 10, 10000, maxParticles, left,locY+=ySpace/2);    

  InvertOnOff = addMButton("INVERT_IMG","Black", left,locY+=ySpace);

  minDotSlider = addSlider("Min_Dot_Size","Min Dot Size", .5, 8, MinDotSize, left,locY+=ySpace); 

  dotRangeSlider = addSlider("Dot_Size_Range","Dot Size Range", 0, 20, DotSizeFactor, left, locY+=ySpace/2);  

  whiteSlider = addSlider("White_Cutoff","White Cutoff", 0, 1, cutoff, left, locY+=ySpace/2); 


  CellOnOff = addMButton("CELLS_ON_OFF", "Hide Cells", left, locY+=ySpace);

  PauseButton = addMButton("Pause", "Pause",left,locY+=ySpace);

  OrderOnOff = addMButton("ORDER_ON_OFF", "Hide Paths",left,locY+=ySpace);


  MaxDotSize = MinDotSize * (1 + DotSizeFactor);

  ReInitiallizeArray = false;
  pausemode = false;
  showBG  = false;
  invertImg  = false;
  showPath = true;
  showCells = false;
  fileLoaded = false;
  SaveNow = 0;
  hideStippleControls();
}

void showStippleControls()
{
  stipplesSlider.setVisible(true);    
  InvertOnOff.setVisible(true); 
  minDotSlider.setVisible(true); 
  dotRangeSlider.setVisible(true); 
  whiteSlider.setVisible(true); 
  CellOnOff.setVisible(true); 
  PauseButton.setVisible(true); 
  OrderOnOff.setVisible(true);
 
}

void hideStippleControls()
{
  
  stipplesSlider.setVisible(false);    
  InvertOnOff.setVisible(false); 
  minDotSlider.setVisible(false); 
  dotRangeSlider.setVisible(false); 
  whiteSlider.setVisible(false); 
  CellOnOff.setVisible(false); 
  PauseButton.setVisible(false); 
  OrderOnOff.setVisible(false);  
  
}

void calculateStippleImage()
{
      ReInitiallizeArray = true;
}

void SAVE_PATH(float theValue) {  
  FileModeTSP = true;
  SAVE_SVG(0);
}



void SAVE_STIPPLES(float theValue) {  
  FileModeTSP = false;
  SAVE_SVG(0);
}






void SAVE_SVG(float theValue) {  



  if (pausemode != true) {
    Pause(0.0);
    ErrorDisplay = "Error: PAUSE before saving.";
    ErrorTime = millis();
    ErrorDisp = true;
  }
  else {
    savePath = "save.svg";
//    savePath = selectOutput("Output .svg file name:");  // Opens file chooser
    if (savePath == null) {
      // If a file was not selected
      println("No output file was selected...");
      ErrorDisplay = "ERROR: NO FILE NAME CHOSEN.";
      ErrorTime = millis();
      ErrorDisp = true;
    } 
    else { 

      String[] p = splitTokens(savePath, ".");
      boolean fileOK = false;

      if ( p[p.length - 1].equals("SVG"))
        fileOK = true;
      if ( p[p.length - 1].equals("svg"))
        fileOK = true;      

      if (fileOK == false)
        savePath = savePath + ".svg";


      // If a file was selected, print path to folder 
      println("Save file: " + savePath);
      SaveNow = 1; 
      showPath  = true;

      ErrorDisplay = "SAVING FILE...";
      ErrorTime = millis();
      ErrorDisp = true;
    }
  }
}


void ORDER_ON_OFF(float theValue) {  
  if (showPath) {
    showPath  = false;
    OrderOnOff.setCaptionLabel("Show Paths");
  }
  else {
    showPath  = true;
    OrderOnOff.setCaptionLabel("Hide Paths");
  }
} 

void CELLS_ON_OFF(float theValue) {  
  if (showCells) {
    showCells  = false;
    CellOnOff.setCaptionLabel("Hide Cells");
  }
  else {
    showCells  = true;
    CellOnOff.setCaptionLabel("Show Cells");
  }
}  

 


void INVERT_IMG(float theValue) {  
  if (invertImg) {
    invertImg  = false;
    InvertOnOff.setCaptionLabel("Black");
    cp5.getController("White_Cutoff").setCaptionLabel("White Cutoff");
  }
  else {
    invertImg  = true;
    InvertOnOff.setCaptionLabel("White");
    cp5.getController("White_Cutoff").setCaptionLabel("Black Cutoff");
  }

  ReInitiallizeArray = true;
  pausemode =  false;
} 




void Pause(float theValue) { 
  // Main particle array setup (to be repeated if necessary):

  if  (pausemode)
  {
    pausemode = false;
    println("Resuming.");
    PauseButton.setCaptionLabel("Pause");
  }
  else
  {
    pausemode = true;
    println("Paused. Press PAUSE again to resume.");
    PauseButton.setCaptionLabel("Resume");
  }
  RouteStep = 0;
} 



void Stipples(int inValue) { 

  if (maxParticles != (int) inValue) {
    println("Update:  Stipple Count -> " + inValue); 
    ReInitiallizeArray = true;
    pausemode =  false;
  }
}





void Min_Dot_Size(float inValue) {
  if (MinDotSize != inValue) {
    println("Update: Min_Dot_Size -> "+inValue);  
    MinDotSize = inValue; 
    MaxDotSize = MinDotSize* (1 + DotSizeFactor);
  }
} 


void Dot_Size_Range(float inValue) {  
  if (DotSizeFactor != inValue) {
    println("Update: Dot Size Range -> "+inValue); 
    DotSizeFactor = inValue;
    MaxDotSize = MinDotSize* (1 + DotSizeFactor);
  }
} 


void White_Cutoff(float inValue) {
  if (cutoff != inValue) {
    println("Update: White_Cutoff -> "+inValue); 
    cutoff = inValue; 
    RouteStep = 0; // Reset TSP path
  }
} 


void  DoBackgrounds() {
  if(true) return;
  if (showBG)
    image(img, 0, 0);    // Show original (cropped and scaled, but not blurred!) image in background
  else { 

    if (invertImg)
      fill(0);
    else
      fill(255);

    rect(0, 0, mainwidth, mainheight);
  }
}

void OptimizePlotPath()
{ 
  int temp;
  // Calculate and show "optimized" plotting path, beneath points.

  StatusDisplay = "Optimizing plotting path";
  /*
  if (RouteStep % 100 == 0) {
   println("RouteStep:" + RouteStep);
   println("fps = " + frameRate );
   }
   */

  Vec2D p1;


  if (RouteStep == 0)
  {

    float cutoffScaled = 1 - cutoff;
    // Begin process of optimizing plotting route, by flagging particles that will be shown.

    particleRouteLength = 0;

    boolean particleRouteTemp[] = new boolean[maxParticles]; 

    for (int i = 0; i < maxParticles; ++i) {

      particleRouteTemp[i] = false;

      int px = (int) particles[i].x;
      int py = (int) particles[i].y;

      if ((px >= imgblur.width) || (py >= imgblur.height) || (px < 0) || (py < 0))
        continue;

      float v = (brightness(imgblur.pixels[ py*imgblur.width + px ]))/255; 

      if (invertImg)
        v = 1 - v;


      if (v < cutoffScaled) {
        particleRouteTemp[i] = true;   
        particleRouteLength++;
      }
    }

    particleRoute = new int[particleRouteLength]; 
    int tempCounter = 0;  
    for (int i = 0; i < maxParticles; ++i) { 

      if (particleRouteTemp[i])      
      {
        particleRoute[tempCounter] = i;
        tempCounter++;
      }
    }
    // These are the ONLY points to be drawn in the tour.
  }

  if (RouteStep < (particleRouteLength - 2)) 
  { 

    // Nearest neighbor ("Simple, Greedy") algorithm path optimization:

    int StopPoint = RouteStep + 1000;      // 1000 steps per frame displayed; you can edit this number!

    if (StopPoint > (particleRouteLength - 1))
      StopPoint = particleRouteLength - 1;

    for (int i = RouteStep; i < StopPoint; ++i) { 

      p1 = particles[particleRoute[RouteStep]];
      int ClosestParticle = 0; 
      float  distMin = Float.MAX_VALUE;

      for (int j = RouteStep + 1; j < (particleRouteLength - 1); ++j) { 
        Vec2D p2 = particles[particleRoute[j]];

        float  dx = p1.x - p2.x;
        float  dy = p1.y - p2.y;
        float  distance = (float) (dx*dx+dy*dy);  // Only looking for closest; do not need sqrt factor!

        if (distance < distMin) {
          ClosestParticle = j; 
          distMin = distance;
        }
      }  

      temp = particleRoute[RouteStep + 1];
      //        p1 = particles[particleRoute[RouteStep + 1]];
      particleRoute[RouteStep + 1] = particleRoute[ClosestParticle];
      particleRoute[ClosestParticle] = temp;

      if (RouteStep < (particleRouteLength - 1))
        RouteStep++;
      else
      {
        println("Now optimizing plot path" );
      }
    }
  }
  else
  {     // Initial routing is complete
    // 2-opt heuristic optimization:
    // Identify a pair of edges that would become shorter by reversing part of the tour.

    for (int i = 0; i < 90000; ++i) {   // 1000 tests per frame; you can edit this number.

      int indexA = floor(random(particleRouteLength - 1));
      int indexB = floor(random(particleRouteLength - 1));

      if (Math.abs(indexA  - indexB) < 2)
        continue;

      if (indexB < indexA)
      {  // swap A, B.
        temp = indexB;
        indexB = indexA;
        indexA = temp;
      }

      Vec2D a0 = particles[particleRoute[indexA]];
      Vec2D a1 = particles[particleRoute[indexA + 1]];
      Vec2D b0 = particles[particleRoute[indexB]];
      Vec2D b1 = particles[particleRoute[indexB + 1]];

      // Original distance:
      float  dx = a0.x - a1.x;
      float  dy = a0.y - a1.y;
      float  distance = (float) (dx*dx+dy*dy);  // Only a comparison; do not need sqrt factor! 
      dx = b0.x - b1.x;
      dy = b0.y - b1.y;
      distance += (float) (dx*dx+dy*dy);  //  Only a comparison; do not need sqrt factor! 

      // Possible shorter distance?
      dx = a0.x - b0.x;
      dy = a0.y - b0.y;
      float distance2 = (float) (dx*dx+dy*dy);  //  Only a comparison; do not need sqrt factor! 
      dx = a1.x - b1.x;
      dy = a1.y - b1.y;
      distance2 += (float) (dx*dx+dy*dy);  // Only a comparison; do not need sqrt factor! 

      if (distance2 < distance)
      {
        // Reverse tour between a1 and b0.   

        int indexhigh = indexB;
        int indexlow = indexA + 1;

        //      println("Shorten!" + frameRate );

        while (indexhigh > indexlow)
        {

          temp = particleRoute[indexlow];
          particleRoute[indexlow] = particleRoute[indexhigh];
          particleRoute[indexhigh] = temp;

          indexhigh--;
          indexlow++;
        }
      }
    }
  }

  frameTime = (millis() - millisLastFrame)/1000;
  millisLastFrame = millis();
}







void doPhysics()
{   // Iterative relaxation via weighted Lloyd's algorithm.

  int temp;
  int CountTemp;

  if (VoronoiCalculated == false)
  {  // Part I: Calculate voronoi cell diagram of the points.

    StatusDisplay = "Calculating Voronoi diagram "; 

    //    float millisBaseline = millis();  // Baseline for timing studies
    //    println("Baseline.  Time = " + (millis() - millisBaseline) );


    if (vorPointsAdded == 0)
      voronoi = new Voronoi();  // Erase mesh

    temp = vorPointsAdded + 200;   // This line: VoronoiPointsPerPass  (Feel free to edit this number.)
    if (temp > maxParticles) 
      temp = maxParticles; 

    for (int i = vorPointsAdded; i < temp; ++i) {  


      // Optional, for diagnostics:::
      //  println("particles[i].x, particles[i].y " + particles[i].x + ", " + particles[i].y );


      // 


      voronoi.addPoint(new Vec2D(particles[i].x, particles[i].y ));
      vorPointsAdded++;
    }   

    if (vorPointsAdded >= maxParticles)
    {

      //    println("Points added.  Time = " + (millis() - millisBaseline) );

      cellsTotal =  (voronoi.getRegions().size());
      vorPointsAdded = 0;
      cellsCalculated = 0;
      cellsCalculatedLast = 0;

      RegionList = new Polygon2D[cellsTotal];

      int i = 0;
      for (Polygon2D poly : voronoi.getRegions()) {
        RegionList[i++] = poly;  // Build array of polygons
      }
      VoronoiCalculated = true;
    }
  }
  else
  {    // Part II: Calculate weighted centroids of cells.
    //  float millisBaseline = millis();
    //  println("fps = " + frameRate );

    StatusDisplay = "Calculating weighted centroids"; 


    temp = cellsCalculated + 100;   // This line: CentroidsPerPass  (Feel free to edit this number.)
    // Higher values give slightly faster computation, but a less responsive GUI.


    if (temp > cellsTotal)
    {
      temp = cellsTotal;
    }

    for (int i=cellsCalculated; i< temp; i++) {  

      float xMax = 0;
      float xMin = mainwidth;
      float yMax = 0;
      float yMin = mainheight;
      float xt, yt;

      Polygon2D region = clip.clipPolygon(RegionList[i]);


      for (Vec2D v : region.vertices) { 

        xt = v.x;
        yt = v.y;

        if (xt < xMin)
          xMin = xt;
        if (xt > xMax)
          xMax = xt;
        if (yt < yMin)
          yMin = yt;
        if (yt > yMax)
          yMax = yt;
      }

      float xDiff = xMax - xMin;
      float yDiff = yMax - yMin;
      float maxSize = max(xDiff, yDiff);
      float minSize = min(xDiff, yDiff);

      float scaleFactor = 1.0;

      // Maximum voronoi cell extent should be between
      // cellBuffer/2 and cellBuffer in size.

      while (maxSize > cellBuffer)
      {
        scaleFactor *= 0.5;
        maxSize *= 0.5;
      }

      while (maxSize < (cellBuffer/2))
      {
        scaleFactor *= 2;
        maxSize *= 2;
      }  

      if ((minSize * scaleFactor) > (cellBuffer/2))
      {   // Special correction for objects of near-unity (square-like) aspect ratio, 
        // which have larger area *and* where it is less essential to find the exact centroid:
        scaleFactor *= 0.5;
      }

      float StepSize = (1/scaleFactor);

      float xSum = 0;
      float ySum = 0;
      float dSum = 0;       
      float PicDensity = 1.0; 


      if (invertImg)
        for (float x=xMin; x<=xMax; x += StepSize) {
          for (float y=yMin; y<=yMax; y += StepSize) {

            Vec2D p0 = new Vec2D(x, y);
            if (region.containsPoint(p0)) { 

              // Thanks to polygon clipping, NO vertices will be beyond the sides of imgblur.  
              PicDensity = 0.001 + (brightness(imgblur.pixels[ round(y)*imgblur.width + round(x) ]));  

              xSum += PicDensity * x;
              ySum += PicDensity * y; 
              dSum += PicDensity;
            }
          }
        }  
      else
        for (float x=xMin; x<=xMax; x += StepSize) {
          for (float y=yMin; y<=yMax; y += StepSize) {

            Vec2D p0 = new Vec2D(x, y);
            if (region.containsPoint(p0)) {

              // Thanks to polygon clipping, NO vertices will be beyond the sides of imgblur. 
              PicDensity = 255.001 - (brightness(imgblur.pixels[ round(y)*imgblur.width + round(x) ]));  


              xSum += PicDensity * x;
              ySum += PicDensity * y; 
              dSum += PicDensity;
            }
          }
        }  

      if (dSum > 0)
      {
        xSum /= dSum;
        ySum /= dSum;
      }

      Vec2D centr;


      float xTemp  = (xSum);
      float yTemp  = (ySum);


      if ((xTemp <= lowBorderX) || (xTemp >= hiBorderX) || (yTemp <= lowBorderY) || (yTemp >= hiBorderY)) {
        // If new centroid is computed to be outside the visible region, use the geometric centroid instead.
        // This will help to prevent runaway points due to numerical artifacts. 
        centr = region.getCentroid(); 
        xTemp = centr.x;
        yTemp = centr.y;

        // Enforce sides, if absolutely necessary:  (Failure to do so *will* cause a crash, eventually.)

        if (xTemp <= lowBorderX)
          xTemp = lowBorderX + 1; 
        if (xTemp >= hiBorderX)
          xTemp = hiBorderX - 1; 
        if (yTemp <= lowBorderY)
          yTemp = lowBorderY + 1; 
        if (yTemp >= hiBorderY)
          yTemp = hiBorderY - 1;
      }      

      particles[i].x = xTemp;
      particles[i].y = yTemp;

      cellsCalculated++;
    } 


    //  println("cellsCalculated = " + cellsCalculated );
    //  println("cellsTotal = " + cellsTotal );

    if (cellsCalculated >= cellsTotal)
    {
      VoronoiCalculated = false; 
      Generation++;
      println("Generation = " + Generation );
      if(Generation >=1)
      {
        Pause(0);
      }


      frameTime = (millis() - millisLastFrame)/1000;
      millisLastFrame = millis();
    }
  }
}

void exportStipple(File file)
{
  if (particles.length <=0) return;

  BufferedWriter writer = null;
  try {
    writer = new BufferedWriter( new FileWriter( file));

   for(int i =0;i<hatchPaths.size();i++)
   {

      Vec2D p1 = particles[particleRoute[i]];
      float x1 = p1.x-simage.width/2+offX;
      float y1 =  p1.y+offY;
      if (i == 0)
      {
        writer.write("G21\n"); //mm
        writer.write("G90\n"); // absolute
        writer.write("G0 F"+speedValue+"\n");

          // pen up
        writer.write("G0 Z"+cncSafeHeight+"\n");
        writer.write("G0 X"+nf(x1, 0, 3) +" Y"+nf(y1, 0, 3)+"\n");
          //pen Down
        writer.write("G0 Z0\n");
      }

      writer.write("G1 X"+nf(x1, 0, 3) +" Y"+nf(y1, 0, 3)+"\n");
      
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
void plotStipples()
{
  dindex = 0;
  plottingStipple = true;
  plottingStarted();
  plotNextStipple();
}

void plotNextStipple()
{
  if(dindex < particleRoute.length)
  {
    Vec2D p1 = particles[particleRoute[dindex]];
    if(dindex == 0)
      sendMoveG0(p1.x+homeX-simage.width/2+offX,p1.y+homeY+offY);
    else
      sendMoveG1(p1.x+homeX-simage.width/2+offX,p1.y+homeY+offY);    
    dindex++;
  }
  else
  {
    plotDone();
    alpha = 255;
    plottingStipple = false;
  }
}

void spiral(float x, float y,float size)
{
   float STEPS_PER_ROTATION = 25;
   float increment = (float)(2*Math.PI/STEPS_PER_ROTATION);
  
  float lastX = x;
  float lastY = y;
  float nx;
  float ny;
  float theta = increment;

  while( theta < size) {

       nx = (float)(x + theta/4 * Math.cos(theta));
       ny = (float)(y + theta/4 * Math.sin(theta));

      line(scaleX(lastX), scaleY(lastY),scaleX(nx),scaleY(ny));
      
      theta = theta + increment;
      lastX = nx; 
      lastY = ny;   
    }

}

void stippleDraw()
{

  int i = 0;
  int temp;
  float dotScale = (MaxDotSize - MinDotSize);
  float cutoffScaled = 1 - cutoff;

  if (ReInitiallizeArray) {
    maxParticles = (int) cp5.getController("Stipples").getValue(); // Only change this here!

    MainArraysetup();
    ReInitiallizeArray = false;
  } 

  if (pausemode && (VoronoiCalculated == false))  
    OptimizePlotPath();
  else
    doPhysics();


  if (pausemode)
  {

    DoBackgrounds();

    // Draw paths:

    if ( showPath ) {

      
        // Stroke color (blue)
      strokeWeight (1);

      for ( i = 0; i < (particleRouteLength - 1); ++i) {
        if(i < dindex)
          stroke(255, 0, 0,255); 
        else
          stroke(128, 128, 255,alpha); 
        Vec2D p1 = particles[particleRoute[i]];
        Vec2D p2 = particles[particleRoute[i + 1]];

        line(scaleX(p1.x+homeX-simage.width/2+offX), scaleY(p1.y+homeY+offY), scaleX(p2.x+homeX-simage.width/2+offX), scaleY(p2.y+homeY+offY));
      }
    }


    if (invertImg)
      stroke(255);
    else
      stroke(0);

    for ( i = 0; i < particleRouteLength; ++i) {
      // Only show "routed" particles-- those above the white cutoff.

      Vec2D p1 = particles[particleRoute[i]];  
      int px = (int) p1.x;
      int py = (int) p1.y;

      float v = (brightness(imgblur.pixels[ py*imgblur.width + px ]))/255; 

      if (invertImg)
        v = 1 - v;

      strokeWeight (zoomScale*(MaxDotSize -  v * dotScale));  
      point(scaleX(px+homeX-simage.width/2+offX), scaleY(py+homeY+offY));
     //  strokeWeight(0.1);
     // spiral(px+homeX-simage.width/2+offX,py+homeY+offY,MaxDotSize -  v * dotScale);

    }
  }
  else
  {      // NOT in pause mode.  i.e., just displaying stipples.
    if (cellsCalculated == 0) {

      DoBackgrounds();

      if (Generation == 0)
      {
        TempShowCells = true;
      }

      if (showCells || TempShowCells) {  // Draw voronoi cells, over background.
        strokeWeight(1);
        noFill();


        if (invertImg && (showBG == false))  // TODO -- if invertImg AND NOT background
          stroke(100);
        else
          stroke(200);

        //        stroke(200);

        i = 0;

        pushMatrix();
        Vec2D offset = new Vec2D(scaleX(homeX-simage.width/2+offX),scaleY(homeY+offY));
        Vec2D scale = new Vec2D(zoomScale,zoomScale);
        gfx.translate(offset);
        gfx.scale(scale);
        for (Polygon2D poly : voronoi.getRegions()) {
          //RegionList[i++] = poly; 
          gfx.polygon2D(clip.clipPolygon(poly));
        }
        popMatrix();
      }

      if (showCells) {
        // Show "before and after" centroids, when polygons are shown.

        strokeWeight (zoomScale*MinDotSize);  // Normal w/ Min & Max dot size
        for ( i = 0; i < maxParticles; ++i) {

          int px = (int) particles[i].x;
          int py = (int) particles[i].y;

          if ((px >= imgblur.width) || (py >= imgblur.height) || (px < 0) || (py < 0))
            continue;
          {  
            point(scaleX(px+homeX-simage.width/2+offX), scaleY(py+homeY+offY));
          }
        }
      }
    }
    else {
      // Stipple calculation is still underway

      if (TempShowCells)
      {
        DoBackgrounds(); 
        TempShowCells = false;
      }


      //      stroke(0);   // Stroke color


      if (invertImg)
        stroke(255);
      else
        stroke(0);

      for ( i = 0; i < cellsCalculated; ++i) {

        int px = (int) particles[i].x;
        int py = (int) particles[i].y;

        if ((px >= imgblur.width) || (py >= imgblur.height) || (px < 0) || (py < 0))
          continue;
        { 
          float v = (brightness(imgblur.pixels[ py*imgblur.width + px ]))/255; 

          if (invertImg)
            v = 1 - v;

          if (v < cutoffScaled) { 
            strokeWeight (zoomScale*(MaxDotSize - v * dotScale));  
            point(scaleX(px+homeX-simage.width/2+offX), scaleY(py+homeY+offY));
          }
        }
      }

      cellsCalculatedLast = cellsCalculated;
    }
  }


  if (SaveNow > 0) {

    StatusDisplay = "Saving SVG File";
    SaveNow = 0;

    FileOutput = loadStrings("header.txt"); 

    String rowTemp;

    float SVGscale = (800.0 / (float) mainheight); 
    int xOffset = (int) (1600 - (SVGscale * mainwidth / 2));
    int yOffset = (int) (400 - (SVGscale * mainheight / 2));


    if (FileModeTSP) 
    { // Plot the PATH between the points only.

      println("Save TSP File (SVG)");

      // Path header::
      rowTemp = "<path style=\"fill:none;stroke:black;stroke-width:2px;stroke-linejoin:round;stroke-linecap:round;\" d=\"M "; 
      FileOutput = append(FileOutput, rowTemp);


      for ( i = 0; i < particleRouteLength; ++i) {

        Vec2D p1 = particles[particleRoute[i]];  

        float xTemp = SVGscale*p1.x + xOffset;
        float yTemp = SVGscale*p1.y + yOffset;        

        rowTemp = xTemp + " " + yTemp + "\r";

        FileOutput = append(FileOutput, rowTemp);
      } 
      FileOutput = append(FileOutput, "\" />"); // End path description
    }
    else {
      println("Save Stipple File (SVG)");

      for ( i = 0; i < particleRouteLength; ++i) {

        Vec2D p1 = particles[particleRoute[i]]; 

        int px = floor(p1.x);
        int py = floor(p1.y);

        float v = (brightness(imgblur.pixels[ py*imgblur.width + px ]))/255;  
        
        if (invertImg)
          v = 1 - v;
        
        float dotrad =  (MaxDotSize - v * dotScale)/2; 

        float xTemp = SVGscale*p1.x + xOffset;
        float yTemp = SVGscale*p1.y + yOffset; 

        rowTemp = "<circle cx=\"" + xTemp + "\" cy=\"" + yTemp + "\" r=\"" + dotrad +
          "\" style=\"fill:none;stroke:black;stroke-width:2;\"/>";

        // Typ:   <circle  cx="1600" cy="450" r="3" style="fill:none;stroke:black;stroke-width:2;"/>

        FileOutput = append(FileOutput, rowTemp);
      }
    }



    // SVG footer:
    FileOutput = append(FileOutput, "</g></g></svg>");
    saveStrings(savePath, FileOutput);
    FileModeTSP = false; // reset for next time

      if (FileModeTSP) 
      ErrorDisplay = "TSP Path .SVG file Saved";
    else
      ErrorDisplay = "Stipple .SVG file saved ";

    ErrorTime = millis();
    ErrorDisp = true;
  }
} 




