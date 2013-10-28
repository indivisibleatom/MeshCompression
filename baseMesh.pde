class BaseMesh extends Mesh
{
  int m_expandedIsland;
  int[] m_hooks = new int [3*maxnt];               // V table (triangle/vertex indices)
  int[] m_expansionIndex = new int [numIslands];      // is an island expanded?
  IslandExpansionManager m_expansionManager;
  
  int m_beachEdgesToExpand = 0;
  int m_beachEdgesExpanded = 0;
  
  BaseMesh()
  {
    m_userInputHandler = new BaseMeshUserInputHandler(this);
    m_expandedIsland = -1;
    m_expansionManager = null;
    
    for (int i = 0; i < numIslands; i++)
    {
      m_expansionIndex[i] = -1;
    }
  }
  
  void pickc (pt X) {
   int origCC = cc;
    super.pickc(X);
    if ( origCC != cc && DEBUG && DEBUG_MODE >= LOW ) { print(" Hook " + m_hooks[cc] + "\n" ); }
  }

  
  void addTriangle(int island1, int island2, int island3, int hook1, int hook2, int hook3)
  {
    m_hooks[nc] = hook1;
    m_hooks[nc+1] = hook2;
    m_hooks[nc+2] = hook3;
    super.addTriangle(island1, island2, island3);
  }
  
  int getTriangle(int island1, int island2, int island3, int hook1, int hook2, int hook3)
  {
    int []islands = {island1, island2, island3};
    int []hooks = {hook1, hook2, hook3};
    
    int lowestIndex = island1 <= island2? 0 : 1;
    lowestIndex = islands[lowestIndex] <= island3? lowestIndex : 2;
    
    int triangleRet = -1;
    boolean fTriangleFound = false;
    
    for (int i = 0; i < nt; i++)
    {
      fTriangleFound = true;
      for (int j = 0; j < 3; j++)
      {
        if ( v(3*i + j) == islands[(lowestIndex+j)%3] && m_hooks[3*i + j] == hooks[(lowestIndex+j)%3] )
          continue;
        fTriangleFound = false;
      }
      if (fTriangleFound)
        return i;
    }
    return -1;
  }
  
  void setExpansionManager( IslandExpansionManager manager )
  {
    m_expansionManager = manager;
  }
  
  private int addIslandGeometry( int islandNumber )
  {
    m_expansionIndex[ islandNumber ] = nv;
    pt[] geometry = m_expansionManager.getStream( islandNumber ).getG();
    int[] r = m_expansionManager.getStream( islandNumber ).getR();
    for (int i = 0; i < geometry.length; i++)
    {
      addVertex( geometry[i] );
    }
    
    for (int i = 0; i < geometry.length; i++)
    {
      addTriangle( m_expansionIndex[ islandNumber ] + i, m_expansionIndex[ islandNumber ] + (i + 1) % geometry.length , m_expansionIndex[ islandNumber ] + r[i] );
      tm[nt-1] = ISLAND;
      tm[ islandNumber ] = 0;
    }
    for (int i = 0; i < 3*nt; i++)
    {
      if (G[v(i)] == null)
      {
        print( i / 3 + " " );
      }
    }
    return geometry.length;
  }
  
  void beforeStepWiseExpand()
  {
    m_beachEdgesToExpand = 0;
    m_beachEdgesExpanded = 0;
  }
  
  void onStepWiseExpand()
  {
    /*if ( m_expansionManager != null )
    {
      int vertexNumber = v(cc);
      if ( vertexNumber < numIslands ) //If an island
      {
        if ( m_expansionIndex[vertexNumber] == -1 ) //Is not expanded
        {
          addIslandGeometry( vertexNumber );
          int initCorner = cc;
          int currentCorner = initCorner;
          int nextS = -1;
          do
          {
            nextS = s( currentCorner );
            if ( v(p(currentCorner)) < numIslands && m_expansionIndex[ v(p(currentCorner)) ]  == -1 ) //The other island forming the straits is not expanded and is not a water vertex
            {
              walkAndExpand( m_hooks[currentCorner], m_hooks[nextS], vertexNumber, v(p(currentCorner)) );
              visible[t(currentCorner)] = false;
              addTriangle( m_expansionIndex[vertexNumber] + m_hooks[currentCorner], v(n(currentCorner)), v(p(currentCorner)) );
            }
            else if ( v(p(currentCorner)) >= numIslands ) //Water vertex in base mesh. TODO msati3: Get the condition correct
            {
              walkAndExpand( m_hooks[currentCorner], m_hooks[nextS], vertexNumber, v(p(currentCorner)) );
              visible[t(currentCorner)] = false;
              addTriangle( m_expansionIndex[vertexNumber] + m_hooks[currentCorner], v(n(currentCorner)), v(p(currentCorner)) );
            }
            currentCorner = nextS;
          } while (currentCorner != initCorner);
        }
      }
    }*/
  }
  
  void onExpandIsland()
  {
    m_beachEdgesToExpand = -1;
    m_beachEdgesExpanded = -1;

    if ( m_expansionManager != null )
    {
      int vertexNumber = v(cc);
      if ( vertexNumber < numIslands ) //If an island
      {
        if ( m_expansionIndex[vertexNumber] == -1 ) //Is not expanded
        {
          int maxVertexNum = addIslandGeometry( vertexNumber ); //Expand the island itself
          int initCorner = cc;
          int currentCorner = initCorner;
          int nextS = -1;
          do
          {
            nextS = s( currentCorner );
            if ( v(p(currentCorner)) < numIslands ) //The other island forming the straits is not a water vertex
            {
              if (m_expansionIndex[ v(p(currentCorner)) ]  == -1) //Not expanded
              {
                walkAndExpand( m_hooks[currentCorner], m_hooks[nextS], vertexNumber, v(p(currentCorner)), maxVertexNum);
                print ("Removing " + currentCorner );
                visible[t(currentCorner)] = false;
                addTriangle( m_expansionIndex[vertexNumber] + m_hooks[currentCorner], v(n(currentCorner)), v(p(currentCorner)) );
              }
              else //The other island has been expanded. Fetch the expansion from the corner
              {
              }
            }
            else if ( v(p(currentCorner)) >= numIslands ) //Water vertex in base mesh. TODO msati3: Get the condition correct
            {
              walkAndExpand( m_hooks[currentCorner], m_hooks[nextS], vertexNumber, v(p(currentCorner)), maxVertexNum);
              print ("Removing " + currentCorner );
              visible[t(currentCorner)] = false;
              addTriangle( m_expansionIndex[vertexNumber] + m_hooks[currentCorner], v(n(currentCorner)), v(p(currentCorner)) );
            }
            currentCorner = nextS;
          } while (currentCorner != initCorner);
        }
      }
    }
  }
  
  private void walkAndExpand(int startHook, int endHook, int currentIsland, int nextIsland, int maxVertexNum)
  {
    int start = startHook;
    int end = endHook;
    for (int i = start; start <= end ? (i < end) : (i < end + maxVertexNum); i++)
    {
      addTriangle( m_expansionIndex[currentIsland] + ((i + 1) % maxVertexNum), m_expansionIndex[currentIsland] + (i%maxVertexNum), nextIsland );

      m_beachEdgesExpanded++;
      
      if ( m_beachEdgesToExpand != -1 && m_beachEdgesToExpand <= m_beachEdgesExpanded )
      {
        m_beachEdgesToExpand++;
        return;
      }
    }
  }
  
  void draw()
  {
    super.draw();
  }  
}

