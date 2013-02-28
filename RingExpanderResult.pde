class RingExpanderResult
{
  private int m_seed;
  private int[] m_parentTArray;
  private int m_numTrianglesToColor;
  private int m_numTrianglesColored;
  Mesh m_mesh;
  
  public RingExpanderResult(Mesh m, int seed, int[] vertexArray)
  {
    m_seed = seed;
    m_parentTArray = vertexArray;
    m_mesh = m;
    m_numTrianglesToColor = -1;
  }
  
  private void setColor(int corner)
  {
    m_mesh.tm[m_mesh.t(corner)] = 0;
  }

  private boolean isValidChild(int childCorner, int parentCorner)
  {
    if ( (m_mesh.hasValidR(parentCorner) && childCorner == m_mesh.r(parentCorner)) || (m_mesh.hasValidL(parentCorner) && childCorner == m_mesh.l(parentCorner)) )
    {
      if (m_parentTArray[m_mesh.v(childCorner)] == m_mesh.t(parentCorner))
      {
        return true;
      }
    }
    return false;
  }
  
  private void label(int corner)
  {
    fill(255,0,0);
    pt vtx = m_mesh.G[m_mesh.v(corner)];
    translate(vtx.x, vtx.y, vtx.z);
      sphere(3);
    translate(-vtx.x, -vtx.y, -vtx.z);
  }
  
  private void visitAndColor(int corner)
  {
    if ((m_numTrianglesToColor == -1 || m_numTrianglesColored < m_numTrianglesToColor))
    {
      m_numTrianglesColored++;
      setColor(corner);
      label(corner);
      
      if (isValidChild(m_mesh.r(corner), corner))
      {
        visitAndColor(m_mesh.r(corner));
      }
      if (isValidChild(m_mesh.l(corner), corner))
      {
        visitAndColor(m_mesh.l(corner));
      }
    }
  }
  
  private int getLength(int corner)
  {
    int rightLen = 0;
    int leftLen = 0;
    if (isValidChild(m_mesh.r(corner), corner))
    {
      rightLen = getLength(m_mesh.r(corner));
    }
    if (isValidChild(m_mesh.l(corner), corner))
    {
      leftLen = getLength(m_mesh.l(corner));
    }

    return rightLen + leftLen + 1;    
  }
  
  public void advanceStep()
  {
    if (m_numTrianglesToColor != -1)
    {
      m_numTrianglesToColor++;
    }
  }
  
  public void stepColorRingExpander()
  {
    if (m_numTrianglesToColor == -1)
    {
      m_numTrianglesToColor = 0;
    }

    for (int i = 0; i < m_mesh.nt; i++)
    {
      m_mesh.tm[i] = 2;
    }
    
    m_numTrianglesColored = 0;
    visitAndColor(m_seed);
    m_mesh.tm[m_mesh.t(m_seed)] = 1;
  }
  
  public void colorRingExpander()
  {
    for (int i = 0; i < m_mesh.nt; i++)
    {
      m_mesh.tm[i] = 2;
    }
    visitAndColor(m_seed);
    m_mesh.tm[m_mesh.t(m_seed)] = 1;
    
    m_numTrianglesToColor = -1;
  }
  
  public void queryLength()
  {
    getLength(m_mesh.cc);
  }
}
