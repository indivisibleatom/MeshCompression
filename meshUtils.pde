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
    
    //display modes
    if(key=='=') translucent=!translucent;
    if(key=='g') m_mesh.flatShading=!m_mesh.flatShading;
    if(key=='-') {m_mesh.showEdges=!m_mesh.showEdges; if (m_mesh.showEdges) shrunk=1; else shrunk=0;}
    if(key=='.') showVertices=!showVertices;
    if(key=='|') showNormals=!showNormals;
   
    // mesh edits, smoothing, refinement
    if(key=='b') {pickBack=true; translucent=true; println("picking on the back");}
    if(key=='f') {pickBack=false; translucent=false; println("picking on the front");}
    if(key=='/') m_mesh.flip(); // clip edge opposite to M.cc
    if(key=='F') {m_mesh.smoothen(); m_mesh.normals();}
    if(key=='Y') {m_mesh.refine(); m_mesh.makeAllVisible();}
    if(key=='d') {m_mesh.clean();}
    if(key=='o') m_mesh.offset();
    if(key=='(') {showSilhouette=!showSilhouette;}

    if(key=='u') {m_mesh.resetMarkers(); m_mesh.makeAllVisible(); } // undo deletions
    if(key=='L') ;
    if(key=='B') showBack=!showBack;
    if(key=='R') ;   
    if(key=='#') m_mesh.volume(); 
    if(key=='_') m_mesh.surface(); 
    if(key==',') 

    //Drawing options
    if (key == 'Q') { m_mesh.getDrawingState().m_fShowVertices = !m_mesh.getDrawingState().m_fShowVertices; }
    if (key == 'q') { m_mesh.getDrawingState().m_fShowCorners = !m_mesh.getDrawingState().m_fShowCorners; }
  }
}

class IslandMeshUserInputHandler extends MeshUserInputHandler
{
  private IslandMesh m_mesh;
  
  IslandMeshUserInputHandler( IslandMesh m )
  {
    super( m );
    m_mesh = m;
  }
  
  public void onKeyPress()
  {
    super.onKeyPress();
    if (key=='1') {g_stepWiseRingExpander.setStepMode(false); m_mesh.showEdges = true; R = new RingExpander(m_mesh, (int) random(m_mesh.nt * 3)); m_mesh.setResult(R.completeRingExpanderRecursive()); m_mesh.showRingExpanderCorners(); }
    if (key=='2') {g_stepWiseRingExpander.setStepMode(false); m_mesh.formIslands(-1);}
    if (key =='3') { m_mesh.colorTriangles(); }
    if (key=='4') { m_mesh.toggleMorphingState(); }
    if (key=='6') {EgdeBreakerCompress e = new EgdeBreakerCompress(m_mesh); e.initCompression();}
    if (key=='p') {m_mesh.populateBaseG();}
    if (key=='i') {m_mesh.connectMesh();}
    if (key=='y') {g_viewportManager.registerMeshToViewport( baseMesh, 1 );}
    //if (key=='`') {CuboidConstructor c = new CuboidConstructor(8, 8, 20, 30); c.constructMesh(); M =  c.getMesh();}
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
    if (key=='I') {m_mesh.advanceOnIslandEdge();} //Advance on the beach edges of an island
  }
}
