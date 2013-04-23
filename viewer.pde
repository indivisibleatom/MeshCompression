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

boolean fShowCorners = true;
boolean fBeginMorph = false;
boolean fBeginUnmorph = false;

// ****************************** GLOBAL VARIABLES FOR DISPLAY OPTIONS *********************************
Boolean frontPick=true, translucent=false, showMesh=true, pickBack=false, showNormals=false, showVertices=false, labels=false, 
   showSilhouette=false, showHelpText=false, showLeft=true, showRight=true, showBack=false, showMiddle=false, showBaffle=false; // display modes
   
// ****************************** VIEW PARAMETERS *******************************************************
pt F = P(0,0,0); pt T = P(); pt E = P(0,0,1000); vec U=V(0,1,0);  // focus  set with mouse when pressing 't', eye, and up vector
pt Q=P(0,0,0); vec I=V(1,0,0); vec J=V(0,1,0); vec K=V(0,0,1); // picked surface point Q and screen aligned vectors {I,J,K} set when picked
void initView() {Q=P(0,0,0); I=V(1,0,0); J=V(0,1,0); K=V(0,0,1); F = P(0,0,0); E = P(0,0,1000); U=V(0,1,0); } // declares the local frames

// ******************************** MESHES ***********************************************
Mesh MM[] = new Mesh[3];
Mesh M;
RingExpander R;
int m=0; // current mesh
int nsteps=250;
float s=10; // scale for drawing cutout
float a=0, dx=0, dy=0;   // angle for drawing cutout
float sd=10; // samp[le distance for cut curve
pt sE = P(), sF = P(); vec sU=V(); //  view parameters (saved with 'j'

// *******************************************************************************************************************    SETUP
void setup() {
  size(900, 900, OPENGL); // size(500, 500, OPENGL);  
  setColors(); sphereDetail(6); 
//  PFont font = loadFont("Courier-14.vlw"); textFont(font, 12);  // font for writing labels on 
  PFont font = loadFont("GillSans-24.vlw"); textFont(font, 20);  // font for writing labels on 
  
  glu= ((PGraphicsOpenGL) g).glu;  PGraphicsOpenGL pgl = (PGraphicsOpenGL) g;  gl = pgl.beginGL();  pgl.endGL();
  initView(); // declares the local frames for 3D GUI
  for(int i=0; i<MM.length; i++) {
    MM[i]=new Mesh(); 
    M=MM[i]; 
    M.declareVectors();  
    M.makeGrid(8);
    M.updateON(); // computes O table and normals
    M.resetMarkers(); // resets vertex and tirangle markers
    }
  M=MM[m];
  M.loadMeshVTS("data/flat.vts");
  M.updateON();  
  M.resetMarkers();
  M.computeBox();  
  F.set(M.Cbox); 
  for(int i=0; i<10; i++) vis[i]=true; // to show all types of triangles
  }
  
