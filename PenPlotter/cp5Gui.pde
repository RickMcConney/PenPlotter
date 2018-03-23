 DropdownList connectDropList;
    DropdownList filterDropList;
    Textlabel myTextarea;
    int leftMargin = 10;
    int posY = 10;
    int ySpace = 36;

    Slider pixelSizeSlider;
    Slider speedSlider;
    Slider scaleSlider;
    Slider penSlider;

    Slider t1Slider;
    Slider t2Slider;
    Slider t3Slider;
    Slider t4Slider;

    PImage penUpImg;
    PImage penDownImg;
    PImage loadImg;
    PImage clearImg;
    PImage pauseImg;
    PImage plotImg;
    PImage stepImg;
    PImage nodrawImg;
    PImage drawImg;
    
    MyButton loadButton;
    MyButton plotButton;
    MyButton penUpButton;
    MyButton noDrawButton;
    
    String[] filters = {"Hatch","Diamond","Square","Stipple"};

    class MyButton extends Button {
        public PImage img;

        MyButton(ControlP5 cp5, String theName) {
            super(cp5, theName);
        }
        public void setImg(PImage img)
        {
            this.img = img;
        }
    }

    public MyButton addButton(String name, String label, int x, int y)
    {

        PImage img = loadImage("icons/"+name+".png");
        MyButton b = new MyButton(cp5, name);
        b.setPosition(x, y)
                .setSize(menuWidth, 30)
                .setCaptionLabel(label)
                .setView(new myView())
        ;

        b.setImg(img);
        b.getCaptionLabel().setFont(createFont("", 10));
        return b;
    }

    public Slider addSlider(int x, int y, String name, String label, float min, float max, float value)
    {
        Slider s = cp5.addSlider(name)
                .setCaptionLabel(label)
                .setPosition(x, y)
                .setSize(menuWidth, 17)
                .setRange(min, max)
                .setColorBackground(buttonUpColor)
                .setColorActive(buttonHoverColor)
                .setColorForeground(buttonHoverColor)
                .setColorCaptionLabel(buttonTextColor)
                .setColorValue(buttonTextColor)
                .setScrollSensitivity(1)
                .setValue(value)
                ;
        controlP5.Label l = s.getCaptionLabel();
        l.getStyle().marginTop = 0;
        l.getStyle().marginLeft = -(int)textWidth(label);
        return s;
    }


    class myView implements ControllerView<Button> {

        public void display(PGraphics theApplet, Button theButton) {


            theApplet.pushMatrix();
            if (theButton.isInside() ) {
                if (theButton.isPressed()) { // button is pressed
                    theApplet.fill(buttonPressColor);
                } else { // mouse hovers the button
                    theApplet.fill(buttonHoverColor);
                }
            } else { // the mouse is located outside the button area
                theApplet.fill(buttonUpColor);
            }

            stroke(buttonBorderColor);
            strokeWeight(0.5f);

            theApplet.rect(0, 0, theButton.getWidth(), theButton.getHeight(), 8);


            // center the caption label
            int x = theButton.getWidth()/2 - theButton.getCaptionLabel().getWidth()/2-10;
            int y = theButton.getHeight()/2 - theButton.getCaptionLabel().getHeight()/2;

            translate(x, y);
            theButton.getCaptionLabel().setColor(buttonTextColor);
            theButton.getCaptionLabel().draw(theApplet);

            translate(-x, -y);
            PImage img = ((MyButton)theButton).img;
            if (img != null)
            {
                if ("".equals(theButton.getCaptionLabel().getText()))
                    theApplet.image(img, theButton.getWidth()/2-16, -3, 32, 32);
                else
                    theApplet.image(img, theButton.getWidth()-34, 0, 32, 32);
            }
            theApplet.popMatrix();
        }
    }


    public void createcp5GUI()
    {

        cp5 = new ControlP5(this);
      //  cp5.addFrameRate().setInterval(10).setPosition(0,height - 10).setColorValue(color(0));
        penUpImg= loadImage("icons/penUp.png");
        penDownImg= loadImage("icons/penDown.png");
        loadImg= loadImage("icons/load.png");
        clearImg= loadImage("icons/clear.png");
        pauseImg = loadImage("icons/pause.png");
        plotImg = loadImage("icons/plot.png");
        stepImg = loadImage("icons/right.png");
        nodrawImg = loadImage("icons/nodraw.png");
        drawImg = loadImage("icons/draw.png");

        connectDropList = cp5.addDropdownList("dropListConnect")
                .setPosition(leftMargin, posY)
                .setCaptionLabel("Disconnected")
                .onEnter(toFront)
                .onLeave(close)
                .setBackgroundColor(buttonUpColor)
                .setColorBackground(buttonUpColor)
                .setColorForeground(buttonHoverColor)
                .setColorActive(buttonHoverColor)
                .setColorCaptionLabel(buttonTextColor)
                .setColorValue(buttonTextColor)
                .setItemHeight(20)
                .setBarHeight(20)
                .setSize(menuWidth,(com.comPorts.size()+1)*20)
                .setOpen(false)
                .addItems(com.comPorts)
        ;

        filterDropList = cp5.addDropdownList("filterDropList")
                .setPosition(imageX+20, imageY+imageHeight+20)
                .setCaptionLabel("Hatch")
                .onEnter(toFront)
                .onLeave(close)
                .setBackgroundColor(buttonUpColor)
                .setColorBackground(buttonUpColor)
                .setColorForeground(buttonHoverColor)
                .setColorActive(buttonHoverColor)
                .setColorCaptionLabel(buttonTextColor)
                .setColorValue(buttonTextColor)
                .setItemHeight(20)
                .setBarHeight(20)
                .setSize(menuWidth, 20 * 5)
                .setOpen(false)
                .addItems(filters)
        ;

        myTextarea = cp5.addTextlabel("txt")
                .setPosition(leftMargin, posY+=20)
                .setSize(menuWidth, 30)
                .setFont(createFont("", 10))
                .setLineHeight(14)
                .setColor(textColor)
                .setColorBackground(gridColor)
                .setColorForeground(textColor)
        ;

        addButton("setHome", "Set Home", leftMargin, posY += ySpace / 2);
        addButton("up", "", leftMargin+36, posY+=ySpace+4).onPress(press).onRelease(release).setSize(30, 24);
        addButton("left", "", leftMargin+16, posY+=30).onPress(press).onRelease(release).setSize(30, 24);
        addButton("right", "", leftMargin+56, posY).onPress(press).onRelease(release).setSize(30, 24);

        addButton("down", "", leftMargin+36, posY+=30).onPress(press).onRelease(release).setSize(30, 24);

        loadButton = addButton("load", "Load", leftMargin, posY+=ySpace);
        plotButton = addButton("plot", "Plot", leftMargin, posY+=ySpace);
        addButton("dorotate", "Rotate", leftMargin, posY+=ySpace);
        addButton("mirrorX","Flip X",leftMargin,posY+=ySpace);
        addButton("mirrorY","Flip Y",leftMargin,posY+=ySpace);


        scaleSlider = addSlider(leftMargin,posY += ySpace+10,"scale", "SCALE", 0.1f, 5, userScale);

        speedSlider = addSlider(leftMargin,posY += ySpace/2,"speedChanged", "SPEED", 100, 6000, 500);
        speedSlider.onRelease(speedrelease)
                .onReleaseOutside(speedrelease);

        pixelSizeSlider = addSlider(imageX+20,imageY+imageHeight+60,"pixelSlider", "PIXEL SIZE", 2, 16, pixelSize);

        penSlider = addSlider(imageX+20,imageY+imageHeight+60+ySpace/2,"penWidth", "PEN WIDTH", 0.1f, 5, 0.5f);
        penSlider.onRelease(penrelease)
                .onReleaseOutside(penrelease);
        t1Slider = addSlider(imageX+20,imageY+imageHeight+60+ySpace/2,"t1", "T1 \\", 0, 255, 192).onRelease(thresholdrelease).onReleaseOutside(thresholdrelease);
        t2Slider = addSlider(imageX+20,imageY+imageHeight+60+2*ySpace/2,"t2", "T2 /", 0, 255, 128).onRelease(thresholdrelease).onReleaseOutside(thresholdrelease);
        t3Slider = addSlider(imageX+20,imageY+imageHeight+60+3*ySpace/2,"t3", "T3 |", 0, 255, 64).onRelease(thresholdrelease).onReleaseOutside(thresholdrelease);
        t4Slider = addSlider(imageX+20,imageY+imageHeight+60+4*ySpace/2,"t4", "T4 -", 0, 255, 32).onRelease(thresholdrelease).onReleaseOutside(thresholdrelease);

        penUpButton = addButton("penUp", "Pen Up", leftMargin, posY+=ySpace);

        addButton("goHome", "Go Home", leftMargin, posY+=ySpace);
        addButton("off", "Motors Off", leftMargin, posY+=ySpace);
        addButton("save", "Save", leftMargin, posY+=ySpace);
        addButton("export", "Export",leftMargin, posY+=ySpace);
        noDrawButton = addButton("nodraw", "No Draw",leftMargin, posY+=ySpace);

        stipplePlot.init();

        hideImageControls();
        showPenDown();

    }

    public void hideImageControls()
    {

        filterDropList.setVisible(false);
        pixelSizeSlider.setVisible(false);
        t1Slider.setVisible(false);
        t2Slider.setVisible(false);
        t3Slider.setVisible(false);
        t4Slider.setVisible(false);
        penSlider.setVisible(false);

        stipplePlot.hideControls();

    }

    CallbackListener toFront = new CallbackListener() {
        public void controlEvent(CallbackEvent theEvent) {
            theEvent.getController().bringToFront();
            ((DropdownList)theEvent.getController()).open();
        }
    };

    CallbackListener close = new CallbackListener() {
        public void controlEvent(CallbackEvent theEvent) {
            ((DropdownList)theEvent.getController()).close();
        }
    };

    CallbackListener press = new CallbackListener() {
        public void controlEvent(CallbackEvent theEvent) {
            Button b = (Button)theEvent.getController();
            if (b.getName().equals("left"))
                jog(true, -1, 0);
            else if (b.getName().equals("right"))
                jog(true, 1, 0);
            else if (b.getName().equals("up"))
                jog(true, 0, -1);
            else if (b.getName().equals("down"))
                jog(true, 0, 1);
        }
    };

    CallbackListener release = new CallbackListener() {
        public void controlEvent(CallbackEvent theEvent) {
            Button b = (Button)theEvent.getController();
            if (b.getName().equals("left"))
                jog(false, 0, 0);
            else if (b.getName().equals("right"))
                jog(false, 0, 0);
            else if (b.getName().equals("up"))
                jog(false, 0, 0);
            else if (b.getName().equals("down"))
                jog(false, 0, 0);
        }
    };

    CallbackListener speedrelease = new CallbackListener() {
        public void controlEvent(CallbackEvent theEvent) {
            setSpeed((int)speedSlider.getValue());
        }
    };

    CallbackListener thresholdrelease = new CallbackListener() {
        public void controlEvent(CallbackEvent theEvent) {
            currentPlot.calculate();
        }
    };

    CallbackListener penrelease = new CallbackListener() {
        public void controlEvent(CallbackEvent theEvent) {
            setPenWidth(penSlider.getValue());
        }
    };

    public void controlEvent(ControlEvent theEvent) {

       if (theEvent.isController()) {
            //println("event from controller : "+theEvent.getController().getValue()+" from "+theEvent.getController());

            if (("" + theEvent.getController()).contains("dropListConnect"))
            {
                Map m = connectDropList.getItem((int)theEvent.getController().getValue());
                println(m.get("name"));
                com.connect((String) m.get("name"));
            }
            else if (("" + theEvent.getController()).contains("filterDropList"))
            {
                imageMode = (int)theEvent.getController().getValue();
                println("Image Mode = " + imageMode);

                if(imageMode == DIAMOND)
                    currentPlot = diamondPlot;
                else if(imageMode == HATCH)
                    currentPlot = hatchPlot;
                else if(imageMode == SQUARE)
                    currentPlot = squarePlot;
                else if(imageMode == STIPPLE)
                {
                    currentPlot = stipplePlot;
                    currentPlot.load();
                }

                hideImageControls();
                currentPlot.showControls();
                currentPlot.reset();
                currentPlot.calculate();
            }
        }
    }


    public void setHome()
    {
        com.sendHome();
    }

    public void plotDone()
    {
        plotButton.setCaptionLabel("Plot");
        plotButton.setImg(plotImg);
    }

    public void fileLoaded() {
        loadButton.setCaptionLabel("Clear");
        loadButton.setImg(clearImg);
    }

    public void load(ControlEvent theEvent)
    {
        Button b = (Button) theEvent.getController();

        if (b.getCaptionLabel().getText().startsWith("Load"))
        {
            loadVectorFile();
        } else
        {
            hideImageControls();
            currentPlot.clear();

            goHome();
            b.setCaptionLabel("Load");
            ((MyButton)b).setImg(loadImg);
        }
    }

    public void plot(ControlEvent theEvent)
    {
        Button b = (Button) theEvent.getController();
        if (b.getCaptionLabel().getText().contains("Step")) {

            if (currentPlot.isPlotting())
                currentPlot.nextPlot(true);
            else
            {
                b.setCaptionLabel("Plot");
                ((MyButton)b).setImg(plotImg);
            }
        }
        else if (b.getCaptionLabel().getText().contains("Abort"))
        {
            b.setCaptionLabel("Plot");
            ((MyButton)b).setImg(plotImg);
            currentPlot.reset();
        }
        else
        {
            if (currentPlot.isLoaded())
                currentPlot.plot();

            if(currentPlot.isPlotting() )
            {
                if (com.myPort == null)
                {
                    b.setCaptionLabel("Step");
                    ((MyButton)b).setImg(stepImg);
                }
                else
                {
                    b.setCaptionLabel("Abort");
                    ((MyButton)b).setImg(pauseImg);
                }
            }
        }
    }

    public void dorotate()
    {
        currentPlot.rotate();
    }

    public void mirrorX()
    {
        flipX *= -1;
        updateScale();
        currentPlot.flipX();
    }
    public void mirrorY()
    {
        flipY *= -1;
        updateScale();
        currentPlot.flipY();
    }
    public void showPenUp()
    {
        penUpButton.setCaptionLabel("Pen Up");
        penUpButton.setImg(penDownImg);
    }

    public void showPenDown()
    {
        penUpButton.setCaptionLabel("Pen Down");
        penUpButton.setImg(penUpImg);
    }

    public void penUp(ControlEvent theEvent)
    {
        Button b = (Button) theEvent.getController();

        if (b.getCaptionLabel().getText().indexOf("Up") > 0)
        {
            com.sendPenUp();
        } else
        {
            com.sendPenDown();
        }
    }
    
    public void nodraw(ControlEvent theEvent)
    {
      Button b = (Button) theEvent.getController();
      if(b.getCaptionLabel().getText().indexOf("No") >=0)
      {
          noDrawButton.setCaptionLabel("Draw");
          noDrawButton.setImg(drawImg);
          draw = false;
      }
      else
      {
          noDrawButton.setCaptionLabel("No Draw");
          noDrawButton.setImg(nodrawImg);
          draw = true;
      }
    }

    public void goHome()
    {
        com.sendAbsolute();
        com.sendPenUp();
        com.sendMoveG0(homeX, homeY);
    }

    public void off()
    {
        com.sendMotorOff();
    }

    public void save()
    {
        saveProperties();
    }

    public void export()
    {
        if(currentPlot.isLoaded())
          exportGcode();
    }

    public void speedChanged(int speed)
    {
        int s = (speed/10)*10;
        if (s != speed)
            speedSlider.setValue(s);
    }

    public void penWidth(float width)
    {
        int w = (int)(width*10);
        float f = ((float)w)/10;
        if (f != width)
            penSlider.setValue(f);
    }

    public void pixelSlider(int size)
    {
        setPixelSize(size);
    }

    public void scale(float scale)
    {
        setuserScale(scale);
    }

    public void jog(boolean jog, int x, int y)
    {
        if (jog) {
            com.sendRelative();
            jogX = x;
            jogY = y;
        } else
        {
            com.sendAbsolute();
            jogX = 0;
            jogY = 0;
        }
    }