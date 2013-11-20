class LagoonExpansionStream
{
  private int m_vertex1;
  private int m_vertex2;
  
  private String m_clersString;
  
  LagoonExpansionStream()
  {
  }
  
  void setVertices( int vertex1, int vertex2 )
  {
    m_vertex1 = vertex1;
    m_vertex2 = vertex2;
  }
  
  void setClersString( String clersString )
  {
    m_clersString = clersString;
  }
  
  String getClersString()
  {
    return m_clersString;
  }
  
  int vertex1() { return m_vertex1; }
  int vertex2() { return m_vertex2; }
}
