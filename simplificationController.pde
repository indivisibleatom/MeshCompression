int c_numMeshes = 3;

class SimplificationController
{
 private ViewportManager m_viewportManager;
 private IslandMesh m_islandMesh;
 private Mesh m_baseMesh;
 private SuccLODMapperManager m_lodMapperManager;
 private ArrayList<Mesh> m_displayMeshes;
 int m_minMesh;
 int m_maxMesh;
 
 SimplificationController()
 {
  m_viewportManager = new ViewportManager();
  m_viewportManager.addViewport( new Viewport( 0, 0, width/3, height ) );
  m_viewportManager.addViewport( new Viewport( width/3, 0, width/3, height ) );
  m_viewportManager.addViewport( new Viewport( 2*width/3, 0, width/3, height ) );

  m_displayMeshes = new ArrayList<Mesh>();
  m_islandMesh = new IslandMesh(); 
  m_lodMapperManager = new SuccLODMapperManager();
  m_baseMesh = null;
  m_islandMesh.declareVectors();  
  m_islandMesh.loadMeshVTS("data/horse.vts");
  m_islandMesh.updateON(); // computes O table and normals
  m_islandMesh.resetMarkers(); // resets vertex and tirangle markers
  m_islandMesh.computeBox();
  m_viewportManager.registerMeshToViewport( m_islandMesh, 0 );
  m_displayMeshes.add(m_islandMesh);
  m_minMesh = 0;
  m_maxMesh = 0;
  for(int i=0; i<20; i++) vis[i]=true; // to show all types of triangles
 }
 
 ViewportManager viewportManager()
 {
   return m_viewportManager;
 }
 
 void onKeyPressed()
 {
   /*if (key=='p')  //Create base mesh and register it to other viewport archival
   {
     if (m_baseMesh != null)
     {
       m_viewportManager.unregisterMeshFromViewport( m_baseMesh, 1 );
     }
     m_baseMesh = m_islandMesh.populateBaseG(); 
     m_islandMesh.numberVerticesOfIslandsAndCreateStream();
     m_islandMesh.connectMesh(); 
     m_baseMesh.computeCForV();
     m_baseMesh.computeBox(); 
     m_viewportManager.registerMeshToViewport( m_baseMesh, 1 );
   }*/
   /*if (key=='p')  //Create base mesh and register it to other viewport archival
   {
     if (m_baseMesh != null)
     {
       m_viewportManager.unregisterMeshFromViewport( m_baseMesh, 1 );
     }
     MeshSimplifier simplifier = new MeshSimplifier( m_islandMesh );
     m_baseMesh = simplifier.simplify(); 
     m_baseMesh.computeCForV();
     m_baseMesh.computeBox(); 
     m_viewportManager.registerMeshToViewport( m_baseMesh, 1 );
   }*/
   //Debugging baseVToVMap
   if (keyPressed&&key=='h')
   {
     m_lodMapperManager.getActiveLODMapper().printVertexMapping();
   }
   else if (key=='p')  //Create base mesh and register it to other viewport archival
   {
     MeshSimplifierEdgeCollapse simplifier = new MeshSimplifierEdgeCollapse( m_islandMesh, m_lodMapperManager );
     m_baseMesh = simplifier.simplify(); 
     
     m_baseMesh.computeBox(); 
     onMeshAdded(m_baseMesh);
     
     if ( m_lodMapperManager.fMaxSimplified() )
     {
       m_lodMapperManager.propagateNumberings();
     }

   }
   else if(key=='l') {IslandMesh m = new IslandMesh();
                 m.declareVectors();
                 m.loadMeshOBJ(); // M.loadMesh(); 
                 m.updateON();   m.resetMarkers();
                 m.computeBox();
                 for(int i=0; i<10; i++) vis[i]=true;
                 changeIslandMesh(m);
                }
   else if(key=='*') {
                 IslandMesh m = new IslandMesh(m_baseMesh);
                 m.resetMarkers();
                 m.computeBox();
                 for(int i=0; i<20; i++) vis[i]=true;
                 changeIslandMesh(m);
                 m_baseMesh = null;
                }
   else if(key=='M') {IslandMesh m = new IslandMesh();
                 m.declareVectors();  
                 m.loadMeshVTS(); 
                 m.updateON();   m.resetMarkers();
                 m.computeBox();
                 for(int i=0; i<10; i++) vis[i]=true;
                 changeIslandMesh(m);
                 }
   //Debugging utilities
   else if (key=='`') 
   {
     CuboidConstructor c = new CuboidConstructor(8, 8, 20, 30);
     c.constructMesh();
     changeIslandMesh(c.getMesh());
   }
   else if (key=='i')
   {
     if (m_baseMesh != null)
     {
       m_viewportManager.unregisterMeshFromViewport( m_baseMesh, 1 );
     }
     m_islandMesh.onBeforeAdvanceOnIslandEdge();
     m_baseMesh = m_islandMesh.populateBaseG(); 
     m_islandMesh.numberVerticesOfIslandsAndCreateStream();
     m_baseMesh.Cbox = m_islandMesh.Cbox;
     m_baseMesh.rbox = m_islandMesh.rbox;
     m_viewportManager.registerMeshToViewport( m_baseMesh, 1 ); 
   }
   else if (key=='I') //Connect base mesh step by step
   {
     if (m_baseMesh != null)
     {
       m_islandMesh.connectMeshStepByStep();
     }
   }
   else
   {
      viewportManager().onKeyPressed(); 
   }
 }
 
 private void onMeshAdded( Mesh mesh )
 {
   m_maxMesh++;
   print("Adding mesh" + m_maxMesh + " " + m_minMesh + "\n");
   m_displayMeshes.add(mesh);
   if ( m_maxMesh - m_minMesh > c_numMeshes )
   {
     for (int i = m_minMesh; i < m_maxMesh; i++)
     {
       m_viewportManager.unregisterMeshFromViewport( m_displayMeshes.get(i), i - m_minMesh );
       m_viewportManager.registerMeshToViewport( m_displayMeshes.get(i+1), i - m_minMesh );
     }
     m_minMesh++;
   }
   else
   {
     m_viewportManager.registerMeshToViewport( m_displayMeshes.get(m_maxMesh), m_maxMesh );
   }
 }
 
 private void changeIslandMesh(IslandMesh m)
 {
   print("Changing island mesh");
   m_viewportManager.unregisterMeshFromViewport( m_displayMeshes.get(m_maxMesh), m_maxMesh - m_minMesh );
   m_displayMeshes.set( m_maxMesh, m );
   m_islandMesh = m;
   m_viewportManager.registerMeshToViewport( m_displayMeshes.get(m_maxMesh), m_maxMesh - m_minMesh );
 }
}
