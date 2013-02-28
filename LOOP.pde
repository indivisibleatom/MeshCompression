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

 

  
  
