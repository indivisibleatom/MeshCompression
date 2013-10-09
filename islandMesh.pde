//TYPES OF TRIANGLES
int SPLIT = 1;
int GATE = 2;
int CHANNEL = 3;
int WATER = 8; //Water before forming islands
int ISOLATEDWATER = 4;
int LAGOON = 5;
int JUNCTION = 6;
int CAP = 7;
int ISLAND = 9;

class IslandMesh extends Mesh
{
 boolean m_fDrawIsles = false;
 pt[] baseG = new pt [maxnv];               // to store the locations of the vertices in their contracted form
 int[] island = new int[3*maxnt];
 int[] triangleIsland = new int[maxnt];
 
 pt[] islandBaryCenter = new pt[MAX_ISLANDS];
 float[] islandArea = new float[MAX_ISLANDS];

 //Morphing functionality
 float m_currentT; //Storing the current value of T for morphing
 boolean m_fMorphing; //True if morphing
 boolean m_fCollapsed; //store if this is collapsed state or not

 Map<Integer, Integer> m_vertexForIsland; //A representative vertex of main mesh in a particular island
 Map<Integer, Integer> m_islandForWaterVert; //Mapping of water vertices to island numbers in base mesh

 //TODO msati3: clean this up...where does this go? Do wholistically
 RingExpanderResult m_ringExpanderResult = null;
 BaseMesh baseMesh = null;
 
 //Debugging functionality
 int m_numAdvances = -1; //For advancing on an island border
 int m_currentAdvances = 0;
 int m_selectedIsland = -1;
 
 IslandMesh()
 {
   m_userInputHandler = new IslandMeshUserInputHandler(this);
 }

 void resetMarkers() 
 {
   super.resetMarkers();
   for (int i = 0; i < island.length; i++) island[i] = -1;
 }
 
 void setResult(RingExpanderResult result)
 {
   m_ringExpanderResult = result;
 }
   
 void advanceRingExpanderResult()
 {
   if (m_ringExpanderResult != null)
   {
     m_ringExpanderResult.advanceStep();
   }
 }
   
 void showRingExpanderCorners()
 {
   if (m_ringExpanderResult != null)
   {
     m_ringExpanderResult.colorRingExpander();
   }
 }
   
 void formIslands(int initCorner)
 {
   m_fDrawIsles = true;
   if (m_ringExpanderResult != null)
   {
     showRingExpanderCorners();
     m_ringExpanderResult.formIslands(initCorner);
   }
 }
 
 //Adds morphing to base mesh, aside from normal functionality of a mesh
 void draw()
 {
   if (m_fMorphing)
   {
     if (!m_fCollapsed)
     {
        morphToBaseMesh();
     }
     else
     {
        morphFromBaseMesh();
     }
   }
   super.draw();
   drawIsland();

 }
 
 private void drawIsland()
 {
   for (int i = 0; i < nt; i++)
   {
     if (m_selectedIsland != -1 && island[3*i] == m_selectedIsland)
     {
       vm[m_vertexForIsland.get(m_selectedIsland)] = 5;
       fill(red);
       shade(i);
     }
   }
 }
 
 void selectIsland(int islandNum)
 {
   m_selectedIsland = islandNum;
 }
  
 void toggleMorphingState()
 {
   m_fMorphing = true;
 }
 
 //Queryable state functions
 int getNumIslands()
 {
   return numIslands;
 }
 
 public int getIslandForVertex(int vertex)
 {
   int initCorner = cForV(vertex);
   int curCorner = initCorner;
   do
   {
     if (island[curCorner] != -1)
     {
       return island[curCorner];
     }
     curCorner = s(curCorner);
   }while (curCorner != initCorner);
   return -1;
 }


 private void morphFromBaseMesh()
 {    
   pt[] temp = baseG;
   baseG = G;
   G = temp;
   if (m_currentT > 0)
   {
     m_currentT -= 0.01;
   }
   else
   {
     m_fMorphing = false;
     m_fCollapsed = false;
     m_currentT = 0;
   }

   for (int i = 0; i < nv; i++)
   {
     int vertexType = getVertexType(i);
     switch (vertexType)
     {
       case 0: int island = getIslandForVertex(i);
               if (island == -1)
               {
                 if ( DEBUG && DEBUG_MODE >= LOW )
                 {
                   print("Fatal error!! Get island == -1 for vertex of type IslandVertex");
                 }
               }
               if (islandBaryCenter[island] == null)
               {
                 if ( DEBUG && DEBUG_MODE >= LOW )
                 {
                   print("Barycenter null for " + island + " " + numIslands);
                 }
               }
               baseG[i] = morph(G[i], islandBaryCenter[island], m_currentT);
               break;
       case 1: baseG[i] = new pt();
               baseG[i].set(G[i]);
               break;
       default: if ( DEBUG && DEBUG_MODE >= LOW ) { print("Fatal error!! Vertex not classified as water or island vertex"); }
               break;
     }
   }
   temp = G;
   G = baseG;
   baseG = temp;
   updateON();
 }

