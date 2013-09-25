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
    M.morphToBaseMesh();
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
    s.collectStats(10, 30);
    s.collectStats(10, 62);
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


boolean DEBUG = true;
int VERBOSE = 4;
int HIGH = 2;
int LOW = 1;
int DEBUG_MODE = LOW;
//*********************************************************************
//**                      3D geeomtry tools                          **
//**       Jarek Rossignac, October 2010, updates Oct 2011           **   
//**                 (points, vectors, and more)                     **   
//*********************************************************************

// ===== vector class
class vec { float x=0,y=0,z=0; 
   vec () {}; 
   vec (float px, float py, float pz) {x = px; y = py; z = pz;};
   vec set (float px, float py, float pz) {x = px; y = py; z = pz; return this;}; 
   vec set (vec V) {x = V.x; y = V.y; z = V.z; return this;}; 
   vec add(vec V) {x+=V.x; y+=V.y; z+=V.z; return this;};
   vec add(float s, vec V) {x+=s*V.x; y+=s*V.y; z+=s*V.z; return this;};
   vec sub(vec V) {x-=V.x; y-=V.y; z-=V.z; return this;};
   vec mul(float f) {x*=f; y*=f; z*=f; return this;};
   vec div(float f) {x/=f; y/=f; z/=f; return this;};
   vec div(int f) {x/=f; y/=f; z/=f; return this;};
   vec rev() {x=-x; y=-y; z=-z; return this;};
   float norm() {return(sqrt(sq(x)+sq(y)+sq(z)));}; 
   vec normalize() {float n=norm(); if (n>0.000001) {div(n);}; return this;};
   vec rotate(float a, vec I, vec J) {float x=d(this,I), y=d(this,J); float c=cos(a), s=sin(a); add(x*c-x-y*s,I); add(x*s+y*c-y,J); return this; }; // Rotate by a in plane (I,J)
   } ;
  
// ===== vector functions
vec V() {return new vec(); };                                                                          // make vector (x,y,z)
vec V(float x, float y, float z) {return new vec(x,y,z); };                                            // make vector (x,y,z)
vec V(vec V) {return new vec(V.x,V.y,V.z); };                                                          // make copy of vector V
vec A(vec A, vec B) {return new vec(A.x+B.x,A.y+B.y,A.z+B.z); };                                       // A+B
vec A(vec U, float s, vec V) {return V(U.x+s*V.x,U.y+s*V.y,U.z+s*V.z);};                               // U+sV
vec M(vec U, vec V) {return V(U.x-V.x,U.y-V.y,U.z-V.z);};                                              // U-V
vec M(vec V) {return V(-V.x,-V.y,-V.z);};                                                              // -V
vec V(vec A, vec B) {return new vec((A.x+B.x)/2.0,(A.y+B.y)/2.0,(A.z+B.z)/2.0); }                      // (A+B)/2
vec V(vec A, float s, vec B) {return new vec(A.x+s*(B.x-A.x),A.y+s*(B.y-A.y),A.z+s*(B.z-A.z)); };      // (1-s)A+sB
vec V(vec A, vec B, vec C) {return new vec((A.x+B.x+C.x)/3.0,(A.y+B.y+C.y)/3.0,(A.z+B.z+C.z)/3.0); };  // (A+B+C)/3
vec V(vec A, vec B, vec C, vec D) {return V(V(A,B),V(C,D)); };                                         // (A+B+C+D)/4
vec V(float s, vec A) {return new vec(s*A.x,s*A.y,s*A.z); };                                           // sA
vec V(float a, vec A, float b, vec B) {return A(V(a,A),V(b,B));}                                       // aA+bB 
vec V(float a, vec A, float b, vec B, float c, vec C) {return A(V(a,A,b,B),V(c,C));}                   // aA+bB+cC
vec V(pt P, pt Q) {return new vec(Q.x-P.x,Q.y-P.y,Q.z-P.z);};                                          // PQ
vec U(vec V) {float n = V.norm(); if (n<0.000001) return V(0,0,0); else return V.div(n);};             // V/||V||
vec U(pt A, pt B) {return U(V(A,B));}
vec N(vec U, vec V) {return V( U.y*V.z-U.z*V.y, U.z*V.x-U.x*V.z, U.x*V.y-U.y*V.x); };                  // UxV CROSS PRODUCT (normal to both)
vec N(pt A, pt B, pt C) {return N(V(A,B),V(A,C)); };                                                   // normal to triangle (A,B,C), not normalized (proportional to area)
vec B(vec U, vec V) {return U(N(N(U,V),U)); }                                                           // (UxV)xV unit normal to U in the plane UV
vec R(vec V) {return V(-V.y,V.x,V.z);} // rotated 90 degrees in XY plane
vec R(vec V, float a, vec I, vec J) {float x=d(V,I), y=d(V,J); float c=cos(a), s=sin(a); return A(V,V(x*c-x-y*s,I,x*s+y*c-y,J)); }; // Rotated V by a parallel to plane (I,J)


// ===== point class
class pt { float x=0,y=0,z=0; 
   pt () {}; 
   pt (float px, float py, float pz) {x = px; y = py; z = pz; };
   pt set (float px, float py, float pz) {x = px; y = py; z = pz; return this;}; 
   pt set (pt P) {x = P.x; y = P.y; z = P.z; return this;}; 
   pt add(pt P) {x+=P.x; y+=P.y; z+=P.z; return this;};
   pt add(vec V) {x+=V.x; y+=V.y; z+=V.z; return this;};
   pt add(float s, vec V) {x+=s*V.x; y+=s*V.y; z+=s*V.z; return this;};
   pt add(float dx, float dy, float dz) {x+=dx; y+=dy; z+=dz; return this;};
   pt sub(pt P) {x-=P.x; y-=P.y; z-=P.z; return this;};
   pt mul(float f) {x*=f; y*=f; z*=f; return this;};
   pt div(float f) {x/=f; y/=f; z/=f; return this;};
   pt div(int f) {x/=f; y/=f; z/=f; return this;};
   void log() { print(x + " " + y + " " + z); }
//   void projectOnCylinder(pt A, pt B, float r) {pt H = S(A,d(V(A,B),V(A,this))/d(V(A,B),V(A,B)),B); this.setTo(T(H,r,this));}
   }
//  void projectOnCylinder(pt A, pt B, float r) {pt H = S(A,d(V(A,B),V(A,this))/d(V(A,B),V(A,B)),B); this.setTo(T(H,r,this));}   
// =====  point functions
pt P() {return new pt(); };                                            // point (x,y,z)
pt P(float x, float y, float z) {return new pt(x,y,z); };                                            // point (x,y,z)
pt P(pt A) {return new pt(A.x,A.y,A.z); };                                                           // copy of point P
pt P(pt A, float s, pt B) {return new pt(A.x+s*(B.x-A.x),A.y+s*(B.y-A.y),A.z+s*(B.z-A.z)); };        // A+sAB
pt P(pt A, pt B) {return P((A.x+B.x)/2.0,(A.y+B.y)/2.0,(A.z+B.z)/2.0); }                             // (A+B)/2
pt P(pt A, pt B, pt C) {return new pt((A.x+B.x+C.x)/3.0,(A.y+B.y+C.y)/3.0,(A.z+B.z+C.z)/3.0); };     // (A+B+C)/3
pt P(pt A, pt B, pt C, pt D) {return P(P(A,B),P(C,D)); };                                            // (A+B+C+D)/4
pt P(float s, pt A) {return new pt(s*A.x,s*A.y,s*A.z); };                                            // sA
pt A(pt A, pt B) {return new pt(A.x+B.x,A.y+B.y,A.z+B.z); };                                         // A+B
pt P(float a, pt A, float b, pt B) {return A(P(a,A),P(b,B));}                                        // aA+bB 
pt P(float a, pt A, float b, pt B, float c, pt C) {return A(P(a,A),P(b,B,c,C));}                     // aA+bB+cC 
pt P(float a, pt A, float b, pt B, float c, pt C, float d, pt D){return A(P(a,A,b,B),P(c,C,d,D));}   // aA+bB+cC+dD
pt P(pt P, vec V) {return new pt(P.x + V.x, P.y + V.y, P.z + V.z); }                                 // P+V
pt P(pt P, float s, vec V) {return new pt(P.x+s*V.x,P.y+s*V.y,P.z+s*V.z);}                           // P+sV
pt P(pt O, float x, vec I, float y, vec J) {return P(O.x+x*I.x+y*J.x,O.y+x*I.y+y*J.y,O.z+x*I.z+y*J.z);}  // O+xI+yJ
pt P(pt O, float x, vec I, float y, vec J, float z, vec K) {return P(O.x+x*I.x+y*J.x+z*K.x,O.y+x*I.y+y*J.y+z*K.y,O.z+x*I.z+y*J.z+z*K.z);}  // O+xI+yJ+kZ
pt R(pt P, float a, vec I, vec J, pt G) {float x=d(V(G,P),I), y=d(V(G,P),J); float c=cos(a), s=sin(a); return P(P,x*c-x-y*s,I,x*s+y*c-y,J); }; // Rotated P by a around G in plane (I,J)
void makePts(pt[] C) {for(int i=0; i<C.length; i++) C[i]=P();} // fills array C with points initialized to (0,0,0)
pt Predict(pt A, pt B, pt C) {return P(B,V(A,C)); };     // B+AC, parallelogram predictor


// ===== mouse tools
pt Mouse() {return P(mouseX,mouseY,0);};                                          // current mouse location
pt Pmouse() {return P(pmouseX,pmouseY,0);};
vec MouseDrag() {return V(mouseX-pmouseX,mouseY-pmouseY,0);};                     // vector representing recent mouse displacement

// ===== measures
float d(vec U, vec V) {return U.x*V.x+U.y*V.y+U.z*V.z; };                                            //U*V dot product
float d(pt P, pt Q) {return sqrt(sq(Q.x-P.x)+sq(Q.y-P.y)+sq(Q.z-P.z)); };                            // ||AB|| distance
float d2(pt P, pt Q) {return sq(Q.x-P.x)+sq(Q.y-P.y)+sq(Q.z-P.z); };                                 // AB^2 distance squared
float m(vec U, vec V, vec W) {return d(U,N(V,W)); };                                                 // (UxV)*W  mixed product, determinant
float m(pt E, pt A, pt B, pt C) {return m(V(E,A),V(E,B),V(E,C));}                                    // det (EA EB EC) is >0 when E sees (A,B,C) clockwise
float n2(vec V) {return sq(V.x)+sq(V.y)+sq(V.z);};                                                   // V*V    norm squared
float n(vec V) {return sqrt(n2(V));};                                                                // ||V||  norm
float area(pt A, pt B, pt C) {return n(N(A,B,C))/2; };                                               // area of triangle 
float volume(pt A, pt B, pt C, pt D) {return m(V(A,B),V(A,C),V(A,D))/6; };                           // volume of tet 
boolean parallel (vec U, vec V) {return n(N(U,V))<n(U)*n(V)*0.00001; }                               // true if U and V are almost parallel
float angle(vec U, vec V) {return acos(d(U,V)/n(V)/n(U)); };                                         // angle(U,V)
boolean cw(vec U, vec V, vec W) {return m(U,V,W)>=0; };                                              // (UxV)*W>0  U,V,W are clockwise
boolean cw(pt A, pt B, pt C, pt D) {return volume(A,B,C,D)>=0; };                                    // tet is oriented so that A sees B, C, D clockwise 

// ===== rotate 

// ===== render
void normal(vec V) {normal(V.x,V.y,V.z);};                                          // changes normal for smooth shading
void vertex(pt P) {vertex(P.x,P.y,P.z);};                                           // vertex for shading or drawing
void vTextured(pt P, float u, float v) {vertex(P.x,P.y,P.z,u,v);};                          // vertex with texture coordinates
void show(pt P, pt Q) {line(Q.x,Q.y,Q.z,P.x,P.y,P.z); };                       // draws edge (P,Q)
void show(pt P, vec V) {line(P.x,P.y,P.z,P.x+V.x,P.y+V.y,P.z+V.z); };          // shows edge from P to P+V
void show(pt P, float d , vec V) {line(P.x,P.y,P.z,P.x+d*V.x,P.y+d*V.y,P.z+d*V.z); }; // shows edge from P to P+dV
void show(pt A, pt B, pt C) {beginShape(); vertex(A);vertex(B); vertex(C); endShape(CLOSE);};                      // volume of tet 
void show(pt A, pt B, pt C, pt D) {beginShape(); vertex(A); vertex(B); vertex(C); vertex(D); endShape(CLOSE);};                      // volume of tet 
void show(pt P, float r) {pushMatrix(); translate(P.x,P.y,P.z); sphere(r); popMatrix();}; // render sphere of radius r and center P
void show(pt P, float s, vec I, vec J, vec K) {noStroke(); fill(yellow); show(P,5); stroke(red); show(P,s,I); stroke(green); show(P,s,J); stroke(blue); show(P,s,K); }; // render sphere of radius r and center P
void show(pt P, String s) {text(s, P.x, P.y, P.z); }; // prints string s in 3D at P
void show(pt P, String s, vec D) {text(s, P.x+D.x, P.y+D.y, P.z+D.z);  }; // prints string s in 3D at P+D

// ==== curve
void bezier(pt A, pt B, pt C, pt D) {bezier(A.x,A.y,A.z,B.x,B.y,B.z,C.x,C.y,C.z,D.x,D.y,D.z);} // draws a cubic Bezier curve with control points A, B, C, D
void bezier(pt [] C) {bezier(C[0],C[1],C[2],C[3]);} // draws a cubic Bezier curve with control points A, B, C, D
pt bezierPoint(pt[] C, float t) {return P(bezierPoint(C[0].x,C[1].x,C[2].x,C[3].x,t),bezierPoint(C[0].y,C[1].y,C[2].y,C[3].y,t),bezierPoint(C[0].z,C[1].z,C[2].z,C[3].z,t)); }
vec bezierTangent(pt[] C, float t) {return V(bezierTangent(C[0].x,C[1].x,C[2].x,C[3].x,t),bezierTangent(C[0].y,C[1].y,C[2].y,C[3].y,t),bezierTangent(C[0].z,C[1].z,C[2].z,C[3].z,t)); }
void PT(pt P0, vec T0, pt P1, vec T1) {float d=d(P0,P1)/3;  bezier(P0, P(P0,-d,U(T0)), P(P1,-d,U(T1)), P1);} // draws cubic Bezier interpolating  (P0,T0) and  (P1,T1) 
void PTtoBezier(pt P0, vec T0, pt P1, vec T1, pt [] C) {float d=d(P0,P1)/3;  C[0].set(P0); C[1].set(P(P0,-d,U(T0))); C[2].set(P(P1,-d,U(T1))); C[3].set(P1);} // draws cubic Bezier interpolating  (P0,T0) and  (P1,T1) 
vec vecToCubic (pt A, pt B, pt C, pt D, pt E) {return V( (-A.x+4*B.x-6*C.x+4*D.x-E.x)/6, (-A.y+4*B.y-6*C.y+4*D.y-E.y)/6, (-A.z+4*B.z-6*C.z+4*D.z-E.z)/6);}
vec vecToProp (pt B, pt C, pt D) {float cb=d(C,B);  float cd=d(C,D); return V(C,P(B,cb/(cb+cd),D)); };  

// ==== perspective
pt Pers(pt P, float d) { return P(d*P.x/(d+P.z) , d*P.y/(d+P.z) , d*P.z/(d+P.z) ); };

pt InverserPers(pt P, float d) { return P(d*P.x/(d-P.z) , d*P.y/(d-P.z) , d*P.z/(d-P.z) ); };

// ==== intersection
boolean intersect(pt P, pt Q, pt A, pt B, pt C, pt X)  {return intersect(P,V(P,Q),A,B,C,X); } // if (P,Q) intersects (A,B,C), return true and set X to the intersection point

boolean intersect(pt E, vec T, pt A, pt B, pt C, pt X) { // if ray from E along T intersects triangle (A,B,C), return true and set X to the intersection point
  vec EA=V(E,A), EB=V(E,B), EC=V(E,C), AB=V(A,B), AC=V(A,C); 
  boolean s=cw(EA,EB,EC), sA=cw(T,EB,EC), sB=cw(EA,T,EC), sC=cw(EA,EB,T); 
  if ( (s==sA) && (s==sB) && (s==sC) ) return false;
  float t = m(EA,AC,AB) / m(T,AC,AB);
  X.set(P(E,t,T));
  return true;
  }
  
boolean rayIntersectsTriangle(pt E, vec T, pt A, pt B, pt C) { // true if ray from E with direction T hits triangle (A,B,C)
  vec EA=V(E,A), EB=V(E,B), EC=V(E,C); 
  boolean s=cw(EA,EB,EC), sA=cw(T,EB,EC), sB=cw(EA,T,EC), sC=cw(EA,EB,T); 
  return  (s==sA) && (s==sB) && (s==sC) ;}
  
boolean edgeIntersectsTriangle(pt P, pt Q, pt A, pt B, pt C)  {
  vec PA=V(P,A), PQ=V(P,Q), PB=V(P,B), PC=V(P,C), QA=V(Q,A), QB=V(Q,B), QC=V(Q,C); 
  boolean p=cw(PA,PB,PC), q=cw(QA,QB,QC), a=cw(PQ,PB,PC), b=cw(PA,PQ,PC), c=cw(PQ,PB,PQ); 
  return (p!=q) && (p==a) && (p==b) && (p==c);
  }
  
float rayParameterToIntersection(pt E, vec T, pt A, pt B, pt C) {vec AE=V(A,E), AB=V(A,B), AC=V(A,C); return - m(AE,AC,AB) / m(T,AC,AB);}
   
float angleDraggedAround(pt G) {  // returns angle in 2D dragged by the mouse around the screen projection of G
   pt S=P(screenX(G.x,G.y,G.z),screenY(G.x,G.y,G.z),0);
   vec T=V(S,Pmouse()); vec U=V(S,Mouse());
   return atan2(d(R(U),T),d(U,T));
   }

void showShrunkOffset(pt A, pt B, pt C, float e, float h) {vec N=U(N(V(A,B),V(A,C))); showShrunk(P(A,h,N),P(B,h,N),P(C,h,N),e);}

void showShrunk(pt A, pt B, pt C, float e) {
   vec AB = U(V(A,B)), BC = U(V(B,C)), CA = U(V(C,A));
   float a = e/n(N(CA,AB)), b = e/n(N(AB,BC)), c = e/n(N(BC,CA));
   float d = max(d(A,B)/3,d(B,C)/3,d(C,A)/3);
   a=min(a,d); b=min(b,d); c=min(c,d);
   pt As=P(A,a,AB,-a,CA), Bs=P(B,b,BC,-b,AB), Cs=P(C,c,CA,-c,BC);
   beginShape(); vertex(As); vertex(Bs); vertex(Cs); endShape(CLOSE);
   } 
   
float scaleDraggedFrom(pt G) {pt S=P(screenX(G.x,G.y,G.z),screenY(G.x,G.y,G.z),0); return d(S,Mouse())/d(S,Pmouse()); }
 
// INTERPOLATING CURVE
void drawCurve(pt A, pt B, pt C, pt D) {float d=d(A,B)+d(B,C)+d(C,D); beginShape(); for(float t=0; t<=1; t+=0.025) vertex(P(A,B,C,D,t*d)); endShape(); }
void drawSamplesOnCurve(pt A, pt B, pt C, pt D, float r) {float d=d(A,B)+d(B,C)+d(C,D); for(float t=0; t<=1; t+=0.025) show(P(A,B,C,D,t*d),r);}
pt P(pt A, pt B, pt C, pt D, float t) {return P(0,A,d(A,B),B,d(A,B)+d(B,C),C,d(A,B)+d(B,C)+d(C,D),D,t);}
pt P(float a, pt A, float b, pt B, float c, pt C, float d, pt D, float t) {
   pt E = P(A,(t-a)/(b-a),B), F = P(B,(t-b)/(c-b),C), G = P(C,(t-c)/(d-c),D), 
                 H = P(E,(t-a)/(c-a),F), I = P(F,(t-b)/(d-b),G);
                            return P(H,(t-a)/(d-a),I);
  }

pt NUBS(float a, pt A, float b, pt B, float c, pt C, float d, pt D, float e, float t) {
  pt E = P(A,(a+b+t*c)/(a+b+c),B), F = P(B,(b+t*c)/(b+c+d),C), G = P(C,(t*c)/(c+d+e),D), 
                 H = P(E,(b+t*c)/(b+c),F),         I = P(F,(t*c)/(c+d),G),
                            J = P(H,t,I);
  return J;
  }

LOOP CL = new LOOP();   // loop of control points
LOOP SL = new LOOP();  // refined interpolating loop using retrofiting and NUBS
LOOP PL = new LOOP();  // projected SL used to compute the ring and then smoothened and projected onto the ring (the cut)
LOOP RL = new LOOP();  // record of projected loop PL before it is resampled

class LOOP {
  int n=0;                            // current number of control points
  pt [] P = new pt[5000];            // decalres an array of  points
  vec [] L = new vec[5000];          // Laplace vectores for smoothing
  int p=0;                          // index to the currently selected vertex being dragged
  LOOP(int pn) {n=pn; declarePoints(); resetPoints(); }
  LOOP() {declarePoints(); resetPoints(); }
  int n(int j) {  if (j==n-1) {return (0);}  else {return(j+1);}  };  // next point in loop
  int p(int j) {  if (j==0) {return (n-1);}  else {return(j-1);}  };  // previous point in loop                                                     
  pt Pof(int p) {return P[p];}
  pt cP() {return P[p];}
  pt pP() {return P[p(p)];}
  pt nP() {return P[n(p)];}
  void pp() {p=p(p);}
  void np() {p=n(p);}
  void declarePoints() {for (int i=0; i<P.length; i++) P[i]=new pt();} // allocates space
  void resetPoints() {float r=10; for (int i=0; i<n; i++) {P[i].x=r*cos(TWO_PI/n); P[i].y=r*sin(TWO_PI/n);}; } // init the points to be on a circle
  void empty(){ n=0; };      // resets the vertex count to zero
  void pick(pt M) {p=0; for (int i=1; i<n; i++) if (d(M,P[i])<d(M,P[p])) p=i;}
  void dragPoint(vec V) {P[p].add(V);}
  void movePointTo(pt Q) {P[p].set(Q);}
  void append(pt Q)  {if(n+1 < P.length) { p=n; P[n++].set(Q); } }; // add point at end of list
  void delete() { for (int i=p; i<n-1; i++) P[i].set(P[n(i)]); n--; p=p(p);}
  void insert() { // inserts after p
    if(p==n-1) {P[n].set(P[n-1]); p=n; n++; } 
    else {
      for (int i=n-1; i>p; i--) P[i+1].set(P[i]); 
      n++;  
      P[p+1].set(P[p]); 
      p=p+1; 
      }
    };
  void insert(pt M) {                // grabs closeest vertex or adds vertex at closest edge. It will be dragged by te mouse
     p=0; for (int i=0; i<n; i++) if (d(M,P[i])<d(M,P[p])) p=i; 
     int e=-1;
     float d = d(M,P[p]);
     for (int i=0; i<n; i++) {float dd=d(M,P(P[i],M,P[n(i)])); if (dd<d) {e=i; d=dd;}; }
     if (e!=-1) { for (int i=n-1; i>e; i--) P[i+1].set(P[i]); n++; p=n(e); P[p].set(M);  };
     }

  LOOP refine(int k){ // inserts an average of k vertices per span using a NUBS retrofit
    if(n<3) return this;
    LOOP B = new LOOP(10);
    B.cloneFrom(this); 
    LOOP R = new LOOP();
    for (int r=0; r<10; r++) {B.controlNUBS(R); B.addDif(R,this);}  // stroke(cyan); B.drawEdges(); 
    B.makeNUBS(R,k);  
    float l = R.length(); 
    //  R.resample(int(l/20));
    return R;
    }
    
  void drawEdges() {beginShape(); for (int i=0; i<n; i++) vertex(P[i]); endShape(CLOSE);}  // fast draw of edges
  void showSamples() {for (int i=0; i<n; i++) show(P[i],1);}  // fast draw of edges
  void showSamples(float r) {for (int i=0; i<n; i++) show(P[i],r);}  // fast draw of edges
  void showPick() {show(P[p],2); }  // fast draw of edges
  void cloneFrom(LOOP D) {for (int i=0; i<max(n,D.n); i++) P[i].set(D.P[i]); n=D.n;}
  pt pt(int i) {return P[i];}
  void showLoop() { noFill(); stroke(orange); drawEdges(); noStroke(); fill(orange); showSamples(); }  
  int closestVertexID(pt M) {int v=0; for (int i=1; i<n; i++) if (d(M,P[i])<d(M,P[v])) v=i; return v;}
  pt ClosestVertex(pt M) {pt R=P[0]; for (int i=1; i<n; i++) if (d(M,P[i])<d(M,R)) R=P[i]; return P(R);}
  float distanceTo(pt M) {float md=d(M,P[0]); for (int i=1; i<n; i++) md=min(md,d(M,P[i])); return md;}
  void savePts() {savePts("data/P.pts");}
  void savePts(String fn) { String [] inppts = new String [n+1];
    int s=0; inppts[s++]=str(n); 
    for (int i=0; i<n; i++) {inppts[s++]=str(P[i].x)+","+str(P[i].y)+","+str(P[i].z);};
    saveStrings(fn,inppts);  };
  void loadPts() {loadPts("data/P.pts");}
  void loadPts(String fn) { String [] ss = loadStrings(fn);
    String subpts;
    int s=0; int comma1, comma2; n = int(ss[s]);
    for(int i=0; i<n; i++) { 
      String S =  ss[++s];
      comma1=S.indexOf(',');
      float x=float(S.substring(0, comma1));
      String R = S.substring(comma1+1);
      comma2=R.indexOf(',');      
      float y=float(R.substring(0, comma2)); 
      float z=float(R.substring(comma2+1));
      P[i]= P(x,y,z);  
      }; 
    }
void addDif(LOOP R, LOOP C) {for(int i=0;i<n; i++) P[i].add(V(R.pt(i),C.pt(i)));}    
float length () {float L=0; for (int i=0; i<n; i++) L+=d(P[i],P[n(i)]);  return(L); }    

// ******************************************************************************************** LACING ***************
LOOP resampleDistance(float r) { // laces loop
  LOOP NL = new LOOP();
  NL.append(P[0]); 
  if (n<3) return NL;
//  fill(dred); noStroke();
  pt C = new pt();
  C.set(P[0]);
  int i=0; 
  Boolean go=true;
  while(go) {
    int j=i; while(j<n && d(P[j+1],C)<r) j++; // last vertex in sphere(C,r);
    if(j>=n-1) go=false; 
    else {
      pt A=P[j], B=P[j+1]; 
      float a=d2(A,B), b=d(V(C,A),V(A,B)), c=d2(C,A)-sq(r);  
      float s=(-b+sqrt(sq(b)-a*c))/a; 
      C.set(P(A,s,B)); 
      NL.append(C);
      i=j;           
      }
    }
        println(NL.n+" points on resampled curve");

//  noStroke(); fill(dgreen); show(A,5); fill(dred); show(B,5); 
//  fill(dblue); show(X,5); 
 return NL;
 }
 
void showLace(float s) {stroke(orange); strokeWeight(3); for(int i=1; i<floor(n/2); i++) show(P[i],P[n-i]); strokeWeight(1);} 
void shadeLace(float s) {
  fill(cyan); noStroke(); 
  beginShape(TRIANGLES); 
    vertex(P[0]); vertex(P[n-1]); vertex(P[1]); 
    for(int i=1; i<floor((n-1)/2); i++) {
    vertex(P[i]); vertex(P[n-i]); vertex(P[i+1]); 
    vertex(P[i+1]); vertex(P[n-i]); vertex(P[n-i-1]);
    } 
  if(n%2==0) {int j=floor((n-1)/2); vertex(P[j]); vertex(P[j+1]); vertex(P[j+2]);}
  endShape();
  }
    
int addTrianglesTo(Mesh M, int m) {   // ---------------------------------------------------------------
  int nv=M.nv, nt=M.nt;
  for(int i=0; i<n; i++) M.addVertex(P[i]);
  M.addTriangle(nv, nv+n-1, nv+1); M.tm[M.nt-1]=m;
  
  for(int i=1; i<floor((n-1)/2); i++) {
     M.addTriangle(nv+i, nv+n-i, nv+i+1); M.tm[M.nt-1]=m; 
     M.addTriangle(nv+i+1, nv+n-i, nv+n-i-1); M.tm[M.nt-1]=m; 
    } 
  if(n%2==0) {int j=floor((n-1)/2); M.addTriangle(nv+j, nv+j+2, nv+j+1); M.tm[M.nt-1]=m;}
  return (nt-1)*3+1;
  }  
  
int addReverseTrianglesTo(Mesh M, int m) {
  int nv=M.nv, nt=M.nt;
  for(int i=0; i<n; i++) M.addVertex(P[i]);
  M.addTriangle(nv, nv+1, nv+n-1); M.tm[M.nt-1]=m;
  
  for(int i=1; i<floor((n-1)/2); i++) {
     M.addTriangle(nv+i, nv+i+1, nv+n-i); M.tm[M.nt-1]=m; 
     M.addTriangle(nv+i+1, nv+n-i-1, nv+n-i); M.tm[M.nt-1]=m; 
    } 
  if(n%2==0) {int j=floor((n-1)/2); M.addTriangle(nv+j, nv+j+1, nv+j+2); M.tm[M.nt-1]=m;}
  return (nt-1)*3+1;
  }  

 
  
void shadeLaceQ(float s) {
  fill(cyan); stroke(orange); strokeWeight(3); 
  beginShape(QUAD_STRIP); 
    for(int i=1; i<floor(n/2); i++) {vertex(P[i]); vertex(P[n-i]);} 
  endShape();
  strokeWeight(1);
  }

vec normal() { // compute normal as the average of cross-products between successive triplets along the loop
  vec up = new vec(0,0,0);
  for(int ppi = n-2, pi = n-1, i = 0; i < n; ppi = pi, pi = i, i++) up.add(N(V(P[i],P[pi]), V(P[pi],P[ppi])));
  return up.normalize();
}

pt center() { // compute center of loop as average of points
  pt sum = new pt(0,0,0);
  for(int i = 0; i < n; i++) sum.add(P[i]);
  return sum.div(n);
}

void resample(int nn) { // resamples the curve with new nn vertices
    if(nn<3) return;
    float L = length();  // current total length  
    float d = L / nn;   // desired arc-length spacing                        
    float rd=d;        // remaining distance to next sample
    float cl=0;        // length of remaining portion of current edge
    int k=0,nk;        // counters
    pt [] R = new pt [nn]; // temporary array for the new points
    pt Q;
    int s=0;
    Q=P[0];         
    R[s++]=P(Q);     
    while (s<nn) {
       nk=n(k);
       cl=d(Q,P[nk]);                            
       if (rd<cl) {Q=P(Q,rd,P[nk]); R[s++]=P(Q); cl-=rd; rd=d; } 
       else {rd-=cl; Q.set(P[nk]); k++; };
       };
     n=s;   for (int i=0; i<n; i++)  P[i].set(R[i]);
   }
   
