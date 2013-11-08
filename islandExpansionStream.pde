class IslandExpansionStream
{
  private pt []m_G;
  private int[]m_R;
  
  IslandExpansionStream()
  {
    m_R = new int[ISLAND_SIZE + 2];
    m_G = new pt[ISLAND_SIZE + 2];
  }
  
  void add(pt G, int i, int R)
  {
    m_G[i] = P( G );
    m_R[i] = R;
    if ( DEBUG && DEBUG_MODE >= VERBOSE )
    {
      print ("Adding G " + i + " R " + m_R[i]);
    }
  }
  
  pt[] getG()
  {
    return m_G;
  }
  
  int[] getR()
  {
    return m_R;  
  }  
}

/*
//Keeps information about hooks and expansions of channels that may be sent to 
class BaseMeshBookkeeper
{
  int[] m_hooks = new int [3*maxnt];               // V table (triangle/vertex indices)
  
}*/

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
    print("Remove island " + islandNumber);
    m_islandStreams.remove( islandNumber );
  }
  
  IslandExpansionStream getStream(int islandNumber)
  {
    return m_islandStreams.get( islandNumber );
  }
}

