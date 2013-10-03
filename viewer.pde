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
Boolean frontPick=true, translucent=false, showMesh=true, pickBack=false, showNormals=false, showVertices=false, labels=false, 
   showSilhouette=false, showHelpText=false, showLeft=true, showRight=true, showBack=false, showMiddle=false, showBaffle=false; // display modes
   
// ******************************** MESHES ***********************************************
/*Mesh MM[] = new Mesh[3];
Mesh M;
Mesh origMesh = null;*/

RingExpander R;
int nsteps=250;
/*int m=0; // current mesh

float s=10; // scale for drawing cutout
float a=0, dx=0, dy=0;   // angle for drawing cutout
float sd=10; // samp[le distance for cut curve
pt sE = P(), sF = P(); vec sU=V(); //  view parameters (saved with 'j'*/

// ********* TEMPORARY GLOBALS ************
ViewportManager g_viewportManager;

// *******************************************************************************************************************    SETUP
void setup() {
  size(1200, 600, OPENGL); // size(500, 500, OPENGL);  
  setColors(); sphereDetail(3); 
//  PFont font = loadFont("Courier-14.vlw"); textFont(font, 12);  // font for writing labels on 
  PFont font = loadFont("GillSans-24.vlw"); textFont(font, 20);  // font for writing labels on 
  
  glu= ((PGraphicsOpenGL) g).glu;  PGraphicsOpenGL pgl = (PGraphicsOpenGL) g;  gl = pgl.beginGL();  pgl.endGL();
  /*for(int i=0; i<MM.length; i++) {
    MM[i]=new IslandMesh(); 
    M=MM[i]; 
    M.declareVectors();  
    M.makeGrid(8);
    M.updateON(); // computes O table and normals
    M.resetMarkers(); // resets vertex and tirangle markers
    }*/
    
  g_viewportManager = new ViewportManager();
  g_viewportManager.addViewport( new Viewport( 0, 0, width/2, height ) );
  g_viewportManager.addViewport( new Viewport( width/2, 0, width/2, height ) );

  /*M=MM[m];
  M.loadMeshVTS("data/horse.vts");
  M.updateON();  
  M.resetMarkers();*/
  IslandMesh mesh = new IslandMesh(); 
  mesh.declareVectors();  
  mesh.loadMeshVTS("data/horse.vts");
  mesh.updateON(); // computes O table and normals
  mesh.resetMarkers(); // resets vertex and tirangle markers
  mesh.computeBox();  
  
  g_viewportManager.registerMeshToViewport( mesh, 0 );
  for(int i=0; i<10; i++) vis[i]=true; // to show all types of triangles
  }
  
// ******************************************************************************************************************* DRAW      
void draw() {  
  background(white);
  // -------------------------------------------------------- 2D display ----------------------------------
  g_viewportManager.draw();
 } // end draw
 
 // ****************************************************************************************************************************** INTERRUPTS
Boolean pressed=false;
void mousePressed() {
  g_viewportManager.onMousePressed();
  }
  
void mouseDragged() {
  g_viewportManager.onMouseDragged();
  }

void mouseReleased() {
  }
  
void keyReleased() {
   g_viewportManager.onKeyReleased();
   } 

 
void keyPressed() {
   g_viewportManager.onKeyPressed();
  } //------------------------------------------------------------------------ end keyPressed
  
Boolean prev=false;

void showGrid(float s) {
  for (float x=0; x<width; x+=s*20) line(x,0,x,height);
  for (float y=0; y<height; y+=s*20) line(0,y,width,y);
  }
  
  // Snapping PICTURES of the screen
PImage myFace; // picture of author's face, read from file pic.jpg in data folder
int pictureCounter=0;
Boolean snapping=false; // used to hide some text whil emaking a picture
void snapPicture() {saveFrame("PICTURES/P"+nf(pictureCounter++,3)+".jpg"); snapping=false;}


