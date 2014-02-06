class PacketFetcher
{
  pt[][] m_G;
  boolean[][] m_fExpandEdge;

  PacketFetcher()
  {
  }
  
  pt[] fetchGeometry( int lod, int order )
  {
    pt[] result = new pt[3];
    result[0] = P(m_G[lod][3*order]);
    result[1] = P(m_G[lod][3*order+1]);
    result[2] = P(m_G[lod][3*order+2]);
    return result;
  }
  
  
  boolean fetchConnectivity( int lod, int order )
  {
    return m_fExpandEdge[lod][order];
  }
}