 private void morphToBaseMesh()
 {
   if (m_currentT != 0)
   {
     pt[] temp = baseG;
     baseG = G;
     G = temp;
   }
   if (m_currentT < 1)
   {
     m_currentT += 0.01;
   }
   else
   {
     m_fMorphing = false;
     m_fCollapsed = true;
     m_currentT = 1;
   }
   for (int i = 0; i < nv; i++)
   {
     int vertexType = getVertexType(i);
     switch (vertexType)
     {
       case 0: int island = getIslandForVertex(i);
               if (island == -1)
               {
                 if ( DEBUG && DEBUG_MODE >= LOW )
                 {
                   print("IslandMesh::MorphtoBaseMesh - Fatal error!! Get island == -1 for vertex of type IslandVertex");
                 }
               }
               if (islandBaryCenter[island] == null)
               {
                 if ( DEBUG && DEBUG_MODE >= LOW )
                 {
                   print("IslandMesh::MorphtoBaseMesh - Barycenter null for " + island + " " + numIslands);
                 }
               }
               baseG[i] = morph(G[i], islandBaryCenter[island], m_currentT);
               break;
       case 1: baseG[i] = new pt();
               baseG[i].set(G[i]);
               break;
       default: if ( DEBUG && DEBUG_MODE >= LOW )
               { 
                 print("Fatal error!! Vertex not classified as water or island vertex");
               }
               break;
     }
   }
   pt[] temp = G;
   G = baseG;
   baseG = temp;
 }
   
   
 //************************PRIVATE helpers***********************
 //State checking functions
 private boolean isVertexForCornerWaterVertex(int corner)
 {
   int initCorner = corner;
   int curCorner = initCorner;
   do
   {
     if (island[curCorner] != -1)
     {
       return false;
     }
     curCorner = s(curCorner);
   }while (curCorner != initCorner);
   return true;
 }

 private boolean waterIncident(int triangle)
 {
   int corner = c(triangle);
   return (isVertexForCornerWaterVertex(corner) || isVertexForCornerWaterVertex(n(corner)) || isVertexForCornerWaterVertex(p(corner)));
 }
   
 private boolean isWaterVertex(int vertex)
 {
   int cornerForVertex = cForV(vertex);
   return isVertexForCornerWaterVertex(cornerForVertex);
 }

 //Gives a vertex, returns any one corner incident on the vertex and incident on an island
 //TODO msati3: There can be multiple such corners. Which one to return?
 private int getIslandCornerForVertex(int vertex)
 {
   int initCorner = cForV(vertex);
   int curCorner = initCorner;
   do
   {
     if (island[curCorner] != -1)
     {
       return curCorner;
     }
     curCorner = s(curCorner);
   }while (curCorner != initCorner);
   return -1;
 }

 //Returns island number ( = vertex id in base mesh ). Also assigns numbers to water vertices
 private int getIslandForVertexExtended(int vertex)
 {
   int island = getIslandForVertex(vertex);
   if ( island == -1 )
   {
     return m_islandForWaterVert.get( vertex );
   }
   return island;
 }
     
 private int getIslandByUnswing(int corner)
 {
   int initCorner = corner;
   int curCorner = initCorner;
   do
   {
     if (island[curCorner] != -1)
     {
       return island[curCorner];
     }
     int swing = u(curCorner);
     if (swing == n(curCorner))
     {
       break;
     }
     curCorner = swing;
   }while (curCorner != initCorner);
   return -1;
 }
  
 private int getIslandAtCorner(int corner)
 {
   return island[corner];
 }

 //Given a corner, swing around to find an island
 private int getIsland(int corner)
 {
   int initCorner = corner;
   int curCorner = initCorner;
   do
   {
     if (island[curCorner] != -1)
     {
       return island[curCorner];
     }
     int swing = s(curCorner);
     if (swing == p(curCorner))
     {
       return getIslandByUnswing(initCorner);
     }
     curCorner = swing;
   }while (curCorner != initCorner);
   return -1;
 }
   
 //Given two corners, returns is this triangle lies on a beach edge
 private boolean hasBeachEdgeAroundCorners(int c1, int c2)
 {
   int island1 = getIsland(c1);
   int island2 = getIsland(c2);
     
   if ((island1 != -1 && island2 != -1) && ((island[s(c1)] == -1 && island[u(c2)] == -1)||(island[u(c1)] == -1 && island[s(c2)] == -1)))
   {
     if (island1 == island2)
     {
       return true;
     }
   }
   return false;
 }
   
