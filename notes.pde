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
