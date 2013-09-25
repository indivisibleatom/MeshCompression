class State
{
  private int m_corner;
  private int m_parentTriangle;

  public State(int corner, int parent)
  {
    m_corner = corner;
    m_parentTriangle = parent;
  }
  
  public int corner()
  {
    return m_corner;
  }
  
  public int parentTriangle()
  {
    return m_parentTriangle;
  }
}

class RingExpander
{
  private Mesh m_mesh;
  private int m_seed;
  private int m_numTrianglesToVisit;
  private int m_numTrianglesVisited;
  private RingExpanderResult m_ringExpanderResult;
  private boolean m_fColoringRingExpander;
  private int[] m_parentTriangles;

  boolean[] m_vertexVisited;
  boolean[] m_triangleVisited;

  Stack< State > m_recursionStack;
  
  public RingExpander(Mesh m, int seed)
  {
    m_mesh = m;
    m_mesh.resetMarkers();
    m_seed = 0;

    if (seed != -1)
    {
      print("Seed for ringExpander " + seed);
      m_seed = seed;
    }
    m_mesh.cc = m_seed;

    m_numTrianglesToVisit = -1;
    m_numTrianglesVisited = 0;
    m_parentTriangles = new int[m_mesh.nt * 3];

    m_ringExpanderResult = null;

    for (int i = 0; i < m_mesh.nt * 3; i++)
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
        m_mesh.tm[i] = ISLAND;
      }
      else
      {
        m_mesh.tm[i] = CHANNEL;
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

  public void visitRecursively()
  {
    while (((m_numTrianglesToVisit == -1) || (m_numTrianglesVisited < m_numTrianglesToVisit)) &&(!m_recursionStack.empty()))
    {
      State currentState = m_recursionStack.pop();
      int corner = currentState.corner();
      int parentTriangle = currentState.parentTriangle();

      if (!m_vertexVisited[m_mesh.v(corner)])
      {
        m_vertexVisited[m_mesh.v(corner)] = true;
        m_triangleVisited[m_mesh.t(corner)] = true;
        m_parentTriangles[corner] = parentTriangle;
        m_numTrianglesVisited++;

        if (m_mesh.hasValidL(corner))
        {
          m_recursionStack.push(new State(m_mesh.l(corner), m_mesh.t(corner)));
        }
        if (m_mesh.hasValidR(corner))
        {
          m_recursionStack.push(new State(m_mesh.r(corner), m_mesh.t(corner)));
        }
      }
    }
  }

  public RingExpanderResult completeRingExpanderRecursive()
  {
    Mesh m = m_mesh;
    int seed = m_seed;

    m_vertexVisited = new boolean[m.nv];
    m_triangleVisited = new boolean[m.nt];
    m_recursionStack = new Stack();

    m_vertexVisited[m.v(m.p(seed))] = true;   
    m_vertexVisited[m.v(m.n(seed))] = true;   

    m_numTrianglesToVisit = -1;
    m_numTrianglesVisited = 0;

    m_recursionStack.push(new State(seed, -1));
    visitRecursively();
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

    m_vertexVisited = new boolean[m.nv];
    m_triangleVisited = new boolean[m.nt];
    m_recursionStack = new Stack();

    m_vertexVisited[m.v(m.p(seed))] = true;
    m_vertexVisited[m.v(m.n(seed))] = true;   

    m_recursionStack.push(new State(seed, -1));
    visitRecursively();

    colorTriangles(m_vertexVisited, m_triangleVisited);
  }
}