 //Given two corners, returns if the edge bounding them in the triangle containing them is a beach eadge. Returns false if they don't lie on the same triangle
 private boolean hasBeachEdgeForCorners(int c1, int c2)
 {
   if (!((n(c1) == c2 || p(c1) == c2)))
   {
     return false;
   }

   int island1 = getIslandAtCorner(c1);
   int island2 = getIslandAtCorner(c2);
   int otherCorner = n(c1) == c2 ? p(c1) : n(c1);
   int opposite = o(otherCorner);
   int island3 = getIslandAtCorner(n(opposite));
   int island4 = getIslandAtCorner(p(opposite));

   if ((island1 != -1 && island2 != -1) && (island3 == -1 && island4 == -1))
   {
     if (island1 == island2)
     {
       return true;
     }
     else
     {
       //print("Islands on the beach edge are not the same. Failure!!" + island1 + " " + island2);
     }
   }
   return false;
 }
   
 private boolean hasBeachEdge(int triangle)
 {
   int corner = c(triangle);
   int count = 0;
   while(count < 3)
   {
     if ( hasBeachEdgeAroundCorners( corner, n(corner) ) )
     {
       return true;
     }
     corner = n(corner);
     count++;
   }
   return false;
 }
   
 ColorResult colorTriangles()
 {
   int countLand = 0, countGood = 0, countSeparator = 0, countLagoons = 0, countBad = 0;
   int numVerts = 0, numWaterVerts = 0, numNormalVerts = 0;
   for (int i = 0; i < nt; i++)
   {
     int corner = c(i);
     int island1 = getIsland(corner);
     int island2 = getIsland(n(corner));
     int island3 = getIsland(p(corner));
     tm[i] = 0;
     if (island[corner] != -1 && island[n(corner)] != -1 && island[p(corner)] != -1 && island1 == island2 && island1 == island3)
     {
       countLand++;
       tm[i] = ISLAND;
     }
     else if (hasBeachEdge(i)) //shallow
     {
       if (island1 != -1 && island2 != -1 && island3 != -1 && (island1 == island2 || island1 == island3 || island2 == island3))
       {
         if (island1 == island2 && island1 == island3)
         {
           countLagoons++;
           tm[i] = LAGOON; //Lagoon
         }
         else
         {
           if (island1 != -1 && island2 != -1 && island3 != -1 && (island1 != island2 || island1 != island3))
           {
             countGood++;
             tm[i] = CHANNEL;
           }
           else
           {
             if (DEBUG && DEBUG_MODE >= LOW)
             {
               print ("This case unhandled!");
             }
           }
         }
       }
       else
       {
         tm[i] = CAP; //Cap triangle
       }
     }
    else //deep
     {
         if (island1 != -1 && island2 != -1 && island3 != -1 && island1 == island2 && island1 == island3)
         {
           tm[i] = SPLIT;
         }
         else if (island1 != -1 && island2 != -1 && island3 != -1 && (island1 == island2 || island1 == island3 || island2 == island3))
         {
           tm[i] = GATE;
         }
         else if (island1 != -1 && island2 != -1 && island3 != -1)
         {
           countSeparator++;
           tm[i] = JUNCTION;
         }
         else
         {
           countBad++;
           tm[i] = ISOLATEDWATER;
         }
     }
   }
     
   for (int i = 0; i < nv; i++)
   {
     numVerts++;
     if (isWaterVertex(i))
     {
       numWaterVerts++;
     }
     else
     {
       numNormalVerts++;
     }
   }
   if ( DEBUG && DEBUG_MODE >= VERBOSE )
   {
     print("\nStats : Total " + nt + " Land " + countLand + " Good water " + countGood + " Island separators " + countSeparator + " Lagoons " + countLagoons + " Bad water " + countBad + "Num Water Verts " + numWaterVerts);
   }
     
   //TODO msati3: This is a hack. Should be made a separate function
   computeBaryCenterForIslands();
   calculateFinalLocationsForVertices();
   return new ColorResult(nt, countLand, countGood, countSeparator, countLagoons, countBad, numVerts, numWaterVerts, numNormalVerts);
 }
   
 private int getVertexType(int vertex)
 {
   int cornerForVertex = cForV(vertex);
   if (!isVertexForCornerWaterVertex(cornerForVertex))
   {
     return 0;
   }
   return 1;
 }
   
 private boolean isIslandVertex(int vertex)
 {
   return getVertexType(vertex) == 0;
 }
      
 private void computeBaryCenterForIslands()
 {
   for (int i = 0; i < numIslands; i++)
   {
     islandArea[i] = 0;
     islandBaryCenter[i] = new pt(0,0,0);
     for (int j = 0; j < nt; j++)
     {
       if (triangleIsland[j] == i)
       {
         float area = m_utils.computeArea(j);
         islandArea[i] += area;
         islandBaryCenter[i].add(m_utils.baryCenter(j).mul(area));
       }
     }
     islandBaryCenter[i].div(islandArea[i]);
   }
 }
   
