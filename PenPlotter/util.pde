SortedProperties props = null;
    public static String propertiesFilename = "default.properties.txt";

    public void exportGcode()
    {
        SwingUtilities.invokeLater(new Runnable()
                                   {
                                       public void run() {
                                           JFileChooser fc = new JFileChooser();
                                           if (currentFileName != null)
                                           {
                                               String name = currentFileName;
                                               int dot = currentFileName.indexOf('.');
                                               if (dot > 0)
                                                   name = currentFileName.substring(0, dot)+".gcode";
                                               fc.setSelectedFile(new File(name));
                                           }
                                           fc.setDialogTitle("Export file...");

                                           int returned = fc.showSaveDialog(frame);
                                           if (returned == JFileChooser.APPROVE_OPTION)
                                           {
                                               File file = fc.getSelectedFile();
                                               if(sh != null)
                                                   exportSvg(file);
                                               else if(imageMode == HATCH)
                                                   exportHatch(file);
                                               else if(imageMode == STIPPLE)
                                                   exportStipple(file);
                                           }
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

                props.setProperty("com.baudrate",""+baudRate);
                props.setProperty("com.serialPort",""+lastPort);

                props.setProperty("machine.offX",""+offX);
                props.setProperty("machine.offY",""+offY);
                props.setProperty("machine.zoomScale",""+zoomScale);

                props.setProperty("image.cropLeft",""+cropLeft);
                props.setProperty("image.cropRight",""+cropRight);
                props.setProperty("image.cropTop",""+cropTop);
                props.setProperty("image.cropBottom",""+cropBottom);
                props.setProperty("cnc.safeHeight",""+cncSafeHeight);



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
                                               File file = fc.getSelectedFile();
                                               if (file.getPath().endsWith(".svg"))
                                               {
                                                   sh = loadShapeFromFile(file.getPath());
                                               }
                                               else if (gcodeFile(file.getPath()))
                                               {
                                                   loadGcode(file.getPath());
                                               }
                                               else if (imageFile(file.getPath()))
                                               {
                                                   loadImageFile(file.getPath());
                                                   showImageControls();
                                               }
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