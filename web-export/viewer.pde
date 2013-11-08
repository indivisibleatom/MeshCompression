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

//Linear interpolation
pt morph(pt p1, pt p2, float t)
{
   pt result = new pt();
   result.set(p1);
   result.mul(1-t);
   pt temp = new pt();
   temp.set(p2);
   temp.mul(t);
   result.add(temp);
   return result;
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

 

  
  
int ISLAND_SIZE = 5;
int MAX_ISLANDS = 40000;

int numIslands = 0; //TODO msati3: Move this inside islandMesh
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
  private IslandExpansionManager m_expansionManager;

  IslandMesh m_mesh;

  public RingExpanderResult(IslandMesh m, int seed, int[] parentTrianglesArray)
  {
    m_seed = seed;
    m_parentTArray = parentTrianglesArray;
    m_mesh = m;
    m_numTrianglesToColor = -1;
    m_expansionManager = new IslandExpansionManager();
  }

  private void setColor(int corner)
  {
    m_mesh.tm[m_mesh.t(corner)] = ISLAND;
  }

  private boolean isValidChild(int childCorner, int parentCorner)
  {
    if ( (m_mesh.hasValidR(parentCorner) && childCorner == m_mesh.r(parentCorner)) || (m_mesh.hasValidL(parentCorner) && childCorner == m_mesh.l(parentCorner)) )
    {
      if (m_parentTArray[childCorner] == m_mesh.t(parentCorner))
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
      m_mesh.tm[i] = WATER;
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
      if (m_mesh.t(m_mesh.o(corner)) == m_parentTArray[corner])
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
    m_mesh.tm[tri] = WATER;
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
      if (isValidChild(m_mesh.r(corner), corner) && m_mesh.tm[m_mesh.t(m_mesh.r(corner))] != WATER)
      {
        succStack.push(new VisitState(m_mesh.r(corner)));
        numSuc++;
      }
      if (isValidChild(m_mesh.l(corner), corner) && m_mesh.tm[m_mesh.t(m_mesh.l(corner))] != WATER)
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
    if (isValidChild(m_mesh.r(corner), corner) && m_mesh.tm[m_mesh.t(m_mesh.r(corner))] != WATER)
    {
      numChild++;
    }
    if (isValidChild(m_mesh.l(corner), corner) && m_mesh.tm[m_mesh.t(m_mesh.l(corner))] != WATER)
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
    if (isValidChild(m_mesh.l(corner), corner) && m_mesh.tm[m_mesh.t(m_mesh.l(corner))] != WATER)
    {
      return m_mesh.l(corner);
    }
    if (isValidChild(m_mesh.r(corner), corner) && m_mesh.tm[m_mesh.t(m_mesh.r(corner))] != WATER)
    {
      return m_mesh.r(corner);
    } 
    return -1;
  }

  private void markVisited(int triangle, int islandNumber)
  {
    m_mesh.triangleIsland[triangle] =  islandNumber;
    m_mesh.island[m_mesh.c(triangle)] = islandNumber;
    m_mesh.island[m_mesh.n(m_mesh.c(triangle))] = islandNumber;
    m_mesh.island[m_mesh.p(m_mesh.c(triangle))] = islandNumber;
    markCorner(m_mesh.c(triangle), islandNumber); markCorner(m_mesh.n(m_mesh.c(triangle)), islandNumber); markCorner(m_mesh.p(m_mesh.c(triangle)), islandNumber);
  }
  
  private void markUnVisited(int triangle)
  {
    m_mesh.triangleIsland[triangle] = -1;
    m_mesh.island[m_mesh.c(triangle)] = -1;
    m_mesh.island[m_mesh.n(m_mesh.c(triangle))] = -1;
    m_mesh.island[m_mesh.p(m_mesh.c(triangle))] = -1;
    unmarkCorner(m_mesh.c(triangle)); unmarkCorner(m_mesh.n(m_mesh.c(triangle))); unmarkCorner(m_mesh.p(m_mesh.c(triangle)));
  }
  
  private void markCorner( int corner, int islandNumber )
  {
    m_mesh.cm[corner] = 100+islandNumber;
  }
  
  private void unmarkCorner( int corner )
  {
    m_mesh.cm[corner] = 0;
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
      if (isValidChild(m_mesh.r(corner), corner) && m_mesh.tm[m_mesh.t(m_mesh.r(corner))] != WATER)
      {
        submergeStack.push(m_mesh.r(corner));
      }
      if (isValidChild(m_mesh.l(corner), corner) && m_mesh.tm[m_mesh.t(m_mesh.l(corner))] != WATER)
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
        if (isValidChild(m_mesh.r(corner), corner) && m_mesh.tm[m_mesh.t(m_mesh.r(corner))] != WATER)
        {
          submergeStack.push(m_mesh.r(corner));
        }
        if (isValidChild(m_mesh.l(corner), corner) && m_mesh.tm[m_mesh.t(m_mesh.l(corner))] != WATER)
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
                if (hasVertices(m_mesh.t(corner), shoreVertsR) && hasVertices(m_mesh.t(corner), shoreVertsL))
                {
                  numIslands--;
                  renumberIslands(m_mesh.island[m_mesh.l(corner)]);
                  submergeOther(m_mesh.l(corner), shoreVertsR);
                }
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
    IslandExpansionStream currentStream = m_expansionManager.addIslandStream();
    Stack<Integer> markStack = new Stack<Integer>();
    markStack.push(corner);
    int count = 0;
    char ch1, ch2, ch = 0;

    currentStream.addG( count++, m_mesh.g(m_mesh.p(corner)), ch );
    currentStream.addG( count++, m_mesh.g(m_mesh.n(corner)), ch );

    while (!markStack.empty())
    {
      ch1 = 0; ch2 = 0; ch = 0;
      corner = markStack.pop();
      if (isValidChild(m_mesh.r(corner), corner) && m_mesh.tm[m_mesh.t(m_mesh.r(corner))] != WATER)
      {
        markStack.push(m_mesh.r(corner));
        ch1 = 'r';
      }
      if (isValidChild(m_mesh.l(corner), corner) && m_mesh.tm[m_mesh.t(m_mesh.l(corner))] != WATER)
      {
        markStack.push(m_mesh.l(corner));
        ch2 = 'l';
      }

      //Populate appropriate triangle character
      if (ch1 == 'l' && ch2 == 'r')
      {
        ch = 's';
      }
      else
      {
        ch = (ch1 == 0) ? ch2 : ch1;
      }

      currentStream.addG( count++, m_mesh.g(corner), ch );
      markVisited(m_mesh.t(corner), islandNumber);
    }
  }
  
  private void renumberIslands(int islandNumber)
  {
     m_expansionManager.removeIslandStream( islandNumber );
    if (islandNumber == -1)
    {
      if ( DEBUG && DEBUG_MODE >= LOW )
      {
        print("RingExpanderResult::renumberIsland - supplying -1 as islandNumber. Bug!");
      }
      return;
    }
    for (int i = 0; i < m_mesh.nt; i++)
    {
      if ( m_mesh.island[3*i] > islandNumber )
      {
        markVisited(i, m_mesh.island[3*i]-1);
      }
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
      if (DEBUG && DEBUG_MODE >= LOW)
      {
        print("Correct corner not found. Returning");
      }
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
        submergeAll(cornerToStart);
        g_submersionCounter.incBadSubmersion();
      }
       numIslands--;
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
  
  public IslandExpansionManager getIslandExpansionManager()
  {
    return m_expansionManager;
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
  private IslandMesh m_mesh;
  
  StatsCollector( IslandMesh mesh )
  {
    m_mesh = mesh;
    output = createWriter("stats.csv");
    output.println("Num Triangles in Mesh\t Num triangles not on LR traversal\t Num water triangles after island formation\t Num triangles introduced by island formation\t Num Islands");
  }
  
  private void collectStats(int numTries, int islandSize)
  {
    for (int i = 0; i < numTries; i++)
    {
      ISLAND_SIZE = islandSize;
      int seed = (int)random(m_mesh.nt * 3);
      
      RingExpander expander = new RingExpander(m_mesh, seed); 
      RingExpanderResult result = expander.completeRingExpanderRecursive();
      m_mesh.setResult(result);
      m_mesh.showRingExpanderCorners();

      int numWater = 0;

      for (int j = 0; j < m_mesh.nt; j++)
      {
        if (m_mesh.tm[j] == WATER )
        {
          numWater++;
        }
      }
      
      m_mesh.formIslands(result.seed());
      ColorResult res = m_mesh.colorTriangles();

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
class BaseMesh extends Mesh
{
  int m_expandedIsland;
  IslandExpansionManager m_expansionManager;
  
  BaseMesh()
  {
    m_userInputHandler = new BaseMeshUserInputHandler(this);
    m_expandedIsland = -1;
    m_expansionManager = null;
  }
  
  void setExpansionManager( IslandExpansionManager manager )
  {
    m_expansionManager = manager;
  }
  
  void onExpandIsland()
  {
    if ( m_expansionManager != null )
    {
      if ( v(cc) < numIslands )
      {
        m_expandedIsland = v(cc);
      }
    }
  }
  
  void draw()
  {
    super.draw();
    drawExpandedIsland();
  }
  
  private void drawExpandedIsland()
  {
    if ( m_expandedIsland != -1 )
    {
      Mesh singleIslandMesh = m_expansionManager.getStream( m_expandedIsland ).createAndGetMesh();
      m_viewport.registerMesh(singleIslandMesh);
      singleIslandMesh.getDrawingState().m_fShowVertices = true;
      singleIslandMesh.draw();
      m_viewport.unregisterMesh(singleIslandMesh);
    }
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

class EgdeBreakerCompress
{
  private Mesh m_mesh;
  private boolean[] m_tVisited;
  private boolean[] m_vVisited;
  int m_numTrianglesVisited;
  String m_edgeBreakerString;

  public EgdeBreakerCompress(Mesh mesh)
  {
    m_mesh = mesh;
    m_tVisited = new boolean[m_mesh.nt];
    m_vVisited = new boolean[m_mesh.nv];
    m_edgeBreakerString = new String();
  }

  public void initCompression()
  {
    int initCorner = 0;
    m_vVisited[m_mesh.v(initCorner)] = true;
    m_vVisited[m_mesh.v(m_mesh.n(initCorner))] = true;
    m_vVisited[m_mesh.v(m_mesh.p(initCorner))] = true;
    m_tVisited[m_mesh.t(initCorner)] = true;
    m_numTrianglesVisited = 1;
    compress(m_mesh.o(initCorner));
    print ("EdgeBreaker compression" + m_edgeBreakerString);
  }

  public boolean allTrianglesVisited()
  {
    return (m_numTrianglesVisited == m_mesh.nt);
  }

  public void compress(int corner)
  {
    do
    {
      m_tVisited[m_mesh.t(corner)] = true;
      m_numTrianglesVisited++;
      if ( !m_vVisited[m_mesh.v(corner)] )
      {
        m_edgeBreakerString+="C";
        m_vVisited[m_mesh.v(corner)] = true;
      }
      else if ( m_tVisited[m_mesh.t(m_mesh.r(corner))] )
      {
        if ( m_tVisited[m_mesh.t(m_mesh.l(corner))] )
        {
          m_edgeBreakerString+="E";
          return;
        }
        else
        {
          m_edgeBreakerString+="R";
          corner = m_mesh.l( corner );
        }
      }
      else
      {
        if ( m_tVisited[m_mesh.t(m_mesh.l(corner))] )
        {
          m_edgeBreakerString+="L";
          corner = m_mesh.r( corner );
        }
        else
        {
          m_edgeBreakerString+="S";
          compress( m_mesh.r( corner ) );
          corner = m_mesh.l( corner );
        }
      }
    } 
    while ( true );
  }
}

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

int pictureCounter=0;
void snapPicture() {saveFrame("PICTURES/P"+nf(pictureCounter++,3)+".jpg");}


class IslandExpansionStream
{
  private String m_SLRString;
  private pt []m_G;  

  IslandExpansionStream()
  {
    m_SLRString = new String();
    m_G = new pt[ISLAND_SIZE + 2];
  }
  
  //TODO msati3: For simplicity. Can be speeded up by doing this is IslandExpansionManager
  void addG(int num, pt G, char SLRChar)
  {
    m_G[num] = P( G );
    if ( DEBUG && DEBUG_MODE >= VERBOSE )
    {
      print ("Adding G " + num + " " + SLRChar);
    }
    if ( num > 1 )
    {
      m_SLRString += SLRChar;
    }
  }
  
  pt[] getVertices()
  {
    return m_G;
  }
  
  Mesh createAndGetMesh()
  {
    Mesh m = new Mesh();
    m.addVertex( m_G[0] );
    m.addVertex( m_G[1] );
    int prevV = 0;
    int nextV = 1;
    for (int i = 2; i < m_G.length; i++)
    {
      if (prevV == -1)
      {
        if ( DEBUG && DEBUG_MODE >= LOW )
        {
            print("IslandExpansionStream : createAndGetMesh - Neither of S, L or R in LR string");
        }
      }
      m.addVertex( m_G[i] );
      m.addTriangle( prevV, i, nextV );
      m.tm[i-2] = ISLAND;
      if ( m_SLRString.charAt(i - 2) == 'r' )
      {
        prevV = i;
        nextV = nextV;
      }
      else if ( m_SLRString.charAt(i - 2) == 'l' )
      {
        prevV = prevV;
        nextV = i;
      }
      else if ( m_SLRString.charAt(i - 2) == 's' )
      {
        print("This case");
      }
      else
      {
        prevV = -1;
        nextV = -1;
      }
      if ( DEBUG && DEBUG_MODE >= VERBOSE )
      {
        print("IslandExpanderStream: create and get mesh - " + nextV + " " + prevV + " " + i + " " + m_SLRString.charAt(i-2) + "\n");
      }
    }
    return m;
  }
}

class IslandExpansionManager
{
  private ArrayList<IslandExpansionStream> m_islandStreams;
  
  IslandExpansionManager()
  {
    m_islandStreams = new ArrayList<IslandExpansionStream>();
  }
  
  IslandExpansionStream addIslandStream()
  {
    m_islandStreams.add( new IslandExpansionStream() );
    return getStream( m_islandStreams.size() - 1 );
  }
  
  void removeIslandStream(int islandNumber)
  {
    m_islandStreams.remove( islandNumber );
  }
  
  IslandExpansionStream getStream(int islandNumber)
  {
    return m_islandStreams.get( islandNumber );
  }
}

//TYPES OF TRIANGLES
int SPLIT = 1;
int GATE = 2;
int CHANNEL = 3;
int WATER = 8; //Water before forming islands
int ISOLATEDWATER = 4;
int LAGOON = 5;
int JUNCTION = 6;
int CAP = 7;
int ISLAND = 9;

class IslandMesh extends Mesh
{
 boolean m_fDrawIsles = false;
 pt[] baseG = new pt [maxnv];               // to store the locations of the vertices in their contracted form
 int[] island = new int[3*maxnt];
 int[] triangleIsland = new int[maxnt];
 
 pt[] islandBaryCenter = new pt[MAX_ISLANDS];
 float[] islandArea = new float[MAX_ISLANDS];

 //Morphing functionality
 float m_currentT; //Storing the current value of T for morphing
 boolean m_fMorphing; //True if morphing
 boolean m_fCollapsed; //store if this is collapsed state or not

 Map<Integer, Integer> m_vertexForIsland; //A representative vertex of main mesh in a particular island
 Map<Integer, Integer> m_islandForWaterVert; //Mapping of water vertices to island numbers in base mesh

 //TODO msati3: clean this up...where does this go? Do wholistically
 RingExpanderResult m_ringExpanderResult = null;
 BaseMesh baseMesh = null;
 
 //Debugging functionality
 int m_numAdvances = -1; //For advancing on an island border
 int m_currentAdvances = 0;
 int m_selectedIsland = -1;
 
 IslandMesh()
 {
   m_userInputHandler = new IslandMeshUserInputHandler(this);
 }

 void resetMarkers() 
 {
   super.resetMarkers();
   for (int i = 0; i < island.length; i++) island[i] = -1;
 }
 
 void setResult(RingExpanderResult result)
 {
   m_ringExpanderResult = result;
 }
   
 void advanceRingExpanderResult()
 {
   if (m_ringExpanderResult != null)
   {
     m_ringExpanderResult.advanceStep();
   }
 }
   
 void showRingExpanderCorners()
 {
   if (m_ringExpanderResult != null)
   {
     m_ringExpanderResult.colorRingExpander();
   }
 }
   
 void formIslands(int initCorner)
 {
   m_fDrawIsles = true;
   if (m_ringExpanderResult != null)
   {
     showRingExpanderCorners();
     m_ringExpanderResult.formIslands(initCorner);
   }
 }
 
 //Adds morphing to base mesh, aside from normal functionality of a mesh
 void draw()
 {
   if (m_fMorphing)
   {
     if (!m_fCollapsed)
     {
        morphToBaseMesh();
     }
     else
     {
        morphFromBaseMesh();
     }
   }
   super.draw();
   drawIsland();

 }
 
 private void drawIsland()
 {
   for (int i = 0; i < nt; i++)
   {
     if (m_selectedIsland != -1 && island[3*i] == m_selectedIsland)
     {
       vm[m_vertexForIsland.get(m_selectedIsland)] = 5;
       fill(red);
       shade(i);
     }
   }
 }
 
 void selectIsland(int islandNum)
 {
   m_selectedIsland = islandNum;
 }
  
 void toggleMorphingState()
 {
   m_fMorphing = true;
 }
 
 //Queryable state functions
 int getNumIslands()
 {
   return numIslands;
 }
 
 public int getIslandForVertex(int vertex)
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


 private void morphFromBaseMesh()
 {    
   pt[] temp = baseG;
   baseG = G;
   G = temp;
   if (m_currentT > 0)
   {
     m_currentT -= 0.01;
   }
   else
   {
     m_fMorphing = false;
     m_fCollapsed = false;
     m_currentT = 0;
   }

   for (int i = 0; i < nv; i++)
   {
     int vertexType = getVertexType(i);
     switch (vertexType)
     {
       case 0: int island = getIslandForVertex(i);
               if (island == -1)
               {
                 if ( DEBUG && DEBUG_MODE >= LOW )
                 {
                   print("Fatal error!! Get island == -1 for vertex of type IslandVertex");
                 }
               }
               if (islandBaryCenter[island] == null)
               {
                 if ( DEBUG && DEBUG_MODE >= LOW )
                 {
                   print("Barycenter null for " + island + " " + numIslands);
                 }
               }
               baseG[i] = morph(G[i], islandBaryCenter[island], m_currentT);
               break;
       case 1: baseG[i] = new pt();
               baseG[i].set(G[i]);
               break;
       default: if ( DEBUG && DEBUG_MODE >= LOW ) { print("Fatal error!! Vertex not classified as water or island vertex"); }
               break;
     }
   }
   temp = G;
   G = baseG;
   baseG = temp;
   updateON();
 }

 private void morphToBaseMesh()
 {
   if (m_currentT != 0)
   {
     pt[] temp = baseG;
     baseG = G;
     G = temp;
   }
   if (m_currentT < 1)
   {
     m_currentT += 0.01;
   }
   else
   {
     m_fMorphing = false;
     m_fCollapsed = true;
     m_currentT = 1;
   }
   for (int i = 0; i < nv; i++)
   {
     int vertexType = getVertexType(i);
     switch (vertexType)
     {
       case 0: int island = getIslandForVertex(i);
               if (island == -1)
               {
                 if ( DEBUG && DEBUG_MODE >= LOW )
                 {
                   print("IslandMesh::MorphtoBaseMesh - Fatal error!! Get island == -1 for vertex of type IslandVertex");
                 }
               }
               if (islandBaryCenter[island] == null)
               {
                 if ( DEBUG && DEBUG_MODE >= LOW )
                 {
                   print("IslandMesh::MorphtoBaseMesh - Barycenter null for " + island + " " + numIslands);
                 }
               }
               baseG[i] = morph(G[i], islandBaryCenter[island], m_currentT);
               break;
       case 1: baseG[i] = new pt();
               baseG[i].set(G[i]);
               break;
       default: if ( DEBUG && DEBUG_MODE >= LOW )
               { 
                 print("Fatal error!! Vertex not classified as water or island vertex");
               }
               break;
     }
   }
   pt[] temp = G;
   G = baseG;
   baseG = temp;
 }
   
   
 //************************PRIVATE helpers***********************
 //State checking functions
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

 //Gives a vertex, returns any one corner incident on the vertex and incident on an island
 //TODO msati3: There can be multiple such corners. Which one to return?
 private int getIslandCornerForVertex(int vertex)
 {
   int initCorner = cForV(vertex);
   int curCorner = initCorner;
   do
   {
     if (island[curCorner] != -1)
     {
       return curCorner;
     }
     curCorner = s(curCorner);
   }while (curCorner != initCorner);
   return -1;
 }

 //Returns island number ( = vertex id in base mesh ). Also assigns numbers to water vertices
 private int getIslandForVertexExtended(int vertex)
 {
   int island = getIslandForVertex(vertex);
   if ( island == -1 )
   {
     return m_islandForWaterVert.get( vertex );
   }
   return island;
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
  
 private int getIslandAtCorner(int corner)
 {
   return island[corner];
 }

 //Given a corner, swing around to find an island
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
   
 //Given two corners, returns is this triangle lies on a beach edge
 private boolean hasBeachEdgeAroundCorners(int c1, int c2)
 {
   int island1 = getIsland(c1);
   int island2 = getIsland(c2);
     
   if ((island1 != -1 && island2 != -1) && ((island[s(c1)] == -1 && island[u(c2)] == -1)||(island[u(c1)] == -1 && island[s(c2)] == -1)))
   {
     if (island1 == island2)
     {
       return true;
     }
   }
   return false;
 }
   
 //Given two corners, returns if the edge bounding them in the triangle containing them is a beach eadge. Returns false if they don't lie on the same triangle
 private boolean hasBeachEdgeForCorners(int c1, int c2)
 {
   if (!((n(c1) == c2 || p(c1) == c2)))
   {
     return false;
   }

   int island1 = getIslandAtCorner(c1);
   int island2 = getIslandAtCorner(c2);
   int otherCorner = n(c1) == c2 ? p(c1) : n(c1);
   int opposite = o(otherCorner);
   int island3 = getIslandAtCorner(n(opposite));
   int island4 = getIslandAtCorner(p(opposite));

   if ((island1 != -1 && island2 != -1) && (island3 == -1 && island4 == -1))
   {
     if (island1 == island2)
     {
       return true;
     }
     else
     {
       //print("Islands on the beach edge are not the same. Failure!!" + island1 + " " + island2);
     }
   }
   return false;
 }
   
 private boolean hasBeachEdge(int triangle)
 {
   int corner = c(triangle);
   int count = 0;
   while(count < 3)
   {
     if ( hasBeachEdgeAroundCorners( corner, n(corner) ) )
     {
       return true;
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
       tm[i] = ISLAND;
     }
     else if (hasBeachEdge(i)) //shallow
     {
       if (island1 != -1 && island2 != -1 && island3 != -1 && (island1 == island2 || island1 == island3 || island2 == island3))
       {
         if (island1 == island2 && island1 == island3)
         {
           countLagoons++;
           tm[i] = LAGOON; //Lagoon
         }
         else
         {
           if (island1 != -1 && island2 != -1 && island3 != -1 && (island1 != island2 || island1 != island3))
           {
             countGood++;
             tm[i] = CHANNEL;
           }
           else
           {
             if (DEBUG && DEBUG_MODE >= LOW)
             {
               print ("This case unhandled!");
             }
           }
         }
       }
       else
       {
         tm[i] = CAP; //Cap triangle
       }
     }
    else //deep
     {
         if (island1 != -1 && island2 != -1 && island3 != -1 && island1 == island2 && island1 == island3)
         {
           tm[i] = SPLIT;
         }
         else if (island1 != -1 && island2 != -1 && island3 != -1 && (island1 == island2 || island1 == island3 || island2 == island3))
         {
           tm[i] = GATE;
         }
         else if (island1 != -1 && island2 != -1 && island3 != -1)
         {
           countSeparator++;
           tm[i] = JUNCTION;
         }
         else
         {
           countBad++;
           tm[i] = ISOLATEDWATER;
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
   if ( DEBUG && DEBUG_MODE >= VERBOSE )
   {
     print("\nStats : Total " + nt + " Land " + countLand + " Good water " + countGood + " Island separators " + countSeparator + " Lagoons " + countLagoons + " Bad water " + countBad + "Num Water Verts " + numWaterVerts);
   }
     
   //TODO msati3: This is a hack. Should be made a separate function
   computeBaryCenterForIslands();
   calculateFinalLocationsForVertices();
   return new ColorResult(nt, countLand, countGood, countSeparator, countLagoons, countBad, numVerts, numWaterVerts, numNormalVerts);
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
         float area = m_utils.computeArea(j);
         islandArea[i] += area;
         islandBaryCenter[i].add(m_utils.baryCenter(j).mul(area));
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
                 if ( DEBUG && DEBUG_MODE >= LOW )
                 {
                   print("Fatal error!! Get island == -1 for vertex of type IslandVertex");
                 }
               }
               baseG[i] = islandBaryCenter[island];
               break;
       case 1: baseG[i] = G[i];
               break;
       default: if ( DEBUG && DEBUG_MODE >= LOW )
               {
                 print("Fatal error!! Vertex not classified as water or island vertex");
               }
               break;
     }
   }
 }   
   
   private int getNumWaterVerts()
   {
     int numWaterVerts = 0;
     for (int i = 0; i < nv; i++ )
     {
       if ( !isIslandVertex(i) )
       {
         numWaterVerts++;
       }
     }
     return numWaterVerts;
   }
   
   BaseMesh populateBaseG()
   {
     print("Creating new base mesh");
     baseMesh = new BaseMesh();
     baseMesh.setExpansionManager( m_ringExpanderResult.getIslandExpansionManager() );
     baseMesh.declareVectors();

     m_vertexForIsland = new HashMap< Integer, Integer >();
     m_islandForWaterVert = new HashMap< Integer, Integer >();
     int numWaterVerts = getNumWaterVerts();
     int countWater = 0;
     pt[] baseMeshG = new pt[numIslands + numWaterVerts];
     for (int i = 0; i < baseMeshG.length; i++)
     {
       baseMeshG[i] = null;
     }
     baseMesh.G = baseMeshG;
     for (int i = 0; i < nv; i++ )
     {
       if ( isIslandVertex(i) )
       {
         int island = getIslandForVertex( i );
         if ( m_vertexForIsland.get( island ) == null )
         {
           m_vertexForIsland.put( island, i );
           baseMeshG[ island ] = P(islandBaryCenter[island]); 
         }
       }
       else
       {
         m_vertexForIsland.put( numIslands + countWater, i );
         m_islandForWaterVert.put( i, numIslands + countWater );
         baseMeshG[ numIslands + countWater ] = G[i]; 
         countWater++;
       }
     }
     baseMesh.nv = baseMesh.G.length;
     if ( DEBUG && DEBUG_MODE >= VERBOSE )
     {
       print ("Base mesh created with number of vertices " + (numIslands + numWaterVerts));
     }
     return baseMesh;
   }
   
   void onBeforeAdvanceOnIslandEdge()
   {
     for (int i = 0; i < 3*nt; i++)
     {
       cm[i] = 0;
     }
     m_numAdvances = 1;
     m_currentAdvances = 0;
   }
   
   void connectMeshStepByStep()
   {
     m_currentAdvances = 0;
     for (int i = 0; i < baseMesh.G.length; i++)
     {
       int v = m_vertexForIsland.get(i);
       if ( isIslandVertex( v ) && connectInBaseMesh(v) )
       {
         int currentVOnIsland = v;
         int prevVOnIsland = v;
         int prevPrevVOnIsland = v;
         int returnedVertex = -1;
         int bTrackedC2 = -1, bTrackedC3 = -1; //Track the last added triangle corners in the base mesh for this island.
         int nextUsedIsland = -1; //Track the next used island post a junction / water triangle.
         int bFirstC2 = -1, bFirstC3 = -1; //Trac the initial triangle, so that the last can be combined post encircling the edges of the island

         ArrayList<Integer> cornerList = new ArrayList<Integer>(); //Return the cornerList og JUNCTION and ISOLATEDWATER triangles obtained by swinging around
         do
         {
           int incidentCorner = incidentTriangleType( currentVOnIsland, prevVOnIsland, JUNCTION, ISOLATEDWATER, cornerList );

           if ( incidentCorner != -1 )
           {
             for (int j = 0; j < cornerList.size(); j++)
             {
               incidentCorner = cornerList.get(j);
               int vertex2 = v( n( incidentCorner ) );
               int vertex3 = v( p( incidentCorner ) );
               int bv1 = i;
               int island2 = getIslandForVertexExtended( vertex2 );
               int island3 = getIslandForVertexExtended( vertex3 );

               int bv2 = island2;
               int bv3 = island3;

               if ( bv2 != -1 && bv3 != -1 )
               {
                 baseMesh.addTriangle(bv1, bv2, bv3);
                 if ( bTrackedC2 != -1 )
                 {
                   addOppositeForUnusedIsland( baseMesh.nc-1, baseMesh.nc-2, bTrackedC2, bTrackedC3, nextUsedIsland );                                      
                 }
                 else
                 {
                   bFirstC2 = baseMesh.nc-2;
                   bFirstC3 = baseMesh.nc-1;
                 }

                 nextUsedIsland = getNextUsedIslandFromCorner( incidentCorner );

                 bTrackedC2 = baseMesh.nc-2;
                 bTrackedC3 = baseMesh.nc-1;
                 
                 if (nextUsedIsland != -1)
                 {
                   vm[m_vertexForIsland.get(nextUsedIsland)] = 5;
                 }
                 cm[incidentCorner] = 2;
                 cm[n(incidentCorner)] = 2;
                 cm[p(incidentCorner)] = 2;
               }
               else
               {
                 if ( DEBUG && DEBUG_MODE >= VERBOSE )
                 {
                   print ("Get a -1 as one of the base vertices incident on a Junction / Water triangle. Error!");
                 }
               }
             }
           }
           vm[v] = 1;
           m_currentAdvances++;
           if ( m_currentAdvances >= m_numAdvances )
           {
             if ( DEBUG && DEBUG_MODE >= VERBOSE )
             {
               print ("NumAdvances " + m_numAdvances);
             }
             m_numAdvances++;
             return;
           }
           returnedVertex = getNextVertexOnIsland( v, currentVOnIsland, prevVOnIsland, prevPrevVOnIsland );
           if ( DEBUG && DEBUG_MODE >= VERBOSE )
           {
             print("Next vertex " + returnedVertex );
           }
           prevPrevVOnIsland = prevVOnIsland;
           prevVOnIsland = currentVOnIsland;
           currentVOnIsland = returnedVertex;
           if (returnedVertex != -1)
           {
             vm[currentVOnIsland] = 2;
           }
           vm[prevVOnIsland] = 3;
           vm[prevPrevVOnIsland] = 1;
         } while ( returnedVertex != -1 );
         if ( bTrackedC2 != -1 )
         {
           if ( m_numAdvances != -1 && m_currentAdvances == m_numAdvances-1 )
           {
             if ( DEBUG && DEBUG_MODE >= LOW )
             {
               print("Closing");
             }
           }
           addOppositeForUnusedIsland( bFirstC2, bFirstC3, bTrackedC2, bTrackedC3, nextUsedIsland );
         }
       }
       else if ( !isIslandVertex(v) ) //Is a water vertex
       {
         int initCorner = incidentTriangleType( v, ISOLATEDWATER );
         int currentCorner = initCorner;
         if ( DEBUG && DEBUG_MODE >= VERBOSE )
         {
           print("Found corner " + currentCorner);
         }
         do
         {
           int island2 = getIslandForVertexExtended( v(n(currentCorner)) );
           int island3 = getIslandForVertexExtended( v(p(currentCorner)) );
           baseMesh.addTriangle(i, island2, island3);
           currentCorner = s(currentCorner);
         } while (currentCorner != initCorner);
       }
     } //end for loop over base mesh vertices
   }

   void connectMesh()
   {
     m_numAdvances = -1;
     for (int i = 0; i < baseMesh.G.length; i++)
     {
       int v = m_vertexForIsland.get(i);
       if ( isIslandVertex( v ) && connectInBaseMesh(v) )
       {
         int currentVOnIsland = v;
         int prevVOnIsland = v;
         int prevPrevVOnIsland = v;
         int returnedVertex = -1;
         int bTrackedC2 = -1, bTrackedC3 = -1; //Track the last added triangle corners in the base mesh for this island.
         int nextUsedIsland = -1; //Track the next used island post a junction / water triangle.
         int bFirstC2 = -1, bFirstC3 = -1; //Track the initial triangle, so that the last can be combined post encircling the edges of the island

         ArrayList<Integer> cornerList = new ArrayList<Integer>(); //Return the cornerList og JUNCTION and ISOLATEDWATER triangles obtained by swinging around
         do
         {
           int incidentCorner = incidentTriangleType( currentVOnIsland, prevVOnIsland, JUNCTION, ISOLATEDWATER, cornerList );

           if ( incidentCorner != -1 )
           {
             for (int j = 0; j < cornerList.size(); j++)
             {
               incidentCorner = cornerList.get(j);
               int vertex2 = v( n( incidentCorner ) );
               int vertex3 = v( p( incidentCorner ) );
               int bv1 = i;
               int island2 = getIslandForVertexExtended( vertex2 );
               int island3 = getIslandForVertexExtended( vertex3 );

               int bv2 = island2;
               int bv3 = island3;

               if ( bv2 != -1 && bv3 != -1 )
               {
                 baseMesh.addTriangle(bv1, bv2, bv3);
                 if ( bTrackedC2 != -1 )
                 {
                   addOppositeForUnusedIsland( baseMesh.nc-1, baseMesh.nc-2, bTrackedC2, bTrackedC3, nextUsedIsland );                                      
                 }
                 else
                 {
                   bFirstC2 = baseMesh.nc-2;
                   bFirstC3 = baseMesh.nc-1;
                 }

                 nextUsedIsland = getNextUsedIslandFromCorner( incidentCorner );

                 bTrackedC2 = baseMesh.nc-2;
                 bTrackedC3 = baseMesh.nc-1;                 
               }
               else
               {
                 if ( DEBUG && DEBUG_MODE >= VERBOSE )
                 {
                   print ("Get a -1 as one of the base vertices incident on a Junction / Water triangle. Error!");
                 }
               }
             }
           }
           returnedVertex = getNextVertexOnIsland( v, currentVOnIsland, prevVOnIsland, prevPrevVOnIsland );
           prevPrevVOnIsland = prevVOnIsland;
           prevVOnIsland = currentVOnIsland;
           currentVOnIsland = returnedVertex;
         } while ( returnedVertex != -1 );
         if ( bTrackedC2 != -1 )
         {
           if ( m_numAdvances != -1 && m_currentAdvances == m_numAdvances-1 )
           {
             if ( DEBUG && DEBUG_MODE >= LOW )
             {
               print("Closing");
             }
           }
           addOppositeForUnusedIsland( bFirstC2, bFirstC3, bTrackedC2, bTrackedC3, nextUsedIsland );
         }
       }
       else if ( !isIslandVertex(v) ) //Is a water vertex
       {
         int initCorner = incidentTriangleType( v, ISOLATEDWATER );
         int currentCorner = initCorner;
         if ( DEBUG && DEBUG_MODE >= VERBOSE )
         {
           print("Found corner " + currentCorner);
         }
         do
         {
           int island2 = getIslandForVertexExtended( v(n(currentCorner)) );
           int island3 = getIslandForVertexExtended( v(p(currentCorner)) );
           baseMesh.addTriangle(i, island2, island3);
           currentCorner = s(currentCorner);
         } while (currentCorner != initCorner);
       }
     } //end for loop over base mesh vertices
   }
   
   /*void connectMesh()
   {
     m_numAdvances = -1;
     for (int i = 0; i < baseMesh.G.length; i++)
     {
       int v = m_vertexForIsland.get(i);
       if ( isIslandVertex( v ) && connectInBaseMesh(v) )
       {      
         int currentVOnIsland = v;
         int prevVOnIsland = v;
         int prevPrevVOnIsland = v;
         int returnedVertex = -1;
         int bTrackedC2 = -1, bTrackedC3 = -1; //Track the last added triangle corners in the base mesh for this island.
         int nextUsedIsland = -1; //Track the next used island post a junction / water triangle.
         int bFirstC2 = -1, bFirstC3 = -1; //Trac the initial triangle, so that the last can be combined post encircling the edges of the island

         ArrayList<Integer> cornerList = new ArrayList<Integer>(); //Return the cornerList og JUNCTION and ISOLATEDWATER triangles obtained by swinging around
         do
         {
           int incidentCorner = incidentTriangleType( currentVOnIsland, prevVOnIsland, JUNCTION, ISOLATEDWATER, cornerList );

           if ( incidentCorner != -1 )
           {
             for (int j = 0; j < cornerList.size(); j++)
             {
               incidentCorner = cornerList.get(j);

               int vertex2 = v( n( incidentCorner ) );
               int vertex3 = v( p( incidentCorner ) );
               int bv1 = i;
               int island2 = getIslandForVertexExtended( vertex2 );
               int island3 = getIslandForVertexExtended( vertex3 );
  
               int bv2 = island2;
               int bv3 = island3;
  
               if ( bv2 != -1 && bv3 != -1 )
               {
                 baseMesh.addTriangle(bv1, bv2, bv3);
                 if ( bTrackedC2 != -1 )
                 {
                   addOppositeForUnusedIsland( baseMesh.nc-1, baseMesh.nc-2, bTrackedC2, bTrackedC3, nextUsedIsland );
                 }
                 else
                 {
                   bFirstC2 = baseMesh.nc-2;
                   bFirstC3 = baseMesh.nc-1;
                 }

                 nextUsedIsland = getNextUsedIslandFromCorner( incidentCorner );
                 bTrackedC2 = baseMesh.nc-2;
                 bTrackedC3 = baseMesh.nc-1;
               }
               else
               {
                 if ( DEBUG && DEBUG_MODE >= LOW )
                 {
                   print ("Get a -1 as one of the base vertices incident on a Junction / Water triangle. Error!");
                 }
               }
             }
           }
           returnedVertex = getNextVertexOnIsland( v, currentVOnIsland, prevVOnIsland, prevPrevVOnIsland );
           prevPrevVOnIsland = prevVOnIsland;
           prevVOnIsland = currentVOnIsland;
           currentVOnIsland = returnedVertex;
         } while ( returnedVertex != -1 );
         if ( bTrackedC2 != -1 )
         {
           addOppositeForUnusedIsland( bFirstC2, bFirstC3, bTrackedC2, bTrackedC3, nextUsedIsland );
         }
       }
       else if ( !isIslandVertex(v) ) //Is a water vertex
       {
         int initCorner = incidentTriangleType( v, ISOLATEDWATER );
         int currentCorner = initCorner;
         if ( DEBUG && DEBUG_MODE >= VERBOSE )
         {
           print("Found corner " + currentCorner);
         }
         do
         {
           int island2 = getIslandForVertexExtended( v(n(currentCorner)) );
           int island3 = getIslandForVertexExtended( v(p(currentCorner)) );
           baseMesh.addTriangle(i, island2, island3);
           currentCorner = s(currentCorner);
         } while (currentCorner != initCorner);
       }
     } //end for loop over base mesh vertices
   }*/
   
   private int getNextUsedIslandFromCorner( int iCorner )
   {
     int swingCorner = s( iCorner );
     return getIslandForVertexExtended(v(n(swingCorner)));
   }
   
   private void addOppositeForUnusedIsland( int bc2, int bc3, int btrackedc2, int btrackedc3, int nextUsedIsland )
   {
     if ( m_numAdvances != -1 && m_currentAdvances == m_numAdvances-1 )
     {
       if ( DEBUG && DEBUG_MODE >= LOW )
       {
         print("AddOppositeForUnused " + baseMesh.v(bc2) + " " + baseMesh.v(bc3) + " " + baseMesh.v(btrackedc2) + " " + baseMesh.v(btrackedc3) + " " + nextUsedIsland);
       }
     }

     int corner1 = -1, corner2 = -1;

     if ( baseMesh.v( bc2 ) == nextUsedIsland )
     {
       corner1 = bc3;
     }
     else if ( baseMesh.v( bc3 ) == nextUsedIsland )
     {
       corner1 = bc2;
     }
     else
     {
       if ( DEBUG && DEBUG_MODE >= LOW )
       {
         print("IslandMesh::addOppositeForUnusedIsland - no same island found\n");
       }
     }
     
     if ( baseMesh.v( btrackedc2 ) == nextUsedIsland )
     {
       corner2 = btrackedc3;
     }
     else if ( baseMesh.v( btrackedc3 ) == nextUsedIsland )
     {
       corner2 = btrackedc2;
     }
     else
     {
       if ( DEBUG && DEBUG_MODE >= LOW )
       {
         print("IslandMesh::addOppositeForUnusedIsland - no same island found\n");
       }
     }

     baseMesh.O[ corner1 ] = corner2;
     baseMesh.O[ corner2 ] = corner1;
     
     baseMesh.cm[ corner1 ] = 2;
     baseMesh.cm[ corner2 ] = 2;
   }
   
   private int getNonIslandTriangleForEdge( int v1, int v2 )
   {
     int corner = cForV( v1 );
     int currentCorner = corner;
     int cornerNonEdge = -1;
     do
     {
       if ( v( n( currentCorner ) ) == v2 )
       {
         cornerNonEdge = p( currentCorner );
         break;
       }
       if ( v( p( currentCorner ) ) == v2 )
       {
         cornerNonEdge = n( currentCorner );
         break;
       }
       currentCorner = s( currentCorner );
     } while ( currentCorner != corner );
     if ( cornerNonEdge == -1 )
     {
       if (DEBUG && DEBUG_MODE >= LOW)
       {
         print ("Could not find a corner for a triangle having the given edge. Error! ");
       }
       return -1;
     }
     if ( getIslandForVertex( v( cornerNonEdge ) ) == getIslandForVertex( v1 ) )
     {
       return t( o( cornerNonEdge ) );
     }
     else
     {
       return t( cornerNonEdge );
     }
   }
   
   private int getNonIslandVertex( int nonIslandTriangle, int currentVOnIsland, int returnedV )
   {
     int initCorner = c( nonIslandTriangle );
     int currentCorner = initCorner;
     do
     {
       if ( v( currentCorner ) != currentVOnIsland && v( currentCorner ) != returnedV )
       {
         return v( currentCorner );
       }
       currentCorner = n( currentCorner );
     } while ( currentCorner != initCorner );
     return -1;
   }
   
   int triangleType( int triangle )
   {
     return tm[triangle];
   }
   
   int incidentTriangleType( int vertex, int prevVertex, int type1, int type2, ArrayList<Integer> cornerList )
   {
     cornerList.clear();
     int startCorner = findBeachEdgeCornerForVertex( vertex, prevVertex );
     
     if (startCorner == -1)
     {
       if ( DEBUG && DEBUG_MODE >= LOW )
       {
         print("IslandMesh: IncidentTriangleType got -1 as BeachEdgeCornerForVertex");
       }
     }
     int currentCorner = startCorner;
     int retVal = -1;
     do
     {
       if (( triangleType (t(currentCorner)) == type1 ) || ( triangleType (t(currentCorner)) == type2  ))
       {
         if ( retVal == -1 )
         {
           retVal = currentCorner;
         }
         cornerList.add( currentCorner );
       }
       currentCorner = s(currentCorner);
     } while ( currentCorner != startCorner );
     return retVal;
   }
   
   int incidentTriangleType( int vertex, int type )
   {
     int c = cForV( vertex );
     int currentCorner = c;
     do
     {
       currentCorner = s(currentCorner);
       if ( triangleType (t(currentCorner)) == type )
       {
         return currentCorner;
       }
     } while ( currentCorner != c );
     return -1;
   }
   
   boolean connectInBaseMesh( int vertex )
   {
     if (isIslandVertex( vertex ) )
     {
       int island = getIslandForVertex( vertex );
       int currentVertex = vertex;
       int prevVertex = vertex;
       int prevPrevVertex = vertex;
       int vertexNew = currentVertex;
       do
       {
         if ( incidentTriangleType( vertexNew, JUNCTION ) != -1 || incidentTriangleType( vertexNew, ISOLATEDWATER ) != -1 )
         {
           return true;
         }
         prevPrevVertex = prevVertex;
         prevVertex = currentVertex;
         currentVertex = vertexNew;
       } while ( (vertexNew = getNextVertexOnIsland( vertex, currentVertex, prevVertex, prevPrevVertex) ) != -1 );
     }
     else
     {
       if ( incidentTriangleType( vertex, ISOLATEDWATER ) != -1 )
       {
         return true;
       }
     }
     if ( DEBUG && DEBUG_MODE >= LOW )
     {
       print ("IslandMesh::connectInBaseMesh - the island " + getIslandForVertex( vertex ) + " is not connected in base mesh\n");
     }
     return false;
   }
   
   int getNextVertexOnIsland( int finalV, int currentV, int prevV, int prevPrevV )
   {
     int v = findOtherBeachEdgeVertexForVertex( currentV, prevV, prevPrevV );
     if ( DEBUG && DEBUG_MODE >= VERBOSE )
     {
       print ("The value of v is " + v );
     }
     if ( v == finalV && currentV != finalV ) 
     {
       if ( DEBUG && DEBUG_MODE >= VERBOSE )
       {
         print( "Completing island" + v + " " + finalV);
       }
     }
     return ( (v == finalV && currentV != finalV) ? -1 : v );
   }
   
   int findOtherBeachEdgeVertexForTriangleCorners( int c1, int c2 )
   {
     if ( hasBeachEdgeForCorners( c1, c2 ) )
     {
        return v(c2);
     }
     return -1;
   }
   
   int findBeachEdgeCornerForVertex( int currentV, int otherV )
   {
     int c = getIslandCornerForVertex( currentV );
     int currentCorner = c;
     do
     {
       int otherBeachEdgeVertex1 = findOtherBeachEdgeVertexForTriangleCorners( currentCorner, n(currentCorner) );
       int otherBeachEdgeVertex2 = findOtherBeachEdgeVertexForTriangleCorners( currentCorner, p(currentCorner) );
       if ( (otherBeachEdgeVertex1 != -1) || (otherBeachEdgeVertex2 != -1) )
       {
         if ( ( currentV == otherV ) || ( currentV != otherV && otherBeachEdgeVertex1 == otherV) )
         {
           return currentCorner;
         }
         if ( ( currentV == otherV ) || ( currentV != otherV && otherBeachEdgeVertex2 == otherV) )
         {
           return currentCorner;
         }
       }
       currentCorner = s( currentCorner );
     } while ( currentCorner != c );
     if ( DEBUG && DEBUG_MODE >= LOW )
     {
       print( "Can't find beach edge corner for currentVertex! Potential bug" );
     }
     return -1;
   }

   int findOtherBeachEdgeVertexForVertex( int currentV, int prevV, int prevPrevV )
   {
     int c = getIslandCornerForVertex( currentV );
     int currentCorner = c;
     do
     {
       int otherBeachEdgeVertex1 = findOtherBeachEdgeVertexForTriangleCorners( currentCorner, n(currentCorner) );
       int otherBeachEdgeVertex2 = findOtherBeachEdgeVertexForTriangleCorners( currentCorner, p(currentCorner) );
       if ( (otherBeachEdgeVertex1 != -1) || (otherBeachEdgeVertex2 != -1) )
       {
         if ( ( currentV == prevV ) || ( currentV != prevV && otherBeachEdgeVertex1 != prevV && otherBeachEdgeVertex1 != prevPrevV && otherBeachEdgeVertex1 != -1) )
         {
           //cm[currentCorner] = 1;
           //cm[n(currentCorner)] = 1;
           return otherBeachEdgeVertex1;
         }
         if ( ( currentV == prevV ) || ( currentV != prevV && otherBeachEdgeVertex2 != prevV && otherBeachEdgeVertex2 != prevPrevV && otherBeachEdgeVertex2 != -1) )
         {
           //cm[currentCorner] = 1;
           //cm[p(currentCorner)] = 1;
           return otherBeachEdgeVertex2;
         }
       }
       currentCorner = s( currentCorner );
     } while ( currentCorner != c );
     if ( DEBUG && DEBUG_MODE >= LOW )
     {
       print( "Can't find beach edge vertex for currentVertex! Potential bug" );
     }
     return -1;
   }
}
// CORNER TABLE FOR TRIANGLE MESHES by Jarek Rosignac
// Last edited October, 2011
// example meshesshowShrunkOffsetT
String [] fn= {"HeartReallyReduced.vts","horse.vts","bunny.vts","torus.vts","flat.vts","tet.vts","fandisk.vts","squirrel.vts","venus.vts","mesh.vts","hole.vts","gs_dimples_bumps.vts"};
int fni=0; int fniMax=fn.length; // file names for loading meshes
Boolean [] vis = new Boolean [10]; 
Boolean onTriangles=true, onEdges=true; // projection control

class DrawingState
{
  public boolean m_fShowEdges;
  public boolean m_fShowVertices;
  public boolean m_fShowCorners;
  public boolean m_fShowNormals;
  public boolean m_fShowTriangles;
  public boolean m_fTranslucent;
  public boolean m_fSilhoutte;
  public boolean m_fPickingBack;
  public float m_shrunk;
  
  public DrawingState()
  {
    m_fShowEdges = true;
    m_fShowVertices = false;
    m_fShowCorners = false;
    m_fShowNormals = false;
    m_fShowTriangles = true;
    m_fTranslucent = false;
    m_fSilhoutte = false;
    m_fPickingBack = false;
    m_shrunk = 0;
  }
};

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
 
 // primary tables
 int[] V = new int [3*maxnt];               // V table (triangle/vertex indices)
 int[] O = new int [3*maxnt];               // O table (opposite corner indices)
 int[] CForV = new int [maxnv];                  // For querying for any corner for a vertex
 pt[] G = new pt [maxnv];                   // geometry table (vertices)
 pt[] baseG = new pt [maxnv];               // to store the locations of the vertices in their contracted form

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
 int rings=2;                               // number of rings for colorcoding
 Viewport m_viewport;                       // the viewport the mesh is registered to

 // box
 pt Cbox = new pt(width/2,height/2,0);                   // mini-max box center
 float rbox=1000;                                        // half-diagonal of enclosing box

 // rendering modes
 Boolean flatShading=true, showEdges=false;  // showEdges shoes edges as gaps. Smooth shading works only when !showEdge
 DrawingState m_drawingState = new DrawingState();
 protected MeshUserInputHandler m_userInputHandler;

 //wrapper class providing utilities to meshes
 MeshUtils m_utils = new MeshUtils(this);

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
 Mesh() 
 {
     m_userInputHandler = new MeshUserInputHandler(this);
 }

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
   }
 
 int addVertex(pt P) { G[nv] = new pt(); G[nv].set(P); nv++; return nv-1;};
 int addVertex(float x, float y, float z) { G[nv] = new pt(); G[nv].x=x; G[nv].y=y; G[nv].z=z; nv++; return nv-1;};
  
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
  boolean hasValidR(int c) { return r(c) != p(c); } //true for meshes with border if not returning previous (has actual R)
  boolean hasValidL(int c) { return l(c) != n(c); } //true for meshes with borher if not returning next (has actual L)
  
  int cForV(int v) { 
    if (CForV[v] == -1) 
    {
      if ( DEBUG && DEBUG_MODE >= LOW )
      {
        print("Fatal error! The corner for the vertex is -1"); 
      }
    } 
    return CForV[v]; 
  }

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
  void showCorners()
  {
    noStroke();
    for (int i = 0; i < 3*nt; i++)
    {
      if (cm[i] == 1)
      {
        fill(green);
        showCorner(i, 5);
      }
      else if (cm[i] == 2)
      {
        fill(black);
        showCorner(i, 5);
      }
      else
      {
      //fill(orange);
      //showCorner(i, 3);
      }
    }
  }

  void showCorner(int c, float r) {if (m_drawingState.m_fShowCorners) {show(cg(c),r);} };   // renders corner c as small ball
  
  void showcc(){noStroke(); fill(blue); showCorner(sc,3); /* fill(green); showCorner(pc,5); */ fill(dred); showCorner(cc,3); } // displays corner markers
  
  void showLabels() { // displays IDs of corners, vertices, and triangles
   fill(black); 
   for (int i=0; i<nv; i++) {show(G[i],"v"+str(i),V(10,Nv[i])); }; 
   for (int i=0; i<nc; i++) {show(corner(i),"c"+str(i),V(10,Nt[i])); }; 
   for (int i=0; i<nt; i++) {show(triCenter(i),"t"+str(i),V(10,Nt[i])); }; 
   noFill();
   }

// ============================================= DISPLAY VERTICES =======================================
  void showVertices() {
    noStroke(); noSmooth(); 
    for (int v=0; v<nv; v++)  {
      //if (vm[v]==0) fill(brown,150);
      if (vm[v]==1) fill(red,150);
       show(G[v],r);  
      if (vm[v]==2)
      {
        fill(green,150);
        show(G[v],5);  
      }
      if (vm[v]==3)
      {
        fill(blue,150);
        show(G[v],5);  
      }
      if (vm[v]==5)
      {
        fill(red,150);
        show(G[v],5);  
      }
    }
    noFill();
    }
    
    void showVertices(int col, int radius) 
    {
      noStroke(); noSmooth(); 
      for (int v=0; v<nv; v++)
      {
         fill(col);
         show(G[v],radius);  
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
  Boolean frontFacing(int t) {return !cw(m_viewport.getE(),g(3*t),g(3*t+1),g(3*t+2)); } 
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
       if(tm[t]==4) fill(magenta,opacity); 
       if(tm[t]==5) fill(green,opacity); 
       if(tm[t]==6) fill(blue,opacity); 
       if(tm[t]==7) fill(#FAAFBA,opacity); 
       if(tm[t]==8) fill(blue,opacity); 
       if(tm[t]==9) fill(yellow,opacity); 
       if(vis[tm[t]]) {if(m_drawingState.m_shrunk != 0) showShrunkT(t, m_drawingState.m_shrunk); else shade(t);}
       }
     }
  
  void showBackTriangles() {for(int t=0; t<nt; t++) if(!frontFacing(t)) shade(t);};  
  void showAllTriangles() {for(int t=0; t<nt; t++) if(showEdges) showShrunkT(t,1); else shade(t);};  
  void showMarkedTriangles() {for(int t=0; t<nt; t++) if(visible[t]&&Mt[t]!=0) {fill(ramp(Mt[t],rings)); showShrunkOffsetT(t,1,1); }};  
  
  // ********************************************************* DRAW *****************************************************
  void draw()
  {
    if(m_drawingState.m_fShowEdges)
    {
      stroke(orange); 
    } 
    else
    { 
      noStroke();
    }
    if(m_drawingState.m_fPickingBack)
    {
        noStroke(); 
        if(m_drawingState.m_fTranslucent)  
        {
          showTriangles(false,100,m_drawingState.m_shrunk); 
        }
        else 
        {
          showBackTriangles();
        }
    }
    else if(m_drawingState.m_fTranslucent)
    {
      if (m_drawingState.m_fShowTriangles)
      {
        fill(grey,80); noStroke(); 
        showBackTriangles();  
        showTriangles(true,150,m_drawingState.m_shrunk);
      } 
    }
    else if (m_drawingState.m_fShowTriangles)
    {
      showTriangles(true,255,m_drawingState.m_shrunk);
    }
    if(m_drawingState.m_fShowVertices)
    {
      showVertices();
    }
    if(m_drawingState.m_fShowCorners)
    {
      showCorners();
    }
    if(m_drawingState.m_fShowNormals)
    {
      showNormals();
    }
    if(m_drawingState.m_fShowEdges)
    {
     stroke(red); showBorder();  // show border edges
    }
  }
  
  void drawPostPicking()
  {       
     // -------------------------------------------------------- display picked points and triangles ----------------------------------   
    fill(cyan); showSOT(); // shoes triangle t(cc) shrunken
    showcc();  // display corner markers: seed sc (green),  current cc (red)
    
    // -------------------------------------------------------- display FRONT if we were picking on the back ---------------------------------- 
    if(getDrawingState().m_fPickingBack) 
    {
      if(getDrawingState().m_fTranslucent) {fill(cyan,150); if(getDrawingState().m_fShowEdges) stroke(orange); else noStroke(); showTriangles(true,100,m_drawingState.m_shrunk);} 
      else {fill(cyan); if(getDrawingState().m_fShowEdges) stroke(orange); else noStroke(); showTriangles(true,255,m_drawingState.m_shrunk);}
    }
       
    // -------------------------------------------------------- Disable z-buffer to display occluded silhouettes and other things ---------------------------------- 
    hint(DISABLE_DEPTH_TEST);  // show on top
    if(getDrawingState().m_fSilhoutte) {stroke(dbrown); drawSilhouettes(); }  // display silhouettes
  }
  
  DrawingState getDrawingState()
  {
    return m_drawingState;
  }

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
   
   //Interaction of mesh class with outside objects. TODO msati3: Better ways of handling this?
   void setViewport(Viewport viewport) {
     m_viewport = viewport;
   }
   
   void onKeyPressed() {
     m_userInputHandler.onKeyPress();
   }
   
   void onMousePressed() {
     m_userInputHandler.onMousePressed();
   }
   
   void interactSelectedMesh() {
     m_userInputHandler.interactSelectedMesh();
   }
} // ==== END OF MESH CLASS
  
vec labelD=new vec(-4,+4, 12);           // offset vector for drawing labels  

float distPE (pt P, pt A, pt B) {return n(N(V(A,B),V(A,P)))/d(A,B);} // distance from P to edge(A,B)
float distPtPlane (pt P, pt A, pt B, pt C) {vec N = U(N(V(A,B),V(A,C))); return abs(d(V(A,P),N));} // distance from P to plane(A,B,C)
Boolean projPonE (pt P, pt A, pt B) {return d(V(A,B),V(A,P))>0 && d(V(B,A),V(B,P))>0;} // P projects onto the interior of edge(A,B)
Boolean projPonT (pt P, pt A, pt B, pt C) {vec N = U(N(V(A,B),V(A,C))); return m(N,V(A,B),V(A,P))>0 && m(N,V(B,C),V(B,P))>0 && m(N,V(C,A),V(C,P))>0 ;} // P projects onto the interior of edge(A,B)
pt CPonE (pt P, pt A, pt B) {return P(A,d(V(A,B),V(A,P))/d(V(A,B),V(A,B)),V(A,B));}
pt CPonT (pt P, pt A, pt B, pt C) {vec N = U(N(V(A,B),V(A,C))); return P(P,-d(V(A,P),N),N);}
class CuboidConstructor
{
  private int m_numRows;
  private int m_numCols;
  private float m_thickness;
  private float m_triangleSize;

  private IslandMesh m_mesh;
  
  public CuboidConstructor( int rows, int cols, float thickness, float triangleSize )
  {
    m_numRows = rows;
    m_numCols = cols;
    m_thickness = thickness;
    m_triangleSize = triangleSize;

    m_mesh = new IslandMesh();
    m_mesh.declareVectors();  
  }
  
  public void constructMesh()
  {
    for (int k = 0; k < 2; k++)
    {
      float z = getZForHeight( k );
      for (int i = 0; i < m_numRows; i++)
      {
        float y = getYForRow( i );
        for (int j = 0; j < m_numCols; j++)
        {
          float x = getXForCol( j );
          if ( DEBUG && DEBUG_MODE >= VERBOSE )
          {
            print("CuboidConstructor : Adding vertex " + x + " " + y + " " + z );
          }
          m_mesh.addVertex( new pt(x, y , z) );
        }
      }
    }
    
    //Triangulate the flat faces.
    for (int k = 0; k < 2; k++)
    {
      int initialOffset = k * ( m_numRows * m_numCols );
      for (int i = 0; i < m_numRows - 1; i++)
      {
        for (int j = 0; j < m_numCols - 1; j++)
        {
          if ( k == 0 )
          {
            m_mesh.addTriangle( initialOffset + m_numRows * i + j, initialOffset + m_numRows * i + j + 1, initialOffset + m_numRows * ( i + 1 ) + j );
            m_mesh.addTriangle( initialOffset + m_numRows * ( i + 1 ) + j + 1, initialOffset + m_numRows * ( i + 1 ) + j, initialOffset + m_numRows * i + j + 1 );
          }
          else
          {
            m_mesh.addTriangle( initialOffset + m_numRows * i + j + 1, initialOffset + m_numRows * i + j, initialOffset + m_numRows * ( i + 1 ) + j );
            m_mesh.addTriangle( initialOffset + m_numRows * ( i + 1 ) + j, initialOffset + m_numRows * ( i + 1 ) + j + 1, initialOffset + m_numRows * i + j + 1 );
          }
        }
      }
    }
    
    //Triangulate the sides.
    //Left and right
    for (int i = 0; i < m_numRows - 1; i++)
    {
      int initialOffsetBack = ( m_numRows * m_numCols );
      m_mesh.addTriangle( initialOffsetBack + m_numCols * i, m_numCols * i,  m_numCols * (i + 1) );
      m_mesh.addTriangle( m_numCols * (i + 1), initialOffsetBack + m_numCols * (i + 1), initialOffsetBack + m_numCols * i );
      
      m_mesh.addTriangle( m_numCols * i + m_numCols - 1, initialOffsetBack + m_numCols * i + m_numCols - 1, m_numCols * (i + 1) + m_numCols - 1 );
      m_mesh.addTriangle( initialOffsetBack + m_numCols * (i + 1) + m_numCols - 1, m_numCols * (i + 1) + m_numCols - 1, initialOffsetBack + m_numCols * i + m_numCols - 1 );
    }
    
    //Top and bottom
    for (int j = 0; j < m_numCols - 1; j++)
    {
      int initialOffsetBack = ( m_numRows * m_numCols );
      m_mesh.addTriangle( j, initialOffsetBack + j, initialOffsetBack + j + 1 );
      m_mesh.addTriangle( initialOffsetBack + j + 1, j + 1, j );
      
      int initialOffsetRow = ( (m_numRows - 1) * m_numCols );
      m_mesh.addTriangle( initialOffsetRow + initialOffsetBack + j, initialOffsetRow + j, initialOffsetRow + initialOffsetBack + j + 1 );
      m_mesh.addTriangle( initialOffsetRow + j + 1, initialOffsetRow + initialOffsetBack + j + 1, initialOffsetRow + j );
    }
       
    m_mesh.resetMarkers(); // resets vertex and tirangle markers
    m_mesh.updateON();
    
    //Flip around some edges
    /*for (int i = 1; i < m_numRows-2; i++)
    {
      for (int j = 1; j < m_numCols-2; j++)
      {
        int triangle1 = 2 * i * (m_numCols - 1) + 2 * j;
        int triangle2 = 2 * (m_numRows - 1) * (m_numCols - 1) + triangle1 + 1; 
        if ( random(5) <= 3 )
        {
          m_mesh.flip(triangle1*3);
        }
        if ( random(5) <= 3 )
        {
          m_mesh.flip(triangle2*3);
        }
      }
    }*/

    m_mesh.computeBox();
  }
  
  private float getXForCol( int col ) { return (-m_triangleSize * m_numCols / 2) + col * m_triangleSize; }
  private float getYForRow( int row ) { return (-m_triangleSize * m_numRows / 2) + row * m_triangleSize; }
  private float getZForHeight( int height ) {return - height * m_thickness; }
  
  public IslandMesh getMesh()
  {
    return m_mesh;
  }
};
//Allows for selecting a particular mesh being displayed and performing operations on it
class MeshInteractor
{
  private ArrayList<Mesh> m_meshes;
  private int m_selectedMesh;
  
  MeshInteractor()
  {
    m_meshes = new ArrayList<Mesh>();
    m_selectedMesh = -1;
  } 
  
  int addMesh(Mesh m)
  {
    m_meshes.add(m);
    if ( m_selectedMesh == -1 )
    {
      m_selectedMesh = 0;
    }
    return m_meshes.size();
  }
  
  void removeMesh(Mesh m)
  {
    boolean fRemoved = m_meshes.remove(m);
    if ( !fRemoved )
    {
      if (DEBUG && DEBUG_MODE >= LOW)
      {
        print("MeshInteractor::removeMesh - can't find mesh to be unregistered!");
      }
    }
    else if (m_meshes.size() == 0)
    {
      m_selectedMesh = -1;
    }
  }

  void selectMesh(int meshIndex)
  {
    if (meshIndex >= m_meshes.size() && meshIndex >= 0)
    {
      if (DEBUG && DEBUG_MODE >= LOW)
      {
        print ("MeshInteractor::selectMesh - Error trying to select incorrect mesh. Current number of meshes is " + m_meshes.size()+"\n");
      }
      if ( m_meshes.size() > 0 ) 
      {
        selectMesh(m_meshes.size()-1); 
      }
      else
      {
        if (DEBUG && DEBUG_MODE >= LOW)
        {
          print ("MeshInteractor::selectMesh - Current meshlist is empty. Returning without selecting a mesh");
        }
        return;
      }
    }
    m_selectedMesh = meshIndex;
  }

  int getSelectedMeshIndex()
  {
    return m_selectedMesh;
  }

  Mesh getSelectedMesh()
  {
    if (m_selectedMesh == -1)
    {
      return null;
    }
    return m_meshes.get(m_selectedMesh);
  } 
  
  void drawRegisteredMeshes()
  {
    for (int i = 0; i < m_meshes.size(); i++)
    {
      m_meshes.get(i).draw();
    }
  }
}
class MeshUtils
{
 private Mesh m;
 
 MeshUtils(Mesh _m) { m = _m; }
 
 public float computeArea(int triangle)
 {
   pt A = m.G[m.v(m.c(triangle))];
   pt B = m.G[m.v(m.n(m.c(triangle)))];
   pt C = m.G[m.v(m.p(m.c(triangle)))];
     
   vec AB = V(A, B);
   vec AC = V(A, C);
   vec cross = N(AB, AC);
   float area = 0.5 * cross.norm();
   return abs(area);
 }
 
    
 public pt baryCenter(int triangle)
 {
   int corner = m.c(triangle);
   pt baryCenter = new pt();
   baryCenter.set(m.G[m.v(m.c(triangle))]);
   baryCenter.add(m.G[m.v(m.n(m.c(triangle)))]);
   baryCenter.add(m.G[m.v(m.p(m.c(triangle)))]);
   baryCenter.div(3);
   if (DEBUG && DEBUG_MODE >= VERBOSE)
   {
     print(baryCenter.x + " " + baryCenter.y + " " + baryCenter.z);
   }
   return baryCenter;
 }
}

class MeshUserInputHandler
{
  private Mesh m_mesh;
  
  MeshUserInputHandler(Mesh m)
  {
    m_mesh = m;
  }
  
  public void onMousePressed()
  {
     pressed=true;
     if (keyPressed&&key=='h') {m_mesh.hide(); }  // hide triangle
  }
  
  public void onKeyPress()
  {
    // corner ops for demos
    // CORNER OPERATORS FOR TEACHING AND DEBUGGING
    if(key=='N') m_mesh.next();      
    if(key=='P') m_mesh.previous();
    if(key=='O') m_mesh.back();
    if(key=='L') m_mesh.left();
    if(key=='R') m_mesh.right();   
    if(key=='S') m_mesh.swing();
    if(key=='U') m_mesh.unswing();
    
    // mesh edits, smoothing, refinement
    if(key=='v') m_mesh.flip(); // clip edge opposite to M.cc
    if(key=='F') {m_mesh.smoothen(); m_mesh.normals();}
    if(key=='Y') {m_mesh.refine(); m_mesh.makeAllVisible();}
    if(key=='d') {m_mesh.clean();}
    if(key=='o') m_mesh.offset();

    if(key=='u') {m_mesh.resetMarkers(); m_mesh.makeAllVisible(); } // undo deletions
    if(key=='B') showBack=!showBack;
    if(key=='#') m_mesh.volume(); 
    if(key=='_') m_mesh.surface(); 

    //Drawing options
    if (key == 'Q') { m_mesh.getDrawingState().m_fShowVertices = !m_mesh.getDrawingState().m_fShowVertices; }
    if (key == 'q') { m_mesh.getDrawingState().m_fShowCorners = !m_mesh.getDrawingState().m_fShowCorners; }
    if (key == 'A') { m_mesh.getDrawingState().m_fShowNormals = !m_mesh.getDrawingState().m_fShowNormals; }
    if (key == 'a') { m_mesh.getDrawingState().m_fShowTriangles = !m_mesh.getDrawingState().m_fShowTriangles; }
    if (key == 'E') { m_mesh.getDrawingState().m_fTranslucent = !m_mesh.getDrawingState().m_fTranslucent; }
    if (key == 'e') { m_mesh.getDrawingState().m_fSilhoutte = !m_mesh.getDrawingState().m_fSilhoutte; }
    if (key == 'b') { m_mesh.getDrawingState().m_fPickingBack=true; m_mesh.getDrawingState().m_fTranslucent = true; println("picking on the back");}
    if (key == 'f') { m_mesh.getDrawingState().m_fPickingBack=false; m_mesh.getDrawingState().m_fTranslucent = false; println("picking on the front");}
    if (key == 'g') { m_mesh.flatShading=!m_mesh.flatShading; }
    if (key == '-') { m_mesh.showEdges=!m_mesh.showEdges; if (m_mesh.showEdges) m_mesh.getDrawingState().m_shrunk=1; else m_mesh.getDrawingState().m_shrunk=0; }

  }
  
  public void interactSelectedMesh()
  {
    // -------------------------------------------------------- graphic picking on surface ----------------------------------   
    if (keyPressed&&key=='h') { m_mesh.pickc(Pick()); }// sets c to closest corner in M 
    if(pressed) {
       if (keyPressed&&key=='s') m_mesh.picks(Pick()); // sets M.sc to the closest corner in M from the pick point
       if (keyPressed&&key=='c') m_mesh.pickc(Pick()); // sets M.cc to the closest corner in M from the pick point
       if (keyPressed&&(key=='w'||key=='x'||key=='X')) m_mesh.pickcOfClosestVertex(Pick()); 
    }
    pressed=false;
  }
}

class BaseMeshUserInputHandler extends MeshUserInputHandler
{
  private BaseMesh m_mesh;
  private int m_islandForExpansion;
  
  BaseMeshUserInputHandler( BaseMesh m )
  {
    super( m );
    m_mesh = m;
    m_islandForExpansion = -1;
  }
   
  public void interactSelectedMesh()
  {
    if(pressed) {
       if (keyPressed&&key=='m') m_mesh.pickc(Pick()); // sets M.sc to the closest corner in M from the pick point
       m_mesh.onExpandIsland();
    }
    super.interactSelectedMesh();
  }
}

class IslandMeshUserInputHandler extends MeshUserInputHandler
{
  private IslandMesh m_mesh;
  private boolean m_fSelectIsland;
  
  IslandMeshUserInputHandler( IslandMesh m )
  {
    super( m );
    m_mesh = m;
    m_fSelectIsland = false;
  }
  
  public void onKeyPress()
  {
    super.onKeyPress();
    if (key==':')
    {
      m_fSelectIsland = true;
    }
    else if (m_fSelectIsland)
    {
      if (m_fSelectIsland && (key - '0' >= 0) && (key - '0' < 10))
      {
        m_mesh.selectIsland(key-'0');
      }
      else
      {
        m_mesh.selectIsland(-1);
      }
      m_fSelectIsland = false;
    }
    else
    {
      if (key=='1') {g_stepWiseRingExpander.setStepMode(false); m_mesh.showEdges = true; R = new RingExpander(m_mesh, (int) random(m_mesh.nt * 3)); m_mesh.setResult(R.completeRingExpanderRecursive()); m_mesh.showRingExpanderCorners(); }
      if (key=='2') {g_stepWiseRingExpander.setStepMode(false); m_mesh.formIslands(-1);}
      if (key=='3') {m_mesh.colorTriangles(); }
      if (key=='4') {m_mesh.toggleMorphingState(); }
      if (key=='6') {EgdeBreakerCompress e = new EgdeBreakerCompress(m_mesh); e.initCompression();}
      if (key=='7')
      {
        g_stepWiseRingExpander.setStepMode(false);
        StatsCollector s = new StatsCollector(m_mesh); 
        s.collectStats(10, 30);
        s.collectStats(10, 62);
        s.done();
      }
      
      //Debugging modes
      if (key=='5') {g_stepWiseRingExpander.setStepMode(true); m_mesh.showEdges = true; if (R == null) { R = new RingExpander(m_mesh, (int)random(m_mesh.nt * 3)); } R.ringExpanderStepRecursive();} //Press 4 to trigger step by step ring expander
    }
  }
}
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
  private IslandMesh m_mesh;
  private int m_seed;
  private int m_numTrianglesToVisit;
  private int m_numTrianglesVisited;
  private RingExpanderResult m_ringExpanderResult;
  private boolean m_fColoringRingExpander;
  private int[] m_parentTriangles;

  boolean[] m_vertexVisited;
  boolean[] m_triangleVisited;

  Stack< State > m_recursionStack;

  public RingExpander(IslandMesh m, int seed)
  {
    m_mesh = m;
    m_mesh.resetMarkers();
    m_seed = 0;

    if (seed != -1)
    {
      seed = 679;
      print("Seed for ringExpander " + seed);
      m_seed = seed;
    }
    m_mesh.cc = m_seed;

    m_numTrianglesToVisit = -1;
    m_numTrianglesVisited = 0;
    m_parentTriangles = new int[m_mesh.nt * 3];

    m_ringExpanderResult = null;

    for (int i = 0; i < m_mesh.nt * 3; i++)
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
        m_mesh.tm[i] = ISLAND;
      }
      else
      {
        m_mesh.tm[i] = CHANNEL;
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
    }
    while (seed != m.o (init));
    colorTriangles(vertexVisited, triangleVisited);

    m_numTrianglesToVisit = -1;
  }

  public void visitRecursively()
  {
    while ( ( (m_numTrianglesToVisit == -1) || (m_numTrianglesVisited < m_numTrianglesToVisit)) &&(!m_recursionStack.empty()))
    {
      State currentState = m_recursionStack.pop();
      int corner = currentState.corner();
      int parentTriangle = currentState.parentTriangle();

      if (!m_vertexVisited[m_mesh.v(corner)])
      {
        m_vertexVisited[m_mesh.v(corner)] = true;
        m_triangleVisited[m_mesh.t(corner)] = true;
        m_parentTriangles[corner] = parentTriangle;
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
    IslandMesh m = m_mesh;
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

class SimplificationController
{
 private ViewportManager m_viewportManager;
 private IslandMesh m_islandMesh;
 private BaseMesh m_baseMesh;
 
 SimplificationController()
 {
  m_viewportManager = new ViewportManager();
  m_viewportManager.addViewport( new Viewport( 0, 0, width/2, height ) );
  m_viewportManager.addViewport( new Viewport( width/2, 0, width/2, height ) );

  m_islandMesh = new IslandMesh(); 
  m_baseMesh = null;
  m_islandMesh.declareVectors();  
  m_islandMesh.loadMeshVTS("data/horse.vts");
  m_islandMesh.updateON(); // computes O table and normals
  m_islandMesh.resetMarkers(); // resets vertex and tirangle markers
  m_islandMesh.computeBox();
  m_viewportManager.registerMeshToViewport( m_islandMesh, 0 );
  for(int i=0; i<10; i++) vis[i]=true; // to show all types of triangles
 }
 
 ViewportManager viewportManager()
 {
   return m_viewportManager;
 }
 
 void onKeyPressed()
 {
   if (key=='p')  //Create base mesh and register it to other viewport archival
   {
     if (m_baseMesh != null)
     {
       m_viewportManager.unregisterMeshFromViewport( m_baseMesh, 1 );
     }
     m_baseMesh = m_islandMesh.populateBaseG(); 
     m_islandMesh.connectMesh(); 
     m_baseMesh.computeBox(); 
     m_viewportManager.registerMeshToViewport( m_baseMesh, 1 ); 
   }
   else if(key=='L') {IslandMesh m = new IslandMesh();
                 m.declareVectors();
                 m.loadMeshOBJ(); // M.loadMesh(); 
                 m.updateON();   m.resetMarkers();
                 m.computeBox();
                 for(int i=0; i<10; i++) vis[i]=true;
                 changeIslandMesh(m);
                }
   else if(key=='M') {IslandMesh m = new IslandMesh();
                 m.declareVectors();  
                 m.loadMeshVTS(); 
                 m.updateON();   m.resetMarkers();
                 m.computeBox();
                 for(int i=0; i<10; i++) vis[i]=true;
                 changeIslandMesh(m);
                 }
   //Debugging utilities
   else if (key=='`') 
   {
     CuboidConstructor c = new CuboidConstructor(8, 8, 20, 30);
     c.constructMesh();
     changeIslandMesh(c.getMesh());
   }
   else if (key=='i')
   {
     if (m_baseMesh != null)
     {
       m_viewportManager.unregisterMeshFromViewport( m_baseMesh, 1 );
     }
     m_islandMesh.onBeforeAdvanceOnIslandEdge();
     m_baseMesh = m_islandMesh.populateBaseG(); 
     m_baseMesh.Cbox = m_islandMesh.Cbox;
     m_baseMesh.rbox = m_islandMesh.rbox;
     m_viewportManager.registerMeshToViewport( m_baseMesh, 1 ); 
   }
   else if (key=='I') //Connect base mesh step by step
   {
     if (m_baseMesh != null)
     {
       m_islandMesh.connectMeshStepByStep();
     }
   }
   else
   {
      viewportManager().onKeyPressed(); 
   }
 }
 
 private void changeIslandMesh(IslandMesh m)
 {
   m_viewportManager.unregisterMeshFromViewport( m_islandMesh, 0 );
   if ( m_baseMesh != null )
   {
     m_viewportManager.unregisterMeshFromViewport( m_baseMesh, 1 );
   }
   m_islandMesh = m;
   m_viewportManager.registerMeshToViewport( m_islandMesh, 0 );
 }
}
class Viewport
{
  private int m_x;
  private int m_y;
  private int m_width;
  private int m_height;
  private boolean m_fSelected;
  MeshInteractor m_meshInteractor;

  // ****************************** VIEWING PARAMETERS *******************************************************
  private pt F = P(0,0,0); pt T = P(); pt E = P(0,0,1000); vec U=V(0,1,0);  // focus  set with mouse when pressing 't', eye, and up vector
  private pt Q=P(0,0,0); vec I=V(1,0,0); vec J=V(0,1,0); vec K=V(0,0,1); // picked surface point Q and screen aligned vectors {I,J,K} set when picked
  
  Viewport( int x, int y, int width, int height )
  {
    m_x = x;
    m_y = y;
    m_width = width;
    m_height = height;
    m_meshInteractor = new MeshInteractor();
    initView();
  }
  
  void initView()
  {
    Q=P(0,0,0); I=V(1,0,0); J=V(0,1,0); K=V(0,0,1); F = P(0,0,0); E = P(0,0,1000); U=V(0,1,0);  // declares the local frames
  }
  
  //Interactions with viewport manager
  void onSelected()
  {
    m_fSelected = true;
  }
  
  void onDeselected()
  {
    m_fSelected = false;
  }
    
  void registerMesh(Mesh m)
  {
    if ( m_meshInteractor.addMesh(m) == 1 )
    {
      initView();
      F.set(m.Cbox);
    }
    m.setViewport(this);
  }
  
  void unregisterMesh(Mesh m)
  {
    m_meshInteractor.removeMesh(m);
    m.setViewport(null);
  }
    
  void onMousePressed()
  {
    Mesh selectedMesh = m_meshInteractor.getSelectedMesh();
    if (selectedMesh != null)
    {
      selectedMesh.onMousePressed();
    }
  }
  
  void onMouseDragged()
  {
    Mesh selectedMesh = m_meshInteractor.getSelectedMesh();
    if (selectedMesh != null)
    {
      if(keyPressed&&key=='w') {selectedMesh.add(float(mouseX-pmouseX),I).add(-float(mouseY-pmouseY),J); } // move selected vertex in screen plane
      if(keyPressed&&key=='x') {selectedMesh.add(float(mouseX-pmouseX),I).add(float(mouseY-pmouseY),K);}  // move selected vertex in X/Z screen plane
      if(keyPressed&&key=='W') {selectedMesh.addROI(float(mouseX-pmouseX),I).addROI(-float(mouseY-pmouseY),J); } // move selected vertex in screen plane
      if(keyPressed&&key=='X') {selectedMesh.addROI(float(mouseX-pmouseX),I).addROI(float(mouseY-pmouseY),K);}  // move selected vertex in X/Z screen plane 

      //Rotate viewport's view
      if(!keyPressed) {E=R(E,  PI*float(mouseX-pmouseX)/width,I,K,F); E=R(E,-PI*float(mouseY-pmouseY)/width,J,K,F); } // rotate E around F 
      if(keyPressed&&key=='Z') {E=P(E,-float(mouseY-pmouseY),K); }  //   Moves E forward/backward
      if(keyPressed&&key=='z') {E=P(E,-float(mouseY-pmouseY),K);U=R(U, -PI*float(mouseX-pmouseX)/width,I,J); }//   Moves E forward/backward and rotatees around (F,Y)

    }
    else
    {
      if (DEBUG && DEBUG_MODE >= LOW)
      {
        print("Viewport::onMouseDragged - no interactions possible, as no mesh is currently selected");
      }
    }
  }
  
  void onKeyReleased()
  {
    if(key=='t') F.set(T);  // set camera focus
     /*if(key=='c') println("edge length = "+d(M.gp(),M.gn()));  
     U.set(M(J)); // reset camera up vector*/
  }
  
  void onKeyPressed()
  {
    Mesh M = m_meshInteractor.getSelectedMesh();
    if ( M == null )
    {
      if (DEBUG && DEBUG_MODE >= LOW)
      {
        print("Viewport::onInteractSelectedMesh - no interactions possible, as no mesh is currently selected");
      }
      return;
    }  
    // camera focus set 
    if(key=='^') F.set(M.g()); // to picked corner
    if(key==']') F.set(M.Cbox);  // center of minimax box
    if(key==';') {initView(); F.set(M.Cbox); } // reset the view
    

    //archival
    if(key=='K') {M.saveMeshVTS();}
    if(key=='L') {Mesh m = new Mesh();
                 m.loadMeshOBJ(); // M.loadMesh(); 
                 m.updateON();   m.resetMarkers();
                 m.computeBox();
                 for(int i=0; i<10; i++) vis[i]=true;
                 registerMesh(m);
                }
    if(key=='M') {Mesh m = new Mesh();
                 m.loadMeshVTS(); 
                 m.updateON();   m.resetMarkers();
                 m.computeBox();
                 for(int i=0; i<10; i++) vis[i]=true;
                 registerMesh(m);
                 }
    if(key=='?') {showHelpText=!showHelpText;} 
    //if(key=='V') {sE.set(E); sF.set(F); sU.set(U);}
    //if(key=='v') {E.set(sE); F.set(sF); U.set(sU);}
    //if(key=='m') {m=(m+1)%MM.length; M=MM[m];};  
    M.onKeyPressed();
  }

  //************Drawing functions*****************  
  void draw(boolean fShowFullScreen)
  {
    if (fShowFullScreen)
    {
      gl.glViewport( 0, 0, width, height );
    }
    else
    {
      gl.glViewport( m_x, m_y, m_width, m_height );
    }
    
    drawDecorations();

    camera(E.x, E.y, E.z, F.x, F.y, F.z, U.x, U.y, U.z); // defines the view : eye, ctr, up
    vec Li=U(A(V(E,F),0.1*d(E,F),J));   // vec Li=U(A(V(E,F),-d(E,F),J)); 
    directionalLight(255,255,255,Li.x,Li.y,Li.z); // direction of light: behind and above the viewer
    specular(255,255,0); shininess(5);  
    SetFrame(Q,I,J,K);
    m_meshInteractor.drawRegisteredMeshes();

    if (m_fSelected)
    {
      interactSelectedMesh();
    }
  }
  
  private void drawDecorations()
  {
    camera(); // 2D view to write help text
    if (m_fSelected)
    {
      noFill();
      strokeWeight(2);
      stroke(blue);
      rect(0, 0, width, height);

      Mesh selectedMesh = m_meshInteractor.getSelectedMesh();
      if (selectedMesh != null)
      {
        stroke(green);
        fill(green); scribe("Surface = "+nf(selectedMesh.surf,1,1)+", Volume = "+nf(selectedMesh.vol,1,0),0); 
        scribeHeaderRight("Mesh "+str(m_meshInteractor.getSelectedMeshIndex()));
      }
    }
  
    hint(ENABLE_DEPTH_TEST); // show silouettes
  }
 
  private void interactSelectedMesh()
  {
    Mesh selectedMesh = m_meshInteractor.getSelectedMesh();
    if ( selectedMesh == null )
    {
      if (DEBUG && DEBUG_MODE >= LOW)
      {
        print("Viewport::onInteractSelectedMesh - no interactions possible, as no mesh is currently selected");
      }
      return;
    }
    // -------------------------------------------------------- 3D display : set up view ----------------------------------
    camera(E.x, E.y, E.z, F.x, F.y, F.z, U.x, U.y, U.z); // defines the view : eye, ctr, up
    vec Li=U(A(V(E,F),0.1*d(E,F),J));   // vec Li=U(A(V(E,F),-d(E,F),J)); 
    
    //TODO msati3: Change this if so required
    //directionalLight(255,255,255,Li.x,Li.y,Li.z); // direction of light: behind and above the viewer
    //specular(255,255,0); shininess(5);  
    
    selectedMesh.draw();
    if (keyPressed&&key=='t') T.set(Pick()); // sets point T on the surface where the mouse points. The camera will turn toward's it when the 't' key is released
    selectedMesh.interactSelectedMesh();      
   
    SetFrame(Q,I,J,K);  // showFrame(Q,I,J,K,30);  // sets frame from picked points and screen axes
    
    selectedMesh.drawPostPicking();  
   } //end interact selected mesh

 //State query functions for viewport
  boolean containsPoint(int x, int y)
  {
    if ( x >= m_x && x <= m_x + m_width && y >= m_y && y <= m_y + m_height )
      return true;
    return false;   
  }
  
  pt getE() {return E;}
}
class ViewportManager
{
  private ArrayList<Viewport> m_viewports;
  private int m_selectedViewport;
  private boolean m_fShowingFullScreen;
  private boolean m_fShowingHelp;

  ViewportManager()
  {
    m_selectedViewport = -1;
    m_viewports = new ArrayList<Viewport>();
    m_fShowingFullScreen = false;
    m_fShowingHelp = false;
  }
  
  void addViewport( Viewport v )
  {
    m_viewports.add( v );
    if ( m_selectedViewport == -1 )
    {
      selectViewport( 0 );
    }
  }
  
  void selectViewport( int index )
  {
    if ( index >= m_viewports.size() || m_viewports.size() < 0)
    {
      if (DEBUG && DEBUG_MODE >= LOW)
      {
        print ("ViewportManager::selectViewport incorrect viewport index. The number of viewports is " + m_viewports.size()); 
      }
      if ( m_viewports.size() > 0 )
      {
        selectViewport( m_viewports.size() - 1 );
      }
      else
      {
        if (DEBUG && DEBUG_MODE >= LOW)
        {
          print ("ViewportManager::selectViewPort no viewports exist in viewport list");
        }
        return;
      }
    }
    
    //Track the selected viewport
    if ( m_selectedViewport != -1 )
    {
      m_viewports.get(m_selectedViewport).onDeselected();
    }
    m_selectedViewport = index;  
    m_viewports.get(m_selectedViewport).onSelected();
  }
  
  void registerMeshToViewport( Mesh m, int viewportIndex )
  {
    m_viewports.get(viewportIndex).registerMesh(m);
  }
  
  void unregisterMeshFromViewport( Mesh m, int viewportIndex )
  {
    m_viewports.get(viewportIndex).unregisterMesh(m);
  }

  void draw()
  {
    if (m_fShowingFullScreen)
    {
      if (m_selectedViewport != -1)
      {
        m_viewports.get(m_selectedViewport).draw(m_fShowingFullScreen);
      }
    }
    else
    {
      for (int i = 0; i < m_viewports.size(); i++)
      {
        m_viewports.get(i).draw(m_fShowingFullScreen);
      }
    }
    if (m_fShowingHelp)
    {
      camera();
      gl.glViewport(0,0,width,height);
      writeHelp();
    }
  }
  
  void onMousePressed()
  {
    int viewport = getViewportForMouse( mouseX, mouseY );
    selectViewport( viewport );
    if (m_selectedViewport != -1)
    {
      m_viewports.get(m_selectedViewport).onMousePressed();
    }
    else
    {
    }
  }
  
  void onMouseDragged()
  {
    if (m_selectedViewport != -1)
    {
      m_viewports.get(m_selectedViewport).onMouseDragged();
    }
    else
    {
      if (DEBUG && DEBUG_MODE >= LOW)
      {
        print ("ViewportManager::onMouseDragged - no viewport currently selected");
      }
    }
  }
  
  void onKeyReleased()
  {
    if (m_selectedViewport != -1)
    {
      m_viewports.get(m_selectedViewport).onKeyReleased();
    }
    else
    {
      if (DEBUG && DEBUG_MODE >= LOW)
      {
        print ("ViewportManager::onMouseDragged - no viewport currently selected");
      }
    }
  }
  
  void onKeyPressed()
  {
    if (key == '.')
    {
      if (m_selectedViewport != -1)
      {
        selectViewport( (m_selectedViewport + 1)%m_viewports.size() );
      }
    }
    if (key == '/')
    {
      m_fShowingFullScreen = !m_fShowingFullScreen;
    }
    if (key == 'H')
    {
      m_fShowingHelp = !m_fShowingHelp;
    }

    if (key == '!') {snapPicture();}
    
    if (m_selectedViewport != -1)
    {
      m_viewports.get(m_selectedViewport).onKeyPressed();
    }    
  }
  
  private int getViewportForMouse( int mouseX, int mouseY )
  {
    if ( m_fShowingFullScreen )
    {
      return m_selectedViewport;
    }
    for (int i = 0; i < m_viewports.size(); i++)
    {
      if (m_viewports.get(i).containsPoint(mouseX, height - mouseY))
      {
        return i;
      }
    }
    if ( DEBUG && DEBUG_MODE >= LOW )
    {
      print ("ViewportManager::getViewportForMouse : can't find viewport for mouse. Keeping same viewport!");
    }
    return m_selectedViewport;
  }
}