 void makeNUBS(LOOP L, int k) { // ***NEW*** equalized sampling
   L.n=0;
   float len=length();
   for(int j=0; j<n; j++)  {
     int i=p(p(j));
     float d=d(pt(j),pt(n(j)));
     int kk=int(d/len*k*n);
     for(int m=0; m<kk; m++) {
       float t = float(m)/kk;
       L.P[L.n++]=NUBS(
        d(pt(i),pt(n(i))), pt(n(i)),
        d(pt(n(i)),pt(n(n(i)))),pt(n(n(i))),
        d(pt(n(n(i))),pt(n(n(n(i))))),pt(n(n(n(i)))),
        d(pt(n(n(n(i)))),pt(n(n(n(n(i)))))),pt(n(n(n(n(i))))),
        d(pt(n(n(n(n(i))))),pt(n(n(n(n(n(i))))))),
        t);
     }
   }
 }
 
void showNUBS(int k) {
  beginShape();
    for(int i=0; i<n; i++) for(int j=0; j<k; j++) {
       float t = float(j)/k;
       vertex(NUBS(
        d(pt(i),pt(n(i))), pt(n(i)),
        d(pt(n(i)),pt(n(n(i)))),pt(n(n(i))),
        d(pt(n(n(i))),pt(n(n(n(i))))),pt(n(n(n(i)))),
        d(pt(n(n(n(i)))),pt(n(n(n(n(i)))))),pt(n(n(n(n(i))))),
        d(pt(n(n(n(n(i))))),pt(n(n(n(n(n(i))))))),
        t));
     }
  endShape(CLOSE);
   }

void controlNUBS(LOOP L) {L.n=0;
   for(int j=0; j<n; j++) {
     int i=p(p(j));
     L.P[L.n++]=NUBS(
       d(pt(i),pt(n(i))), pt(n(i)),
       d(pt(n(i)),pt(n(n(i)))),pt(n(n(i))),
       d(pt(n(n(i))),pt(n(n(n(i))))),pt(n(n(n(i)))),
       d(pt(n(n(n(i)))),pt(n(n(n(n(i)))))),pt(n(n(n(n(i))))),
       d(pt(n(n(n(n(i))))),pt(n(n(n(n(n(i))))))),
       0);
     }
  }
  
  
// float distanceTo(pt M) {return d(M,Projection(M));}
// pt Projection(pt M) {
//     int v=0; for (int i=1; i<n; i++) if (d(M,P[i])<d(M,P[v])) v=i; 
//     int e=-1;
//     float d = d(M,P[v]);
//     for (int i=0; i<n; i++) {float x=x(P[i],M,P[n(i)]); if ( 0<x && x<1) { float y=abs(ay(P[i],M,P[n(i)])); if(y<d) {e=i; d=y;} } }
//     if (e!=-1) return Shadow(P[e],M,P[n(e)]); else return P(P[v]);
//      }

 void setToProjection(LOOP L,Mesh M) {n=L.n; for(int j=0; j<n; j++) P[j].set(M.closestProjection(L.Pof(j))); }
 void setToProjection(LOOP L,Mesh M, int km) {n=L.n; for(int j=0; j<n; j++) P[j].set(M.closestProjection(L.Pof(j),km)); }
 void projectOn(CYL C) {for(int j=0; j<n; j++) P[j].set(C.project(P[j])); }
 void projectOn(Mesh M, int km) {for(int j=0; j<n; j++) P[j].set(M.closestProjection(P[j],km)); }
 void projectOn(Mesh M, int jm, int km) {
   for(int j=0; j<n; j++) {
     pt T=M.closestProjection(P[j],jm); 
///    pt T=P(M.closestProjection(P[j],jm),M.closestProjection(P[j],km)); 
//     P[j].set(M.closestProjection(P(P[j],.3,T))); 
//     P[j].set(M.closestProjection(P[j])); 
P[j].set(T);
     }
   }
 void projectOn(Mesh M) {for(int j=0; j<n; j++) P[j].set(M.closestProjection(P[j])); }
 void smoothenOn(Mesh M, int km) {for (int i=0; i<5; i++) {computeL(); applyL(0.5); computeL(); applyL(-0.5); projectOn(M,km); };}
 void smoothenOn(Mesh M, int jm, int km) {
     for (int i=0; i<5; i++) {
        computeL(); applyL(0.5); computeL(); applyL(-0.5); 
        computeL(); applyL(0.5); computeL(); applyL(-0.5); 
        projectOn(M,jm,km); // projectOn(M,jm,km); 
        };
     }
 void smoothenOn(Mesh M) {for (int i=0; i<5; i++) {computeL(); applyL(0.5); computeL(); applyL(-0.5); projectOn(M); };}
 void smoothen() {for (int i=0; i<50; i++) {computeL(); applyL(0.5); computeL(); applyL(-0.5); };}
 void computeL() {for (int i=0; i<n; i++) L[i]=V(0.5,V(P[i],P(P[p(i)],P[n(i)])));};
 void applyL(float s) {for (int i=0; i<n; i++) P[i].add(s,L[i]);};
 
 void drawConnections(Mesh M, int up, int cut, int bot) {
  for(int pi = n-1, i = 0; i < n; pi = i, i++) { 
 // for (int i=1; i<n; i++) { // index on loop
//    int pi=i-1;
    int pl=M.closestVertexNextCorner(P[pi],up);  //c
    int l=M.closestVertexNextCorner(P[i],up);  // c
    int ls=M.v(M.p(pl)); int le=M.v(M.p(l));  //v
    
    strokeWeight(4); stroke(orange); show(P[pi],M.g(M.p(pl))); strokeWeight(1);
    
    int nnc= M.nextAlongSplit(pl,1);
    
//       stroke(red); show(P[pi],P(M.g(M.p(nnc)),M.G[le]));

//    fill(orange); show(P[i],P[pi],M.g(M.p(pl)));
//    fill(cyan); show(P[i],P[pi],M.g(M.p(l)));
//    stroke(red); show(M.g(l),M.g(M.nextAlongSplit(l,1)));
//    fill(red); noStroke(); show(M.cg(M.nextAlongSplit(l,1)),2);
    int lc=ls;
    int k=pl; // c
    int xxx=0;
    while(lc!=le) {
      int ln = M.v(M.n(k));
      if(d(M.g(M.p(pi)),M.G[ln])>d(M.g(M.p(i)),M.G[ln])) break;
      fill(yellow); show(P[pi],M.G[lc],M.G[ln]);
      k=M.nextAlongSplit(k,1); // corner
      lc=ln;
      }
    lc=M.v(M.p(k));
    fill(orange); stroke(black); show(P[pi],M.G[lc],P[i]);

    while(lc!=le) {
       int ln = M.v(M.n(k));
       fill(green); show(P[i],M.G[lc],M.G[ln]);
       k=M.nextAlongSplit(k,1); // corner
       lc=ln;
       }   
      }
   }   
  //*********************************************++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ make 2D loop

  //********************************************* show flattened baffle
  void showFlattenedBaffleMARK() {
    if(n < 2) return;
    translate(width/4,20);
    scale(-1);
    
    ellipse(0,0,8,8);
    int maxI = floor(n/2);
    int i = 1;
    pt a = P[i], b = P[n-i];
    
    float l = d(a,b);
    pt A = P(l/2,0,0), B = P(-l/2,0,0); // 2D flattened version
    pt M = P(0,0,0);
    show(A,B);
    
    int bad = 0;
    i++;
    for(; i<maxI; i++) {
      pt c = P[n-i], d = P[i];
      pt C = P(), D = P();
      stroke(orange);
      // attempt to layout parallel
      if(!fourBarParallel(a,b,c,d,A,B,C,D)) {
        stroke(yellow);
        // if that fails, use equal angle layout
        if(!fourBarEqualAngle(a, b, c, d, A, B, C, D)) {
          bad++;
          continue;
        }
      }
      show(D,C);
      stroke(yellow);
      pt N = CPonE(M, C, D); // find a new spine center on this rib
      show(M,N);
      
      float step = 10;
      float al = d(A,M), bl = d(B,M), cl = d(C,N), dl = d(D,N);
      float t;
      
      // leftward fill
      vec MB = U(M,B), NC = U(N,C);
      for(t = 0; t < min(bl,cl); t += step) show(P(M,t,MB), P(N,t,NC));
      t -= step;
      if(bl < cl) for(; t < cl; t += step)  show(B,P(N,t,NC));
      else for(; t < bl; t += step)  show(C,P(M,t,MB));
      
      // rightward fill
      vec MA = U(M,A), ND = U(N,D);
      for(t = 0; t < min(al,dl); t += step) show(P(M,t,MA), P(N,t,ND));
      t -= step;
      if(al < dl) for(; t < dl; t += step)  show(A,P(N,t,ND));
      else for(; t < al; t += step)  show(D,P(M,t,MA));
      
      stroke(red);
      show(A,D); show(B,C);
      
      A = D; B = C;
      a = d; b = c;
      M = N;
    }
  }
  
  pt[] makeBaffleOutline() {
    if(n < 2) return null;
    int maxI = floor(n/2);
    
    pt[] baffle = new pt[n]; // result
    
    
    int i = 1;
    pt a = P[i], b = P[n-i];
    
    float l = d(a,b);
    pt A = P(l/2,0,0), B = P(-l/2,0,0);
    baffle[0] = P(0,0,0); // the first triangle, 
    baffle[i] = A; baffle[n-i] = B;
    
    int bad = 0;
    i++;
    for(; i<maxI; i++) {
      pt c = P[n-i], d = P[i];
      pt C = P(), D = P();
      // attempt to layout parallel
      if(!fourBarParallel(a,b,c,d,A,B,C,D)) {
        // if that fails, use equal angle layout
        if(!fourBarEqualAngle(a, b, c, d, A, B, C, D)) {
          bad++;
          continue;
        }
      }
      
      baffle[n-i] = C;
      baffle[i] = D;
      
      A = D; B = C;
      a = d; b = c;
    }
    // ignore the last triangle (if it exists)
    if(n%2 == 0) baffle[maxI] = P(baffle[maxI-1],baffle[maxI+1]); 
    return baffle;
  }
  
  void makeBaffleMesh(Mesh mesh, float gridSize) {
    pt[] F = makeBaffleOutline();
    if(F == null) return;
    mesh.addVertex(P(0,0,0)); // off by one?
    pt A = null, B = null;
    int r = 0; 
    pt M = P();
    int maxI = floor(n/2);
    for(int i = 1; i < maxI; i++) {
      int ui = mesh.nv, vi = r; r = mesh.nv;
      
      pt c = P[n-i], d = P[i];
      vec cdu = U(c,d);
      
      float tMax = d(c,d);
      for(float t = 0; t < tMax; t += gridSize){
        mesh.addVertex(P(c,t,cdu));
      }
      mesh.addVertex(d);
      
      pt C = F[n-i], D = F[i];
      pt N = CPonE(M, C, D);
      
      if(i != 1) {
        float u = -d(C,N), v = -d(B,M);
        float uMax = d(N,D), vMax = d(M,A);
        while(u < uMax || v < vMax) {
          if((u < v || v >= vMax) && u < uMax) {
            float uNext = min(u+gridSize, uMax);
            mesh.addTriangle(ui, vi, ui+1);
            u = uNext; ui++;
          } else {
            float vNext = min(v+gridSize, vMax);
            mesh.addTriangle(ui, vi, vi+1);
            v = vNext; vi++;
          }
        }
      }
      M = N;
      B = C; A = D;
    }
    try {
      mesh.computeO();
    } catch(ArrayIndexOutOfBoundsException e) {
      e.printStackTrace();
    }
  }
  
  boolean fourBarParallel(pt a, pt b, pt c, pt d, pt A, pt B, pt C, pt D) {
    float l0 = d(a,b), l1 = d(b,c), l2 = d(c,d), l3 = d(d,a);
    vec u = U(A,B);
    float x = (sq(l1)-sq(l3)-sq(l2-l0)) /  (-2*l3*(l2-l0));
    if(x > 1 || x < -1) return false;
    D.set(P(A, l3, V(u).rotate(PI-acos(x), II, JJ)));
    C.set(P(D, l2, u));
    return true;
  }
  
  boolean fourBarEqualAngle(pt a, pt b, pt c, pt d, pt A, pt B, pt C, pt D) {
    float l1 = d(b,c), l2 = d(c,d), l3 = d(d,a);
    
    float quality = 1f; // maximum allowable error in distance from c to d
    
    float maxAngle = PI;
    float minAngle = 0;
    float angle = PI/2;
    float diff = 0;
    
    vec AB = U(A,B);
    vec BA = V(AB).rev();
    float l2cur;
    int maxJ = 50;
    int j = 0;
    while(true) {
      D.set(P(A, l3, V(AB).rotate(angle, II, JJ)));
      C.set(P(B, l1, V(BA).rotate(-angle, II, JJ)));
      l2cur = d(C,D);
      if(j++ > maxJ) break;
      diff = l2-l2cur;
      if(abs(diff) < quality) break;
      if(diff < 0) {
        minAngle = angle;
      } else {
        maxAngle = angle;
      }
      angle = (minAngle+maxAngle)/2;
    }
    return j < maxJ;
  }
  
  vec II = V(1,0,0), JJ = V(0,1,0);
  }  // end class LOOP

 

  
  
int ISLAND_SIZE = 30;
int MAX_ISLANDS = 40000;
int waterColor = 8;
int landColor = 9;

int numIslands = 0;
StepWiseRingExpander g_stepWiseRingExpander = new StepWiseRingExpander();

class SubmersionCounter
{
  private int m_numSubmersions;
  private int m_badSubmersions;
  
  public SubmersionCounter()
  {
    m_numSubmersions = 0;
    m_badSubmersions = 0;
  }
  
  public void incSubmersion()
  {
    m_numSubmersions++;
  }
  
  public void incBadSubmersion()
  {
    m_badSubmersions++;
    m_numSubmersions++;
  }
  
  public int numSubmersions()
  {
    return m_numSubmersions;
  }
  
  public int numBadSubmersions()
  {
    return m_badSubmersions;
  }
}

SubmersionCounter g_submersionCounter;

class StepWiseRingExpander
{
  private int m_lastLength;
  private boolean m_stepMode;
  
  StepWiseRingExpander()
  {
    m_lastLength = 0;
    m_stepMode = false;
  }
  
  void updateStep()
  {
    m_lastLength++;
  }
  
  public void setStepMode(boolean fStepMode)
  {
    m_stepMode = fStepMode;
  }
  
  public void setLastLength(int lastLength)
  {
    m_lastLength = lastLength;
  } 
  
  public boolean fStepMode()
  {
    return m_stepMode;
  }
  
  public int lastLength()
  {
    return m_lastLength;
  }
}


class VisitState
{
  private int m_corner;

  public VisitState(int corner)
  {
    m_corner = corner;
  }

  public int corner()
  {
    return m_corner;
  }
}

class SubmersionState
{
  private int m_corner;
  private int m_numToSubmerge;
  private Stack<Integer> m_bitString;
  private boolean m_fFirstState;
  private int m_LR;
  private int m_numChild;

  public SubmersionState(int corner, int numToSubmerge, Stack<Integer> bitString, int LR, boolean fFirst)
  {
    m_corner = corner;
    m_numToSubmerge = numToSubmerge;
    m_bitString = bitString;
    m_fFirstState = fFirst;
    m_LR = LR;
    m_numChild = 0;
  }

  public void setFirstState(boolean fFirstState) { m_fFirstState = fFirstState; }
  public void setLR(int LR) { m_LR = LR; }
  public void setNumChild(int numChild) { m_numChild = numChild; }
  public int numChild() { return m_numChild; }
  public int LR() { return m_LR; }
  public int corner() { return m_corner; }
  public int numToSubmerge() { return m_numToSubmerge; }
  public Stack<Integer> bitString() { return m_bitString; }
  public boolean fFirstState() { return m_fFirstState; }
}

class SubmersionStateTry
{
  private int m_corner;
  private int m_numToSubmerge;
  private Stack<Integer> m_bitString;
  private boolean m_fFirstState;
  private int m_result;
  private SubmersionStateTry m_leftChild;
  private SubmersionStateTry m_rightChild;

  public SubmersionStateTry(int corner, int numToSubmerge, Stack<Integer> bitString, boolean fFirst)
  {
    m_corner = corner;
    m_numToSubmerge = numToSubmerge;
    m_bitString = bitString;
    m_fFirstState = fFirst;
    m_result = -1;
    m_leftChild = null;
    m_rightChild = null;
  }

  public void setFirstState(boolean fFirstState) { m_fFirstState = fFirstState; }
  public void setChildren(SubmersionStateTry left, SubmersionStateTry right) { m_leftChild = left; m_rightChild = right; }
  public void setResult(int result) { m_result = result; }
  public void setBitString(Stack<Integer> bitString) { m_bitString = bitString; }
  public int corner() { return m_corner; }
  public int numToSubmerge() { return m_numToSubmerge; }
  public Stack<Integer> bitString() { return m_bitString; }
  public boolean fFirstState() { return m_fFirstState; }
  public SubmersionStateTry left() { return m_leftChild; }
  public SubmersionStateTry right() { return m_rightChild; }
  public int result() { return m_result; }
}

class FormIslandsState
{
  private int m_corner;
  private int m_result;
  private boolean m_fFirstState;
  private int[] m_shoreVertices;
  private FormIslandsState m_leftChild;
  private FormIslandsState m_rightChild;

  public FormIslandsState(int corner, int[] shoreVertices)
  {
    m_corner = corner;
    m_shoreVertices = shoreVertices;
    m_result = -1;
    m_fFirstState = true;
    m_leftChild = null;
    m_rightChild = null;
  }  

  public void setFirstState(boolean fFirstState) { m_fFirstState = fFirstState; }
  public void setChildren(FormIslandsState left, FormIslandsState right) { m_leftChild = left; m_rightChild = right; }
  public void setResult(int result) { m_result = result; }
  public int corner() { return m_corner; }
  public int[] shoreVerts() { return m_shoreVertices; }
  public boolean fFirstState() { return m_fFirstState; }
  public FormIslandsState left() { return m_leftChild; }
  public FormIslandsState right() { return m_rightChild; }
  public int result() { return m_result; }
}

class RingExpanderResult
{
  private int m_seed;
  private int[] m_parentTArray;
  private int m_numTrianglesToColor;
  private int m_numTrianglesColored;
  private Stack<VisitState> m_visitStack;

  Mesh m_mesh;

  public RingExpanderResult(Mesh m, int seed, int[] vertexArray)
  {
    m_seed = seed;
    m_parentTArray = vertexArray;
    m_mesh = m;
    m_numTrianglesToColor = -1;
  }

  private void setColor(int corner)
  {
    m_mesh.tm[m_mesh.t(corner)] = landColor;
  }

  private boolean isValidChild(int childCorner, int parentCorner)
  {
    if ( (m_mesh.hasValidR(parentCorner) && childCorner == m_mesh.r(parentCorner)) || (m_mesh.hasValidL(parentCorner) && childCorner == m_mesh.l(parentCorner)) )
    {
      if (m_parentTArray[m_mesh.v(childCorner)] == m_mesh.t(parentCorner))
      {
        return true;
      }
    }
    return false;
  }

  private void label(int corner)
  {
    fill(255, 0, 0);
    pt vtx = m_mesh.G[m_mesh.v(corner)];
    translate(vtx.x, vtx.y, vtx.z);
    sphere(3);
    translate(-vtx.x, -vtx.y, -vtx.z);
  }

  private void visitAndColor()
  {
    for (int i = 0; i < m_mesh.nt * 3; i++)
    {
      m_mesh.cm[i] = 0;
    }

    while ((m_numTrianglesToColor == -1 || m_numTrianglesColored < m_numTrianglesToColor) && !m_visitStack.empty())
    {
      VisitState currentState = m_visitStack.pop();
      int corner = currentState.corner();
      m_numTrianglesColored++;
      m_mesh.cm[corner] = 1;
      setColor(corner);

      if (isValidChild(m_mesh.l(corner), corner))
      {
        m_visitStack.push(new VisitState(m_mesh.l(corner)));
      }
      if (isValidChild(m_mesh.r(corner), corner))
      {
        m_visitStack.push(new VisitState(m_mesh.r(corner)));
      }
    }
  }

  private void resetState()
  {
    if (m_numTrianglesToColor == -1)
    {
      m_numTrianglesToColor = 0;
    }

    for (int i = 0; i < m_mesh.nt; i++)
    {
      m_mesh.tm[i] = waterColor;
    }

    m_numTrianglesColored = 0;
  }

  private int getCornerOnLR(int anyCorner)
  {
    int tri = m_mesh.t(anyCorner);
    int corner = m_mesh.c(tri);
    if (tri == m_mesh.t(m_seed))
    {
      return m_seed;
    }
    for (int i = 0; i < 3; i++)
    {
      if (m_mesh.t(m_mesh.o(corner)) == m_parentTArray[m_mesh.v(corner)])
      {
        return corner;
      }
      corner = m_mesh.n(corner);
    }

    return -1;
  }
  
  private boolean isOnLR(int corner)
  {
    int cornerOnLR = getCornerOnLR(corner);
    return (cornerOnLR == corner);
  }
  
  private void mergeShoreVertices(int tri, int[] vertsR, int[] vertsL, int[] shoreVerts)
  {
    int cornerInit = m_mesh.c(tri);
    int v1 = m_mesh.v(cornerInit);
    int v2 = m_mesh.v(m_mesh.n(cornerInit));
    int v3 = m_mesh.v(m_mesh.p(cornerInit));

    int index = 0;

    if (v1 == vertsR[0] || v1 == vertsR[1] || v1 == vertsL[0] || v1 == vertsL[1])
    {
      if (!isOnLR(cornerInit))
      {
        shoreVerts[index++] = v1;
      }
    }
    if (v2 == vertsR[0] || v2 == vertsR[1] || v2 == vertsL[0] || v2 == vertsL[1])
    {
      if (!isOnLR(m_mesh.n(cornerInit)))
      {
        shoreVerts[index++] = v2;
      }
    }
    if (v3 == vertsR[0] || v3 == vertsR[1] || v3 == vertsL[0] || v3 == vertsL[1])
    {
      if (!isOnLR(m_mesh.p(cornerInit)))
      {
        shoreVerts[index++] = v3;
      }
    }

    while (index != 2)
    {
      shoreVerts[index++] = -1;
    }
  }

  private void markSubmerged(int tri)
  {
    markUnVisited(tri);    
    m_mesh.tm[tri] = waterColor;
  }

  private boolean hasVertices(int tri, int[] shoreVerts)
  {
    int cornerInit = m_mesh.c(tri);
    int v1 = m_mesh.v(cornerInit);
    int v2 = m_mesh.v(m_mesh.n(cornerInit));
    int v3 = m_mesh.v(m_mesh.p(cornerInit));

    if (v1 == shoreVerts[0] || v1 == shoreVerts[1])
    {
      return true;
    }
    if (v2 == shoreVerts[0] || v2 == shoreVerts[1])
    {
      return true;
    }
    if (v3 == shoreVerts[0] || v3 == shoreVerts[1])
    {
      return true;
    }

    return false;
  }

  private void markAsBeach(int corner, int[] shoreVerts)
  {
    numberIslands(corner, numIslands++);
    m_mesh.tm[m_mesh.t(corner)] = 4;
    shoreVerts[0] = m_mesh.v(m_mesh.n(corner));
    shoreVerts[1] = m_mesh.v(m_mesh.p(corner));
  }

  private void propagateShoreVertices(int tri, int[] vertsChild, int[] shoreVerts)
  {
    int cornerInit = m_mesh.c(tri);
    int v1 = m_mesh.v(cornerInit);
    int v2 = m_mesh.v(m_mesh.n(cornerInit));
    int v3 = m_mesh.v(m_mesh.p(cornerInit));

    int index = 0;

    if (v1 == vertsChild[0] || v1 == vertsChild[1])
    {
     if (!isOnLR(cornerInit))
     {
        shoreVerts[index++] = v1;
     }
    }
    if (v2 == vertsChild[0] || v2 == vertsChild[1])
    {
      if (!isOnLR(m_mesh.n(cornerInit)))
      {
        shoreVerts[index++] = v2;
      }
    }
    if (v3 == vertsChild[0] || v3 == vertsChild[1])
    {
      if (!isOnLR(m_mesh.p(cornerInit)))
      {
        shoreVerts[index++] = v3;
      }
    }

    while (index != 2)
    {
      shoreVerts[index++] = -1;
    }
  }

  //Utilities to determine leaf, single Parent, etc
  private int getNumSuccessors(int corner)
  {
    int numSuc = 0;

    Stack<VisitState> succStack = new Stack<VisitState>();
    succStack.push(new VisitState(corner));

    while (!succStack.empty())
    {
      corner = succStack.pop().corner();
      if (isValidChild(m_mesh.r(corner), corner) && m_mesh.tm[m_mesh.t(m_mesh.r(corner))] != waterColor)
      {
        succStack.push(new VisitState(m_mesh.r(corner)));
        numSuc++;
      }
      if (isValidChild(m_mesh.l(corner), corner) && m_mesh.tm[m_mesh.t(m_mesh.l(corner))] != waterColor)
      {
        succStack.push(new VisitState(m_mesh.l(corner)));
        numSuc++;
      }
    }
    return numSuc;
  }

  private int getNumChild(int corner)
  {
    int numChild = 0;
    if (isValidChild(m_mesh.r(corner), corner) && m_mesh.tm[m_mesh.t(m_mesh.r(corner))] != waterColor)
    {
      numChild++;
    }
    if (isValidChild(m_mesh.l(corner), corner) && m_mesh.tm[m_mesh.t(m_mesh.l(corner))] != waterColor)
    {
      numChild++;
    }
    return numChild;
  }

  private boolean isLeaf(int corner)
  {
    return (getNumChild(corner) == 0);
  }

  private boolean isSingleParent(int corner)
  {
    return (getNumChild(corner) == 1);
  }

  private int getChild(int corner)
  {
    if (isValidChild(m_mesh.l(corner), corner) && m_mesh.tm[m_mesh.t(m_mesh.l(corner))] != waterColor)
    {
      return m_mesh.l(corner);
    }
    if (isValidChild(m_mesh.r(corner), corner) && m_mesh.tm[m_mesh.t(m_mesh.r(corner))] != waterColor)
    {
      return m_mesh.r(corner);
    } 
    return -1;
  }

  private void markVisited(int triangle, int islandNumber)
  {
    m_mesh.triangleIsland[triangle] =  
    m_mesh.island[m_mesh.c(triangle)] = islandNumber;
    m_mesh.island[m_mesh.n(m_mesh.c(triangle))] = islandNumber;
    m_mesh.island[m_mesh.p(m_mesh.c(triangle))] = islandNumber;
  }
  
