/**
*  Polargraph Server. - CORE
*  Written by Sandy Noble
*  Released under GNU License version 3.
*  http://www.polargraph.co.uk
*  https://github.com/euphy/polargraph_server_polarshield

Pixel.

This is one of the core files for the polargraph server program.  

This is a biggie, and has the routines necessary for generating and drawing
the squarewave and scribble pixel styles.

*/
#define F(x) x
#define COMMA ","
const static byte DIR_NE = 1;
const static byte DIR_SE = 2;
const static byte DIR_SW = 3;
const static byte DIR_NW = 4;

const static byte DIR_N = 5;
const static byte DIR_E = 6;
const static byte DIR_S = 7;
const static byte DIR_W = 8;
static int globalDrawDirection = DIR_NW;

static boolean pixelDebug = false;
const static byte DIR_MODE_AUTO = 1;
const static byte DIR_MODE_PRESET = 2;
const static byte DIR_MODE_RANDOM = 3;
static int globalDrawDirectionMode = DIR_MODE_AUTO;
static float penWidth = 0.5;

static const byte ALONG_A_AXIS = 0;
static const byte ALONG_B_AXIS = 1;
static const byte SQUARE_SHAPE = 0;
static const byte SAW_SHAPE = 1;
float stepsPerMM = 1;
float mmPerStep = 1;
static boolean lastWaveWasTop = true;
byte lastDir = DIR_SE;

void setPenWidth(float width)
{
  penWidth = width;
  Com::print("penWidth ");
  Com::printFloat(width,2);
}
long multiplier(long x)
{
  return x;
}

int multiplier(int x)
{
  return x;
}

long motorAcurrentPosition()
{
  return Printer::currentPosition[X_AXIS];
}

long motorBcurrentPosition()
{
  return Printer::currentPosition[Y_AXIS];
}

void moveA(float a)
{
    PrintLine::moveSteps(a,0,true);
   // Printer::currentPosition[X_AXIS] += a;
   // PrintLine::queueCartesianMove(ALWAYS_CHECK_ENDSTOPS,true);
}

void moveB(float b)
{
    PrintLine::moveSteps(0,b,true);
   // Printer::currentPosition[Y_AXIS] += b;
   // PrintLine::queueCartesianMove(ALWAYS_CHECK_ENDSTOPS,true);
}
void changeLength(float a, float b)
{
    Printer::currentPosition[X_AXIS] = a;
    Printer::currentPosition[Y_AXIS] = b;
    PrintLine::queueCartesianMove(ALWAYS_CHECK_ENDSTOPS,true);
}
void changeLengthRelative(float a, float b)
{
    PrintLine::moveSteps(a,b,true);
    //Printer::currentPosition[X_AXIS] += a;
   // Printer::currentPosition[Y_AXIS] += b;
   // PrintLine::queueCartesianMove(ALWAYS_CHECK_ENDSTOPS,true);
}
void reportPosition()
{
}
void pixel_drawSquarePixel( int size, int density,byte dir,long delta) 
{   
    globalDrawDirection = dir;  
 /*   
    if(lastDir != dir && delta > 0)
    { 
      if(lastDir == DIR_SE)
      {
        if(dir == DIR_SW) 
        {
          PrintLine::moveSteps(0,delta*size-size/2,true);
          PrintLine::moveSteps(-size/2,0,true);
        }
        else if(dir == DIR_NE)
        {
          PrintLine::moveSteps(0,-delta*size+size/2,true);
          PrintLine::moveSteps(-size/2,0,true);
        }
        else if(dir == DIR_NW)
          PrintLine::moveSteps(-delta*size,0,true); 
      } 
      else if(lastDir == DIR_SW)
      {
        if(dir == DIR_SE) 
        {
          PrintLine::moveSteps(delta*size-size/2,0,true);
          PrintLine::moveSteps(0,-size/2,true);
        }
        else if(dir == DIR_NE)
        {
          PrintLine::moveSteps(0,-delta*size,true);
        }
        else if(dir == DIR_NW)
        {
          PrintLine::moveSteps(-delta*size+size/2,0,true);
          PrintLine::moveSteps(0,-size/2,true);
        } 
      }
      else if(lastDir == DIR_NE)
      {
        if(dir == DIR_SE)
       { 
          PrintLine::moveSteps(delta*size-size/2,0,true);
          PrintLine::moveSteps(0,size/2,true);
       }
        else if(dir == DIR_SW)
        {
          PrintLine::moveSteps(0,delta*size,true);
        }
        else if(dir == DIR_NW)
        {
          PrintLine::moveSteps(-delta*size+size/2,0,true); 
          PrintLine::moveSteps(0,size/2,true);
        }
      }
      else if(lastDir == DIR_NW)
      {
        if(dir == DIR_SE) 
          PrintLine::moveSteps(delta*size,0,true);
        else if(dir == DIR_SW)
        {
          PrintLine::moveSteps(0,delta*size-size/2,true);
          PrintLine::moveSteps(size/2,0,true);
        }
        else if(dir == DIR_NE)
        {
          PrintLine::moveSteps(0,-delta*size+size/2,true);
          PrintLine::moveSteps(size/2,0,true);
        } 
      }      
    }
    lastDir = dir;
*/
    int maxWavesForGridAndPen = pixel_maxDensity(penWidth, size);
    int noOfWaves = pixel_scaleDensity(density, 255, maxWavesForGridAndPen);

    if (noOfWaves > 1)
    {
      pixel_drawWavePixel(size, size, noOfWaves, globalDrawDirection, SQUARE_SHAPE);
    } 
}

