class STypeTriangleStateV
{
  private int m_v1;
  private int m_v2;
  int m_oppositeCornerOther;
  
  public STypeTriangleStateV( int v1, int v2, int oppositeCornerOther )
  {
    m_v1 = v1;
    m_v2 = v2;
    m_oppositeCornerOther = oppositeCornerOther;
  }
  
  public int v1() { return m_v1; }
  public int v2() { return m_v2; }
  public int oppositeCornerOther() { return m_oppositeCornerOther; }
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
  
  ChannelExpansion reverse()
  {
    ArrayList<Boolean> rev = new ArrayList<Boolean>();
    for (int i = m_expansion.size() - 1; i >= 0; i--)
    {
      rev.add( m_expansion.get(i) );
    }
    ChannelExpansion newExpansion = new ChannelExpansion( rev );
    return newExpansion;
  }
  
  ArrayList<Boolean> expansion() { return m_expansion; }
  
  private ArrayList<Boolean> m_expansion;
}

class BaseMesh extends Mesh
{
  int m_expandedIsland;
  int[] m_hooks = new int [3*maxnt];               // V table (triangle/vertex indices) .. TODO msati3: Move this to outside the base mesh datastructure
  int[] m_expansionIndex = new int [numIslands];   // is an island expanded?
  int[] m_expansionIndexVTable = new int [numIslands]; //stores the index of the first entry in the V table for the island
  