  private void markUnVisited(int triangle)
  {
    m_mesh.triangleIsland[triangle] = -1;
    m_mesh.island[m_mesh.c(triangle)] = -1;
    m_mesh.island[m_mesh.n(m_mesh.c(triangle))] = -1;
    m_mesh.island[m_mesh.p(m_mesh.c(triangle))] = -1;
  }

  //Perform an actual submerge from a corner, the number of triangles to submerge and the bitString -- the path to follow for the submersion
  private int performSubmerge(int corner, int numToSubmerge, Stack<Integer> origBitString)
  {
    Stack<SubmersionState> submergeStack = new Stack<SubmersionState>();
    submergeStack.push(new SubmersionState(corner, numToSubmerge, origBitString, 0, true));
    int retVal = 0;
    //print ("Num to submerge " + numToSubmerge);
    int countTwo = 0;
    
    while (!submergeStack.empty())
    {
      SubmersionState cur = submergeStack.pop();
      corner = cur.corner(); numToSubmerge = cur.numToSubmerge(); Stack<Integer> bitString = cur.bitString();
      
      if (cur.fFirstState())
      {
          if (isLeaf(corner))
          {
            cur.setNumChild(0);
            cur.setFirstState(false);
            submergeStack.push(cur);
            markSubmerged(m_mesh.t(corner));
            if (numToSubmerge == 1)
            {
              retVal = -1;
            }
            else
            {
              retVal++;
            }
          }
          else if (isSingleParent(corner))
          {
            cur.setNumChild(1);
            cur.setFirstState(false);
            submergeStack.push(cur);
            submergeStack.push(new SubmersionState(getChild(corner), numToSubmerge, bitString, 0, true));
          }
          else
          {
            countTwo++;
            int popped = -1;
            //TODO msati3: Fix empty stack bug for seed 166
            popped = bitString.pop();
            cur.setNumChild(2);
            cur.setFirstState(false);
            cur.setLR(popped);
            submergeStack.push(cur);
            if (popped == 1)
            {
              submergeStack.push(new SubmersionState(m_mesh.l(corner), numToSubmerge, bitString, 0, true));
            }
            else if (popped == -1)
            {
              submergeStack.push(new SubmersionState(m_mesh.r(corner), numToSubmerge, bitString, 0, true));
            }
            else
            {
               submergeStack.push(new SubmersionState(m_mesh.r(corner), numToSubmerge, bitString, 0, true));
               submergeStack.push(new SubmersionState(m_mesh.l(corner), numToSubmerge, bitString, 0, true));
            }
          }
          continue;
        }
        else //fFirstState
        {
            if (cur.numChild() == 0)
            {
            }
            else if (cur.numChild() == 1)
            {
              if (retVal > numToSubmerge)
              {
              }
              else if (retVal == -1)
              {
                retVal = -1;
              }
              else if (retVal+1 == numToSubmerge)
              {
                markSubmerged(m_mesh.t(corner));
                retVal = -1;
              }
              else
              {
                markSubmerged(m_mesh.t(corner));
                retVal++;
              }
           }
           else //!leaf and !singleParent
           {
             int popped = cur.LR();
             if (popped == 1)
             {
                if (DEBUG && DEBUG_MODE >= LOW)
                {
                  if (retVal < numToSubmerge && retVal != -1)
                  {
                    print("Fatal bug in submersion! Should not happen!!" + retVal);
                  }
                }
                retVal = -1;
             }
             else if (popped == -1)
             {
               if (DEBUG && DEBUG_MODE >= LOW)
               {
                 if (retVal < numToSubmerge && retVal != -1)
                 {
                   print("Fatal bug in submersion! Should not happen!!" + retVal);
                 }
               }
               retVal = -1;
            }
            else
            {
              if (retVal == -1)
              {
               //Case when l + r sum to total num submerged
              }
              else if (retVal + 1 == numToSubmerge)
              {
                markSubmerged(m_mesh.t(corner));
                retVal = -1;
              }
              else
              {
                markSubmerged(m_mesh.t(corner));
                retVal++;
              }
            }
          }
        }//fFirstState
      }//while
      return retVal;
  }//code

  private int trySubmerge(int corner, int numToSubmerge, Stack<Integer> bitString)
  {
    Stack<SubmersionStateTry> submergeStack = new Stack<SubmersionStateTry>();
    submergeStack.push(new SubmersionStateTry(corner, numToSubmerge, bitString, true));
    int finalRet = -1;
    
    while (!submergeStack.empty())
    {
      SubmersionStateTry cur = submergeStack.pop();
      corner = cur.corner(); numToSubmerge = cur.numToSubmerge(); bitString = cur.bitString();
      
      if (cur.fFirstState())
      {
        if (isLeaf(corner))
        {
          if (numToSubmerge == 1)
          {
            cur.setResult(-1);
          }
          else
          {
            cur.setResult(1);
          }
        }
        else if (isSingleParent(corner))
        {
          SubmersionStateTry childState = new SubmersionStateTry(getChild(corner), numToSubmerge, bitString, true);
          cur.setFirstState(false);
          cur.setChildren(childState, null);
          submergeStack.push(cur);          
          submergeStack.push(childState);
        }
        else
        {
          Stack<Integer> lStack = new Stack<Integer>();
          Stack<Integer> rStack = new Stack<Integer>();
          SubmersionStateTry lChild = new SubmersionStateTry(m_mesh.l(corner), numToSubmerge, lStack, true);
          SubmersionStateTry rChild = new SubmersionStateTry(m_mesh.r(corner), numToSubmerge, rStack, true);
          cur.setFirstState(false);
          cur.setChildren(lChild, rChild);
          submergeStack.push(cur);
          submergeStack.push(lChild);
          submergeStack.push(rChild);
        }
        continue;
      }       
      else //firstState
      {
        if (isLeaf(corner))
        {
        }
        else if (isSingleParent(corner))
        { 
          int result = cur.left().result();
          Stack<Integer> lStack = cur.left().bitString();
          if (result > numToSubmerge)
          {
          }
          else if (result == -1 || result+1 == numToSubmerge)
          {
            result = -1;
          }
          else
          {
            result++;
          }
          cur.setBitString(lStack);
          cur.setResult(result);
        }
        else
        {
          int numL = cur.left().result();
          int numR = cur.right().result();
          Stack<Integer> lStack = cur.left().bitString();
          Stack<Integer> rStack = cur.right().bitString();
        
            /*print ("\nrStack ");
            for (int i = 0; i < rStack.size(); i++)
            {
              print(rStack.get(i) + " ");
            }
            print ("\nlStack ");
            for (int i = 0; i < lStack.size(); i++)
            {
              print(lStack.get(i) + " ");
            }*/

          if (numL == -1)
          {
            combine(bitString, lStack);
            bitString.push(1);
            cur.setResult(-1);
          }
          else if (numR == -1)
          {
            combine(bitString, rStack);
            bitString.push(-1);
            cur.setResult(-1);
          }
          else if (numL > numToSubmerge || numR > numToSubmerge)
          {
            if (numL > numToSubmerge && numR > numToSubmerge)
            {
              if (numL < numR)
              {
                combine(bitString, lStack);
                bitString.push(1);
              }
              else
              {
                combine(bitString, rStack);
                bitString.push(-1);
              }
              cur.setResult(((numL < numR) ? numL : numR));
            }
            else if (numL > numToSubmerge)
            {
              combine(bitString, lStack);
              bitString.push(1);
              cur.setResult(numL);
            }
            else
            {
              combine(bitString, rStack);
              bitString.push(-1);
              cur.setResult(numR);
            }
          }
          else
          {
            combine(bitString, rStack);
            combine(bitString, lStack);
            bitString.push(0);
 
            if (numL + numR + 1 == numToSubmerge)
            {
              cur.setResult(-1);
            }
            else if (numL + numR == numToSubmerge)
            {
              cur.setResult(-1);
            }
            else
            {
              cur.setResult(numL + numR + 1);
            }
          }

          /*print("\nBitString ");
          for (int i = 0; i < bitString.size(); i++)
          {
            print(bitString.get(i) + " ");
          }*/
        }
      } //if stage 2
      bitString = cur.bitString();
      finalRet = cur.result();
    } //while !stackEmpty
    return finalRet;
  }

  private void combine(Stack<Integer> mainStack, Stack<Integer> otherStack)
  {
    Stack<Integer> temp = new Stack<Integer>();
    while(!otherStack.empty())
    {
      temp.push(otherStack.pop());
    }
    while(!temp.empty())
    {
      mainStack.push(temp.pop());
    }
  }
  
  private void submergeAll(int corner)
  {
    Stack<Integer> submergeStack = new Stack<Integer>();
    submergeStack.push(corner);

    while (!submergeStack.empty())
    {
      corner = submergeStack.pop();
      if (isValidChild(m_mesh.r(corner), corner) && m_mesh.tm[m_mesh.t(m_mesh.r(corner))] != waterColor)
      {
        submergeStack.push(m_mesh.r(corner));
      }
      if (isValidChild(m_mesh.l(corner), corner) && m_mesh.tm[m_mesh.t(m_mesh.l(corner))] != waterColor)
      {
        submergeStack.push(m_mesh.l(corner));
      }
      markSubmerged(m_mesh.t(corner));
    }
  }
  
  private void submergeOther(int corner, int[] shoreVerts)
  {
    Stack<Integer> submergeStack = new Stack<Integer>();
    submergeStack.push(corner);
    
    while (!submergeStack.empty())
    {
      corner = submergeStack.pop();
      if (!hasVertices(m_mesh.t(corner), shoreVerts))
      {
        if (getNumSuccessors(corner) < ISLAND_SIZE)
        {
          submergeAll(corner);
        }
      }
      else
      {
        if (isValidChild(m_mesh.r(corner), corner) && m_mesh.tm[m_mesh.t(m_mesh.r(corner))] != waterColor)
        {
          submergeStack.push(m_mesh.r(corner));
        }
        if (isValidChild(m_mesh.l(corner), corner) && m_mesh.tm[m_mesh.t(m_mesh.l(corner))] != waterColor)
        {
          submergeStack.push(m_mesh.l(corner));
        }
        markSubmerged(m_mesh.t(corner));
      }
    }
  }

  private int formIslesAndGetLength(int corner, int[] origShoreVerts)
  {
    numIslands = 0;
    Stack<FormIslandsState> formIslesStack = new Stack<FormIslandsState>();
    formIslesStack.push(new FormIslandsState(corner, origShoreVerts));
    int finalRet = -1;

    while (!formIslesStack.empty())
    {
      FormIslandsState cur = formIslesStack.pop();
      corner = cur.corner(); 
      int[] curShoreVerts = cur.shoreVerts();

      if (cur.fFirstState())
      {
        FormIslandsState rightChild = null;
        FormIslandsState leftChild = null;

        if (isValidChild(m_mesh.r(corner), corner))
        {
          rightChild = new FormIslandsState(m_mesh.r(corner), new int[2]);
        }
        if (isValidChild(m_mesh.l(corner), corner))
        {
          leftChild = new FormIslandsState(m_mesh.l(corner), new int[2]);
        }

        cur.setChildren(leftChild, rightChild);
        cur.setFirstState(false);
        formIslesStack.push(cur);

        if (rightChild != null)
        {
          formIslesStack.push(rightChild);
        }
        if (leftChild != null)
        {
          formIslesStack.push(leftChild);
        }
        continue;
      }
      else
      {
        int lenL = 0;
        int lenR = 0;
        int[] shoreVertsR = null;
        int[] shoreVertsL = null;

        if (cur.left() != null)
        {
          lenL = cur.left().result();
          shoreVertsL = cur.left().shoreVerts();
        }
        if (cur.right() != null)
        {
          lenR = cur.right().result();
          shoreVertsR = cur.right().shoreVerts();          
        }
        
        if (lenR != 0 && lenL != 0)
        {
          boolean rNeg = (lenR == -1);
          boolean lNeg = (lenL == -1);
          if (rNeg || lNeg)
          {
            if (rNeg && lNeg)
            {
              if (hasVertices(m_mesh.t(corner), shoreVertsR) || hasVertices(m_mesh.t(corner), shoreVertsL))
              {
                mergeShoreVertices(m_mesh.t(corner), shoreVertsR, shoreVertsL, curShoreVerts);
                markSubmerged(m_mesh.t(corner));
                cur.setResult(-1);
              }
              else
              {
                cur.setResult(1);
              }
            }
            else
            {
              int[] shoreVertsNeg = rNeg? shoreVertsR : shoreVertsL; 
              int other = rNeg? m_mesh.l(corner) : m_mesh.r(corner);
              if (hasVertices(m_mesh.t(corner), shoreVertsNeg))
              {
                submergeOther(other, shoreVertsNeg);
                mergeShoreVertices(m_mesh.t(corner), shoreVertsR, shoreVertsL, curShoreVerts);
                markSubmerged(m_mesh.t(corner));
                cur.setResult(-1);
              }
              else
              {
                int lOther = rNeg? lenL : lenR;
                if (lOther+1 == ISLAND_SIZE)
                {
                  markAsBeach(corner, curShoreVerts);
                  cur.setResult(-1);
                }
                else
                {
                  cur.setResult(lOther + 1);
                }
              }
            }
          }
          else
          {
            if (lenR + lenL >= ISLAND_SIZE)
            {
              //Check for possible submersions possible in left branch and right branch recursively
              Stack<Integer> bitStringL = new Stack<Integer>();
              Stack<Integer> bitStringR = new Stack<Integer>();
              int numTrianglesToSubmerge = lenR + lenL - (ISLAND_SIZE - 1);
              int numL = trySubmerge(m_mesh.l(corner), numTrianglesToSubmerge, bitStringL);
              int numR = trySubmerge(m_mesh.r(corner), numTrianglesToSubmerge, bitStringR);
              /*print("Final data and bitString " + lenR + " " + lenL + " " + numL + " " + numR);
              for (int i = 0; i < bitStringL.size(); i++)
              {
                print (" " + bitStringL.get(i) + " ");
              }*/

              //Actually perform the submersion using the bitstring as a guide. TODO msati3: Can the bitstring be removed?
              if (numL == -1)
              {
                performSubmerge(m_mesh.l(corner), numTrianglesToSubmerge, bitStringL);
                markAsBeach(corner, curShoreVerts);
                cur.setResult(-1);
              }
              else if (numR == -1)
              {
                performSubmerge(m_mesh.r(corner), numTrianglesToSubmerge, bitStringR);
                markAsBeach(corner, curShoreVerts);
                cur.setResult(-1);
              }
              else if (numL > numTrianglesToSubmerge || numR > numTrianglesToSubmerge)
              {
                print("Here");
                //Select to submerge the side that leads to lesser submersions
                if (numL < numR)
                {
                  performSubmerge(m_mesh.l(corner), numTrianglesToSubmerge, bitStringL);
                  int numTrianglesLeft = lenR + lenL + 1 - numL;
                  cur.setResult(numTrianglesLeft);
                }
                else
                {
                  performSubmerge(m_mesh.r(corner), numTrianglesToSubmerge, bitStringR);
                  int numTrianglesLeft = lenR + lenL + 1 - numR;
                  cur.setResult(numTrianglesLeft);
                }
                g_submersionCounter.incSubmersion();
              }
              else //extremely bad case. Submerge the entire island :O..can't be helped.
              {
                print("Here as well");
                performSubmerge(m_mesh.l(corner), numTrianglesToSubmerge, bitStringL);
                performSubmerge(m_mesh.l(corner), numTrianglesToSubmerge, bitStringR);
                markSubmerged(m_mesh.t(corner));
                curShoreVerts[0] = -1;
                curShoreVerts[1] = -1;
                cur.setResult(-1);
                g_submersionCounter.incBadSubmersion();
              }
            }
            else
            {
              if (lenR + lenL + 1 == ISLAND_SIZE)
              {
                markAsBeach(corner, curShoreVerts);
                cur.setResult(-1);
              }
              else
              {
                cur.setResult(lenR + lenL + 1);
              }
            }
          }
        }
        else if (lenR == 0 && lenL == 0)
        {
          cur.setResult(1); //Leaf
        }
        else
        {
          int lenChild = (lenR == 0) ? lenL : lenR;
          int[] shoreVertsChild = (lenR == 0)? shoreVertsL : shoreVertsR; 
          if (lenChild == -1)
          {
            if (hasVertices(m_mesh.t(corner), shoreVertsChild))
            {
              markSubmerged(m_mesh.t(corner));
              propagateShoreVertices(m_mesh.t(corner), shoreVertsChild, curShoreVerts);
              cur.setResult(-1);
            }
            else
            {
              cur.setResult(1);
            }
          }
          else
          {
            if (lenChild + 1 == ISLAND_SIZE)
            {
              markAsBeach(corner, curShoreVerts);
              int cnr = m_mesh.o(corner);
              //print("The shore vertices are " + shoreVerts[0] + " " + shoreVerts[1] + ". The parent vertices are " + m_mesh.v(cnr) + " " + m_mesh.v(m_mesh.n(cnr)) + "  " + m_mesh.v(m_mesh.p(cnr)) + "\n");
              //DEBUG
              if (getCornerOnLR(m_mesh.t(m_mesh.cc)) == m_mesh.t(cnr))
              {
                //print("The shore vertices are " + shoreVerts[0] + " " + shoreVerts[1] + ". The parent vertices are " + m_mesh.v(cnr) + " " + m_mesh.v(m_mesh.n(cnr)) + "  " + m_mesh.v(m_mesh.p(cnr)) + "\n");
              }
              cur.setResult(-1);
            }
            else
            {
              cur.setResult(lenChild + 1);
            }
          }
        }        
      }//if !state.fFirst
      finalRet = cur.result();
    }//while !stack.empty
    return finalRet;
  }//function    
  
  private void numberIslands(int corner, int islandNumber)
  {
    Stack<Integer> markStack = new Stack<Integer>();
    markStack.push(corner);
    int count = 0;

    while (!markStack.empty())
    {
      corner = markStack.pop();
      if (isValidChild(m_mesh.r(corner), corner) && m_mesh.tm[m_mesh.t(m_mesh.r(corner))] != waterColor)
      {
        markStack.push(m_mesh.r(corner));
      }
      if (isValidChild(m_mesh.l(corner), corner) && m_mesh.tm[m_mesh.t(m_mesh.l(corner))] != waterColor)
      {
        markStack.push(m_mesh.l(corner));
      }
      markVisited(m_mesh.t(corner), islandNumber);
      count++;
    }
    if (islandNumber == 6)
    {
      print("Count " + count);
    }
  }

  private int getLength(int corner)
  {
    int rightLen = 0;
    int leftLen = 0;
    if (isValidChild(m_mesh.r(corner), corner))
    {
      rightLen = getLength(m_mesh.r(corner));
    }
    if (isValidChild(m_mesh.l(corner), corner))
    {
      leftLen = getLength(m_mesh.l(corner));
    }

    return rightLen + leftLen + 1;
  }

  public void advanceStep()
  {
    if (m_numTrianglesToColor != -1)
    {
      m_numTrianglesToColor++;
    }
  }

  public void stepColorRingExpander()
  {
    resetState();
    m_visitStack = new Stack<VisitState>();
    m_visitStack.push(new VisitState(m_seed));
    visitAndColor();
    m_mesh.tm[m_mesh.t(m_seed)] = 3;
  }

  public void colorRingExpander()
  {
    resetState();
    m_numTrianglesToColor = -1;
    m_visitStack = new Stack<VisitState>();
    m_visitStack.push(new VisitState(m_seed));
    visitAndColor();
    m_mesh.tm[m_mesh.t(m_seed)] = 3;
  }
  
  private boolean isBreakerTriangle(int triangle)
  {
    int v1 = m_mesh.v(m_mesh.c(triangle));
    int v2 = m_mesh.v(m_mesh.n(m_mesh.c(triangle)));
    int v3 = m_mesh.v(m_mesh.p(m_mesh.c(triangle)));

    if (m_mesh.island[v1] != -1 && m_mesh.island[v2] != -1 && m_mesh.island[v3] != -1)
    {
      if ((m_mesh.island[v1] != m_mesh.island[v2]) && (m_mesh.island[v1] != m_mesh.island[v3]) && (m_mesh.island[v2] != m_mesh.island[v3]))
      {
        return true;
      }
    }
    return false;
  }
  
  public void formIslands(int cornerToStart)
  {
    //init
    int[] shoreVertices = {
      -1, -1
    };
    if (cornerToStart != -1)
    {
      m_mesh.cc = cornerToStart;
    }
    cornerToStart = m_mesh.cc;

    cornerToStart = getCornerOnLR(cornerToStart);
    if (cornerToStart == -1)
    {
      print("Correct corner not found. Returning");
      return ;  
    }
    
    for (int i = 0; i < 3 * m_mesh.nt; i++)
    {
      m_mesh.island[i] = -1;
    }
    for (int i = 0; i < m_mesh.nt; i++)
    {
      m_mesh.triangleIsland[i] = -1;
    }

    g_submersionCounter = new SubmersionCounter();
    int length = formIslesAndGetLength(cornerToStart, shoreVertices);
    numIslands++;

    if (g_stepWiseRingExpander.fStepMode())
    {
      if (length != g_stepWiseRingExpander.lastLength())
      { 
        g_stepWiseRingExpander.setLastLength(length);
        if (length < ISLAND_SIZE && length != -1)
        {
          numIslands--;
          submergeAll(cornerToStart);
          g_submersionCounter.incBadSubmersion();
        }
      }
    }
    else
    {
      if (length < ISLAND_SIZE && length != -1)
      {
        numIslands--;
        submergeAll(cornerToStart);
        g_submersionCounter.incBadSubmersion();
      }
    }

    print("\nThe selected corner for starting is " + m_mesh.cc);
    print("The length of the last island is " + length);
    print("Number of islands is " + numIslands);
    print("Number of submersions " + g_submersionCounter.numSubmersions() + " number of bad submersions " + g_submersionCounter.numBadSubmersions());
  }
  
  public int seed()
  {
    return m_seed;
  }
}

class ColorResult
{
  private int m_numTriangles;
  private int m_countLand;
  private int m_countStraits;
  private int m_countSeparators;
  private int m_countLagoons;
  private int m_countWater;
  private int m_totalVerts;
  private int m_waterVerts;
  private int m_normalVerts;
  
  ColorResult(int nt, int countLand, int countStraits, int countSeparators, int countLagoons, int countWater, int totalVerts, int waterVerts, int normalVerts)
  {
    m_numTriangles = nt;
    m_countLand = countLand;
    m_countStraits = countStraits;
    m_countSeparators = countSeparators;
    m_countLagoons = countLagoons;
    m_countWater = countWater;
    m_totalVerts = totalVerts;
    m_waterVerts = waterVerts;
    m_normalVerts = normalVerts;
  }
  
  int total() { return m_numTriangles; }
  int land() { return m_countLand; }
  int straits() { return m_countStraits; }
  int separators() { return m_countSeparators; }
  int lagoons() { return m_countLagoons; }
  int water() { return m_countWater; }
  int totalVerts() { return m_totalVerts; }
  int waterVerts() { return m_waterVerts; }
  int normalVerts() { return m_normalVerts; }

  float pLand() { return (float)m_countLand*100/m_numTriangles; }
  float pStraits() { return (float)m_countStraits*100/m_numTriangles; }
  float pSeparators() { return (float)m_countSeparators*100/m_numTriangles; }
  float pLagoons() { return (float)m_countLagoons*100/m_numTriangles; }
  float pWater() { return (float)m_countWater*100/m_numTriangles; }
  float pWaterVerts() { return (float)m_waterVerts*100/m_totalVerts; }
  float pNormalVerts() { return (float)m_normalVerts*100/m_totalVerts; }
}

class StatsCollector
{
  private PrintWriter output;
  
  StatsCollector()
  {
    output = createWriter("stats.csv");
    output.println("Num Triangles in Mesh\t Num triangles not on LR traversal\t Num water triangles after island formation\t Num triangles introduced by island formation\t Num Islands");
  }
  
  private void collectStats(int numTries, int islandSize)
  {
    for (int i = 0; i < numTries; i++)
    {
      ISLAND_SIZE = islandSize;
      int seed = (int)random(M.nt * 3);
      
      RingExpander expander = new RingExpander(M, seed); 
      RingExpanderResult result = expander.completeRingExpanderRecursive();
      M.setResult(result);
      M.showRingExpanderCorners();

      int numWater = 0;

      for (int j = 0; j < M.nt; j++)
      {
        if (M.tm[j] == waterColor )
        {
          numWater++;
        }
      }
      
      M.formIslands(result.seed());
      ColorResult res = M.colorTriangles();

      output.println(ISLAND_SIZE + "\t" + numIslands + "\t" + res.total() + "\t" + numWater + "\t" + (float)numWater*100/res.total() + "\t" + res.land() + "\t" + res.pLand() + "\t" + res.water() + "\t" + res.pWater() + 
                     "\t" + res.straits() + "\t" + res.pStraits() + "\t" + res.lagoons() + "\t" + res.pLagoons() + "\t" + res.separators() + "\t" + res.pSeparators() + "\t" + res.totalVerts() + "\t" + res.normalVerts() + 
                     "\t" + res.pNormalVerts() + "\t" + res.waterVerts() + "\t" + res.pWaterVerts());
    }
  }
  
  public void done()
  {
    output.close();
  }
}
// color utilities in RBG color mode
color red, yellow, green, cyan, blue, magenta, dred, dyellow, dgreen, dcyan, dblue, dmagenta, white, black, orange, grey, metal, dorange, brown, dbrown;
void setColors() {
   red = color(250,0,0);        dred = color(150,0,0);
   magenta = color(250,0,250);  dmagenta = color(150,0,150); 
   blue = color(0,0,250);     dblue = color(0,0,150);
   cyan = color(0,250,250);     dcyan = color(0,150,150);
   green = color(0,250,0);    dgreen = color(0,150,0);
   yellow = color(250,250,0);    dyellow = color(150,150,0);  
   orange = color(250,150,0);    dorange = color(150,50,0);  
   brown = color(150,150,0);     dbrown = color(50,50,0);
   white = color(250,250,250); black = color(0,0,0); grey = color(100,100,100); metal = color(150,150,250);
  }
 color ramp(int v, int mv) {return color(int(float(255)*v/mv),100,int(float(255)*(mv-v)/mv)) ; }
CYL Cylinder  = new CYL(100,200);
class CYL { // *** start CYL class
  pt O=P(0,0,0);            // point on axis
  vec I=V(1,0,0);           // normal
  vec J=V(0,1,0);           // other normal
  vec K=V(0,0,1);           // axis direction (unit vector)
  float r=1;                // radius
  float h=1;                // height
  float a0=-PI/2, a1=PI/2;  // angles
  int k=32;                 // number of tiles
  CYL() {}                  // creation
  CYL(float pr, float ph) {r=pr; h=ph;}  // creation
  void showLines() {        // display
    float da=(a1-a0)/k; pt P=P(O,r,I), Q=P(O,r,I,h,K);
    for(float a=a0; a<=a1; a+=da) show(R(P,a,I,J,O),R(Q,a,I,J,O));
    }
  void through(pt A, pt B, pt C, pt D) { // cylinder passing through 4 points with axis parallel to AC
    h=d(A,C);
    K=U(A,C);  // axis direction
    vec U=M(V(A,B),V(d(V(A,B),K),K)); // vector from axis (A,C) to B 
    vec V=M(V(A,D),V(d(V(A,D),K),K)); // vector from axis (A,C) to D 
    /*
    AO=xU+yV
    AO*U=U*U/2 : bx+my=b/2
    AO*V=V*V/2 : mx+dy=d/2
    with b=U*U, m=U*V, d=V*V
    I=U(OA)
    K=U(AC)
    J=KxI
    */
    float b=d(U,U), m=d(U,V), d=d(V,V); // dot products
    float det = (b*d-m*m)*2;
    float x=d*(b-m)/det, y=b*(d-m)/det;
    O=P(A,x,U,y,V);
    r=d(A,O);   
    I=U(O,A); J=U(N(I,K));

    a0=atan2(d(V(O,B),J),d(V(O,B),I));
    a1=atan2(d(V(O,D),J),d(V(O,D),I));
      //      stroke(red); show(A,U); show(A,V); stroke(green); show(O,V(r,I)); show(O,V(h,K)); show(O,V(r,J));
    }  
  pt project(pt P) {
    pt Q = P(O,d(V(O,P),K),K);
    return P(Q,r,U(Q,P));
    }
  } // *** end CYL class

void writeHelp () {fill(dblue);
    int i=0;
    scribe("MESH VIEWER 2012 (Jarek Rossignac)",i++);
    scribe("MODEL M:load, Y:subdivide, F:fair (smoothen), o:offset, W:write, m:next mesh, T:copyTo",i++);
    scribe("VIEW ;:init, .:focus, ^:on cc, ]:on box center, V:save, v:restore, ",i++);
    scribe("SHOW (:silhouette, B:backfaces, |:normals, .:vertices, -:edges, g:Gouraud/flat, =:translucent",i++);
    scribe("COMPUTE #:volume, _:surface",i++);
    scribe("TRIANGLES /:flip edge, h:hide, u:unhide, d;delete hidden",i++);
    scribe("PICK f:front, b:back, c:cc , s:sc ",i++);
    scribe("CORNERS N:next, P:prev, O:opposite, L:left, R;right, S:swing, U:unswing",i++);
    scribe("VERTICES w:warp x-y, x:warp x-z, W:warp neighborhood x-y, X:warp neighborhood x-z",i++);
    scribe("",i++);

   }
