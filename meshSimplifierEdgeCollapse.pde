class MeshSimplifierEdgeCollapse
{
  private Mesh m_mesh;
  private Mesh m_simplifiedMesh;
  private SuccLODMapperManager m_succLODMapperManager;
  int[][] m_vertexMappingBaseToMain;
  int[] m_triangleMappingBaseToMain;
  int[][] m_vertexToTriagleMappingBaseToMain;
  
  MeshSimplifierEdgeCollapse( Mesh m, SuccLODMapperManager sLODMapperManager )
  {
    m_mesh = m;
    m_simplifiedMesh = new Mesh();
    m_succLODMapperManager = sLODMapperManager;
    m_vertexMappingBaseToMain = new int[m_mesh.nv][3];
    m_triangleMappingBaseToMain = new int[m_mesh.nt];
    m_vertexToTriagleMappingBaseToMain = new int[m_mesh.nv][4];

    m_succLODMapperManager.addLODLevel();
    m_succLODMapperManager.getActiveLODMapper().setBaseMesh(m_simplifiedMesh);
    m_succLODMapperManager.getActiveLODMapper().setRefinedMesh(m_mesh);
  }
  
  private pt centroid(Mesh m, int triangleIndex)
  {
    pt pt1 = m.G[m.v(m.c(triangleIndex))];
    pt pt2 = m.G[m.v(m.c(triangleIndex) + 1)];
    pt pt3 = m.G[m.v(m.c(triangleIndex) + 2)];

    return P(pt1, pt2, pt3);
  }
  
  private void copyMainToSimplifiedMesh()
  {
    //First create copy of orig mesh 
    for (int i = 0; i < m_mesh.nv; i++) 
    {
      m_vertexMappingBaseToMain[i][0] = i;
      m_vertexMappingBaseToMain[i][1] = -1;
      m_vertexMappingBaseToMain[i][2] = -1;
      
      m_vertexToTriagleMappingBaseToMain[i][0] = -1;
      m_vertexToTriagleMappingBaseToMain[i][1] = -1;
      m_vertexToTriagleMappingBaseToMain[i][2] = -1;
      m_vertexToTriagleMappingBaseToMain[i][3] = -1;     

      m_simplifiedMesh.G[i] = P(m_mesh.G[i]);
    }
    m_simplifiedMesh.nv = m_mesh.nv;

    for (int i = 0; i < m_mesh.nc; i++)
    {
      m_simplifiedMesh.V[i] = m_mesh.V[i];
    }
    m_simplifiedMesh.nt = m_mesh.nt;

    for (int i = 0; i < m_mesh.nc; i++) 
    {
      m_simplifiedMesh.O[i] = m_mesh.O[i];
    }

    m_simplifiedMesh.resetMarkers();

    for (int i = 0; i < m_mesh.nt; i++)
    {
      m_triangleMappingBaseToMain[i] = i;
      m_simplifiedMesh.tm[i] = m_mesh.tm[i];
    }
    m_simplifiedMesh.nc = m_mesh.nc;
  }
  
  //Ch
  private void populateOpposites( int c )
  {
    int l = m_simplifiedMesh.l(c);
    int r = m_simplifiedMesh.r(c);
    m_simplifiedMesh.O[l] = r;
    m_simplifiedMesh.O[r] = l;
  }
  
  private void shifGUp( pt[] G, int lower, int higher)
  {
    int offset = 1;
    for (int i = lower+1; i < m_mesh.nv; i++)
    {
      if ( i == higher )
      {
        offset = 2;
      }
      else
      {
        G[i-offset] = G[i];
        for (int j = 0; j < 3; j++)
        {
          m_vertexMappingBaseToMain[i-offset][j] = m_vertexMappingBaseToMain[i][j];        
        }
        for (int j = 0; j < 4; j++)
        {
          m_vertexToTriagleMappingBaseToMain[i-offset][j] = m_vertexToTriagleMappingBaseToMain[i][j];        
        }
      }
    }
  }

  private void shiftGUp( pt[] G, int startIndex )
  {
    for (int i = startIndex+1; i < m_mesh.nv; i++)
    {
      G[i-1] = G[i];
      for (int j = 0; j < 3; j++)
      {
        m_vertexMappingBaseToMain[i-1][j] = m_vertexMappingBaseToMain[i][j];
      }
      for (int j = 0; j < 4; j++)
      {
        m_vertexToTriagleMappingBaseToMain[i-1][j] = m_vertexToTriagleMappingBaseToMain[i][j];        
      }
    }
  }
  
  private void fixupV( int lowV, int highV )
  {
    Mesh m = m_simplifiedMesh;
    for (int i = 0; i < m.nc; i++)
    {
      if ( m.V[i] == highV )
      {
        m.V[i] = lowV;
      }
      else if ( m.V[i] > highV )
      {
        m.V[i]--;
      }
    }
  }
  
  private void fixupV( int vertexIndex, int lowV, int highV )
  {
    Mesh m = m_simplifiedMesh;
    for (int i = 0; i < m.nc; i++)
    {
      if ( m.V[i] == highV || m.V[i] == lowV )
      {
        m.V[i] = vertexIndex;
      }
      else if ( m.V[i] > lowV && m.V[i] < highV )
      {
        m.V[i]--;
      }
      else if ( m.V[i] > highV )
      {
        m.V[i] -= 2;
      }
    }
  }

  private int cornerShift( int corner, int c1, int c2 )
  {
    if ( corner < c1 && corner < c2 )
      return corner;
    if ( corner > c1 && corner > c2 )
      return corner - 6;
    return corner - 3;
  }
  
  private void fixupO( int c1, int c2 )
  {
    Mesh m = m_simplifiedMesh;
    for (int i = 0; i < m.nc; i++)
    {
      m.O[i] = cornerShift( m.O[i], c1, c2 );
    }
  }
  
  private void removeTriangles( int t1, int t2 )
  {
    Mesh m = m_simplifiedMesh;
    int lower = t1 < t2 ? t1 : t2;
    int higher = t1 > t2 ? t1 : t2; 
    int offsetCorner = 3;
    int offsetTriangle = 1;
    
    for (int i = lower + offsetTriangle; i < m.nt; i++)
    {
      if ( i == higher )
      {
        offsetTriangle = 2;
      }
      else
      {
        m.tm[i-offsetTriangle] = m.tm[i]; 
      }
    }
    
    for (int i = 3*lower + offsetCorner; i < m.nc; i++)
    {
      if ( i == 3*higher || i == 3*higher+1 || i == 3*higher+2 )
      {
        offsetCorner = 6;
      }
      else
      {
        m.V[i-offsetCorner] = m.V[i];
        m.O[i-offsetCorner] = m.O[i];
      }
    }
    m.nc -= 6;
    m.nt -= 2;    
  }
  
  //Collapse to a new vertex. Add this new vertex to lower location of G table and modify O, V and G tables
  private int edgeCollapse( int c1, int c2, pt vertex )
  {
    if ( DEBUG && DEBUG_MODE >= VERBOSE)
    {
      print("Edge collapse " + c1 + "  " + c2 + "\n");
    }
    Mesh m = m_simplifiedMesh;
    int v1 = m.v(m.n(c1));
    int v2 = m.v(m.p(c1));
    int lower = v1 < v2 ? v1 : v2;
    int higher = v1 > v2 ? v1 : v2;
    
    //Populate opposites
    populateOpposites(c1);
    populateOpposites(c2);
    
    //Add vertex, modify G
    m.G[lower] = vertex;
    shiftGUp(m.G, higher);
    m.nv--;
    
    //Remove triangles modify V and O
    int t1 = m.t(c1); int t2 = m.t(c2);
    removeTriangles( t1, t2 );
    fixupV(lower, higher);
    fixupO(3*t1, 3*t2);
    
    return lower;
  }
  
  //Collapse to an already existing vertex
  private int edgeCollapse( int c1, int c2, int vertexIndex )
  {
    Mesh m = m_simplifiedMesh;
    int v1 = m.v(m.n(c1));
    int v2 = m.v(m.p(c1));
    int lower = v1 < v2 ? v1 : v2;
    int higher = v1 > v2 ? v1 : v2;
    int retVal = 0;
    
    //Populate opposites
    populateOpposites(c1);
    populateOpposites(c2);
    
    //Modify G
    if ( lower < vertexIndex )
    {
      m.G[lower] = m.G[vertexIndex];
      lower = vertexIndex < higher ? vertexIndex : higher;
      higher = vertexIndex > higher ? vertexIndex : higher; 
      shifGUp(m.G, lower, higher);
      retVal = lower;
    }
    else
    {
      shifGUp(m.G, lower, higher);
      retVal = vertexIndex;
    }
    m.nv -= 2;
    
    //Remove triangles modify  V and O
    int t1 = m.t(c1); int t2 = m.t(c2);
    removeTriangles( t1, t2 );
    fixupV(retVal, lower, higher);
    fixupO(3*t1, 3*t2);
    
    return retVal;
  }
  
  Mesh simplify()
  {
    copyMainToSimplifiedMesh();
    
    int[] islandTriangleNumbersInMain = new int[m_mesh.nt];
    int numIslandTriangles = 0;
    int numBaseTriangles = 0;
    
    for (int i = 0; i < m_mesh.nt; i++)
    {
      if (m_mesh.tm[i] == ISLAND)
      {
        islandTriangleNumbersInMain[numIslandTriangles++] = i;
      }
      if (m_mesh.tm[i] != ISLAND && m_mesh.tm[i] != CHANNEL)
      {
         m_triangleMappingBaseToMain[numBaseTriangles++] = i;
      }
    }

    numIslandTriangles = 0;
    for (int i = 0; i < m_simplifiedMesh.nt; i++)
    {
      if (m_simplifiedMesh.tm[i] == ISLAND)
      {
        int c = m_simplifiedMesh.c(i);
        int o = m_simplifiedMesh.o(c);
        int l = m_simplifiedMesh.l(c);
        int r = m_simplifiedMesh.r(c);
        
        if (DEBUG && DEBUG_MODE >= VERBOSE)
        {
          print(c + " " + o + " " + l + " " + r + "\n");
        }

        pt newPt = centroid(m_simplifiedMesh, i);
        int commonVertexIndex = edgeCollapse( c, o, newPt );
        l = cornerShift( l, c, o );
        r = cornerShift( r, c, o );
        commonVertexIndex = edgeCollapse( l, r, newPt );

        m_vertexMappingBaseToMain[commonVertexIndex][0] = m_mesh.v(m_mesh.c(islandTriangleNumbersInMain[numIslandTriangles]));
        m_vertexMappingBaseToMain[commonVertexIndex][1] = m_mesh.v(m_mesh.n(m_mesh.c(islandTriangleNumbersInMain[numIslandTriangles])));
        m_vertexMappingBaseToMain[commonVertexIndex][2] = m_mesh.v(m_mesh.p(m_mesh.c(islandTriangleNumbersInMain[numIslandTriangles])));
        
        m_vertexToTriagleMappingBaseToMain[commonVertexIndex][0] = islandTriangleNumbersInMain[numIslandTriangles];
        m_vertexToTriagleMappingBaseToMain[commonVertexIndex][1] = m_mesh.t(m_mesh.s(m_mesh.c(islandTriangleNumbersInMain[numIslandTriangles])));
        m_vertexToTriagleMappingBaseToMain[commonVertexIndex][2] = m_mesh.t(m_mesh.s(m_mesh.n(m_mesh.c(islandTriangleNumbersInMain[numIslandTriangles]))));
        m_vertexToTriagleMappingBaseToMain[commonVertexIndex][3] = m_mesh.t(m_mesh.s(m_mesh.p(m_mesh.c(islandTriangleNumbersInMain[numIslandTriangles]))));
        
        numIslandTriangles++;

        //At most 3 triangles before may be removed due to collapse. Revert i index to the required number for this case
        i -= 4;
        if ( i < -1 )
        {
          i = -1;
        }
      }
    }
    m_succLODMapperManager.getActiveLODMapper().setBaseToRefinedVMap(m_vertexMappingBaseToMain);
    m_succLODMapperManager.getActiveLODMapper().setBaseToRefinedTMap(m_triangleMappingBaseToMain);
    m_succLODMapperManager.getActiveLODMapper().setBaseVToRefinedTMap(m_vertexToTriagleMappingBaseToMain);
    print("Num vertices " + m_simplifiedMesh.nv + " Num triangles " + m_simplifiedMesh.nt + "\n");
    return m_simplifiedMesh;
  }
}
