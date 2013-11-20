class IslandExpansionStream
{
  private pt []m_G;
  private String m_clersString;
  private ArrayList< LagoonExpansionStream > m_lagoonStreams;
  
  IslandExpansionStream()
  {
    m_G = new pt[VERTICES_PER_ISLAND];
    m_lagoonStreams = new ArrayList<LagoonExpansionStream>();
  }
  
  void add(pt G, int i)
  {
    m_G[i] = P( G );
    if ( DEBUG && DEBUG_MODE >= VERBOSE )
    {
      print ("Adding G " + i );
    }
  }
  
  void setClersString(String clersString)
  {
    m_clersString = clersString;
  }
  
  LagoonExpansionStream addLagoonExpansionStream()
  {
    LagoonExpansionStream lagoonStream = new LagoonExpansionStream();
    m_lagoonStreams.add(lagoonStream);
    return lagoonStream;
  }
  
  ArrayList<LagoonExpansionStream> getLagoonExpansionStreamList()
  {
    return m_lagoonStreams;
  }
  
  pt[] getG()
  {
    return m_G;
  }
  
  String getClersString()
  {
    return m_clersString;  
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

