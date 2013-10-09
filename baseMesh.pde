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