 private void calculateFinalLocationsForVertices()
 {
   for (int i = 0; i < nv; i++)
   {
     int vertexType = getVertexType(i);
     switch (vertexType)
     {
       case 0: int island = getIslandForVertex(i);
               if (island == -1)
               {
                 if ( DEBUG && DEBUG_MODE >= LOW )
                 {
                   print("Fatal error!! Get island == -1 for vertex of type IslandVertex");
                 }
               }
               baseG[i] = islandBaryCenter[island];
               break;
       case 1: baseG[i] = G[i];
               break;
       default: if ( DEBUG && DEBUG_MODE >= LOW )
               {
                 print("Fatal error!! Vertex not classified as water or island vertex");
               }
               break;
     }
   }
 }   
   
   private int getNumWaterVerts()
   {
     int numWaterVerts = 0;
     for (int i = 0; i < nv; i++ )
     {
       if ( !isIslandVertex(i) )
       {
         numWaterVerts++;
       }
     }
     return numWaterVerts;
   }
   
   BaseMesh populateBaseG()
   {
     print("Creating new base mesh");
     baseMesh = new BaseMesh();
     baseMesh.setExpansionManager( m_ringExpanderResult.getIslandExpansionManager() );
     baseMesh.declareVectors();

     m_vertexForIsland = new HashMap< Integer, Integer >();
     m_islandForWaterVert = new HashMap< Integer, Integer >();
     int numWaterVerts = getNumWaterVerts();
     int countWater = 0;
     pt[] baseMeshG = new pt[numIslands + numWaterVerts];
     for (int i = 0; i < baseMeshG.length; i++)
     {
       baseMeshG[i] = null;
     }
     baseMesh.G = baseMeshG;
     for (int i = 0; i < nv; i++ )
     {
       if ( isIslandVertex(i) )
       {
         int island = getIslandForVertex( i );
         if ( m_vertexForIsland.get( island ) == null )
         {
           m_vertexForIsland.put( island, i );
           baseMeshG[ island ] = P(islandBaryCenter[island]); 
         }
       }
       else
       {
         m_vertexForIsland.put( numIslands + countWater, i );
         m_islandForWaterVert.put( i, numIslands + countWater );
         baseMeshG[ numIslands + countWater ] = G[i]; 
         countWater++;
       }
     }
     baseMesh.nv = baseMesh.G.length;
     if ( DEBUG && DEBUG_MODE >= VERBOSE )
     {
       print ("Base mesh created with number of vertices " + (numIslands + numWaterVerts));
     }
     return baseMesh;
   }
   
   void onBeforeAdvanceOnIslandEdge()
   {
     for (int i = 0; i < 3*nt; i++)
     {
       cm[i] = 0;
     }
     m_numAdvances = 1;
     m_currentAdvances = 0;
   }
   
