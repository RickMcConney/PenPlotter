SortedProperties props = null;
public static String propertiesFilename = "default.properties.txt";

void saveProperties() {

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
			props.setProperty("svg.name",currentFileName);
			props.setProperty("svg.UserScale",""+userScale);

			props.setProperty("image.pixelSize",""+pixelSize);
			
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


Properties getProperties()
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

void loadVectorFile()
{

  SwingUtilities.invokeLater(new Runnable() 
  {
    public void run() {
      JFileChooser fc = new JFileChooser();
      fc.setFileFilter(new VectorFileFilter());
      if (currentFileName != null)
        fc.setSelectedFile(new File(currentFileName));
      fc.setDialogTitle("Choose a vector file...");

      int returned = fc.showOpenDialog(frame);
      if (returned == JFileChooser.APPROVE_OPTION) 
      {
        File file = fc.getSelectedFile();
        if (file.getPath().endsWith(".svg"))
          sh = loadShapeFromFile(file.getPath());
        else if (gcodeFile(file.getPath()))
          loadGcode(file.getPath());
        else if (imageFile(file.getPath()))
          loadImageFile(file.getPath());
        currentFileName = file.getPath();
        fileLoaded();
      }
    }
  }
  );
}

boolean gcodeFile(String filename)
{
  if (filename.endsWith(".gco") || filename.endsWith(".g") ||
    filename.endsWith(".nc") || filename.endsWith(".cnc") ||
    filename.endsWith(".gcode"))
    return true;
  return false;
}
boolean imageFile(String filename)
{
  if (filename.endsWith(".png") || filename.endsWith(".jpg") ||
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
    return "Plote files (SVG, GCode, Image)";
  }
}

