class PacketFetcher
{
  SuccLODMapperManager m_lodMapperManager;

  PacketFetcher( SuccLODMapperManager manager )
  {
    m_lodMapperManager = manager;
  }
  
  pt[] fetchGeometry( int lod, int order )
  {
    SuccLODMapper mapper = m_lodMapperManager.getMapperForLOD(lod);
    pt[] result = new pt[3];
    result[0] = P(mapper.getGeometry(3*order));
    result[1] = mapper.getGeometry(3*order+1) == null ? null : P(mapper.getGeometry(3*order+1));
    result[2] = mapper.getGeometry(3*order+2) == null ? null : P(mapper.getGeometry(3*order+2));
    return result;
  }
  
  
  boolean fetchConnectivity( int lod, int order )
  {
    SuccLODMapper mapper = m_lodMapperManager.getMapperForLOD(lod);
    return mapper.getConnectivity(order);
  }
}
