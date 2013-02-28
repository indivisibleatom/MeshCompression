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

