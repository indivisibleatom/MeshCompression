class SimplificationController
{
 private ViewportManager m_viewportManager;
 private IslandMesh m_islandMesh;
 private Mesh m_baseMesh;
 
 SimplificationController()
 {
  m_viewportManager = new ViewportManager();
  m_viewportManager.addViewport( new Viewport( 0, 0, width/2, height ) );
  m_viewportManager.addViewport( new Viewport( width/2, 0, width/2, height ) );

  m_islandMesh = new IslandMesh(); 
  m_baseMesh = null;
  m_islandMesh.declareVectors();  
  m_islandMesh.loadMeshVTS("data/horse.vts");
  m_islandMesh.updateON(); // computes O table and normals
  m_islandMesh.resetMarkers(); // resets vertex and tirangle markers
  m_islandMesh.computeBox();
  m_viewportManager.registerMeshToViewport( m_islandMesh, 0 );
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
   if (key=='p')  //Create base mesh and register it to other viewport archival
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
   }
   else if(key=='l') {IslandMesh m = new IslandMesh();
                 m.declareVectors();
                 m.loadMeshOBJ(); // M.loadMesh(); 
                 m.updateON();   m.resetMarkers();
                 m.computeBox();
                 for(int i=0; i<10; i++) vis[i]=true;
                 changeIslandMesh(m);
                }
   else if(key=='*') {IslandMesh m = new IslandMesh(m_baseMesh);
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
 
 private void changeIslandMesh(IslandMesh m)
 {
   m_viewportManager.unregisterMeshFromViewport( m_islandMesh, 0 );
   if ( m_baseMesh != null )
   {
     m_viewportManager.unregisterMeshFromViewport( m_baseMesh, 1 );
   }
   m_islandMesh = m;
   m_viewportManager.registerMeshToViewport( m_islandMesh, 0 );
 }
}
