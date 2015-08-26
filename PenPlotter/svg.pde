RShape sh = null;
ArrayList<Path> optimizedPaths;

int svgPathIndex = -1;        // curent path that is plotting
int svgLineIndex = -1;        // current line within path that is plotting
boolean plottingSvg = false;  // true if plotting svg file
float svgDpi = 72;
float svgScale = 25.4f/svgDpi;


void clearSvg()
{
  sh = null;
  optimizedPaths = null;
  resetSvg();
}

void resetSvg()
{
  plottingSvg = false;
  plotDone();
  svgPathIndex = -1;
  svgLineIndex = -1;
  clearQueue();
}

void drawPlottedLine()
{
  if (svgPathIndex < 0)
  {
    return;
  }
  float cx = homeX;
  float cy = homeY;

  for (int i = 0; i<optimizedPaths.size (); i++)
  {
    for (int j = 0; j<optimizedPaths.get (i).size()-1; j++)
    {
      if (i > svgPathIndex || (i == svgPathIndex && j > svgLineIndex)) return;
      float x1 = optimizedPaths.get(i).getPoint(j).x*scaleX+machineWidth/2+offX;
      float y1 =  optimizedPaths.get(i).getPoint(j).y*scaleY+homeY+offY;
      float x2 = optimizedPaths.get(i).getPoint(j+1).x*scaleX+machineWidth/2+offX;
      float y2 =  optimizedPaths.get(i).getPoint(j+1).y*scaleY+homeY+offY;


      if (j == 0)
      {
        // pen up

        stroke(rapidColor); 
        sline(cx, cy, x1, y1);
        cx = x1;
        cy = y1;
      }

      stroke(drawColor); 
      sline(cx, cy, x2, y2);
      cx = x2;
      cy = y2;



      if (i == svgPathIndex && j == svgLineIndex)
        return;
    }
  }
}

void plotLine()
{
  if (svgPathIndex < 0)
  {
    plottingSvg = false;
    plotDone();
    return;
  }

  if (svgPathIndex == 0 && svgLineIndex == 0) // first line
  {
    sendAbsolute();
    sendSpeed(speedValue);
  }
  if (svgPathIndex < optimizedPaths.size())
  {
    if (svgLineIndex< optimizedPaths.get(svgPathIndex).size()-1)
    {

      float x1 = optimizedPaths.get(svgPathIndex).getPoint(svgLineIndex).x*scaleX+machineWidth/2+offX;
      float y1 =  optimizedPaths.get(svgPathIndex).getPoint(svgLineIndex).y*scaleY+homeY+offY;
      float x2 = optimizedPaths.get(svgPathIndex).getPoint(svgLineIndex+1).x*scaleX+machineWidth/2+offX;
      float y2 =  optimizedPaths.get(svgPathIndex).getPoint(svgLineIndex+1).y*scaleY+homeY+offY;


      if (svgLineIndex == 0)
      {
        sendPenUp();
        sendMoveG0(x1,y1);
        sendPenDown();
      }

      sendMoveG1(x2,y2);
      svgLineIndex++;
    } else
    {
      svgPathIndex++;
      svgLineIndex = 0;
      plotLine();
    }
  } else // finished
  {
    plottingSvg = false;
    plotDone();
    float x1 = homeX;
    float y1 = homeY;

    sendPenUp();
    sendMoveG0(x1,y1);
    sendMotorOff();
    svgLineIndex = -1;
    svgPathIndex = -1;
  }
}

