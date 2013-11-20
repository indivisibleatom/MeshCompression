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
    if(key=='S') {m_mesh.cc = m_mesh.s(m_mesh.cc); print("Current corner " + m_mesh.cc);}
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
    if (key == '-') { m_mesh.getDrawingState().m_fShowEdges=!m_mesh.getDrawingState().m_fShowEdges; if (m_mesh.getDrawingState().m_fShowEdges) m_mesh.getDrawingState().m_shrunk=1; else m_mesh.getDrawingState().m_shrunk=0; }

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
       if (keyPressed&&key=='m')
       {
         m_mesh.pickc(Pick()); // sets M.sc to the closest corner in M from the pick point
         m_mesh.onExpandIsland();
       }
    }
    
    //Debug
    if (pressed) {
    if (keyPressed&&key=='y')
       { 
         m_mesh.pickc(Pick()); // sets M.sc to the closest corner in M from the pick point
         m_mesh.beforeStepWiseExpand();
       }
    }
   
    super.interactSelectedMesh();
  }
  
  public void onKeyPress()
  {
    super.onKeyPress();
    if(keyPressed&&key == 'G') {
      m_mesh.onStepWiseExpand();
    }
  }
}

class IslandMeshUserInputHandler extends MeshUserInputHandler
{
  private IslandMesh m_mesh;
  private boolean m_fKeyEntryMode;
  private String m_command;
  
  IslandMeshUserInputHandler( IslandMesh m )
  {
    super( m );
    m_mesh = m;
    m_fKeyEntryMode = false;
  }
  
  private int getNumberFromCommand( String command, int indexBegin )
  {
    String desiredPart = command.substring( indexBegin );
    return Integer.parseInt( desiredPart );
  }
  
  private void interpretCommand( String command )
  {
    switch( command.charAt(0) )
    {
      case 'z': m_mesh.selectIsland(getNumberFromCommand(command, 1));
        break;
      case 'c': m_mesh.cc = getNumberFromCommand(command, 1);
        break;
    }
  }
  
  public void onKeyPress()
  {
    super.onKeyPress();
    if (key==':')
    {
      m_fKeyEntryMode = true;
      m_command = "";
    }
    else if (m_fKeyEntryMode)
    {
      if (key == ENTER || key == RETURN)
      {
        interpretCommand( m_command );
        m_fKeyEntryMode = false;
      }
      else
      {
        m_command += key;
      }
    }
    else
    {
      /*if (key=='1') 
      {
        g_stepWiseRingExpander.setStepMode(false); 
        m_mesh.showEdges = true; 
        for (int i = 667; i < 3*m_mesh.nt; i++) 
        {
          R = new RingExpander(m_mesh, i);
          m_mesh.setResult(R.completeRingExpanderRecursive()); 
          m_mesh.showRingExpanderCorners();
          g_stepWiseRingExpander.setStepMode(false); 
          m_mesh.formIslands(-1);
          m_mesh.colorTriangles();
         //if (m_baseMesh != null)
         //{
         //  m_viewportManager.unregisterMeshFromViewport( m_baseMesh, 1 );
         //}
         BaseMesh baseMesh = m_mesh.populateBaseG(); 
         m_mesh.numberVerticesOfIslandsAndCreateStream();
         m_mesh.connectMesh(); 
         baseMesh.computeCForV();
         baseMesh.computeBox(); 
       }
       //m_viewportManager.registerMeshToViewport( m_baseMesh, 1 ); 
      }*/
      if (key=='1') {g_stepWiseRingExpander.setStepMode(false); m_mesh.getDrawingState().m_fShowEdges = true; R = new RingExpander(m_mesh, (int) random(m_mesh.nt * 3)); m_mesh.setResult(R.completeRingExpanderRecursive()); m_mesh.showRingExpanderCorners(); }
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
      if (key=='5') {g_stepWiseRingExpander.setStepMode(true); m_mesh.getDrawingState().m_fShowEdges = true; if (R == null) { R = new RingExpander(m_mesh, (int)random(m_mesh.nt * 3)); } R.ringExpanderStepRecursive();} //Press 4 to trigger step by step ring expander
    }
  }
}
