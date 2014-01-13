int NUMLODS = 4;

class SuccLODMapperManager
{
  private SuccLODMapper []m_sucLODMapper = new SuccLODMapper[NUMLODS];
}

class SuccLODMapper
{
  private Mesh m_base;
  private Mesh m_refined;
  private int []m_baseToRefinedVMap;
  
  SuccLODMapper()
  {
  }
  
  void setBaseMesh( Mesh base )
  {
    m_base = base;
  }
  
  void setRefinedMesh( Mesh refined )
  {
    m_refined = refined;
  }
  
  void addBaseToRefinedVMapEntry(int index, int entry1, int entry2, int entry3)
  {
    
  }
}