byte pixel_getRandomDrawDirection()
{
  return random(1, 5);
}

byte pixel_getAutoDrawDirection(long targetA, long targetB, long sourceA, long sourceB)
{
  byte dir = DIR_SE;
  
  // some bitchin triangles, I goshed-well love triangles.
//  long diffA = sourceA - targetA;
//  long diffB = sourceB - targetB;
//  long hyp = sqrt(sq(diffA)+sq(diffB));
//  
//  float bearing = atan(hyp/diffA);
  
//  Com::print("bearing:");
//  Com::print(bearing);
//
    if (pixelDebug) {
      Com::print(F("TargetA: "));
      Com::print(targetA);
      Com::print(F(", targetB: "));
      Com::print(targetB);
      Com::print(F(". SourceA: "));
      Com::print(sourceA);
      Com::print(F(", sourceB: "));
      Com::print(sourceB);
      Com::print(F("."));
  }
  
  if (targetA<sourceA && targetB<sourceB)
  {
    if (pixelDebug) { Com::print(F("calculated NW")); }
    dir = DIR_NW;
  }
  else if (targetA>sourceA && targetB>sourceB)
  {
    if (pixelDebug) { Com::print(F("calculated SE")); }
    dir = DIR_SE;
  }
  else if (targetA<sourceA && targetB>sourceB)
  {
    if (pixelDebug) { Com::print(F("calculated SW")); }
    dir = DIR_SW;
  }
  else if (targetA>sourceA && targetB<sourceB)
  {
    if (pixelDebug) { Com::print(F("calculated NE")); }
    dir = DIR_NE;
  }
  else if (targetA==sourceA && targetB<sourceB)
  {
    if (pixelDebug) { Com::print(F("calc NE")); }
    dir = DIR_NE;
  }
  else if (targetA==sourceA && targetB>sourceB)
  {
    if (pixelDebug) { Com::print(F("calc SW")); }
    dir = DIR_SW;
  }
  else if (targetA<sourceA && targetB==sourceB)
  {
    if (pixelDebug) { Com::print(F("calc NW")); }
    dir = DIR_NW;
  }
  else if (targetA>sourceA && targetB==sourceB)
  {
    if (pixelDebug) { Com::print(F("calc SE")); }
    dir = DIR_SE;
  }
  else
  {
    if (pixelDebug) { Com::print("Not calculated - default SE"); }
  }

  return dir;
}

void pixel_drawScribblePixelM(long inParam1, long inParam2, int inParam3, int inParam4) 
{
    long originA = multiplier(inParam1);
    long originB = multiplier(inParam2);
    int size = multiplier(inParam3);
    int density = inParam4;
    
    int maxDens = pixel_maxDensity(penWidth, size);

    density = pixel_scaleDensity(density, 255, maxDens);
    pixel_drawScribblePixel(originA, originB, size*1.1, density);
    
    //outputAvailableMemory(); 
}

void pixel_drawScribblePixel(long originA, long originB, int size, int density) 
{
  if (pixelDebug) { 
    int originA = motorAcurrentPosition();
    int originB = motorBcurrentPosition();
  }
  
  long lowLimitA = originA-(size/2);
  long highLimitA = lowLimitA+size;
  long lowLimitB = originB-(size/2);
  long highLimitB = lowLimitB+size;
  int randA;
  int randB;
  
  int inc = 0;
  int currSize = size;
  
  for (int i = 0; i <= density; i++)
  {
    randA = random(0, currSize);
    randB = random(0, currSize);
    changeLength(lowLimitA+randA, lowLimitB+randB);
    
    lowLimitA-=inc;
    highLimitA+=inc;
    currSize+=inc*2;
  }
}