void writeFooterHelp () {fill(dbrown);
    scribeFooter("M:load,",2);
    scribeFooter("?:help, Q:exit",1);
  }
void scribeHeader(String S) {text(S,10,20);} // writes on screen at line i
void scribeHeaderRight(String S) {text(S,width-S.length()*15,20);} // writes on screen at line i
void scribeFooter(String S) {text(S,10,height-10);} // writes on screen at line i
void scribeFooter(String S, int i) {text(S,10,height-10-i*20);} // writes on screen at line i from bottom
void scribe(String S, int i) {text(S,10,i*30+20);} // writes on screen at line i
void scribeAtMouse(String S) {text(S,mouseX,mouseY);} // writes on screen near mouse
void scribeAt(String S, int x, int y) {text(S,x,y);} // writes on screen pixels at (x,y)
void scribe(String S, float x, float y) {text(S,x,y);} // writes at (x,y)
void scribe(String S, float x, float y, color c) {fill(c); text(S,x,y); noFill();}

float currentT = 0;

// CORNER TABLE FOR TRIANGLE MESHES by Jarek Rosignac
// Last edited October, 2011
// example meshesshowShrunkOffsetT
String [] fn= {"HeartReallyReduced.vts","horse.vts","bunny.vts","torus.vts","flat.vts","tet.vts","fandisk.vts","squirrel.vts","venus.vts","mesh.vts","hole.vts","gs_dimples_bumps.vts"};
int fni=0; int fniMax=fn.length; // file names for loading meshes
Boolean [] vis = new Boolean [10]; 
Boolean onTriangles=true, onEdges=true; // projection control
float shrunk; // >0 for showoing shrunk triangles

Mesh baseMesh = new Mesh();
Dictionary<Integer, Integer> vertexForIsland; //A representative vertex of main mesh in a particular island

//========================== class MESH ===============================
class Mesh {
//  ==================================== Internal variables ====================================
 // max sizes, counts, selected corners
 int maxnv = 100000;                         //  max number of vertices
 int maxnt = maxnv*2;                       // max number of triangles
 int nv = 0;                              // current  number of vertices
 int nt = 0;                   // current number of triangles
 int nc = 0;                                // current number of corners (3 per triangle)
 int nvr=0, ntr=0, ncr=0; // remember state to restore
 int cc=0, pc=0, sc=0;                      // current, previous, saved corners
 float vol=0, surf=0;                      // vol and surface
 
 boolean m_fDrawIsles = false;
 
 // primary tables
 int[] V = new int [3*maxnt];               // V table (triangle/vertex indices)
 int[] O = new int [3*maxnt];               // O table (opposite corner indices)
 int[] CForV = new int [maxnv];                  // For querying for any corner for a vertex
 pt[] G = new pt [maxnv];                   // geometry table (vertices)
 pt[] baseG = new pt [maxnv];               // to store the locations of the vertices in their contracted form
 int[] island = new int[3*maxnt];
 int[] triangleIsland = new int[maxnt];
 
 pt[] islandBaryCenter = new pt[MAX_ISLANDS];
 float[] islandArea = new float[MAX_ISLANDS];

 vec[] Nv = new vec [maxnv];                 // vertex normals or laplace vectors
 vec[] Nt = new vec [maxnt];                // triangles normals

 
 // auxiliary tables for bookkeeping
 int[] cm = new int[3*maxnt];               // corner markers: 
 int[] vm = new int[3*maxnt];               // vertex markers: 0=not marked, 1=interior, 2=border, 3=non manifold
 int[] tm = new int[3*maxnt];               // triangle markers: 0=not marked, 

 // other tables
 int[] Mv = new int[maxnv];                  // vertex markers
 int [] Valence = new int [maxnv];          // vertex valence (count of incident triangles)

 int[] Mt = new int[maxnt];                 // triangle markers for distance and other things   
 boolean [] VisitedT = new boolean [maxnt];  // triangle visited
 boolean[] visible = new boolean[maxnt];    // set if triangle visible

 int[] W = new int [3*maxnt];               // mid-edge vertex indices for subdivision (associated with corner opposite to edge)

 pt[] G2 = new pt [maxnv]; //2008-03-06 JJ misc
 boolean [] Border = new boolean [maxnv];   // vertex is border
 boolean [] VisitedV = new boolean [maxnv];  // vertex visited
 int r=2;                                // radius of spheres for displaying vertices
 float [] distance = new float [maxnv];
 // geodesic
 boolean  showPath=false, showDistance=false;  
 boolean[] P = new boolean [3*maxnt];       // marker of corners in a path to parent triangle for tracing back the paths
 int[] Distance = new int[maxnt];           // triangle markers for distance fields 
 int[] SMt = new int[maxnt];                // sum of triangle markers for isolation
 int prevc = 0;                             // previously selected corner
 int rings=2;                           // number of rings for colorcoding


 // box
 pt Cbox = new pt(width/2,height/2,0);                   // mini-max box center
 float rbox=1000;                                        // half-diagonal of enclosing box

 // rendering modes
 Boolean flatShading=true, showEdges=false;  // showEdges shoes edges as gaps. Smooth shading works only when !showEdge

//  ==================================== OFFSET ====================================
 void offset() {
   normals();
   float d=rbox/100;
   for (int i=0; i<nv; i++) G[i]=P(G[i],d,Nv[i]);
   }
 void offset(float d) {
   normals();
   for (int i=0; i<nv; i++) G[i]=P(G[i],d,Nv[i]);
   }
//  ==================================== INIT, CREATE, COPY ====================================
 Mesh() {}

 void copyTo(Mesh M) {
   for (int i=0; i<nv; i++) M.G[i]=G[i];
   M.nv=nv;
   for (int i=0; i<nc; i++) M.V[i]=V[i];
   M.nt=nt;
   for (int i=0; i<nc; i++) M.O[i]=O[i];
   M.nc=nc;
   M.resetMarkers();
   }
 
 void declareVectors() {
   for (int i=0; i<maxnv; i++) {G[i]=P(); Nv[i]=V();};   // init vertices and normals
   for (int i=0; i<maxnt; i++) Nt[i]=V();       // init triangle normals and skeleton lab els
   }

 void resetCounters() {nv=0; nt=0; nc=0;}
 void rememberCounters() {nvr=nv; ntr=nt; ncr=nc;}
 void restoreCounters() {nv=nvr; nt=ntr; nc=ncr;}

 void makeGrid (int w) { // make a 2D grid of w x w vertices
   for (int i=0; i<w; i++) {for (int j=0; j<w; j++) { G[w*i+j].set(height*.8*j/(w-1)+height/10,height*.8*i/(w-1)+height/10,0);}}    
   for (int i=0; i<w-1; i++) {for (int j=0; j<w-1; j++) {                  // define the triangles for the grid
     V[(i*(w-1)+j)*6]=i*w+j;       V[(i*(w-1)+j)*6+2]=(i+1)*w+j;       V[(i*(w-1)+j)*6+1]=(i+1)*w+j+1;
     V[(i*(w-1)+j)*6+3]=i*w+j;     V[(i*(w-1)+j)*6+5]=(i+1)*w+j+1;     V[(i*(w-1)+j)*6+4]=i*w+j+1;}; };
   nv = w*w;
   nt = 2*(w-1)*(w-1); 
   nc=3*nt;  }

 void resetMarkers() { // reset the seed and current corner and the markers for corners, triangles, and vertices
   cc=0; pc=0; sc=0;
   for (int i=0; i<nv; i++) vm[i]=0;
   for (int i=0; i<nc; i++) cm[i]=0;
   for (int i=0; i<nt; i++) tm[i]=0;
   for (int i=0; i<nt; i++) visible[i]=true;
   for (int i = 0; i < island.length; i++) island[i] = -1;
   }
 
 int addVertex(pt P) { G[nv].set(P); nv++; return nv-1;};
 int addVertex(float x, float y, float z) { G[nv].x=x; G[nv].y=y; G[nv].z=z; nv++; return nv-1;};
  
 void addTriangle(int i, int j, int k) {V[nc++]=i; V[nc++]=j; V[nc++]=k; visible[nt++]=true;} // adds a triangle
 void addTriangle(int i, int j, int k, int m) {V[nc++]=i; V[nc++]=j; V[nc++]=k; tm[nt]=m; visible[nt++]=true; } // adds a triangle

 void updateON() {computeO(); normals(); } // recomputes O and normals

  // ============================================= CORNER OPERATORS =======================================
    // operations on a corner
  int t (int c) {return int(c/3);};              // triangle of corner    
  int n (int c) {return 3*t(c)+(c+1)%3;};        // next corner in the same t(c)    
  int p (int c) {return n(n(c));};               // previous corner in the same t(c)  
  int v (int c) {return V[c] ;};                 // id of the vertex of c             
  int o (int c) {return O[c];};                  // opposite (or self if it has no opposite)
  int l (int c) {return o(n(c));};               // left neighbor (or next if n(c) has no opposite)                      
  int r (int c) {return o(p(c));};               // right neighbor (or previous if p(c) has no opposite)                    
  int s (int c) {return n(l(c));};               // swings around v(c) or around a border loop
  int u (int c) {return p(r(c));};               // unswings around v(c) or around a border loop
  int c (int t) {return t*3;}                    // first corner of triangle t
  boolean b (int c) {return O[c]==c;};           // if faces a border (has no opposite)
  boolean vis(int c) {return visible[t(c)]; };   // true if tiangle of c is visible
  boolean hasValidR(int c) { return r(c) != p(c); }
  boolean hasValidL(int c) { return l(c) != n(c); }
  
  int cForV(int v) { if (CForV[v] == -1) { print("Fatal error! The corner for the vertex is -1"); } return CForV[v]; }

    // operations on the selected corner cc
  int t() {return t(cc); }
  int n() {return n(cc); }        Mesh next() {pc=cc; cc=n(cc); return this;};
  int p() {return p(cc); }        Mesh previous() {pc=cc; cc=p(cc); return this;};
  int v() {return v(cc); }
  int o() {return o(cc); }        Mesh back() {if(!b(cc)) {pc=cc; cc=o(cc);}; return this;};
  boolean b() {return b(cc);}             
  int l() {return l(cc);}         Mesh left() {next(); back(); return this;}; 
  int r() {return r(cc);}         Mesh right() {previous(); back(); return this;};
  int s() {return s(cc);}         Mesh swing() {left(); next();  return this;};
  int u() {return u(cc);}         Mesh unswing() {right(); previous();  return this;};

    // geometry for corner c
  pt g (int c) {return G[v(c)];};                // shortcut to get the point of the vertex v(c) of corner c
  pt cg(int c) {pt cPt = P(g(c),.3,triCenter(t(c)));  return(cPt); };   // computes point at corner
  pt corner(int c) {return P(g(c),triCenter(t(c)));   };   // returns corner point

    // normals fot t(c) (must be precomputed)
  vec Nv (int c) {return(Nv[V[c]]);}; vec Nv() {return Nv(cc);}            // shortcut to get the normal of v(c) 
  vec Nt (int c) {return(Nt[t(c)]);}; vec Nt() {return Nt(cc);}            // shortcut to get the normal of t(c) 

    // geometry for corner cc
  pt g() {return g(cc);}            // shortcut to get the point of the vertex v(c) of corner c
  pt gp() {return g(p(cc));}            // shortcut to get the point of the vertex v(c) of corner c
  pt gn() {return g(n(cc));}            // shortcut to get the point of the vertex v(c) of corner c
  void setG(pt P) {G[v(cc)].set(P);} // moves vertex of c to P

     // debugging prints
  void writeCorner (int c) {println("cc="+cc+", n="+n(cc)+", p="+p(cc)+", o="+o(cc)+", v="+v(cc)+", t="+t(cc)+"."+", nt="+nt+", nv="+nv ); }; 
  void writeCorner () {writeCorner (cc);}
  void writeCorners () {for (int c=0; c<nc; c++) {println("T["+c+"]="+t(c)+", visible="+visible[t(c)]+", v="+v(c)+",  o="+o(c));};}

// ============================================= MESH MANIPULATION =======================================
  // pick corner closest to point X
  void pickcOfClosestVertex (pt X) {for (int b=0; b<nc; b++) if(vis[tm[t(b)]]) if(d(X,g(b))<d(X,g(cc))) {cc=b; pc=b; } } // picks corner of closest vertex to X
  void pickc (pt X) {for (int b=0; b<nc; b++) if(vis[tm[t(b)]]) if(d(X,cg(b))<d(X,cg(cc))) {cc=b; pc=b; } } // picks closest corner to X
  void picksOfClosestVertex (pt X) {for (int b=0; b<nc; b++) if(vis[tm[t(b)]]) if(d(X,g(b))<d(X,g(sc))) {sc=b;} } // picks corner of closest vertex to X
  void picks (pt X) {for (int b=0; b<nc; b++)  if(vis[tm[t(b)]]) if(d(X,cg(b))<d(X,cg(sc))) {sc=b;} } // picks closest corner to X

  // move the vertex of a corner
  void setG(int c, pt P) {G[v(c)].set(P);}       // moves vertex of c to P
  Mesh add(int c, vec V) {G[v(c)].add(V); return this;}             // moves vertex of c to P
  Mesh add(int c, float s, vec V) {G[v(c)].add(s,V); return this;}   // moves vertex of c to P
  Mesh add(vec V) {G[v(cc)].add(V); return this;} // moves vertex of c to P
  Mesh add(float s, vec V) {G[v(cc)].add(s,V); return this;} // moves vertex of c to P
  void move(int c) {g(c).add(pmouseY-mouseY,Nv(c));}
  void move(int c, float d) {g(c).add(d,Nv(c));}
  void move() {move(cc); normals();}

  Mesh addROI(float s, vec V) { return addROI(64,s,V);}
  Mesh addROI(int d, float s, vec V) {
     float md=setROI(d); 
     for (int c=0; c<nc; c++) if(!VisitedV[v(c)]&&(Mv[v(c)]!=0))  G[v(c)].add(s*(1.-distance[v(c)]/md),V);   // moves ROI
     smoothROI();
     setROI(d*2); // marks ROI of d rings
     smoothROI(); smoothROI();
     return this;
     }   

  void tuckROI(float s) {for (int i=0; i<nv; i++) if (Mv[i]!=0) G[i].add(s,Nv[i]); };  // displaces each vertex by a fraction s of its normal
  void smoothROI() {computeLaplaceVectors(); tuckROI(0.5); computeLaplaceVectors(); tuckROI(-0.5);};
  
float setROI(int n) { // marks vertices and triangles at a graph distance of maxr
  float md=0;
  int tc=0; // triangle counter
  int r=1; // ring counter
  for(int i=0; i<nt; i++) {Mt[i]=0;};  // unmark all triangles
  Mt[t(cc)]=1; tc++;                   // mark t(cc)
  for(int i=0; i<nv; i++) {Mv[i]=0;};  // unmark all vertices
  while ((tc<nt)&&(tc<n)) {  // while not finished
     for(int i=0; i<nc; i++) {if ((Mv[v(i)]==0)&&(Mt[t(i)]==r)) {Mv[v(i)]=r; distance[v(i)]=d(g(cc),g(i)); md = max(md,distance[v(i)]); };};  // mark vertices of last marked triangles
     for(int i=0; i<nc; i++) {if ((Mt[t(i)]==0)&&(Mv[v(i)]==r)) {Mt[t(i)]=r+1; tc++;};}; // mark triangles incident on last marked vertices
     r++; // increment ring counter
     };
  rings=r;
  return md;
  }

 //  ==========================================================  HIDE TRIANGLES ===========================================
void markRings(int maxr) { // marks vertices and triangles at a graph distance of maxr
  int tc=0; // triangle counter
  int r=1; // ring counter
  for(int i=0; i<nt; i++) {Mt[i]=0;};  // unmark all triangles
  Mt[t(cc)]=1; tc++;                   // mark t(cc)
  for(int i=0; i<nv; i++) {Mv[i]=0;};  // unmark all vertices
  while ((tc<nt)&&(r<=maxr)) {  // while not finished
     for(int i=0; i<nc; i++) {if ((Mv[v(i)]==0)&&(Mt[t(i)]==r)) {Mv[v(i)]=r;};};  // mark vertices of last marked triangles
     for(int i=0; i<nc; i++) {if ((Mt[t(i)]==0)&&(Mv[v(i)]==r)) {Mt[t(i)]=r+1; tc++;};}; // mark triangles incident on last marked vertices
     r++; // increment ring counter
     };
  rings=r; // sets ring variable for rendring?
  }

void hide() {
  visible[t(cc)]=false; 
  if(!b(cc) && visible[t(o(cc))]) cc=o(cc); else {cc=n(cc); if(!b(cc) && visible[t(o(cc))]) cc=o(cc); else {cc=n(cc); if(!b(cc) && visible[t(o(cc))]) cc=o(cc); };};
  }
void purge(int k) {for(int i=0; i<nt; i++) visible[i]=Mt[i]==k;} // hides triangles marked as k


// ============================================= GEOMETRY =======================================

  // enclosing box
  void computeBox() { // computes center Cbox and half-diagonal Rbox of minimax box
    pt Lbox =  P(G[0]);  pt Hbox =  P(G[0]);
    for (int i=1; i<nv; i++) { 
      Lbox.x=min(Lbox.x,G[i].x); Lbox.y=min(Lbox.y,G[i].y); Lbox.z=min(Lbox.z,G[i].z);
      Hbox.x=max(Hbox.x,G[i].x); Hbox.y=max(Hbox.y,G[i].y); Hbox.z=max(Hbox.z,G[i].z); 
      };
    Cbox.set(P(Lbox,Hbox));  rbox=d(Cbox,Hbox); 
    };

// ============================================= O TABLE CONSTRUCTION =========================================
  void computeOnaive() {                        // sets the O table from the V table, assumes consistent orientation of triangles
    resetCounters();
    for (int i=0; i<3*nt; i++) {O[i]=i;};  // init O table to -1: has no opposite (i.e. is a border corner)
    for (int i=0; i<nc; i++) {  for (int j=i+1; j<nc; j++) {       // for each corner i, for each other corner j
        if( (v(n(i))==v(p(j))) && (v(p(i))==v(n(j))) ) {O[i]=j; O[j]=i;};};};}// make i and j opposite if they match         

  void computeO() {
 //   resetMarkers(); 
    int val[] = new int [nv]; for (int v=0; v<nv; v++) val[v]=0;  for (int c=0; c<nc; c++) val[v(c)]++;   //  valences
    int fic[] = new int [nv]; int rfic=0; for (int v=0; v<nv; v++) {fic[v]=rfic; rfic+=val[v];};  // head of list of incident corners
    for (int v=0; v<nv; v++) val[v]=0;   // valences wil be reused to track how many incident corners were encountered for each vertex
    int [] C = new int [nc]; for (int c=0; c<nc; c++) C[fic[v(c)]+val[v(c)]++]=c;  // vor each vertex: the list of val[v] incident corners starts at C[fic[v]]
    for (int i = 0; i < nv; i++){ CForV[i] = -1; }
    for (int i = 0; i < nc; i++){ if (CForV[v(i)] == -1) { CForV[v(i)] = i; } }
    for (int c=0; c<nc; c++) O[c]=c;    // init O table to -1 meaning that a corner has no opposite (i.e. faces a border)
    for (int v=0; v<nv; v++)             // for each vertex...
       for (int a=fic[v]; a<fic[v]+val[v]-1; a++) for (int b=a+1; b<fic[v]+val[v]; b++)  { // for each pair (C[a],C[b[]) of its incident corners
          if (v(n(C[a]))==v(p(C[b]))) {O[p(C[a])]=n(C[b]); O[n(C[b])]=p(C[a]); }; // if C[a] follows C[b] around v, then p(C[a]) and n(C[b]) are opposite
          if (v(n(C[b]))==v(p(C[a]))) {O[p(C[b])]=n(C[a]); O[n(C[a])]=p(C[b]); };        
        };                
     }
  void computeOvis() { // computees O for the visible triangles
 //   resetMarkers(); 
    int val[] = new int [nv]; for (int v=0; v<nv; v++) val[v]=0;  for (int c=0; c<nc; c++) if(visible[t(c)]) val[v(c)]++;   //  valences
    int fic[] = new int [nv]; int rfic=0; for (int v=0; v<nv; v++) {fic[v]=rfic; rfic+=val[v];};  // head of list of incident corners
    for (int v=0; v<nv; v++) val[v]=0;   // valences wil be reused to track how many incident corners were encountered for each vertex
    int [] C = new int [nc]; for (int c=0; c<nc; c++) if(visible[t(c)]) C[fic[v(c)]+val[v(c)]++]=c;  // for each vertex: the list of val[v] incident corners starts at C[fic[v]]
    for (int c=0; c<nc; c++) O[c]=c;    // init O table to -1 meaning that a corner has no opposite (i.e. faces a border)
    for (int v=0; v<nv; v++)             // for each vertex...
       for (int a=fic[v]; a<fic[v]+val[v]-1; a++) for (int b=a+1; b<fic[v]+val[v]; b++)  { // for each pair (C[a],C[b[]) of its incident corners
          if (v(n(C[a]))==v(p(C[b]))) {O[p(C[a])]=n(C[b]); O[n(C[b])]=p(C[a]); }; // if C[a] follows C[b] around v, then p(C[a]) and n(C[b]) are opposite
          if (v(n(C[b]))==v(p(C[a]))) {O[p(C[b])]=n(C[a]); O[n(C[a])]=p(C[b]); };        
        };                
     }

// ============================================= DISPLAY CORNERS and LABELS =============================
  void showMarkers()
  {
    for (int i = 0; i < 3*nt; i++)
    {
      if (cm[i] != 0)
      {
        showCorner(i, 3);
      }
    }
  }

  void showCorner(int c, float r) {if (fShowCorners) {show(cg(c),r);} };   // renders corner c as small ball
  
  void showcc(){noStroke(); fill(blue); showCorner(sc,3); /* fill(green); showCorner(pc,5); */ fill(dred); showCorner(cc,3); } // displays corner markers
  
  void showLabels() { // displays IDs of corners, vertices, and triangles
   fill(black); 
   for (int i=0; i<nv; i++) {show(G[i],"v"+str(i),V(10,Nv[i])); }; 
   for (int i=0; i<nc; i++) {show(corner(i),"c"+str(i),V(10,Nt[i])); }; 
   for (int i=0; i<nt; i++) {show(triCenter(i),"t"+str(i),V(10,Nt[i])); }; 
   noFill();
   }

// ============================================= DISPLAY VERTICES =======================================
  void showVertices () {
    noStroke(); noSmooth(); 
    for (int v=0; v<nv; v++)  {
      if (vm[v]==0) fill(brown,150);
      if (vm[v]==1) fill(red,150);
      if (vm[v]==2) fill(green,150);
      if (vm[v]==3) fill(blue,150);
       show(G[v],r);  
      }
    noFill();
    }

// ============================================= DISPLAY EDGES =======================================
  void showBorder() {for (int c=0; c<nc; c++) {if (b(c) && visible[t(c)]) {drawEdge(c);}; }; };         // draws all border edges
  void showEdges () {for(int c=0; c<nc; c++) drawEdge(c); };  
  void drawEdge(int c) {show(g(p(c)),g(n(c))); };  // draws edge of t(c) opposite to corner c
  void drawSilhouettes() {for (int c=0; c<nc; c++) if (c<o(c) && frontFacing(t(c))!=frontFacing(t(o(c)))) drawEdge(c); }  

// ============================================= DISPLAY TRIANGLES =======================================
  // displays triangle if marked as visible using flat or smooth shading (depending on flatShading variable
  void shade(int t) { // displays triangle t if visible
    if(visible[t])  
      if(flatShading) {beginShape(); vertex(g(3*t)); vertex(g(3*t+1)); vertex(g(3*t+2));  endShape(CLOSE); }
      else {beginShape(); normal(Nv[v(3*t)]); vertex(g(3*t)); normal(Nv[v(3*t+1)]); vertex(g(3*t+1)); normal(Nv[v(3*t+2)]); vertex(g(3*t+2));  endShape(CLOSE); }; 
    }
  
  // display shrunken and offset triangles
  void showShrunkT(int t, float e) {if(visible[t]) showShrunk(g(3*t),g(3*t+1),g(3*t+2),e);}
  void showSOT(int t) {if(visible[t]) showShrunkOffsetT(t,1,1);}
  void showSOT() {if(visible[t(cc)]) showShrunkOffsetT(t(cc),1,1);}
  void showShrunkOffsetT(int t, float e, float h) {if(visible[t]) showShrunkOffset(g(3*t),g(3*t+1),g(3*t+2),e,h);}
  void showShrunkT() {int t=t(cc); if(visible[t]) showShrunk(g(3*t),g(3*t+1),g(3*t+2),2);}
  void showShrunkOffsetT(float h) {int t=t(cc); if(visible[t]) showShrunkOffset(g(3*t),g(3*t+1),g(3*t+2),2,h);}

  // display front and back triangles shrunken if showEdges  
  Boolean frontFacing(int t) {return !cw(E,g(3*t),g(3*t+1),g(3*t+2)); } 
  void showFrontTrianglesSimple() {for(int t=0; t<nt; t++) if(frontFacing(t)) {if(showEdges) showShrunkT(t,1); else shade(t);}};  
 
  void showFrontTriangles() {
     for(int t=0; t<nt; t++) if(frontFacing(t)) {
       if(!visible[t]) continue;
 //      if(tm[t]==1) continue;
       if(tm[t]==0) fill(cyan,155); 
       if(tm[t]==1) fill(green,150); 
       if(tm[t]==2) fill(red,150); 
       if(tm[t]==3) fill(blue,150); 
       if(showEdges) showShrunkT(t,1); else shade(t);
     }
   } 
   
