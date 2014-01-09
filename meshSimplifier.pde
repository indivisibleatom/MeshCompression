class MeshSimplifier
{
  private IslandMesh m_mesh;
  private Mesh m_createdMesh;
  private ArrayList<VertexInfo> m_vertexInfo;
  private int[] m_oldVertexToNew;
  
  MeshSimplifier( IslandMesh m )
  {
    m_mesh = m;
    m_oldVertexToNew = new int[m_mesh.maxnv];
    m_createdMesh = new Mesh();
    m_vertexInfo = new ArrayList<VertexInfo>();
  }
  
  private pt centroid(Mesh m, int triangleIndex)
  {
    pt pt1 = m.G[m.v(m.c(triangleIndex))];
    pt pt2 = m.G[m.v(m.c(triangleIndex) + 1)];
    pt pt3 = m.G[m.v(m.c(triangleIndex) + 2)];

    return P(pt1, pt2, pt3);
  }
  
  private boolean isIsolatedVertex( int corner )
  {
    int numTimes = 0;
    int currentCorner = corner;
    do
    {
      if (m_mesh.tm[m_mesh.t(currentCorner)] == ISLAND)
      {
        return false;
      }
      currentCorner = m_mesh.s(currentCorner);
      numTimes++;
      if ( numTimes > 10 ) 
      {
        print(corner + "\n"); 
        break;
      }
      
    } while (currentCorner != corner);
    return true;
  }
  
  private void addIslandVertices( int triangle )
  {
    m_createdMesh.addVertex(centroid(m_mesh, triangle));
    int currentCorner = m_mesh.c(triangle);

    m_vertexInfo.add( new VertexInfo(m_mesh.v(currentCorner), m_mesh.v(m_mesh.n(currentCorner)), m_mesh.v(m_mesh.p(currentCorner))) );
    do
    {
      m_oldVertexToNew[m_mesh.v(currentCorner)] = m_createdMesh.nv-1;
      currentCorner = m_mesh.n(currentCorner);
    } while (currentCorner != m_mesh.c(triangle));
  }
  
  private void addIsolatedVertices( int triangle )
  {
    int currentCorner = m_mesh.c(triangle);
    do
    {
      if (isIsolatedVertex(currentCorner) && m_mesh.vm[m_mesh.v(currentCorner)] == 0)
      {
        m_mesh.vm[m_mesh.v(currentCorner)] = 1;
        m_createdMesh.addVertex(m_mesh.G[m_mesh.v(currentCorner)]);
        m_vertexInfo.add( new VertexInfo(m_mesh.v(currentCorner), -1, -1) );
        m_oldVertexToNew[m_mesh.v(currentCorner)] = m_createdMesh.nv-1;
      }
      currentCorner = m_mesh.n(currentCorner);
    } while (currentCorner != m_mesh.c(triangle));
  }
  
  Mesh simplify()
  {     
   print("Entering simplify\n");
   for (int i = 0; i < m_mesh.nt; i++)
   {
     if ( m_mesh.tm[i] == ISLAND )
     {
       addIslandVertices( i );
     }
     else if ( m_mesh.tm[i] == OTHER )
     {
       addIsolatedVertices( i );
     }
   }
   
   for (int i = 0; i < m_mesh.nt; i++)
   {
     if ( m_mesh.tm[i] == OTHER )
     {
       int corner = m_mesh.c(i);
       m_createdMesh.addTriangle(m_oldVertexToNew[m_mesh.v(corner)], m_oldVertexToNew[m_mesh.v(m_mesh.n(corner))], m_oldVertexToNew[m_mesh.v(m_mesh.p(corner))] );
     }
   }
   print("Simplified\n");
   m_createdMesh.computeO();
   return m_createdMesh; 
  }
}

class VertexInfo
{
  private int m_index1; //The index in the higher resolution mesh
  private int m_index2;
  private int m_index3;
  
  VertexInfo(int index1, int index2, int index3)
  {
    m_index1 = index1; 
    m_index2 = index2;
    m_index3 = index3;
  }
}