int pixel_minSegmentSizeForPen(float penSize)
{
  float penSizeInSteps = penSize * stepsPerMM;

  int minSegSize = 1;
  if (penSizeInSteps >= 2.0)
    minSegSize = int(penSizeInSteps);

  if (pixelDebug) {     
    Com::print(F("Min segment size for penSize "));
    Com::printFLN("P ",penSize);
    Com::print(F(": "));
    Com::print(minSegSize);
    Com::print(F(" steps."));
    Com::println();
  }
  
  return minSegSize;
}

int pixel_maxDensity(float penSize, int rowSize)
{
  float rowSizeInMM = mmPerStep * rowSize;

  if (pixelDebug) {     
    Com::print(F("MSG,D,rowsize in mm: "));
    Com::printFLN("r",rowSizeInMM);
    Com::print(F(", mmPerStep: "));
    Com::printFLN("m",mmPerStep);
    Com::print(F(", so rowsize in steps: "));
    Com::print(rowSize);
  }
  
  float numberOfSegments = rowSizeInMM / penSize;
  int maxDens = 1;
  if (numberOfSegments >= 2.0)
    maxDens = int(numberOfSegments);

  if (maxDens <= 1)
  {
    Com::print(F("MSG,I,Max waves for penSize: "));
    Com::printFLN("P",penSize);
    Com::print(F(", grid: "));
    Com::printFLN("R",rowSize);
    Com::print(F(" is "));
    Com::print(maxDens);
   // Com::print(MSG);
    //Com::print(MSG_INFO);
    Com::print(F("Not possible to express any detail."));
  }  
  
  return maxDens;
}

int pixel_scaleDensity(int inDens, int inMax, int outMax)
{
  float reducedDens = (float(inDens) / float(inMax)) * float(outMax);
  reducedDens = outMax-reducedDens;
  if (pixelDebug) {     
    Com::print(F("inDens:"));
    Com::print(inDens);
    Com::print(F(", inMax:"));
    Com::print(inMax);
    Com::print(F(", outMax:"));
    Com::print(outMax);
    Com::print(F(", reduced:"));
    Com::printFLN("r",reducedDens);
  }
  
  // round up if bigger than .5
  int result = int(reducedDens);
  if (reducedDens - (result) > 0.5)
    result ++;

  
  return result;
}

void pixel_drawWavePixel(int length, int width, int density, byte drawDirection, byte shape) 
{
  if (density > 0)
  {
    int mmToStep = 80; //todo call global
    float segmentLength = (float)length / (float)density;
    int stepLen = round(mmToStep*segmentLength);
    long error = mmToStep*length - (stepLen*density);
  /*  
   Com::print("length ");
   Com::print(length);
   Com::print(" density ");
   Com::print(density);
   Com::print(" error ");
   Com::print(error);
   Com::print("\n");
   */
    for (int i = 0; i <= density; i++) 
    {
      if (drawDirection == DIR_SE) {
        pixel_drawWaveAlongAxis(width, segmentLength, density, i, ALONG_A_AXIS, shape);
      }
      if (drawDirection == DIR_SW) {
        pixel_drawWaveAlongAxis(width, segmentLength, density, i, ALONG_B_AXIS, shape);
      }
      if (drawDirection == DIR_NW) {
        pixel_drawWaveAlongAxis(width, -segmentLength, density, i, ALONG_A_AXIS, shape);
      }
      if (drawDirection == DIR_NE) {
        pixel_drawWaveAlongAxis(width, -segmentLength, density, i, ALONG_B_AXIS, shape);
      }

    } // end of loop
    if(error != 0)
    {
      if (drawDirection == DIR_SE) {
         PrintLine::moveRawDeltaSteps(error,0,true);
      }
      if (drawDirection == DIR_SW) {
         PrintLine::moveRawDeltaSteps(0,error,true);
       }
      if (drawDirection == DIR_NW) {
         PrintLine::moveRawDeltaSteps(-error,0,true);  
       }
      if (drawDirection == DIR_NE) {
        PrintLine::moveRawDeltaSteps(0,-error,true);
      }

    }
  }
}

