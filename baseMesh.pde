class STypeTriangleStateV
{
  private int m_v1;
  private int m_v2;
  
  public STypeTriangleStateV( int v1, int v2 )
  {
    m_v1 = v1;
    m_v2 = v2;
  }
  
  public int v1() { return m_v1; }
  public int v2() { return m_v2; }
}

class SOffsetState
{
  private int m_e;
  private int m_s;
  
  public SOffsetState( int e, int s )
  {
    m_e = e;
    m_s = s;
  }
  
  public int e() { return m_e; }
  public int s() { return m_s; }
}

class ChannelExpansion
{
  ChannelExpansion( ArrayList<Boolean> expansion )
  {
    m_expansion = expansion;
  }
  
  ArrayList<Boolean> expansion() { return m_expansion; }
  
  private ArrayList<Boolean> m_expansion;
}

class BaseMesh extends Mesh
{
  int m_expandedIsland;
  int[] m_hooks = new int [3*maxnt];               // V table (triangle/vertex indices) .. TODO msati3: Move this to outside the base mesh datastructure
  int[] m_expansionIndex = new int [numIslands];   // is an island expanded?
  int[] m_shiftedCorners = new int[3*maxnt];       // store the "shifted" corners for each junction triangle at each time one of the incident islands is expanded
  ChannelExpansion[] m_triangleStrips = new ChannelExpansion[3*maxnt];
  IslandExpansionManager m_expansionManager;
  
  int m_beachEdgesToExpand = 0;
  int m_beachEdgesExpanded = 0;
  int m_vertexNumberToExpandStepWise = 0;
  int m_cornerNumberToExpandStepWise = 0;
  
  int m_initSize;
  
  BaseMesh()
  {
    m_userInputHandler = new BaseMeshUserInputHandler(this);
    m_expandedIsland = -1;
    m_expansionManager = null;
    
    for (int i = 0; i < numIslands; i++)
    {
      m_expansionIndex[i] = -1;
    }
    
    for (int i = 0; i < 3*maxnt; i++)
    {
      m_shiftedCorners[i] = -1;
      m_triangleStrips[i] = null;
    }
  }
  
  void setInitSize( int nv )
  {
    m_initSize = nv;
  }
  
  void pickc (pt X) {
    int origCC = cc;
    super.pickc(X);
    if ( origCC != cc && DEBUG && DEBUG_MODE >= LOW )
    {
        print(" Hook " + m_hooks[cc] + "\n" ); 
        if ( m_triangleStrips[cc] != null )
        {
          print(" Triangle strips: ");
          for (int i = 0; i < m_triangleStrips[cc].expansion().size(); i++)
          {
            print( m_triangleStrips[cc].expansion().get(i) + " ");
          }
          print("\n");
        }
    }
  }
  
