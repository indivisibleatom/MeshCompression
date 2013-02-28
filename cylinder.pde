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

