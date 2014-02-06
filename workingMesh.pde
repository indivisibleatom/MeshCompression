class WorkingMesh extends Mesh
{
  int[] m_LOD = new int[maxnv]; //LOD per vertex
  int[] m_orderV = new int[maxnv]; //The order of the vertex
  
  int[] m_orderT = new int[maxnt]; //The order of the triangle

  int m_baseTriangles;
  int m_baseVerts;
  
  PacketFetcher m_packetFetcher;
  
  WorkingMesh( Mesh m )
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
   }
   
   m_userInputHandler = new WorkingMeshUserInputHandler(this);
  }
  
  void expand(int corner)
  {
    homogenize(corner);
    int vertex = v(corner);
    int lod = m_LOD[vertex];
    int order = m_order[vertex];
    pt[] result = fetchGeometry();
    
    int[] c = fetchExpansionCornerNumbers();
    stitch( 
  }
  
  void stitch( pt[] g, int currentLOD, int currentOrder, int[] ct )
  {
    int offsetCorner = 3*nt;
    int v1 = addVertex(g[0], currentLOD+1, 3*currentOrder);
    int v2 = addVertex(g[1], currentLOD+1, 3*currentOrder+1);
    int v3 = addVertex(g[3], currentLOD+1, 3*currentOrder+2);
    
    int offsetTriangles = m_baseTriangles;
    int nuLowerLOD = MAXLOD - currentLOD;
    int verticesAtLOD = m_baseVertices;
    for (int i = 0; i < nuLowerLOD; i++)
    {
      offsetTriangles += 4 * verticesAtLOD;
      verticesAtLOD *= 3;
    }
    addTriangle( v1, v2, v3, offsetTriangles + 1 );
    addTriangle( v1, v(p(ct[0])), v2, offsetTriangles + 2 );
    addTriangle( v2, v(p(ct[1])), v3, offsetTriangles + 3 );
    addTriangle( v3, v(p(ct[2])), v1, offsetTriangles + 4 );
  
    O[p(s(ct[0]))] = offsetCorner + 3; 
    O[p(s(ct[1]))] = offsetCorner + 6;
    O[p(s(ct[2]))] = offsetCorner + 9;
    O[offsetCorner + 3] = p(s(ct[0]));
    O[offsetCorner + 6] = p(s(ct[1]));
    O[offsetCorner + 9] = p(s(ct[2]));
    
    O[n(ct[0])] = offsetCorner + 5;
    O[n(ct[1])] = offsetCorner + 8;
    O[n(ct[2])] = offsetCorner + 11;
    O[offsetCorner + 5] = n(ct[0));
    O[offsetCorner + 8] = n(ct[1]);
    O[offsetCorner + 11] = n(ct[2]);
    
    O[offset] = offset+7;
    O[offset+1] = offset+10;
    O[offset+2] = offset+4;
    O[offset+7] = offset;
    O[offset+10] = offset+1;
    O[offset+4] = offset+2;
  }
}
