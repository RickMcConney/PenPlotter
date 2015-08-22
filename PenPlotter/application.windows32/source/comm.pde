Serial myPort;  //the Serial port object
String val;
ArrayList<String> buf = new ArrayList<String>();

ArrayList<String> comPorts = new ArrayList<String>();
long baudRate = 115200;
int lastPort;
int okCount = 0;

public void listPorts()
{
  //  initialize your serial port and set the baud rate to 9600

  comPorts.add("Connect");
  comPorts.add("Disconnect");

  for (int i = 0; i<Serial.list().length; i++)
  {
    String name = Serial.list()[i];
    int dot = name.indexOf('.');
    if (dot >= 0)
      name = name.substring(dot+1);
    if(name.indexOf("luetooth") <0) 
    {
        comPorts.add(name);
        println(name);
    }
  }
}
void disconnect()
{
  clearQueue();
  if (myPort != null)
    myPort.stop();
  myPort = null;
  //  myTextarea.setVisible(false);
}
void connect(int port)
{
  clearQueue();
  try {
    myPort = new Serial(this, Serial.list()[port], (int)baudRate);
    lastPort = port;
    //      myTextarea.setVisible(true);
  }
  catch(Exception exp)
  {
    println("Failed to open serial port");
  }
}

void connect(String name)
{
  for (int i = 0; i<Serial.list().length; i++)
  {
    if (Serial.list()[i].indexOf(name) >=0)
    {
      connect(i);
      return;
    }
  }
  disconnect();
}
void sendMotorOff()
{
  send("M84\n");
}
void moveDeltaX(float x)
{
  send("G0 X"+x+"\n");
}

void moveDeltaY(float y)
{
  send("G0 Y"+y+"\n");
}
void sendMoveG0(float x, float y)
{
  send("G0 X"+x+" Y"+y+"\n");
}

void sendMoveG1(float x, float y)
{
  send("G1 X"+x+" Y"+y+"\n");
}

void sendG2(float x, float y,float i, float j)
{
  send("G2 X"+x+" Y"+y+" I"+i+" J"+j+"\n");
}

void sendG3(float x, float y,float i, float j)
{
  send("G3 X"+x+" Y"+y+" I"+i+" J"+j+"\n");
}

void sendSpeed(int speed)
{
    send("G0 F"+speed+"\n");
}

void sendHome()
{
  send("M1 Y"+homeY+"\n");
}

void sendSpeed()
{
  send("G0 F"+speedValue+"\n");
}

void sendPenWidth()
{
  send("M4 E"+penWidth+"\n");
}

void sendSpecs()
{
  send("M4 X"+machineWidth+" E"+penWidth+" S"+stepsPerRev+" P"+mmPerRev+"\n");
}

void sendPenUp()
{
  send("G4 P250\n");
  send("M340 P3 S2350\n");
  send("G4 P250\n");
}

void sendPenDown()
{
  send("G4 P250\n");
  send("M340 P3 S1500\n");
  send("G4 P250\n");
}
void sendAbsolute()
{
    send("G90\n");
}

void sendRelative()
{
    send("G91\n");
}

void sendPixel(float da,float db,int pixelSize,int shade,int pixelDir)
{
  send("M3 X"+da+" Y"+db+" P"+pixelSize+" S"+shade+" E"+pixelDir+"\n");
}

void sendSqPixel(float x,float y,int size,int b)
{
  //todo 
   send("M2 X"+x+" Y"+y+" P"+size+" S"+b+"\n");
}
    
void initArduino()
{
  sendHome();
  sendSpeed();
  sendSpecs();
}

public void clearQueue()
{
  buf.clear();
  okCount = 0;
}
public void queue(String msg)
{
  print("Q "+msg);
  buf.add(msg);
}

public void nextMsg()
{
  if (buf.size() > 0)
  {
    String msg = buf.get(0);
    //print("sending "+msg);
    oksend(msg);
    buf.remove(0);
  } else
  {
    if (plottingSvg)
      plotLine();
    if (plottingImage)
      plotNextDiamondPixel();
    if (plottingGcode)
      nextGcode();
  }
}
public void send(String msg)
{
  if (okCount >=0)
    oksend(msg);
  else
    queue(msg);
}

public void oksend(String msg)
{
  okCount--;
  print(msg);

  if (myPort != null)
  {
    if (msg.indexOf("G") >= 0)
      motorsOn = true;
    else if (msg.indexOf("M84") >=0)
      motorsOn = false;

    myPort.write(msg);
    myTextarea.setText(" "+msg);
  }
}

void serialEvent( Serial myPort) {

  if (myPort == null || myPort.available() <=0) return;

  val = myPort.readStringUntil('\n');
  if (val != null) {
    val = trim(val);

    if (val.indexOf("wait") >= 0)
      okCount = 0;
    else               
      println(val);
    String[] tokens = val.split(" ");
    if (tokens[0].startsWith("Free"))
    {
      initArduino();
      okCount++;
      nextMsg();
    }

    if (tokens[0].startsWith("ok"))
    {
      okCount++;
      nextMsg();
    }
  }
}

