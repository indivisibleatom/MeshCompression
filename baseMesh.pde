//int numTimes = 0; //Flag for producing drawings. Enable when producing drawings
int numTimes = 1;
int NUM_CONTRACTIONS = 1;

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

//Debug information
class StepWiseDualExpansionState
{
  private int m_v1Offset;
  private int m_v2Offset;
  private int m_origNextSwingCorner;
  private int m_i;
  private int m_currentCornerOnFan;
    
  StepWiseDualExpansionState( int v1Offset, int v2Offset, int origNextSwingCorner, int currentCornerOnFan, int i )
  {
    m_v1Offset = v1Offset; 
    m_v2Offset = v2Offset;
    m_origNextSwingCorner = origNextSwingCorner;
    m_i = i;
    m_currentCornerOnFan = currentCornerOnFan;
  }
    
  int v1Offset() { return m_v1Offset; }
  int v2Offset() { return m_v2Offset; }
  int origNextSwingCorner() { return m_origNextSwingCorner; }
  int i() { return m_i; }
  int currentCornerOnFan() { return m_currentCornerOnFan; }
}

class BaseMesh extends Mesh
{
  int[] m_expansionIndex = new int [numIslands];   // is an island expanded?
  int[] m_expansionIndexVTable = new int [numIslands]; //stores the index of the first entry in the V table for the island
  int[] m_numTrianglesVTable = new int [numIslands]; //stores the number of triangles for the island in the V table for the island. TODO msati3: Can you remove this?
  
  int[] m_shiftedOpposites = new int[3*maxnt];       // store the original opposites corners for each junction triangle at each time one of the incident islands is expanded
  int[] m_shiftedVertices = new int[3*maxnt];        // store the original base vertex numbers for each junction triangle at each time one of the incident islands is expanded
  
  IslandExpansionManager m_expansionManager;
  ChannelExpansionPacketManager m_channelExpansionManager;

  //Debug state.
  int m_beachEdgesToExpand = 0;
  int m_beachEdgesExpanded = 0;
  int m_vertexNumberToExpandStepWise = 0;
  int m_cornerNumberToExpandStepWise = 0;
  StepWiseDualExpansionState m_dualExpansionState;
  
  int m_initSize;
  int m_numTimesContracted = 0;
  
