int MAXLAGOONS = 1000; //TODO msati3: We should count this number from the island mesh

class IslandExpansionStream
{
  private pt []m_G;
  private String m_clersString;
  private int m_lagoonStartIndex;
  private int m_numLagoons;
  
  IslandExpansionStream()
  {
    m_G = new pt[VERTICES_PER_ISLAND];
    m_lagoonStartIndex = -1;
    m_numLagoons = 0;
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
  
  pt[] getG()
  {
    return m_G;
  }
  
  String getClersString()
  {
    return m_clersString;  
  }  
  
  int getNumberLagoons()
  {
    return m_numLagoons;
  }
  
  int getLagoonStartIndex()
  {
    return m_lagoonStartIndex;
  }
  
  int addLagoon(int currentLagoonsIndex)
  {
    if ( m_lagoonStartIndex == -1 )
    {
      m_lagoonStartIndex = currentLagoonsIndex;
    }
    m_numLagoons++;
    return m_lagoonStartIndex + (m_numLagoons-1);
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
  private IslandExpansionStream[] m_islandStreams;
  private LagoonExpansionStream[] m_lagoonExpansionStream;
  int m_nLagoons; //TODO msati3: Can this be removed? Store current total number of lagoons
  
  IslandExpansionManager()
  {
    m_islandStreams = new IslandExpansionStream[numIslands];
    m_lagoonExpansionStream = new LagoonExpansionStream[MAXLAGOONS];
    m_nLagoons = 0;
  }
  
  IslandExpansionStream addStream(int islandNumber)
  {
    m_islandStreams[ islandNumber ] = new IslandExpansionStream();
    return m_islandStreams[ islandNumber ];
  }
  
  IslandExpansionStream getStream(int islandNumber)
  {
    return m_islandStreams[ islandNumber ];
  }
  
  LagoonExpansionStream addLagoon(int islandNumber)
  {
    int numberLagoonsStream = m_islandStreams[islandNumber].addLagoon( m_nLagoons );
    m_lagoonExpansionStream[numberLagoonsStream] = new LagoonExpansionStream();
    m_nLagoons++; 
    return m_lagoonExpansionStream[numberLagoonsStream];
  }

  LagoonExpansionStream[] getLagoonExpansionStreams(int islandNumber)
  {
    LagoonExpansionStream[] expansionStreams = new LagoonExpansionStream[ m_islandStreams[islandNumber].getNumberLagoons() ];
    int startIndex = m_islandStreams[islandNumber].getLagoonStartIndex();
    for (int i = 0; i < m_islandStreams[islandNumber].getNumberLagoons(); i++)
    {
      expansionStreams[i] = m_lagoonExpansionStream[startIndex+i];
    }
    return expansionStreams;
  }
  
  void printStats()
  {
    float avgLagoons = 0;
    float numLagoons = 0;
    float avgLagoonSize = 0;
    for (int i = 0; i < numIslands; i++)
    {
      numLagoons += m_islandStreams[i].getNumberLagoons();
      for (int j = 0; j < m_islandStreams[i].getNumberLagoons(); j++)
      {
        int lagoonIndex = m_islandStreams[i].getLagoonStartIndex() + j;
        avgLagoonSize += m_lagoonExpansionStream[j].getClersString().length();
      }
    }
    avgLagoonSize /= numLagoons;
    avgLagoons = numLagoons / numIslands;
    print("Avg lagoon size " + avgLagoonSize + " Avg lagoons per island " + avgLagoons + "\n");
  }
}