   void connectMeshStepByStep()
   {
     m_currentAdvances = 0;
     for (int i = 0; i < baseMesh.G.length; i++)
     {
       int v = m_vertexForIsland.get(i);
       if ( isIslandVertex( v ) && connectInBaseMesh(v) )
       {
         int currentVOnIsland = v;
         int prevVOnIsland = v;
         int prevPrevVOnIsland = v;
         int returnedVertex = -1;
         int bTrackedC2 = -1, bTrackedC3 = -1; //Track the last added triangle corners in the base mesh for this island.
         int nextUsedIsland = -1; //Track the next used island post a junction / water triangle.
         int bFirstC2 = -1, bFirstC3 = -1; //Trac the initial triangle, so that the last can be combined post encircling the edges of the island

         ArrayList<Integer> cornerList = new ArrayList<Integer>(); //Return the cornerList og JUNCTION and ISOLATEDWATER triangles obtained by swinging around
         do
         {
           int incidentCorner = incidentTriangleType( currentVOnIsland, prevVOnIsland, JUNCTION, ISOLATEDWATER, cornerList );

           if ( incidentCorner != -1 )
           {
             for (int j = 0; j < cornerList.size(); j++)
             {
               incidentCorner = cornerList.get(j);
               int vertex2 = v( n( incidentCorner ) );
               int vertex3 = v( p( incidentCorner ) );
               int bv1 = i;
               int island2 = getIslandForVertexExtended( vertex2 );
               int island3 = getIslandForVertexExtended( vertex3 );

               int bv2 = island2;
               int bv3 = island3;

               if ( bv2 != -1 && bv3 != -1 )
               {
                 baseMesh.addTriangle(bv1, bv2, bv3);
                 if ( bTrackedC2 != -1 )
                 {
                   addOppositeForUnusedIsland( baseMesh.nc-1, baseMesh.nc-2, bTrackedC2, bTrackedC3, nextUsedIsland );                                      
                 }
                 else
                 {
                   bFirstC2 = baseMesh.nc-2;
                   bFirstC3 = baseMesh.nc-1;
                 }

                 nextUsedIsland = getNextUsedIslandFromCorner( incidentCorner );

                 bTrackedC2 = baseMesh.nc-2;
                 bTrackedC3 = baseMesh.nc-1;
                 
                 if (nextUsedIsland != -1)
                 {
                   vm[m_vertexForIsland.get(nextUsedIsland)] = 5;
                 }
                 cm[incidentCorner] = 2;
                 cm[n(incidentCorner)] = 2;
                 cm[p(incidentCorner)] = 2;
               }
               else
               {
                 if ( DEBUG && DEBUG_MODE >= VERBOSE )
                 {
                   print ("Get a -1 as one of the base vertices incident on a Junction / Water triangle. Error!");
                 }
               }
             }
           }
           vm[v] = 1;
           m_currentAdvances++;
           if ( m_currentAdvances >= m_numAdvances )
           {
             if ( DEBUG && DEBUG_MODE >= VERBOSE )
             {
               print ("NumAdvances " + m_numAdvances);
             }
             m_numAdvances++;
             return;
           }
           returnedVertex = getNextVertexOnIsland( v, currentVOnIsland, prevVOnIsland, prevPrevVOnIsland );
           if ( DEBUG && DEBUG_MODE >= VERBOSE )
           {
             print("Next vertex " + returnedVertex );
           }
           prevPrevVOnIsland = prevVOnIsland;
           prevVOnIsland = currentVOnIsland;
           currentVOnIsland = returnedVertex;
           if (returnedVertex != -1)
           {
             vm[currentVOnIsland] = 2;
           }
           vm[prevVOnIsland] = 3;
           vm[prevPrevVOnIsland] = 1;
         } while ( returnedVertex != -1 );
         if ( bTrackedC2 != -1 )
         {
           if ( m_numAdvances != -1 && m_currentAdvances == m_numAdvances-1 )
           {
             if ( DEBUG && DEBUG_MODE >= LOW )
             {
               print("Closing");
             }
           }
           addOppositeForUnusedIsland( bFirstC2, bFirstC3, bTrackedC2, bTrackedC3, nextUsedIsland );
         }
       }
       else if ( !isIslandVertex(v) ) //Is a water vertex
       {
         int initCorner = incidentTriangleType( v, ISOLATEDWATER );
         int currentCorner = initCorner;
         if ( DEBUG && DEBUG_MODE >= VERBOSE )
         {
           print("Found corner " + currentCorner);
         }
         do
         {
           int island2 = getIslandForVertexExtended( v(n(currentCorner)) );
           int island3 = getIslandForVertexExtended( v(p(currentCorner)) );
           baseMesh.addTriangle(i, island2, island3);
           currentCorner = s(currentCorner);
         } while (currentCorner != initCorner);
       }
     } //end for loop over base mesh vertices
   }

   void connectMesh()
   {
     m_numAdvances = -1;
     for (int i = 0; i < baseMesh.G.length; i++)
     {
       int v = m_vertexForIsland.get(i);
       if ( isIslandVertex( v ) && connectInBaseMesh(v) )
       {
         int currentVOnIsland = v;
         int prevVOnIsland = v;
         int prevPrevVOnIsland = v;
         int returnedVertex = -1;
         int bTrackedC2 = -1, bTrackedC3 = -1; //Track the last added triangle corners in the base mesh for this island.
         int nextUsedIsland = -1; //Track the next used island post a junction / water triangle.
         int bFirstC2 = -1, bFirstC3 = -1; //Track the initial triangle, so that the last can be combined post encircling the edges of the island

         ArrayList<Integer> cornerList = new ArrayList<Integer>(); //Return the cornerList og JUNCTION and ISOLATEDWATER triangles obtained by swinging around
         do
         {
           int incidentCorner = incidentTriangleType( currentVOnIsland, prevVOnIsland, JUNCTION, ISOLATEDWATER, cornerList );

           if ( incidentCorner != -1 )
           {
             for (int j = 0; j < cornerList.size(); j++)
             {
               incidentCorner = cornerList.get(j);
               int vertex2 = v( n( incidentCorner ) );
               int vertex3 = v( p( incidentCorner ) );
               int bv1 = i;
               int island2 = getIslandForVertexExtended( vertex2 );
               int island3 = getIslandForVertexExtended( vertex3 );

               int bv2 = island2;
               int bv3 = island3;

               if ( bv2 != -1 && bv3 != -1 )
               {
                 baseMesh.addTriangle(bv1, bv2, bv3);
                 if ( bTrackedC2 != -1 )
                 {
                   addOppositeForUnusedIsland( baseMesh.nc-1, baseMesh.nc-2, bTrackedC2, bTrackedC3, nextUsedIsland );                                      
                 }
                 else
                 {
                   bFirstC2 = baseMesh.nc-2;
                   bFirstC3 = baseMesh.nc-1;
                 }

                 nextUsedIsland = getNextUsedIslandFromCorner( incidentCorner );

                 bTrackedC2 = baseMesh.nc-2;
                 bTrackedC3 = baseMesh.nc-1;                 
               }
               else
               {
                 if ( DEBUG && DEBUG_MODE >= VERBOSE )
                 {
                   print ("Get a -1 as one of the base vertices incident on a Junction / Water triangle. Error!");
                 }
               }
             }
           }
           returnedVertex = getNextVertexOnIsland( v, currentVOnIsland, prevVOnIsland, prevPrevVOnIsland );
           prevPrevVOnIsland = prevVOnIsland;
           prevVOnIsland = currentVOnIsland;
           currentVOnIsland = returnedVertex;
         } while ( returnedVertex != -1 );
         if ( bTrackedC2 != -1 )
         {
           if ( m_numAdvances != -1 && m_currentAdvances == m_numAdvances-1 )
           {
             if ( DEBUG && DEBUG_MODE >= LOW )
             {
               print("Closing");
             }
           }
           addOppositeForUnusedIsland( bFirstC2, bFirstC3, bTrackedC2, bTrackedC3, nextUsedIsland );
         }
       }
       else if ( !isIslandVertex(v) ) //Is a water vertex
       {
         int initCorner = incidentTriangleType( v, ISOLATEDWATER );
         int currentCorner = initCorner;
         if ( DEBUG && DEBUG_MODE >= VERBOSE )
         {
           print("Found corner " + currentCorner);
         }
         do
         {
           int island2 = getIslandForVertexExtended( v(n(currentCorner)) );
           int island3 = getIslandForVertexExtended( v(p(currentCorner)) );
           baseMesh.addTriangle(i, island2, island3);
           currentCorner = s(currentCorner);
         } while (currentCorner != initCorner);
       }
     } //end for loop over base mesh vertices
   }
   
