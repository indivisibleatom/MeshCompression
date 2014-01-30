

int NUMLODS = 4;
int MAXTRIANGLES = 1000000;

class SuccLODMapperManager
{
  private SuccLODMapper []m_sucLODMapper = new SuccLODMapper[NUMLODS];
  int m_currentLODLevel = -1;

  public void addLODLevel()
  {
    m_currentLODLevel++;
    m_sucLODMapper[m_currentLODLevel] = new SuccLODMapper();
  }
  
  public SuccLODMapper getActiveLODMapper()
  {
    if ( m_currentLODLevel != -1 )
    {
      return m_sucLODMapper[m_currentLODLevel];
    }
    return null;
  }
  
  public void propagateNumberings()
  {
    for (int i = NUMLODS-1; i >= 0; i++)
    {
      m_sucLODMapper[i].createGExpansionPacket( ( (i == NUMLODS-1)?null : m_sucLODMapper[i+1]) );
      m_sucLODMapper[i].createEdgeExpansionPacket( ( (i == NUMLODS-1)?null : m_sucLODMapper[i+1]), m_sucLODMapper[NUMLODS-1].getBaseTriangles() );
    }
  }
}

class SuccLODMapper
{
  private Mesh m_base;
  private Mesh m_refined;
  private int [][]m_baseToRefinedVMap;
  private int []m_tBaseToRefinedTMap;
  private int [][]m_vBaseToRefinedTMap;

  private int []m_vertexNumberings;  //Mapping from the vertices ordered correctly (3i,3i+1,..) according to the base mesh to the actual vertex numbers in the main mesh > used to transition from one LOD to another.
  private int []m_triangleNumberings;  //Mapping from the triangles ordered correctly (N+4i,4i+1,...) according to the base mesh to the actual triangles numbers in the main mesh > used to transition from one LOD to another.
  private pt []m_GExpansionPacket;
  private boolean []m_edgeExpansionPacket;
  
  SuccLODMapper()
  {
  }
  
  public int getBaseTriangles()
  {
    return m_base.nt;
  }

  public void setBaseMesh( Mesh base )
  {
    m_base = base;
  }
  
  void setRefinedMesh( Mesh refined )
  {
    m_refined = refined;
  }
  
  void setBaseToRefinedVMap(int[][] vMap)
  {
    m_baseToRefinedVMap = vMap;
  }
  
  void setBaseToRefinedTMap(int[] tMap)
  {
    m_tBaseToRefinedTMap = tMap;
  }
  
  void setBaseVToRefinedTMap(int[][] vToTMap)
  {
    m_vBaseToRefinedTMap = vToTMap;
  }  
  
  void printVertexMapping()
  {
    int vertex = m_base.v(m_base.cc);
    print(m_base.cc + " " + vertex + " " + m_baseToRefinedVMap[vertex][0] + " " + m_baseToRefinedVMap[vertex][1] + " " + m_baseToRefinedVMap[vertex][2] + "\n");
    print(m_tBaseToRefinedTMap[m_base.t(m_base.cc)] + " " + m_vBaseToRefinedTMap[vertex][0] + " " + m_vBaseToRefinedTMap[vertex][1] + " " + m_vBaseToRefinedTMap[vertex][2] + " " +  m_vBaseToRefinedTMap[vertex][3] + "\n");
  }
  
  private void getSmallestBaseEdgeToExpand( int triangleNumber )
  {
    int corner =  m_refined.c(triangleNumber);
    int minBaseTriangle = MAXTRIANGLES;
    do
    {
      int triangleNumberDeterministic = getBaseTriangleNumberDeterministicForRefined( m_refined.t(m_refined.s(m_refined.o(corner))) );
      if (triangleNumberDeterministic < minBaseTriangle)
      {
        minBaseTriangle = m_refined.t(m_refined.s(m_refined.o(corner)));
      }
      corner = m_refined.n(corner);
    }while (corner != m_refined.c(triangleNumber) );
  }
  
  private void getNextEdgeToExpWand( int triangleNumber )
  {
    int currentTriangle = triangleNumber;
    int triangleNumber = s(triangleNumber);
  }
  