  void showTriangles(Boolean front, int opacity, float shrunk) {
     for(int t=0; t<nt; t++) {
       if(!frontFacing(t)&&showBack) {fill(blue); shade(t); continue;}
       if(!vis[tm[t]] || frontFacing(t)!=front || !visible[t]) continue;
       //if(tm[t]==1) continue; 
       //if(tm[t]==1&&!showMiddle || tm[t]==0&&!showLeft || tm[t]==2&&!showRight) continue; 
       if(tm[t]==0) fill(red,opacity); 
       if(tm[t]==1) fill(brown,opacity); 
       if(tm[t]==2) fill(orange,opacity); 
       if(tm[t]==3) fill(cyan,opacity); 
       if(tm[t]==4) fill(magenta,250); 
       if(tm[t]==5) fill(green,opacity); 
       if(tm[t]==6) fill(blue,250); 
       if(tm[t]==7) fill(#FFCBDB,250); 
       if(tm[t]==8) fill(blue,220); 
       if(tm[t]==9) fill(yellow,250); 
       if(vis[tm[t]]) {if(shrunk!=0) showShrunkT(t,shrunk); else shade(t);}
       }
     }
  
  void showBackTriangles() {for(int t=0; t<nt; t++) if(!frontFacing(t)) shade(t);};  
  void showAllTriangles() {for(int t=0; t<nt; t++) if(showEdges) showShrunkT(t,1); else shade(t);};  
  void showMarkedTriangles() {for(int t=0; t<nt; t++) if(visible[t]&&Mt[t]!=0) {fill(ramp(Mt[t],rings)); showShrunkOffsetT(t,1,1); }};  

//  ==========================================================  PROCESS EDGES ===========================================
  // FLIP 
  void flip(int c) {      // flip edge opposite to corner c, FIX border cases
    if (b(c)) return;
      V[n(o(c))]=v(c); V[n(c)]=v(o(c));
      int co=o(c); 
      
      O[co]=r(c); 
      if(!b(p(c))) O[r(c)]=co; 
      if(!b(p(co))) O[c]=r(co); 
      if(!b(p(co))) O[r(co)]=c; 
      O[p(c)]=p(co); O[p(co)]=p(c);  
    }
  void flip() {flip(cc); pc=cc; cc=p(cc);}

  void flipWhenLonger() {for (int c=0; c<nc; c++) if (d(g(n(c)),g(p(c)))>d(g(c),g(o(c)))) flip(c); } 

  int cornerOfShortestEdge() {  // assumes manifold
    float md=d(g(p(0)),g(n(0))); int ma=0;
    for (int a=1; a<nc; a++) if (vis(a)&&(d(g(p(a)),g(n(a)))<md)) {ma=a; md=d(g(p(a)),g(n(a)));}; 
    return ma;
    } 
  void findShortestEdge() {cc=cornerOfShortestEdge();  } 

//  ========================================================== PROCESS  TRIANGLES ===========================================
 pt triCenter(int i) {return P( G[V[3*i]], G[V[3*i+1]], G[V[3*i+2]] ); };  
 pt triCenter() {return triCenter(t());}  // computes center of triangle t(i) 
 void writeTri (int i) {println("T"+i+": V = ("+V[3*i]+":"+v(o(3*i))+","+V[3*i+1]+":"+v(o(3*i+1))+","+V[3*i+2]+":"+v(o(3*i+2))+")"); };

 
   
//  ==========================================================  NORMALS ===========================================
void normals() {computeTriNormals(); computeVertexNormals(); }
void computeValenceAndResetNormals() {      // caches valence of each vertex
  for (int i=0; i<nv; i++) {Nv[i]=V();  Valence[i]=0;};  // resets the valences to 0
  for (int i=0; i<nc; i++) {Valence[v(i)]++; };
  }
vec triNormal(int t) { return N(V(g(3*t),g(3*t+1)),V(g(3*t),g(3*t+2))); };  
void computeTriNormals() {for (int i=0; i<nt; i++) {Nt[i].set(triNormal(i)); }; };             // caches normals of all tirangles
void computeVertexNormals() {  // computes the vertex normals as sums of the normal vectors of incident tirangles scaled by area/2
  for (int i=0; i<nv; i++) {Nv[i].set(0,0,0);};  // resets the valences to 0
  for (int i=0; i<nc; i++) {Nv[v(i)].add(Nt[t(i)]);};
  for (int i=0; i<nv; i++) {Nv[i].normalize();};            };
void showVertexNormals() {for (int i=0; i<nv; i++) show(G[i],V(10*r,Nv[i]));  };
void showTriNormals() {for (int i=0; i<nt; i++) show(triCenter(i),V(10*r,U(Nt[i])));  };
void showNormals() {if(flatShading) showTriNormals(); else showVertexNormals(); }
vec normalTo(int m) {vec N=V(); for (int i=0; i<nt; i++) if (tm[i]==m) N.add(triNormal(i)); return U(N); }

//  ==========================================================  VOLUME ===========================================
float volume() {float v=0; for (int i=0; i<nt; i++) v+=triVol(i); vol=v/6; return vol; }
float volume(int m) {float v=0; for (int i=0; i<nt; i++) if (tm[i]==m) v+=triVol(i); return v/6; }
float triVol(int t) { return m(P(),g(3*t),g(3*t+1),g(3*t+2)); };  

float surface() {float s=0; for (int i=0; i<nt; i++) s+=triSurf(i); surf=s; return surf; }
float surface(int m) {float s=0; for (int i=0; i<nt; i++) if (tm[i]==m) s+=triSurf(i); return s; }
float triSurf(int t) { if(visible[t]) return area(g(3*t),g(3*t+1),g(3*t+2)); else return 0;};  

// ============================================================= SMOOTHING ============================================================
void computeLaplaceVectors() {  // computes the vertex normals as sums of the normal vectors of incident tirangles scaled by area/2
  computeValenceAndResetNormals();
  for (int i=0; i<3*nt; i++) {Nv[v(p(i))].add(V(g(p(i)),g(n(i))));};
  for (int i=0; i<nv; i++) {Nv[i].div(Valence[i]);};                         };
void tuck(float s) {for (int i=0; i<nv; i++) G[i].add(s,Nv[i]); };  // displaces each vertex by a fraction s of its normal
void smoothen() {normals(); computeLaplaceVectors(); tuck(0.6); computeLaplaceVectors(); tuck(-0.6);};

// ============================================================= SUBDIVISION ============================================================
int w (int c) {return(W[c]);};               // temporary indices to mid-edge vertices associated with corners during subdivision

void splitEdges() {            // creates a new vertex for each edge and stores its ID in the W of the corner (and of its opposite if any)
  for (int i=0; i<3*nt; i++) {  // for each corner i
    if(b(i)) {G[nv]=P(g(n(i)),g(p(i))); W[i]=nv++;}
    else {if(i<o(i)) {G[nv]=P(g(n(i)),g(p(i))); W[o(i)]=nv; W[i]=nv++; }; }; }; } // if this corner is the first to see the edge
  
void bulge() {              // tweaks the new mid-edge vertices according to the Butterfly mask
  for (int i=0; i<3*nt; i++) {
    if((!b(i))&&(i<o(i))) {    // no tweak for mid-vertices of border edges
     if (!b(p(i))&&!b(n(i))&&!b(p(o(i)))&&!b(n(o(i))))
      {G[W[i]].add(0.25,V(P(P(g(l(i)),g(r(i))),P(g(l(o(i))),g(r(o(i))))),(P(g(i),g(o(i)))))); }; }; }; };
  
void splitTriangles() {    // splits each tirangle into 4
  for (int i=0; i<3*nt; i=i+3) {
    V[3*nt+i]=v(i); V[n(3*nt+i)]=w(p(i)); V[p(3*nt+i)]=w(n(i));
    V[6*nt+i]=v(n(i)); V[n(6*nt+i)]=w(i); V[p(6*nt+i)]=w(p(i));
    V[9*nt+i]=v(p(i)); V[n(9*nt+i)]=w(n(i)); V[p(9*nt+i)]=w(i);
    V[i]=w(i); V[n(i)]=w(n(i)); V[p(i)]=w(p(i));
    };
  nt=4*nt; nc=3*nt;  };
  
void refine() { updateON(); splitEdges(); bulge(); splitTriangles(); updateON();}
  
//  ========================================================== FILL HOLES ===========================================
void fanHoles() {for (int cc=0; cc<nc; cc++) if (visible[t(cc)]&&b(cc)) fanThisHole(cc); normals();  }
void fanThisHole() {fanThisHole(cc);}
void fanThisHole(int cc) {   // fill hole with triangle fan (around average of parallelogram predictors). Must then call computeO to restore O table
 if(!b(cc)) return ; // stop if cc is not facing a border
 G[nv].set(0,0,0);   // tip vertex of fan
 int o=0;              // tip corner of new fan triangle
 int n=0;              // triangle count in fan
 int a=n(cc);          // corner running along the border
 while (n(a)!=cc) {    // walk around the border loop 
   if(b(p(a))) {       // when a is at the left-end of a border edge
      G[nv].add( P(P(g(a),g(n(a))),P(g(a),V(g(p(a)),g(n(a))))) ); // add parallelogram prediction and mid-edge point
      o=3*nt; V[o]=nv; V[n(o)]=v(n(a)); V[p(o)]=v(a); visible[nt]=true; nt++; // add triangle to V table, make it visible
      O[o]=p(a); O[p(a)]=o;        // link opposites for tip corner
      O[n(o)]=-1; O[p(o)]=-1;
      n++;}; // increase triangle-count in fan
    a=s(a);} // next corner along border
 G[nv].mul(1./n); // divide fan tip to make it the average of all predictions
 a=o(cc);       // reset a to walk around the fan again and set up O
 int l=n(a);   // keep track of previous
 int i=0; 
 while(i<n) {a=s(a); if(v(a)==nv) { i++; O[p(a)]=l; O[l]=p(a); l=n(a);}; };  // set O around the fan
 nv++;  nc=3*nt;  // update vertex count and corner count
 };




// =========================================== STITCH SHELLS ==================================================================================================================================================== ###
int c1=0, c2=0;
pt Q1 = P();
pt Q2 = P();
void stitch(int m1, int m2, int m3) { // add m3 triangles to sip gap between m1 and m2
   c1=-1; for (int c=0; c<nc; c++) if (tm[t(c)]==m1) if(b(c)) {c1=c; break;} else if(tm[t(o(c))]!=m1) {c1=c; break;} // compute border corner of m1
   if (c1==-1) {c1=0; return ;}; // no border found
   cc=c1;
   pt Q=g(p(c1));
   Q1=Q;
   // search for matching border edge of m2
   float d = 1000000;
   c2=-1; for (int c=0; c<nc; c++) if (tm[t(c)]==m2) {
     if(b(c)) {if( d( P(g(n(c)),g(p(c)) ),Q)<d ) {c2=c; d=d(P(g(n(c)),g(p(c))),Q);}}
     else if(tm[t(o(c))]!=m2) {if(d(P(g(n(c)),g(p(c))),Q)<d) {c2=c; d=d(P(g(n(c)),g(p(c))),Q);}}
     }
     if (c2==-1) {c2=0; return ;};
   sc=c2;  
   addTriangle( v(p(c1)) , v(p(c2)) , v(n(c2)), m3 );
   int sc1=c1, sc2=c2; // record starting corners
   c2=pal(c2);
   boolean e1=false, e2=false; // finished walking around borders
   int i=0;
   while((!e1  || !e2) && i++<nsteps) {
    if(e2 || (!e1 && (d(g(n(c2)),g(n(c1)))) < d(g(p(c2)),g(p(c1)))) ) {addTriangle( v(n(c2)) , v(p(c1)) , v(n(c1)), m3 ); c1=nal(c1); if(c1==sc1) e1=true;}
    else {addTriangle( v(p(c1)) , v(p(c2)) , v(n(c2)), m3 ); c2=pal(c2); if(c2==sc2) e2=true;}
    }
  }

  int nal(int c) {int a=p(c); while (!b(a)&&tm[t(a)]==tm[t(o(a))]) a=p(o(a)); return a; } // returns next corner around loop
  int pal(int c) {int a=n(c); while (!b(a)&&tm[t(a)]==tm[t(o(a))]) a=n(o(a)); return a; } // returns previous corner around loop

// =========================================== STITCH SHELLS (END) ============================================================================================================================================ ###





// =========================================== GEODESIC MEASURES, DISTANCES =============================
void computeDistance(int maxr) { // marks vertices and triangles at a graph distance of maxr
  int tc=0; // triangle counter
  int r=1; // ring counter
  for(int i=0; i<nt; i++) {Mt[i]=0;};  // unmark all triangles
  Mt[t(cc)]=1; tc++;                   // mark t(cc)
  for(int i=0; i<nv; i++) {Mv[i]=0;};  // unmark all vertices
  while ((tc<nt)&&(r<=maxr)) {  // while not finished
     for(int i=0; i<nc; i++) {if ((Mv[v(i)]==0)&&(Mt[t(i)]==r)) {Mv[v(i)]=r;};};  // mark vertices of last marked triangles
     for(int i=0; i<nc; i++) {if ((Mt[t(i)]==0)&&(Mv[v(i)]==r)) {Mt[t(i)]=r+1; tc++;};}; // mark triangles incident on last marked vertices
     r++; // increment ring counter
     };
  rings=r; // sets ring variable for rendring?
  }
  
void computeIsolation() {
  println("Starting isolation computation for "+nt+" triangles");
  for(int i=0; i<nt; i++) {SMt[i]=0;}; 
  for(int c=0; c<nc; c+=3) {println("  triangle "+t(c)+"/"+nt); computeDistance(1000); for(int j=0; j<nt; j++) {SMt[j]+=Mt[j];}; };
  int L=SMt[0], H=SMt[0];  for(int i=0; i<nt; i++) { H=max(H,SMt[i]); L=min(L,SMt[i]);}; if (H==L) {H++;};
  cc=0; for(int i=0; i<nt; i++) {Mt[i]=(SMt[i]-L)*255/(H-L); if(Mt[i]>Mt[t(cc)]) {cc=3*i;};}; rings=255;
  for(int i=0; i<nv; i++) {Mv[i]=0;};  for(int i=0; i<nc; i++) {Mv[v(i)]=max(Mv[v(i)],Mt[t(i)]);};
  println("finished isolation");
  }
  
void computePath() {                 // graph based shortest path between t(c0 and t(prevc), prevc is the previously picekd corner
  for(int i=0; i<nt; i++) {Mt[i]=0;}; // reset marking
  Mt[t(sc)]=1; // Mt[0]=1;            // mark seed triangle
  for(int i=0; i<nc; i++) {P[i]=false;}; // reset corners as not visited
  int r=1;
  boolean searching=true;
  while (searching) {
     for(int i=0; i<nc; i++) {
       if (searching&&(Mt[t(i)]==0)&&(!b(i))) { // t(i) is an unvisited triangle and i is not facing a border edge
         if(Mt[t(o(i))]==r) { // if opposite triangle is ring r
           Mt[t(i)]=r+1; // mark (invade) t(i) as part of ring r+1
           P[i]=true;    // mark corner i as visited
           if(t(i)==t(cc)){searching=false;}; // if we reached the end?
           };
         };
       };
     r++;
     };
  for(int i=0; i<nt; i++) {Mt[i]=0;};  // graph distance between triangle and t(c)
  rings=1;      // track ring number
  int b=cc;
  int k=0;
  while (t(b)!=t(sc)) { // back track
    rings++;  
    if (P[b]) {b=o(b); print(".o");} else {if (P[p(b)]) {b=r(b);print(".r");} else {b=l(b);print(".l");};}; Mt[t(b)]=rings; };
  }

 void  showDistance() {noStroke(); for(int t=0; t<nt; t++) if(Mt[t]!=0) {fill(ramp(Mt[t],rings)); showShrunkOffsetT(t,1,1);}; noFill(); } 


//  ==========================================================  GARBAGE COLLECTION ===========================================
void clean() {
   excludeInvisibleTriangles();  println("excluded");
   compactVO(); println("compactedVO");
   compactV(); println("compactedV");
   normals(); println("normals");
   computeO();
   resetMarkers();
   }  // removes deleted triangles and unused vertices
   
void excludeInvisibleTriangles () {for (int b=0; b<nc; b++) {if (!visible[t(o(b))]) {O[b]=b;};};}
void compactVO() {  
  int[] U = new int [nc];
  int lc=-1; for (int c=0; c<nc; c++) {if (visible[t(c)]) {U[c]=++lc; }; };
  for (int c=0; c<nc; c++) {if (!b(c)) {O[c]=U[o(c)];} else {O[c]=c;}; };
  int lt=0;
  for (int t=0; t<nt; t++) {
    if (visible[t]) {
      V[3*lt]=V[3*t]; V[3*lt+1]=V[3*t+1]; V[3*lt+2]=V[3*t+2]; 
      O[3*lt]=O[3*t]; O[3*lt+1]=O[3*t+1]; O[3*lt+2]=O[3*t+2]; 
      visible[lt]=true; 
      lt++;
      };
    };
  nt=lt; nc=3*nt;    
  println("      ...  NOW: nv="+nv +", nt="+nt +", nc="+nc );
  }

void compactV() {  
  println("COMPACT VERTICES: nv="+nv +", nt="+nt +", nc="+nc );
  int[] U = new int [nv];
  boolean[] deleted = new boolean [nv];
  for (int v=0; v<nv; v++) {deleted[v]=true;};
  for (int c=0; c<nc; c++) {deleted[v(c)]=false;};
  int lv=-1; for (int v=0; v<nv; v++) {if (!deleted[v]) {U[v]=++lv; }; };
  for (int c=0; c<nc; c++) {V[c]=U[v(c)]; };
  lv=0;
  for (int v=0; v<nv; v++) {
    if (!deleted[v]) {G[lv].set(G[v]);  deleted[lv]=false; 
      lv++;
      };
    };
 nv=lv;
 println("      ...  NOW: nv="+nv +", nt="+nt +", nc="+nc );
  }

// ============================================================= ARCHIVAL ============================================================
boolean flipOrientation=false;            // if set, save will flip all triangles

void saveMeshVTS() {
  String savePath = selectOutput("Select or specify .vts file where the mesh will be saved");  // Opens file chooser
  if (savePath == null) {println("No output file was selected..."); return;}
  else println("writing to "+savePath);
  saveMeshVTS(savePath);
  }

void saveMeshVTS(String fn) {
  String [] inppts = new String [nv+1+nt+1];
  int s=0;
  inppts[s++]=str(nv);
  for (int i=0; i<nv; i++) {inppts[s++]=str(G[i].x)+","+str(G[i].y)+","+str(G[i].z);};
  inppts[s++]=str(nt);
  if (flipOrientation) {for (int i=0; i<nt; i++) {inppts[s++]=str(V[3*i])+","+str(V[3*i+2])+","+str(V[3*i+1]);};}
    else {for (int i=0; i<nt; i++) {inppts[s++]=str(V[3*i])+","+str(V[3*i+1])+","+str(V[3*i+2]);};};
  saveStrings(fn,inppts);  
  };
  
void loadMeshVTS() {
  String loadPath = selectInput("Select .vts mesh file to load");  // Opens file chooser
  if (loadPath == null) {println("No input file was selected..."); return;}
  else println("reading from "+loadPath); 
  loadMeshVTS(loadPath);
 }

void loadMeshVTS(String fn) {
  println("loading: "+fn); 
  String [] ss = loadStrings(fn);
  String subpts;
  int s=0;   int comma1, comma2;   float x, y, z;   int a, b, c;
  nv = int(ss[s++]);
    print("nv="+nv);
    for(int k=0; k<nv; k++) {int i=k+s; 
      comma1=ss[i].indexOf(',');   
      x=float(ss[i].substring(0, comma1));
      String rest = ss[i].substring(comma1+1, ss[i].length());
      comma2=rest.indexOf(',');    y=float(rest.substring(0, comma2)); z=float(rest.substring(comma2+1, rest.length()));
      G[k].set(x,y,z);
    };
  s=nv+1;
  nt = int(ss[s]); nc=3*nt;
  println(", nt="+nt);
  s++;
  for(int k=0; k<nt; k++) {int i=k+s;
      comma1=ss[i].indexOf(',');   a=int(ss[i].substring(0, comma1));  
      String rest = ss[i].substring(comma1+1, ss[i].length()); comma2=rest.indexOf(',');  
      b=int(rest.substring(0, comma2)); c=int(rest.substring(comma2+1, rest.length()));
      V[3*k]=a;  V[3*k+1]=b;  V[3*k+2]=c;
    }
  };
  

void loadMeshOBJ() {
  String loadPath = selectInput("Select .obj mesh file to load");  // Opens file chooser
  if (loadPath == null) {println("No input file was selected..."); return;}
  else println("reading from "+loadPath); 
  loadMeshOBJ(loadPath);
 }

void loadMeshOBJ(String fn) {
  println("loading: "+fn); 
  String [] ss = loadStrings(fn);
  String subpts;
  String S;
  int comma1, comma2;   float x, y, z;   int a, b, c;
  int s=2;   
  println(ss[s]);
  int nn=ss[s].indexOf(':')+2; println("nn="+nn);
  nv = int(ss[s++].substring(nn));  println("nv="+nv);
  int k0=s;
    for(int k=0; k<nv; k++) {int i=k+k0; 
      S=ss[i].substring(2); if(k==0 || k==nv-1) println(S);
      comma1=S.indexOf(' ');   
      x=-float(S.substring(0, comma1));           // swaped sign to fit picture
      String rest = S.substring(comma1+1);
      comma2=rest.indexOf(' ');    y=float(rest.substring(0, comma2)); z=float(rest.substring(comma2+1));
      G[k].set(x,y,z); if(k<3 || k>nv-4) {print("k="+k+" : "); }
      s++;
    };
  s=s+2; 
  println("Triangles");
  println(ss[s]);
  nn=ss[s].indexOf(':')+2;
  nt = int(ss[s].substring(nn)); nc=3*nt;
  println(", nt="+nt);
  s++;
  k0=s;
  for(int k=0; k<nt; k++) {int i=k+k0;
      S=ss[i].substring(2);                        if(k==0 || k==nt-1) println(S);
      comma1=S.indexOf(' ');   a=int(S.substring(0, comma1));  
      String rest = S.substring(comma1+1); comma2=rest.indexOf(' ');  
      b=int(rest.substring(0, comma2)); c=int(rest.substring(comma2+1));
//      V[3*k]=a-1;  V[3*k+1]=b-1;  V[3*k+2]=c-1;                           // original
      V[3*k]=a-1;  V[3*k+1]=c-1;  V[3*k+2]=b-1;                           // swaped order
    }
  for (int i=0; i<nv; i++) G[i].mul(4);  
  }; 




// ============================================================= CUT =======================================================
  void cut(pt[] CP, int ncp) {
    if(ncp<3) return;
    for(int t=0; t<nt; t++) {tm[t]=0;}; // reset triangle markings are not in ring
    int[] cc = new int[ncp]; // closest corners
    for(int i=0; i<ncp; i++) cc[i]=closestCorner(CP[i+1]);
    traceRing(cc,ncp); // marks triangles on ring through control points
    }
 
 //************************************************************************************************************** CUT ************************************************************
 void cut(LOOP L) { // computes projected loop PL and constructs baffle
    if(L.n<3) return;
//    LOOP XL = new LOOP(); 
//    XL.setToProjection(L,this); 
//    PL=XL.resampleDistance(100);                                           // loop sampling was 10
    RL.setToProjection(L,this); 
    PL=RL.resampleDistance(5);                                           // loop sampling was 10
 
//    for(int i=0; i<10; i++) {PL.projectOn(Cylinder); PL.projectOn(this);}
    
    PL.smoothen(); 
    PL.projectOn(this);
    PL.smoothenOn(this); 
    for(int t=0; t<nt; t++) {tm[t]=0;}; // reset triangle markings are not in ring
    int[] cc = new int[PL.n]; // closest corners
    for(int i=0; i<PL.n; i++) cc[i]=closestCorner(PL.Pof(i));
    traceRing(cc,PL.n); // marks triangles on ring through control points
    int s=0; // mark the corners facing the cut triangles
    for(int c=0; c<nc; c++) if( tm[t(c)]==0 && tm[t(o(c))]==1 && d(g(c),g(cc[0]))<d(g(s),g(cc[0]))) s=c;
    tm[t(s)]=2;
    invade(0,2,s);
    PL.smoothenOn(this,1); 
    }
 
 void invade(int om, int nm, int s) { // grows region  tm[t]=nm by invading triangles where tm[t]==om
   Boolean found=true;
   while(found) {
      found=false;
      for(int c=0; c<nc; c++) 
        if( tm[t(c)]==om && tm[t(o(c))]==nm) {tm[t(c)]=nm; found=true;} 
      }
   }
 void showPebbles() {noStroke(); fill(magenta); for(int c=0; c<nc; c++) if(P[c]) show(cg(c),2);}
 
 void traceRing(int[] cc, int ncp) { // computes ring of triangles that visits corners cc
  markPath(cc[ncp-1],cc[0]); 
  for(int i=0; i<ncp-1; i++) markPath( cc[i] , cc[i+1] ); 
  }

void markPath(int sc, int cc) {     // graph based shortest path between sc and cc
  if(t(sc)==t(cc)) {tm[t(sc)]=1; return;}
  for(int i=0; i<nt; i++) {Mt[i]=0;}; // reset marking of visited triangles
  Mt[t(sc)]=1;                      // mark seed triangle
  for(int i=0; i<nc; i++) {P[i]=false;}; // reset all corners as not having a parent
  int r=1;
  boolean searching=true;
  while (searching) {
     for(int i=0; i<nc; i++) {
       if (searching&&(Mt[t(i)]==0)&&(!b(i))) { // t(i) is an unvisited triangle and i is not facing a border edge
         if(Mt[t(o(i))]==r) { // if opposite triangle is ring r
           Mt[t(i)]=r+1; // mark (invade) t(i) as part of ring r+1
           P[i]=true;    // mark corner i as visited
           if(t(i)==t(cc)){searching=false;}; // if we reached the end?
           };
         };
       };
     r++;
     };
  int b=cc;
  while (t(b)!=t(sc)) { // back track
    if (P[b]) b=o(b);  else if (P[p(b)]) b=r(b); else b=l(b);
    tm[t(b)]=1; 
    };
  }

void makeInvisible(int m) { for(int i=0; i<nt; i++) if(tm[i]==m) visible[i]=false; }
void rename(int m, int k) { for(int i=0; i<nt; i++) if(tm[i]==m)  tm[i]=k;}
void makeAllVisible() { for(int i=0; i<nt; i++) visible[i]=true; }

  // cplit the mesh near loop
  int closestVertexID(pt M) {int v=0; for (int i=1; i<nv; i++) if (d(M,G[i])<d(M,G[v])) v=i; return v;}
  int closestCorner(pt M) {int c=0; for (int i=1; i<nc; i++) if (d(M,cg(i))<d(M,cg(c))) c=i; return c;}
  
  void drawLoopOfClosestVertices(LOOP L) {
    resetMarkers(); 
    noFill(); stroke(magenta); 
    beginShape();
    for (int p=0; p<L.n; p++) {int v=closestVertexID(L.P[p]); vm[v]=p+1; vertex(G[v]);};  
    endShape();   
    }

    
  void drawProjection(LOOP L) {
    stroke(cyan); fill(cyan);
    for (int p=0; p<L.n; p++) {
      pt CP=closestProjection(L.P[p]); 
      show(L.P[p],CP); show(CP,1);
      }
    }
    
 void makeLoopOfClosestVerticesAndMarkTriangles(LOOP L) {
    resetMarkers();
    for (int p=0; p<L.n; p++) {closestProjectionMark(L.P[p]);};  
    }
    
 pt closestProjectionMark(pt P) {
    float md=d(P,g(0));
    int cc=0; // corner of closest cell
    int type = 0; // type of closest projection: - = vertex, 1 = edge, 2 = triangle
    pt Q = P(); // closest point
    for (int c=0; c<nc; c++) if (d(P,g(c))<md) {Q.set(g(c)); cc=c; type=0; md=d(P,g(c));} 
    for (int c=0; c<nc; c++) if (c<=o(c)) {float d = distPE(P,g(n(c)),g(p(c))); if (d<md && projPonE(P,g(n(c)),g(p(c)))) {md=d; cc=c; type=1; Q=CPonE(P,g(n(c)),g(p(c)));} } 
    if(onTriangles) 
       for (int t=0; t<nt; t++) {int c=3*t; float d = distPtPlane(P,g(c),g(n(c)),g(p(c))); if (d<md && projPonT(P,g(c),g(n(c)),g(p(c)))) {md=d; cc=c; type=2; Q=CPonT(P,g(c),g(n(c)),g(p(c)));} } 
    if(type==2) tm[t(cc)]=1;
    if(type==1) {tm[t(cc)]=2; tm[t(o(cc))]=2;}
    if(type==0) {tm[t(cc)]=3; int c=s(cc); while(c!=cc) {c=s(c); tm[t(c)]=3;} }
    return Q;
    }
 
  void drawClosestProjections(LOOP L) {
    for (int p=0; p<L.n; p++) {drawLineToClosestProjection(L.P[p]);};  
    }
    
  
 void drawLineToClosestProjection(pt P) {
    float md=d(P,g(0));
    int cc=0; // corner of closest cell
    int type = 0; // type of closest projection: - = vertex, 1 = edge, 2 = triangle
    pt Q = P(); // closest point
    for (int c=0; c<nc; c++) if (d(P,g(c))<md) {Q.set(g(c)); cc=c; type=0; md=d(P,g(c));} 
    for (int c=0; c<nc; c++) if (c<=o(c)) {float d = distPE(P,g(n(c)),g(p(c))); if (d<md && projPonE(P,g(n(c)),g(p(c)))) {md=d; cc=c; type=1; Q=CPonE(P,g(n(c)),g(p(c)));} } 
    if(onTriangles) 
      for (int t=0; t<nt; t++) {int c=3*t; float d = distPtPlane(P,g(c),g(n(c)),g(p(c))); if (d<md && projPonT(P,g(c),g(n(c)),g(p(c)))) {md=d; cc=c; type=2; Q=CPonT(P,g(c),g(n(c)),g(p(c)));} } 
    if(type==2) stroke(dred);   if(type==1) stroke(dgreen);  if(type==0) stroke(dblue);  show(P,Q);   
    }
 
  pt closestProjection(pt P) {  // ************ closest projection of P on this mesh
    float md=d(P,G[0]);
    pt Q = P();
    int v=0; for (int i=1; i<nv; i++) if (d(P,G[i])<md) {Q=G[i]; md=d(P,G[i]);} 
    for (int c=0; c<nc; c++) if (c<=o(c)) {
         float d = abs(distPE(P,g(n(c)),g(p(c)))); 
         if (d<md && projPonE(P,g(n(c)),g(p(c)))) {md=d; Q=CPonE(P,g(n(c)),g(p(c)));} 
         } 
    for (int t=0; t<nt; t++) {
         int c=3*t; 
         float d = distPtPlane(P,g(c),g(n(c)),g(p(c))); 
         if (d<md && projPonT(P,g(c),g(n(c)),g(p(c)))) {md=d; Q=CPonT(P,g(c),g(n(c)),g(p(c)));} 
         } 
    return Q;
    }
 
   pt closestProjection(pt P, int k) { //closest projection on triangles marked as tm[t]==k
    float md=d(P,G[0]);
    pt Q = P();
    for (int c=0; c<nc; c++) if(tm[t(c)]==k) if (d(P,g(c))<md) {Q=g(c); md=d(P,g(c));} 
    for (int c=0; c<nc; c++)  if(tm[t(c)]==k) if (c<=o(c)) {float d = distPE(P,g(n(c)),g(p(c))); if (d<md && projPonE(P,g(n(c)),g(p(c)))) {md=d; Q=CPonE(P,g(n(c)),g(p(c)));} } 
    for (int t=0; t<nt; t++)  if(tm[t]==k) {int c=3*t; float d = distPtPlane(P,g(c),g(n(c)),g(p(c))); if (d<md && projPonT(P,g(c),g(n(c)),g(p(c)))) {md=d; Q=CPonT(P,g(c),g(n(c)),g(p(c)));} } 
    return Q;
    }
    
    
  int closestVertexNextCorner(pt P, int k) { //closest projection on triangles marked as tm[t]==k
    int bc=0; // best corner index
    float md=d(P,g(p(bc)));
    for (int c=0; c<nc; c++) if(tm[t(c)]==k && tm[t(o(c))]!=k) if (d(P,g(p(c)))<md) {bc=c; md=d(P,g(p(c)));} 
    return bc;
    }

  int closestVertex(pt P, int k) { //closest projection on triangles marked as tm[t]==k
    int v=0;
    float md=d(P,G[v]);
    for (int c=0; c<nc; c++) if(tm[t(c)]==k) if (d(P,g(c))<md) {v=v(c); md=d(P,g(c));} 
    return v;
    }
    
  int nextAlongSplit(int c, int mk) {
    c=p(c);
    if(tm[t(o(c))]==mk) return c;
    c=p(o(c));
    while(tm[t(o(c))]!=mk) c=p(o(c));
    return c;
    }  

  int prevAlongSplit(int c, int mk) {
    c=n(c);
    if(tm[t(o(c))]==mk) return c;
    c=n(o(c));
    while(tm[t(o(c))]!=mk) c=n(o(n(c)));
    return c;
    }  
    
 float flattenStrip() { // flattens a particular triangle strip LLRLRLRLR
   float [] x = new float [nv]; 
   float [] y = new float [nv]; 
   for (int c=2; c<nc; c+=3) {
     pt A = g(n(c)); pt B = g(p(c)); pt C = g(c);
     vec I = U(A,B); vec K=U(triNormal(t(o(c))));  vec J=N(I,K); 
     x[v(c)]=d(I,V(A,C)); y[v(c)]=d(J,V(A,C)); 
     }
   float d=d(G[v(0)],G[v(1)]);
   G[v(0)]=P(0,0,0); G[v(1)]=P(d,0,0);
     for (int c=2; c<nc; c+=3) {
     pt A = g(n(c)); pt B = g(p(c)); 
     vec I = U(A,B); vec K=V(0,0,-1);  vec J=N(I,K);
     G[v(c)].set(P(A,x[v(c)],I,y[v(c)],J));
     }
   float minx=G[0].x, miny=G[0].y, maxx=G[0].x, maxy=G[0].y;
   for (int i=1; i<nv; i++) { minx=min(minx,G[i].x); miny=min(miny,G[i].y); maxx=max(maxx,G[i].x); maxy=max(maxy,G[i].y); }
   float s=min(width/(maxx-minx),height/(maxy-miny))*.8;
   float cx=(maxx+minx)/2; float cy=(maxy+miny)/2;
   for (int i=0; i<nv; i++) { G[i].x=(G[i].x-cx)*s; G[i].y=(G[i].y-cy)*s; }
   return s;
   } 
    
   //TODO msati3: clean this up...where does this go? Do wholistically
   RingExpanderResult m_result = null;
   void setResult(RingExpanderResult result)
   {
     m_result = result;
   }
   
   void advanceRingExpanderResult()
   {
     if (m_result != null)
     {
       m_result.advanceStep();
     }
   }
   
   void showRingExpanderCorners()
   {
     if (m_result != null)
     {
       m_result.colorRingExpander();
     }
   }
   
   void formIslands(int initCorner)
   {
     m_fDrawIsles = true;
     if (m_result != null)
     {
       showRingExpanderCorners();
       m_result.formIslands(initCorner);
     }
   }
   
   private boolean waterIncident(int triangle)
   {
     int corner = c(triangle);
     return (isVertexForCornerWaterVertex(corner) || isVertexForCornerWaterVertex(n(corner)) || isVertexForCornerWaterVertex(p(corner)));
   }
   
   private boolean isWaterVertex(int vertex)
   {
     int cornerForVertex = cForV(vertex);
     return isVertexForCornerWaterVertex(cornerForVertex);
   }

   private boolean isVertexForCornerWaterVertex(int corner)
   {
     int initCorner = corner;
     int curCorner = initCorner;
     do
     {
       if (island[curCorner] != -1)
       {
         return false;
       }
       curCorner = s(curCorner);
     }while (curCorner != initCorner);
     return true;
   }
   
   private int getIslandForVertex(int vertex)
   {
     int initCorner = cForV(vertex);
     int curCorner = initCorner;
     do
     {
       if (island[curCorner] != -1)
       {
         return island[curCorner];
       }
       curCorner = s(curCorner);
     }while (curCorner != initCorner);
     return -1;
   }
    
   private int getIslandByUnswing(int corner)
   {
     int initCorner = corner;
     int curCorner = initCorner;
     do
     {
       if (island[curCorner] != -1)
       {
         return island[curCorner];
       }
       int swing = u(curCorner);
       if (swing == n(curCorner))
       {
         break;
       }
       curCorner = swing;
     }while (curCorner != initCorner);
     return -1;
   }
  
   private int getIsland(int corner)
   {
     int initCorner = corner;
     int curCorner = initCorner;
     do
     {
       if (island[curCorner] != -1)
       {
         return island[curCorner];
       }
       int swing = s(curCorner);
       if (swing == p(curCorner))
       {
         return getIslandByUnswing(initCorner);
       }
       curCorner = swing;
     }while (curCorner != initCorner);
     return -1;
   }
   
  private boolean hasBeachEdge(int triangle)
   {
     int corner = c(triangle);

     int count = 0;
     while(count < 3)
     {
       int island1 = getIsland(corner);
       int island2 = getIsland(n(corner));
       int island3 = getIsland(p(corner));

       if ((island1 != -1 && island2 != -1) && ((island[s(corner)] != -1 && island[u(n(corner))] != -1)||(island[u(corner)] != -1 && island[s(n(corner))] != -1)))
       {
         if (island1 == island2)
         {
           return true;
         }
         else
         {
           print("Islands on the beach edge are not the same. Failure!!" + island1 + " " + island2);
         }
       }
       corner = n(corner);
       count++;
     }
     return false;
   }
   
   ColorResult colorTriangles()
   {
     int countLand = 0, countGood = 0, countSeparator = 0, countLagoons = 0, countBad = 0;
     int numVerts = 0, numWaterVerts = 0, numNormalVerts = 0;
     for (int i = 0; i < nt; i++)
     {
       int corner = c(i);
       int island1 = getIsland(corner);
       int island2 = getIsland(n(corner));
       int island3 = getIsland(p(corner));
       tm[i] = 0;
       if (island[corner] != -1 && island[n(corner)] != -1 && island[p(corner)] != -1 && island1 == island2 && island1 == island3)
       {
         countLand++;
         tm[i] = landColor;
       }
       else if (hasBeachEdge(i)) //shallow
       {
         if (island1 != -1 && island2 != -1 && island3 != -1 && (island1 == island2 || island1 == island3 || island2 == island3))
         {
           if (island1 == island2 && island1 == island3)
           {
             countLagoons++;
             tm[i] = 5; //Lagoon
           }
           else
           {
             if (island1 != -1 && island2 != -1 && island3 != -1 && (island1 != island2 || island1 != island3))
             {
               countGood++;
               tm[i] = 3;
             }
             else
             {
               print ("This case unhandled!");
             }
           }
         }
         else
         {
           tm[i] = 7; //Cap triangle
         }
       }
       else //deep
       {
           if (island1 != -1 && island2 != -1 && island3 != -1 && island1 == island2 && island1 == island3)
           {
             tm[i] = 1;
           }
           else if (island1 != -1 && island2 != -1 && island3 != -1 && (island1 == island2 || island1 == island3 || island2 == island3))
           {
             tm[i] = 2;
           }
           else if (island1 != -1 && island2 != -1 && island3 != -1)
           {
             countSeparator++;
             tm[i] = 6;
           }
           else
           {
             countBad++;
             tm[i] = 4;
           }
       }
     }
     
     for (int i = 0; i < nv; i++)
     {
       numVerts++;
       if (isWaterVertex(i))
       {
         numWaterVerts++;
       }
       else
       {
         numNormalVerts++;
       }
     }
     print("\nStats : Total " + nt + " Land " + countLand + " Good water " + countGood + " Island separators " + countSeparator + " Lagoons " + countLagoons + " Bad water " + countBad + "Num Water Verts " + numWaterVerts);
     
     //TODO msati3: This is a hack. Should be made a separate function
     computeBaryCenterForIslands();
     calculateFinalLocationsForVertices();
     return new ColorResult(nt, countLand, countGood, countSeparator, countLagoons, countBad, numVerts, numWaterVerts, numNormalVerts);
   }

   ColorResult colorTrianglesOld()
   {
     int countLand = 0, countGood = 0, countSeparator = 0, countLagoons = 0, countBad = 0;
     int numVerts = 0, numWaterVerts = 0, numNormalVerts = 0;
     for (int i = 0; i < nt; i++)
     {
       int corner = c(i);
       int island1 = getIsland(corner);
       int island2 = getIsland(n(corner));
       int island3 = getIsland(p(corner));
       tm[i] = 0;       
       if (waterIncident(i))
       {
         if ((isVertexForCornerWaterVertex(corner) && island2 != -1 && island3 != -1 && island2 == island3) ||
             (isVertexForCornerWaterVertex(n(corner)) && island1 != -1 && island3 != -1 && island1 == island3) ||
             (isVertexForCornerWaterVertex(p(corner)) && island1 != -1 && island2 != -1 && island1 == island2))
         {
           tm[i] = 7;
         }
         else
         {
           countBad++;
           tm[i] = 4;
         }
       }
       else if (island[corner] != -1 && island[n(corner)] != -1 && island[p(corner)] != -1 && island1 == island2 && island1 == island3)
       {
         countLand++;
         tm[i] = landColor;
       }
       else if (island1 != -1 && island2 != -1 && island3 != -1 && island1 != island2 && island1 != island3 && island2 != island3)
       {
         countSeparator++;
         tm[i] = 6;
       }
       else if (island1 != -1 && island2 != -1 && island3 != -1 && island1 == island2 || island1 == island3 || island2 == island3)
       {
         if (island1 == island2 && island1 == island3)
         {
           countLagoons++;
           tm[i] = 5;
         }
         else
         {
           if (hasBeachEdge(i))
           {
             countGood++;
             tm[i] = 3;
           }
           else if (island1 == island2 && island1 == island3)
           {
             tm[i] = 1;
           }
           else
           {
             tm[i] = 2;
           }
         }
       }
     }
     
     for (int i = 0; i < nv; i++)
     {
       numVerts++;
       if (isWaterVertex(i))
       {
         numWaterVerts++;
       }
       else
       {
         numNormalVerts++;
       }
     }
     print("\nStats : Total " + nt + " Land " + countLand + " Good water " + countGood + " Island separators " + countSeparator + " Lagoons " + countLagoons + " Bad water " + countBad + "Num Water Verts " + numWaterVerts);
     
     //TODO msati3: This is a hack. Should be made a separate function
     computeBaryCenterForIslands();
     calculateFinalLocationsForVertices();
     return new ColorResult(nt, countLand, countGood, countSeparator, countLagoons, countBad, numVerts, numWaterVerts, numNormalVerts);
   }
   
   void printState()
   {
       int corner = cc;
       int island1 = getIsland(corner);
       int island2 = getIsland(n(corner));
       int island3 = getIsland(p(corner));
   }
   
   private int getVertexType(int vertex)
   {
     int cornerForVertex = cForV(vertex);
     if (!isVertexForCornerWaterVertex(cornerForVertex))
     {
       return 0;
     }
     return 1;
   }
   
   private boolean isIslandVertex(int vertex)
   {
     return getVertexType(vertex) == 0;
   }
   
   private float computeArea(int triangle)
   {
     pt A = G[v(c(triangle))];
     pt B = G[v(n(c(triangle)))];
     pt C = G[v(p(c(triangle)))];
     
     vec AB = V(A, B);
     vec AC = V(A, C);
     vec cross = N(AB, AC);
     float area = 0.5 * cross.norm();
     return abs(area);
   }
   
   private pt baryCenter(int triangle)
   {
     int corner = c(triangle);
     pt baryCenter = new pt();
     baryCenter.set(G[v(c(triangle))]);
     baryCenter.add(G[v(n(c(triangle)))]);
     baryCenter.add(G[v(p(c(triangle)))]);
     baryCenter.div(3);
     //print(baryCenter.x + " " + baryCenter.y + " " + baryCenter.z);
     return baryCenter;
   }
   
   private void computeBaryCenterForIslands()
   {
     for (int i = 0; i < numIslands; i++)
     {
       islandArea[i] = 0;
       islandBaryCenter[i] = new pt(0,0,0);
       for (int j = 0; j < nt; j++)
       {
         if (triangleIsland[j] == i)
         {
           float area = computeArea(j);
           islandArea[i] += area;
           islandBaryCenter[i].add(baryCenter(j).mul(area));
           //islandArea[i]++;
           //islandBaryCenter[i].add(baryCenter(j));
         }
       }
       islandBaryCenter[i].div(islandArea[i]);
     }
   }
   
   private void calculateFinalLocationsForVertices()
   {
     for (int i = 0; i < nv; i++)
     {
       int vertexType = getVertexType(i);
       switch (vertexType)
       {
         case 0: int island = getIslandForVertex(i);
                 if (island == -1)
                 {
                   print("Fatal error!! Get island == -1 for vertex of type IslandVertex");
                 }
                 baseG[i] = islandBaryCenter[island];
                 break;
         case 1: baseG[i] = G[i];
                 break;
         default: print("Fatal error!! Vertex not classified as water or island vertex");
                 break;
       }
     }
   }
   
   pt morph(pt p1, pt p2, float t)
   {
     pt result = new pt();
     result.set(p1);
     result.mul(1-t);
     pt temp = new pt();
     temp.set(p2);
     temp.mul(t);
     result.add(temp);
     //result.log();
     //print("\n");
     return result;
   }

   void morphFromBaseMesh()
   {
     pt[] temp = baseG;
     baseG = G;
     G = temp;
     if (currentT > 0)
     {
       currentT -= 0.01;
     }
     else
     {
       fBeginUnmorph = false;
       currentT = 0;
     }

     for (int i = 0; i < nv; i++)
     {
       int vertexType = getVertexType(i);
       switch (vertexType)
       {
         case 0: int island = getIslandForVertex(i);
                 if (island == -1)
                 {
                   print("Fatal error!! Get island == -1 for vertex of type IslandVertex");
                 }
                 if (islandBaryCenter[island] == null)
                 {
                   print("Barycenter null for " + island + " " + numIslands);
                 }
                 baseG[i] = morph(G[i], islandBaryCenter[island], currentT);
                 break;
         case 1: baseG[i] = new pt();
                 baseG[i].set(G[i]);
                 break;
         default: print("Fatal error!! Vertex not classified as water or island vertex");
                 break;
       }
     }
     temp = G;
     G = baseG;
     baseG = temp;
   }

   void morphToBaseMesh()
   {
     if (currentT != 0)
     {
       pt[] temp = baseG;
       baseG = G;
       G = temp;
     }
     if (currentT < 1)
     {
       currentT += 0.01;
     }
     else
     {
       fBeginMorph = false;
       currentT = 1;
     }
     for (int i = 0; i < nv; i++)
     {
       int vertexType = getVertexType(i);
       switch (vertexType)
       {
         case 0: int island = getIslandForVertex(i);
                 if (island == -1)
                 {
                   print("Fatal error!! Get island == -1 for vertex of type IslandVertex");
                 }
                 if (islandBaryCenter[island] == null)
                 {
                   print("Barycenter null for " + island + " " + numIslands);
                 }
                 baseG[i] = morph(G[i], islandBaryCenter[island], currentT);
                 break;
         case 1: baseG[i] = new pt();
                 baseG[i].set(G[i]);
                 break;
         default: print("Fatal error!! Vertex not classified as water or island vertex");
                 break;
       }
     }
     pt[] temp = G;
     G = baseG;
     baseG = temp;
   }
   
   void populateBaseG()
   {
     for (int i = 0; i < nv; i++ )
     {
       if ( isIslandVertex(i) )
       {
         int island = getIslandForVertex( i );
       } 
     }
   }
     
  } // ==== END OF MESH CLASS
  
vec labelD=new vec(-4,+4, 12);           // offset vector for drawing labels  

float distPE (pt P, pt A, pt B) {return n(N(V(A,B),V(A,P)))/d(A,B);} // distance from P to edge(A,B)
float distPtPlane (pt P, pt A, pt B, pt C) {vec N = U(N(V(A,B),V(A,C))); return abs(d(V(A,P),N));} // distance from P to plane(A,B,C)
Boolean projPonE (pt P, pt A, pt B) {return d(V(A,B),V(A,P))>0 && d(V(B,A),V(B,P))>0;} // P projects onto the interior of edge(A,B)
Boolean projPonT (pt P, pt A, pt B, pt C) {vec N = U(N(V(A,B),V(A,C))); return m(N,V(A,B),V(A,P))>0 && m(N,V(B,C),V(B,P))>0 && m(N,V(C,A),V(C,P))>0 ;} // P projects onto the interior of edge(A,B)
pt CPonE (pt P, pt A, pt B) {return P(A,d(V(A,B),V(A,P))/d(V(A,B),V(A,B)),V(A,B));}
pt CPonT (pt P, pt A, pt B, pt C) {vec N = U(N(V(A,B),V(A,C))); return P(P,-d(V(A,P),N),N);}
/*
Terminology:
CL: Control polygon interplates control points
SL: Smooth loop that interpolates the control polygon
PL: Projected and resampled loop (the "cut")
Ring is the trianglers stabbed by loop (will be removed): marked '1'
Stitch are triangles (two circular strips) that replace the ring, marked '5' and '6'
Baffle mesh that has loop as border

Invade:
Use cut normal to decide which side to invade as 2

Add baffle: 
remember rnv=nv and rnt=nt to restore
restore key (nv, nt, ncp)
add loop vertices to M
add baffle triangles to M and set their internal connectivity label 3 facing normal
add reverse baffle triangles to M and set their internal connectivity labal 4
Stitch 2&3 and 0&4

Stitch A & B:
Seed corners sa in A and sb in B st g(p(sa)) and g(n(sb)) is shortest
nbc(a) {int c=p(a); while(mt[t(o(c))]!=mt[t(a)]) c=p(o(c)); return c;} // next border corner with same triangle label 
pbc(c) {int c=n(a); while(mt[t(o(c))]!=mt[t(a)]) c=n(o(c));r eturn c;} // next border corner with same triangle label 
void stitch(int sa, int sb) {
  while(true) {
    if(a==sa && b==sb) exit;
    if(a==sa || d(g(p(a)),g(p(b)))<d(g(n(a)),g(n(b)))) {addTriangle(v(p(b)),v(n(b)),v(p(a))); b=pbc(b);} 
    else {addTriangle(v(p(a)),v(n(a)),v(n(b))); a=nbc(a);}
    }
  }
  
Baffle:
Normal to loop: sum of cross-products
Center of loop: average of vertices
Tangent: vector from CP[1] to center projected to be orthogonal to normal
Horizontal H
pt arcCenter(pt A, pt B, vec T, float r) {float s=sqrt(sq(r)/d2(A,B)-.25); pt C=(A+B)/2+sTxAB;}
Variable spacing slices normal to T (adjust slice so that centers of arcs are equidistant)
Spacing h: U=V(Ap,An); A=Ap+h/(U.T)U;


Display options
Top on/off
Bottom on/off
Baffle ribs overlaid
Baffle transparent

Compute volumes and % and write on screen

Draw cutout and compute thickness and min radius
  
*/
// ************************ Graphic pick utilities *******************************

// returns 3D point under mouse     
pt Pick() { 
  ((PGraphicsOpenGL)g).beginGL(); 
  int viewport[] = new int[4]; 
  double[] proj=new double[16]; 
  double[] model=new double[16]; 
  gl.glGetIntegerv(GL.GL_VIEWPORT, viewport, 0); 
  gl.glGetDoublev(GL.GL_PROJECTION_MATRIX,proj,0); 
  gl.glGetDoublev(GL.GL_MODELVIEW_MATRIX,model,0); 
  FloatBuffer fb=ByteBuffer.allocateDirect(4).order(ByteOrder.nativeOrder()).asFloatBuffer(); 
  gl.glReadPixels(mouseX, height-mouseY, 1, 1, GL.GL_DEPTH_COMPONENT, GL.GL_FLOAT, fb); 
  fb.rewind(); 
  double[] mousePosArr=new double[4]; 
  glu.gluUnProject((double)mouseX,height-(double)mouseY,(double)fb.get(0), model,0,proj,0,viewport,0,mousePosArr,0); 
  ((PGraphicsOpenGL)g).endGL(); 
  return P((float)mousePosArr[0],(float)mousePosArr[1],(float)mousePosArr[2]);
  }

// sets Q where the mouse points to and I, J, K to be aligned with the screen (I right, J up, K towards thre viewer)
void SetFrame(pt Q, vec I, vec J, vec K) { 
     glu= ((PGraphicsOpenGL) g).glu;  PGraphicsOpenGL pgl = (PGraphicsOpenGL) g;  
     float modelviewm[] = new float[16]; gl = pgl.beginGL(); gl.glGetFloatv(GL.GL_MODELVIEW_MATRIX, modelviewm, 0); pgl.endGL();
     Q.set(Pick()); 
     I.set(modelviewm[0],modelviewm[4],modelviewm[8]);  J.set(modelviewm[1],modelviewm[5],modelviewm[9]); K.set(modelviewm[2],modelviewm[6],modelviewm[10]);   // println(I.x+","+I.y+","+I.z);
     noStroke();
     }
     

// ********************** frame display ****************************
void showFrame(pt Q, vec I, vec J, vec K, float s) {  // sets the matrix and displays the second model (here the axes as blocks)
  pushMatrix();
  applyMatrix( I.x,    J.x,    K.x,    Q.x,
               I.y,    J.y,    K.y,    Q.y,
               I.z,    J.z,    K.z,    Q.z,
               0.0,    0.0,    0.0,    1.0      );
  showAxes(s); // replace this (showing the axes) with code for showing your second model
  popMatrix();
  }
  
void showAxes(float s) { // shows three orthogonal axes as red, green, blue blocks aligned with the local frame coordinates
  noStroke();
  pushMatrix(); 
  pushMatrix(); fill(red);  scale(s,1,1); box(2); popMatrix();
  pushMatrix(); fill(green);  scale(1,s,1); box(2); popMatrix();
  pushMatrix(); fill(blue);  scale(1,1,s); box(2); popMatrix();  
  popMatrix();  
  }
  

class State
{
  private int m_corner;
  private int m_parentTriangle;