   /*void connectMesh()
   {
     m_numAdvances = -1;
     for (int i = 0; i < baseMesh.G.length; i++)
     {
       int v = m_vertexForIsland.get(i);
       if ( isIslandVertex( v ) && connectInBaseMesh(v) )
       {      
         int currentVOnIsland = v;
         int prevVOnIsland = v;
         int prevPrevVOnIsland = v;
         int returnedVertex = -1;
         int bTrackedC2 = -1, bTrackedC3 = -1; //Track the last added triangle corners in the base mesh for this island.
         int nextUsedIsland = -1; //Track the next used island post a junction / water triangle.
         int bFirstC2 = -1, bFirstC3 = -1; //Trac the initial triangle, so that the last can be combined post encircling the edges of the island

         ArrayList<Integer> cornerList = new ArrayList<Integer>(); //Return the cornerList og JUNCTION and ISOLATEDWATER triangles obtained by swinging around
         do
         {
           int incidentCorner = incidentTriangleType( currentVOnIsland, prevVOnIsland, JUNCTION, ISOLATEDWATER, cornerList );

           if ( incidentCorner != -1 )
           {
             for (int j = 0; j < cornerList.size(); j++)
             {
               incidentCorner = cornerList.get(j);

               int vertex2 = v( n( incidentCorner ) );
               int vertex3 = v( p( incidentCorner ) );
               int bv1 = i;
               int island2 = getIslandForVertexExtended( vertex2 );
               int island3 = getIslandForVertexExtended( vertex3 );
  
               int bv2 = island2;
               int bv3 = island3;
  
               if ( bv2 != -1 && bv3 != -1 )
               {
                 baseMesh.addTriangle(bv1, bv2, bv3);
                 if ( bTrackedC2 != -1 )
                 {
                   addOppositeForUnusedIsland( baseMesh.nc-1, baseMesh.nc-2, bTrackedC2, bTrackedC3, nextUsedIsland );
                 }
                 else
                 {
                   bFirstC2 = baseMesh.nc-2;
                   bFirstC3 = baseMesh.nc-1;
                 }

                 nextUsedIsland = getNextUsedIslandFromCorner( incidentCorner );
                 bTrackedC2 = baseMesh.nc-2;
                 bTrackedC3 = baseMesh.nc-1;
               }
               else
               {
                 if ( DEBUG && DEBUG_MODE >= LOW )
                 {
                   print ("Get a -1 as one of the base vertices incident on a Junction / Water triangle. Error!");
                 }
               }
             }
           }
           returnedVertex = getNextVertexOnIsland( v, currentVOnIsland, prevVOnIsland, prevPrevVOnIsland );
           prevPrevVOnIsland = prevVOnIsland;
           prevVOnIsland = currentVOnIsland;
           currentVOnIsland = returnedVertex;
         } while ( returnedVertex != -1 );
         if ( bTrackedC2 != -1 )
         {
           addOppositeForUnusedIsland( bFirstC2, bFirstC3, bTrackedC2, bTrackedC3, nextUsedIsland );
         }
       }
       else if ( !isIslandVertex(v) ) //Is a water vertex
       {
         int initCorner = incidentTriangleType( v, ISOLATEDWATER );
         int currentCorner = initCorner;
         if ( DEBUG && DEBUG_MODE >= VERBOSE )
         {
           print("Found corner " + currentCorner);
         }
         do
         {
           int island2 = getIslandForVertexExtended( v(n(currentCorner)) );
           int island3 = getIslandForVertexExtended( v(p(currentCorner)) );
           baseMesh.addTriangle(i, island2, island3);
           currentCorner = s(currentCorner);
         } while (currentCorner != initCorner);
       }
     } //end for loop over base mesh vertices
   }*/
   
