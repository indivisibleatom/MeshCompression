class IslandExpansionStream
{
  private String m_SLRString;
  private pt []m_G;  

  IslandExpansionStream()
  {
    m_SLRString = new String();
    m_G = new pt[ISLAND_SIZE + 2];
  }
  
  //TODO msati3: For simplicity. Can be speeded up by doing this is IslandExpansionManager
  void addG(int num, pt G, char SLRChar)
  {
    m_G[num] = P( G );
    if ( DEBUG && DEBUG_MODE >= VERBOSE )
    {
      print ("Adding G " + num + " " + SLRChar);
    }
    if ( num > 1 )
    {
      m_SLRString += SLRChar;
    }
  }
  
  pt[] getVertices()
  {
    return m_G;
  }
  
  Mesh createAndGetMesh()
  {
    Mesh m = new Mesh();
    m.addVertex( m_G[0] );
    m.addVertex( m_G[1] );
    int prevV = 0;
    int nextV = 1;
    for (int i = 2; i < m_G.length; i++)
    {
      if (prevV == -1)
      {
        if ( DEBUG && DEBUG_MODE >= LOW )
        {
            print("IslandExpansionStream : createAndGetMesh - Neither of S, L or R in LR string");
        }
      }
      m.addVertex( m_G[i] );
      m.addTriangle( prevV, i, nextV );
      m.tm[i-2] = ISLAND;
      if ( m_SLRString.charAt(i - 2) == 'r' )
      {
        prevV = i;
        nextV = nextV;
      }
      else if ( m_SLRString.charAt(i - 2) == 'l' )
      {
        prevV = prevV;
        nextV = i;
      }
      else if ( m_SLRString.charAt(i - 2) == 's' )
      {
        print("This case");
      }
      else
      {
        prevV = -1;
        nextV = -1;
      }
      if ( DEBUG && DEBUG_MODE >= VERBOSE )
      {
        print("IslandExpanderStream: create and get mesh - " + nextV + " " + prevV + " " + i + " " + m_SLRString.charAt(i-2) + "\n");
      }
    }
    return m;
  }
}

class IslandExpansionManager
{
  private ArrayList<IslandExpansionStream> m_islandStreams;
  
  IslandExpansionManager()
  {
    m_islandStreams = new ArrayList<IslandExpansionStream>();
  }
  
  IslandExpansionStream addIslandStream()
  {
    m_islandStreams.add( new IslandExpansionStream() );
    return getStream( m_islandStreams.size() - 1 );
  }
  
  void removeIslandStream(int islandNumber)
  {
    m_islandStreams.remove( islandNumber );
  }
  
  IslandExpansionStream getStream(int islandNumber)
  {
    return m_islandStreams.get( islandNumber );
  }
}

