class WorkingMesh extends Mesh
{
  int[] m_LOD = new int[maxnv]; //LOD per vertex
  int[] m_orderV = new int[maxnv]; //The order of the vertex

  int[] m_orderT = new int[maxnt]; //The order of the triangle

  int m_baseTriangles;
  int m_baseVerts;

  PacketFetcher m_packetFetcher;

  WorkingMesh( Mesh m, SuccLODMapperManager lodMapperManager )
  {
    G = m.G;
    V = m.V;
    O = m.O;
    nv = m.nv;
    nt = m.nt;
    nc = m.nc;

    for (int i = 0; i < m.nt; i++)
    {
      m_orderT[i] = i;
    }

    for (int i = 0; i < m.nv; i++)
    {
      m_orderV[i] = i;
      m_LOD[i] = NUMLODS - 1;
    }

    m_baseVerts = nv;
    m_baseTriangles = nt;
    m_userInputHandler = new WorkingMeshUserInputHandler(this);
    m_packetFetcher = new PacketFetcher(lodMapperManager);
  }

  private int findSmallestExpansionCorner( int lod, int corner )
  {
    print("Find smallest expansion corner for corner " + corner + "LOD and LOD swing " + lod + " " + m_LOD[v(n(s(corner)))] + "\n");
    int minTriangle = maxnt;
    int currentCorner = corner;
    int smallestCorner = corner;
    int initCorner = corner;
    do
    {
      int cornerOffset = currentCorner%3;
      int triangle = t(currentCorner);
      int orderT = m_orderT[triangle];
      if (triangle < minTriangle && m_packetFetcher.fetchConnectivity(lod, 3*orderT + cornerOffset) == true)
      {
        minTriangle = triangle;
        smallestCorner = currentCorner;
      }
      currentCorner = s(currentCorner);
      while ( currentCorner != initCorner )
      {
        int vertex1 = v(n(currentCorner));
        int lodCurrent1 = m_LOD[vertex1];
        int vertex2 = v(p(currentCorner));
        int lodCurrent2 = m_LOD[vertex2];
        if ( lod == lodCurrent1 || lod == lodCurrent2 )
        {
          break;
        }
        print("Skipping corner " + currentCorner + "\n");
        currentCorner = s(currentCorner);
      }
    } 
    while (currentCorner != initCorner);
    return smallestCorner;
  }

  private int[] getExpansionCornerNumbers(int lod, int corner)
  {
    print("Get expansion corner numbers for lod " + lod + " " + m_LOD[v(corner)] + "\n");
    int []result = new int[3];
    int numResults = 0;
    int currentCorner = findSmallestExpansionCorner(lod, corner);
    int initCorner = currentCorner;
    do
    {
      int triangle = t(currentCorner);
      int orderT = m_orderT[triangle];

      int cornerOffset = currentCorner%3;

      //TODO msati3: Optimize this query
      boolean expand = m_packetFetcher.fetchConnectivity(lod, 3*orderT + cornerOffset);
      if (expand)
      {
        result[numResults++] = currentCorner;
      }
      currentCorner = s(currentCorner);
      while ( currentCorner != initCorner )
      {
        int vertex1 = v(n(currentCorner));
        int lodCurrent1 = m_LOD[vertex1];
        int vertex2 = v(p(currentCorner));
        int lodCurrent2 = m_LOD[vertex2];
        if ( lod == lodCurrent1 || lod == lodCurrent2 )
        {
          break;
        }
        currentCorner = s(currentCorner);
      }
    } 
    while (currentCorner != initCorner);
    return result;
  }

  void homogenize( int corner )
  {
    int currentCorner = s(corner);
    int lod = m_LOD[v(corner)];
    while (currentCorner != corner)
    {
      int lodCurrent = m_LOD[v(currentCorner)];
      if ( lodCurrent > lod )
      {
        expand(currentCorner);
      }
      currentCorner = s(currentCorner);
    }
  }

  int addVertex(pt p, int lod, int orderV)
  {
    int vertexIndex = addVertex(p);
    m_LOD[vertexIndex] = lod;
    m_orderV[vertexIndex] = orderV;
    return vertexIndex;
  }

  void addTriangle( int v1, int v2, int v3, int orderT, boolean fCallThisClass )
  {
    addTriangle(v1, v2, v3);
    print("Adding triangle with order " + orderT + "\n");
    m_orderT[nt-1] = orderT;
  }

  void printVerticesSelected()
  {
    int vertex = v(cc);
    int orderV = m_orderV[vertex];
    int lod = m_LOD[vertex];
    pt[] result = m_packetFetcher.fetchGeometry(lod, orderV);
    print( "Results " + result[0] + " " + result[1] + " " + result[2] + "\n" );
  }

