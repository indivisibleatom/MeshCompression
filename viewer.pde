//*********************************************************************
//**      SURGEM : baffle design and stitching                        **
//**              Jarek Rossignac, November 2012                      **   
//*********************************************************************
import processing.opengl.*;                // load OpenGL libraries and utilities
import javax.media.opengl.*; 
import javax.media.opengl.glu.*; 
import java.nio.*;
import java.util.*;
GL gl; 
GLU glu; 

// ****************************** GLOBAL VARIABLES FOR DISPLAY OPTIONS *********************************
Boolean showMesh=true, labels=false, 
        showHelpText=false, showLeft=true, showRight=true, showBack=false, showMiddle=false, showBaffle=false; // display modes
   
RingExpander R;
int nsteps=250;

SimplificationController g_controller;

/*float s=10; // scale for drawing cutout
float a=0, dx=0, dy=0;   // angle for drawing cutout
float sd=10; // samp[le distance for cut curve
pt sE = P(), sF = P(); vec sU=V(); //  view parameters (saved with 'j'*/

// *******************************************************************************************************************    SETUP
void setup() {
  size(1200, 600, OPENGL); // size(500, 500, OPENGL);  
  setColors(); sphereDetail(3); 
  PFont font = loadFont("GillSans-24.vlw"); textFont(font, 20);  // font for writing labels on 
  
  glu= ((PGraphicsOpenGL) g).glu;  PGraphicsOpenGL pgl = (PGraphicsOpenGL) g;  gl = pgl.beginGL();  pgl.endGL();
  
  g_controller = new SimplificationController(); //The controlling object for the project
}
  
// ******************************************************************************************************************* DRAW      
void draw() {  
  background(white);
  g_controller.viewportManager().draw();
 } // end draw
 
 // ****************************************************************************************************************************** INTERRUPTS
Boolean pressed=false;
void mousePressed() {
  g_controller.viewportManager().onMousePressed();
  }
  
void mouseDragged() {
  g_controller.viewportManager().onMouseDragged();
  }

void mouseReleased() {
  }
  
void keyReleased() {
   g_controller.viewportManager().onKeyReleased();
   } 

 
void keyPressed() {
   g_controller.onKeyPressed();
  } 
  
Boolean prev=false;

void showGrid(float s) {
  for (float x=0; x<width; x+=s*20) line(x,0,x,height);
  for (float y=0; y<height; y+=s*20) line(0,y,width,y);
  }
  