  BaseMesh()
  {
    m_userInputHandler = new BaseMeshUserInputHandler(this);
    m_expansionManager = null;
    
    for (int i = 0; i < numIslands; i++)
    {
      m_expansionIndex[i] = -1;
      m_expansionIndexVTable[i] = -1;
      m_numTrianglesVTable[i] = 5;
    }
    
    for (int i = 0; i < 3*maxnt; i++)
    {
      O[i] = -1;
      m_shiftedOpposites[i] = -1;
      m_shiftedVertices[i] = -1;
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
  
  //Get a corner on the base mesh by swinging around the corner
  private int getBaseMeshCornerForIsland(int corner)
  {
    int currentCorner = corner;
    do
    {
      if ( baseV(currentCorner) < m_initSize && baseV(n(currentCorner)) < m_initSize && baseV(p(currentCorner)) < m_initSize )
      {
        print("Base mesh corner " + currentCorner + "\n");
        return currentCorner;
      }
      currentCorner = s(currentCorner);
    } while( currentCorner != corner );
    return -1;
  }
  
  //Given an index of a vertex in a partially expanded mesh, returns the island number for the vertex. Returns -1 if the vertex is to a non-expanded mesh vertex
  private int getIslandForVertex(int vertex)
  {
    for ( int i = 0; i < numIslands; i++ )
    {
      if ( (m_expansionIndex[i] != -1) && (vertex >= m_expansionIndex[i]) && (vertex < m_expansionIndex[i] + VERTICES_PER_ISLAND) )
      {
        if ( DEBUG && DEBUG_MODE >= VERBOSE )
        {
          print ("BaseMesh: getIsland for vertex " + vertex + " " + i + "\n");
        }
        return i;
      }
    }
    if ( DEBUG && DEBUG_MODE >= VERBOSE )
    {
      print("BaseMesh: getIslandForVertex no island found for vertex " + vertex + "\n");
    }
    return -1;
  }
  
  private boolean belongsToIsland(int vertex, int island)
  {
    if ( (m_expansionIndex[island] != -1) && (vertex >= m_expansionIndex[island]) && (vertex < m_expansionIndex[island] + VERTICES_PER_ISLAND) )
    {
      return true;
    }
    return false;
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
        if ( cc < m_channelExpansionManager.nc )
        {
          print(" Hook " + m_channelExpansionManager.hookForCorner(cc) + "\n" ); 
        }
        if ( cc < m_channelExpansionManager.nc && m_channelExpansionManager.triangleStripForCorner(cc) != null )
        {
          print(" Triangle strips: ");
          for (int i = 0; i < m_channelExpansionManager.triangleStripForCorner(cc).expansion().size(); i++)
          {
            print( m_channelExpansionManager.triangleStripForCorner(cc).expansion().get(i) + " ");
          }
          print("\n");
        }
    }
  }
  
  void addTriangle(int island1, int island2, int island3)
  {
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
  
  void setExpansionManager( IslandExpansionManager manager, ChannelExpansionPacketManager channelMananger )
  {
    m_expansionManager = manager;
    m_channelExpansionManager = channelMananger;
  }
  
  //Adds a triangle in mesh, with vertices offset by base offset
  private void addTriangleWithOffset(int baseOffset, int v1, int v2, int v3, int type)
  {
    if (DEBUG && DEBUG_MODE >= VERBOSE)
    {
      print("Adding triangle withoffset " + (baseOffset + v1) + " " + (baseOffset + v2) + " " + (baseOffset + v3) + "\n");
    }
    addTriangle( baseOffset + v1, baseOffset + v2, baseOffset + v3 );
    tm[nt-1] = type + (numTimes - 1)*10;
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
        print ("getHookFromVertexNumber - the hook number that is determined is greater than the number of the vertices on an island!!" + vertexNumber + " " + baseOffset + "\n");
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
    m_cornerNumberToExpandStepWise = getBaseMeshCornerForIsland(cc);
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
    //numTimes = numTimes == 0 ? 1 : 2;
    m_beachEdgesToExpand = -1;
    m_beachEdgesExpanded = -1;
    if ( m_expansionManager != null )
    {
      int corner = getBaseMeshCornerForIsland(cc);
      if (corner == -1)
        return;
      int vertexNumber = v(corner);
      if ( vertexNumber < numIslands ) //If an island
      {
        if ( m_expansionIndex[vertexNumber] == -1 ) //Is not expanded
        {
          int maxVertexNum = VERTICES_PER_ISLAND;
          addIslandGeometry( vertexNumber ); //Expand the island itself
          int initCorner = corner;
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
                V[currentCorner] = m_expansionIndex[vertexNumber] + m_channelExpansionManager.hookForCorner(currentCorner); //Set the vertex of the junction triangle to the expansion island's hook vertex
                if ( currentCorner != initCorner && O[3*nt-2] == -1)
                {
                  O[p(currentCorner)] = 3*nt - 2;
                  O[3*nt - 2] = p(currentCorner);
                }

                walkAndExpand( m_channelExpansionManager.hookForCorner(currentCorner), m_channelExpansionManager.hookForCorner(nextS), vertexNumber, v(p(currentCorner)), maxVertexNum, currentCorner, CHANNEL );
              }
              else //The other island has been expanded. Fetch the expansion from the corner
              {
                adjustOppositesOnExpansion( currentCorner );
                V[currentCorner] = m_expansionIndex[vertexNumber] + m_channelExpansionManager.hookForCorner(currentCorner); //Set the vertex of the junction triangle to the expansion island's hook vertex                
                if ( currentCorner != initCorner && O[3*nt-2] == -1)
                {
                  O[p(currentCorner)] = 3*nt - 2;
                  O[3*nt - 2] = p(currentCorner);
                }

                ArrayList<Boolean> triangleStripList = m_channelExpansionManager.triangleStripForCorner( n(currentCorner) ).expansion();
                boolean flip = false;
                if ( baseV(p(currentCorner)) < baseV(currentCorner ) ) //If the current island number is less than the other island number, no need to invert triangle strip
                {
                  flip = true;
                }
                walkAndExpandBoth( m_channelExpansionManager.hookForCorner(currentCorner), m_channelExpansionManager.hookForCorner(nextS), vertexNumber, maxVertexNum, m_channelExpansionManager.hookForCorner(p(currentCorner)), m_channelExpansionManager.hookForCorner(unswingBase(p(currentCorner))), baseV(p(currentCorner)), triangleStripList, flip, currentCorner );
              }
            }
            else if ( v(p(currentCorner)) >= numIslands && v(p(currentCorner)) < m_initSize) //water vertex
            {
              adjustOppositesOnExpansion( currentCorner );
              V[currentCorner] = m_expansionIndex[vertexNumber] + m_channelExpansionManager.hookForCorner(currentCorner); //Set the vertex of the junction triangle to the expansion island's hook vertex
              if ( currentCorner != initCorner && O[3*nt-2] == -1)
              {
                O[p(currentCorner)] = 3*nt - 2;
                O[3*nt - 2] = p(currentCorner);
              }

              walkAndExpand( m_channelExpansionManager.hookForCorner(currentCorner), m_channelExpansionManager.hookForCorner(nextS), vertexNumber, v(p(currentCorner)), maxVertexNum, currentCorner, CAP );
            }
            else
            {
            }
            currentCorner = nextS;
          } while (currentCorner != initCorner);
          
          //Populate opposites for the last corner corresponding to the base mesh's junction triangles
          if (O[3*nt-2] == -1)
          {
            O[p(currentCorner)] = 3*nt - 2;
            O[3*nt - 2] = p(currentCorner); 
          }
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
                  V[currentCorner] = m_expansionIndex[vertexNumber] + m_channelExpansionManager.hookForCorner(currentCorner); //Set the vertex of the junction triangle to the expansion island's hook vertex
                  if ( currentCorner != initCorner && O[3*nt-2] == -1)
                  {
                    print("Setting opposite for corner " + p(currentCorner) + "to " + (3*nt-2) + "\n");
                    O[p(currentCorner)] = 3*nt - 2;
                    O[3*nt - 2] = p(currentCorner);
                  }
                }
                m_beachEdgesExpanded++;
                walkAndExpand( m_channelExpansionManager.hookForCorner(currentCorner), m_channelExpansionManager.hookForCorner(nextS), vertexNumber, v(p(currentCorner)), maxVertexNum, currentCorner, CHANNEL );
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
                  V[currentCorner] = m_expansionIndex[vertexNumber] + m_channelExpansionManager.hookForCorner(currentCorner); //Set the vertex of the junction triangle to the expansion island's hook vertex                
                  if ( currentCorner != initCorner && O[3*nt-2] == -1)
                  {
                    O[p(currentCorner)] = 3*nt - 2;
                    O[3*nt - 2] = p(currentCorner);
                  }
                }
                m_beachEdgesExpanded++;


                ArrayList<Boolean> triangleStripList = m_channelExpansionManager.triangleStripForCorner( n(currentCorner) ).expansion();
                boolean flip = false;
                if ( baseV(p(currentCorner)) < baseV(currentCorner ) ) //If the current island number is less than the other island number, no need to invert triangle strip
                {
                  flip = true;
                }
                if ( m_dualExpansionState == null )
                {
                  m_dualExpansionState = new StepWiseDualExpansionState( m_channelExpansionManager.hookForCorner(currentCorner), m_channelExpansionManager.hookForCorner(p(currentCorner)), -1, currentCorner, 0 );
                }
                walkAndExpandBothStepWise( m_channelExpansionManager.hookForCorner(currentCorner), m_channelExpansionManager.hookForCorner(nextS), vertexNumber, maxVertexNum, m_channelExpansionManager.hookForCorner(p(currentCorner)), m_channelExpansionManager.hookForCorner(unswingBase(p(currentCorner))), baseV(p(currentCorner)), triangleStripList, flip, currentCorner );
                if ( m_beachEdgesExpanded > m_beachEdgesToExpand )
                {
                  m_beachEdgesToExpand++;
                  return;
                }
                else
                {
                  m_dualExpansionState = null;
                }
              }
            }
            else if ( v(p(currentCorner)) >= numIslands && v(p(currentCorner)) < m_initSize) //Water vertex in base mesh. TODO msati3: Get the condition correct
            {
              if ( m_beachEdgesExpanded == m_beachEdgesToExpand )
              {
                print("Expanding water vertex " + currentCorner + "\n");
                adjustOppositesOnExpansion( currentCorner );
                V[currentCorner] = m_expansionIndex[vertexNumber] + m_channelExpansionManager.hookForCorner(currentCorner); //Set the vertex of the junction triangle to the expansion island's hook vertex
                if ( currentCorner != initCorner && O[3*nt-2] == -1)
                {
                  print("Setting opposite for corner " + p(currentCorner) + "to " + (3*nt-2) + "\n");
                  O[p(currentCorner)] = 3*nt - 2;
                  O[3*nt - 2] = p(currentCorner);
                }
              }
              m_beachEdgesExpanded++;
              if ( m_beachEdgesToExpand == m_beachEdgesExpanded )
              {
                if ( DEBUG && DEBUG_MODE >= LOW )
                {
                  print("Walk and expand " + m_channelExpansionManager.hookForCorner(currentCorner) + " " + m_channelExpansionManager.hookForCorner(nextS) + " " + vertexNumber + " " + v(p(currentCorner)) + " " + maxVertexNum + "\n");
                }
              }
              walkAndExpand( m_channelExpansionManager.hookForCorner(currentCorner), m_channelExpansionManager.hookForCorner(nextS), vertexNumber, v(p(currentCorner)), maxVertexNum, currentCorner, CAP );
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
          if (O[3*nt-2] == -1)
          {
            O[p(currentCorner)] = 3*nt - 2;
            O[3*nt - 2] = p(currentCorner); 
          }
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
  
  private void walkAndExpand(int startHook, int endHook, int currentIsland, int nextIsland, int maxVertexNum, int cornerJunction, int type)
  {
    int start = startHook;
    int end = endHook >= startHook ? endHook : endHook + maxVertexNum;
    int cornerLastChannelFan = -1;

    for (int i = start; i < end;)
    {
      int currentLocalVertNum = i % maxVertexNum;
      int posNextLocalVertNum = (i + 1) % maxVertexNum;
      
      int cornerIsland = getCornerForHookPair( currentIsland, currentLocalVertNum, posNextLocalVertNum ); //Corner on island, corresponding to next vertex to i
      int prevCorner = p(cornerIsland);

      //Unswing to get the outermost lagoon triangle
      if ( m_beachEdgesToExpand != -1 )
      {
        while (o(p(prevCorner)) != -1 && (tm[o(p(prevCorner))] == ISLAND || tm[t(o(p(prevCorner)))] == LAGOON))
        {
          prevCorner = u(prevCorner);
        }
      }
      else
      {
        while (o(p(prevCorner)) != -1)
        {
          prevCorner = u(prevCorner);
        }
      }

      cornerIsland = n(prevCorner);
      int nextLocalVertNum = getHookFromVertexNumber( v(cornerIsland), m_expansionIndex[currentIsland] );

      if ( m_beachEdgesToExpand != -1 && m_beachEdgesToExpand < m_beachEdgesExpanded )
      {
        return;
      }

      if ( m_beachEdgesToExpand == -1 || m_beachEdgesToExpand == m_beachEdgesExpanded )
      {
        if ( m_beachEdgesToExpand != -1 )
        {
          print("Expand edge hook " + currentLocalVertNum + " next local vert " + nextLocalVertNum + "\n");
        }
        addTriangle( m_expansionIndex[currentIsland] + nextLocalVertNum, m_expansionIndex[currentIsland] + currentLocalVertNum, nextIsland );
        m_numTrianglesVTable[currentIsland]++;
        addOppositesAndUpdateCornerForChannel( cornerIsland, cornerLastChannelFan, cornerJunction );
        tm[nt-1] = type + (numTimes-1)*10;
      }
      cornerLastChannelFan = 3*nt - 2; //TODO msati3: Move to the main API
      i = nextLocalVertNum < i ? nextLocalVertNum + maxVertexNum : nextLocalVertNum;
      
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
    int origNextSwingCorner = -1; //Cache the corner to swing to, so that post opposite population, all works well  
    
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
         //Given the current and next local vetex number, try to find out the correct next local vertex (including lagoon)
        int cornerNext = getCornerForHookPair( currentIsland, currentVertexOffset1, (currentVertexOffset1+1)%maxVertexNum );
        int prevCorner = p(cornerNext);
        //Unswing to get the outermost lagoon triangle
        if ( m_beachEdgesToExpand != -1 )
        {
          while (o(p(prevCorner)) != -1 && (tm[o(p(prevCorner))] == ISLAND || tm[t(o(p(prevCorner)))] == LAGOON))
          {
              prevCorner = u(prevCorner);
          }
        }
        else
        {
          while (o(p(prevCorner)) != -1)
          {
            prevCorner = u(prevCorner);
          }
        }
        int nextLocalVertex = getHookFromVertexNumber( v(n(prevCorner)), m_expansionIndex[currentIsland] );
        if ( m_beachEdgesToExpand == -1 || m_beachEdgesToExpand == m_beachEdgesExpanded )
        {
          addTriangle( m_expansionIndex[currentIsland] + nextLocalVertex, m_expansionIndex[currentIsland] + currentVertexOffset1, m_expansionIndex[nextIsland] + currentVertexOffset2 );
          m_numTrianglesVTable[currentIsland]++;

          //Fixup opposites between channel and junction triangles
          if (origNextSwingCorner == -1)
          {
            //Cache the corner got to by swinging for later use
            origNextSwingCorner = s(currentCornerOnFan);
            O[3*nt-2] = o(n(currentCornerOnFan));
            O[o(n(currentCornerOnFan))] = 3*nt-2;
            O[3*nt-3] = n(currentCornerOnFan);
            O[n(currentCornerOnFan)] = 3*nt-3;
          }
          else
          {
            O[3*nt-2] = O[3*nt-5];
            O[O[3*nt-2]] = 3*nt-2;
            O[3*nt-5] = 3*nt-3;
            O[3*nt-3] = 3*nt-5;
          }

          //Set opposite of the beach edge and added triangle
          O[p(prevCorner)] = 3*nt-1;
          O[3*nt-1] = p(prevCorner);
          
          tm[nt-1] = CHANNEL + (numTimes-1)*10;
        }

        currentVertexOffset1 = nextLocalVertex;      
      }
      else
      {
        print("Corner on fan is " + currentCornerOnFan + " " + origNextSwingCorner + " " + s(currentCornerOnFan) + "\n");
        if (origNextSwingCorner == -1)
        {
          currentCornerOnFan = s(currentCornerOnFan);
        }
        else
        {
          currentCornerOnFan = origNextSwingCorner;
        }
        V[currentCornerOnFan] = m_expansionIndex[currentIsland] + currentVertexOffset1;
        tm[t(currentCornerOnFan)] += (numTimes-1)*10;
        origNextSwingCorner = -1;
        currentVertexOffset2 = getHookFromVertexNumber( v(p(currentCornerOnFan)), m_expansionIndex[nextIsland] );
      }
      m_beachEdgesExpanded++;
    }
  }  
 
  private void walkAndExpandBothStepWise( int startHook, int endHook, int currentIsland, int maxVertexNum, int startHookOther, int endHookOther, int nextIsland, ArrayList<Boolean> triangleStripList, boolean flip, int currentCorner )
  {
    StepWiseDualExpansionState state = m_dualExpansionState;
    int currentVertexOffset1 = state.v1Offset();
    int currentVertexOffset2 = state.v2Offset();
    int origNextSwingCorner = state.origNextSwingCorner(); //Cache the corner to swing to, so that post opposite population, all works well  
    
    // track the current corner on the fan. Each time no progress on self strip, change the vertex of the corner appropriately. Else, increase the vertex number on the
    int currentCornerOnFan = state.currentCornerOnFan();
    int i = state.i();
    m_beachEdgesExpanded += i;
    print("Walk and expand both " + currentVertexOffset1 + " " + currentVertexOffset2 + " " + origNextSwingCorner + " " + i + " " + m_beachEdgesExpanded + " " + m_beachEdgesToExpand + "\n");
    
    for (; i < triangleStripList.size(); i++)
    {
      if ( m_beachEdgesToExpand < m_beachEdgesExpanded )
      {
        m_dualExpansionState = new StepWiseDualExpansionState( currentVertexOffset1, currentVertexOffset2, origNextSwingCorner, currentCornerOnFan, i );
        return;
      }

      boolean advanceOnCurrentIsland = triangleStripList.get(i) ^ flip;
      if ( m_beachEdgesToExpand == m_beachEdgesExpanded )
      {
        print("Advance on currentIsland " + advanceOnCurrentIsland + "\n");
      }
      
      if ( advanceOnCurrentIsland )
      {
         //Given the current and next local vetex number, try to find out the correct next local vertex (including lagoon)
        int cornerNext = getCornerForHookPair( currentIsland, currentVertexOffset1, (currentVertexOffset1+1)%maxVertexNum );
        int prevCorner = p(cornerNext);
        //Unswing to get the outermost lagoon triangle
        while (o(p(prevCorner)) != -1 && (tm[o(p(prevCorner))] == ISLAND || tm[t(o(p(prevCorner)))] == LAGOON))
        {
            prevCorner = u(prevCorner);
        }

        int nextLocalVertex = getHookFromVertexNumber( v(n(prevCorner)), m_expansionIndex[currentIsland] );
        addTriangle( m_expansionIndex[currentIsland] + nextLocalVertex, m_expansionIndex[currentIsland] + currentVertexOffset1, m_expansionIndex[nextIsland] + currentVertexOffset2 );
        m_numTrianglesVTable[currentIsland]++;
        print("Adding triangle " + (m_expansionIndex[currentIsland] + nextLocalVertex) + " " + (m_expansionIndex[currentIsland] + currentVertexOffset1) + " " + m_expansionIndex[nextIsland] + currentVertexOffset2 + "\n");

        //Cache the corner got to by swinging for later use
        if (origNextSwingCorner == -1)
        {
          origNextSwingCorner = s(currentCornerOnFan);
        }

        //Set opposite of the beach edge and added triangle
        O[p(prevCorner)] = 3*nt-1;
        O[3*nt-1] = p(prevCorner);
          
        //Fixup opposites between channel and junction triangles
          
        O[3*nt-2] = o(n(currentCornerOnFan));
        O[o(n(currentCornerOnFan))] = 3*nt-2;
        O[3*nt-3] = n(currentCornerOnFan);
        O[n(currentCornerOnFan)] = 3*nt-3;

        tm[nt-1] = CHANNEL;
        currentVertexOffset1 = nextLocalVertex;      
      }
      else
      {
        print("Corner on fan is " + currentCornerOnFan + " " + origNextSwingCorner + " " + s(currentCornerOnFan) + "\n");
        if (origNextSwingCorner == -1)
        {
          currentCornerOnFan = s(currentCornerOnFan);
        }
        else
        {
          currentCornerOnFan = origNextSwingCorner;
        }
        V[currentCornerOnFan] = m_expansionIndex[currentIsland] + currentVertexOffset1;
        origNextSwingCorner = -1;
        print("Here " + v(p(currentCornerOnFan)) + " " + nextIsland + "\n" );
        currentVertexOffset2 = getHookFromVertexNumber( v(p(currentCornerOnFan)), m_expansionIndex[nextIsland] );
      }
      m_beachEdgesExpanded++;
    }
  }
  
  void onContractIsland()
  {
    int time = 0;
    int vertex = v(cc);
    //TODO msati3: Compaction?
    
    int island = getIslandForVertex( vertex );
    if ( island == -1 )
      return;
    cc = -1;
   
    int startCornerIsland = m_expansionIndexVTable[island];
    int currentCornerIsland = startCornerIsland;
    int initTrackedCorner = -1;
    int trackedCorner = -1;
    
    if ( m_numTimesContracted >= NUM_CONTRACTIONS )
    {
      compactBaseMesh();
      m_numTimesContracted = 0;
    }
    
    do
    {
      int currentCorner = currentCornerIsland;
      if ( DEBUG && DEBUG_MODE >= VERBOSE )
      {
        print("Current corner " + currentCorner + "\n");
      }
      int nextCorner = -1;
      int prevVertex = v(p(currentCornerIsland));
      do
      {
        if ( !belongsToIsland(v(n(currentCorner)), island) && !belongsToIsland(v(p(currentCorner)), island) )
        {
          if ( cc == -1 ) { cc = currentCorner; }
          if ( DEBUG && DEBUG_MODE >= VERBOSE )
          {
            print("Setting opposite " + currentCorner + "\n");
          }
          V[currentCorner] = island;
          if ( initTrackedCorner == -1 )
          {
            initTrackedCorner = currentCorner;
            trackedCorner = n(currentCorner);
          }
          else
          {
            O[trackedCorner] = p(currentCorner);
            O[p(currentCorner)] = trackedCorner;
            trackedCorner = n(currentCorner);
          }
        }
        currentCorner = s(currentCorner);
        if ( belongsToIsland(v(n(currentCorner)), island) && (nextCorner == -1) )
        {
          if ( v(n(currentCorner)) != prevVertex )
          {
            prevVertex = v(currentCorner);
            nextCorner = n(currentCorner);
          }
          else
          {
            if ( belongsToIsland(v(p(currentCorner)), island) )
            {
              prevVertex = v(p(currentCorner));
            }
          }
        }
      } while (currentCorner != currentCornerIsland);
      time++;
      currentCornerIsland = nextCorner;
    } while ( v(currentCornerIsland) != v(startCornerIsland) );
    O[trackedCorner] = p(initTrackedCorner);
    O[p(initTrackedCorner)] = trackedCorner;
    
    for (int i = m_expansionIndexVTable[island]; ; i+=3)
    {
      if (belongsToIsland(v(i), island) || belongsToIsland(v(i+1), island) || belongsToIsland(v(i+2), island))
      {
        V[i] = -1;
        V[i+1] = -1;
        V[i+2] = -1;
      }
      else
      {
        break;
      }
    }
    for (int i = m_expansionIndex[island]; i < m_expansionIndex[island] + VERTICES_PER_ISLAND ; i++)
    {
      G[i] = null;
    }
    m_expansionIndexVTable[island] = -1;
    m_expansionIndex[island] = -1;
    
    m_numTimesContracted++;
  }

  void explodeExpand()
  {
    for (int i = 0; i < nt; i++)
    {
      if ( ( tm[i] == CHANNEL + 10*(numTimes-1) ) || ( tm[i] == LAGOON + 10*(numTimes-1) ) || ( tm[i] == ISLAND + 10*(numTimes-1) ) || ( tm[i] == CAP + 10*(numTimes-1) ) )
      {
        visible[i] = false;
      }
      else
      {
        visible[i] = true;
      }
    }
  }
  
  void explodeExpandWithIsland()
  {
    for (int i = 0; i < nt; i++)
    {
      if (tm[i] == (numTimes-1)*10 + CHANNEL || tm[i] == (numTimes-1)*10 + CAP)
      {
        visible[i] = false;
      }
      else
      {
        visible[i] = true;
      }
    }
  }
  
  void compactBaseMesh()
  {
    print("Before compaction - vertices " + nv + " triangles " + nt + "\n");
    int getIndex = m_initSize;
    int putIndex = m_initSize;
    
    int VMapping[] = new int[3*nt]; //The mapping of old corners to new corners
    int GMapping[] = new int[nv];
    for (int i = m_initSize; i < nv; i++)
    {
      if ( G[i] != null )
      {
        GMapping[getIndex] = putIndex;
        G[putIndex++] = G[getIndex++];
      }
      else
      {
        getIndex++;
      }
    }
    nv = putIndex;

    getIndex = 0;
    putIndex = 0;
    for (int i = 0; i < 3*nt; i++)
    {
      if ( V[i] != -1 )
      {
        VMapping[getIndex] = putIndex;
        V[putIndex] = V[getIndex];
        O[putIndex++] = O[getIndex++];
      }
      else
      {
        getIndex++;
      }
    }
    nt = putIndex / 3;
    for (int i = 0; i < 3*nt; i++)
    {
      V[i] = GMapping[V[i]];
      O[i] = VMapping[O[i]];
    }
    
    for (int i = 0; i < numIslands; i++)
    {
      if ( m_expansionIndex[i] != -1 )
      {
        m_expansionIndex[i] = GMapping[m_expansionIndex[i]];
      }
      if ( m_expansionIndexVTable[i] != -1 )
      {
        m_expansionIndexVTable[i] = VMapping[m_expansionIndexVTable[i]];
      }
    }
    print("After compaction - vertices " + nv + " triangles " + nt + "\n");
  }
 
  void draw()
  {
    super.draw();
  }  
}