void pixel_drawSquarePixel(int length, int width, int density, byte drawDirection) 
{
  // work out how wide each segment should be
  int segmentLength = 0;

  if (density > 0)
  {
    
    // work out some segment widths
    float basicSegLength = (float)length / (float)density;
   // int basicSegRemainder = length % density;
   // float remainderPerSegment = float(basicSegRemainder) / float(density);
   // float totalRemainder = 0.0;
   // int lengthSoFar = 0;
    
    if (pixelDebug) {
      Com::print("Basic sq length:");
     // Com::print(basicSegLength);
     // Com::print(", basic seg remainder:");
    //  Com::print(basicSegRemainder);
     // Com::print(", remainder per seg");
     // Com::printFLN("r",remainderPerSegment);
    }
    
    for (int i = 0; i <= density; i++) 
    {
      /*
      totalRemainder += remainderPerSegment;

      if (totalRemainder >= 1.0)
      {
        totalRemainder -= 1.0;
        segmentLength = basicSegLength+1;
      }
      else
      {
        segmentLength = basicSegLength;
      }
*/
      if (drawDirection == DIR_SE) {
        pixel_drawWaveAlongAxis(width, segmentLength, density, i, ALONG_A_AXIS, SQUARE_SHAPE);
      }
      if (drawDirection == DIR_SW) {
        pixel_drawWaveAlongAxis(width, segmentLength, density, i, ALONG_B_AXIS, SQUARE_SHAPE);
      }
      if (drawDirection == DIR_NW) {
       // segmentLength = 0 - segmentLength; // reverse
        pixel_drawWaveAlongAxis(width, -segmentLength, density, i, ALONG_A_AXIS, SQUARE_SHAPE);
      }
      if (drawDirection == DIR_NE) {
       // segmentLength = 0 - segmentLength; // reverse
        pixel_drawWaveAlongAxis(width, -segmentLength, density, i, ALONG_B_AXIS, SQUARE_SHAPE);
      }
     // lengthSoFar += segmentLength;
    //  reportPosition();
    } // end of loop
  }
}

/* 
Direction is along A or B axis.
*/
void pixel_movePairForWave(float amplitude, float length, byte dir, byte shape)
{
  if (shape == SQUARE_SHAPE)  // square wave
  {
    if (dir == ALONG_A_AXIS)
    {
      moveB(amplitude);
      moveA(length);
    }
    else if (dir == ALONG_B_AXIS)
    {
      moveA(amplitude);
      moveB(length);
    }
  }
  else if (shape == SAW_SHAPE)
  {
    if (dir == ALONG_A_AXIS)
    {
      changeLengthRelative(long(length/2), long(amplitude));
      changeLengthRelative(long(0-(length/2)), long(0-amplitude));
    }
    else if (dir == ALONG_B_AXIS)
    {
      changeLengthRelative(long(amplitude), long(length/2));
      changeLengthRelative(long(0-amplitude), long(0-(length/2)));
      
      
    }
  }
}

void pixel_drawWaveAlongAxis(int waveAmplitude, float waveLength, int totalWaves, int waveNo, byte dir, byte shape)
{
  float halfAmplitude = (float)waveAmplitude / 2;
  if (waveNo == 0) 
  { 
    // first one, half a line and an along
    //Com::print("First wave half");
    if (lastWaveWasTop)
      pixel_movePairForWave(halfAmplitude, waveLength, dir, shape);
    else 
      pixel_movePairForWave(0-halfAmplitude, waveLength, dir, shape);
    pixel_flipWaveDirection();
  }
  else if (waveNo == totalWaves) 
  { 
    // last one, half a line with no along
    if (lastWaveWasTop) 
      pixel_movePairForWave(halfAmplitude, 0, dir, shape);
    else
      pixel_movePairForWave(0-halfAmplitude, 0, dir, shape);
  }
  else 
  { 
    // intervening lines - full lines, and an along
    if (lastWaveWasTop) 
      pixel_movePairForWave(waveAmplitude, waveLength, dir, shape);
    else
      pixel_movePairForWave(0-waveAmplitude, waveLength, dir, shape);
    pixel_flipWaveDirection();
  }
}

void pixel_flipWaveDirection()
{
  if (lastWaveWasTop)
    lastWaveWasTop = false;
  else
    lastWaveWasTop = true;
}

  void pixel_testPenWidth(int inParam1,float inParam2,float inParam3,float inParam4)
  {
    int rowWidth = multiplier(inParam1);
    float startWidth = inParam2;
    float endWidth = inParam3; 
    float incSize = inParam4;

    int tempDirectionMode = globalDrawDirectionMode;
    globalDrawDirectionMode = DIR_MODE_PRESET;
    
    float oldPenWidth = penWidth;
    int iterations = 0;
    
    for (float pw = startWidth; pw <= endWidth; pw+=incSize)
    {
      iterations++;
      penWidth = pw;
      int maxDens = pixel_maxDensity(penWidth, rowWidth);
      if (pixelDebug) {
        Com::print(F("Penwidth test "));
        Com::print(iterations);
        Com::print(F(", pen width: "));
        Com::printFLN("p",penWidth);
        Com::print(F(", max density: "));
        Com::print(maxDens);
      }
      pixel_drawSquarePixel(rowWidth, rowWidth, maxDens, DIR_SE);
    }

    penWidth = oldPenWidth;
    
    moveB(0-rowWidth);
    for (int i = 1; i <= iterations; i++)
    {
      moveB(0-(rowWidth/2));
      moveA(0-rowWidth);
      moveB(rowWidth/2);
    }
    
    penWidth = oldPenWidth;
    globalDrawDirectionMode = tempDirectionMode;
  }    

