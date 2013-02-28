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
