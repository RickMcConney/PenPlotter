SortedProperties props = null;

JFileChooser fc;

     String propertiesFilename = "default.properties.txt";

   
    
 class MyExtensionFileFilter extends FileFilter
 {
   String description;
   String ext;
   
    public MyExtensionFileFilter(String description,String ext)
    {
      this.description = description;
      this.ext = ext;
    }
    public String getDescription() {
      return description;
    }
     
    public boolean accept(File f) {
      if (f.isDirectory()) {
      return true;
      } else {
      return f.getName().toLowerCase().endsWith(ext);
      }
    }
    public String getExtension()
    {
      return ext;
    }
 }
                                        
    public class MyFileChooser extends JFileChooser {
    private File file = new File("");
    private String name;
    
    public String getName()
    {
      return name;
    }
    
    

    public MyFileChooser(String name) {
        this.name = name;
        addPropertyChangeListener(JFileChooser.FILE_FILTER_CHANGED_PROPERTY, new PropertyChangeListener() {
            public void propertyChange(PropertyChangeEvent e) {
              String filename = MyFileChooser.this.getName();
               if(MyFileChooser.this.getSelectedFile() != null)
               {
                 filename = MyFileChooser.this.getSelectedFile().getName();
               }
                String extnew = null;
  
                if (e.getNewValue() == null || !(e.getNewValue() instanceof MyExtensionFileFilter)) {
                    return;
                }

                MyExtensionFileFilter newValue = ((MyExtensionFileFilter) e.getNewValue());
                extnew = newValue.getExtension();
              
                String name = filename;
                 int dot = filename.indexOf('.');
                 if (dot > 0)
                     name = filename.substring(0, dot);
                name+=extnew;
                setSelectedFile(new File(name));
            }
        });
    }

    @Override
    public void setSelectedFile(File file) {
        super.setSelectedFile(file);
        if(getDialogType() == SAVE_DIALOG) {
            if(file != null) {
                super.setSelectedFile(file);
                this.file = file;
            }
        }
    }

    @Override
    public void approveSelection() { 
        if(getDialogType() == SAVE_DIALOG) {
            File f = getSelectedFile();  
            if (f.exists()) {  
                String msg = "Replace File?";  
                msg = MessageFormat.format(msg, new Object[] { f.getName() });  
                int option = JOptionPane.showConfirmDialog(this, msg, "", JOptionPane.YES_NO_OPTION);
                if (option == JOptionPane.NO_OPTION ) {  
                    return;  
                }
            }
            String ext = ".gcode";
            if(getFileFilter() instanceof MyExtensionFileFilter)
            {
               ext = ((MyExtensionFileFilter)getFileFilter()).getExtension();
            }
            println("export "+ext);
            Com oldcom = com;
            com = new Export(ext);
            com.export(f);
            com = oldcom;

        }
        super.approveSelection();   
    }

    @Override
    public void setVisible(boolean visible) {
        super.setVisible(visible);
        if(!visible) {
            resetChoosableFileFilters();
        }
    }
}

    
    public void exportGcode()
    {
        SwingUtilities.invokeLater(new Runnable()
                                   {
                                       public void run() {
                                         String name = currentFileName;
                                               int dot = currentFileName.indexOf('.');
                                               if (dot > 0)
                                                   name = currentFileName.substring(0, dot)+".gcode";
                                           fc = new MyFileChooser(name);
                                           if (currentFileName != null)
                                           {
                                               fc.setSelectedFile(new File(name));
                                           }
                                           fc.setDialogTitle("Export file...");
                                           fc.setAcceptAllFileFilterUsed(false);
                                           fc.addChoosableFileFilter(new MyExtensionFileFilter("PEN Plotter gcode",".gcode"));
                                           fc.addChoosableFileFilter(new MyExtensionFileFilter("CNC gcode",".cnc"));
                                           
                                           fc.showSaveDialog(frame);

                                       }
                                   }
        );
    }

    public void saveProperties() {

        if(props == null)
            props = new SortedProperties();

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
            props.setProperty("svg.shortestSegment",""+shortestSegment);

            props.setProperty("image.pixelSize",""+pixelSize);

            props.setProperty("com.baudrate",""+com.baudRate);
            props.setProperty("com.serialPort",""+com.lastPort);

            props.setProperty("machine.offX",""+offX);
            props.setProperty("machine.offY",""+offY);
            props.setProperty("machine.zoomScale",""+zoomScale);

            props.setProperty("image.cropLeft",""+cropLeft);
            props.setProperty("image.cropRight",""+cropRight);
            props.setProperty("image.cropTop",""+cropTop);
            props.setProperty("image.cropBottom",""+cropBottom);
            props.setProperty("cnc.safeHeight",""+cncSafeHeight);
            props.setProperty("servo.dwell",""+servoDwell);
            props.setProperty("servo.upValue",""+servoUpValue);
            props.setProperty("servo.downValue",""+servoDownValue);
            

            String fileToSave = sketchPath(propertiesFilename);
            File f = new File(fileToSave);
            OutputStream out = new FileOutputStream( f );
            props.store(out, "Polar Properties");
            out.close();
            println("Saved Properties "+propertiesFilename);
        }
        catch (Exception e ) {
            e.printStackTrace();
            println(e);
        }
    }


    public Properties getProperties()
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
                }
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

    public void loadVectorFile()
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
                                               scaleSlider.setValue(1);
                                               userScale = 1;
                                               flipX = 1;
                                               flipY = 1;
                                               updateScale();
                                               offX = 0;
                                               offY = 0;
                                               File file = fc.getSelectedFile();
                                               if (file.getPath().endsWith(".svg"))
                                               {
                                                   currentPlot = new SvgPlot();
                                               }
                                               else if (gcodeFile(file.getPath()))
                                               {
                                                   currentPlot = new GcodePlot();
                                               }
                                               else if (imageFile(file.getPath()))
                                               {
                                                   if(imageMode == HATCH)
                                                       currentPlot = hatchPlot;
                                                   else if(imageMode == DIAMOND)
                                                       currentPlot = diamondPlot;
                                                   else if(imageMode == SQUARE)
                                                       currentPlot = squarePlot;
                                                   else
                                                       currentPlot = stipplePlot;
                                               }
                                               currentPlot.load(file.getPath());
                                               currentPlot.showControls();
                                               currentFileName = file.getPath();
                                               fileLoaded();
                                           }
                                       }
                                   }
        );
    }

    public boolean gcodeFile(String filename)
    {
        return filename.endsWith(".gco") || filename.endsWith(".g") ||
                filename.endsWith(".nc") || filename.endsWith(".cnc") ||
                filename.endsWith(".gcode");
    }

    public boolean imageFile(String filename)
    {
        return filename.endsWith(".png") || filename.endsWith(".jpg") ||
                filename.endsWith(".gif") || filename.endsWith(".tga");
    }

    class VectorFileFilter extends javax.swing.filechooser.FileFilter
    {
        public boolean accept(File file) {
            String filename = file.getName();
            filename = filename.toLowerCase();
            return file.isDirectory() || filename.endsWith(".svg") || gcodeFile(filename) || imageFile(filename);
        }
        public String getDescription() {
            return "Plote files (SVG, GCode, Image)";
        }
    }

    public float getCartesianX(float aPos, float bPos) {
        return (machineWidth * machineWidth - bPos * bPos + aPos * aPos) / (machineWidth * 2);
    }

    public float getCartesianY(float cX, float aPos) {
        return sqrt(aPos * aPos - cX * cX);
    }

    public float getMachineA(float cX, float cY) {
        return sqrt(cX * cX + cY * cY);
    }

    public float getMachineB(float cX, float cY) {
        return sqrt(sq((machineWidth - cX)) + cY * cY);
    }
