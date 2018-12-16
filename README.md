# PenPlotter
PenPlotter controller that uses repetier firmware. Inspired by work at http://www.polargraph.co.uk

I built a plotter like the one described on the polargraph site. I thought it would be a good way to play around with stepper motor control. The software provided by the site worked great, but I wanted to play around with creating my own version to better understand the controls.

First I decided to use the repetier 3d printer control firmware https://github.com/repetier/Repetier-Firmware as a base. As I used this for the 3d Printer I built. It provides very smooth motor control with good path planning so the drawing is much smoother. I modified the firmware to support the polar coordinates. The firmware uses standard gcodes with mm units, while the original controller uses a custom command set and native polar coordinates.  So the original controller was not going to talk with the new firmware.

Next I wrote a simpler version of the controller that speaks gcode and uses mm units. Here is a list of some of the features of the controller.

Solenoid or servo can be used. Solenoid are connected to FAN pins.

# Features
- Supports Gcode files (.gcode, .cnc, .nc, .g, .gco)
  - Standard Gcodes G0, G1, G2, G3 are supported for movement.
  - Standard M340 and G4 are used for servo control and dwell (wait for servo to lift lower pen).
  - Standard M84 is used to disable motors
  - Custom Gcode M1 Y is used to set the home Y position in mm.
  - Custom Gcode M3 X Y P S E to plot a pixel.
    - X is delta x from last pixel
    - Y is delta y from last pixel
    - P is pixel size
    - S is shade
    - E is direction
  - Custom Gcode M4 X E S P to set the machine specs
    - X is machine width
    - E is pen Width
    - S is steps per rev
    - P is mm per Rev
  - When processing a gcode file the pen lift is triggered by the G0 gcode G1 will lower the pen

- Supports SVG files (.svg)
  - When processing a SVG file disconnected paths trigger a pen lift. 
  - The SVG paths are optimized to try and avoid needless moves.
  - The optimizer will auto join paths that touch.
  - The optimizer will remove very short lines in a path
  - Svg files can be scaled and rotated by multiples of 90 degrees
  - Svg files can be flipped about the X or Y axis
- Supports Image files (.jpg, .png, .tga, .gif)
  - The image preview shows how the pixel size and pen width will affect the plot.
  - Images can be cropped, scaled and rotated by multiples of 90 degrees
  - Images can be flipped about the X or Y axis
  - Four image styles are supported
    - Hatch: a cross hatch style similar to blackstripes
    - Diamond: Diamond shaped pixels similar to the original poloar graph
    - Square: Simple square wave pixes. 
    - Stipple: Stippled similar to stipplegen program. You need to pause the stipple generation before plotting or exporting.
- Export
  - All formats (except Diamond) can be exported to standard gcode files.
  - Comments are added to the export file to indicate the original file name and image settings.
- The controller runs in processing 2 or processing 3

#Compiling
The controller can be compiled in processing 2 or 3 just download the source files and open PenPlotter.pde in processing.
The code is dependent of the controlP5, geomerative and toxi libraries go to the processing sketch import library menu to import them before compiling, or they can be added manually by downloading the libraries.zip file from the releases tab and unziping in the processing libraries directory.

The firmware is compiled using the arduino IDE. Download the code and load the Repitier.ino into arduino. I have only tested with the mega board with the ramps 1.4 shield. However repetier works with many boards so you may need to change the board type in the configuration.h file if you are using a different board.

*WARNING* The X axis pins were chaged in the Marlin pins.h file to use the E1 port this was for compatibility with the original pen plotter pins. So you need to connect the X axis motor to the E1 port or change the pins back in the pins.h file line 596-616 remove the pin numbers to leave the original commented pins.

*WARNING* I changed the X Y and ZAXIS_STEPS_PER_MM defines in the configuragion.h to 1mm as I do my own mm to polar conversion based on the machine specs described above so make sure if you change boards the setting remains at 1.

#Usage
- Load the firmware on arduino board.
- Make sure once loaded that you disconnect the arduino IDE before trying to connect the controller.
- Edit the default.properties.txt file in the controller’s home directory and change the following settings to match your plotter. (Sorry I did not include the ability to change this in the GUI)
  - machine.motors.mmPerRev=80.0
  - machine.motors.stepsPerRev=6400.0  
- Launch the controller 
- Connect the controller to the board using the connect menu (select the same com port the arduino IDE was using)
- Manually position the gondola over the home point and hit the set Home button to sync the controllers and plotters home location.
- Load a file with the load button, the file extension determines the type so make sure it is one of the supported types
- Adjust the scale 
- Hit the plot button to start plotting.
- You can save any changes with the save button, all changes are saved to the defaults.properties.txt file

#Not so obvious GUI controls 
-	There is a status line right under the connect menu that shows the last command sent to the plotter
-	The little blue circles at the top represent the motors and will go red when the motors are powered. Hit motor off button to idle the motors.
-	The little square control handles can be dragged to change the Y position and machine width and height.
-	The paper size can be changed with the control handles on the edges of the paper.
-	The gondola can be dragged around the page and the plotter will move to the new point when the mouse is released.
-	You can adjust the placement of the plot on the page by dragging on the page canvas with the right mouse button down.
-	You can scale the page view with the scroll wheel.
-	You can move the whole page by dragging with the scroll wheel pressed.
-	You can crop an image with the green handles around the image frame.
-	You can hit the 'c' key to open a debug console, usefull to capture and report any exceptions.

#Screen shots
Here are some screen shots of the controler.

![Svg Plot](/ScreenShots/svgScreenShot.png?raw=true)

![Hatch Plot](/ScreenShots/hatch.png?raw=true)

![Stipple Plot](/ScreenShots/stipple.png?raw=true)


