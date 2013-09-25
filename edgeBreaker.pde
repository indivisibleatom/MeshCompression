class EgdeBreakerCompress
{
  private Mesh m_mesh;
  private boolean[] m_tVisited;
  private boolean[] m_vVisited;
  int m_numTrianglesVisited;
  String m_edgeBreakerString;

  public EgdeBreakerCompress(Mesh mesh)
  {
    m_mesh = mesh;
    m_tVisited = new boolean[m_mesh.nt];
    m_vVisited = new boolean[m_mesh.nv];
    m_edgeBreakerString = new String();
  }

  public void initCompression()
  {
    int initCorner = 0;
    m_vVisited[m_mesh.v(initCorner)] = true;
    m_vVisited[m_mesh.v(m_mesh.n(initCorner))] = true;
    m_vVisited[m_mesh.v(m_mesh.p(initCorner))] = true;
    m_tVisited[m_mesh.t(initCorner)] = true;
    m_numTrianglesVisited = 1;
    compress(m_mesh.o(initCorner));
    print ("EdgeBreaker compression" + m_edgeBreakerString);
  }

  public boolean allTrianglesVisited()
  {
    return (m_numTrianglesVisited == m_mesh.nt);
  }

  public void compress(int corner)
  {
    do
    {
      m_tVisited[m_mesh.t(corner)] = true;
      m_numTrianglesVisited++;
      if ( !m_vVisited[m_mesh.v(corner)] )
      {
        m_edgeBreakerString+="C";
        m_vVisited[m_mesh.v(corner)] = true;
      }
      else if ( m_tVisited[m_mesh.t(m_mesh.r(corner))] )
      {
        if ( m_tVisited[m_mesh.t(m_mesh.l(corner))] )
        {
          m_edgeBreakerString+="E";
          return;
        }
        else
        {
          m_edgeBreakerString+="R";
          corner = m_mesh.l( corner );
        }
      }
      else
      {
        if ( m_tVisited[m_mesh.t(m_mesh.l(corner))] )
        {
          m_edgeBreakerString+="L";
          corner = m_mesh.r( corner );
        }
        else
        {
          m_edgeBreakerString+="S";
          compress( m_mesh.r( corner ) );
          corner = m_mesh.l( corner );
        }
      }
    } 
    while ( true );
  }
}