   private int getNextUsedIslandFromCorner( int iCorner )
   {
     int swingCorner = s( iCorner );
     return getIslandForVertexExtended(v(n(swingCorner)));
   }
   
   private void addOppositeForUnusedIsland( int bc2, int bc3, int btrackedc2, int btrackedc3, int nextUsedIsland )
   {
     if ( m_numAdvances != -1 && m_currentAdvances == m_numAdvances-1 )
     {
       if ( DEBUG && DEBUG_MODE >= LOW )
       {
         print("AddOppositeForUnused " + baseMesh.v(bc2) + " " + baseMesh.v(bc3) + " " + baseMesh.v(btrackedc2) + " " + baseMesh.v(btrackedc3) + " " + nextUsedIsland);
       }
     }

     int corner1 = -1, corner2 = -1;

     if ( baseMesh.v( bc2 ) == nextUsedIsland )
     {
       corner1 = bc3;
     }
     else if ( baseMesh.v( bc3 ) == nextUsedIsland )
     {
       corner1 = bc2;
     }
     else
     {
       if ( DEBUG && DEBUG_MODE >= LOW )
       {
         print("IslandMesh::addOppositeForUnusedIsland - no same island found\n");
       }
     }
     
     if ( baseMesh.v( btrackedc2 ) == nextUsedIsland )
     {
       corner2 = btrackedc3;
     }
     else if ( baseMesh.v( btrackedc3 ) == nextUsedIsland )
     {
       corner2 = btrackedc2;
     }
     else
     {
       if ( DEBUG && DEBUG_MODE >= LOW )
       {
         print("IslandMesh::addOppositeForUnusedIsland - no same island found\n");
       }
     }

     baseMesh.O[ corner1 ] = corner2;
     baseMesh.O[ corner2 ] = corner1;
     
     baseMesh.cm[ corner1 ] = 2;
     baseMesh.cm[ corner2 ] = 2;
   }
   
   private int getNonIslandTriangleForEdge( int v1, int v2 )
   {
     int corner = cForV( v1 );
     int currentCorner = corner;
     int cornerNonEdge = -1;
     do
     {
       if ( v( n( currentCorner ) ) == v2 )
       {
         cornerNonEdge = p( currentCorner );
         break;
       }
       if ( v( p( currentCorner ) ) == v2 )
       {
         cornerNonEdge = n( currentCorner );
         break;
       }
       currentCorner = s( currentCorner );
     } while ( currentCorner != corner );
     if ( cornerNonEdge == -1 )
     {
       if (DEBUG && DEBUG_MODE >= LOW)
       {
         print ("Could not find a corner for a triangle having the given edge. Error! ");
       }
       return -1;
     }
     if ( getIslandForVertex( v( cornerNonEdge ) ) == getIslandForVertex( v1 ) )
     {
       return t( o( cornerNonEdge ) );
     }
     else
     {
       return t( cornerNonEdge );
     }
   }
   
   private int getNonIslandVertex( int nonIslandTriangle, int currentVOnIsland, int returnedV )
   {
     int initCorner = c( nonIslandTriangle );
     int currentCorner = initCorner;
     do
     {
       if ( v( currentCorner ) != currentVOnIsland && v( currentCorner ) != returnedV )
       {
         return v( currentCorner );
       }
       currentCorner = n( currentCorner );
     } while ( currentCorner != initCorner );
     return -1;
   }
   
   int triangleType( int triangle )
   {
     return tm[triangle];
   }
   
   int incidentTriangleType( int vertex, int prevVertex, int type1, int type2, ArrayList<Integer> cornerList )
   {
     cornerList.clear();
     int startCorner = findBeachEdgeCornerForVertex( vertex, prevVertex );
     
     if (startCorner == -1)
     {
       if ( DEBUG && DEBUG_MODE >= LOW )
       {
         print("IslandMesh: IncidentTriangleType got -1 as BeachEdgeCornerForVertex");
       }
     }
     int currentCorner = startCorner;
     int retVal = -1;
     do
     {
       if (( triangleType (t(currentCorner)) == type1 ) || ( triangleType (t(currentCorner)) == type2  ))
       {
         if ( retVal == -1 )
         {
           retVal = currentCorner;
         }
         cornerList.add( currentCorner );
       }
       currentCorner = s(currentCorner);
     } while ( currentCorner != startCorner );
     return retVal;
   }
   