  public State(int corner, int parent)
  {
    m_corner = corner;
    m_parentTriangle = parent;
  }
  
  public int corner()
  {
    return m_corner;
  }
  
  public int parentTriangle()
  {
    return m_parentTriangle;
  }
}

class RingExpander
{
  private Mesh m_mesh;
  private int m_seed;
  private int m_numTrianglesToVisit;
  private int m_numTrianglesVisited;
  private RingExpanderResult m_ringExpanderResult;
  private boolean m_fColoringRingExpander;
  private int[] m_parentTriangles;

  boolean[] m_vertexVisited;
  boolean[] m_triangleVisited;

  Stack< State > m_recursionStack;
  
  public RingExpander(Mesh m, int seed)
  {
    m_mesh = m;
    m_mesh.resetMarkers();
    m_seed = 0;

    if (seed != -1)
    {
      print("Seed for ringExpander " + seed);
      m_seed = seed;
    }
    m_mesh.cc = m_seed;

    m_numTrianglesToVisit = -1;
    m_numTrianglesVisited = 0;
    m_parentTriangles = new int[m_mesh.nv];

    m_ringExpanderResult = null;

    for (int i = 0; i < m_mesh.nv; i++)
    {
      m_parentTriangles[i] = -1;
    }
  }

  private void colorTriangles(boolean[] vertexVisited, boolean[] triangleVisited)
  {
    for (int i = 0; i < triangleVisited.length; i++)
    {
      if (triangleVisited[i])
      {
        m_mesh.tm[i] = 1;
      }
      else
      {
        m_mesh.tm[i] = 2;
      }
    }
  }

  private void resetStateForRingExpander()
  {
    m_numTrianglesToVisit = 0;
  }

  private boolean onUpdateTriangleVisitCount()
  {
    if (m_numTrianglesVisited > m_numTrianglesToVisit && DEBUG && DEBUG_MODE > LOW)
    {
      print("Number of triangles visited exceeds the number of triangles desired to be visited. Bug!! ");
      return true;
    }
    if (m_numTrianglesVisited == m_numTrianglesToVisit)
    {
      return true;
    }
    return false; 
  }

  public void completeRingExpander()
  {
    Mesh m = m_mesh;
    int seed = m_seed;
    int init = seed;

    boolean vertexVisited[] = new boolean[m.nv];
    boolean triangleVisited[] = new boolean[m.nt];

    vertexVisited[m.v(m.p(seed))] = true;   

    do
    {
      if (!vertexVisited[m.v(seed)])
      {
         vertexVisited[m.v(seed)] = true;
         triangleVisited[m.t(seed)] = true;
      }
      else if (!triangleVisited[m.t(seed)]) 
      {
        seed = m.o(seed);
      }
      seed = m.r(seed);
    }while (seed != m.o(init));
    colorTriangles(vertexVisited, triangleVisited);

    m_numTrianglesToVisit = -1;
  }

  public void visitRecursively()
  {
    while (((m_numTrianglesToVisit == -1) || (m_numTrianglesVisited < m_numTrianglesToVisit)) &&(!m_recursionStack.empty()))
    {
      State currentState = m_recursionStack.pop();
      int corner = currentState.corner();
      int parentTriangle = currentState.parentTriangle();

      if (!m_vertexVisited[m_mesh.v(corner)])
      {
        m_vertexVisited[m_mesh.v(corner)] = true;
        m_triangleVisited[m_mesh.t(corner)] = true;
        m_parentTriangles[m_mesh.v(corner)] = parentTriangle;
        m_numTrianglesVisited++;

        if (m_mesh.hasValidL(corner))
        {
          m_recursionStack.push(new State(m_mesh.l(corner), m_mesh.t(corner)));
        }
        if (m_mesh.hasValidR(corner))
        {
          m_recursionStack.push(new State(m_mesh.r(corner), m_mesh.t(corner)));
        }
      }
    }
  }

  public RingExpanderResult completeRingExpanderRecursive()
  {
    Mesh m = m_mesh;
    int seed = m_seed;

    m_vertexVisited = new boolean[m.nv];
    m_triangleVisited = new boolean[m.nt];
    m_recursionStack = new Stack();

    m_vertexVisited[m.v(m.p(seed))] = true;   
    m_vertexVisited[m.v(m.n(seed))] = true;   

    m_numTrianglesToVisit = -1;
    m_numTrianglesVisited = 0;

    m_recursionStack.push(new State(seed, -1));
    visitRecursively();
    m_ringExpanderResult = new RingExpanderResult(m_mesh, seed, m_parentTriangles);

    return m_ringExpanderResult;
  }

