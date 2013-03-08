class RingExpander
{
  private Mesh m_mesh;
  private int m_seed;
  private int m_numTrianglesToVisit;
  private int m_numTrianglesVisited;
  private RingExpanderResult m_ringExpanderResult;
  private boolean m_fColoringRingExpander;
  private int[] m_parentTriangles;

  public RingExpander(Mesh m)
  {
    m_mesh = m;
    m_seed = (m_mesh.cc);
    m_numTrianglesToVisit = -1;
    m_numTrianglesVisited = 0;
    m_parentTriangles = new int[m_mesh.nv];

    m_ringExpanderResult = null;

    for (int i = 0; i < m_mesh.nv; i++)
    {
      m_parentTriangles[i] = -1;
    }
  }

  private void colorTriangles(boolean[] vertexVisited, boolean[] triangleVisited)
  {
    for (int i = 0; i < triangleVisited.length; i++)
    {
      if (triangleVisited[i])
      {
        m_mesh.tm[i] = 0;
      }
      else
      {
        m_mesh.tm[i] = 2;
      }
    }
  }

  private void resetStateForRingExpander()
  {
    m_numTrianglesToVisit = 0;
  }

  private boolean onUpdateTriangleVisitCount()
  {
    if (m_numTrianglesVisited > m_numTrianglesToVisit && DEBUG && DEBUG_MODE > LOW)
    {
      print("Number of triangles visited exceeds the number of triangles desired to be visited. Bug!! ");
      return true;
    }
    if (m_numTrianglesVisited == m_numTrianglesToVisit)
    {
      return true;
    }
    return false; 
  }

  public void ringExpanderStep()
  {
    if (m_numTrianglesToVisit == -1)
    {
      resetStateForRingExpander();
    }

    Mesh m = m_mesh;
    int seed = m_seed;
    int init = seed;
    m_numTrianglesToVisit++;
    m_numTrianglesVisited = 0;

    boolean vertexVisited[] = new boolean[m.nv];
    boolean triangleVisited[] = new boolean[m.nt];

    vertexVisited[m.v(m.p(seed))] = true;

    do
    {
      if (!vertexVisited[m.v(seed)])
      {
         vertexVisited[m.v(seed)] = true;
         triangleVisited[m.t(seed)] = true;
         m_numTrianglesVisited++;
         if (onUpdateTriangleVisitCount())
         {
           break;
         }
      }
      else if (!triangleVisited[m.t(seed)]) 
      {
        seed = m.o(seed);
      }
      seed = m.r(seed);
    }while (seed != m.o(init));
    colorTriangles(vertexVisited, triangleVisited);
  }

  public void completeRingExpander()
  {
    Mesh m = m_mesh;
    int seed = m_seed;
    int init = seed;

    boolean vertexVisited[] = new boolean[m.nv];
    boolean triangleVisited[] = new boolean[m.nt];

    vertexVisited[m.v(m.p(seed))] = true;   

    do
    {
      if (!vertexVisited[m.v(seed)])
      {
         vertexVisited[m.v(seed)] = true;
         triangleVisited[m.t(seed)] = true;
      }
      else if (!triangleVisited[m.t(seed)]) 
      {
        seed = m.o(seed);
      }
      seed = m.r(seed);
    }while (seed != m.o(init));
    colorTriangles(vertexVisited, triangleVisited);

    m_numTrianglesToVisit = -1;
  }

  public void visitRecursively(int corner, boolean[] vertexVisited, boolean[] triangleVisited, int parentTriangle)
  {
    if ((m_numTrianglesToVisit == -1) || (m_numTrianglesVisited < m_numTrianglesToVisit))
    {
      if (!vertexVisited[m_mesh.v(corner)])
      {
        vertexVisited[m_mesh.v(corner)] = true;
        triangleVisited[m_mesh.t(corner)] = true;
        m_parentTriangles[m_mesh.v(corner)] = parentTriangle;
        m_numTrianglesVisited++;

        if (m_mesh.hasValidR(corner))
        {
          visitRecursively(m_mesh.r(corner), vertexVisited, triangleVisited, m_mesh.t(corner));
        }
        if (m_mesh.hasValidL(corner))
        {
          visitRecursively(m_mesh.l(corner), vertexVisited, triangleVisited, m_mesh.t(corner));
        }
      }
    }
  }

  public RingExpanderResult completeRingExpanderRecursive()
  {
    Mesh m = m_mesh;
    int seed = m_seed;

    boolean vertexVisited[] = new boolean[m.nv];
    boolean triangleVisited[] = new boolean[m.nt];

    vertexVisited[m.v(m.p(seed))] = true;   

    m_numTrianglesToVisit = -1;
    m_numTrianglesVisited = 0;

    visitRecursively(seed, vertexVisited, triangleVisited, -1);
    m_ringExpanderResult = new RingExpanderResult(m_mesh, seed, m_parentTriangles);

    return m_ringExpanderResult;
  }

  public void ringExpanderStepRecursive()
  {
    if (m_numTrianglesToVisit == -1)
    {
      resetStateForRingExpander();
    }

    Mesh m = m_mesh;
    int seed = m_seed;

    m_numTrianglesToVisit++;
    m_numTrianglesVisited = 0;

    boolean vertexVisited[] = new boolean[m.nv];
    boolean triangleVisited[] = new boolean[m.nt];

    vertexVisited[m.v(m.p(seed))] = true;   
    visitRecursively(seed, vertexVisited, triangleVisited, -1);

    colorTriangles(vertexVisited, triangleVisited);
  }
}