   int incidentTriangleType( int vertex, int type )
   {
     int c = cForV( vertex );
     int currentCorner = c;
     do
     {
       currentCorner = s(currentCorner);
       if ( triangleType (t(currentCorner)) == type )
       {
         return currentCorner;
       }
     } while ( currentCorner != c );
     return -1;
   }
   
   boolean connectInBaseMesh( int vertex )
   {
     if (isIslandVertex( vertex ) )
     {
       int island = getIslandForVertex( vertex );
       int currentVertex = vertex;
       int prevVertex = vertex;
       int prevPrevVertex = vertex;
       int vertexNew = currentVertex;
       do
       {
         if ( incidentTriangleType( vertexNew, JUNCTION ) != -1 || incidentTriangleType( vertexNew, ISOLATEDWATER ) != -1 )
         {
           return true;
         }
         prevPrevVertex = prevVertex;
         prevVertex = currentVertex;
         currentVertex = vertexNew;
       } while ( (vertexNew = getNextVertexOnIsland( vertex, currentVertex, prevVertex, prevPrevVertex) ) != -1 );
     }
     else
     {
       if ( incidentTriangleType( vertex, ISOLATEDWATER ) != -1 )
       {
         return true;
       }
     }
     if ( DEBUG && DEBUG_MODE >= LOW )
     {
       print ("IslandMesh::connectInBaseMesh - the island " + getIslandForVertex( vertex ) + " is not connected in base mesh\n");
     }
     return false;
   }
   
   int getNextVertexOnIsland( int finalV, int currentV, int prevV, int prevPrevV )
   {
     int v = findOtherBeachEdgeVertexForVertex( currentV, prevV, prevPrevV );
     if ( DEBUG && DEBUG_MODE >= VERBOSE )
     {
       print ("The value of v is " + v );
     }
     if ( v == finalV && currentV != finalV ) 
     {
       if ( DEBUG && DEBUG_MODE >= VERBOSE )
       {
         print( "Completing island" + v + " " + finalV);
       }
     }
     return ( (v == finalV && currentV != finalV) ? -1 : v );
   }
   
   int findOtherBeachEdgeVertexForTriangleCorners( int c1, int c2 )
   {
     if ( hasBeachEdgeForCorners( c1, c2 ) )
     {
        return v(c2);
     }
     return -1;
   }
   
   int findBeachEdgeCornerForVertex( int currentV, int otherV )
   {
     int c = getIslandCornerForVertex( currentV );
     int currentCorner = c;
     do
     {
       int otherBeachEdgeVertex1 = findOtherBeachEdgeVertexForTriangleCorners( currentCorner, n(currentCorner) );
       int otherBeachEdgeVertex2 = findOtherBeachEdgeVertexForTriangleCorners( currentCorner, p(currentCorner) );
       if ( (otherBeachEdgeVertex1 != -1) || (otherBeachEdgeVertex2 != -1) )
       {
         if ( ( currentV == otherV ) || ( currentV != otherV && otherBeachEdgeVertex1 == otherV) )
         {
           return currentCorner;
         }
         if ( ( currentV == otherV ) || ( currentV != otherV && otherBeachEdgeVertex2 == otherV) )
         {
           return currentCorner;
         }
       }
       currentCorner = s( currentCorner );
     } while ( currentCorner != c );
     if ( DEBUG && DEBUG_MODE >= LOW )
     {
       print( "Can't find beach edge corner for currentVertex! Potential bug" );
     }
     return -1;
   }

   int findOtherBeachEdgeVertexForVertex( int currentV, int prevV, int prevPrevV )
   {
     int c = getIslandCornerForVertex( currentV );
     int currentCorner = c;
     do
     {
       int otherBeachEdgeVertex1 = findOtherBeachEdgeVertexForTriangleCorners( currentCorner, n(currentCorner) );
       int otherBeachEdgeVertex2 = findOtherBeachEdgeVertexForTriangleCorners( currentCorner, p(currentCorner) );
       if ( (otherBeachEdgeVertex1 != -1) || (otherBeachEdgeVertex2 != -1) )
       {
         if ( ( currentV == prevV ) || ( currentV != prevV && otherBeachEdgeVertex1 != prevV && otherBeachEdgeVertex1 != prevPrevV && otherBeachEdgeVertex1 != -1) )
         {
           //cm[currentCorner] = 1;
           //cm[n(currentCorner)] = 1;
           return otherBeachEdgeVertex1;
         }
         if ( ( currentV == prevV ) || ( currentV != prevV && otherBeachEdgeVertex2 != prevV && otherBeachEdgeVertex2 != prevPrevV && otherBeachEdgeVertex2 != -1) )
         {
           //cm[currentCorner] = 1;
           //cm[p(currentCorner)] = 1;
           return otherBeachEdgeVertex2;
         }
       }
       currentCorner = s( currentCorner );
     } while ( currentCorner != c );
     if ( DEBUG && DEBUG_MODE >= LOW )
     {
       print( "Can't find beach edge vertex for currentVertex! Potential bug" );
     }
     return -1;
   }
}
