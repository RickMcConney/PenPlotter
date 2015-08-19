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

void setSvgUserScale(float value)
{
	svgUserScale = value;
        imageScale = value;
	//svgValue.setText("Scale "+nf(value,0,2));
}
void clearSvg()
{
	sh = null;
	plotting = false;
	iindex = -1;
	jindex = -1;
	clearQueue();
        optimizedPaths = null;
}

void drawPlottedLine()
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
			float x1 = optimizedPaths.get(i).getPoint(j).x*svgScale*svgUserScale+machineWidth/2+offX;
			float y1 =  optimizedPaths.get(i).getPoint(j).y*svgScale*svgUserScale+homeY+offY;
			float x2 = optimizedPaths.get(i).getPoint(j+1).x*svgScale*svgUserScale+machineWidth/2+offX;
			float y2 =  optimizedPaths.get(i).getPoint(j+1).y*svgScale*svgUserScale+homeY+offY;


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

void plotLine()
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

			float x1 = optimizedPaths.get(iindex).getPoint(jindex).x*svgScale*svgUserScale+machineWidth/2+offX;
			float y1 =  optimizedPaths.get(iindex).getPoint(jindex).y*svgScale*svgUserScale+homeY+offY;
			float x2 = optimizedPaths.get(iindex).getPoint(jindex+1).x*svgScale*svgUserScale+machineWidth/2+offX;
			float y2 =  optimizedPaths.get(iindex).getPoint(jindex+1).y*svgScale*svgUserScale+homeY+offY;


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

void exportSvg(File file)
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

      float x1 = p.getPoint(j).x*svgScale*svgUserScale+offX;
      float y1 =  p.getPoint(j).y*svgScale*svgUserScale+offY;
      float x2 = p.getPoint(j+1).x*svgScale*svgUserScale+offX;
      float y2 =  p.getPoint(j+1).y*svgScale*svgUserScale+offY;


      if(j == 0)
      {
        // pen up
        writer.write("G0 Z5\n");
        writer.write("G0 X"+nf(x1,0,3) +" Y"+nf(y1,0,3)+"\n");
        //pen Down
        writer.write("G0 Z0\n");
      }

      writer.write("G1 X"+nf(x2,0,3) +" Y"+nf(y2,0,3)+"\n");
    }
  }


  float x1 = 0;
  float y1 = 0;

    writer.write("G0 Z5\n");
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

void plotSvg()
{
	if(sh != null)
	{
		plotting = true;
		iindex = 0;
		jindex = 0;
		plotLine();
	}
}

void rotateSvg(int rotation)
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

void drawSvg()
{
	stroke(penColor);
	strokeWeight(0.1);
	noFill();
	for(int i = 0; i<optimizedPaths.size(); i++){
		Path p = optimizedPaths.get(i);
		beginShape();
		for(int j = 0; j<p.size(); j++){
			vertex(scaleX(p.getPoint(j).x*svgScale*svgUserScale+homeX+offX), scaleY(p.getPoint(j).y*svgScale*svgUserScale+homeY+offY));
		}
		endShape();

	}
}


RShape loadShapeFromFile(String filename) {

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

void loadTestFile()
{
	sh = loadShapeFromFile(svgName);
}

void exportGcode()
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

void loadVectorFile()
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
boolean gcodeFile(String filename)
{
	if(filename.endsWith(".gco") || filename.endsWith(".g") ||
			filename.endsWith(".nc") || filename.endsWith(".cnc") ||
			filename.endsWith(".gcode"))
		return true;
	return false;
}
boolean imageFile(String filename)
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

void optimize()
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


}

void removeShort(float len)
{
	for(int i = 0;i<optimizedPaths.size();i++)
		optimizedPaths.get(i).removeShort(len);
}

int totalPoints(ArrayList<Path> list)
{
	int total = 0;
	for(int i = 0;i<list.size();i++)
	{
		total += list.get(i).size();
	}
	return total;
}

void mergePaths(float len)
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



Path nearestPath(float x, float y)
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



