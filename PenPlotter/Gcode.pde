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

void clearGcode()
{
  gcodeData = null;
  gcodePaths = null;
  resetGcode();
}

void resetGcode()
{
    plottingGcode = false;  
    plotDone();
}

void loadGcode(String fileName)
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


void renderData(ArrayList<String> data)
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

  double offsetX = 0.5*(x-(y*h_x2_div_d));
  double offsetY = 0.5*(y+(x*h_x2_div_d));

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

  double angle = 0.0;

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
      angle = Math.PI / 2.0;
    }
    // 270 deg
    else {
      angle = Math.PI * 3.0 / 2.0;
    }
  }

  return angle;
} 

void generatePointsAlongArcBDring(int step, int c, float sx, float sy, float sz, float ex, float ey, float ez, float cx, float cy, boolean isCw, double R, int arcResolution) {
  double radius = R;
  double sweep;

  // Calculate radius if necessary.
  if (radius == 0) {
    radius = Math.sqrt(Math.pow(sx - cx, 2.0) + Math.pow(sy - cy, 2.0));
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
void addLine(int step, int c, float lastX, float lastY, float lastZ, float x, float y, float z) 
{

  if (c == BLUE || gcodePath == null)
  {
    gcodePath = new Path();
    gcodePaths.add(gcodePath);
  }
    
  gcodePath.addPoint(x, y);

}

void rotateGcode(int rotation)
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

void drawPath()
{
  float lastX = -offX/(userScale*flipX);
  float lastY = -offY/(userScale*flipY);
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
      sline(lastX*userScale*flipX+offX+homeX, lastY*userScale*flipY+offY+homeY, cur.x*userScale*flipX+offX+homeX, cur.y*userScale*flipY+offY+homeY);
      lastX = cur.x;
      lastY = cur.y;
    }
  }
  stroke(0, 255, 0);
  sline(lastX*userScale*flipX+offX+homeX, lastY*userScale*flipY+offY+homeY, homeX, homeY);
}

void plotGcode()
{
  gcodeIndex = 0;
  plottingGcode = true;
  lastX = 0;
  lastY = 0;
  lastZ = 0;
  sendSpeed(speedValue);
  nextGcode();
}

void nextGcode()
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
      plotDone();
      sendPenUp();
      sendMoveG0(homeX,homeY);
      updatePos(homeX,homeY);
      sendMotorOff();


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
        x = Float.parseFloat(token.substring(1))*conversion*userScale*flipX;
      else if (token.startsWith("Y"))
        y = Float.parseFloat(token.substring(1))*conversion*userScale*flipY;
      else if (token.startsWith("Z"))
        z = -Float.parseFloat(token.substring(1))*conversion*userScale;
      else if (token.startsWith("I"))
        I = Float.parseFloat(token.substring(1))*conversion*userScale*flipX;
      else if (token.startsWith("J"))
        J = Float.parseFloat(token.substring(1))*conversion*userScale*flipY;
      else if (token.startsWith("R"))
        R = Double.parseDouble(token.substring(1))*conversion*userScale;
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
        sendMoveG0((x+offX+homeX),(y+offY+homeY));
        sendPenDown();
        sent= true;
      } else if (cmd.equals("G1"))
      {
        sendMoveG1((x+offX+homeX),(y+offY+homeY));
        sent= true;
      } else if (cmd.equals("G2"))
      {
        if (!Float.isNaN(I) && !Float.isNaN(J))
        { 
          sendG2((x+offX+homeX),(y+offY+homeY),I,J);
          sent= true;
        }
      } else if (cmd.equals("G3"))
      {
        if (!Float.isNaN(I) && !Float.isNaN(J))
        { 
          sendG3((x+offX+homeX),(y+offY+homeY),I,J);
          sent = true;
        }
      }

      updatePos(x+offX+homeX,y+offY+homeY);
      lastX = x;
      lastY = y;
      lastZ = z;
    } 
    gcodeIndex++;
  }
}




