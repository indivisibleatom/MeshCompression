int NUMLODS = 2;
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
  
  public boolean fMaxSimplified()
  {
    return (m_currentLODLevel >= NUMLODS - 1);
  }
  
  public SuccLODMapper getActiveLODMapper()
  {
    if ( m_currentLODLevel != -1 )
    {
      return m_sucLODMapper[m_currentLODLevel];
    }
    return null;
  }
  
  public SuccLODMapper getMapperForLOD(int LOD)
  {
    return m_sucLODMapper[LOD];
  }
  
  public SuccLODMapper getLODMapperForBaseMeshNumber(int number)
  {
    if ( m_currentLODLevel != -1 )
    {
      if ( number > 0 )
      {
        return m_sucLODMapper[number - 1];
      }
      else
      {
        return m_sucLODMapper[number];
      }
    }
    return null;
  }
  
  public void propagateNumberings()
  {
    for (int i = NUMLODS-1; i >= 0; i--)
    {
      m_sucLODMapper[i].createGExpansionPacket( ( (i == NUMLODS-1)?null : m_sucLODMapper[i+1]) );
      m_sucLODMapper[i].createTriangleNumberings( ( (i == NUMLODS-1)?null : m_sucLODMapper[i+1]), m_sucLODMapper[NUMLODS-1].getBaseTriangles() );
      print("LOD " + i + "\n");
      m_sucLODMapper[i].checkNumberings();
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

  private int[] m_refinedTriangleToOrderedTriangle;
  private int[] m_refinedTriangleToAssociatedVertexNumber;
  SuccLODMapper m_parent;
  
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
  
  pt getGeometry( int index )
  {
    return m_GExpansionPacket[index];
  }
  
  boolean getConnectivity( int index )
  {
    return m_edgeExpansionPacket[index];
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

  private void printVertexNumberings( int vertex, boolean useParent )
  {
    if ( useParent )
    {
      for (int i = 0; i < m_parent.m_vertexNumberings.length; i++)
      {
        if (vertex == m_parent.m_vertexNumberings[i])
        {
          print(i + " ");
        }
      }
    }
    else
    {
      for (int i = 0; i < m_vertexNumberings.length; i++)
      {
        if (vertex == m_vertexNumberings[i])
        {
          print(i + " ");
        }
      }
    }
  }
  
  private void printTriangleNumberings( int triangle, boolean useParent )
  {
    if ( useParent )
    {
      for (int i = 0; i < m_parent.m_triangleNumberings.length; i++)
      {
        if (triangle == m_parent.m_triangleNumberings[i])
        {
          print(i + " ");
        }
      }
    }
    else
    {
      for (int i = 0; i < m_triangleNumberings.length; i++)
      {
        if (triangle == m_triangleNumberings[i])
        {
          print(i + " ");
        }
      }
    }
  }
  
  void printVertexMapping(int corner, int meshNumber)
  {
    //Treating corner for the base mesh
    if (meshNumber != 0)
    {
      int vertex = m_base.v(corner);
      print("\nBaseToRefinedVMap " + corner + " " + vertex + " " + m_baseToRefinedVMap[vertex][0] + " " + m_baseToRefinedVMap[vertex][1] + " " + m_baseToRefinedVMap[vertex][2] + "\n");
      print("BaseToRefinedTMap " + m_tBaseToRefinedTMap[m_base.t(corner)] + " " + m_vBaseToRefinedTMap[vertex][0] + " " + m_vBaseToRefinedTMap[vertex][1] + " " + m_vBaseToRefinedTMap[vertex][2] + " " +  m_vBaseToRefinedTMap[vertex][3] + "\n");
    }
    
    //Treating corner for the refined mesh
    if (meshNumber == 1)
    {
      print("VertexNumbering for vertex ");
      int vertex = m_base.v(corner);
      printVertexNumberings( vertex, true );
      print("\n");
      
      print("TriangleNumbering for triangle ");
      int triangle = m_base.t(corner);
      printTriangleNumberings( triangle, true );
      print("\n");
    }
    if (meshNumber == 0)
    {
      print("VertexNumbering for vertex ");
      int vertex = m_refined.v(corner);
      printVertexNumberings( vertex, false );
      print("\n");

      int triangle = m_refined.t(corner);
      print("TriangleNumbering for triangle ");
      printTriangleNumberings( triangle, false );
      print("\n");    }    
  }

  private int getEdgeOffset( int corner )
  {
    corner %= 3;
    return m_refined.p(corner);
  }
  
  //Given a base triangle numbering, returns one ordered triangle corresponding to the base triangle
  private int getOrderedTriangleNumberInBase( SuccLODMapper parent, int baseTriangle )
  {
    if ( parent != null )
    {
      return parent.m_refinedTriangleToOrderedTriangle[baseTriangle];
    }
    else
    {
      return baseTriangle;
    }
  }

  //Given a refined triangle, returns one ordered vertex corresponding to the base vertex that expands to the refined triangle
  private int getOrderedVertexNumberInBase( int refinedTriangle )
  {
    return m_refinedTriangleToAssociatedVertexNumber[ refinedTriangle ];
  }
  
  private int findOrderedTriangle( int triangleRefined )
  {
    for (int i = 0; i < m_triangleNumberings.length; i++)
    {
      if ( m_triangleNumberings[i] == triangleRefined )
        return i;
    }
    return -1;
  }

  void createTriangleNumberings(SuccLODMapper parent, int numBaseTriangles)
  {
    m_refinedTriangleToAssociatedVertexNumber = new int[m_refined.nt];
    for (int i = 0; i < m_refinedTriangleToAssociatedVertexNumber.length; i++)
    {
      m_refinedTriangleToAssociatedVertexNumber[i] = -1;
    }

    if ( parent == null )
    {
      int maxTriangleNumber = numBaseTriangles + 4*m_base.nv;
      m_edgeExpansionPacket = new boolean[3*maxTriangleNumber];
      m_triangleNumberings = new int[maxTriangleNumber];
      for (int i = 0; i < m_edgeExpansionPacket.length; i++)
      {
        m_edgeExpansionPacket[i] = false;
      }
      for (int i = 0; i < numBaseTriangles; i++)
      {
        m_triangleNumberings[i] = m_tBaseToRefinedTMap[i];
      }
      int offset = numBaseTriangles;
      for (int i = 0; i < m_base.nv; i++)
      {
        for (int j = 0; j < 4; j++)
        {
          if ( m_vBaseToRefinedTMap[i][j] == -1 )
          {
            m_triangleNumberings[offset + 4*i + j] = -1;
          }
          else
          {
            m_triangleNumberings[offset + 4*i + j] = m_vBaseToRefinedTMap[i][j];
            if ( m_refinedTriangleToAssociatedVertexNumber[m_vBaseToRefinedTMap[i][j]] == -1 )
            {
              m_refinedTriangleToAssociatedVertexNumber[m_vBaseToRefinedTMap[i][j]] = offset + 4*i + j;
            }
          }
        }
      }
    }
    else
    {
      int maxTriangleNumber = parent.m_triangleNumberings.length + 4*parent.m_vertexNumberings.length;
      m_edgeExpansionPacket = new boolean[3*maxTriangleNumber];
      for (int i = 0; i < m_edgeExpansionPacket.length; i++)
      {
        m_edgeExpansionPacket[i] = false;
      }
      m_triangleNumberings = new int[maxTriangleNumber];
      for (int i = 0; i < parent.m_triangleNumberings.length; i++)
      {
        if ( parent.m_triangleNumberings[i] == -1 )
        {
          m_triangleNumberings[i] = -1;
        }
        else
        {
          m_triangleNumberings[i] = m_tBaseToRefinedTMap[parent.m_triangleNumberings[i]];
        }
      }
      int offset = parent.m_triangleNumberings.length;
      for (int i = 0; i < parent.m_vertexNumberings.length; i++)
      {
        for (int j = 0; j < 4; j++)
        {
          if ( m_vBaseToRefinedTMap[parent.m_vertexNumberings[i]][j] == -1 )
          {
            m_triangleNumberings[offset + 4*i + j] = -1;
          }
          else
          {
            if ( m_refinedTriangleToAssociatedVertexNumber[m_vBaseToRefinedTMap[parent.m_vertexNumberings[i]][j]] == -1 )
            {
              m_refinedTriangleToAssociatedVertexNumber[m_vBaseToRefinedTMap[parent.m_vertexNumberings[i]][j]] = offset + 4*i + j;
            }
            m_triangleNumberings[offset + 4*i + j] = m_vBaseToRefinedTMap[parent.m_vertexNumberings[i]][j];
          }
        }
      }
    }

    m_refinedTriangleToOrderedTriangle = new int[m_refined.nt];
    for (int i = 0; i < m_refinedTriangleToOrderedTriangle.length; i++)
    {
      m_refinedTriangleToOrderedTriangle[i] = findOrderedTriangle(i); //TODO msati3: faster by caching
    }
  }
  
  private int getVertexNumbering(int vertex)
  {
    for (int i = 0; i < m_vertexNumberings.length; i++)
    {
      if ( m_vertexNumberings[i] == vertex )
      {
        return i;
      }
    }
    print("No vertex numbering found for vertex " + vertex + "\n");
    return -1;
  }
  
  private int getTriangleNumbering(int triangle)
  {
    for (int i = 0; i < m_triangleNumberings.length; i++)
    {
      if ( m_triangleNumberings[i] == triangle )
      {
        return i;
      }
    }
    print("No triangle numbering found for triangle " + triangle + "\n");
    return -1;
  }
  
  private void checkNumberings()
  {
    for (int i = 0; i < m_refined.nv; i++)
    {
      getVertexNumbering( i );
    }
    for (int i = 0; i < m_refined.nt; i++)
    {
      getTriangleNumbering( i );
    }
  }  
  
  
  private void createEdgeExpansionPacket(SuccLODMapper parent, int numBaseTriangles)
  {
    for (int i = 0; i < m_refined.nt; i++)
    {
      if ( m_refined.tm[i] == ISLAND )
      {
        int corner1 = m_refined.c(i);
        int oppositeCorner1 = m_refined.o(corner1);
        int baseTriangle1 = m_refined.t(m_refined.s(oppositeCorner1));
        int offset1 = getEdgeOffset(m_refined.s(oppositeCorner1));

        int corner2 = m_refined.n(corner1);
        int oppositeCorner2 = m_refined.o(corner2);
        int baseTriangle2 = m_refined.t(m_refined.s(oppositeCorner2));
        int offset2 = getEdgeOffset(m_refined.s(oppositeCorner1));

        int corner3 = m_refined.p(corner1);
        int oppositeCorner3 = m_refined.o(corner3);
        int baseTriangle3 = m_refined.t(m_refined.s(oppositeCorner3));
        int offset3 = getEdgeOffset(m_refined.s(oppositeCorner1));
        
        int t1 = getTriangleNumbering(baseTriangle1);
        int t2 = getTriangleNumbering(baseTriangle2);
        int t3 = getTriangleNumbering(baseTriangle3);
        
        /*int t1 = getOrderedTriangleNumberInBase( parent, getTriangleNumbering(baseTriangle1) );
        int t2 = getOrderedTriangleNumberInBase( parent, getTriangleNumbering(baseTriangle2) );
        int t3 = getOrderedTriangleNumberInBase( parent, getTriangleNumbering(baseTriangle3) );*/
        
        m_edgeExpansionPacket[3*t1 + offset1] = true;
        m_edgeExpansionPacket[3*t2 + offset2] = true;
        m_edgeExpansionPacket[3*t3 + offset3] = true;
        
        int vertexBase = getOrderedVertexNumberInBase( i ); //TODO msati3: Cache this

        //Renumber the G packet
        /*int offset = 0;
        if ( t2 < t3 && t2 < t1 )
        {
          offset = 1;
        }
        if ( t3 < t2 && t3 < t1 )
        {
          offset = 2;
        }
        pt temp = m_GExpansionPacket[3*vertexBase+offset];
        m_GExpansionPacket[3*vertexBase+offset] = m_GExpansionPacket[3*vertexBase+(offset+1)%3];
        offset = (offset + 1) % 3;
        m_GExpansionPacket[3*vertexBase+offset] = m_GExpansionPacket[3*vertexBase+(offset+1)%3];
        offset = (offset + 1) % 3;
        m_GExpansionPacket[3*vertexBase+offset] = temp;*/
      }
    }
  }
  
  //Given a base vertex and triangle, return a corner in the refined mesh in the corresponding triangle so that it is incident upon v's expansion and its incident half edge is shared with a channel
  private int findCornerInRefined( int baseV, int baseT )
  {
    int[] vertexInRefined  = m_baseToRefinedVMap[baseV];
    if (vertexInRefined[1] == -1)
      return -1;
    int triangleInRefined = m_tBaseToRefinedTMap[baseT];

    int corner = m_refined.c(triangleInRefined);
    for (int i = 0; i < 3; i++)
    {
      int currentCorner = corner;
      do
      {
        if (m_refined.v(currentCorner) == vertexInRefined[i] && m_refined.tm[m_refined.t(m_refined.s(currentCorner))] == CHANNEL && m_refined.tm[m_refined.t(m_refined.s(m_refined.s(currentCorner)))] == ISLAND)
        {
          //print("Found");
          return currentCorner;
        }
        currentCorner = m_refined.n(currentCorner);
      }while (currentCorner != corner);
    }
    
    if ( DEBUG && DEBUG_MODE >= HIGH )
    {
      print("SuccLODMapper::findCornerInRefined returing -1!!");
    }
    return -1;
  }
  
  void createGExpansionPacket(SuccLODMapper parent)
  {
    m_parent = parent; //TODO msati: Debug hack...remove

    int []vertexNumberings;
    if ( parent == null )
    {
      vertexNumberings = new int[m_base.nv];
      for (int i = 0; i < m_base.nv; i++)
      {
        vertexNumberings[i] = i;
      }
      m_vertexNumberings = new int[3*m_base.nv];
      m_GExpansionPacket = new pt[3*m_base.nv];
    }
    else
    {
      vertexNumberings = parent.m_vertexNumberings;
      m_vertexNumberings = new int[3*vertexNumberings.length];
      m_GExpansionPacket = new pt[3*vertexNumberings.length];
    }
    
    //Order the G entries correctly
    int[] minTPerVBase = new int[m_base.nv]; //Stores the min T incident on the base vertices
    int[] cornerRefinedPerVBase = new int[m_base.nv]; //Caches corner in refined for min t
    for (int i = 0; i < m_base.nv; i++)
    {
      minTPerVBase[i] = m_base.nt;
      cornerRefinedPerVBase[i] = -1;
    }
    for (int i = 0; i < m_base.nc; i++)
    {
      int vertexBase = m_base.v(i);
      int tBase = m_base.t(i);
      int corner = findCornerInRefined( vertexBase, tBase );
      if ( corner != -1 ) //If expandable
      {
        if ( tBase < minTPerVBase[vertexBase] )
        {
          minTPerVBase[vertexBase] = tBase;
          cornerRefinedPerVBase[vertexBase] = corner;
        }
      }
    }
    for (int i = 0; i < m_base.nv; i++)
    {
      int corner = cornerRefinedPerVBase[i];
      if ( corner != -1 )
      {
        int cornerIsland = m_refined.s(m_refined.s(corner));
        if (DEBUG && DEBUG_MODE >= LOW)
        {
          if (m_refined.tm[m_refined.t(cornerIsland)] != ISLAND)
          {
            print("Something wrong! Not an island on double swing");
          }
        }
        if ( (cornerIsland%3) != 0)
        {
          int offset = (cornerIsland%3);
          int []newVMap = new int[3];
          int []newTMap = new int[3];
          for (int j = 0; j < 3; j++)
          {
            newVMap[j] = m_baseToRefinedVMap[i][(j+offset)%3];
            newTMap[j] = m_vBaseToRefinedTMap[i][1+(j+offset)%3];
          }
          for (int j = 0; j < 3; j++)
          {
            m_baseToRefinedVMap[i][j] = newVMap[j];
            m_vBaseToRefinedTMap[i][j+1] = newTMap[j];
          }
        }
      }
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