  void markExpandableVerts()
  {
    for (int i = 0; i < nc; i++)
    {
      vm[i] = 0;
    }
    for (int i = 0; i < nc; i++)
    {
      int vertex = v(i);

      int orderV = m_orderV[vertex];
      int triangle = t(i);
      int cornerOffset = i%3;

      if (m_orderV[vertex] == -1)
      {
        print("Here\n");
      }

      int orderT = m_orderT[triangle];
      int lod = m_LOD[vertex];
      pt[] result = m_packetFetcher.fetchGeometry(lod, orderV);
      if (result[1] != null)
      {
        vm[vertex] = 1;
      }
      else
      {
        vm[vertex] = 0;
      }
      boolean expand = m_packetFetcher.fetchConnectivity(lod, 3*orderT + cornerOffset);
      if (expand)
      {
        int minTriangle = maxnt;
        minTriangle = t(i);
        int currentCorner = s(i);
        boolean smallest = true;
        while (currentCorner != i)
        {
          cornerOffset = currentCorner%3;
          triangle = t(currentCorner);
          orderT = m_orderT[triangle];
          if (triangle < minTriangle && m_packetFetcher.fetchConnectivity(lod, 3*orderT + cornerOffset) == true)
          {
            smallest = false;
          }
          currentCorner = s(currentCorner);
        }
        if ( smallest )
        {
          cm[i] = 1;
        }
        else
        {
          cm[i] = 2;
        }
      }
    }
  }

  int numTimes = 0;

  void expand(int corner)
  {
    numTimes++;
    if ( numTimes > 5 )
      return;
    homogenize(corner);
    print("Homogenized");
    int vertex = v(corner);
    int lod = m_LOD[vertex];
    if (lod >= 0)
    {
      int orderV = m_orderV[vertex];
      pt[] result = m_packetFetcher.fetchGeometry(lod, orderV);
      int[] ct = getExpansionCornerNumbers(lod, corner);
      print("Stiching");
      stitch( result, lod, orderV, ct );
    }
  }

  void stitch( pt[] g, int currentLOD, int currentOrderV, int[] ct )
  {
    int offsetCorner = 3*nt;
    int v1 = addVertex(g[0], currentLOD-1, 3*currentOrderV);
    int v2 = addVertex(g[1], currentLOD-1, 3*currentOrderV+1);
    int v3 = addVertex(g[2], currentLOD-1, 3*currentOrderV+2);

    int offsetTriangles = m_baseTriangles;
    int nuLowerLOD = NUMLODS - currentLOD;
    int verticesAtLOD = m_baseVerts;

    //Rehook the triangles incident on expanded vertices
    int currentCorner = s(ct[0]);
    int vertex = v2;
    do
    {
      V[currentCorner] = vertex;
      if ( currentCorner == ct[1] )
      {
        vertex = v3;
      }
      if ( currentCorner == ct[2] )
      {
        vertex = v1;
      }
      currentCorner = s(currentCorner);
    } 
    while (currentCorner != s (ct[0]));

    for (int i = 0; i < nuLowerLOD; i++)
    {
      if ( i + 1 == nuLowerLOD )
      {
        offsetTriangles += 4 * currentOrderV;
      }
      else
      {
        offsetTriangles += 4 * verticesAtLOD;
      }
      verticesAtLOD *= 3;
    }
    addTriangle( v1, v2, v3, offsetTriangles + 1, true );
    addTriangle( v1, v(p(ct[0])), v2, offsetTriangles + 2, true );
    addTriangle( v2, v(p(ct[1])), v3, offsetTriangles + 3, true );
    addTriangle( v3, v(p(ct[2])), v1, offsetTriangles + 4, true );

    O[p(s(ct[0]))] = offsetCorner + 3; 
    O[p(s(ct[1]))] = offsetCorner + 6;
    O[p(s(ct[2]))] = offsetCorner + 9;
    O[offsetCorner + 3] = p(s(ct[0]));
    O[offsetCorner + 6] = p(s(ct[1]));
    O[offsetCorner + 9] = p(s(ct[2]));

    O[n(ct[0])] = offsetCorner + 5;
    O[n(ct[1])] = offsetCorner + 8;
    O[n(ct[2])] = offsetCorner + 11;
    O[offsetCorner + 5] = n(ct[0]);
    O[offsetCorner + 8] = n(ct[1]);
    O[offsetCorner + 11] = n(ct[2]);

    O[offsetCorner] = offsetCorner+7;
    O[offsetCorner+1] = offsetCorner+10;
    O[offsetCorner+2] = offsetCorner+4;
    O[offsetCorner+7] = offsetCorner;
    O[offsetCorner+10] = offsetCorner+1;
    O[offsetCorner+4] = offsetCorner+2;
    markExpandableVerts();
  }
}