// ******************************************************************************************************************* DRAW      
void draw() {  
  background(white);
  // -------------------------------------------------------- 2D display ----------------------------------
  if(showHelpText) {
    camera(); // 2D display to show cutout
    lights();
    // noFill(); strokeWeight(1); stroke(green); showGrid(s); // show 2D grid
    fill(black); writeHelp();
    return;
    } 
    
  if (fBeginMorph)
  {
    //print("Here");
    M.morphToBaseMesh();
    /*if (currentT <= 1.0)
    {
      currentT += 0.01;
    }*/
  }
  else if (fBeginUnmorph)
  {
    M.morphFromBaseMesh();
  }
    
  // -------------------------------------------------------- 3D display : set up view ----------------------------------
  camera(E.x, E.y, E.z, F.x, F.y, F.z, U.x, U.y, U.z); // defines the view : eye, ctr, up
  vec Li=U(A(V(E,F),0.1*d(E,F),J));   // vec Li=U(A(V(E,F),-d(E,F),J)); 
  directionalLight(255,255,255,Li.x,Li.y,Li.z); // direction of light: behind and above the viewer
  specular(255,255,0); shininess(5);

  // -------------------------------------------------------- display BACK if picking on the back ---------------------------------- 
  // display model used for picking (back only when picking on the back)
  if(pickBack) {noStroke(); if(translucent)  M.showTriangles(false,100,shrunk); else M.showBackTriangles(); }
  if(!pickBack) {
    if(translucent) {                                       // translucent mode
      fill(grey,80); noStroke(); M.showBackTriangles();  
      if(M.showEdges) stroke(orange); else noStroke();
      M.showTriangles(true,150,shrunk);
      } 
    else {                                                  // opaque mode
      if(M.showEdges) stroke(dblue); else noStroke(); 
      M.showTriangles(true,255,shrunk);
      M.showMarkers();
      M.drawBarycenters();
      }      
    }
      
    // -------------------------------------------------------- graphic picking on surface ----------------------------------   
  if (keyPressed&&key=='t') T.set(Pick()); // sets point T on the surface where the mouse points. The camera will turn toward's it when the 't' key is released
  if (keyPressed&&key=='h') { M.pickc(Pick()); M.printState(); }// sets c to closest corner in M 
  if(pressed) {
     if (keyPressed&&key=='s') M.picks(Pick()); // sets M.sc to the closest corner in M from the pick point
     if (keyPressed&&key=='c') M.pickc(Pick()); // sets M.cc to the closest corner in M from the pick point
     if (keyPressed&&(key=='w'||key=='x'||key=='W'||key=='X')) M.pickcOfClosestVertex(Pick()); 
     }
  pressed=false;
 
  SetFrame(Q,I,J,K);  // showFrame(Q,I,J,K,30);  // sets frame from picked points and screen axes
  
  // rotate view 
  if(!keyPressed&&mousePressed) {E=R(E,  PI*float(mouseX-pmouseX)/width,I,K,F); E=R(E,-PI*float(mouseY-pmouseY)/width,J,K,F); } // rotate E around F 
  if(keyPressed&&key=='Z'&&mousePressed) {E=P(E,-float(mouseY-pmouseY),K); }  //   Moves E forward/backward
  if(keyPressed&&key=='z'&&mousePressed) {E=P(E,-float(mouseY-pmouseY),K);U=R(U, -PI*float(mouseX-pmouseX)/width,I,J); }//   Moves E forward/backward and rotatees around (F,Y)

 
   // -------------------------------------------------------- display picked points and triangles ----------------------------------   
  fill(cyan); M.showSOT(); // shoes triangle t(cc) shrunken
  M.showcc();  // display corner markers: seed sc (green),  current cc (red)
  
  // --------------------------------------------------------- display corners visited by ringexpander ------------------------------
  //M.showRingExpanderCorners();

  
  // -------------------------------------------------------- display FRONT if we were picking on the back ---------------------------------- 
  if(pickBack) 
    if(translucent) {fill(cyan,150); if(M.showEdges) stroke(orange); else noStroke(); M.showTriangles(true,100,shrunk);} 
    else {fill(cyan); if(M.showEdges) stroke(orange); else noStroke(); M.showTriangles(true,255,shrunk);}
 
  // -------------------------------------------------------- Show mesh border (red), vertices and normals ---------------------------------- 
   stroke(red); M.showBorder();  // show border edges
   if(showVertices) M.showVertices(); // show vertices
   if(showNormals) M.showNormals();  // show normals
   
  // -------------------------------------------------------- Disable z-buffer to display occluded silhouettes and other things ---------------------------------- 
  hint(DISABLE_DEPTH_TEST);  // show on top
  if(showSilhouette) {stroke(dbrown); M.drawSilhouettes(); }  // display silhouettes
  
  camera(); // 2D view to write help text
  fill(dred); scribe("surface = "+nf(M.surf,1,1)+", volume = "+nf(M.vol,1,0),0); 
  // writeFooterHelp();
  scribeHeaderRight("Mesh "+str(m));
  hint(ENABLE_DEPTH_TEST); // show silouettes

  // -------------------------------------------------------- SNAP PICTURE ---------------------------------- 
   if(snapping) snapPicture(); // does not work for a large screen

 } // end draw
 
 
 
 
 
 // ****************************************************************************************************************************** INTERRUPTS
Boolean pressed=false;
void mousePressed() {pressed=true;
  if (keyPressed&&key=='h') {M.hide(); }  // hide triangle
  }
  
void mouseDragged() {
  if(keyPressed&&key=='w') {M.add(float(mouseX-pmouseX),I).add(-float(mouseY-pmouseY),J); } // move selected vertex in screen plane
  if(keyPressed&&key=='x') {M.add(float(mouseX-pmouseX),I).add(float(mouseY-pmouseY),K);}  // move selected vertex in X/Z screen plane
  if(keyPressed&&key=='W') {M.addROI(float(mouseX-pmouseX),I).addROI(-float(mouseY-pmouseY),J); } // move selected vertex in screen plane
  if(keyPressed&&key=='X') {M.addROI(float(mouseX-pmouseX),I).addROI(float(mouseY-pmouseY),K);}  // move selected vertex in X/Z screen plane 
  }

void mouseReleased() {
    }
  