void exportSvg(File file)
{
  if (optimizedPaths == null) return;
  BufferedWriter writer = null;
  try {
    writer = new BufferedWriter( new FileWriter( file));

    for (int i = 0; i<optimizedPaths.size (); i++)
    {
      Path p = optimizedPaths.get(i);
      if (i == 0)
      {
        writer.write("G21\n"); //mm
        writer.write("G90\n"); // absolute
        writer.write("G0 F"+speedValue+"\n");
      }
      for (int j = 0; j<p.size ()-1; j++)
      {

        float x1 = p.getPoint(j).x*scaleX+offX;
        float y1 =  p.getPoint(j).y*scaleY+offY;
        float x2 = p.getPoint(j+1).x*scaleX+offX;
        float y2 =  p.getPoint(j+1).y*scaleY+offY;


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

void plotSvg()
{
  if (sh != null)
  {
    plottingSvg = true;
    svgPathIndex = 0;
    svgLineIndex = 0;
    plotLine();
  }
}

void rotateSvg(int rotation)
{
  if (optimizedPaths == null) return;

  for (int i = 0; i<optimizedPaths.size (); i++) {
    Path p = optimizedPaths.get(i);
    for (int j = 0; j<p.size (); j++) {
      float x = p.getPoint(j).x;
      float y = p.getPoint(j).y;

      p.getPoint(j).x = -y;
      p.getPoint(j).y = x;
    }
  }
}

void drawSvg()
{
  lastX = -offX;
  lastY = -offY;
  strokeWeight(0.1);
  noFill();
  

  for (int i = 0; i<optimizedPaths.size (); i++) {
    Path p = optimizedPaths.get(i);

    stroke(rapidColor);
    if(i == 0)
        sline(homeX, homeY, p.first().x*scaleX+homeX+offX, p.first().y*scaleY+homeY+offY);
    else
        sline(lastX*scaleX+homeX+offX, lastY*scaleY+homeY+offY, p.first().x*scaleX+homeX+offX, p.first().y*scaleY+homeY+offY);
        
    stroke(penColor);
    beginShape();
    for (int j = 0; j<p.size (); j++) {
      vertex(scaleX(p.getPoint(j).x*scaleX+homeX+offX), scaleY(p.getPoint(j).y*scaleY+homeY+offY));
    }
    endShape();
    lastX = p.last().x;
    lastY = p.last().y;
  }
  
  stroke(rapidColor);
  sline(lastX*scaleX+homeX+offX, lastY*scaleY+homeY+offY, homeX, homeY);

}


RShape loadShapeFromFile(String filename) {

  RShape shape = null;
  File file = new File(filename);
  if (file.exists())
  {
    shape = RG.loadShape(filename);

    println("loaded "+filename);
    optimize(shape);
  } else
    println("Failed to load file "+filename);

  return shape;
}




void totalPathLength()
{
  long total = 0;
  float lx = homeX;
  float ly = homeY;
  for (int i = 0; i<optimizedPaths.size (); i++) {
    Path path = optimizedPaths.get(i);
    for (int j = 0; j<path.size (); j++) {
      RPoint p = path.getPoint(j);
      total += dist(lx, ly, p.x, p.y);
      lx = p.x;
      ly = p.y;
    }
  }
  System.out.println("total Path length "+total);
}

void optimize(RShape shape)
{
  RPoint[][] pointPaths = shape.getPointsInPaths();
  optimizedPaths = new ArrayList<Path>();
  ArrayList <Path> remainingPaths = new ArrayList<Path>();

  for (int i = 0; i<pointPaths.length; i++) {
    if (pointPaths[i] != null) 
    {
      Path path = new Path();

      for (int j =0; j<pointPaths[i].length; j++)
      {
        path.addPoint(pointPaths[i][j].x, pointPaths[i][j].y);
      }
      remainingPaths.add(path);
    }
  }

  println("Original number of paths "+remainingPaths.size());
  
  Path path = nearestPath(homeX, homeY, remainingPaths);
  optimizedPaths.add(path); 

  int numPaths = remainingPaths.size();
  for (int i = 0; i<numPaths; i++)
  {
    RPoint last = path.last();
    path = nearestPath(last.x, last.y, remainingPaths);
    optimizedPaths.add(path);
  }

  if(shortestSegment > 0)
  {
    remainingPaths = optimizedPaths;
    optimizedPaths = new ArrayList<Path>();

    mergePaths(shortestSegment, remainingPaths);
    println("number of optimized paths "+optimizedPaths.size());

    println("number of points "+totalPoints(optimizedPaths));  
    removeShort(shortestSegment);
    println("number of opt points "+totalPoints(optimizedPaths));
  }
  totalPathLength();

}

void removeShort(float len)
{
  for (int i = 0; i<optimizedPaths.size (); i++)
    optimizedPaths.get(i).removeShort(len);
}

int totalPoints(ArrayList<Path> list)
{
  int total = 0;
  for (int i = 0; i<list.size (); i++)
  {
    total += list.get(i).size();
  }
  return total;
}

void mergePaths(float len, ArrayList <Path> remainingPaths)
{
  Path cur = remainingPaths.get(0);
  optimizedPaths.add(cur);

  for (int i = 1; i<remainingPaths.size (); i++)
  {
    Path p = remainingPaths.get(i);
    if (dist(cur.last().x, cur.last().y, p.first().x, p.first().y) < len)
    {
      cur.merge(p);
    } else
    {
      optimizedPaths.add(p);
      cur = p;
    }
  }
}

Path nearestPath(float x, float y, ArrayList <Path> remainingPaths)
{
  boolean reverse = false;
  double min = Double.MAX_VALUE;
  int index = 0;
  for (int i = remainingPaths.size()-1; i >= 0;i--)     
  {
    Path path = remainingPaths.get(i);
    RPoint first = path.first();
    float sx = first.x;
    float sy = first.y;

    double ds = (x-sx)*(x-sx) + (y-sy)*(y-sy);
    if(ds > min) continue;

    RPoint last = path.last();
    sx = last.x;
    sy = last.y;

    double de =  (x-sx)*(x-sx) + (y-sy)*(y-sy);
    double d = ds+de;
    if (d < min)
    {
      if (de < ds)
        reverse = true;
      else
        reverse = false;
      min = d;
      index = i;
    }
  }

  Path p = remainingPaths.remove(index);
  if (reverse)
    p.reverse();
  return p;
}





