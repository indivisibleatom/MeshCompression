// CORNER TABLE FOR TRIANGLE MESHES by Jarek Rosignac
// Last edited October, 2011
// example meshesshowShrunkOffsetT
String [] fn= {
  "HeartReallyReduced.vts", "horse.vts", "bunny.vts", "torus.vts", "flat.vts", "tet.vts", "fandisk.vts", "squirrel.vts", "venus.vts", "mesh.vts", "hole.vts", "gs_dimples_bumps.vts"
};
int fni=0; 
int fniMax=fn.length; // file names for loading meshes
Boolean [] vis = new Boolean [20]; 
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
  int maxnv = 1000000;                         //  max number of vertices
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
  int[] cm2 = new int[3*maxnt];               // triangle markers: 0=not marked, 

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
  pt Cbox = new pt(width/2, height/2, 0);                   // mini-max box center
  float rbox=1000;                                        // half-diagonal of enclosing box

  // rendering modes
  Boolean flatShading=true;
  DrawingState m_drawingState = new DrawingState();
  protected MeshUserInputHandler m_userInputHandler;

  //wrapper class providing utilities to meshes
  MeshUtils m_utils = new MeshUtils(this);

  //  ==================================== OFFSET ====================================
  void offset() {
    normals();
    float d=rbox/100;
    for (int i=0; i<nv; i++) G[i]=P(G[i], d, Nv[i]);
  }
  void offset(float d) {
    normals();
    for (int i=0; i<nv; i++) G[i]=P(G[i], d, Nv[i]);
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
    for (int i=0; i<maxnv; i++) {
      G[i]=P(); 
      Nv[i]=V();
    };   // init vertices and normals
    for (int i=0; i<maxnt; i++) Nt[i]=V();       // init triangle normals and skeleton lab els
  }

  void resetCounters() {
    nv=0; 
    nt=0; 
    nc=0;
  }
  void rememberCounters() {
    nvr=nv; 
    ntr=nt; 
    ncr=nc;
  }
  void restoreCounters() {
    nv=nvr; 
    nt=ntr; 
    nc=ncr;
  }

  void makeGrid (int w) { // make a 2D grid of w x w vertices
    for (int i=0; i<w; i++) {
      for (int j=0; j<w; j++) { 
        G[w*i+j].set(height*.8*j/(w-1)+height/10, height*.8*i/(w-1)+height/10, 0);
      }
    }    
    for (int i=0; i<w-1; i++) {
      for (int j=0; j<w-1; j++) {                  // define the triangles for the grid
        V[(i*(w-1)+j)*6]=i*w+j;       
        V[(i*(w-1)+j)*6+2]=(i+1)*w+j;       
        V[(i*(w-1)+j)*6+1]=(i+1)*w+j+1;
        V[(i*(w-1)+j)*6+3]=i*w+j;     
        V[(i*(w-1)+j)*6+5]=(i+1)*w+j+1;     
        V[(i*(w-1)+j)*6+4]=i*w+j+1;
      };
    };
    nv = w*w;
    nt = 2*(w-1)*(w-1); 
    nc=3*nt;
  }

  void resetMarkers() { // reset the seed and current corner and the markers for corners, triangles, and vertices
    cc=0; 
    pc=0; 
    sc=0;
    for (int i=0; i<nv; i++) vm[i]=0;
    for (int i=0; i<nc; i++) cm[i]=0;
    for (int i=0; i<nt; i++) tm[i]=0;
    for (int i=0; i<nt; i++) visible[i]=true;
  }

  int addVertex(pt P) { 
    G[nv] = new pt(); 
    G[nv].set(P); 
    nv++; 
    return nv-1;
  };
  int addVertex(float x, float y, float z) { 
    G[nv] = new pt(); 
    G[nv].x=x; 
    G[nv].y=y; 
    G[nv].z=z; 
    nv++; 
    return nv-1;
  };

  void addTriangle(int i, int j, int k) {
    V[nc++]=i; 
    V[nc++]=j; 
    V[nc++]=k; 
    visible[nt++]=true; /*print("Triangle added " + nt + " " + i + " " + j + " " + k + "\n");*/
  } // adds a triangle
  void addTriangle(int i, int j, int k, int m) {
    V[nc++]=i; 
    V[nc++]=j; 
    V[nc++]=k; 
    tm[nt]=m; 
    visible[nt++]=true;
  } // adds a triangle

    void updateON() {
    computeO(); 
    normals();
  } // recomputes O and normals

    // ============================================= CORNER OPERATORS =======================================
  // operations on a corner
  int t (int c) {
    return int(c/3);
  };              // triangle of corner    
  int n (int c) {
    return 3*t(c)+(c+1)%3;
  };        // next corner in the same t(c)    
  int p (int c) {
    return n(n(c));
  };               // previous corner in the same t(c)  
  int v (int c) {
    return V[c] ;
  };                 // id of the vertex of c             
  int o (int c) {
    return O[c];
  };                  // opposite (or self if it has no opposite)
  int l (int c) {
    return o(n(c));
  };               // left neighbor (or next if n(c) has no opposite)                      
  int r (int c) {
    return o(p(c));
  };               // right neighbor (or previous if p(c) has no opposite)                    
  int s (int c) {
    return n(l(c));
  };               // swings around v(c) or around a border loop
  int u (int c) {
    return p(r(c));
  };               // unswings around v(c) or around a border loop
  int c (int t) {
    return t*3;
  }                    // first corner of triangle t
  boolean b (int c) {
    return O[c]==c;
  };           // if faces a border (has no opposite)
  boolean vis(int c) {
    return visible[t(c)];
  };   // true if tiangle of c is visible
  boolean hasValidR(int c) { 
    return r(c) != p(c);
  } //true for meshes with border if not returning previous (has actual R)
  boolean hasValidL(int c) { 
    return l(c) != n(c);
  } //true for meshes with borher if not returning next (has actual L)

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
  int t() {
    return t(cc);
  }
  int n() {
    return n(cc);
  }        
  Mesh next() {
    pc=cc; 
    cc=n(cc); 
    return this;
  };
  int p() {
    return p(cc);
  }        
  Mesh previous() {
    pc=cc; 
    cc=p(cc); 
    return this;
  };
  int v() {
    return v(cc);
  }
  int o() {
    return o(cc);
  }        
  Mesh back() {
    if (!b(cc)) {
      pc=cc; 
      cc=o(cc);
    }; 
    return this;
  };
  boolean b() {
    return b(cc);
  }             
  int l() {
    return l(cc);
  }         
  Mesh left() {
    next(); 
    back(); 
    return this;
  }; 
  int r() {
    return r(cc);
  }         
  Mesh right() {
    previous(); 
    back(); 
    return this;
  };
  int s() {
    return s(cc);
  }         
  Mesh swing() {
    left(); 
    next();  
    return this;
  };
  int u() {
    return u(cc);
  }         
  Mesh unswing() {
    right(); 
    previous();  
    return this;
  };

  // geometry for corner c
  pt g (int c) {
    return G[v(c)];
  };                // shortcut to get the point of the vertex v(c) of corner c
  pt cg(int c) {
    pt cPt = P(g(c), .3, triCenter(t(c)));  
    return(cPt);
  };   // computes point at corner
  pt corner(int c) {
    return P(g(c), triCenter(t(c)));
  };   // returns corner point

  // normals fot t(c) (must be precomputed)
  vec Nv (int c) {
    return(Nv[V[c]]);
  }; 
  vec Nv() {
    return Nv(cc);
  }            // shortcut to get the normal of v(c) 
  vec Nt (int c) {
    return(Nt[t(c)]);
  }; 
  vec Nt() {
    return Nt(cc);
  }            // shortcut to get the normal of t(c) 

  // geometry for corner cc
  pt g() {
    return g(cc);
  }            // shortcut to get the point of the vertex v(c) of corner c
  pt gp() {
    return g(p(cc));
  }            // shortcut to get the point of the vertex v(c) of corner c
  pt gn() {
    return g(n(cc));
  }            // shortcut to get the point of the vertex v(c) of corner c
  void setG(pt P) {
    G[v(cc)].set(P);
  } // moves vertex of c to P

    // debugging prints
  void writeCorner (int c) {
    println("cc="+cc+", n="+n(cc)+", p="+p(cc)+", o="+o(cc)+", v="+v(cc)+", t="+t(cc)+"."+", nt="+nt+", nv="+nv );
  }; 
  void writeCorner () {
    writeCorner (cc);
  }
  void writeCorners () {
    for (int c=0; c<nc; c++) {
      println("T["+c+"]="+t(c)+", visible="+visible[t(c)]+", v="+v(c)+",  o="+o(c));
    };
  }

  // ============================================= MESH MANIPULATION =======================================
  // pick corner closest to point X
  void pickcOfClosestVertex (pt X) {
    for (int b=0; b<nc; b++) if (vis[tm[t(b)]]) if (d(X, g(b))<d(X, g(cc))) {
      cc=b; 
      pc=b;
    }
  } // picks corner of closest vertex to X
  void pickc (pt X) {
    int origCC = cc;
    for (int b=0; b<nc; b++) if (V[b] != -1 && vis[tm[t(b)]] && visible[t(b)]) if (d(X, cg(b))<d(X, cg(cc)) ) {
      cc=b; 
      pc=b;
    }
    if ( origCC != cc && DEBUG && DEBUG_MODE >= LOW ) { 
      print("Corner picked :" + cc + " vertex :" + v(cc) + " corner for vertex :" + CForV[v(cc)]);
    }
  } // picks closest corner to X
  void picksOfClosestVertex (pt X) {
    for (int b=0; b<nc; b++) if (vis[tm[t(b)]]) if (d(X, g(b))<d(X, g(sc))) {
      sc=b;
    }
  } // picks corner of closest vertex to X
  void picks (pt X) {
    for (int b=0; b<nc; b++)  if (vis[tm[t(b)]]) if (d(X, cg(b))<d(X, cg(sc))) {
      sc=b;
    }
  } // picks closest corner to X

  // move the vertex of a corner
  void setG(int c, pt P) {
    G[v(c)].set(P);
  }       // moves vertex of c to P
  Mesh add(int c, vec V) {
    G[v(c)].add(V); 
    return this;
  }             // moves vertex of c to P
  Mesh add(int c, float s, vec V) {
    G[v(c)].add(s, V); 
    return this;
  }   // moves vertex of c to P
  Mesh add(vec V) {
    G[v(cc)].add(V); 
    return this;
  } // moves vertex of c to P
  Mesh add(float s, vec V) {
    G[v(cc)].add(s, V); 
    return this;
  } // moves vertex of c to P
  void move(int c) {
    g(c).add(pmouseY-mouseY, Nv(c));
  }
  void move(int c, float d) {
    g(c).add(d, Nv(c));
  }
  void move() {
    move(cc); 
    normals();
  }

  Mesh addROI(float s, vec V) { 
    return addROI(64, s, V);
  }
  Mesh addROI(int d, float s, vec V) {
    float md=setROI(d); 
    for (int c=0; c<nc; c++) if (!VisitedV[v(c)]&&(Mv[v(c)]!=0))  G[v(c)].add(s*(1.-distance[v(c)]/md), V);   // moves ROI
    smoothROI();
    setROI(d*2); // marks ROI of d rings
    smoothROI(); 
    smoothROI();
    return this;
  }   

  void tuckROI(float s) {
    for (int i=0; i<nv; i++) if (Mv[i]!=0) G[i].add(s, Nv[i]);
  };  // displaces each vertex by a fraction s of its normal
  void smoothROI() {
    computeLaplaceVectors(); 
    tuckROI(0.5); 
    computeLaplaceVectors(); 
    tuckROI(-0.5);
  };

  float setROI(int n) { // marks vertices and triangles at a graph distance of maxr
    float md=0;
    int tc=0; // triangle counter
    int r=1; // ring counter
    for (int i=0; i<nt; i++) {
      Mt[i]=0;
    };  // unmark all triangles
    Mt[t(cc)]=1; 
    tc++;                   // mark t(cc)
    for (int i=0; i<nv; i++) {
      Mv[i]=0;
    };  // unmark all vertices
    while ( (tc<nt)&&(tc<n)) {  // while not finished
      for (int i=0; i<nc; i++) {
        if ((Mv[v(i)]==0)&&(Mt[t(i)]==r)) {
          Mv[v(i)]=r; 
          distance[v(i)]=d(g(cc), g(i)); 
          md = max(md, distance[v(i)]);
        };
      };  // mark vertices of last marked triangles
      for (int i=0; i<nc; i++) {
        if ((Mt[t(i)]==0)&&(Mv[v(i)]==r)) {
          Mt[t(i)]=r+1; 
          tc++;
        };
      }; // mark triangles incident on last marked vertices
      r++; // increment ring counter
    };
    rings=r;
    return md;
  }

  //  ==========================================================  HIDE TRIANGLES ===========================================
  void markRings(int maxr) { // marks vertices and triangles at a graph distance of maxr
    int tc=0; // triangle counter
    int r=1; // ring counter
    for (int i=0; i<nt; i++) {
      Mt[i]=0;
    };  // unmark all triangles
    Mt[t(cc)]=1; 
    tc++;                   // mark t(cc)
    for (int i=0; i<nv; i++) {
      Mv[i]=0;
    };  // unmark all vertices
    while ( (tc<nt)&&(r<=maxr)) {  // while not finished
      for (int i=0; i<nc; i++) {
        if ((Mv[v(i)]==0)&&(Mt[t(i)]==r)) {
          Mv[v(i)]=r;
        };
      };  // mark vertices of last marked triangles
      for (int i=0; i<nc; i++) {
        if ((Mt[t(i)]==0)&&(Mv[v(i)]==r)) {
          Mt[t(i)]=r+1; 
          tc++;
        };
      }; // mark triangles incident on last marked vertices
      r++; // increment ring counter
    };
    rings=r; // sets ring variable for rendring?
  }

  void hide() {
    visible[t(cc)]=false; 
    if (!b(cc) && visible[t(o(cc))]) cc=o(cc); 
    else {
      cc=n(cc); 
      if (!b(cc) && visible[t(o(cc))]) cc=o(cc); 
      else {
        cc=n(cc); 
        if (!b(cc) && visible[t(o(cc))]) cc=o(cc);
      };
    };
  }
  void purge(int k) {
    for (int i=0; i<nt; i++) visible[i]=Mt[i]==k;
  } // hides triangles marked as k


    // ============================================= GEOMETRY =======================================

  // enclosing box
  void computeBox() { // computes center Cbox and half-diagonal Rbox of minimax box
    pt Lbox =  P(G[0]);  
    pt Hbox =  P(G[0]);
    for (int i=1; i<nv; i++) { 
      Lbox.x=min(Lbox.x, G[i].x); 
      Lbox.y=min(Lbox.y, G[i].y); 
      Lbox.z=min(Lbox.z, G[i].z);
      Hbox.x=max(Hbox.x, G[i].x); 
      Hbox.y=max(Hbox.y, G[i].y); 
      Hbox.z=max(Hbox.z, G[i].z);
    };
    Cbox.set(P(Lbox, Hbox));  
    rbox=d(Cbox, Hbox);
  };

  // ============================================= O TABLE CONSTRUCTION =========================================
  void computeOnaive() {                        // sets the O table from the V table, assumes consistent orientation of triangles
    resetCounters();
    for (int i=0; i<3*nt; i++) {
      O[i]=i;
    };  // init O table to -1: has no opposite (i.e. is a border corner)
    for (int i=0; i<nc; i++) {  
      for (int j=i+1; j<nc; j++) {       // for each corner i, for each other corner j
        if ( (v(n(i))==v(p(j))) && (v(p(i))==v(n(j))) ) {
          O[i]=j; 
          O[j]=i;
        };
      };
    };
  }// make i and j opposite if they match         

  void computeCForV() {
    for (int i = 0; i < nv; i++) { 
      CForV[i] = -1;
    }
    for (int i = 0; i < nc; i++) { 
      if (CForV[v(i)] == -1) { 
        CForV[v(i)] = i;
      }
    }
  }

  void computeO() {
    computeCForV();
    int val[] = new int [nv]; 
    for (int v=0; v<nv; v++) val[v]=0;  
    for (int c=0; c<nc; c++) val[v(c)]++;   //  valences
    int fic[] = new int [nv]; 
    int rfic=0; 
    for (int v=0; v<nv; v++) {
      fic[v]=rfic; 
      rfic+=val[v];
    };  // head of list of incident corners
    for (int v=0; v<nv; v++) val[v]=0;   // valences wil be reused to track how many incident corners were encountered for each vertex
    int [] C = new int [nc]; 
    for (int c=0; c<nc; c++) C[fic[v(c)]+val[v(c)]++]=c;  // vor each vertex: the list of val[v] incident corners starts at C[fic[v]]
    for (int c=0; c<nc; c++) O[c]=c;    // init O table to -1 meaning that a corner has no opposite (i.e. faces a border)
    for (int v=0; v<nv; v++)             // for each vertex...
      for (int a=fic[v]; a<fic[v]+val[v]-1; a++) for (int b=a+1; b<fic[v]+val[v]; b++) { // for each pair (C[a],C[b[]) of its incident corners
        if (v(n(C[a]))==v(p(C[b]))) {
          O[p(C[a])]=n(C[b]); 
          O[n(C[b])]=p(C[a]);
        }; // if C[a] follows C[b] around v, then p(C[a]) and n(C[b]) are opposite
        if (v(n(C[b]))==v(p(C[a]))) {
          O[p(C[b])]=n(C[a]); 
          O[n(C[a])]=p(C[b]);
        };
      };
  }
  void computeOvis() { // computees O for the visible triangles
    //   resetMarkers(); 
    int val[] = new int [nv]; 
    for (int v=0; v<nv; v++) val[v]=0;  
    for (int c=0; c<nc; c++) if (visible[t(c)]) val[v(c)]++;   //  valences
    int fic[] = new int [nv]; 
    int rfic=0; 
    for (int v=0; v<nv; v++) {
      fic[v]=rfic; 
      rfic+=val[v];
    };  // head of list of incident corners
    for (int v=0; v<nv; v++) val[v]=0;   // valences wil be reused to track how many incident corners were encountered for each vertex
    int [] C = new int [nc]; 
    for (int c=0; c<nc; c++) if (visible[t(c)]) C[fic[v(c)]+val[v(c)]++]=c;  // for each vertex: the list of val[v] incident corners starts at C[fic[v]]
    for (int c=0; c<nc; c++) O[c]=c;    // init O table to -1 meaning that a corner has no opposite (i.e. faces a border)
    for (int v=0; v<nv; v++)             // for each vertex...
      for (int a=fic[v]; a<fic[v]+val[v]-1; a++) for (int b=a+1; b<fic[v]+val[v]; b++) { // for each pair (C[a],C[b[]) of its incident corners
        if (v(n(C[a]))==v(p(C[b]))) {
          O[p(C[a])]=n(C[b]); 
          O[n(C[b])]=p(C[a]);
        }; // if C[a] follows C[b] around v, then p(C[a]) and n(C[b]) are opposite
        if (v(n(C[b]))==v(p(C[a]))) {
          O[p(C[b])]=n(C[a]); 
          O[n(C[a])]=p(C[b]);
        };
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

  void showCorner(int c, float r) {
    if (m_drawingState.m_fShowCorners) {
      show(cg(c), r);
    }
  };   // renders corner c as small ball

  void showcc() {
    noStroke(); 
    fill(blue); 
    showCorner(sc, 3); /* fill(green); showCorner(pc,5); */
    fill(dred); 
    showCorner(cc, 3);
  } // displays corner markers

  void showLabels() { // displays IDs of corners, vertices, and triangles
    fill(black); 
    for (int i=0; i<nv; i++) {
      show(G[i], "v"+str(i), V(10, Nv[i]));
    }; 
    for (int i=0; i<nc; i++) {
      show(corner(i), "c"+str(i), V(10, Nt[i]));
    }; 
    for (int i=0; i<nt; i++) {
      show(triCenter(i), "t"+str(i), V(10, Nt[i]));
    }; 
    noFill();
  }

  // ============================================= DISPLAY VERTICES =======================================
  void showVertices() {
    noStroke(); 
    noSmooth(); 
    for (int v=0; v<nv; v++) {
      //if (vm[v]==0) fill(brown,150);
      if (vm[v]==1) fill(red, 150);
      show(G[v], r);  
      if (vm[v]==2)
      {
        fill(green, 150);
        show(G[v], 5);
      }
      if (vm[v]==3)
      {
        fill(blue, 150);
        show(G[v], 5);
      }
      if (vm[v]==5)
      {
        fill(red, 150);
        show(G[v], 5);
      }
    }
    noFill();
  }

  void showVertices(int col, int radius) 
  {
    noStroke(); 
    noSmooth(); 
    for (int v=0; v<nv; v++)
    {
      fill(col);
      show(G[v], radius);
    }
    noFill();
  }

  // ============================================= DISPLAY EDGES =======================================
  void showBorder() {
    for (int c=0; c<nc; c++) {
      if (b(c) && visible[t(c)]) {
        drawEdge(c);
      };
    };
  };         // draws all border edges
  void showEdges () {
    for (int c=0; c<nc; c++) drawEdge(c);
  };  
  
  void drawEdge(int c) {
    show(g(p(c)), g(n(c)));
  };  // draws edge of t(c) opposite to corner c
  void drawSilhouettes() {
    for (int c=0; c<nc; c++) if (c<o(c) && frontFacing(t(c))!=frontFacing(t(o(c)))) drawEdge(c);
  }  

  // ============================================= DISPLAY TRIANGLES =======================================
  // displays triangle if marked as visible using flat or smooth shading (depending on flatShading variable
  void shade(int t) { // displays triangle t if visible
    if (visible[t])  
      if (flatShading) {
        beginShape(); 
        vertex(g(3*t)); 
        vertex(g(3*t+1)); 
        vertex(g(3*t+2));  
        endShape(CLOSE);
      }
      else {
        beginShape(); 
        normal(Nv[v(3*t)]); 
        vertex(g(3*t)); 
        normal(Nv[v(3*t+1)]); 
        vertex(g(3*t+1)); 
        normal(Nv[v(3*t+2)]); 
        vertex(g(3*t+2));  
        endShape(CLOSE);
      };
  }

  // display shrunken and offset triangles
  void showShrunkT(int t, float e) {
    if (visible[t]) showShrunk(g(3*t), g(3*t+1), g(3*t+2), e);
  }
  void showSOT(int t) {
    if (visible[t]) showShrunkOffsetT(t, 1, 1);
  }
  void showSOT() {
    if (visible[t(cc)]) showShrunkOffsetT(t(cc), 1, 1);
  }
  void showShrunkOffsetT(int t, float e, float h) {
    if (visible[t]) showShrunkOffset(g(3*t), g(3*t+1), g(3*t+2), e, h);
  }
  void showShrunkT() {
    int t=t(cc); 
    if (visible[t]) showShrunk(g(3*t), g(3*t+1), g(3*t+2), 2);
  }
  void showShrunkOffsetT(float h) {
    int t=t(cc); 
    if (visible[t]) showShrunkOffset(g(3*t), g(3*t+1), g(3*t+2), 2, h);
  }

  // display front and back triangles shrunken if showEdges  
  Boolean frontFacing(int t) {
    return !cw(m_viewport.getE(), g(3*t), g(3*t+1), g(3*t+2));
  } 
  void showFrontTrianglesSimple() {
    for (int t=0; t<nt; t++) if (frontFacing(t)) {
      if (m_drawingState.m_fShowEdges) showShrunkT(t, 1); 
      else shade(t);
    }
  };  

  void showFrontTriangles() {
    for (int t=0; t<nt; t++) if (frontFacing(t)) {
      if (!visible[t]) continue;
      //      if(tm[t]==1) continue;
      if (tm[t]==0) fill(cyan, 155); 
      if (tm[t]==1) fill(green, 150); 
      if (tm[t]==2) fill(red, 150); 
      if (tm[t]==3) fill(blue, 150); 
      if (m_drawingState.m_fShowEdges) showShrunkT(t, 1); 
      else shade(t);
    }
  } 

  void showTriangles(Boolean front, int opacity, float shrunk) {
    for (int t=0; t<nt; t++) {
      if (V[3*t] == -1) continue;    //Handle base mesh compacted triangles      
      if (!vis[tm[t]] || frontFacing(t)!=front || !visible[t]) continue;
      if (!frontFacing(t)&&showBack) {
        fill(blue); 
        shade(t); 
        continue;
      }
      //if(tm[t]==1) continue; 
      //if(tm[t]==1&&!showMiddle || tm[t]==0&&!showLeft || tm[t]==2&&!showRight) continue; 
      if (tm[t]==0) fill(cyan, opacity); 
      if (tm[t]==1) fill(brown, opacity); 
      if (tm[t]==2) fill(orange, opacity); 
      if (tm[t]==3) fill(cyan, opacity); 
      if (tm[t]==4) fill(magenta, opacity); 
      if (tm[t]==5) fill(green, opacity); 
      if (tm[t]==6) fill(blue, opacity); 
      if (tm[t]==7) fill(#FAAFBA, opacity); 
      if (tm[t]==8) fill(blue, opacity); 
      if (tm[t]==9) fill(yellow, opacity); 
      
      if (tm[t]==10) fill(cyan, opacity); 
      if (tm[t]==11) fill(brown, opacity); 
      if (tm[t]==12) fill(orange, opacity); 
      if (tm[t]==13) fill(cyan, opacity); 
      if (tm[t]==14) fill(magenta, opacity); 
      if (tm[t]==15) fill(green, opacity); 
      if (tm[t]==16) fill(blue, opacity); 
      if (tm[t]==17) fill(#FAAFBA, opacity); 
      if (tm[t]==18) fill(blue, opacity); 
      if (tm[t]==19) fill(yellow, opacity); 
      
      if (vis[tm[t]]) {
        if (m_drawingState.m_shrunk != 0) showShrunkT(t, m_drawingState.m_shrunk); 
        else shade(t);
      }
    }
  }

  void showBackTriangles() {
    for (int t=0; t<nt; t++) if (!frontFacing(t)) shade(t);
  };  
  void showMarkedTriangles() {
    for (int t=0; t<nt; t++) if (visible[t]&&Mt[t]!=0) {
      fill(ramp(Mt[t], rings)); 
      showShrunkOffsetT(t, 1, 1);
    }
  };  

  // ********************************************************* DRAW *****************************************************
  void draw()
  {
    noStroke();
    if (m_drawingState.m_fPickingBack)
    {
      noStroke(); 
      if (m_drawingState.m_fTranslucent)  
      {
        showTriangles(false, 100, m_drawingState.m_shrunk);
      }
      else 
      {
        showBackTriangles();
      }
    }
    else if (m_drawingState.m_fTranslucent)
    {
      if (m_drawingState.m_fShowTriangles)
      {
        fill(grey, 80); 
        noStroke(); 
        showBackTriangles();  
        showTriangles(true, 150, m_drawingState.m_shrunk);
      }
    }
    else if (m_drawingState.m_fShowTriangles)
    {
      showTriangles(true, 255, m_drawingState.m_shrunk);
    }
    if (m_drawingState.m_fShowVertices)
    {
      showVertices();
    }
    if (m_drawingState.m_fShowCorners)
    {
      showCorners();
    }
    if (m_drawingState.m_fShowNormals)
    {
      showNormals();
    }
    if (m_drawingState.m_fShowEdges)
    {
      stroke(black); 
      showEdges();
    }
  }

  void drawPostPicking()
  {       
    // -------------------------------------------------------- display picked points and triangles ----------------------------------   
    fill(163, 73, 164); 
    showSOT(); // shoes triangle t(cc) shrunken
    showcc();  // display corner markers: seed sc (green),  current cc (red)

    // -------------------------------------------------------- display FRONT if we were picking on the back ---------------------------------- 
    if (getDrawingState().m_fPickingBack) 
    {
      if (getDrawingState().m_fTranslucent) {
        fill(cyan, 150); 
        if (getDrawingState().m_fShowEdges) stroke(orange); 
        else noStroke(); 
        showTriangles(true, 100, m_drawingState.m_shrunk);
      } 
      else {
        fill(cyan); 
        if (getDrawingState().m_fShowEdges) stroke(orange); 
        else noStroke(); 
        showTriangles(true, 255, m_drawingState.m_shrunk);
      }
    }

    // -------------------------------------------------------- Disable z-buffer to display occluded silhouettes and other things ---------------------------------- 
    hint(DISABLE_DEPTH_TEST);  // show on top
    if (getDrawingState().m_fSilhoutte) {
      stroke(dbrown); 
      drawSilhouettes();
    }  // display silhouettes
  }

  DrawingState getDrawingState()
  {
    return m_drawingState;
  }

  //  ==========================================================  PROCESS EDGES ===========================================
  // FLIP 
  void flip(int c) {      // flip edge opposite to corner c, FIX border cases
    if (b(c)) return;
    V[n(o(c))]=v(c); 
    V[n(c)]=v(o(c));
    int co=o(c); 

    O[co]=r(c); 
    if (!b(p(c))) O[r(c)]=co; 
    if (!b(p(co))) O[c]=r(co); 
    if (!b(p(co))) O[r(co)]=c; 
    O[p(c)]=p(co); 
    O[p(co)]=p(c);
  }
  void flip() {
    flip(cc); 
    pc=cc; 
    cc=p(cc);
  }

  void flipWhenLonger() {
    for (int c=0; c<nc; c++) if (d(g(n(c)), g(p(c)))>d(g(c), g(o(c)))) flip(c);
  } 

  int cornerOfShortestEdge() {  // assumes manifold
    float md=d(g(p(0)), g(n(0))); 
    int ma=0;
    for (int a=1; a<nc; a++) if (vis(a)&&(d(g(p(a)), g(n(a)))<md)) {
      ma=a; 
      md=d(g(p(a)), g(n(a)));
    }; 
    return ma;
  } 
  void findShortestEdge() {
    cc=cornerOfShortestEdge();
  } 

  //  ========================================================== PROCESS  TRIANGLES ===========================================
  pt triCenter(int i) {
    return P( G[V[3*i]], G[V[3*i+1]], G[V[3*i+2]] );
  };  
  pt triCenter() {
    return triCenter(t());
  }  // computes center of triangle t(i) 
  void writeTri (int i) {
    println("T"+i+": V = ("+V[3*i]+":"+v(o(3*i))+","+V[3*i+1]+":"+v(o(3*i+1))+","+V[3*i+2]+":"+v(o(3*i+2))+")");
  };



  //  ==========================================================  NORMALS ===========================================
  void normals() {
    computeTriNormals(); 
    computeVertexNormals();
  }
  void computeValenceAndResetNormals() {      // caches valence of each vertex
    for (int i=0; i<nv; i++) {
      Nv[i]=V();  
      Valence[i]=0;
    };  // resets the valences to 0
    for (int i=0; i<nc; i++) {
      Valence[v(i)]++;
    };
  }
  vec triNormal(int t) { 
    return N(V(g(3*t), g(3*t+1)), V(g(3*t), g(3*t+2)));
  };  
  void computeTriNormals() {
    for (int i=0; i<nt; i++) {
      Nt[i].set(triNormal(i));
    };
  };             // caches normals of all tirangles
  void computeVertexNormals() {  // computes the vertex normals as sums of the normal vectors of incident tirangles scaled by area/2
    for (int i=0; i<nv; i++) {
      Nv[i].set(0, 0, 0);
    };  // resets the valences to 0
    for (int i=0; i<nc; i++) {
      Nv[v(i)].add(Nt[t(i)]);
    };
    for (int i=0; i<nv; i++) {
      Nv[i].normalize();
    };
  };
  void showVertexNormals() {
    for (int i=0; i<nv; i++) show(G[i], V(10*r, Nv[i]));
  };
  void showTriNormals() {
    for (int i=0; i<nt; i++) show(triCenter(i), V(10*r, U(Nt[i])));
  };
  void showNormals() {
    if (flatShading) showTriNormals(); 
    else showVertexNormals();
  }
  vec normalTo(int m) {
    vec N=V(); 
    for (int i=0; i<nt; i++) if (tm[i]==m) N.add(triNormal(i)); 
    return U(N);
  }

  //  ==========================================================  VOLUME ===========================================
  float volume() {
    float v=0; 
    for (int i=0; i<nt; i++) v+=triVol(i); 
    vol=v/6; 
    return vol;
  }
  float volume(int m) {
    float v=0; 
    for (int i=0; i<nt; i++) if (tm[i]==m) v+=triVol(i); 
    return v/6;
  }
  float triVol(int t) { 
    return m(P(), g(3*t), g(3*t+1), g(3*t+2));
  };  

  float surface() {
    float s=0; 
    for (int i=0; i<nt; i++) s+=triSurf(i); 
    surf=s; 
    return surf;
  }
  float surface(int m) {
    float s=0; 
    for (int i=0; i<nt; i++) if (tm[i]==m) s+=triSurf(i); 
    return s;
  }
  float triSurf(int t) { 
    if (visible[t]) return area(g(3*t), g(3*t+1), g(3*t+2)); 
    else return 0;
  };  

  // ============================================================= SMOOTHING ============================================================
  void computeLaplaceVectors() {  // computes the vertex normals as sums of the normal vectors of incident tirangles scaled by area/2
    computeValenceAndResetNormals();
    for (int i=0; i<3*nt; i++) {
      Nv[v(p(i))].add(V(g(p(i)), g(n(i))));
    };
    for (int i=0; i<nv; i++) {
      Nv[i].div(Valence[i]);
    };
  };
  void tuck(float s) {
    for (int i=0; i<nv; i++) G[i].add(s, Nv[i]);
  };  // displaces each vertex by a fraction s of its normal
  void smoothen() {
    normals(); 
    computeLaplaceVectors(); 
    tuck(0.6); 
    computeLaplaceVectors(); 
    tuck(-0.6);
  };

  // ============================================================= SUBDIVISION ============================================================
  int w (int c) {
    return(W[c]);
  };               // temporary indices to mid-edge vertices associated with corners during subdivision

  void splitEdges() {            // creates a new vertex for each edge and stores its ID in the W of the corner (and of its opposite if any)
    for (int i=0; i<3*nt; i++) {  // for each corner i
      if (b(i)) {
        G[nv]=P(g(n(i)), g(p(i))); 
        W[i]=nv++;
      }
      else {
        if (i<o(i)) {
          G[nv]=P(g(n(i)), g(p(i))); 
          W[o(i)]=nv; 
          W[i]=nv++;
        };
      };
    };
  } // if this corner is the first to see the edge

  void bulge() {              // tweaks the new mid-edge vertices according to the Butterfly mask
    for (int i=0; i<3*nt; i++) {
      if ((!b(i))&&(i<o(i))) {    // no tweak for mid-vertices of border edges
        if (!b(p(i))&&!b(n(i))&&!b(p(o(i)))&&!b(n(o(i))))
        {
          G[W[i]].add(0.25, V(P(P(g(l(i)), g(r(i))), P(g(l(o(i))), g(r(o(i))))), (P(g(i), g(o(i))))));
        };
      };
    };
  };

  void splitTriangles() {    // splits each tirangle into 4
    for (int i=0; i<3*nt; i=i+3) {
      V[3*nt+i]=v(i); 
      V[n(3*nt+i)]=w(p(i)); 
      V[p(3*nt+i)]=w(n(i));
      V[6*nt+i]=v(n(i)); 
      V[n(6*nt+i)]=w(i); 
      V[p(6*nt+i)]=w(p(i));
      V[9*nt+i]=v(p(i)); 
      V[n(9*nt+i)]=w(n(i)); 
      V[p(9*nt+i)]=w(i);
      V[i]=w(i); 
      V[n(i)]=w(n(i)); 
      V[p(i)]=w(p(i));
    };
    nt=4*nt; 
    nc=3*nt;
  };

  void refine() { 
    updateON(); 
    splitEdges(); 
    bulge(); 
    splitTriangles(); 
    updateON();
  }

  //  ========================================================== FILL HOLES ===========================================
  void fanHoles() {
    for (int cc=0; cc<nc; cc++) if (visible[t(cc)]&&b(cc)) fanThisHole(cc); 
    normals();
  }
  void fanThisHole() {
    fanThisHole(cc);
  }
  void fanThisHole(int cc) {   // fill hole with triangle fan (around average of parallelogram predictors). Must then call computeO to restore O table
    if (!b(cc)) return ; // stop if cc is not facing a border
    G[nv].set(0, 0, 0);   // tip vertex of fan
    int o=0;              // tip corner of new fan triangle
    int n=0;              // triangle count in fan
    int a=n(cc);          // corner running along the border
    while (n (a)!=cc) {    // walk around the border loop 
      if (b(p(a))) {       // when a is at the left-end of a border edge
        G[nv].add( P(P(g(a), g(n(a))), P(g(a), V(g(p(a)), g(n(a))))) ); // add parallelogram prediction and mid-edge point
        o=3*nt; 
        V[o]=nv; 
        V[n(o)]=v(n(a)); 
        V[p(o)]=v(a); 
        visible[nt]=true; 
        nt++; // add triangle to V table, make it visible
        O[o]=p(a); 
        O[p(a)]=o;        // link opposites for tip corner
        O[n(o)]=-1; 
        O[p(o)]=-1;
        n++;
      }; // increase triangle-count in fan
      a=s(a);
    } // next corner along border
    G[nv].mul(1./n); // divide fan tip to make it the average of all predictions
    a=o(cc);       // reset a to walk around the fan again and set up O
    int l=n(a);   // keep track of previous
    int i=0; 
    while (i<n) {
      a=s(a); 
      if (v(a)==nv) { 
        i++; 
        O[p(a)]=l; 
        O[l]=p(a); 
        l=n(a);
      };
    };  // set O around the fan
    nv++;  
    nc=3*nt;  // update vertex count and corner count
  };




  // =========================================== STITCH SHELLS ==================================================================================================================================================== ###
  int c1=0, c2=0;
  pt Q1 = P();
  pt Q2 = P();
  void stitch(int m1, int m2, int m3) { // add m3 triangles to sip gap between m1 and m2
    c1=-1; 
    for (int c=0; c<nc; c++) if (tm[t(c)]==m1) if (b(c)) {
      c1=c; 
      break;
    } 
    else if (tm[t(o(c))]!=m1) {
      c1=c; 
      break;
    } // compute border corner of m1
    if (c1==-1) {
      c1=0; 
      return ;
    }; // no border found
    cc=c1;
    pt Q=g(p(c1));
    Q1=Q;
    // search for matching border edge of m2
    float d = 1000000;
    c2=-1; 
    for (int c=0; c<nc; c++) if (tm[t(c)]==m2) {
      if (b(c)) {
        if ( d( P(g(n(c)), g(p(c)) ), Q)<d ) {
          c2=c; 
          d=d(P(g(n(c)), g(p(c))), Q);
        }
      }
      else if (tm[t(o(c))]!=m2) {
        if (d(P(g(n(c)), g(p(c))), Q)<d) {
          c2=c; 
          d=d(P(g(n(c)), g(p(c))), Q);
        }
      }
    }
    if (c2==-1) {
      c2=0; 
      return ;
    };
    sc=c2;  
    addTriangle( v(p(c1)), v(p(c2)), v(n(c2)), m3 );
    int sc1=c1, sc2=c2; // record starting corners
    c2=pal(c2);
    boolean e1=false, e2=false; // finished walking around borders
    int i=0;
    while ( (!e1  || !e2) && i++<nsteps) {
      if (e2 || (!e1 && (d(g(n(c2)), g(n(c1)))) < d(g(p(c2)), g(p(c1)))) ) {
        addTriangle( v(n(c2)), v(p(c1)), v(n(c1)), m3 ); 
        c1=nal(c1); 
        if (c1==sc1) e1=true;
      }
      else {
        addTriangle( v(p(c1)), v(p(c2)), v(n(c2)), m3 ); 
        c2=pal(c2); 
        if (c2==sc2) e2=true;
      }
    }
  }

  int nal(int c) {
    int a=p(c); 
    while (!b (a)&&tm[t(a)]==tm[t(o(a))]) a=p(o(a)); 
    return a;
  } // returns next corner around loop
  int pal(int c) {
    int a=n(c); 
    while (!b (a)&&tm[t(a)]==tm[t(o(a))]) a=n(o(a)); 
    return a;
  } // returns previous corner around loop

  // =========================================== STITCH SHELLS (END) ============================================================================================================================================ ###





  // =========================================== GEODESIC MEASURES, DISTANCES =============================
  void computeDistance(int maxr) { // marks vertices and triangles at a graph distance of maxr
    int tc=0; // triangle counter
    int r=1; // ring counter
    for (int i=0; i<nt; i++) {
      Mt[i]=0;
    };  // unmark all triangles
    Mt[t(cc)]=1; 
    tc++;                   // mark t(cc)
    for (int i=0; i<nv; i++) {
      Mv[i]=0;
    };  // unmark all vertices
    while ( (tc<nt)&&(r<=maxr)) {  // while not finished
      for (int i=0; i<nc; i++) {
        if ((Mv[v(i)]==0)&&(Mt[t(i)]==r)) {
          Mv[v(i)]=r;
        };
      };  // mark vertices of last marked triangles
      for (int i=0; i<nc; i++) {
        if ((Mt[t(i)]==0)&&(Mv[v(i)]==r)) {
          Mt[t(i)]=r+1; 
          tc++;
        };
      }; // mark triangles incident on last marked vertices
      r++; // increment ring counter
    };
    rings=r; // sets ring variable for rendring?
  }

  void computeIsolation() {
    println("Starting isolation computation for "+nt+" triangles");
    for (int i=0; i<nt; i++) {
      SMt[i]=0;
    }; 
    for (int c=0; c<nc; c+=3) {
      println("  triangle "+t(c)+"/"+nt); 
      computeDistance(1000); 
      for (int j=0; j<nt; j++) {
        SMt[j]+=Mt[j];
      };
    };
    int L=SMt[0], H=SMt[0];  
    for (int i=0; i<nt; i++) { 
      H=max(H, SMt[i]); 
      L=min(L, SMt[i]);
    }; 
    if (H==L) {
      H++;
    };
    cc=0; 
    for (int i=0; i<nt; i++) {
      Mt[i]=(SMt[i]-L)*255/(H-L); 
      if (Mt[i]>Mt[t(cc)]) {
        cc=3*i;
      };
    }; 
    rings=255;
    for (int i=0; i<nv; i++) {
      Mv[i]=0;
    };  
    for (int i=0; i<nc; i++) {
      Mv[v(i)]=max(Mv[v(i)], Mt[t(i)]);
    };
    println("finished isolation");
  }

  void computePath() {                 // graph based shortest path between t(c0 and t(prevc), prevc is the previously picekd corner
    for (int i=0; i<nt; i++) {
      Mt[i]=0;
    }; // reset marking
    Mt[t(sc)]=1; // Mt[0]=1;            // mark seed triangle
    for (int i=0; i<nc; i++) {
      P[i]=false;
    }; // reset corners as not visited
    int r=1;
    boolean searching=true;
    while (searching) {
      for (int i=0; i<nc; i++) {
        if (searching&&(Mt[t(i)]==0)&&(!b(i))) { // t(i) is an unvisited triangle and i is not facing a border edge
          if (Mt[t(o(i))]==r) { // if opposite triangle is ring r
            Mt[t(i)]=r+1; // mark (invade) t(i) as part of ring r+1
            P[i]=true;    // mark corner i as visited
            if (t(i)==t(cc)) {
              searching=false;
            }; // if we reached the end?
          };
        };
      };
      r++;
    };
    for (int i=0; i<nt; i++) {
      Mt[i]=0;
    };  // graph distance between triangle and t(c)
    rings=1;      // track ring number
    int b=cc;
    int k=0;
    while (t (b)!=t(sc)) { // back track
      rings++;  
      if (P[b]) {
        b=o(b); 
        print(".o");
      } 
      else {
        if (P[p(b)]) {
          b=r(b);
          print(".r");
        } 
        else {
          b=l(b);
          print(".l");
        };
      }; 
      Mt[t(b)]=rings;
    };
  }

  void  showDistance() {
    noStroke(); 
    for (int t=0; t<nt; t++) if (Mt[t]!=0) {
      fill(ramp(Mt[t], rings)); 
      showShrunkOffsetT(t, 1, 1);
    }; 
    noFill();
  } 


  //  ==========================================================  GARBAGE COLLECTION ===========================================
  void clean() {
    excludeInvisibleTriangles();  
    println("excluded");
    compactVO(); 
    println("compactedVO");
    compactV(); 
    println("compactedV");
    normals(); 
    println("normals");
    computeO();
    resetMarkers();
  }  // removes deleted triangles and unused vertices

    void excludeInvisibleTriangles () {
    for (int b=0; b<nc; b++) {
      if (!visible[t(o(b))]) {
        O[b]=b;
      };
    };
  }
  void compactVO() {  
    int[] U = new int [nc];
    int lc=-1; 
    for (int c=0; c<nc; c++) {
      if (visible[t(c)]) {
        U[c]=++lc;
      };
    };
    for (int c=0; c<nc; c++) {
      if (!b(c)) {
        O[c]=U[o(c)];
      } 
      else {
        O[c]=c;
      };
    };
    int lt=0;
    for (int t=0; t<nt; t++) {
      if (visible[t]) {
        V[3*lt]=V[3*t]; 
        V[3*lt+1]=V[3*t+1]; 
        V[3*lt+2]=V[3*t+2]; 
        O[3*lt]=O[3*t]; 
        O[3*lt+1]=O[3*t+1]; 
        O[3*lt+2]=O[3*t+2]; 
        visible[lt]=true; 
        lt++;
      };
    };
    nt=lt; 
    nc=3*nt;    
    println("      ...  NOW: nv="+nv +", nt="+nt +", nc="+nc );
  }

  void compactV() {  
    println("COMPACT VERTICES: nv="+nv +", nt="+nt +", nc="+nc );
    int[] U = new int [nv];
    boolean[] deleted = new boolean [nv];
    for (int v=0; v<nv; v++) {
      deleted[v]=true;
    };
    for (int c=0; c<nc; c++) {
      deleted[v(c)]=false;
    };
    int lv=-1; 
    for (int v=0; v<nv; v++) {
      if (!deleted[v]) {
        U[v]=++lv;
      };
    };
    for (int c=0; c<nc; c++) {
      V[c]=U[v(c)];
    };
    lv=0;
    for (int v=0; v<nv; v++) {
      if (!deleted[v]) {
        G[lv].set(G[v]);  
        deleted[lv]=false; 
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
    if (savePath == null) {
      println("No output file was selected..."); 
      return;
    }
    else println("writing to "+savePath);
    saveMeshVTS(savePath);
  }

  void saveMeshVTS(String fn) {
    String [] inppts = new String [nv+1+nt+1];
    int s=0;
    inppts[s++]=str(nv);
    for (int i=0; i<nv; i++) {
      inppts[s++]=str(G[i].x)+","+str(G[i].y)+","+str(G[i].z);
    };
    inppts[s++]=str(nt);
    if (flipOrientation) {
      for (int i=0; i<nt; i++) {
        inppts[s++]=str(V[3*i])+","+str(V[3*i+2])+","+str(V[3*i+1]);
      };
    }
    else {
      for (int i=0; i<nt; i++) {
        inppts[s++]=str(V[3*i])+","+str(V[3*i+1])+","+str(V[3*i+2]);
      };
    };
    saveStrings(fn, inppts);
  };

  void loadMeshVTS() {
    String loadPath = selectInput("Select .vts mesh file to load");  // Opens file chooser
    if (loadPath == null) {
      println("No input file was selected..."); 
      return;
    }
    else println("reading from "+loadPath); 
    loadMeshVTS(loadPath);
  }

  void loadMeshVTS(String fn) {
    println("loading: "+fn); 
    String [] ss = loadStrings(fn);
    String subpts;
    int s=0;   
    int comma1, comma2;   
    float x, y, z;   
    int a, b, c;
    nv = int(ss[s++]);
    print("nv="+nv);
    for (int k=0; k<nv; k++) {
      int i=k+s; 
      comma1=ss[i].indexOf(',');   
      x=float(ss[i].substring(0, comma1));
      String rest = ss[i].substring(comma1+1, ss[i].length());
      comma2=rest.indexOf(',');    
      y=float(rest.substring(0, comma2)); 
      z=float(rest.substring(comma2+1, rest.length()));
      G[k].set(x, y, z);
    };
    s=nv+1;
    nt = int(ss[s]); 
    nc=3*nt;
    println(", nt="+nt);
    s++;
    for (int k=0; k<nt; k++) {
      int i=k+s;
      comma1=ss[i].indexOf(',');   
      a=int(ss[i].substring(0, comma1));  
      String rest = ss[i].substring(comma1+1, ss[i].length()); 
      comma2=rest.indexOf(',');  
      b=int(rest.substring(0, comma2)); 
      c=int(rest.substring(comma2+1, rest.length()));
      V[3*k]=a;  
      V[3*k+1]=b;  
      V[3*k+2]=c;
    }
  };


  void loadMeshOBJ() {
    String loadPath = selectInput("Select .obj mesh file to load");  // Opens file chooser
    if (loadPath == null) {
      println("No input file was selected..."); 
      return;
    }
    else println("reading from "+loadPath); 
    loadMeshOBJ(loadPath);
  }

  void loadMeshOBJ(String fn) {
    println("loading: "+fn); 
    String [] ss = loadStrings(fn);
    String subpts;
    String S;
    int comma1, comma2;   
    float x, y, z;   
    int a, b, c;
    int s=2;   
    println(ss[s]);
    int nn=ss[s].indexOf(':')+2; 
    println("nn="+nn);
    nv = int(ss[s++].substring(nn));  
    println("nv="+nv);
    int k0=s;
    for (int k=0; k<nv; k++) {
      int i=k+k0; 
      S=ss[i].substring(2); 
      if (k==0 || k==nv-1) println(S);
      comma1=S.indexOf(' ');   
      x=-float(S.substring(0, comma1));           // swaped sign to fit picture
      String rest = S.substring(comma1+1);
      comma2=rest.indexOf(' ');    
      y=float(rest.substring(0, comma2)); 
      z=float(rest.substring(comma2+1));
      G[k].set(x, y, z); 
      if (k<3 || k>nv-4) {
        print("k="+k+" : ");
      }
      s++;
    };
    s=s+2; 
    println("Triangles");
    println(ss[s]);
    nn=ss[s].indexOf(':')+2;
    nt = int(ss[s].substring(nn)); 
    nc=3*nt;
    println(", nt="+nt);
    s++;
    k0=s;
    for (int k=0; k<nt; k++) {
      int i=k+k0;
      S=ss[i].substring(2);                        
      if (k==0 || k==nt-1) println(S);
      comma1=S.indexOf(' ');   
      a=int(S.substring(0, comma1));  
      String rest = S.substring(comma1+1); 
      comma2=rest.indexOf(' ');  
      b=int(rest.substring(0, comma2)); 
      c=int(rest.substring(comma2+1));
      //      V[3*k]=a-1;  V[3*k+1]=b-1;  V[3*k+2]=c-1;                           // original
      V[3*k]=a-1;  
      V[3*k+1]=c-1;  
      V[3*k+2]=b-1;                           // swaped order
    }
    for (int i=0; i<nv; i++) G[i].mul(4);
  }; 

  // ============================================================= CUT =======================================================
  void cut(pt[] CP, int ncp) {
    if (ncp<3) return;
    for (int t=0; t<nt; t++) {
      tm[t]=0;
    }; // reset triangle markings are not in ring
    int[] cc = new int[ncp]; // closest corners
    for (int i=0; i<ncp; i++) cc[i]=closestCorner(CP[i+1]);
    traceRing(cc, ncp); // marks triangles on ring through control points
  }

  //************************************************************************************************************** CUT ************************************************************
  void cut(LOOP L) { // computes projected loop PL and constructs baffle
    if (L.n<3) return;
    //    LOOP XL = new LOOP(); 
    //    XL.setToProjection(L,this); 
    //    PL=XL.resampleDistance(100);                                           // loop sampling was 10
    RL.setToProjection(L, this); 
    PL=RL.resampleDistance(5);                                           // loop sampling was 10

    //    for(int i=0; i<10; i++) {PL.projectOn(Cylinder); PL.projectOn(this);}

    PL.smoothen(); 
    PL.projectOn(this);
    PL.smoothenOn(this); 
    for (int t=0; t<nt; t++) {
      tm[t]=0;
    }; // reset triangle markings are not in ring
    int[] cc = new int[PL.n]; // closest corners
    for (int i=0; i<PL.n; i++) cc[i]=closestCorner(PL.Pof(i));
    traceRing(cc, PL.n); // marks triangles on ring through control points
    int s=0; // mark the corners facing the cut triangles
    for (int c=0; c<nc; c++) if ( tm[t(c)]==0 && tm[t(o(c))]==1 && d(g(c), g(cc[0]))<d(g(s), g(cc[0]))) s=c;
    tm[t(s)]=2;
    invade(0, 2, s);
    PL.smoothenOn(this, 1);
  }

  void invade(int om, int nm, int s) { // grows region  tm[t]=nm by invading triangles where tm[t]==om
    Boolean found=true;
    while (found) {
      found=false;
      for (int c=0; c<nc; c++) 
        if ( tm[t(c)]==om && tm[t(o(c))]==nm) {
          tm[t(c)]=nm; 
          found=true;
        }
    }
  }
  void showPebbles() {
    noStroke(); 
    fill(magenta); 
    for (int c=0; c<nc; c++) if (P[c]) show(cg(c), 2);
  }

  void traceRing(int[] cc, int ncp) { // computes ring of triangles that visits corners cc
    markPath(cc[ncp-1], cc[0]); 
    for (int i=0; i<ncp-1; i++) markPath( cc[i], cc[i+1] );
  }

  void markPath(int sc, int cc) {     // graph based shortest path between sc and cc
    if (t(sc)==t(cc)) {
      tm[t(sc)]=1; 
      return;
    }
    for (int i=0; i<nt; i++) {
      Mt[i]=0;
    }; // reset marking of visited triangles
    Mt[t(sc)]=1;                      // mark seed triangle
    for (int i=0; i<nc; i++) {
      P[i]=false;
    }; // reset all corners as not having a parent
    int r=1;
    boolean searching=true;
    while (searching) {
      for (int i=0; i<nc; i++) {
        if (searching&&(Mt[t(i)]==0)&&(!b(i))) { // t(i) is an unvisited triangle and i is not facing a border edge
          if (Mt[t(o(i))]==r) { // if opposite triangle is ring r
            Mt[t(i)]=r+1; // mark (invade) t(i) as part of ring r+1
            P[i]=true;    // mark corner i as visited
            if (t(i)==t(cc)) {
              searching=false;
            }; // if we reached the end?
          };
        };
      };
      r++;
    };
    int b=cc;
    while (t (b)!=t(sc)) { // back track
      if (P[b]) b=o(b);  
      else if (P[p(b)]) b=r(b); 
      else b=l(b);
      tm[t(b)]=1;
    };
  }

  void makeInvisible(int m) { 
    for (int i=0; i<nt; i++) if (tm[i]==m) visible[i]=false;
  }
  void rename(int m, int k) { 
    for (int i=0; i<nt; i++) if (tm[i]==m)  tm[i]=k;
  }
  void makeAllVisible() { 
    for (int i=0; i<nt; i++) visible[i]=true;
  }

  // cplit the mesh near loop
  int closestVertexID(pt M) {
    int v=0; 
    for (int i=1; i<nv; i++) if (d(M, G[i])<d(M, G[v])) v=i; 
    return v;
  }
  int closestCorner(pt M) {
    int c=0; 
    for (int i=1; i<nc; i++) if (d(M, cg(i))<d(M, cg(c))) c=i; 
    return c;
  }

  void drawLoopOfClosestVertices(LOOP L) {
    resetMarkers(); 
    noFill(); 
    stroke(magenta); 
    beginShape();
    for (int p=0; p<L.n; p++) {
      int v=closestVertexID(L.P[p]); 
      vm[v]=p+1; 
      vertex(G[v]);
    };  
    endShape();
  }


  void drawProjection(LOOP L) {
    stroke(cyan); 
    fill(cyan);
    for (int p=0; p<L.n; p++) {
      pt CP=closestProjection(L.P[p]); 
      show(L.P[p], CP); 
      show(CP, 1);
    }
  }

  void makeLoopOfClosestVerticesAndMarkTriangles(LOOP L) {
    resetMarkers();
    for (int p=0; p<L.n; p++) {
      closestProjectionMark(L.P[p]);
    };
  }

  pt closestProjectionMark(pt P) {
    float md=d(P, g(0));
    int cc=0; // corner of closest cell
    int type = 0; // type of closest projection: - = vertex, 1 = edge, 2 = triangle
    pt Q = P(); // closest point
    for (int c=0; c<nc; c++) if (d(P, g(c))<md) {
      Q.set(g(c)); 
      cc=c; 
      type=0; 
      md=d(P, g(c));
    } 
    for (int c=0; c<nc; c++) if (c<=o(c)) {
      float d = distPE(P, g(n(c)), g(p(c))); 
      if (d<md && projPonE(P, g(n(c)), g(p(c)))) {
        md=d; 
        cc=c; 
        type=1; 
        Q=CPonE(P, g(n(c)), g(p(c)));
      }
    } 
    if (onTriangles) 
      for (int t=0; t<nt; t++) {
        int c=3*t; 
        float d = distPtPlane(P, g(c), g(n(c)), g(p(c))); 
        if (d<md && projPonT(P, g(c), g(n(c)), g(p(c)))) {
          md=d; 
          cc=c; 
          type=2; 
          Q=CPonT(P, g(c), g(n(c)), g(p(c)));
        }
      } 
    if (type==2) tm[t(cc)]=1;
    if (type==1) {
      tm[t(cc)]=2; 
      tm[t(o(cc))]=2;
    }
    if (type==0) {
      tm[t(cc)]=3; 
      int c=s(cc); 
      while (c!=cc) {
        c=s(c); 
        tm[t(c)]=3;
      }
    }
    return Q;
  }

  void drawClosestProjections(LOOP L) {
    for (int p=0; p<L.n; p++) {
      drawLineToClosestProjection(L.P[p]);
    };
  }


  void drawLineToClosestProjection(pt P) {
    float md=d(P, g(0));
    int cc=0; // corner of closest cell
    int type = 0; // type of closest projection: - = vertex, 1 = edge, 2 = triangle
    pt Q = P(); // closest point
    for (int c=0; c<nc; c++) if (d(P, g(c))<md) {
      Q.set(g(c)); 
      cc=c; 
      type=0; 
      md=d(P, g(c));
    } 
    for (int c=0; c<nc; c++) if (c<=o(c)) {
      float d = distPE(P, g(n(c)), g(p(c))); 
      if (d<md && projPonE(P, g(n(c)), g(p(c)))) {
        md=d; 
        cc=c; 
        type=1; 
        Q=CPonE(P, g(n(c)), g(p(c)));
      }
    } 
    if (onTriangles) 
      for (int t=0; t<nt; t++) {
        int c=3*t; 
        float d = distPtPlane(P, g(c), g(n(c)), g(p(c))); 
        if (d<md && projPonT(P, g(c), g(n(c)), g(p(c)))) {
          md=d; 
          cc=c; 
          type=2; 
          Q=CPonT(P, g(c), g(n(c)), g(p(c)));
        }
      } 
    if (type==2) stroke(dred);   
    if (type==1) stroke(dgreen);  
    if (type==0) stroke(dblue);  
    show(P, Q);
  }

  pt closestProjection(pt P) {  // ************ closest projection of P on this mesh
    float md=d(P, G[0]);
    pt Q = P();
    int v=0; 
    for (int i=1; i<nv; i++) if (d(P, G[i])<md) {
      Q=G[i]; 
      md=d(P, G[i]);
    } 
    for (int c=0; c<nc; c++) if (c<=o(c)) {
      float d = abs(distPE(P, g(n(c)), g(p(c)))); 
      if (d<md && projPonE(P, g(n(c)), g(p(c)))) {
        md=d; 
        Q=CPonE(P, g(n(c)), g(p(c)));
      }
    } 
    for (int t=0; t<nt; t++) {
      int c=3*t; 
      float d = distPtPlane(P, g(c), g(n(c)), g(p(c))); 
      if (d<md && projPonT(P, g(c), g(n(c)), g(p(c)))) {
        md=d; 
        Q=CPonT(P, g(c), g(n(c)), g(p(c)));
      }
    } 
    return Q;
  }

  pt closestProjection(pt P, int k) { //closest projection on triangles marked as tm[t]==k
    float md=d(P, G[0]);
    pt Q = P();
    for (int c=0; c<nc; c++) if (tm[t(c)]==k) if (d(P, g(c))<md) {
      Q=g(c); 
      md=d(P, g(c));
    } 
    for (int c=0; c<nc; c++)  if (tm[t(c)]==k) if (c<=o(c)) {
      float d = distPE(P, g(n(c)), g(p(c))); 
      if (d<md && projPonE(P, g(n(c)), g(p(c)))) {
        md=d; 
        Q=CPonE(P, g(n(c)), g(p(c)));
      }
    } 
    for (int t=0; t<nt; t++)  if (tm[t]==k) {
      int c=3*t; 
      float d = distPtPlane(P, g(c), g(n(c)), g(p(c))); 
      if (d<md && projPonT(P, g(c), g(n(c)), g(p(c)))) {
        md=d; 
        Q=CPonT(P, g(c), g(n(c)), g(p(c)));
      }
    } 
    return Q;
  }


  int closestVertexNextCorner(pt P, int k) { //closest projection on triangles marked as tm[t]==k
    int bc=0; // best corner index
    float md=d(P, g(p(bc)));
    for (int c=0; c<nc; c++) if (tm[t(c)]==k && tm[t(o(c))]!=k) if (d(P, g(p(c)))<md) {
      bc=c; 
      md=d(P, g(p(c)));
    } 
    return bc;
  }

  int closestVertex(pt P, int k) { //closest projection on triangles marked as tm[t]==k
    int v=0;
    float md=d(P, G[v]);
    for (int c=0; c<nc; c++) if (tm[t(c)]==k) if (d(P, g(c))<md) {
      v=v(c); 
      md=d(P, g(c));
    } 
    return v;
  }

  int nextAlongSplit(int c, int mk) {
    c=p(c);
    if (tm[t(o(c))]==mk) return c;
    c=p(o(c));
    while (tm[t (o (c))]!=mk) c=p(o(c));
    return c;
  }  

  int prevAlongSplit(int c, int mk) {
    c=n(c);
    if (tm[t(o(c))]==mk) return c;
    c=n(o(c));
    while (tm[t (o (c))]!=mk) c=n(o(n(c)));
    return c;
  }  

  float flattenStrip() { // flattens a particular triangle strip LLRLRLRLR
    float [] x = new float [nv]; 
    float [] y = new float [nv]; 
    for (int c=2; c<nc; c+=3) {
      pt A = g(n(c)); 
      pt B = g(p(c)); 
      pt C = g(c);
      vec I = U(A, B); 
      vec K=U(triNormal(t(o(c))));  
      vec J=N(I, K); 
      x[v(c)]=d(I, V(A, C)); 
      y[v(c)]=d(J, V(A, C));
    }
    float d=d(G[v(0)], G[v(1)]);
    G[v(0)]=P(0, 0, 0); 
    G[v(1)]=P(d, 0, 0);
    for (int c=2; c<nc; c+=3) {
      pt A = g(n(c)); 
      pt B = g(p(c)); 
      vec I = U(A, B); 
      vec K=V(0, 0, -1);  
      vec J=N(I, K);
      G[v(c)].set(P(A, x[v(c)], I, y[v(c)], J));
    }
    float minx=G[0].x, miny=G[0].y, maxx=G[0].x, maxy=G[0].y;
    for (int i=1; i<nv; i++) { 
      minx=min(minx, G[i].x); 
      miny=min(miny, G[i].y); 
      maxx=max(maxx, G[i].x); 
      maxy=max(maxy, G[i].y);
    }
    float s=min(width/(maxx-minx), height/(maxy-miny))*.8;
    float cx=(maxx+minx)/2; 
    float cy=(maxy+miny)/2;
    for (int i=0; i<nv; i++) { 
      G[i].x=(G[i].x-cx)*s; 
      G[i].y=(G[i].y-cy)*s;
    }
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
  
  void onMouseDragged() {
    m_userInputHandler.onMouseDragged();
  }
  
  void onMouseMoved() {
    m_userInputHandler.onMouseMoved();
  }

  void interactSelectedMesh() {
    m_userInputHandler.interactSelectedMesh();
  }
} // ==== END OF MESH CLASS

vec labelD=new vec(-4, +4, 12);           // offset vector for drawing labels  

float distPE (pt P, pt A, pt B) {
  return n(N(V(A, B), V(A, P)))/d(A, B);
} // distance from P to edge(A,B)
float distPtPlane (pt P, pt A, pt B, pt C) {
  vec N = U(N(V(A, B), V(A, C))); 
  return abs(d(V(A, P), N));
} // distance from P to plane(A,B,C)
Boolean projPonE (pt P, pt A, pt B) {
  return d(V(A, B), V(A, P))>0 && d(V(B, A), V(B, P))>0;
} // P projects onto the interior of edge(A,B)
Boolean projPonT (pt P, pt A, pt B, pt C) {
  vec N = U(N(V(A, B), V(A, C))); 
  return m(N, V(A, B), V(A, P))>0 && m(N, V(B, C), V(B, P))>0 && m(N, V(C, A), V(C, P))>0 ;
} // P projects onto the interior of edge(A,B)
pt CPonE (pt P, pt A, pt B) {
  return P(A, d(V(A, B), V(A, P))/d(V(A, B), V(A, B)), V(A, B));
}
pt CPonT (pt P, pt A, pt B, pt C) {
  vec N = U(N(V(A, B), V(A, C))); 
  return P(P, -d(V(A, P), N), N);
}

