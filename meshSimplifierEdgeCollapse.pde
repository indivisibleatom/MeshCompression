class MeshSimplifierEdgeCollapse
{
  private Mesh m_mesh;
  private Mesh m_simplifiedMesh;
  
  MeshSimplifierEdgeCollapse( Mesh m )
  {
    m_mesh = m;
    m_simplifiedMesh = new Mesh();
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
    for (int i = lower+1; i < G.length; i++)
    {
      if ( i == higher )
      {
        offset = 2;
      }
      else
      {
        G[i-offset] = G[i];
      }
    }
  }

  private void shiftGUp( pt[] G, int startIndex )
  {
    for (int i = startIndex+1; i < G.length; i++)
    {
      G[i-1] = G[i];
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
    //print("Edge collapse " + c1 + "  " + c2 + "\n");
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
  private void edgeCollapse( int c1, int c2, int vertexIndex )
  {
    Mesh m = m_simplifiedMesh;
    int v1 = m.v(m.n(c1));
    int v2 = m.v(m.p(c1));
    int lower = v1 < v2 ? v1 : v2;
    int higher = v1 > v2 ? v1 : v2;
    
    //Populate opposites
    populateOpposites(c1);
    populateOpposites(c2);
    
    //Modify G
    shifGUp(m.G, lower, higher);
    m.nv -= 2;
    
    //Remove triangles modify  V and O
    int t1 = m.t(c1); int t2 = m.t(c2);
    removeTriangles( t1, t2 );
    fixupV(vertexIndex, lower, higher);
    fixupO(3*t1, 3*t2);
  }
  
  Mesh simplify()
  {
    copyMainToSimplifiedMesh();

    for (int i = 0; i < m_simplifiedMesh.nt; i++)
    {
      if (m_simplifiedMesh.tm[i] == ISLAND)
      {
        int c = m_simplifiedMesh.c(i);
        int o = m_simplifiedMesh.o(c);
        int l = m_simplifiedMesh.l(c);
        int r = m_simplifiedMesh.r(c);
        
        if (DEBUG && DEBUG_MODE >= HIGH)
        {
          print("Details " + c + " " + o + " " + l + " " + r + "\n");
        }

        pt newPt = centroid(m_simplifiedMesh, i);
        int commonVertexIndex = edgeCollapse( c, o, newPt );
        l = cornerShift( l, c, o );
        r = cornerShift( r, c, o );
        edgeCollapse( l, r, newPt );

        //At most 3 triangles before may be removed due to collapse. Revert i index to the required number for this case
        i -= 4;
        if ( i < -1 )
          i = -1;
      }
    }
    print("Num vertices " + m_simplifiedMesh.nv + " Num triangles " + m_simplifiedMesh.nt + "\n");
    return m_simplifiedMesh;
  }
}