  void addTriangle(int island1, int island2, int island3, int hook1, int hook2, int hook3)
  {
    m_hooks[nc] = hook1;
    m_hooks[nc+1] = hook2;
    m_hooks[nc+2] = hook3;
    super.addTriangle(island1, island2, island3);
    if ( ( (island1 >= numIslands) || (island2 >= numIslands) || (island3 >= numIslands) ) )
    {
      tm[nt-1] = ISOLATEDWATER;
    }
    else
    {
      tm[nt-1] = JUNCTION;
    }
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
  
  //Adds a triangle in mesh, with vertices offset by base offset
  private void addTriangleWithOffset(int baseOffset, int v1, int v2, int v3, int type)
  {
    if (DEBUG && DEBUG_MODE >= VERBOSE)
    {
      print("Adding triangle withoffset " + (baseOffset + v1) + " " + (baseOffset + v2) + " " + (baseOffset + v3) + "\n");
    }
    addTriangle( baseOffset + v1, baseOffset + v2, baseOffset + v3 );
    tm[nt-1] = type;
  }
  
  private int getNext( int v )
  {
    return (v+1)%VERTICES_PER_ISLAND;
  }
  
  private int getPrev( int v )
  {
    return (VERTICES_PER_ISLAND+v-1)%VERTICES_PER_ISLAND;
  }
  
  //Uses the clers string of island expansion to add to the V table of the base mesh, from the base offset
  private void decompressConnectivityForIsland( String clersString, int baseOffset )
  {
    //Preprocess
    Stack<SOffsetState> sOffsetState = new Stack<SOffsetState>();

    int[] sOffsets = new int[VERTICES_PER_ISLAND];
    for (int i = 0; i < VERTICES_PER_ISLAND; i++)
    {
      sOffsets[i] = -1;
    }

    int e = 0;
    int s = 0;
    int d = 0;
    for (int i = 0; i < clersString.length(); i++)
    {
      char ch = clersString.charAt(i);
      switch (ch)
      {
        case 's': e-=1;
                  sOffsetState.push(new SOffsetState(e,s));
                  s+=1;
                  d+=1;
                  break;
        case 'l':
        case 'r': e+=1;
                  break;
        case 'e': e+=3;
                  d-=1;
                  if ( d < 0 )
                  {
                    if ( i != clersString.length() - 1 )
                    {
                      if ( DEBUG && DEBUG_MODE >= LOW )
                      {
                        print("Decompress connectivity for island - negative d without ending of clers string!!\n");
                      }
                    }
                  }
                  else
                  {
                    SOffsetState state = sOffsetState.pop();
                    sOffsets[state.s()] = e - state.e() - 2;
                  }
                  break;
      }
    }
    
    //Generate
    int currentV1 = 0;
    int currentV2 = VERTICES_PER_ISLAND - 1;
    int currentVOther = -1;
    Stack<STypeTriangleStateV> sState = new Stack<STypeTriangleStateV>();
    s = 0;
    
    for (int i = 0; i < clersString.length(); i++)
    {
      char ch = clersString.charAt(i);    
      if ( DEBUG && DEBUG_MODE >= VERBOSE )
      {
        print("Decompress connectivity for island - clers character " + ch + "\n");
      }
      switch (ch)
      {
        case 'l': addTriangleWithOffset( baseOffset, currentV1, getNext(currentV1), currentV2, ISLAND );
                  currentV1 = getNext(currentV1); 
                  break;
        case 'r': addTriangleWithOffset( baseOffset, currentV1, getPrev(currentV2), currentV2, ISLAND );
                  currentV2 = getPrev(currentV2);
                  break;
        case 'e': addTriangleWithOffset( baseOffset, currentV1, getNext(currentV1), currentV2, ISLAND );
                  if ( sState.isEmpty() )
                  {
                    if ( i != clersString.length() - 1 )
                    {
                      if ( DEBUG && DEBUG_MODE >= LOW )
                      {
                        print("Decompress connectivity for island - e encountered when the s stack is empty!!\n");
                      }
                    }
                  }
                  else
                  {
                    STypeTriangleStateV state = sState.pop();
                    currentV1 = state.v1();
                    currentV2 = state.v2();
                  }
                  break;                    
        case 's': //First L and then R
                  int offset = sOffsets[s];
                  s++;
                  print("Offset " + offset + "\n");
                  addTriangleWithOffset( baseOffset, currentV1, currentV1 + offset + 1, currentV2, ISLAND );
                  int otherV1 = currentV1 + offset + 1;
                  int otherV2 = currentV2;
                  currentV2 = currentV1 + offset + 1;
                  sState.push( new STypeTriangleStateV( otherV1, otherV2 ) );
                  break;
      }
    }
  }
  
    //Uses the clers string of lagoon expansion to add to the V table of the base mesh, from the base offset
  private void decompressConnectivityForLagoon( int vertex1, int vertex2, String clersString, int baseOffset )
  {
    //Preprocess
    Stack<SOffsetState> sOffsetState = new Stack<SOffsetState>();

    int[] sOffsets = new int[VERTICES_PER_ISLAND];
    for (int i = 0; i < VERTICES_PER_ISLAND; i++)
    {
      sOffsets[i] = -1;
    }

    int e = 0;
    int s = 0;
    int d = 0;
    for (int i = 0; i < clersString.length(); i++)
    {
      char ch = clersString.charAt(i);
      switch (ch)
      {
        case 's': e-=1;
                  sOffsetState.push(new SOffsetState(e,s));
                  s+=1;
                  d+=1;
                  break;
        case 'l':
        case 'r': e+=1;
                  break;
        case 'e': e+=3;
                  d-=1;
                  if ( d < 0 )
                  {
                    if ( i != clersString.length() - 1 )
                    {
                      if ( DEBUG && DEBUG_MODE >= LOW )
                      {
                        print("Decompress connectivity for lagoon - negative d without ending of clers string!!\n");
                      }
                    }
                  }
                  else
                  {
                    SOffsetState state = sOffsetState.pop();
                    sOffsets[state.s()] = e - state.e() - 2;
                  }
                  break;
      }
    }
    
    //Generate
    int currentV1 = vertex1;
    int currentV2 = vertex2;
    int currentVOther = -1;
    Stack<STypeTriangleStateV> sState = new Stack<STypeTriangleStateV>();
    s = 0;
    
    for (int i = 0; i < clersString.length(); i++)
    {
      char ch = clersString.charAt(i);    
      if ( DEBUG && DEBUG_MODE >= LOW )
      {
        print("Decompress connectivity for lagoon - clers character " + ch + "\n");
      }
      switch (ch)
      {
        case 'l': addTriangleWithOffset( baseOffset, currentV1, currentV2, getPrev(currentV2), LAGOON );
                  currentV2 = getPrev(currentV2); 
                  break;
        case 'r': addTriangleWithOffset( baseOffset, currentV1, currentV2, getNext(currentV1), LAGOON );
                  currentV1 = getNext(currentV1);
                  break;
        case 'e': addTriangleWithOffset( baseOffset, currentV1, currentV2, getPrev(currentV2), LAGOON );
                  if ( sState.isEmpty() )
                  {
                    if ( i != clersString.length() - 1 )
                    {
                      if ( DEBUG && DEBUG_MODE >= LOW )
                      {
                        print("Decompress connectivity for lagoon - e encountered when the s stack is empty!!\n");
                      }
                    }
                  }
                  else
                  {
                    STypeTriangleStateV state = sState.pop();
                    currentV1 = state.v1();
                    currentV2 = state.v2();
                  }
                  break;                    
        case 's': //First R and then L
                  int offset = sOffsets[s];
                  s++;
                  addTriangleWithOffset( baseOffset, currentV1, currentV2, (currentV1 + offset + 1) % VERTICES_PER_ISLAND, LAGOON );
                  int otherV1 = (currentV1 + offset + 1) % VERTICES_PER_ISLAND;
                  int otherV2 = currentV2;
                  currentV2 = (currentV1 + offset + 1) % VERTICES_PER_ISLAND;
                  sState.push( new STypeTriangleStateV( otherV1, otherV2 ) );
                  break;
      }
    }
  }
  
  private int addIslandGeometry( int islandNumber )
  {
    m_expansionIndex[ islandNumber ] = nv;
    IslandExpansionStream islandExpansionStream = m_expansionManager.getStream( islandNumber );
    pt[] geometry = islandExpansionStream.getG();
    String clersString = m_expansionManager.getStream( islandNumber ).getClersString();
    for (int i = 0; i < geometry.length; i++)
    {
      addVertex( geometry[i] );
    }
    
    decompressConnectivityForIsland( clersString, m_expansionIndex[ islandNumber ] );
    ArrayList<LagoonExpansionStream> lagoonExpansionStreamList = islandExpansionStream.getLagoonExpansionStreamList();
    for (int i = 0; i < lagoonExpansionStreamList.size(); i++)
    {
      int v1 = lagoonExpansionStreamList.get(i).vertex1();
      int v2 = lagoonExpansionStreamList.get(i).vertex2();
      clersString = lagoonExpansionStreamList.get(i).getClersString();
      decompressConnectivityForLagoon( v1, v2, clersString, m_expansionIndex[ islandNumber ] );
    }
    
    return geometry.length;
  }
  
  void beforeStepWiseExpand()
  {
    m_beachEdgesToExpand = 0;
    m_beachEdgesExpanded = 0;
    m_vertexNumberToExpandStepWise = v(cc);
    m_cornerNumberToExpandStepWise = getCorrectCorner(cc);
  }
  
  private int getCorrectCorner(int cc)
  {
    for (int i = 0; i < 3*nt; i++)
    {
      if ( m_shiftedCorners[i] == cc )
      {
        return i;
      }
    }
    return cc;
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
          int initCorner = getCorrectCorner(cc);
          int currentCorner = initCorner;
          int nextS = -1;
          do
          {
            nextS = s( currentCorner );
            if ( v(p(currentCorner)) < numIslands ) //The other island forming the straits is not a water vertex
            {
              if (m_expansionIndex[ v(p(currentCorner)) ]  == -1) //Not expanded
              {
                if ( m_shiftedCorners[currentCorner] == -1 )
                {
                  visible[t(currentCorner)] = false;
                }
                else
                {
                  visible[t(m_shiftedCorners[currentCorner])] = false;
                }
                int nCorner = m_shiftedCorners[currentCorner] == -1 ? n(currentCorner) : n(m_shiftedCorners[currentCorner]);
                int pCorner = m_shiftedCorners[currentCorner] == -1 ? p(currentCorner) : p(m_shiftedCorners[currentCorner]);
                addTriangle( m_expansionIndex[vertexNumber] + m_hooks[currentCorner], v(nCorner), v(pCorner) );
                m_shiftedCorners[currentCorner] = nc - 3;
                m_shiftedCorners[n(currentCorner)] = nc - 2;
                m_shiftedCorners[p(currentCorner)] = nc - 1;
                tm[t(m_shiftedCorners[currentCorner])] = tm[t(currentCorner)];
                walkAndExpand( m_hooks[currentCorner], m_hooks[nextS], vertexNumber, v(p(currentCorner)), maxVertexNum);
              }
              
              else //The other island has been expanded. Fetch the expansion from the corner
              {
                if ( m_shiftedCorners[currentCorner] == -1 )
                {
                  visible[t(currentCorner)] = false;
                }
                else
                {
                  visible[t(m_shiftedCorners[currentCorner])] = false;
                }
                if ( m_shiftedCorners[currentCorner] == -1 )
                {
                  addTriangle( m_expansionIndex[vertexNumber] + m_hooks[currentCorner], v(n(currentCorner)), v(p(currentCorner)) );
                  m_shiftedCorners[currentCorner] = nc - 3;
                  m_shiftedCorners[n(currentCorner)] = nc - 2;
                  m_shiftedCorners[p(currentCorner)] = nc - 1;
                  tm[t(m_shiftedCorners[currentCorner])] = tm[t(currentCorner)];
                }
                else
                {
                  addTriangle( m_expansionIndex[vertexNumber] + m_hooks[currentCorner], v(n(m_shiftedCorners[currentCorner])), v(p(m_shiftedCorners[currentCorner])) );
                  m_shiftedCorners[currentCorner] = nc - 3;
                  m_shiftedCorners[n(currentCorner)] = nc - 2;
                  m_shiftedCorners[p(currentCorner)] = nc - 1;
                  tm[t(m_shiftedCorners[currentCorner])] = tm[t(currentCorner)];
                }

                ArrayList<Boolean> triangleStripList = m_triangleStrips[ n(currentCorner) ].expansion();
                boolean flip = false;
                if ( v(p(currentCorner)) > v(currentCorner ) ) //If the current island number is less than the other island number, no need to invert triangle strip
                {
                  flip = true;
                }
                walkAndExpandBoth( m_hooks[currentCorner], m_hooks[nextS], vertexNumber, maxVertexNum, m_hooks[p(currentCorner)], m_hooks[u(p(currentCorner))], v(p(currentCorner)), triangleStripList, flip );
              }
            }
            else if ( v(p(currentCorner)) >= numIslands && v(p(currentCorner)) < m_initSize) //Water vertex in base mesh. TODO msati3: Get the condition correct. Correct code
            {
              visible[t(currentCorner)] = false;
              addTriangle( m_expansionIndex[vertexNumber] + m_hooks[currentCorner], v(n(currentCorner)), v(p(currentCorner)) );
              tm[nt-1] = tm[t(currentCorner)];
              m_shiftedCorners[currentCorner] = nc - 3;
              m_shiftedCorners[n(currentCorner)] = nc - 2;
              m_shiftedCorners[p(currentCorner)] = nc - 1;
              walkAndExpand( m_hooks[currentCorner], m_hooks[nextS], vertexNumber, v(p(currentCorner)), maxVertexNum);
            }
            else
            {
            }
            currentCorner = nextS;
          } while (currentCorner != initCorner);
        }
      }
    }
  }
  
  void onStepWiseExpand()
  {
    m_beachEdgesExpanded = 0;
    if ( m_expansionManager != null )
    {
      int vertexNumber = m_vertexNumberToExpandStepWise;
      int initCorner = m_cornerNumberToExpandStepWise;
      if ( vertexNumber < numIslands ) //If an island
      {
        //if ( m_expansionIndex[vertexNumber] == -1 ) //Is not expanded
        {
          int maxVertexNum = addIslandGeometry( vertexNumber ); //Expand the island itself
          int currentCorner = initCorner;
          int nextS = -1;
          do
          {
            print( "Current corner " + currentCorner + " init corner " + initCorner + " next corner " + s(currentCorner) + "\n" );
            nextS = s( currentCorner );
            if ( v(p(currentCorner)) < numIslands ) //The other island forming the straits is not a water vertex
            {
              if (m_expansionIndex[ v(p(currentCorner)) ]  == -1) //Not expanded
              {
                if ( m_beachEdgesExpanded == m_beachEdgesToExpand )
                {
                  if ( m_shiftedCorners[currentCorner] == -1 )
                  {
                    visible[t(currentCorner)] = false;
                  }
                  else
                  {
                    visible[t(m_shiftedCorners[currentCorner])] = false;
                  }
                }
                m_beachEdgesExpanded++;
                if ( m_beachEdgesExpanded == m_beachEdgesToExpand )
                {
                  int nCorner = m_shiftedCorners[currentCorner] == -1 ? n(currentCorner) : n(m_shiftedCorners[currentCorner]);
                  int pCorner = m_shiftedCorners[currentCorner] == -1 ? p(currentCorner) : p(m_shiftedCorners[currentCorner]);
                  addTriangle( m_expansionIndex[vertexNumber] + m_hooks[currentCorner], v(nCorner), v(pCorner) );
                  m_shiftedCorners[currentCorner] = nc - 3;
                  m_shiftedCorners[n(currentCorner)] = nc - 2;
                  m_shiftedCorners[p(currentCorner)] = nc - 1;
                  tm[t(m_shiftedCorners[currentCorner])] = tm[t(currentCorner)];
                }
                m_beachEdgesExpanded++;
                walkAndExpand( m_hooks[currentCorner], m_hooks[nextS], vertexNumber, v(p(currentCorner)), maxVertexNum);
                if ( m_beachEdgesExpanded > m_beachEdgesToExpand )
                {
                  m_beachEdgesToExpand++;
                  return;
                }
              }
              else //The other island has been expanded. Fetch the expansion from the corner
              {
                if ( m_beachEdgesExpanded == m_beachEdgesToExpand )
                {
                  if ( m_shiftedCorners[currentCorner] == -1 )
                  {
                    visible[t(currentCorner)] = false;
                  }
                  else
                  {
                    visible[t(m_shiftedCorners[currentCorner])] = false;
                  }
                }
                m_beachEdgesExpanded++;
                if ( m_beachEdgesExpanded == m_beachEdgesToExpand )
                {
                  if ( m_shiftedCorners[currentCorner] == -1 )
                  {
                    addTriangle( m_expansionIndex[vertexNumber] + m_hooks[currentCorner], v(n(currentCorner)), v(p(currentCorner)) );
                    m_shiftedCorners[currentCorner] = nc - 3;
                    m_shiftedCorners[n(currentCorner)] = nc - 2;
                    m_shiftedCorners[p(currentCorner)] = nc - 1;
                    tm[t(m_shiftedCorners[currentCorner])] = tm[t(currentCorner)];
                  }
                  else
                  {
                    addTriangle( m_expansionIndex[vertexNumber] + m_hooks[currentCorner], v(n(m_shiftedCorners[currentCorner])), v(p(m_shiftedCorners[currentCorner])) );
                    m_shiftedCorners[currentCorner] = nc - 3;
                    m_shiftedCorners[n(currentCorner)] = nc - 2;
                    m_shiftedCorners[p(currentCorner)] = nc - 1;
                    tm[t(m_shiftedCorners[currentCorner])] = tm[t(currentCorner)];
                  }
                }
                m_beachEdgesExpanded++;

                ArrayList<Boolean> triangleStripList = m_triangleStrips[ n(currentCorner) ].expansion();
                boolean flip = false;
                if ( v(p(currentCorner)) > v(currentCorner ) ) //If the current island number is less than the other island number, no need to invert triangle strip
                {
                  flip = true;
                }
                walkAndExpandBoth( m_hooks[currentCorner], m_hooks[nextS], vertexNumber, maxVertexNum, m_hooks[p(currentCorner)], m_hooks[u(p(currentCorner))], v(p(currentCorner)), triangleStripList, flip );
              }
            }
            else if ( v(p(currentCorner)) >= numIslands && v(p(currentCorner)) < m_initSize) //Water vertex in base mesh. TODO msati3: Get the condition correct
            {
              if ( m_beachEdgesExpanded == m_beachEdgesToExpand )
              {
                visible[t(currentCorner)] = false;                
              }
              m_beachEdgesExpanded++;
              if ( m_beachEdgesExpanded == m_beachEdgesToExpand )
              {
                addTriangle( m_expansionIndex[vertexNumber] + m_hooks[currentCorner], v(n(currentCorner)), v(p(currentCorner)) );
                tm[nt-1] = tm[t(currentCorner)];
              }
              m_beachEdgesExpanded++;
              if ( m_beachEdgesToExpand == m_beachEdgesExpanded )
              {
                print("Walk and expand " + m_hooks[currentCorner] + " " + m_hooks[nextS] + " " + vertexNumber + " " + v(p(currentCorner)) + " " + maxVertexNum + "\n");
              }
              walkAndExpand( m_hooks[currentCorner], m_hooks[nextS], vertexNumber, v(p(currentCorner)), maxVertexNum);
              if ( m_beachEdgesExpanded > m_beachEdgesToExpand )
              {
                m_beachEdgesToExpand++;
                return;
              }
            }
            else
            {
            }
            currentCorner = nextS;
          } while (currentCorner != initCorner);
        }
      }
    }
  }
  
  private void walkAndExpand(int startHook, int endHook, int currentIsland, int nextIsland, int maxVertexNum)
  {
    print("Here " + startHook + " " + currentIsland + "\n");
    int start = startHook;
    int end = endHook;
    for (int i = start; start <= end ? (i < end) : (i < end + maxVertexNum); i++)
    {
      if ( m_beachEdgesToExpand != -1 && m_beachEdgesToExpand < m_beachEdgesExpanded )
      {
        return;
      }

      if ( m_beachEdgesToExpand == -1 || m_beachEdgesToExpand == m_beachEdgesExpanded )
      {
        addTriangle( m_expansionIndex[currentIsland] + ((i + 1) % maxVertexNum), m_expansionIndex[currentIsland] + (i%maxVertexNum), nextIsland );
        tm[nt-1] = CHANNEL;
      }

      m_beachEdgesExpanded++;
    }
  }
  
  private void walkAndExpandBoth( int startHook, int endHook, int currentIsland, int maxVertexNum, int startHookOther, int endHookOther, int nextIsland, ArrayList<Boolean> triangleStripList, boolean flip )
  {
    int currentVertexOffset1 = startHook;
    int currentVertexOffset2 = startHookOther;
    for (int i = 0; i < triangleStripList.size(); i++)
    {
      if ( m_beachEdgesToExpand != -1 && m_beachEdgesToExpand < m_beachEdgesExpanded )
      {
        return;
      }

      boolean advanceOnCurrentIsland = triangleStripList.get(i) ^ flip;
      if ( m_beachEdgesToExpand != -1 && m_beachEdgesToExpand == m_beachEdgesExpanded )
      {
        print("Advance on currentIsland " + advanceOnCurrentIsland + "\n");
      }
      
      if ( advanceOnCurrentIsland )
      {
        if ( m_beachEdgesToExpand == -1 || m_beachEdgesToExpand == m_beachEdgesExpanded )
        {
          addTriangle( m_expansionIndex[currentIsland] + ((currentVertexOffset1 + 1) % maxVertexNum), m_expansionIndex[currentIsland] + (currentVertexOffset1%maxVertexNum), m_expansionIndex[nextIsland] + (currentVertexOffset2 % maxVertexNum) );
          tm[nt-1] = CHANNEL;
        }
        currentVertexOffset1++;
      }
      else
      {
        if ( m_beachEdgesToExpand == -1 || m_beachEdgesToExpand == m_beachEdgesExpanded )
        {
          addTriangle( m_expansionIndex[currentIsland] + (currentVertexOffset1 % maxVertexNum), m_expansionIndex[nextIsland] + (currentVertexOffset2%maxVertexNum), m_expansionIndex[nextIsland] + ((currentVertexOffset2 - 1)%maxVertexNum) );
          tm[nt-1] = CHANNEL;
        }
        currentVertexOffset2++;
      }
      m_beachEdgesExpanded++;
    }
  }
  
  void draw()
  {
    super.draw();
  }  
}