  int[] m_shiftedOpposites = new int[3*maxnt];       // store the original opposites corners for each junction triangle at each time one of the incident islands is expanded
  int[] m_shiftedVertices = new int[3*maxnt];        // store the original base vertex numbers for each junction triangle at each time one of the incident islands is expanded
  
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
      m_expansionIndexVTable[i] = -1;
    }
    
    for (int i = 0; i < 3*maxnt; i++)
    {
      O[i] = -1;
      m_shiftedOpposites[i] = -1;
      m_shiftedVertices[i] = -1;
      m_triangleStrips[i] = null;
    }
  }
  
  //Fetchers for connectivity in the base mesh
  private int swingBase( int corner )
  {
    if ( m_shiftedOpposites[n(corner)] != -1 )
    {
      return n(m_shiftedOpposites[n(corner)]);
    }
    else
    {
      return s(corner);
    }
  }
  
  private int unswingBase( int corner )
  {
    if ( m_shiftedOpposites[p(corner)] != -1 )
    {
      return p(m_shiftedOpposites[p(corner)]);
    }
    else
    {
      return u(corner);
    }
  }
  
  private int baseV(int corner)
  {
    if ( m_shiftedVertices[corner] == -1 )
    {
      return v(corner);
    }
    return m_shiftedVertices[corner];
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
        print(" Opposite " + O[cc] + "\n");
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
  
  //Update the opposite corner being tracked, and set the opposite corner for the newly added triangle
  private int setOppositeCornerAndUpdate( int oppositeCornerLast, char triangleType )
  {
    switch( triangleType )
    {
      case 'l': if ( oppositeCornerLast != -1 )
                {
                  O[oppositeCornerLast] = 3*nt - 2;
                  O[3*nt - 2] = oppositeCornerLast;
                }
                oppositeCornerLast = 3*nt - 3;
                break;
      case 'r': if ( oppositeCornerLast != -1 )
                {
                  O[oppositeCornerLast] = 3*nt - 2;
                  O[3*nt - 2] = oppositeCornerLast;
                }
                oppositeCornerLast = 3*nt - 1;
                break;
      case 's': if ( oppositeCornerLast != -1 )
                {
                  O[oppositeCornerLast] = 3*nt - 2;
                  O[3*nt - 2] = oppositeCornerLast;
                }
                oppositeCornerLast = 3*nt - 1;
                break;
      case 'e': if ( oppositeCornerLast == -1 )
                {
                  if ( DEBUG && DEBUG_MODE >= LOW )
                  {
                    print("Set opposite corner and update - oppositeCornerLast is -1 for an E triangle!!\n");
                  }
                }
                O[oppositeCornerLast] = 3*nt - 2;
                O[3*nt-2] = oppositeCornerLast;
                oppositeCornerLast = -1;
                break;
    }
    return oppositeCornerLast;
  }
  
  private int getHookFromVertexNumber( int vertexNumber, int baseOffset )
  {
    int hookNumber = vertexNumber - baseOffset;
    
    if ( DEBUG && DEBUG_MODE >= LOW )
    {
      if ( hookNumber >= VERTICES_PER_ISLAND )
      {
        print ("getHookFromVertexNumber - the hook number that is determined is greater than the number of the vertices on an island!!");
      }
    }
    
    return hookNumber;
  }
  
  private int setOppositeCornerLagoonAndUpdate( int oppositeCornerLast, char triangleType, int island )
  {
    int v1, v2, corner, opposite;
    
    switch( triangleType )
    {
      case 'l': if ( oppositeCornerLast != -1 )
                {
                  O[oppositeCornerLast] = 3*nt - 1;
                  O[3*nt - 1] = oppositeCornerLast;
                }
                
                //Set the opposite for the island edge
                v1 = getHookFromVertexNumber( V[3*nt-2], m_expansionIndex[island] );
                v2 = getHookFromVertexNumber( V[3*nt-1], m_expansionIndex[island] );
                corner = getCornerForHookPair( island, v2, v1 );
                opposite = n(corner);               
                O[3*nt - 3] = opposite;
                O[opposite] = 3*nt - 3;

                oppositeCornerLast = 3*nt - 2;
                break;

      case 'r': if ( oppositeCornerLast != -1 )
                {
                  O[oppositeCornerLast] = 3*nt - 1;
                  O[3*nt - 1] = oppositeCornerLast;
                }

                //Set the opposite for the island edge
                v1 = getHookFromVertexNumber( V[3*nt-1], m_expansionIndex[island] );
                v2 = getHookFromVertexNumber( V[3*nt-3], m_expansionIndex[island] );
                corner = getCornerForHookPair( island, v2, v1 );
                opposite = n(corner);               
                O[3*nt - 2] = opposite;
                O[opposite] = 3*nt - 2;

                oppositeCornerLast = 3*nt - 3;
                break;

      case 's': if ( oppositeCornerLast != -1 )
                {
                  O[oppositeCornerLast] = 3*nt - 1;
                  O[3*nt - 1] = oppositeCornerLast;
                }
                oppositeCornerLast = 3*nt - 2;
                break;

      case 'e': if ( oppositeCornerLast != -1 )
                {                
                  O[oppositeCornerLast] = 3*nt - 1;
                  O[3*nt-1] = oppositeCornerLast;
                  oppositeCornerLast = -1;
                }

                //Set the opposite for the island edge
                v1 = getHookFromVertexNumber( V[3*nt-2], m_expansionIndex[island] );
                v2 = getHookFromVertexNumber( V[3*nt-1], m_expansionIndex[island] );
                corner = getCornerForHookPair( island, v2, v1 );
                print("Get corner for hook pair  " + v1 + " " + v2 + " " + corner + "\n");
                opposite = n(corner);               
                O[3*nt - 3] = opposite;
                O[opposite] = 3*nt - 3;
                print("Adding opposite for " + (3*nt-3) + " " + opposite + "\n");

                v1 = getHookFromVertexNumber( V[3*nt-1], m_expansionIndex[island] );
                v2 = getHookFromVertexNumber( V[3*nt-3], m_expansionIndex[island] );
                corner = getCornerForHookPair( island, v2, v1 );                
                opposite = n(corner);               
                O[3*nt - 2] = opposite;
                O[opposite] = 3*nt - 2;
                break;
    }
    return oppositeCornerLast;
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
    int oppositeCornerLast = -1;
    
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
                  oppositeCornerLast = setOppositeCornerAndUpdate( oppositeCornerLast, ch );
                  break;
        case 'r': addTriangleWithOffset( baseOffset, currentV1, getPrev(currentV2), currentV2, ISLAND );
                  currentV2 = getPrev(currentV2);
                  oppositeCornerLast = setOppositeCornerAndUpdate( oppositeCornerLast, ch );
                  break;
        case 'e': addTriangleWithOffset( baseOffset, currentV1, getNext(currentV1), currentV2, ISLAND );
                  oppositeCornerLast = setOppositeCornerAndUpdate( oppositeCornerLast, ch );
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
                    oppositeCornerLast = state.oppositeCornerOther();
                  }
                  break;                    
        case 's': //First L and then R
                  int offset = sOffsets[s];
                  s++;
                  print("Offset " + offset + "\n");
                  addTriangleWithOffset( baseOffset, currentV1, currentV1 + offset + 1, currentV2, ISLAND );
                  oppositeCornerLast = setOppositeCornerAndUpdate( oppositeCornerLast, ch );
                  int otherV1 = currentV1 + offset + 1;
                  int otherV2 = currentV2;
                  int oppositeCornerOther = 3*nt - 3;
                  currentV2 = currentV1 + offset + 1;
                  sState.push( new STypeTriangleStateV( otherV1, otherV2, oppositeCornerOther ) );
                  break;
      }
    }
  }
  
    //Uses the clers string of lagoon expansion to add to the V table of the base mesh, from the base offset
  private void decompressConnectivityForLagoon( int vertex1, int vertex2, String clersString, int islandNumber )
  {
    int baseOffset = m_expansionIndex[islandNumber];
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
    int oppositeCornerLast = -1;
    
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
                  oppositeCornerLast = setOppositeCornerLagoonAndUpdate( oppositeCornerLast, ch, islandNumber );
                  currentV2 = getPrev(currentV2); 
                  break;
        case 'r': addTriangleWithOffset( baseOffset, currentV1, currentV2, getNext(currentV1), LAGOON );
                  oppositeCornerLast = setOppositeCornerLagoonAndUpdate( oppositeCornerLast, ch, islandNumber );
                  currentV1 = getNext(currentV1);
                  break;
        case 'e': addTriangleWithOffset( baseOffset, currentV1, currentV2, getPrev(currentV2), LAGOON );
                  oppositeCornerLast = setOppositeCornerLagoonAndUpdate( oppositeCornerLast, ch, islandNumber );
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
                    oppositeCornerLast = state.oppositeCornerOther();
                  }
                  break;                    
        case 's': //First R and then L
                  int offset = sOffsets[s];
                  s++;
                  addTriangleWithOffset( baseOffset, currentV1, currentV2, (currentV1 + offset + 1) % VERTICES_PER_ISLAND, LAGOON );
                  oppositeCornerLast = setOppositeCornerLagoonAndUpdate( oppositeCornerLast, ch, islandNumber );
                  int otherV1 = (currentV1 + offset + 1) % VERTICES_PER_ISLAND;
                  int otherV2 = currentV2;
                  int oppositeCornerOther = 3*nt - 3;
                  print("Opposite corner other - " + oppositeCornerOther + "\n");
                  currentV2 = (currentV1 + offset + 1) % VERTICES_PER_ISLAND;
                  sState.push( new STypeTriangleStateV( otherV1, otherV2, oppositeCornerOther ) ); 
                  break;
      }
    }
  }
  
  private void addIslandGeometry( int islandNumber )
  {
    m_expansionIndex[ islandNumber ] = nv;
    m_expansionIndexVTable[ islandNumber ] = 3*nt;
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
      decompressConnectivityForLagoon( v1, v2, clersString, islandNumber );
    }
    
    if ( geometry.length != VERTICES_PER_ISLAND )
    {
      if ( DEBUG && DEBUG_MODE >= LOW )
      {
        print("Fatal error! The size of the geometry is not equal to the number of vertices per island!\n");
      }
    }
  }
  
  void beforeStepWiseExpand()
  {
    m_beachEdgesToExpand = 0;
    m_beachEdgesExpanded = 0;
    m_vertexNumberToExpandStepWise = v(cc);
    m_cornerNumberToExpandStepWise = cc;
  }
  
  void adjustOppositesOnExpansion( int corner )
  {
    if ( m_shiftedVertices[corner] == -1 )
    {
      m_shiftedVertices[corner] = v(corner);
    }

    if ( m_shiftedOpposites[corner] == -1 )
    {
      m_shiftedOpposites[corner] = o(corner);
      m_shiftedOpposites[n(corner)] = o(n(corner));
      m_shiftedOpposites[p(corner)] = o(p(corner));
    }
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
          int maxVertexNum = VERTICES_PER_ISLAND;
          addIslandGeometry( vertexNumber ); //Expand the island itself
          int initCorner = cc;
          int currentCorner = initCorner;
          int nextS = -1;
          do
          {
            nextS = swingBase( currentCorner );
            if ( baseV(p(currentCorner)) < numIslands ) //The other island forming the straits is not a water vertex
            {
              if (m_expansionIndex[ baseV(p(currentCorner)) ]  == -1) //Not expanded other island
              {
                adjustOppositesOnExpansion( currentCorner );
                V[currentCorner] = m_expansionIndex[vertexNumber] + m_hooks[currentCorner]; //Set the vertex of the junction triangle to the expansion island's hook vertex
                if ( currentCorner != initCorner && O[3*nt-2] == -1)
                {
                  O[p(currentCorner)] = 3*nt - 2;
                  O[3*nt - 2] = p(currentCorner);
                }

                walkAndExpand( m_hooks[currentCorner], m_hooks[nextS], vertexNumber, v(p(currentCorner)), maxVertexNum, currentCorner, CHANNEL );
              }
              else //The other island has been expanded. Fetch the expansion from the corner
              {
                adjustOppositesOnExpansion( currentCorner );
                V[currentCorner] = m_expansionIndex[vertexNumber] + m_hooks[currentCorner]; //Set the vertex of the junction triangle to the expansion island's hook vertex                
                if ( currentCorner != initCorner && O[3*nt-2] == -1)
                {
                  O[p(currentCorner)] = 3*nt - 2;
                  O[3*nt - 2] = p(currentCorner);
                }

                ArrayList<Boolean> triangleStripList = m_triangleStrips[ n(currentCorner) ].expansion();
                boolean flip = false;
                if ( baseV(p(currentCorner)) < baseV(currentCorner ) ) //If the current island number is less than the other island number, no need to invert triangle strip
                {
                  flip = true;
                }
                walkAndExpandBoth( m_hooks[currentCorner], m_hooks[nextS], vertexNumber, maxVertexNum, m_hooks[p(currentCorner)], m_hooks[unswingBase(p(currentCorner))], baseV(p(currentCorner)), triangleStripList, flip, currentCorner );
              }
            }
            else if ( v(p(currentCorner)) >= numIslands && v(p(currentCorner)) < m_initSize) //water vertex
            {
              adjustOppositesOnExpansion( currentCorner );
              V[currentCorner] = m_expansionIndex[vertexNumber] + m_hooks[currentCorner]; //Set the vertex of the junction triangle to the expansion island's hook vertex
              if ( currentCorner != initCorner && O[3*nt-2] == -1)
              {
                O[p(currentCorner)] = 3*nt - 2;
                O[3*nt - 2] = p(currentCorner);
              }

              walkAndExpand( m_hooks[currentCorner], m_hooks[nextS], vertexNumber, v(p(currentCorner)), maxVertexNum, currentCorner, CAP );
            }
            else
            {
            }
            currentCorner = nextS;
          } while (currentCorner != initCorner);
          
          //Populate opposites for the last corner corresponding to the base mesh's junction triangles
          O[p(currentCorner)] = 3*nt - 2;
          O[3*nt - 2] = p(currentCorner); 
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
          if ( m_beachEdgesExpanded == m_beachEdgesToExpand )
          {
            addIslandGeometry( vertexNumber ); //Expand the island itself
          }
          m_beachEdgesExpanded++;
          int maxVertexNum = VERTICES_PER_ISLAND;
          int currentCorner = initCorner;
          int nextS = -1;
          do
          {
            print( "Current corner " + currentCorner + " init corner " + initCorner + " next corner " + s(currentCorner) + "\n" );
            nextS = swingBase( currentCorner );
            if ( baseV(p(currentCorner)) < numIslands ) //The other island forming the straits is not a water vertex
            {
              if (m_expansionIndex[ baseV(p(currentCorner)) ]  == -1) //Not expanded
              {
                if ( m_beachEdgesExpanded == m_beachEdgesToExpand )
                {
                  print("Expanding single island \n");
                  adjustOppositesOnExpansion( currentCorner );
                  V[currentCorner] = m_expansionIndex[vertexNumber] + m_hooks[currentCorner]; //Set the vertex of the junction triangle to the expansion island's hook vertex
                  if ( currentCorner != initCorner && O[3*nt-2] == -1)
                  {
                    O[p(currentCorner)] = 3*nt - 2;
                    O[3*nt - 2] = p(currentCorner);
                  }
                }
                m_beachEdgesExpanded++;
                walkAndExpand( m_hooks[currentCorner], m_hooks[nextS], vertexNumber, v(p(currentCorner)), maxVertexNum, currentCorner, CHANNEL );
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
                  print("Expanding multiple islands \n");
                  adjustOppositesOnExpansion( currentCorner );
                  V[currentCorner] = m_expansionIndex[vertexNumber] + m_hooks[currentCorner]; //Set the vertex of the junction triangle to the expansion island's hook vertex                
                  if ( currentCorner != initCorner && O[3*nt-2] == -1)
                  {
                    O[p(currentCorner)] = 3*nt - 2;
                    O[3*nt - 2] = p(currentCorner);
                  }
                }
                m_beachEdgesExpanded++;

                ArrayList<Boolean> triangleStripList = m_triangleStrips[ n(currentCorner) ].expansion();
                boolean flip = false;
                print("Here " + baseV(currentCorner) + " " + baseV(p(currentCorner)) + "\n");
                if ( baseV(p(currentCorner)) < baseV(currentCorner ) ) //If the current island number is less than the other island number, no need to invert triangle strip
                {
                  flip = true;
                }
                walkAndExpandBoth( m_hooks[currentCorner], m_hooks[nextS], vertexNumber, maxVertexNum, m_hooks[p(currentCorner)], m_hooks[unswingBase(p(currentCorner))], baseV(p(currentCorner)), triangleStripList, flip, currentCorner );
                if ( m_beachEdgesExpanded > m_beachEdgesToExpand )
                {
                  m_beachEdgesToExpand++;
                  return;
                }
              }
            }
            else if ( v(p(currentCorner)) >= numIslands && v(p(currentCorner)) < m_initSize) //Water vertex in base mesh. TODO msati3: Get the condition correct
            {
              if ( m_beachEdgesExpanded == m_beachEdgesToExpand )
              {
                print("Expanding water vertex \n");
                adjustOppositesOnExpansion( currentCorner );
                V[currentCorner] = m_expansionIndex[vertexNumber] + m_hooks[currentCorner]; //Set the vertex of the junction triangle to the expansion island's hook vertex
                if ( currentCorner != initCorner && O[3*nt-2] == -1)
                {
                  O[p(currentCorner)] = 3*nt - 2;
                  O[3*nt - 2] = p(currentCorner);
                }
              }
              m_beachEdgesExpanded++;
              if ( m_beachEdgesToExpand == m_beachEdgesExpanded )
              {
                if ( DEBUG && DEBUG_MODE >= VERBOSE )
                {
                  print("Walk and expand " + m_hooks[currentCorner] + " " + m_hooks[nextS] + " " + vertexNumber + " " + v(p(currentCorner)) + " " + maxVertexNum + "\n");
                }
              }
              walkAndExpand( m_hooks[currentCorner], m_hooks[nextS], vertexNumber, v(p(currentCorner)), maxVertexNum, currentCorner, CAP );
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

          //Populate opposites for the last corner corresponding to the base mesh's junction triangles
          O[p(currentCorner)] = 3*nt - 2;
          O[3*nt - 2] = p(currentCorner); 
        }
      }
    }
  }
  
  //Returns the corner for the nexthook
  private int getCornerForHookPair( int currentIsland, int startHook, int nextHook )
  {
    int searchStartIndex = m_expansionIndexVTable[ currentIsland ];
    int currentCorner;
    int retVal = -1;
    for (int i = 0; i < ISLAND_SIZE; i++)
    {
      currentCorner = searchStartIndex + i*3;
      if ( ( v(currentCorner) == m_expansionIndex[ currentIsland ] + startHook ) && ( v(n(currentCorner)) == m_expansionIndex[ currentIsland ] + nextHook ) )
      {
        retVal = n(currentCorner);
        break;
      }
      else if ( ( v(n(currentCorner)) == m_expansionIndex[ currentIsland ] + startHook ) && ( v(p(currentCorner)) == m_expansionIndex[ currentIsland ] + nextHook ) )
      {
        retVal = p(currentCorner);
        break;
      }
      else if ( ( v(p(currentCorner)) == m_expansionIndex[ currentIsland ] + startHook ) && ( v(currentCorner) == m_expansionIndex[ currentIsland ] + nextHook ) )
      {
        retVal = currentCorner;
        break;
      }
    }
    if ( DEBUG && DEBUG_MODE >= LOW )
    {
      if ( retVal == -1 )
      {
        print ("Get corner for hook pair - can't find appropriate corner for the hook!! " + startHook + " " + nextHook + "\n");
      }
    }
    return retVal;
  }
  
  private void addOppositesAndUpdateCornerForChannel( int cornerIsland, int cornerLastChannelFan, int currentCorner )
  {
    O[n(cornerIsland)] = 3*nt - 1;
    O[3*nt - 1] = n(cornerIsland);

    if ( cornerLastChannelFan != -1 )
    {
      O[3*nt - 3] = cornerLastChannelFan;
      O[cornerLastChannelFan] = 3*nt - 3;
    }
    else
    {
      O[3*nt-3] = n(currentCorner);
      O[n(currentCorner)] = 3*nt-3;
    }
  }
  
  private void walkAndExpand(int startHook, int endHook, int currentIsland, int nextIsland, int maxVertexNum, int currentCorner, int type)
  {
    int start = startHook;
    int end = endHook;
    int cornerLastChannelFan = -1;
      
    for (int i = start; start <= end ? (i < end) : (i < end + maxVertexNum); i++)
    {
      int cornerIsland = getCornerForHookPair( currentIsland, i%maxVertexNum, (i + 1)%maxVertexNum ); //Corner on island, corresponding to next vertex to i

      if ( m_beachEdgesToExpand != -1 && m_beachEdgesToExpand < m_beachEdgesExpanded )
      {
        return;
      }

      if ( m_beachEdgesToExpand == -1 || m_beachEdgesToExpand == m_beachEdgesExpanded )
      {
        if ( m_beachEdgesToExpand != -1 )
        {
          print("Expand edge hook " + (i)%maxVertexNum + "\n");
        }
        addTriangle( m_expansionIndex[currentIsland] + ((i + 1) % maxVertexNum), m_expansionIndex[currentIsland] + (i%maxVertexNum), nextIsland );
        addOppositesAndUpdateCornerForChannel( cornerIsland, cornerLastChannelFan, currentCorner );
        tm[nt-1] = type;
      }
      cornerLastChannelFan = 3*nt - 2; //TODO msati3: Move to the main API


      m_beachEdgesExpanded++;
    }   
  }
  
  void onSwingBase()
  {
    pc=cc; 
    cc=swingBase(cc); 
  }
  
  private void walkAndExpandBoth( int startHook, int endHook, int currentIsland, int maxVertexNum, int startHookOther, int endHookOther, int nextIsland, ArrayList<Boolean> triangleStripList, boolean flip, int currentCorner )
  {
    int currentVertexOffset1 = startHook;
    int currentVertexOffset2 = startHookOther;
    
    // track the current corner on the fan. Each time no progress on self strip, change the vertex of the corner appropriately. Else, increase the vertex number on the
    int currentCornerOnFan = currentCorner;
    
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
          addTriangle( m_expansionIndex[currentIsland] + ((currentVertexOffset1 + 1) % maxVertexNum), m_expansionIndex[currentIsland] + currentVertexOffset1, m_expansionIndex[nextIsland] + currentVertexOffset2 );
          tm[nt-1] = CHANNEL;
        }
        currentVertexOffset1 = (currentVertexOffset1 + 1) % maxVertexNum;
      }
      else
      {
        currentCornerOnFan = s(currentCornerOnFan);
        if ( m_beachEdgesToExpand == -1 || m_beachEdgesToExpand == m_beachEdgesExpanded )
        {
          V[currentCornerOnFan] = m_expansionIndex[currentIsland] + currentVertexOffset1;
        }
        currentVertexOffset2 = (maxVertexNum + currentVertexOffset2 - 1) % maxVertexNum;
      }
      m_beachEdgesExpanded++;
    }
  }
  
  void draw()
  {
    super.draw();
  }  
}