  public void ringExpanderStepRecursive()
  {
    if (m_numTrianglesToVisit == -1)
    {
      resetStateForRingExpander();
    }

    Mesh m = m_mesh;
    int seed = m_seed;

    m_numTrianglesToVisit++;
    m_numTrianglesVisited = 0;

    m_vertexVisited = new boolean[m.nv];
    m_triangleVisited = new boolean[m.nt];
    m_recursionStack = new Stack();

    m_vertexVisited[m.v(m.p(seed))] = true;
    m_vertexVisited[m.v(m.n(seed))] = true;   

    m_recursionStack.push(new State(seed, -1));
    visitRecursively();

    colorTriangles(m_vertexVisited, m_triangleVisited);
  }
}

// CORNER TABLE FOR TRIANGLE MESHES by Jarek Rosignac
// Last edited Feb 17, 2008

//Mesh M = new Mesh();     // creates a default triangle meshvoid computeValenceAndResetNormals() {      // caches valence of each vertex
// 
////========================== class MESH ===============================
//class Mesh {
//
////  ==================================== INIT, CREATE, COPY ====================================
// Mesh() {}
// int maxnv = 20000;                         //  max number of vertices
// int maxnt = maxnv*2;                       // max number of triangles
// void declare() {c=0; sc=0; prevc=0;
//   for (int i=0; i<maxnv; i++) {G[i]=new pt(0,0,0); Nv[i]=new vec(0,0,0);};   // init vertices and normals
//   for (int i=0; i<maxnt; i++) {Nt[i]=new vec(0,0,0); visible[i]=true;} ;}       // init triangle normals and skeleton lab els
// void init() {c=0; prevc=0; sc=0; nv=0; nt=0; nc=0;}
// void makeGrid (int w) { // make a 2D grid of vertices
//  for (int i=0; i<w; i++) {for (int j=0; j<w; j++) { G[w*i+j].setTo(height*.8*j/(w-1)+height/10,height*.8*i/(w-1)+height/10,0);}}    
//  for (int i=0; i<w-1; i++) {for (int j=0; j<w-1; j++) {                  // define the triangles for the grid
//    V[(i*(w-1)+j)*6]=i*w+j;       V[(i*(w-1)+j)*6+2]=(i+1)*w+j;       V[(i*(w-1)+j)*6+1]=(i+1)*w+j+1;
//    V[(i*(w-1)+j)*6+3]=i*w+j;     V[(i*(w-1)+j)*6+5]=(i+1)*w+j+1;     V[(i*(w-1)+j)*6+4]=i*w+j+1;}; };
//  nv = w*w;
//  nt = 2*(w-1)*(w-1); 
//  nc=3*nt;  }
// void update() {computeO(); normals(); }
//  // ============================================= CORNER OPERATORS =======================================
// int nc = 0;                                // current number of corners (3 per triangle)
// int c = 0;                                 // current corner shown in image and manipulated with keys: n, p, o, l, r
// int sc=0;                                  // saved value of c
// int[] V = new int [3*maxnt];               // V table (triangle/vertex indices)
// int[] O = new int [3*maxnt];               // O table (opposite corner indices)
// int[] Tc = new int[3*maxnt];               // corner type
//
//// operations on a corner
//int t (int c) {return int(c/3);};          // triangle of corner    
//int n (int c) {return 3*t(c)+(c+1)%3;};   // next corner in the same t(c)    
//int p (int c) {return n(n(c));};  // previous corner in the same t(c)  
//int v (int c) {return V[c] ;};   // id of the vertex of c             
//pt g (int c) {return G[v(c)];};  // shortcut to get the point of the vertex v(c) of corner c
//boolean b (int c) {return O[c]==-1;};       // if faces a border (has no opposite)
//int o (int c) {if (b(c)) return c; else return O[c];}; // opposite (or self if it has no opposite)
//int l (int c) {return o(n(c));}; // left neighbor (or next if n(c) has no opposite)                      
//int r (int c) {return o(p(c));}; // right neighbor (or previous if p(c) has no opposite)                    
//int s (int c) {return n(l(c));}; // swings around v(c) or around a border loop
//
//// operations on the selected corner c
//int t() {return t(c);}
//int n() {return n(c);}
//int p() {return p(c);}
// int v() {return v(c);}
//int o() {return o(c);}
//boolean b() {return b(c);}             // border: returns true if corner has no opposite
//int l() {return l(c);}
//int r() {return r(c);}
//int s() {return s(c);}
//pt g() {return g(c);}            // shortcut to get the point of the vertex v(c) of corner c
//
//vec Nv (int c) {return(Nv[V[c]]);}; vec Nv() {return Nv(c);}            // shortcut to get the normal of v(c) 
//vec Nt (int c) {return(Nt[t(c)]);}; vec Nt() {return Nt(c);}            // shortcut to get the normal of t(c) 
//int w (int c) {return(W[c]);};               // temporary indices to mid-edge vertices associated with corners during subdivision
//boolean vis(int c) {return visible[t(c)]; };   // true if tiangle of c is visible
//  
//void previous() {c=p(c);};
//void next() {c=n(c); println("...... next");};
//void back() {if(!b(c)) {c=o(c);};};
//void left() {next(); back();};
//void right() {previous(); back();};
//void swing() {left(); next(); };
//
//void writeCorner (int c) {println("c="+c+", n="+n(c)+", p="+p(c)+", o="+o(c)+", v="+v(c)+", t="+t(c)+", Mt="+Mt[t(c)]+", EB symbol="+triangleSymbol[t(c)]+"."+", nt="+nt+", nv="+nv ); }; 
//void writeCorner () {writeCorner (c);}
//void writeCorners () {for (int c=0; c<nc; c++) {println("T["+c+"]="+t(c)+", visible="+visible[t(c)]+", v="+v(c)+",  o="+o(c));};}
//
//pt cg(int c) {pt cPt = midPt(g(c),midPt(g(c),triCenter(t(c))));  return(cPt); };   // computes point at corner
//pt corner(int c) {return midPt(g(c),triCenter(t(c)));   };   // returns corner point
//void showCorner(int c, int r) {pt cPt = midPt(g(c),midPt(g(c),corner(c)));  cPt.show(r); };   // renders corner c as small ball
//
//// ============================================= O TABLE CONSTRUCTION =========================================
//void computeOnaive() {                         // sets the O table from the V table, assumes consistent orientation of triangles
//  for (int i=0; i<3*nt; i++) {O[i]=-1;};  // init O table to -1: has no opposite (i.e. is a border corner)
//  for (int i=0; i<nc; i++) {  for (int j=i+1; j<nc; j++) {       // for each corner i, for each other corner j
//      if( (v(n(i))==v(p(j))) && (v(p(i))==v(n(j))) ) {O[i]=j; O[j]=i;};};};}// make i and j opposite if they match         
//
//void computeO() { 
//  int val[] = new int [nv]; for (int v=0; v<nv; v++) val[v]=0;  for (int c=0; c<nc; c++) val[v(c)]++;   //  valences
//  int fic[] = new int [nv]; int rfic=0; for (int v=0; v<nv; v++) {fic[v]=rfic; rfic+=val[v];};  // head of list of incident corners
//  for (int v=0; v<nv; v++) val[v]=0;   // valences wil be reused to track how many incident corners were encountered for each vertex
//  int [] C = new int [nc]; for (int c=0; c<nc; c++) C[fic[v(c)]+val[v(c)]++]=c;  // vor each vertex: the list of val[v] incident corners starts at C[fic[v]]
//  for (int c=0; c<nc; c++) O[c]=-1;    // init O table to -1 meaning that a corner has no opposite (i.e. faces a border)
//  for (int v=0; v<nv; v++)             // for each vertex...
//     for (int a=fic[v]; a<fic[v]+val[v]-1; a++) for (int b=a+1; b<fic[v]+val[v]; b++)  { // for each pair (C[a],C[b[]) of its incident corners
//        if (v(n(C[a]))==v(p(C[b]))) {O[p(C[a])]=n(C[b]); O[n(C[b])]=p(C[a]); }; // if C[a] follows C[b] around v, then p(C[a]) and n(C[b]) are opposite
//        if (v(n(C[b]))==v(p(C[a]))) {O[p(C[b])]=n(C[a]); O[n(C[a])]=p(C[b]); };        };                
//  }
//    
//// ============================================= DISPLAY =======================================
//pt Cbox = new pt(width/2,height/2,0);                   // mini-max box center
//float Rbox=1000;                                        // Radius of enclosing ball
//boolean showLabels=false; 
//void computeBox() {
//  pt Lbox =  G[0].make();  pt Hbox =  G[0].make();
//  for (int i=1; i<nv; i++) { 
//    Lbox.x=min(Lbox.x,G[i].x); Lbox.y=min(Lbox.y,G[i].y); Lbox.z=min(Lbox.z,G[i].z);
//    Hbox.x=max(Hbox.x,G[i].x); Hbox.y=max(Hbox.y,G[i].y); Hbox.z=max(Hbox.z,G[i].z); 
//    };
//  Cbox.setToPoint(midPt(Lbox,Hbox));  Rbox=Cbox.disTo(Hbox);
//  };
//void show() {
//  int col=60;
//  noSmooth(); noStroke();
//  if(showDistance) showDistance(); else if(showEB) showEB();  else if(showTriangles) showTriangles();  
//  if (showEdges) {stroke(dblue); for(int i=0; i<nc; i++) if(visible[t(i)]) drawEdge(i); };  
//  if (showSelectedTriangle) {noStroke(); fill(green); shade(t(c)); noFill(); }; 
//  stroke(red); showBorder();
//  if (showVertices) {noStroke(); noSmooth();fill(white); for (int v=0; v<nv; v++)  G[v].show(r); noFill();};
//  if (showNormals) {stroke(blue); showTriNormals(); stroke(magenta); showVertexNormals(); };                // show triangle normals
//  if (showLabels) { fill(black); 
//      for (int i=0; i<nv; i++) {G[i].label("v"+str(i),labelD); }; 
//      for (int i=0; i<nc; i++) {corner(i).label("c"+str(i),labelD); }; 
//      for (int i=0; i<nt; i++) {triCenter(i).label("t"+str(i),labelD); }; noFill();};
//  noStroke(); fill(dred); showCorner(prevc,r); fill(dgreen); mark.show(r); fill(dblue); showCorner(c,r);  
////  fill(orange); showCorner(c1,r); fill(dyellow); showCorner(c2,r);
////  showNext();
////  noFill(); stroke(black); strokeWeight(3); Rs.to(Re); strokeWeight(1);
//  }
////  ==========================================================  EDGES ===========================================
//boolean showEdges=false;
//void findShortestEdge() {c=cornerOfShortestEdge();  } 
//int cornerOfShortestEdge() {  // assumes manifold
//  float md=d(g(p(0)),g(n(0))); int ma=0;
//  for (int a=1; a<nc; a++) if (vis(a)&&(d(g(p(a)),g(n(a)))<md)) {ma=a; md=d(g(p(a)),g(n(a)));}; 
//  return ma;
//  } 
//void drawEdge(int c) {showLine(g(p(c)),g(n(c))); };  // draws edge of t(c) opposite to corner c
//void showBorder() {for (int i=0; i<nc; i++) {if (visible[t(i)]&&b(i)) {drawEdge(i);}; }; };         // draws all border edges
//
////  ==========================================================  TRIANGLES ===========================================
// boolean showTriangles=true;
// boolean showSelectedTriangle=false;
// int nt = 0;                   // current number of triangles
// void addTriangle(int i, int j, int k) {V[nc++]=i; V[nc++]=j; V[nc++]=k; visible[nt++]=true;}
// boolean[] visible = new boolean[maxnt];    // set if triangle visible
// int[] Mt = new int[maxnt];                 // triangle markers for distance and other things   
// boolean [] VisitedT = new boolean [maxnt];  // triangle visited
// pt triCenter(int i) {return(triCenterFromPts( G[V[3*i]], G[V[3*i+1]], G[V[3*i+2]] )); };  pt triCenter() {return triCenter(t());}  // computes center of triangle i 
// float triArea(int t) {return area(g(3*t),g(3*t+1),g(3*t+2)); }  // computes area of triangle t 
// void writeTri (int i) {println("T"+i+": V = ("+V[3*i]+":"+v(o(3*i))+","+V[3*i+1]+":"+v(o(3*i+1))+","+V[3*i+2]+":"+v(o(3*i+2))+")"); };
// boolean hitTriangle() {
//  prevc=c;       // save c for geodesic and other applications
//  float smallestDepth=10000000;
//  boolean hit=false;
//  for (int t=0; t<nt; t++) {
//    if (rayHitTri(eye,mark,g(3*t),g(3*t+1),g(3*t+2))) {hit=true;
//      float depth = rayDistTriPlane(eye,mark,g(3*t),g(3*t+1),g(3*t+2));
//      if ((depth>0)&&(depth<smallestDepth)) {smallestDepth=depth;  c=3*t;};
//      }; 
//    };
//  if (hit) {        // sets c to be the closest corner in t(c) to the picked point
//    pt X = P(eye); X.addScaledVec(smallestDepth,eye.vecTo(mark));
//    mark.setToPoint(X);
//    float distance=X.disTo(g(c));
//    int b=c;
//    if (X.disTo(g(n(c)))<distance) {b=n(c); distance=X.disTo(g(b)); };
//    if (X.disTo(g(p(c)))<distance) {b=p(c);};
//    c=b;
//    println("c="+c+", pc="+prevc+", t(pc)="+t(prevc));
//    };
//  return hit;
//  }
// void shade(int t) {if(visible[t]) { beginShape(); g(3*t).vert(); g(3*t+1).vert(); g(3*t+2).vert();  endShape(CLOSE); };}; // shade tris
// void showTriangles() {fill(cyan); for(int t=0; t<nt; t++)  shade(t); noFill();}; 
////  ==========================================================  VERTICES ===========================================
// boolean showVertices=false;
// int nv = 0;                              // current  number of vertices
// pt[] G = new pt [maxnv];                   // geometry table (vertices)
// int[] Mv = new int[maxnv];                  // vertex markers
// int [] Valence = new int [maxnv];          // vertex valence (count of incident triangles)
// boolean [] Border = new boolean [maxnv];   // vertex is border
// boolean [] VisitedV = new boolean [maxnv];  // vertex visited
// int r=5;                                // radius of spheres for displaying vertices
//int addVertex(pt P) { G[nv].setTo(P); nv++; return nv-1;};
//int addVertex(float x, float y, float z) { G[nv].x=x; G[nv].y=y; G[nv].z=z; nv++; return nv-1;};
//void move(int c) {g(c).addScaledVec(pmouseY-mouseY,Nv(c));}
//void move(int c, float d) {g(c).addScaledVec(d,Nv(c));}
//void move() {move(c); normals();}
//void moveROI() {
//     pt Q = new pt(0,0,0);
//     for (int i=0; i<nv; i++) Mv[i]=0;  // resets the valences to 0
//     computeDistance(5);
//     for (int i=0; i<nv; i++) VisitedV[i]=false;  // resets the valences to 0
//     computeTriNormals(); computeVertexNormals();
//     for (int i=0; i<nc; i++) if(!VisitedV[v(i)]&&(Mv[v(i)]!=0)) move(i,1.*(pmouseY-mouseY+mouseX-pmouseX)*(rings-Mv[v(i)])/rings/10);  // moves ROI
//     computeDistance(7);
//     Q.setTo(g());
//     smoothROI();
//     g().setTo(Q);
//     }
//     
////  ==========================================================  NORMALS ===========================================
//boolean showNormals=false;
//vec[] Nv = new vec [maxnv];                 // vertex normals or laplace vectors
//vec[] Nt = new vec [maxnt];                // triangles normals
//void normals() {computeValenceAndResetNormals(); computeTriNormals(); computeVertexNormals(); }
//void computeValenceAndResetNormals() {      // caches valence of each vertex
//  for (int i=0; i<nv; i++) {Nv[i].setTo(0,0,0); Valence[i]=0;};  // resets the valences to 0
//  for (int i=0; i<nc; i++) {Valence[v(i)]++; };
//  }
//vec triNormal(int t) { return C(V(g(3*t),g(3*t+1)),V(g(3*t),g(3*t+2))); };  
//vec triNormal() {return triNormal(t());} // computes triangle t(i) normal * area / 2
//void computeTriNormals() {for (int i=0; i<nt; i++) {Nt[i].setToVec(triNormal(i)); }; };             // caches normals of all tirangles
//void computeVertexNormals() {  // computes the vertex normals as sums of the normal vectors of incident tirangles scaled by area/2
//  for (int i=0; i<nv; i++) {Nv[i].setTo(0,0,0);};  // resets the valences to 0
//  for (int i=0; i<nc; i++) {Nv[v(i)].add(Nt[t(i)]);};
//  for (int i=0; i<nv; i++) {Nv[i].makeUnit();};            };
//void showCornerNormal(int c) {S(20*r,Nt[t(c)]).show(M(g(c),g(c),triCenter(t(c))));};   // renders corner normal
//void showVertexNormals() {for (int i=0; i<nv; i++) S(10*r,Nv[i]).show(G[i]);  };
//void showTriNormals() {for (int i=0; i<nt; i++) S(10*r,U(Nt[i])).show(triCenter(i));  };
//
//// ============================================================= SMOOTHING ============================================================
//void computeLaplaceVectors() {  // computes the vertex normals as sums of the normal vectors of incident tirangles scaled by area/2
//  computeValenceAndResetNormals();
//  for (int i=0; i<3*nt; i++) {Nv[v(p(i))].add(g(p(i)).vecTo(g(n(i))));};
//  for (int i=0; i<nv; i++) {Nv[i].div(Valence[i]);};                         };
//void tuck(float s) {for (int i=0; i<nv; i++) {G[i].addScaledVec(s,Nv[i]);}; };  // displaces each vertex by a fraction s of its normal
//void smoothen() {normals(); computeLaplaceVectors(); tuck(0.6); computeLaplaceVectors(); tuck(-0.6);};
//void tuckROI(float s) {for (int i=0; i<nv; i++) if (Mv[i]!=0) G[i].addScaledVec(s,Nv[i]); };  // displaces each vertex by a fraction s of its normal
//void smoothROI() {computeLaplaceVectors(); tuckROI(0.5); computeLaplaceVectors(); tuckROI(-0.5);};
//// ============================================================= SUBDIVISION ============================================================
//int[] W = new int [3*maxnt];               // mid-edge vertex indices for subdivision (associated with corner opposite to edge)
//void splitEdges() {            // creates a new vertex for each edge and stores its ID in the W of the corner (and of its opposite if any)
//  for (int i=0; i<3*nt; i++) {  // for each corner i
//    if(b(i)) {G[nv]=midPt(g(n(i)),g(p(i))); W[i]=nv++;}
//    else {if(i<o(i)) {G[nv]=midPt(g(n(i)),g(p(i))); W[o(i)]=nv; W[i]=nv++; }; }; }; } // if this corner is the first to see the edge
//  
//void bulge() {              // tweaks the new mid-edge vertices according to the Butterfly mask
//  for (int i=0; i<3*nt; i++) {
//    if((!b(i))&&(i<o(i))) {    // no tweak for mid-vertices of border edges
//     if (!b(p(i))&&!b(n(i))&&!b(p(o(i)))&&!b(n(o(i))))
//      {G[W[i]].addScaledVec(0.25,midPt(midPt(g(l(i)),g(r(i))),midPt(g(l(o(i))),g(r(o(i))))).vecTo(midPt(g(i),g(o(i))))); }; }; }; };
//  
//void splitTriangles() {    // splits each tirangle into 4
//  for (int i=0; i<3*nt; i=i+3) {
//    V[3*nt+i]=v(i); V[n(3*nt+i)]=w(p(i)); V[p(3*nt+i)]=w(n(i));
//    V[6*nt+i]=v(n(i)); V[n(6*nt+i)]=w(i); V[p(6*nt+i)]=w(p(i));
//    V[9*nt+i]=v(p(i)); V[n(9*nt+i)]=w(n(i)); V[p(9*nt+i)]=w(i);
//    V[i]=w(i); V[n(i)]=w(n(i)); V[p(i)]=w(p(i));
//    };
//  nt=4*nt; nc=3*nt;  };
//  
//void refine() {update(); splitEdges(); bulge(); splitTriangles(); update();}
//  
////  ========================================================== FILL HOLES ===========================================
//void fanHoles() {for (int cc=0; cc<nc; cc++) if (visible[t(cc)]&&b(cc)) fanThisHole(cc); normals();  }
//void fanThisHole() {fanThisHole(c);}
//void fanThisHole(int cc) {   // fill shole with triangle fan (around average of parallelogram predictors). Must then call computeO to restore O table
// if(!b(cc)) return ; // stop if cc is not facing a border
// G[nv].setTo(0,0,0);   // tip vertex of fan
// int o=0;              // tip corner of new fan triangle
// int n=0;              // triangle count in fan
// int a=n(cc);          // corner running along the border
// while (n(a)!=cc) {    // walk around the border loop 
//   if(b(p(a))) {       // when a is at the left-end of a border edge
//      G[nv].addPt( M(M(g(a),g(n(a))),S(g(a),V(g(p(a)),g(n(a))))) ); // add parallelogram prediction and mid-edge point
//      o=3*nt; V[o]=nv; V[n(o)]=v(n(a)); V[p(o)]=v(a); visible[nt]=true; nt++; // add triangle to V table, make it visible
//      O[o]=p(a); O[p(a)]=o;        // link opposites for tip corner
//      O[n(o)]=-1; O[p(o)]=-1;
//      n++;}; // increase triangle-count in fan
//    a=s(a);} // next corner along border
// G[nv].mul(1./n); // divide fan tip to make it the average of all predictions
// a=o(cc);       // reset a to walk around the fan again and set up O
// int l=n(a);   // keep track of previous
// int i=0; 
// while(i<n) {a=s(a); if(v(a)==nv) { i++; O[p(a)]=l; O[l]=p(a); l=n(a);}; };  // set O around the fan
// nv++;  nc=3*nt;  // update vertex count and corner count
// };








// =========================================== DRILL HOLES ==================================================================================== ###
//pt Rs=new pt(0,0,0); pt Re=new pt(0,0,1);   
//int c1=0, c2=0;
//float r2 = 400; // square radius of cylinder

//void hideCaps() {
//  Rs=P(mark); Re=T(mark,-300,eye); 
//  unhide();
//  classifyVertices(eye,mark);
//  hideStabbedTriangles();
//  hideHitTriangles(); 
//  }
//void classifyVertices(pt A, pt B) {
//  for(int v=0; v<nv; v++) Mv[v]=0; 
//  for (int c=0; c<nc; c++) if(ptInCylinder(g(c),A,B,r2)) Mv[v(c)]=1;
//  }
//void hideStabbedTriangles() {for(int t=0; t<nt; t++) if (triCutCylinder(t)) visible[t]=false;}
//boolean triCutCylinder(int t) {return (Mv[v(3*t)]==1)||(Mv[v(3*t+1)]==1)||(Mv[v(3*t+2)]==1); }
//void hideHitTriangles() {for (int t=0; t<nt; t++) if (rayHitTri(eye,mark,g(3*t),g(3*t+1),g(3*t+2))) {visible[t]=false;}; }







//void stitchBorders(int ma, int mb) {
//  int n1=0,n2=0; // loop lengths
//  c1=-1; for (int c=0; c<nc; c++) if (b(c)&&) c1=c; if (c1==-1) {c1=0; return ;};
//  boolean L[] = new boolean [nc]; for (int c=0; c<nc; c++) L[c]=false;
//  L[c1]=true; int a=nal(c1);  while (a!=c1) {L[a]=true; a=nal(a); n1++;};
//  c2=-1; for (int c=0; c<nc; c++) if (b(c)&&!L[c]) c2=c; if (c2==-1) {c2=0; return ;};
//  a=nal(c2);  while (a!=c2) {a=nal(a); n2++;};
//  float md=1000000;
//  a=c1; int b=c2;
//  for (int i=0; i<n1; i++) {for (int j=0; j<n2; j++) {
//  if (d(g(p(a)),g(n(b)))<md) {md=d(g(p(a)),g(n(b))); c1=a; c2=b;}; b=nal(b);}; a=nal(a);};
//  prevc=c1;
//
//  float n1c=0, n2c=0;
//  while ((n1c<n1+1)&&(n2c<n2+1)) {
//      vec N1=U(N(g(n(c1)),g(n(c2)),g(p(c1)))); vec N2=U(N(g(n(c2)),g(p(c1)),g(p(c2))));  
//      if (n2(C(V(eye,mark),N1))>n2(C(V(eye,mark),N2))) {zipLeft(); n1c++;}
//      else                                             {zipRight();n2c++;};
//      };
//  println("*** zipping: n1="+n1+", n1c="+n1c+",   n2="+n2+", n2c="+n2c);
//  if (n1>n1c-1) {println(" did "+(n1-n1c+1)+" more left  zips"); for (int i=0; i<n1-n1c+1; i++) zipLeft(); };
//  if (n2>n2c-1) {println(" did "+(n2-n2c+1)+" more right zips"); for (int i=0; i<n2-n2c+1; i++) zipRight(); };
//  clean(); computeO(); 
//  }
//int nal(int c) {if (!b(c)) return -1; int a=p(c); while (!b(a)) a=p(o(a)); return a; } // returns next corner around loop
//int pal(int c) {if (!b(c)) return -1; int a=n(c); while (!b(a)) a=n(o(a)); return a; } // returns previous corner around loop
//int advL(int a, int b) {V[nc++]=v(n(a)); V[nc++]=v(n(b)); V[nc++]=v(p(a));  visible[nt]=true; nt++; return nal(a);}
//int advR(int a, int b) {V[nc++]=v(n(a)); V[nc++]=v(p(b)); V[nc++]=v(p(a));  visible[nt]=true; nt++; return pal(a);}
////void joinTo(int a, int b) {O[o(a)]=nc+2; O[nc+2]=o(a); V[nc++]=v(n(a)); V[nc++]=v(p(a)); V[nc++]=v(n(b)); nt++;}
//void zipLeft() {c1=advL(c1,c2);}
//void zipRight() {c2=advR(c2,c1);}
//void zipBest() { vec N1=U(N(g(n(c1)),g(n(c2)),g(p(c1)))); vec N2=U(N(g(n(c2)),g(p(c1)),g(p(c2))));  
//    if (n2(C(V(eye,mark),N1))>n2(C(V(eye,mark),N2))) zipLeft(); else zipRight(); }
//void showNext() {
// //   if (area(g(n(c1)),g(n(c2)),g(p(c1)))<area(g(n(c2)),g(p(c1)),g(p(c2)))) 
//    vec N1=U(N(g(n(c1)),g(n(c2)),g(p(c1)))); vec N2=U(N(g(n(c2)),g(p(c1)),g(p(c2))));
//    stroke(black);
//    if (n2(C(V(eye,mark),N1))>n2(C(V(eye,mark),N2))) 
//      { fill(orange,100); showTriangle(g(n(c1)),g(n(c2)),g(p(c1))); showLineFrom(M(g(n(c1)),g(n(c2)),g(p(c1))),N1,50);}
// else { fill(yellow,100); showTriangle(g(n(c2)),g(p(c1)),g(p(c2))); showLineFrom(M(g(n(c2)),g(p(c1)),g(p(c2))),N2,50);}; }
//int findSeedTriangles() {
//  int seed=0;
//  for (int t=0; t<nt; t++) Mt[t]=0;
//  for (int t=0; t<nt; t++) if (rayHitTri(eye,mark,g(3*t),g(3*t+1),g(3*t+2))) {visible[t]=false; seed++; Mt[t]=seed;};
//  return seed;
//   }
//void growCaps() {println("rings="+rings);
//  for (int cap=1; cap<=rings; cap++) {
//     for(int v=0; v<nv; v++) Mv[v]=0;
//     boolean added=true;
//     while (added) { added=false;
//         for(int c=0; c<nc; c++) if (Mt[t(c)]==cap) Mv[v(c)]=cap;
//         for(int c=0; c<nc; c++) if ((!visible[t(c)])&&(Mv[v(c)]==cap)&&(Mt[t(c)]==0)) {Mt[t(c)]=cap; added=true;};
//         };
//     };
//  }
//void makeTunnel() {
//  unhide();
//  int ht[] = new int [100]; int nht=0; // hit triangles and their count
//  for (int t=0; t<nt; t++) if (rayHitTri(eye,mark,g(3*t),g(3*t+1),g(3*t+2))) {ht[nht++]=t;};
//  if (nht==2) {
//    visible[ht[0]]=false; visible[ht[1]]=false; 
//    int a=3*ht[0]; int b=3*ht[1]; 
//    if (d(g(n(a)),g(b))<d(g(a),g(b))) {a=n(a); if (d(g(n(a)),g(b))<d(g(a),g(b))) a=n(a); } else {if (d(g(p(a)),g(b))<d(g(a),g(b))) a=p(a); };
//    if (d(g(n(b)),g(a))<d(g(b),g(a))) {b=n(b); if (d(g(n(b)),g(a))<d(g(b),g(a))) b=n(b); } else {if (d(g(p(b)),g(a))<d(g(b),g(a))) a=p(b); };
//    for (int i=0; i<3; i++) {join(a,b); join(b,a); a=n(a); b=p(b);};
//    for (int i=0; i<3; i++) {O[p(o(o(a)))]=p(o(o(b)));  O[p(o(o(b)))]=p(o(o(a)));  O[n(o(o(a)))]=n(o(o(p(b)))); O[n(o(o(p(b))))]=n(o(o(a))); a=n(a); b=p(b);};
//    for (int i=0; i<3; i++) {O[a]=-1; O[b]=-1; a=n(a); b=p(b);};    
//    for(int v=0; v<nv; v++) Mv[v]=0;  for(int c=0; c<nc; c++) if (Mt[t(c)]!=0) Mv[v(c)]=1;
//    };
//
//  }
//void join(int a, int b) {O[o(a)]=nc+2; O[nc+2]=o(a); V[nc++]=v(n(a)); V[nc++]=v(p(a)); V[nc++]=v(n(b));  nt++; }
//









//// =========================================== GEODESIC MEASURES, DISTANCES =============================
// boolean  showPath=false, showDistance=false;  
// boolean[] P = new boolean [3*maxnt];       // marker of corners in a path to parent triangle
// int[] Distance = new int[maxnt];           // triangle markers for distance fields 
// int[] SMt = new int[maxnt];                // sum of triangle markers for isolation
// int prevc = 0;                             // previously selected corner
// int rings=10;                           // number of rings for colorcoding
//
//void computeDistance(int maxr) {
//  int tc=0;
//  int r=1;
//  for(int i=0; i<nt; i++) {Mt[i]=0;};  Mt[t(c)]=1; tc++;
//  for(int i=0; i<nv; i++) {Mv[i]=0;};
//  while ((tc<nt)&&(r<=maxr)) {
//      for(int i=0; i<nc; i++) {if ((Mv[v(i)]==0)&&(Mt[t(i)]==r)) {Mv[v(i)]=r;};};
//     for(int i=0; i<nc; i++) {if ((Mt[t(i)]==0)&&(Mv[v(i)]==r)) {Mt[t(i)]=r+1; tc++;};};
//     r++;
//     };
//  rings=r;
//  }
//  
//void computeIsolation() {
//  println("Starting isolation computation for "+nt+" triangles");
//  for(int i=0; i<nt; i++) {SMt[i]=0;}; 
//  for(c=0; c<nc; c+=3) {println("  triangle "+t(c)+"/"+nt); computeDistance(1000); for(int j=0; j<nt; j++) {SMt[j]+=Mt[j];}; };
//  int L=SMt[0], H=SMt[0];  for(int i=0; i<nt; i++) { H=max(H,SMt[i]); L=min(L,SMt[i]);}; if (H==L) {H++;};
//  c=0; for(int i=0; i<nt; i++) {Mt[i]=(SMt[i]-L)*255/(H-L); if(Mt[i]>Mt[t(c)]) {c=3*i;};}; rings=255;
//  for(int i=0; i<nv; i++) {Mv[i]=0;};  for(int i=0; i<nc; i++) {Mv[v(i)]=max(Mv[v(i)],Mt[t(i)]);};
//  println("finished isolation");
//  }
//  
//void computePath() {                 // graph based shortest path between t(c0 and t(prevc), prevc is the previously picekd corner
//  for(int i=0; i<nt; i++) {Mt[i]=0;}; Mt[t(prevc)]=1; // Mt[0]=1;
//  for(int i=0; i<nc; i++) {P[i]=false;};
//  int r=1;
//  boolean searching=true;
//  while (searching) {
//     for(int i=0; i<nc; i++) {
//       if (searching&&(Mt[t(i)]==0)&&(o(i)!=-1)) {
//         if(Mt[t(o(i))]==r) {
//           Mt[t(i)]=r+1; 
//           P[i]=true; 
//           if(t(i)==t(c)){searching=false;};
//           };
//         };
//       };
//     r++;
//     };
//  for(int i=0; i<nt; i++) {Mt[i]=0;};  // graph distance between triangle and t(c)
//  rings=1;      // track ring number
//  int b=c;
//  int k=0;
//   while (t(b)!=t(prevc)) {rings++;  
//   if (P[b]) {b=o(b); print(".o");} else {if (P[p(b)]) {b=r(b);print(".r");} else {b=l(b);print(".l");};}; Mt[t(b)]=rings; };
//  }
// void  showDistance() { for(int t=0; t<nt; t++) {if(Mt[t]==0) fill(cyan); else fill(ramp(Mt[t],rings)); shade(t);}; } 
//
////  ==========================================================  HIDE/ SHOW / DELETE ===========================================
//void hideROI() { for(int i=0; i<nt; i++) if(Mt[i]>0) visible[i]=false; }
//void unhide() { for(int i=0; i<maxnt; i++) visible[i]=true; }
//void toggleVisibility() {for(int i=0; i<nt; i++) visible[i]=!visible[i]; }
//
////  ==========================================================  GARBAGE COLLECTION ===========================================
//void clean() {excludeInvisibleTriangles();  compactVO(); compactV(); M.normals();}  // removes deleted triangles and unused vertices
//void excludeInvisibleTriangles () {for (int b=0; b<nc; b++) {if (!visible[t(o(b))]) {O[b]=-1;};};}
//void compactVO() {  
//  int[] U = new int [nc];
//  int lc=-1; for (int c=0; c<nc; c++) {if (visible[t(c)]) {U[c]=++lc; }; };
//  for (int c=0; c<nc; c++) {if (!b(c)) {O[c]=U[o(c)];} else {O[c]=-1;}; };
//  int lt=0;
//  for (int t=0; t<nt; t++) {
//    if (visible[t]) {
//      V[3*lt]=V[3*t]; V[3*lt+1]=V[3*t+1]; V[3*lt+2]=V[3*t+2]; 
//      O[3*lt]=O[3*t]; O[3*lt+1]=O[3*t+1]; O[3*lt+2]=O[3*t+2]; 
//      visible[lt]=true; 
//      lt++;
//      };
//    };
//  nt=lt; nc=3*nt;    
//  println("      ...  NOW: nv="+nv +", nt="+nt +", nc="+nc );
//  }
//
//void compactV() {  
//  println("COMPACT VERTICES: nv="+nv +", nt="+nt +", nc="+nc );
//  int[] U = new int [nv];
//  boolean[] deleted = new boolean [nv];
//  for (int v=0; v<nv; v++) {deleted[v]=true;};
//  for (int c=0; c<nc; c++) {deleted[v(c)]=false;};
//  int lv=-1; for (int v=0; v<nv; v++) {if (!deleted[v]) {U[v]=++lv; }; };
//  for (int c=0; c<nc; c++) {V[c]=U[v(c)]; };
//  lv=0;
//  for (int v=0; v<nv; v++) {
//    if (!deleted[v]) {G[lv].setToPoint(G[v]);  deleted[lv]=false; 
//      lv++;
//      };
//    };
// nv=lv;
// println("      ...  NOW: nv="+nv +", nt="+nt +", nc="+nc );
//  }
//
//// ============================================================= ARCHIVAL ============================================================
//boolean flipOrientation=false;            // if set, save will flip all triangles
//
//void saveMesh() {
//  String [] inppts = new String [nv+1+nt+1];
//  int s=0;
//  inppts[s++]=str(nv);
//  for (int i=0; i<nv; i++) {inppts[s++]=str(G[i].x)+","+str(G[i].y)+","+str(G[i].z);};
//  inppts[s++]=str(nt);
//  if (flipOrientation) {for (int i=0; i<nt; i++) {inppts[s++]=str(V[3*i])+","+str(V[3*i+2])+","+str(V[3*i+1]);};}
//    else {for (int i=0; i<nt; i++) {inppts[s++]=str(V[3*i])+","+str(V[3*i+1])+","+str(V[3*i+2]);};};
//  saveStrings("mesh.vts",inppts);  println("saved on file");
//  };
//
//void loadMesh() {
//  println("loading fn["+fni+"]: "+fn[fni]); 
//  String [] ss = loadStrings(fn[fni]);
//  String subpts;
//  int s=0;   int comma1, comma2;   float x, y, z;   int a, b, c;
//  nv = int(ss[s++]);
//    print("nv="+nv);
//    for(int k=0; k<nv; k++) {int i=k+s; 
//      comma1=ss[i].indexOf(',');   
//      x=float(ss[i].substring(0, comma1));
//      String rest = ss[i].substring(comma1+1, ss[i].length());
//      comma2=rest.indexOf(',');    y=float(rest.substring(0, comma2)); z=float(rest.substring(comma2+1, rest.length()));
//      G[k].setTo(x,y,z);
//    };
//  s=nv+1;
//  nt = int(ss[s]); nc=3*nt;
//  println(", nt="+nt);
//  s++;
//  for(int k=0; k<nt; k++) {int i=k+s;
//      comma1=ss[i].indexOf(',');   a=int(ss[i].substring(0, comma1));  
//      String rest = ss[i].substring(comma1+1, ss[i].length()); comma2=rest.indexOf(',');  
//      b=int(rest.substring(0, comma2)); c=int(rest.substring(comma2+1, rest.length()));
//      V[3*k]=a;  V[3*k+1]=b;  V[3*k+2]=c;
//    }
//  }; 
//
////  ==========================================================  FLIP ===========================================
//void flipWhenLonger() {for (int c=0; c<nc; c++) if (d(g(n(c)),g(p(c)))>d(g(c),g(o(c)))) flip(c); } 
//void flip() {if(Mt[t(c)]!=0) flip(c);}
//void flip(int c) {      // flip edge opposite to corner c, FIX border cases
//  if (b(c)) return;
//    V[n(o(c))]=v(c); V[n(c)]=v(o(c));
//    int co=o(c); O[co]=r(c); if(!b(p(c))) O[r(c)]=co; if(!b(p(co))) O[c]=r(co); if(!b(p(co))) O[r(co)]=c; O[p(c)]=p(co); O[p(co)]=p(c);  }
// 
////  ==========================================================  SIMPLIFICATION  ===========================================
//void collapse() {collapse(c);}
//void collapse(int c) {if (b(c)) return;      // collapse edge opposite to corner c, does not check anything !!! assumes manifold
//   int b=n(c), oc=o(c), vpc=v(p(c));
//   visible[t(c)]=false; visible[t(oc)]=false;
//   for (int a=b; a!=p(oc); a=n(l(a))) V[a]=vpc;
//   O[l(c)]=r(c); O[r(c)]=l(c); O[l(oc)]=r(oc); O[r(oc)]=l(oc);  }
//
//// ============================================================= COMPRESSION ============================================================
// boolean showEB=false, showEBrec=false;
// char[] triangleSymbol = new char[maxnt];
// char[] CLERS = new char[maxnt];
// int symbols=0;
// int stack[] = new int[10000];
// int stackHeight=1;
// int Ccount=0, Lcount=0, Ecount=0, Rcount=0, Scount=0;
// boolean EBisDone;
// int firstCorner=0; 
// int step=1;                              // to do something step by step
//
// void showEB() {
//      for(int t=0; t<nt; t++) {fill(cyan);
//         if (triangleSymbol[t]=='w') {fill(white);};
//         if (triangleSymbol[t]=='B') {fill(black);};
//         if (triangleSymbol[t]=='C') {fill(yellow);};
//         if (triangleSymbol[t]=='L') {fill(blue);};
//         if (triangleSymbol[t]=='E') {fill(magenta);};
//         if (triangleSymbol[t]=='R') {fill(orange);};
//         if (triangleSymbol[t]=='S') {fill(red);};
//         shade(t); 
//         }
//      }  
// 
//void EBcompress(int c) {
// Ccount=0; Lcount=0; Ecount=0; Rcount=0; Scount=0; 
// resetStack(); 
// for (int v=0; v<nv; v++) {VisitedV[v]=false;};
// for (int t=0; t<nt; t++) {VisitedT[t]=false;};
// VisitedT[t(c)]=true; triangleSymbol[t(c)]='B'; VisitedV[v(c)]=true; VisitedV[v(n(c))]=true; VisitedV[v(p(c))]=true; c=r(c);
// symbols=0; 
// boolean EBisDone=false;
// while (!EBisDone) {
//  VisitedT[t(c)]=true; 
//  if (!VisitedV[v(c)]) {triangleSymbol[t(c)]='C'; Ccount++; CLERS[symbols++]=triangleSymbol[t(c)]; VisitedV[v(c)]=true; c=r(c); }
//  else {
//    if (VisitedT[t(r(c))]) {
//        if (VisitedT[t(l(c))]) {triangleSymbol[t(c)]='E'; Ecount++; CLERS[symbols++]=triangleSymbol[t(c)]; c=stack[--stackHeight]; if (stackHeight==0) {EBisDone=true;};}
//        else {triangleSymbol[t(c)]='R'; Rcount++; CLERS[symbols++]=triangleSymbol[t(c)]; c=l(c);};
//       }
//    else {
//        if (VisitedT[t(l(c))]) {triangleSymbol[t(c)]='L'; Lcount++; CLERS[symbols++]=triangleSymbol[t(c)]; c=r(c);}
//        else {triangleSymbol[t(c)]='S'; triangleSymbol[t(l(c))]='w'; Scount++; CLERS[symbols++]=triangleSymbol[t(c)]; stack[stackHeight++]=l(c); c=r(c);};
//      };
//    };
//  }; 
//  int total=Ccount+Lcount+Ecount+Rcount+Scount;
//  println(nt+" triangles, "+total+" symbols: C="+Ccount+", L="+Lcount+", E="+Ecount+", R="+Rcount+", S="+Scount);
// }
//
//int pop() {if (stackHeight==0){ println("Stack is empty"); stackHeight=1;}; return(stack[--stackHeight]);} // *************************************************************************
//void push(int c) {stack[stackHeight++]=c; }
//void resetStack() {stackHeight=1;};
//
//void EBinit() {
//   for (int v=0; v<nv; v++) {VisitedV[v]=false;};
//   for (int t=0; t<nt; t++) {VisitedT[t]=false;};
//   VisitedT[t(c)]=true; triangleSymbol[t(c)]='B'; VisitedV[v(c)]=true; VisitedV[v(n(c))]=true; VisitedV[v(p(c))]=true; c=r(c);
//   symbols=0; EBisDone=false;
//   }
//   
//void EBmove() {
// if (!EBisDone) {
//  VisitedT[t(c)]=true; 
//  if (!VisitedV[v(c)]) {triangleSymbol[t(c)]='C'; Ccount++; CLERS[symbols++]=triangleSymbol[t(c)]; VisitedV[v(c)]=true; c=r(c); }
//  else {
//    if (VisitedT[t(r(c))]) {
//        if (VisitedT[t(l(c))]) {triangleSymbol[t(c)]='E'; Ecount++; CLERS[symbols++]=triangleSymbol[t(c)]; c=stack[--stackHeight]; if (stackHeight==0) {EBisDone=true;};}
//        else {triangleSymbol[t(c)]='R'; Rcount++; CLERS[symbols++]=triangleSymbol[t(c)]; c=l(c);};
//       }
//    else {
//        if (VisitedT[t(l(c))]) {triangleSymbol[t(c)]='L'; Lcount++; CLERS[symbols++]=triangleSymbol[t(c)]; c=r(c);}
//        else {triangleSymbol[t(c)]='S'; triangleSymbol[t(l(c))]='w'; Scount++; CLERS[symbols++]=triangleSymbol[t(c)]; stack[stackHeight++]=l(c); c=r(c);};
//      };
//    };
//   print(symbols+":"+CLERS[symbols-1]+" ");
//  } else {print(".");};
// }
// 
//void EBjump() {
//  int t=t(c);
//  if (triangleSymbol[t]=='B') {c=r(c);};
//  if (triangleSymbol[t]=='C') {c=r(c);};
//  if (triangleSymbol[t]=='L') {c=r(c);};
//  if (triangleSymbol[t]=='E') {c=pop();};
//  if (triangleSymbol[t]=='R') {c=l(c);};
//  if (triangleSymbol[t]=='S') {push(l(c)); c=r(c);};
//  }
//
//void EBshow(int c, pt nV, pt pV) {
//  fill(yellow);
//  int t=t(c);
//  pt tV = g(c).make();
//  if (triangleSymbol[t]=='B') {fill(200,200,200);tV.moveTowards(0.07,nV);};
//  if (triangleSymbol[t]=='C') {fill(90,250,200); tV.moveTowards(0.07,nV);};
//  if (triangleSymbol[t]=='L') {fill(20,250,250);};
//  if (triangleSymbol[t]=='E') {fill(155,250,150); tV.moveTowards(0.05,pV); tV.moveTowards(0.05,nV);};
//  if (triangleSymbol[t]=='R') {fill(127,250,200);};
//  if (triangleSymbol[t]=='S') {fill(255,250,150); tV.moveTowards(0.05,pV); tV.moveTowards(0.05,nV);};
//  beginShape(TRIANGLES);  nV.vert();   pV.vert();  tV.vert(); endShape(); 
//  if (triangleSymbol[t]=='B') {EBshow(r(c),nV,tV);};
//  if (triangleSymbol[t]=='C') {EBshow(r(c),nV,tV);};
//  if (triangleSymbol[t]=='L') { EBshow(r(c),nV,tV);};
//  if (triangleSymbol[t]=='E') { };
//  if (triangleSymbol[t]=='R') { EBshow(l(c),tV,pV);};
//  if (triangleSymbol[t]=='S') { EBshow(r(c),nV,tV); EBshow(l(c),tV,pV);};
//  };
//
//void EBprint(int c) {
//   int t=t(c);
//   print(triangleSymbol[t]); CLERS[symbols++]=triangleSymbol[t(c)]; 
//  if (triangleSymbol[t]=='B') {EBprint(r(c));};
//  if (triangleSymbol[t]=='C') {EBprint(r(c));};
//  if (triangleSymbol[t]=='L') {EBprint(r(c));};
//  if (triangleSymbol[t]=='E') { };
//  if (triangleSymbol[t]=='R') {EBprint(l(c));};
//  if (triangleSymbol[t]=='S') {EBprint(r(c)); EBprint(l(c));};
//  };
//
//void EBprintS(int pc) {
// int c=pc; 
// symbols=0;
// resetStack();
// boolean EBisDone=false;
// while (!EBisDone) {
//   int t=t(c);
////   print(triangleSymbol[t]); 
//   CLERS[symbols++]=triangleSymbol[t(c)]; 
//  if (triangleSymbol[t]=='B') {c=r(c);};
//  if (triangleSymbol[t]=='C') {c=r(c);};
//  if (triangleSymbol[t]=='L') {c=r(c);};
//  if (triangleSymbol[t]=='E') {c=pop(); if (stackHeight==0) {EBisDone=true;}};
//  if (triangleSymbol[t]=='R') {c=l(c);};
//  if (triangleSymbol[t]=='S') {push(r(c)); c=l(c);};
//   };
// };
//
//int leadingCS() { int r = 1; while (CLERS[r]=='C') {r++;};  return(r);};
//
//void EBstats(int lCs) {
// int cc=0, cl=0, ce=0, cr=0, cs=0, ct=0; 
// int lc=0, ll=0, le=0, lr=0, ls=0, lt=0; 
// int ec=0, el=0, ee=0, er=0, es=0, et=0; 
// int rc=0, rl=0, re=0, rr=0, rs=0, rt=0; 
// int sc=0, sl=0, se=0, sr=0, ss=0, st=0; 
// char last='C';
//  println("    The "+lCs+" leading Cs are not counted and replaced by an overhead of "+int(log2(lCs))+" bits");
// for (int i=lCs; i<symbols; i++) {
//   char s=CLERS[i];    print(s);
//   if (last=='C') {if(s=='C') {cc++;}; if(s=='L') {cl++;}; if(s=='E') {ce++;}; if(s=='R') {cr++;}; if(s=='S') {cs++;}; };
//   if (last=='L') {if(s=='C') {lc++;}; if(s=='L') {ll++;}; if(s=='E') {le++;}; if(s=='R') {lr++;}; if(s=='S') {ls++;}; };
//   if (last=='E') {if(s=='C') {ec++;}; if(s=='L') {el++;}; if(s=='E') {ee++;}; if(s=='R') {er++;}; if(s=='S') {es++;}; };
//   if (last=='R') {if(s=='C') {rc++;}; if(s=='L') {rl++;}; if(s=='E') {re++;}; if(s=='R') {rr++;}; if(s=='S') {rs++;}; };
//   if (last=='S') {if(s=='C') {sc++;}; if(s=='L') {sl++;}; if(s=='E') {se++;}; if(s=='R') {sr++;}; if(s=='S') {ss++;}; };
//   last=s;
//   };
//  println();
//  print("symbols reduced from "+symbols);  int rsymbols=symbols-lCs;  println(" to "+rsymbols);
//  ct=cc+lc+ec+rc+sc;
//  lt=cl+ll+el+rl+sl;
//  et=ce+le+ee+re+se;
//  rt=cr+lr+er+rr+sr;
//  st=cs+ls+es+rs+ss;
//  
//  float Cf=float(ct)/rsymbols, Lf=float(lt)/rsymbols, Ef=float(et)/rsymbols, Rf=float(rt)/rsymbols, Sf=float(st)/rsymbols;
//  float entropy = -( log2(Cf)*Cf + log2(Lf)*Lf + log2(Ef)*Ef + log2(Rf)*Rf + log2(Sf)*Sf ); 
//   println("100*Frequencies: C="+nf(Cf*100,2,2)+", L="+nf(Lf*100,2,2)+", E="+nf(Ef*100,2,2)+", R="+nf(Rf*100,2,2)+", S="+nf(Sf*100,2,2));
//   println("***   Entropy (over remaining symbols ) = "+nf(entropy,1,2));
//  println();
//  println("COUNTS for "+rsymbols+" CLERS symbols:");
//  println("        COUNTS cc="+nf(cc,4)+",  lc="+nf(lc,4)+",  ec="+nf(ec,4)+",  rc="+nf(rc,4)+",  sc="+nf(sc,4)+" .c="+nf(ct,4)); 
//  println("        COUNTS cl="+nf(cl,4)+",  ll="+nf(ll,4)+",  el="+nf(el,4)+",  rl="+nf(rl,4)+",  sl="+nf(sl,4)+" .l="+nf(lt,4)); 
//  println("        COUNTS ce="+nf(ce,4)+",  le="+nf(le,4)+",  ee="+nf(ee,4)+",  re="+nf(re,4)+",  se="+nf(se,4)+" .e="+nf(et,4)); 
//  println("        COUNTS cr="+nf(cr,4)+",  lr="+nf(lr,4)+",  er="+nf(er,4)+",  rr="+nf(rr,4)+",  sr="+nf(sr,4) +" .r="+nf(rt,4)); 
//  println("        COUNTS cs="+nf(cs,4)+",  ls="+nf(ls,4)+",  es="+nf(es,4)+",  rs="+nf(rs,4)+",  ss="+nf(ss,4) +" .s="+nf(st,4)); 
//  float cost = entropy*rsymbols;   float costWlcs = cost+int(log2(lCs));
//  float e = cost/(symbols);   float eWlcs = costWlcs/(symbols); 
//  println("***  Amortized over all symbols :");
//  println("*** No-context:                 Entropy = "+nf(e,1,2)+" bpt. Total cost = "+nf(cost,6,2)+" bits");
//  println("*** counting RLE of leading Cs: Entropy = "+nf(eWlcs,1,2)+" bpt. Total cost = "+nf(costWlcs,6,2)+" bits");
//
//  println("Pairs frequencies:");
//  println("        COUNTS cc="+nf(float(cc)/rsymbols,1,4)+",  lc="+nf(float(lc)/rsymbols,1,4)+",  ec="+nf(float(ec)/rsymbols,1,4)+",  rc="+nf(float(rc)/rsymbols,1,4)+",  sc="+nf(float(sc)/rsymbols,1,4)+" .c="+nf(float(ct)/rsymbols,1,4)); 
//  println("        COUNTS cl="+nf(float(cl)/rsymbols,1,4)+",  ll="+nf(float(ll)/rsymbols,1,4)+",  el="+nf(float(el)/rsymbols,1,4)+",  rl="+nf(float(rl)/rsymbols,1,4)+",  sl="+nf(float(sl)/rsymbols,1,4)+" .l="+nf(float(lt)/rsymbols,1,4)); 
//  println("        COUNTS ce="+nf(float(ce)/rsymbols,1,4)+",  le="+nf(float(le)/rsymbols,1,4)+",  ee="+nf(float(ee)/rsymbols,1,4)+",  re="+nf(float(re)/rsymbols,1,4)+",  se="+nf(float(se)/rsymbols,1,4)+" .e="+nf(float(et)/rsymbols,1,4)); 
//  println("        COUNTS cr="+nf(float(cr)/rsymbols,1,4)+",  lr="+nf(float(lr)/rsymbols,1,4)+",  er="+nf(float(er)/rsymbols,1,4)+",  rr="+nf(float(rr)/rsymbols,1,4)+",  sr="+nf(float(sr)/rsymbols,1,4) +" .r="+nf(float(rt)/rsymbols,1,4)); 
//  println("        COUNTS cs="+nf(float(cs)/rsymbols,1,4)+",  ls="+nf(float(ls)/rsymbols,1,4)+",  es="+nf(float(es)/rsymbols,1,4)+",  rs="+nf(float(rs)/rsymbols,1,4)+",  ss="+nf(float(ss)/rsymbols,1,4) +" .s="+nf(float(st)/rsymbols,1,4)); 
//
//
//  ct=cc+cl+ce+cr+cs;
//  lt=lc+ll+le+lr+ls;
//  et=ec+el+ee+er+es;
//  rt=rc+rl+re+rr+rs;
//  st=sc+sl+se+sr+ss;
//
//  println();
//  float ccf=0, clf=0, cef=0, crf=0, csf=0;
//  float lcf=0, llf=0, lef=0, lrf=0, lsf=0;
//  float ecf=0, elf=0, eef=0, erf=0, esf=0;
//  float rcf=0, rlf=0, ref=0, rrf=0, rsf=0;
//  float scf=0, slf=0, sef=0, srf=0, ssf=0;
//  
//  if (ct!=0) {  ccf=float(cc)/ct; clf=float(cl)/ct; cef=float(ce)/ct; crf=float(cr)/ct; csf=float(cs)/ct; };
//  if (lt!=0) {  lcf=float(lc)/lt; llf=float(ll)/lt; lef=float(le)/lt; lrf=float(lr)/lt; lsf=float(ls)/lt; };
//  if (et!=0) {  ecf=float(ec)/et; elf=float(el)/et; eef=float(ee)/et; erf=float(er)/et; esf=float(es)/et; };
//  if (rt!=0) {  rcf=float(rc)/rt; rlf=float(rl)/rt; ref=float(re)/rt; rrf=float(rr)/rt; rsf=float(rs)/rt; };
//  if (st!=0) {  scf=float(sc)/st; slf=float(sl)/st; sef=float(se)/st; srf=float(sr)/st; ssf=float(ss)/st; };
//  
//  println("  Context frequencies");
//  println("        % cc="+nf(ccf,0,2)+",  lc="+nf(lcf,0,2)+",  ec="+nf(ecf,0,2)+",  rc="+nf(rcf,0,2)+",  sc="+nf(scf,0,2)); 
//  println("        % cl="+nf(clf,0,2)+",  ll="+nf(llf,0,2)+",  el="+nf(elf,0,2)+",  rl="+nf(rlf,0,2)+",  sl="+nf(slf,0,2)); 
//  println("        % ce="+nf(cef,0,2)+",  le="+nf(lef,0,2)+",  ee="+nf(eef,0,2)+",  re="+nf(ref,0,2)+",  se="+nf(sef,0,2)); 
//  println("        % cr="+nf(crf,0,2)+",  lr="+nf(lrf,0,2)+",  er="+nf(erf,0,2)+",  rr="+nf(rrf,0,2)+",  sr="+nf(srf,0,2)); 
//  println("        % cs="+nf(csf,0,2)+",  ls="+nf(lsf,0,2)+",  es="+nf(esf,0,2)+",  rs="+nf(rsf,0,2)+",  ss="+nf(ssf,0,2)); 
//  println();
//   
//  float cE = -( log2(ccf)*ccf + log2(clf)*clf + log2(cef)*cef + log2(crf)*crf + log2(csf)*csf ) ; 
//  float lE = -( log2(lcf)*lcf + log2(llf)*llf + log2(lef)*lef + log2(lrf)*lrf + log2(lsf)*lsf ) ; 
//  float eE = -( log2(ecf)*ecf + log2(elf)*elf + log2(eef)*eef + log2(erf)*erf + log2(esf)*esf ) ; 
//  float rE = -( log2(rcf)*rcf + log2(rlf)*rlf + log2(ref)*ref + log2(rrf)*rrf + log2(rsf)*rsf ) ; 
//  float sE = -( log2(scf)*scf + log2(slf)*slf + log2(sef)*sef + log2(srf)*srf + log2(ssf)*ssf ) ; 
//  
//  println("    Stream entropies: after C="+nf(cE,1,2)+", after L="+nf(lE,1,2)+", after E="+nf(eE,1,2)+", after R="+nf(rE,1,2)+", after S="+nf(sE,1,2));
//  println("    Frequencies:            C="+nf(Cf,1,2)+",       L="+nf(Lf,1,2)+",       E="+nf(Ef,1,2)+",       R="+nf(Rf,1,2)+",       S="+nf(Sf,1,2));
//  float Centropy=cE*Cf+lE*Lf+eE*Ef+rE*Rf+sE*Sf;
//  cost = Centropy*rsymbols;    costWlcs = cost+int(log2(lCs));
//  e = cost/symbols;    eWlcs = costWlcs/symbols; 
//  println("***   Entropy (over remaining symbols ) = "+nf(Centropy,1,2));
//  println("***  Amortized over all symbols :");
//  println("*** Average context Entropy = "+nf(Centropy,1,2)+" bpt. Total cost = "+nf(Centropy*symbols,6,2)+" bits");
//  println("*** Ccontext:                   Entropy = "+nf(e,1,2)+" bpt. Total cost = "+nf(cost,6,2)+" bits");
//  println("*** counting RLE of leading Cs: Entropy = "+nf(eWlcs,1,2)+" bpt. Total cost = "+nf(costWlcs,6,2)+" bits");
//  println("+++++++++++++++++++++++++++++++++++++++++++++");
//  }
//
//  } // ==== END OF MESH CLASS
//  
//float log2(float x) {float r=0; if (x>0.00001) { r=log(x) / log(2);} ; return(r);}
//vec labelD=new vec(-4,+4, 12);           // offset vector for drawing labels
//int maxr=1;