  private void traverseBaseAndConstructPacket()
  {
    for (int i = 0; i < m_refined.nt; i++)
    {
      if (m_refined.tm[i] == ISLAND)
      {
        int smallestBase = getSmallestBaseEdgeToExpand(i);
        setExpansionPacketToTrue(smallestBase, vertex);
        renumberVertices( smallestBase );
        int nextBase = getNextEdgeExpansion( smallestBase );
        setExpansionPacketToTrue(smallestBase, vertex);
        nextBase = getNextEdgeExpansion( nextBase );
        setExpansionPacketToTrue(smallestBase, vertex);
      }
    }
  }

  void createEdgeExpansionPacket(SuccLODMapper parent, int numBaseTriangles)
  {
    if ( parent == null )
    {
      int maxTriangleNumber = numBaseTriangles + 4*m_base.nv;
      m_edgeExpansionPacket = new boolean[3*numBaseTriangles];
      m_triangleNumberings = new int[maxTriangleNumber];
      traverseBaseAndConstructPacket();
      for (int i = 0; i < numBaseTriangles; i++)
      {
        m_triangleNumberings[i] = i;
      }
      int offset = numBaseTriangles;
      for (int i = 0; i < m_base.nv; i++)
      {
        for (int j = 0; j < 4; j++)
        {
          if ( m_vBaseToRefinedTMap[i][j] == -1 )
          {
            m_triangleNumberings[offset + 4*i + j] = m_vBaseToRefinedTMap[i][0];
          }
          else
          {
            m_triangleNumberings[offset + 4*i + j] = m_vBaseToRefinedTMap[i][j];
          }
        }
      }
    }
    else
    {
      int maxTriangleNumber = numBaseTriangles + 4*parent.m_vertexNumberings.length;
      m_edgeExpansionPacket = new boolean[3*maxTriangleNumber];
      m_triangleNumberings = new int[maxTriangleNumber];
      for (int i = 0; i < numBaseTriangles; i++)
      {
        m_triangleNumberings[i] = m_tBaseToRefinedTMap[parent.m_triangleNumberings[i]];
      }
      int offset = numBaseTriangles;
      for (int i = 0; i < parent.m_vertexNumberings.length; i++)
      {
        for (int j = 0; j < 4; j++)
        {
          if ( m_vBaseToRefinedTMap[parent.m_vertexNumberings[i]][j] == -1 )
          {
            m_triangleNumberings[offset + 4*i + j] = m_vBaseToRefinedTMap[parent.m_vertexNumberings[i]][0];
          }
          else
          {
            m_triangleNumberings[offset + 4*i + j] = m_vBaseToRefinedTMap[parent.m_vertexNumberings[i]][j];
          }
        }
      }
    }
  }
  
  void createGExpansionPacket(SuccLODMapper parent)
  {
    m_GExpansionPacket = new pt[3*m_base.nv];
    int []vertexNumberings;
    if ( parent == null )
    {
      vertexNumberings = new int[m_base.nv];
      for (int i = 0; i < m_base.nv; i++)
      {
        vertexNumberings[i] = i;
      }
      m_vertexNumberings = new int[3*m_base.nv];
    }
    else
    {
      m_vertexNumberings = new int[3*m_base.nv];
      vertexNumberings = parent.m_vertexNumberings;
    }
    for (int i = 0; i < vertexNumberings.length; i++)
    {
      for (int j = 0; j < 3; j++)
      {
        if (m_baseToRefinedVMap[vertexNumberings[i]][j] == -1)
        {
          m_GExpansionPacket[3*i+j] = P(m_refined.G[m_baseToRefinedVMap[vertexNumberings[i]][0]]);
          m_vertexNumberings[3*i+j] = m_baseToRefinedVMap[vertexNumberings[i]][0];
        }
        else
        {
          m_GExpansionPacket[3*i+j] = P(m_refined.G[m_baseToRefinedVMap[vertexNumberings[i]][j]]);
          m_vertexNumberings[3*i+j] = m_baseToRefinedVMap[vertexNumberings[i]][j];
        }
      }
    }
  }
}