void keyReleased() {
   if(key=='t') F.set(T);  // set camera focus
   if(key=='c') println("edge length = "+d(M.gp(),M.gn()));  
   U.set(M(J)); // reset camera up vector
   } 

 
void keyPressed() {
  //for(int i=0; i<10; i++) if (key==char(i+48)) vis[i]=!vis[i];
               // corner ops for demos
               // CORNER OPERATORS FOR TEACHING AND DEBUGGING
  if(key=='N') M.next();      
  if(key=='P') M.previous();
  if(key=='O') M.back();
  if(key=='L') M.left();
  if(key=='R') M.right();   
  if(key=='S') M.swing();
  if(key=='U') M.unswing();
  
               // camera focus set 
  if(key=='^') F.set(M.g()); // to picked corner
  if(key==']') F.set(M.Cbox);  // center of minimax box
  if(key==';') {initView(); F.set(M.Cbox); } // reset the view
  
               // display modes
  if(key=='=') translucent=!translucent;
  if(key=='g') M.flatShading=!M.flatShading;
  if(key=='-') {M.showEdges=!M.showEdges; if (M.showEdges) shrunk=1; else shrunk=0;}
  if(key=='.') showVertices=!showVertices;
  if(key=='T') {int n=(m+1)%MM.length; M.copyTo(MM[n]); m=n; M=MM[m];};
  if(key=='|') showNormals=!showNormals;

               // archival
  if(key=='W') {M.saveMeshVTS();}
  if(key=='G') {M.loadMeshOBJ(); // M.loadMesh(); 
                M.updateON();   M.resetMarkers();
                M.computeBox();  F.set(M.Cbox); fni=(fni+1)%fniMax; 
                CL.empty(); SL.empty(); PL.empty(); 
                for(int i=0; i<10; i++) vis[i]=true;
                }
  if(key=='M') {M.loadMeshVTS(); 
                M.updateON();   M.resetMarkers();
                M.computeBox();  F.set(M.Cbox); 
                for(int i=0; i<10; i++) vis[i]=true;
                R = null;
                }
  
               // mesh edits, smoothing, refinement
  if(key=='b') {pickBack=true; translucent=true; println("picking on the back");}
  if(key=='f') {pickBack=false; translucent=false; println("picking on the front");}
  if(key=='/') M.flip(); // clip edge opposite to M.cc
  if(key=='F') {M.smoothen(); M.normals();}
  if(key=='Y') {M.refine(); M.makeAllVisible();}
  if(key=='d') {M.clean();}
//  if(key=='P') {M.computePath();}

               // Loop
  if(key=='I') ;
  if(key=='o') M.offset();
  if(key=='(') {showSilhouette=!showSilhouette;}
  if(key=='l') ;
  
  if(key=='m') {m=(m+1)%MM.length; M=MM[m];};

//  if(key=='C') M.compress();
//  if(key=='D') M.decompress();
 

  if(key=='?') {showHelpText=!showHelpText;} 
  if(key=='u') {M.resetMarkers(); M.makeAllVisible(); } // undo deletions
  if(key=='L') ;
  if(key=='B') showBack=!showBack;
  if(key=='R') ;   
  if(key=='#') M.volume(); 
  if(key=='_') M.surface(); 
  if(key=='Q') exit();
  if(key==',') 
  if(key=='V') {sE.set(E); sF.set(F); sU.set(U);}
  if(key=='v') {E.set(sE); F.set(sF); U.set(sU);}
  if (key == '!') {snapping=true;} // saves picture of screen
  if (key=='1') {g_stepWiseRingExpander.setStepMode(false); M.showEdges = true; R = new RingExpander(M, (int) random(M.nt * 3)); M.setResult(R.completeRingExpanderRecursive()); M.showRingExpanderCorners(); }
  if (key=='3') {M.advanceRingExpanderResult();}
  if (key=='4') {g_stepWiseRingExpander.setStepMode(true); M.showEdges = true; if (R == null) { R = new RingExpander(M, 1968); } R.ringExpanderStepRecursive();}
  if (key=='6') {g_stepWiseRingExpander.setStepMode(false); M.formIslands(-1);}
  if (key=='7')
  {
    g_stepWiseRingExpander.setStepMode(false);
    StatsCollector s = new StatsCollector(); 
    s.collectStats(1000, 30);
    s.collectStats(1000, 62);
    s.done();
  }
  if (key =='8')
  {
    fShowCorners = false;
    M.colorTriangles();
  }
  if (key =='9')
  {
    fBeginMorph = true;
    fBeginUnmorph = false;
    //M.morphToBaseMesh();
  }
  if (key == '5')
  {
    fBeginMorph = false;
    fBeginUnmorph = true;
  }
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


