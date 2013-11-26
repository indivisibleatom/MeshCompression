class ChannelExpansionTriangleStrip
{
  ChannelExpansionTriangleStrip( ArrayList<Boolean> expansion )
  {
    m_expansion = expansion;
  }
  
  ChannelExpansionTriangleStrip reverse()
  {
    ArrayList<Boolean> rev = new ArrayList<Boolean>();
    for (int i = m_expansion.size() - 1; i >= 0; i--)
    {
      rev.add( m_expansion.get(i) );
    }
    ChannelExpansionTriangleStrip newExpansion = new ChannelExpansionTriangleStrip( rev );
    return newExpansion;
  }
  
  ArrayList<Boolean> expansion() { return m_expansion; }
  
  private ArrayList<Boolean> m_expansion;
}

class ChannelExpansionPacketManager
{
  private int m_size;
  int nc;

  ChannelExpansionPacket[] m_channelExpansionPackets;
  
  ChannelExpansionPacketManager(int numTriangles)
  {
    m_channelExpansionPackets = new ChannelExpansionPacket[3*numTriangles];
    m_size = 0;
    nc = 0;
  }
  
  void addChannelExpansionPacket(int island1, int island2, int island3, int hook1, int hook2, int hook3)
  {
    m_channelExpansionPackets[m_size] = new ChannelExpansionPacket(island1, hook1);
    m_channelExpansionPackets[m_size+1] = new ChannelExpansionPacket(island2, hook2);
    m_channelExpansionPackets[m_size+2] = new ChannelExpansionPacket(island3, hook3);
    m_size += 3;
    nc = m_size;
  }
  
  void setTriangleStrip( int corner, ChannelExpansionTriangleStrip triangleStrip )
  {
    m_channelExpansionPackets[corner].setTriangleStrip( triangleStrip );
  }
  
  int islandForCorner( int corner )
  {
    return m_channelExpansionPackets[corner].island();
  }
  
  int hookForCorner( int corner )
  {
    return m_channelExpansionPackets[corner].hook();
  }
  
  ChannelExpansionTriangleStrip triangleStripForCorner( int corner )
  {
    return m_channelExpansionPackets[corner].triangleStrip();
  }
  
  int getTriangle( int island1, int island2, int island3, int hook1, int hook2, int hook3 )
  {
    int []islands = {island1, island2, island3};
    int []hooks = {hook1, hook2, hook3};
    
    int lowestIndex = island1 <= island2? 0 : 1;
    lowestIndex = islands[lowestIndex] <= island3? lowestIndex : 2;
    
    int triangleRet = -1;
    boolean fTriangleFound = false;
    
    for (int i = 0; i < m_size / 3; i++)
    {
      fTriangleFound = true;
      for (int j = 0; j < 3; j++)
      {
        if ( islandForCorner(3*i + j) == islands[(lowestIndex+j)%3] && hookForCorner(3*i + j) == hooks[(lowestIndex+j)%3] )
          continue;
        fTriangleFound = false;
      }
      if (fTriangleFound)
        return i;
    }
    return -1;
  }
}

class ChannelExpansionPacket
{
  private int m_island;
  private int m_hook;
  
  private ChannelExpansionTriangleStrip m_triangleStrips; 
  
  ChannelExpansionPacket(int island, int hook)
  {
    m_island = island;
    m_hook = hook;
    m_triangleStrips = null;
  }
  
  void setTriangleStrip( ChannelExpansionTriangleStrip triangleStrip )
  {
    m_triangleStrips = triangleStrip;
  }
  
  int island()
  {
    return m_island;
  }
  
  int hook()
  {
    return m_hook;
  }
  
  ChannelExpansionTriangleStrip triangleStrip()
  {
    return m_triangleStrips;
  }
}
