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
			props.setProperty("svg.name",svgName);
			props.setProperty("svg.UserScale",""+svgUserScale);

			props.setProperty("image.pixelSize",""+pixelSize);
			props.setProperty("image.scale",""+imageScale);
			
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

