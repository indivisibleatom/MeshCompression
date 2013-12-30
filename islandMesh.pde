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

//For the second case
int TSPLIT = 11;
int TGATE = 12;
int TCHANNEL = 13;
int TWATER = 18; //Water before forming islands
int TISOLATEDWATER = 14;
int TLAGOON = 15;
int TJUNCTION = 16;
int TCAP = 17;
int TISLAND = 19;

class STypeTriangleState
{
  private int m_corner1;
  private int m_corner2;
  
  public STypeTriangleState( int corner1, int corner2 )
  {
    m_corner1 = corner1;
    m_corner2 = corner2;
  }
  
  public int corner1() { return m_corner1; }
  public int corner2() { return m_corner2; }
}

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
 Map<Integer, Integer> m_islandVertexNumber; //For a global vertex index, return the vertex number in the island (starting from 0 to num of vertices in the island)

 //TODO msati3: clean this up...where does this go? Do wholistically
 RingExpanderResult m_ringExpanderResult = null;
 IslandExpansionManager m_islandExpansionManager = null;
 ChannelExpansionPacketManager m_channelExpansionManager = null;
 BaseMesh baseMesh = null;
 
 //Debugging functionality
 int m_numAdvances = -1; //For advancing on an island border
 int m_currentAdvances = 0;
 int m_selectedIsland = -1;
 boolean []m_ringEdge = new boolean[3*maxnt];
 boolean m_fRingEdgesPopulated;
 boolean m_fRingExpanderRun = false;
 boolean m_fScreenShotColor = true;
 int m_coloringState;
 
 IslandMesh()
 {
   m_userInputHandler = new IslandMeshUserInputHandler(this);
   
   for (int i = 0; i < 3*maxnt; i++)
   {
     m_ringEdge[i] = false;
   }
   m_fRingEdgesPopulated = false;
   m_coloringState = 0;
 }
 
 IslandMesh(Mesh m)
 {
   G = m.G;
   V = m.V;
   O = m.O;
   nv = m.nv;
   nt = m.nt;
   
   m_userInputHandler = new IslandMeshUserInputHandler(this);
   for (int i = 0; i < 3*maxnt; i++)
   {
     m_ringEdge[i] = false;
   }
   m_fRingEdgesPopulated = false;
   m_coloringState = 0;
 }

 //Debug
 void pickc (pt X) {
   int origCC = cc;
    super.pickc(X);
    if ( origCC != cc && DEBUG && DEBUG_MODE >= LOW ) { print(" Island for corner " + cc + " is " + getIslandForVertexExtended(v(cc)) + " " + island[cc] + " Number of vertex wrt island is" + m_islandVertexNumber.get(v(cc)) + "\n" ); }
 } // picks closest corner to X

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
   m_drawingState.m_fShowEdges = false;
   drawIsland();
   
   if ( m_fScreenShotColor )
   {
     if ( m_coloringState >= 3 )
     {
       for (int i = 0; i < nv; i++)
       {
         if (isWaterVertex(i))
         {
           fill(red);
           show(G[i], 4);
         }
       }
     }
     if ( m_coloringState < 3 )
     {
       if ( m_fRingExpanderRun )
       {
         for (int i = 0; i < 3*nt; i++)
         {
           if (hasRingEdgeAroundCorners(p(i)))
           {
             strokeWeight(4);
             stroke(black);
             drawEdge(p(i));
           }
           else if (hasRingEdgeAroundCorners(n(i)))
           {
             strokeWeight(4);
             stroke(black);
             drawEdge(n(i));
           }
           else
           {
             strokeWeight(1);
             stroke(red);
             drawEdge(n(i));
             drawEdge(p(i));
           }
         }
       }
       else
       {
         stroke(red);
         for (int i = 0; i < 3*nt; i++)
         {
           drawEdge(n(i));
         }
       }
     }
     else
     {
     }
   }
   else
   {
     stroke(red);
     for (int i = 0; i < 3*nt; i++)
     {
       drawEdge(n(i));
     }
   }
 }
 
   void showTriangles(Boolean front, int opacity, float shrunk) {
    for (int t=0; t<nt; t++) {
      if (V[3*t] == -1) continue;    //Handle base mesh compacted triangles      
      if (!vis[tm[t]] || frontFacing(t)!=front || !visible[t]) continue;
      if (!frontFacing(t)&&showBack) {
        fill(blue); 
        shade(t); 
        continue;
      }
      //if(tm[t]==1) continue; 
      //if(tm[t]==1&&!showMiddle || tm[t]==0&&!showLeft || tm[t]==2&&!showRight) continue; 
      if (!m_fScreenShotColor)
      {
        if (tm[t]==0) fill(cyan, opacity); 
        if (tm[t]==1) fill(brown, opacity); 
        if (tm[t]==2) fill(orange, opacity); 
        if (tm[t]==3) fill(cyan, opacity); 
        if (tm[t]==4) fill(magenta, opacity); 
        if (tm[t]==5) fill(green, opacity); 
        if (tm[t]==6) fill(blue, opacity); 
        if (tm[t]==7) fill(#FAAFBA, opacity); 
        if (tm[t]==8) fill(blue, opacity); 
        if (tm[t]==9) fill(yellow, opacity); 
        
        if (tm[t]==10) fill(cyan, opacity); 
        if (tm[t]==11) fill(brown, opacity); 
        if (tm[t]==12) fill(orange, opacity); 
        if (tm[t]==13) fill(cyan, opacity); 
        if (tm[t]==14) fill(magenta, opacity); 
        if (tm[t]==15) fill(green, opacity); 
        if (tm[t]==16) fill(blue, opacity); 
        if (tm[t]==17) fill(#FAAFBA, opacity); 
        if (tm[t]==18) fill(blue, opacity); 
        if (tm[t]==19) fill(yellow, opacity); 
        
        if (vis[tm[t]]) {
          if (m_drawingState.m_shrunk != 0) showShrunkT(t, m_drawingState.m_shrunk); 
          else shade(t);
        }
      }
      else
      {
        switch(m_coloringState)
        {
          //1 => RingExpander complete, 2 => submerged, 3 => 
          case 0:
            if (tm[t]==0) fill(cyan, opacity); 
            if (tm[t]==1) fill(brown, opacity); 
            if (tm[t]==2) fill(orange, opacity); 
            if (tm[t]==3) fill(cyan, opacity); 
            if (tm[t]==4) fill(blue, opacity); 
            if (tm[t]==5) fill(green, opacity); 
            if (tm[t]==6) fill(blue, opacity); 
            if (tm[t]==7) fill(#FAAFBA, opacity); 
            if (tm[t]==8) fill(cyan, opacity); 
            if (tm[t]==9) fill(yellow, opacity); 
            break;
          case 1:
            if (tm[t]==0) fill(cyan, opacity); 
            if (tm[t]==1) fill(brown, opacity); 
            if (tm[t]==2) fill(orange, opacity); 
            if (tm[t]==3) fill(cyan, opacity); 
            if (tm[t]==4) fill(yellow, opacity); 
            if (tm[t]==5) fill(green, opacity); 
            if (tm[t]==6) fill(blue, opacity); 
            if (tm[t]==7) fill(#FAAFBA, opacity); 
            if (tm[t]==8) fill(cyan, opacity); 
            if (tm[t]==9) fill(yellow, opacity); 
            break;
          case 2:
            if (tm[t]==0) fill(cyan, opacity); 
            if (tm[t]==1) fill(brown, opacity); 
            if (tm[t]==2) fill(orange, opacity); 
            if (tm[t]==3) fill(cyan, opacity); 
            if (tm[t]==4) fill(blue, opacity); 
            if (tm[t]==5) fill(green, opacity); 
            if (tm[t]==6) fill(blue, opacity); 
            if (tm[t]==7) fill(cyan, opacity); 
            if (tm[t]==8) fill(cyan, opacity); 
            if (tm[t]==9) fill(yellow, opacity); 
            break;
          case 3:
            if (tm[t]==0) fill(cyan, opacity); 
            if (tm[t]==1) fill(brown, opacity); 
            if (tm[t]==2) fill(orange, opacity); 
            if (tm[t]==3) fill(cyan, opacity); 
            if (tm[t]==4) fill(blue, opacity); 
            if (tm[t]==5) fill(green, opacity); 
            if (tm[t]==6) fill(blue, opacity); 
            if (tm[t]==7) fill(cyan, opacity); 
            if (tm[t]==8) fill(cyan, opacity); 
            if (tm[t]==9) fill(yellow, opacity); 
            break;
          case 4: 
            vis[9] = false;
            if (tm[t]==0) fill(cyan, opacity); 
            if (tm[t]==1) fill(brown, opacity); 
            if (tm[t]==2) fill(orange, opacity); 
            if (tm[t]==3) fill(cyan, opacity); 
            if (tm[t]==4) fill(blue, opacity); 
            if (tm[t]==5) fill(green, opacity); 
            if (tm[t]==6) fill(blue, opacity); 
            if (tm[t]==7) fill(cyan, opacity); 
            if (tm[t]==8) fill(cyan, opacity); 
            break;
          case 5:
            vis[9] = false;
            vis[3] = false;
            vis[7] = false;
            vis[8] = false;
            if (tm[t]==0) fill(cyan, opacity); 
            if (tm[t]==1) fill(brown, opacity); 
            if (tm[t]==2) fill(orange, opacity); 
            if (tm[t]==4) fill(blue, opacity); 
            if (tm[t]==5) fill(green, opacity); 
            if (tm[t]==6) fill(blue, opacity); 
            break;
        }
        
        if (vis[tm[t]]) {
          if (m_drawingState.m_shrunk != 0) showShrunkT(t, m_drawingState.m_shrunk); 
          else shade(t);
        }
      }
    }
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
 
 //Returns the island number for a vertex. Returns -1 for water vertices
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

 //Returns island number ( = vertex id in base mesh ). Also assigns numbers to water vertices
 private int getIslandForVertexExtended(int vertex)
 {
   if ( m_fDrawIsles == true )
   {
     int island = getIslandForVertex(vertex);
     if ( island == -1 )
     {
       return m_islandForWaterVert.get( vertex );
     }
     return island;
   }
   return -1;
 } 
   
 //************************PRIVATE helpers***********************
 //State checking functions
 //If returns true if vertex is a water vertex (all island[corner] about the corner is -1)
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

 //Is the triangle water incident?
 private boolean waterIncident(int triangle)
 {
   int corner = c(triangle);
   return (isVertexForCornerWaterVertex(corner) || isVertexForCornerWaterVertex(n(corner)) || isVertexForCornerWaterVertex(p(corner)));
 }
 
 //Is a particular vertex a water vertex?  
 private boolean isWaterVertex(int vertex)
 {
   int cornerForVertex = cForV(vertex);
   return isVertexForCornerWaterVertex(cornerForVertex);
 }

 //Gives a beach edge, returns any one beach island corner of the first vertex -- there might be multiple. Returns -1 if not a beach edge
 private int getIslandCornerForVertex(int vertex, int otherVertex)
 {
   if ( DEBUG && DEBUG_MODE >= VERBOSE )
   {
     print("Getting island corner for first vertex for edge vertex1: " + vertex + " vertex2: " + otherVertex);
   }
   int initCorner = cForV(vertex);
   int curCorner = initCorner;
   do
   {
     if (island[curCorner] != -1)
     {
       if ( (vertex == otherVertex) || (v(n(curCorner)) == otherVertex) || (v(p(curCorner)) == otherVertex) )
       {
         return curCorner;
       }
     }
     curCorner = s(curCorner);
   }while (curCorner != initCorner);
   return -1;
 }
 
 //Gives a beach edge, returns the island corner for edge having vertex as its incident vertex and haing prevV as the other vertex
 private int getIslandCornerForVertexIncludingLagoon(int vertex, int prevV)
 {
   if ( DEBUG && DEBUG_MODE >= VERBOSE )
   {
     print("Getting island corner for first vertex for edge vertex1: " + vertex + " vertex2: " + prevV);
   }
   int initCorner = cForV(vertex);
   int curCorner = initCorner;
   do
   {
     if (island[curCorner] != -1 || isLagoonTriangleForCorner(curCorner))
     {
       if ( (vertex == prevV) || (v(n(curCorner)) == prevV) || (v(p(curCorner)) == prevV) )
       {
         return curCorner;
       }
     }
     curCorner = s(curCorner);
   }while (curCorner != initCorner);
   return -1;
 }
 
 //Returns island be unswinging
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

 private int getIslandAtCorner(int corner)
 {
   return island[corner];
 }
 
 //Given a corners, is there a ring edge corresponding to it
 private boolean hasRingEdgeAroundCorners(int c3)
 {
   if ( !m_fRingEdgesPopulated )
   {
     m_fRingEdgesPopulated = true;
     for (int i = 0; i < 3*nt; i++)
     {
       if ((tm[t(i)] == ISLAND) && (tm[t(o(i))] == WATER)) 
       {
         m_ringEdge[i] = true;
       }
       else
       {
         m_ringEdge[i] = false;
       }
     }
   }
   return m_ringEdge[c3];
 }
 
 //Given two corners belonging to a triangle, returns if this triangle has a beach edge
 private boolean hasBeachEdgeAroundCorners(int c1, int c2)
 {
   if (!((n(c1) == c2 || p(c1) == c2)))
   {
     if ( DEBUG && DEBUG_MODE >= LOW )
     {
       print("hasBeachEdgeAroundCorners: two corners passed that are not next or previous to each other");
     }
     return false;
   }

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
     if ( DEBUG && DEBUG_MODE >= LOW )
     {
       print("hasBeachEdgeForCorners: two corners passed that are not next or previous to each other");
     }
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
 
 //Returns true is a triangle is incident on a beach edge
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

 //0 for water vertex, 1 for island vertex 
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
 
 //This is obtained by swinging around the current
 //TODO msati3: this may have a bug
 private int getNextUsedIslandFromCorner( int iCorner )
 {
   int swingCorner = s( iCorner );
   return getIslandForVertexExtended(v(n(swingCorner)));
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
   
   //returns all the corners that are incident on the vertex starting from first corner by swinging about prevVertex, vertex edge, going upto first island (including lagoon) half-edge
   void incidentCorners( int vertex, int prevVertex, ArrayList<Integer> cornerList )
   {
     cornerList.clear();
     int startCorner = findStraitEdgeCornerForVertex( vertex, prevVertex );
     
     if (startCorner == -1)
     {
       if ( DEBUG && DEBUG_MODE >= LOW )
       {
         print("IslandMesh: IncidentTriangleType got -1 as BeachEdgeCornerForVertex");
       }
     }
     int currentCorner = s(startCorner);
     while ( island[currentCorner] == -1 && !isLagoonTriangleForCorner(currentCorner) )
     {
       cornerList.add( currentCorner );
       currentCorner = s(currentCorner);
     }
     if ( cornerList.size() == 0 )
     {
       print("Zero corners for vertex " + vertex + " " + prevVertex + " " + startCorner );
     }
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
   
   int getNextVertexOnIslandIncludingLagoon( int finalV, int currentV, int prevV, int prevPrevV )
   {
     int v = findOtherStraitEdgeVertexForVertex( currentV, prevV, prevPrevV );
     if ( DEBUG && DEBUG_MODE >= VERBOSE )
     {
       print ("The value of v is " + v + " currentV " + currentV + " prevV " + prevV + "\n");
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
   
   int getNextVertexOnIsland( int finalV, int currentV, int prevV, int prevPrevV )
   {
     int v = findOtherBeachEdgeVertexForVertex( currentV, prevV, prevPrevV );
     if ( DEBUG && DEBUG_MODE >= VERBOSE )
     {
       print ("The value of v is " + v + " currentV " + currentV + " prevV " + prevV + "\n");
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
   
   int findOtherIslandEdgeVertexForTriangleCorners( int c1, int c2 )
   {
     if ( hasBeachEdgeForCorners( c1, c2 ) )
     {
        return v(c2);
     }
     if ( isLagoonTriangleForCorner(c1) )
     {
        return v(c2);
     }
     return -1;
   }
   
   int findBeachEdgeCornerForVertex( int currentV, int otherV )
   {
     int c = getIslandCornerForVertex( currentV, otherV );
     int currentCorner = c;
     do
     {
       int otherBeachEdgeVertex1 = findOtherBeachEdgeVertexForTriangleCorners( currentCorner, n(currentCorner) );
       int otherBeachEdgeVertex2 = findOtherBeachEdgeVertexForTriangleCorners( currentCorner, p(currentCorner) );
       if ( DEBUG && DEBUG_MODE >= VERBOSE )
       {
         print("findBeachEdgeCornerForVertex currentCorner " + currentCorner + " currentVertex " + currentV + " otherV " + otherV + " otherBeachEdgeVertex1 " + otherBeachEdgeVertex1 + " otherBeachEdgeVertex2 " + otherBeachEdgeVertex2 + "\n");
       }
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
       print( "IslandMesh:findBeachEdgeCornerForVertex: Can't find beach edge corner for currentVertex! Potential bug" );
     }
     return -1;
   }
   
   //Given a vertex and prevVertex, find the corner for the strait edge
   int findStraitEdgeCornerForVertex( int currentV, int otherV )
   {
     int c = getIslandCornerForVertexIncludingLagoon( currentV, otherV );
     if ( DEBUG && DEBUG_MODE >= LOW )
     {
       if ( c == -1 )
       {
         print( "IslandMesh:findStraitEdgeCornerForVertex: Can't find island edge corner for currentVertex! Potential bug " + currentV + " " + otherV + "\n" );
       }
     }
     return c;
   }
   
   //Unswings till the outermost island-edge (including lagoon edge) is found
   private int findStraitEdgeForBeachEdgeVertices( int currentV, int prevV )
   {
     int corner = findBeachEdgeCornerForVertex( currentV, prevV );
     int swingCorner = p(corner);
     while ( isLagoonTriangleForCorner( u( swingCorner ) ) )
     {
       swingCorner = u(swingCorner);
     }
     return n(swingCorner);
   }

   //Returns other beach edge, given current and prev
   int findOtherBeachEdgeVertexForVertex( int currentV, int prevV, int prevPrevV )
   {
     int c = getIslandCornerForVertex( currentV, prevV );
     if ( DEBUG && DEBUG_MODE >= VERBOSE )
     {
       print("findOtherBeachEdgeVertexForVertex: Island corner for vertex is " + c + "\n");
     }
     int currentCorner = c;
     do
     {
       int otherBeachEdgeVertex1 = findOtherBeachEdgeVertexForTriangleCorners( currentCorner, n(currentCorner) );
       int otherBeachEdgeVertex2 = findOtherBeachEdgeVertexForTriangleCorners( currentCorner, p(currentCorner) );
       if ( DEBUG && DEBUG_MODE >= VERBOSE )
       {
         print("Other beach edge " + otherBeachEdgeVertex1 + " " + otherBeachEdgeVertex2 );
       }
       if ( (otherBeachEdgeVertex1 != -1) || (otherBeachEdgeVertex2 != -1) )
       {
         //If the currentV == prevV, we want to return the edge for which, the next leads to a valid beach edge vertex
         if (  ( ( currentV == prevV ) || ( currentV != prevV && otherBeachEdgeVertex1 != prevV && otherBeachEdgeVertex1 != prevPrevV) ) && otherBeachEdgeVertex1 != -1 )
         {
           return otherBeachEdgeVertex1;
         }
         if ( ( currentV != prevV && otherBeachEdgeVertex2 != prevV && otherBeachEdgeVertex2 != prevPrevV ) && otherBeachEdgeVertex2 != -1 )
         {
           return otherBeachEdgeVertex2;
         }
       }
       currentCorner = s( currentCorner );
     } while ( currentCorner != c );
     if ( DEBUG && DEBUG_MODE >= LOW )
     {
       print( "IslandMesh::findOtherBeachEdgeForBertex: Can't find beach edge vertex for currentVertex! Potential bug" );
     }
     return -1;
   }
   
   //Find next beach edge, given a potential island edge
   int findOtherBeachEdgeVertexForIslandEdge( int currentV, int prevV, int prevPrevV )
   {
     int c = getIslandCornerForVertexIncludingLagoon( currentV, prevV );
     if ( DEBUG && DEBUG_MODE >= VERBOSE )
     {
       print("findOtherBeachEdgeVertexForIslandEdge: Island corner for vertex is " + c + "\n");
     }
     int currentCorner = c;
     do
     {
       int otherBeachEdgeVertex1 = findOtherBeachEdgeVertexForTriangleCorners( currentCorner, n(currentCorner) );
       int otherBeachEdgeVertex2 = findOtherBeachEdgeVertexForTriangleCorners( currentCorner, p(currentCorner) );
       if ( DEBUG && DEBUG_MODE >= VERBOSE )
       {
         print("Other beach edge " + otherBeachEdgeVertex1 + " " + otherBeachEdgeVertex2 );
       }
       if ( (otherBeachEdgeVertex1 != -1) || (otherBeachEdgeVertex2 != -1) )
       {
         //If the currentV == prevV, we want to return the edge for which, the next leads to a valid beach edge vertex
         if (  ( ( currentV == prevV ) || ( currentV != prevV && otherBeachEdgeVertex1 != prevV && otherBeachEdgeVertex1 != prevPrevV) ) && otherBeachEdgeVertex1 != -1 )
         {
           return otherBeachEdgeVertex1;
         }
         if ( ( currentV != prevV && otherBeachEdgeVertex2 != prevV && otherBeachEdgeVertex2 != prevPrevV ) && otherBeachEdgeVertex2 != -1 )
         {
           return otherBeachEdgeVertex2;
         }
       }
       currentCorner = s( currentCorner );
     } while ( currentCorner != c );
     if ( DEBUG && DEBUG_MODE >= LOW )
     {
       print( "IslandMesh::findOtherBeachEdgeForBertex: Can't find beach edge vertex for currentVertex! Potential bug" );
     }
     return -1;
   }
   
   int findOtherStraitEdgeVertexForVertex( int currentV, int prevV, int prevPrevV )
   {
     int beachEdgeVertex = findOtherBeachEdgeVertexForIslandEdge( currentV, prevV, prevPrevV );
     int straitEdgeCorner = findStraitEdgeForBeachEdgeVertices( beachEdgeVertex, currentV );
     if ( DEBUG && DEBUG_MODE >= VERBOSE )
     {
       print("Vertex up next " + v(straitEdgeCorner) + "\n");
     }
     return v(straitEdgeCorner);
   }
   
   private boolean isLagoonTriangleForCorner( int corner1 )
   {
     return (triangleType( t(corner1) ) == LAGOON);
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
   
    //Populate the G of the base mesh
    BaseMesh populateBaseG()
    {
     m_channelExpansionManager = new ChannelExpansionPacketManager(nt);
     m_islandExpansionManager = new IslandExpansionManager();
     if ( DEBUG && DEBUG_MODE >= LOW )
     {
       print("Creating new base mesh");
     }
     baseMesh = new BaseMesh();
     baseMesh.setExpansionManager( m_islandExpansionManager, m_channelExpansionManager );
     baseMesh.declareVectors();

     m_vertexForIsland = new HashMap< Integer, Integer >();
     m_islandForWaterVert = new HashMap< Integer, Integer >();
     m_islandVertexNumber = new HashMap<Integer, Integer>();
     int numWaterVerts = getNumWaterVerts();
     int countWater = 0;
     pt[] baseMeshG = new pt[numIslands + numWaterVerts + 1000];
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
         if ( DEBUG && DEBUG_MODE >= VERBOSE )
         {
           print("Adding water vertex " + (numIslands + countWater) );
         }
         m_vertexForIsland.put( numIslands + countWater, i );
         m_islandForWaterVert.put( i, numIslands + countWater );
         baseMeshG[ numIslands + countWater ] = G[i]; 
         countWater++;
       }
     }
     baseMesh.nv = numIslands + numWaterVerts;
     baseMesh.setInitSize( baseMesh.nv );
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
     print("On before advance");
     m_numAdvances = 1;
     m_currentAdvances = 0;
   }
   
   void connectMeshStepByStep()
   {
     m_currentAdvances = 0;
     for (int i = 0; i < baseMesh.nv; i++)
     {
       int v = m_vertexForIsland.get(i);
       if ( DEBUG && DEBUG_MODE >= VERBOSE )
       {
         print("Current island is " + i);
       }
       if ( isIslandVertex( v ) && connectInBaseMesh(v) )
       {
         int currentVOnIsland = v;
         int prevVOnIsland = v;
         int prevPrevVOnIsland = v;
         int returnedVertex = -1;
         
         int bTrackedC2 = -1, bTrackedC3 = -1; //Track the last added triangle corners in the base mesh for this island.
         int nextUsedIsland = -1; //Track the next used island post a junction / water triangle.
         int bFirstC2 = -1, bFirstC3 = -1; //Track the initial triangle, so that the last can be combined post encircling the edges of the island

         ArrayList<Boolean> triangleStripInitial = new ArrayList<Boolean>();
         ArrayList<Boolean> triangleStripCurrent = new ArrayList<Boolean>();

         ArrayList<Integer> cornerList = new ArrayList<Integer>(); //Return the cornerList of JUNCTION and ISOLATEDWATER triangles obtained by swinging around
         do
         {
           returnedVertex = getNextVertexOnIslandIncludingLagoon( v, currentVOnIsland, prevVOnIsland, prevPrevVOnIsland );
           if (returnedVertex != -1)
           {
             vm[returnedVertex] = 2;
           }
           else
           {
             vm[v] = 2;
           }
           vm[prevVOnIsland] = 1;
           vm[prevPrevVOnIsland] = 1;
           vm[currentVOnIsland] = 3;
           if ( DEBUG && DEBUG_MODE >= VERBOSE )
           {
             if ( m_currentAdvances == m_numAdvances - 1 )
             {
               print("Setting the current vertex to be " + (returnedVertex == -1 ? v : returnedVertex) + " the last vertex is " + currentVOnIsland + "\n");
             }
           }

           incidentCorners( returnedVertex == -1 ? v : returnedVertex, currentVOnIsland, cornerList );

           for (int j = 0; j < cornerList.size(); j++)
           {
             int incidentCorner = cornerList.get(j);
             
             if ( DEBUG && DEBUG_MODE >= LOW )
             {
               if ( m_currentAdvances == m_numAdvances - 1)
               {
                 print("Corner " + cornerList.get(j) + " ");
               }
             }

             if ( (triangleType(t(incidentCorner)) == JUNCTION ) || (triangleType(t(incidentCorner)) == ISOLATEDWATER ) )
             {
               if ( DEBUG && DEBUG_MODE >= VERBOSE )
               {
                 if ( m_currentAdvances == m_numAdvances-1 )
                 {
                   print("Starting from currentVertex " + returnedVertex + " prevVertex " + prevVOnIsland + "bTrackedC2 " + bTrackedC2 + "incidentCorner " + incidentCorner);
                 }
               }

               int vertex2 = v( n( incidentCorner ) );
               int vertex3 = v( p( incidentCorner ) );
               int bv1 = i;
               int island2 = getIslandForVertexExtended( vertex2 );
               int island3 = getIslandForVertexExtended( vertex3 );

               int bv2 = island2;
               int bv3 = island3;
               int triangle = -1, bCornerForVertex = -1;
               
               boolean triangleAdded = false;

               if ( bv2 != -1 && bv3 != -1 )
               {
                 if ( bv1 <= bv2 && bv1 <= bv3 )
                 {
                   if ( m_currentAdvances == m_numAdvances-1 )
                   {
                      if (DEBUG && DEBUG_MODE >= VERBOSE)
                      {
                        print("Adding triangle for these vertices in main mesh " + (returnedVertex == -1 ? v : returnedVertex) + " " + vertex2 + " " + vertex3 + "\n");
                      }                 
                      baseMesh.addTriangle(bv1, bv2, bv3);
                      m_channelExpansionManager.addChannelExpansionPacket(bv1, bv2, bv3, m_islandVertexNumber.get( v(incidentCorner) ), m_islandVertexNumber.get( vertex2 ), m_islandVertexNumber.get( vertex3 ));
                      triangleAdded = true;
                   }
                   else
                   {
                     triangle = m_channelExpansionManager.getTriangle( bv1, bv2, bv3, m_islandVertexNumber.get( v(incidentCorner) ), m_islandVertexNumber.get( vertex2 ), m_islandVertexNumber.get( vertex3 ) );
                     bCornerForVertex = (m_channelExpansionManager.islandForCorner(3*triangle) == bv1) ? 3*triangle : (m_channelExpansionManager.islandForCorner(3*triangle+1) == bv1) ? 3*triangle+1 : 3*triangle+2;
                   }
                 }
                 else //The triangle has already been added while moving around another island. Fetch its corners
                 {
                   triangle = m_channelExpansionManager.getTriangle( bv1, bv2, bv3, m_islandVertexNumber.get( v(incidentCorner) ), m_islandVertexNumber.get( vertex2 ), m_islandVertexNumber.get( vertex3 ) );
                   if ( triangle == -1 )
                   {
                     if ( DEBUG && DEBUG_MODE >= LOW )
                     {
                       print("Tried finding added triangle in base mesh - returned -1! Error");
                     }
                   }
                   bCornerForVertex = (m_channelExpansionManager.islandForCorner(3*triangle) == bv1) ? 3*triangle : (m_channelExpansionManager.islandForCorner(3*triangle+1) == bv1) ? 3*triangle+1 : 3*triangle+2;
                 }
                 if ( bTrackedC2 != -1 ) //If junction / water has been encountered thus far
                 {
                   if ( triangleAdded )
                   {
                     if ( m_currentAdvances == m_numAdvances-1 )
                     {
                       addOppositeForUnusedIsland( m_channelExpansionManager.nc-1, m_channelExpansionManager.nc-2, bTrackedC2, bTrackedC3, nextUsedIsland, triangleStripCurrent );
                     }
                     triangleStripCurrent = new ArrayList<Boolean>();
                   }
                   else
                   {
                     if ( m_currentAdvances == m_numAdvances-1 )
                     {
                       addOppositeForUnusedIsland( baseMesh.p(bCornerForVertex), baseMesh.n(bCornerForVertex), bTrackedC2, bTrackedC3, nextUsedIsland, triangleStripCurrent );
                     }
                     triangleStripCurrent = new ArrayList<Boolean>();
                   }
                 }
                 else
                 {
                   if ( triangleAdded )
                   {
                     bFirstC2 = m_channelExpansionManager.nc-2;
                     bFirstC3 = m_channelExpansionManager.nc-1;
                   }
                   else
                   {
                     bFirstC2 = baseMesh.n(bCornerForVertex);
                     bFirstC3 = baseMesh.p(bCornerForVertex);
                   }
                 }

                 nextUsedIsland = getNextUsedIslandFromCorner( incidentCorner );
                 if ( DEBUG && DEBUG_MODE >= VERBOSE )
                 {
                   print("The next island that is used is " + nextUsedIsland + "from corner " + incidentCorner + "\n");
                 }

                 if ( triangleAdded )
                 {
                   bTrackedC2 = m_channelExpansionManager.nc-2;
                   bTrackedC3 = m_channelExpansionManager.nc-1;
                 }
                 else
                 {
                   bTrackedC2 = baseMesh.n(bCornerForVertex);
                   bTrackedC3 = baseMesh.p(bCornerForVertex);
                 }
                 
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
             } //If juntion or isolated water corner
             else //Not junction and isolated water
             {
               if ( j != 0 && j != cornerList.size() - 1 ) //The first corner goes from last island to this and the last corner goes from this island to the next
               {
                 if ( bTrackedC2 == -1 )
                 {
                   if ( DEBUG && DEBUG_MODE >= VERBOSE )
                   {
                     if ( m_currentAdvances == m_numAdvances-1 )
                     {
                       print("Adding false to initial triangle strip ");
                     }
                   }
                   triangleStripInitial.add(false);
                 }
                 else 
                 {
                   if ( DEBUG && DEBUG_MODE >= VERBOSE )
                   {
                     if ( m_currentAdvances == m_numAdvances-1 )
                     {
                       print("Adding false to triangleStrip ");
                     }
                   }
                   //TODO msati3: Temp remove after debugging
                   /*if (cornerList.get(j) == 572 || cornerList.get(j) == 573)
                   {
                     print("Here adding false to current");
                   }*/
                   triangleStripCurrent.add(false);
                 }
               }
             }
           } //end for over cornerlist
           if ( DEBUG && DEBUG_MODE >= VERBOSE )
           {
             print("\n");
           }
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
           
           prevPrevVOnIsland = prevVOnIsland;
           prevVOnIsland = currentVOnIsland;
           currentVOnIsland = returnedVertex;
           
           if ( bTrackedC2 == -1 ) //Each time we advance on the island beach edge, add a triangleStrip.true
           {
             if ( DEBUG && DEBUG_MODE >= VERBOSE )
             {
               if ( m_currentAdvances == m_numAdvances-1 )
               {
                 print("Adding true to initial triangleStrip ");
               }
             }
             triangleStripInitial.add(true);
           }
           else
           {
             if ( DEBUG && DEBUG_MODE >= VERBOSE )
             {
               if ( m_currentAdvances == m_numAdvances-1 )
               {
                 print("Adding true to triangleStrip ");
               }
             }
             triangleStripCurrent.add(true);
           }
         } while ( returnedVertex != -1 ); //end advancing over the beach edges
         vm[v] = 1;
         vm[prevVOnIsland] = 1;
         if ( bTrackedC2 != -1 )
         {
           if ( m_currentAdvances == m_numAdvances-1 )
           {
             if ( DEBUG && DEBUG_MODE >= VERBOSE )
             {
               print("Closing the current island");
             }
           }
           for (int k = 0; k < triangleStripInitial.size(); k++)
           {
             triangleStripCurrent.add( triangleStripInitial.get(k) );
           }
           if ( m_currentAdvances == m_numAdvances-1 )
           {
             addOppositeForUnusedIsland( bFirstC2, bFirstC3, bTrackedC2, bTrackedC3, nextUsedIsland, triangleStripCurrent );
           }
           triangleStripCurrent = new ArrayList<Boolean>();
           triangleStripInitial = new ArrayList<Boolean>();
         }
       }
       else if ( !isIslandVertex(v) ) //Is a water vertex
       {
         int initCorner = incidentTriangleType( v, ISOLATEDWATER );
         int currentCorner = initCorner;

         int bTrackedC2 = -1, bTrackedC3 = -1; //Track the last added triangle corners in the base mesh for this island.
         int nextUsedIsland = -1; //Track the next used island post a junction / water triangle.
         int bFirstC2 = -1, bFirstC3 = -1; //Track the initial triangle, so that the last can be combined post encircling the edges of the island
         boolean fTriangleAdded = false;
         int triangle = -1, bCornerForVertex = -1;
         ArrayList<Boolean> triangleStripCurrent = new ArrayList<Boolean>();

         if ( DEBUG && DEBUG_MODE >= VERBOSE )
         {
           print("Found corner " + currentCorner);
         }
         do
         {
           int island1 = getIslandForVertexExtended( v );
           int island2 = getIslandForVertexExtended( v(n(currentCorner)) );
           int island3 = getIslandForVertexExtended( v(p(currentCorner)) );
           fTriangleAdded = false;

           if ( triangleType(t(currentCorner)) == ISOLATEDWATER )
           {
             if ( island1 <= island2 && island1 <= island3 )
             {
               baseMesh.addTriangle(island1, island2, island3);
               m_channelExpansionManager.addChannelExpansionPacket(island1, island2, island3, m_islandVertexNumber.get(v(currentCorner)), m_islandVertexNumber.get(v(n(currentCorner))), m_islandVertexNumber.get(v(p(currentCorner))) );
               fTriangleAdded = true;
             }
             else //Handle already added triangles triangles
             {
               triangle = m_channelExpansionManager.getTriangle( island1, island2, island3, m_islandVertexNumber.get( v(currentCorner) ), m_islandVertexNumber.get( v(n(currentCorner)) ), m_islandVertexNumber.get( v(p(currentCorner)) ) );
               if ( triangle == -1 )
               {
                 if ( DEBUG && DEBUG_MODE >= LOW )
                 {
                   print("Tried finding added triangle in base mesh - returned -1! Error");
                 }
               }
               bCornerForVertex = (m_channelExpansionManager.islandForCorner(3*triangle) == island1) ? 3*triangle : (m_channelExpansionManager.islandForCorner(3*triangle+1) == island1) ? 3*triangle+1 : 3*triangle+2;
             }
             
             if ( bTrackedC2 != -1 )
             {
               if ( fTriangleAdded )
               {
                 addOppositeForUnusedIsland( m_channelExpansionManager.nc-1, m_channelExpansionManager.nc-2, bTrackedC2, bTrackedC3, nextUsedIsland, triangleStripCurrent );
                 triangleStripCurrent = new ArrayList<Boolean>();
               }
               else
               {
                 addOppositeForUnusedIsland( baseMesh.p(bCornerForVertex), baseMesh.n(bCornerForVertex), bTrackedC2, bTrackedC3, nextUsedIsland, triangleStripCurrent );
                 triangleStripCurrent = new ArrayList<Boolean>();
               }
             }  
             else
             {
               if ( fTriangleAdded )
               {
                 bFirstC2 = m_channelExpansionManager.nc-2;
                 bFirstC3 = m_channelExpansionManager.nc-1;
               }
               else
               {
                 bFirstC2 = baseMesh.n(bCornerForVertex);
                 bFirstC3 = baseMesh.p(bCornerForVertex);
               }
             }
             nextUsedIsland = getNextUsedIslandFromCorner( currentCorner );
                   
             if ( fTriangleAdded )
             {
               bTrackedC2 = m_channelExpansionManager.nc-2;
               bTrackedC3 = m_channelExpansionManager.nc-1;                 
             }
             else
             {
               bTrackedC2 = baseMesh.n(bCornerForVertex);
               bTrackedC3 = baseMesh.p(bCornerForVertex);
             }
           }
           else //Not water corner
           {
             if ( bTrackedC2 == -1 )
             {
               if ( DEBUG && DEBUG_MODE >= LOW )
               {
                 print("This should not happen, as we start from a water corner!");
               }
             }
             else
             {
               triangleStripCurrent.add(false);
             }
           }   
           currentCorner = s(currentCorner);
         } while (currentCorner != initCorner);
         
         if ( bTrackedC2 != -1 )
         {
           addOppositeForUnusedIsland( bFirstC2, bFirstC3, bTrackedC2, bTrackedC3, nextUsedIsland, triangleStripCurrent );
           triangleStripCurrent = new ArrayList<Boolean>();
         }
       } //If Water vertex
     } //end for loop over base mesh vertices
   }

   void connectMesh()
   {
     m_numAdvances = -1;
     for (int i = 0; i < baseMesh.nv; i++)
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
         ArrayList<Boolean> triangleStripInitial = new ArrayList<Boolean>();
         ArrayList<Boolean> triangleStripCurrent = new ArrayList<Boolean>();

         ArrayList<Integer> cornerList = new ArrayList<Integer>(); //Return the cornerList of JUNCTION and ISOLATEDWATER triangles obtained by swinging around
         do
         {
           returnedVertex = getNextVertexOnIslandIncludingLagoon( v, currentVOnIsland, prevVOnIsland, prevPrevVOnIsland );

           incidentCorners( returnedVertex == -1 ? v : returnedVertex, currentVOnIsland, cornerList );

           for (int j = 0; j < cornerList.size(); j++)
           {
             int incidentCorner = cornerList.get(j);
             if ( (triangleType(t(incidentCorner)) == JUNCTION ) || (triangleType(t(incidentCorner)) == ISOLATEDWATER ) )
             {
               int vertex2 = v( n( incidentCorner ) );
               int vertex3 = v( p( incidentCorner ) );
               int bv1 = i;
               int island2 = getIslandForVertexExtended( vertex2 );
               int island3 = getIslandForVertexExtended( vertex3 );

               int bv2 = island2;
               int bv3 = island3;
               
               int triangle = -1, bCornerForVertex = -1;
               
               boolean fTriangleAdded = false;

               if ( bv2 != -1 && bv3 != -1 )
               {
                 if ( bv1 <= bv2 && bv1 <= bv3 )
                 {
                   baseMesh.addTriangle(bv1, bv2, bv3);
                   m_channelExpansionManager.addChannelExpansionPacket(bv1, bv2, bv3, m_islandVertexNumber.get( v(incidentCorner) ), m_islandVertexNumber.get( vertex2 ), m_islandVertexNumber.get( vertex3 ) );
                   fTriangleAdded = true;
                 }
                 else //The triangle has already been added while moving around another island. Fetch its corners
                 {
                   triangle = m_channelExpansionManager.getTriangle( bv1, bv2, bv3, m_islandVertexNumber.get( v(incidentCorner) ), m_islandVertexNumber.get( vertex2 ), m_islandVertexNumber.get( vertex3 ) );
                   if ( triangle == -1 )
                   {
                     if ( DEBUG && DEBUG_MODE >= LOW )
                     {
                       print("Tried finding added triangle in base mesh - returned -1! Error");
                     }
                   }
                   bCornerForVertex = (m_channelExpansionManager.islandForCorner(3*triangle) == bv1) ? 3*triangle : (m_channelExpansionManager.islandForCorner(3*triangle+1) == bv1) ? 3*triangle+1 : 3*triangle+2;
                 }
                 if ( bTrackedC2 != -1 )
                 {
                   if ( fTriangleAdded )
                   {
                     addOppositeForUnusedIsland( m_channelExpansionManager.nc-1, m_channelExpansionManager.nc-2, bTrackedC2, bTrackedC3, nextUsedIsland, triangleStripCurrent );
                     triangleStripCurrent = new ArrayList<Boolean>();
                   }
                   else
                   {
                     addOppositeForUnusedIsland( baseMesh.p(bCornerForVertex), baseMesh.n(bCornerForVertex), bTrackedC2, bTrackedC3, nextUsedIsland, triangleStripCurrent );
                     triangleStripCurrent = new ArrayList<Boolean>();
                   }
                 }
                 else
                 {
                   if ( fTriangleAdded )
                   {
                     bFirstC2 = m_channelExpansionManager.nc-2;
                     bFirstC3 = m_channelExpansionManager.nc-1;
                   }
                   else
                   {
                     bFirstC2 = baseMesh.n(bCornerForVertex);
                     bFirstC3 = baseMesh.p(bCornerForVertex);
                   }
                 }

                 nextUsedIsland = getNextUsedIslandFromCorner( incidentCorner );
                 
                 if ( fTriangleAdded )
                 {
                   bTrackedC2 = m_channelExpansionManager.nc-2;
                   bTrackedC3 = m_channelExpansionManager.nc-1;                 
                 }
                 else
                 {
                   bTrackedC2 = baseMesh.n(bCornerForVertex);
                   bTrackedC3 = baseMesh.p(bCornerForVertex);
                 }
               }
               else
               {
                 if ( DEBUG && DEBUG_MODE >= VERBOSE )
                 {
                   print ("Get a -1 as one of the base vertices incident on a Junction / Water triangle. Error!");
                 }
               }
             }//If junction or isolated water
             else //Not junction and isolated water
             {
               if ( j != 0 && j != cornerList.size() - 1 ) //The first corner goes from last island to this and the last corner goes from this island to the next
               {
                 if ( bTrackedC2 == -1 )
                 {
                   triangleStripInitial.add(false);
                 }
                 else
                 {
                   triangleStripCurrent.add(false);
                 }
               }
             }
           } //For each corner
           prevPrevVOnIsland = prevVOnIsland;
           prevVOnIsland = currentVOnIsland;
           currentVOnIsland = returnedVertex;
           
           if ( bTrackedC2 == -1 )
           {
             triangleStripInitial.add(true);
           }
           else
           {
             triangleStripCurrent.add(true);
           }
         } while ( returnedVertex != -1 );
         if ( bTrackedC2 != -1 )
         {
           for (int k = 0; k < triangleStripInitial.size(); k++)
           {
             triangleStripCurrent.add( triangleStripInitial.get(k) );
           }
           addOppositeForUnusedIsland( bFirstC2, bFirstC3, bTrackedC2, bTrackedC3, nextUsedIsland, triangleStripCurrent );
           triangleStripCurrent = new ArrayList<Boolean>();
           triangleStripInitial = new ArrayList<Boolean>();
         }
       }
       else if ( !isIslandVertex(v) ) //Is a water vertex
       {
         int initCorner = incidentTriangleType( v, ISOLATEDWATER );
         int currentCorner = initCorner;

         int bTrackedC2 = -1, bTrackedC3 = -1; //Track the last added triangle corners in the base mesh for this island.
         int nextUsedIsland = -1; //Track the next used island post a junction / water triangle.
         int bFirstC2 = -1, bFirstC3 = -1; //Track the initial triangle, so that the last can be combined post encircling the edges of the island
         boolean fTriangleAdded = false;
         int triangle = -1, bCornerForVertex = -1;
         ArrayList<Boolean> triangleStripCurrent = new ArrayList<Boolean>();

         if ( DEBUG && DEBUG_MODE >= VERBOSE )
         {
           print("Found corner " + currentCorner);
         }
         do
         {
           int island1 = getIslandForVertexExtended( v );
           int island2 = getIslandForVertexExtended( v(n(currentCorner)) );
           int island3 = getIslandForVertexExtended( v(p(currentCorner)) );
           fTriangleAdded = false;

           if ( triangleType(t(currentCorner)) == ISOLATEDWATER )
           {
             if ( island1 <= island2 && island1 <= island3 )
             {
               baseMesh.addTriangle(island1, island2, island3);
               m_channelExpansionManager.addChannelExpansionPacket(island1, island2, island3, m_islandVertexNumber.get(v(currentCorner)), m_islandVertexNumber.get(v(n(currentCorner))), m_islandVertexNumber.get(v(p(currentCorner))) );
               fTriangleAdded = true;
             }
             else //Handle already added triangles triangles
             {
               triangle = m_channelExpansionManager.getTriangle( island1, island2, island3, m_islandVertexNumber.get( v(currentCorner) ), m_islandVertexNumber.get( v(n(currentCorner)) ), m_islandVertexNumber.get( v(p(currentCorner)) ) );
               if ( triangle == -1 )
               {
                 if ( DEBUG && DEBUG_MODE >= LOW )
                 {
                   print("Tried finding added triangle in base mesh - returned -1! Error");
                 }
               }
               bCornerForVertex = (m_channelExpansionManager.islandForCorner(3*triangle) == island1) ? 3*triangle : (m_channelExpansionManager.islandForCorner(3*triangle+1) == island1) ? 3*triangle+1 : 3*triangle+2;
             }
             
             if ( bTrackedC2 != -1 )
             {
               if ( fTriangleAdded )
               {
                 addOppositeForUnusedIsland( m_channelExpansionManager.nc-1, m_channelExpansionManager.nc-2, bTrackedC2, bTrackedC3, nextUsedIsland, triangleStripCurrent );
                 triangleStripCurrent = new ArrayList<Boolean>();
               }
               else
               {
                 addOppositeForUnusedIsland( baseMesh.p(bCornerForVertex), baseMesh.n(bCornerForVertex), bTrackedC2, bTrackedC3, nextUsedIsland, triangleStripCurrent );
                 triangleStripCurrent = new ArrayList<Boolean>();
               }
             }  
             else
             {
               if ( fTriangleAdded )
               {
                 bFirstC2 = m_channelExpansionManager.nc-2;
                 bFirstC3 = m_channelExpansionManager.nc-1;
               }
               else
               {
                 bFirstC2 = baseMesh.n(bCornerForVertex);
                 bFirstC3 = baseMesh.p(bCornerForVertex);
               }
             }
             nextUsedIsland = getNextUsedIslandFromCorner( currentCorner );
                   
             if ( fTriangleAdded )
             {
               bTrackedC2 = m_channelExpansionManager.nc-2;
               bTrackedC3 = m_channelExpansionManager.nc-1;                 
             }
             else
             {
               bTrackedC2 = baseMesh.n(bCornerForVertex);
               bTrackedC3 = baseMesh.p(bCornerForVertex);
             }
           }
           else //Not water corner
           {
             if ( bTrackedC2 == -1 )
             {
               if ( DEBUG && DEBUG_MODE >= LOW )
               {
                 //print("This should not happen, as we start from a water corner!");
               }
             }
             else
             {
               triangleStripCurrent.add(false);
             }
           }   
           currentCorner = s(currentCorner);
         } while (currentCorner != initCorner);
         
         if ( bTrackedC2 != -1 )
         {
           addOppositeForUnusedIsland( bFirstC2, bFirstC3, bTrackedC2, bTrackedC3, nextUsedIsland, triangleStripCurrent );
           triangleStripCurrent = new ArrayList<Boolean>();
         }
       } //If Water vertex
     } //end for loop over base mesh vertices
   }
   
   //Populate the m_islandVertexNumber list - the oriented number of each island vertex with respect to a starting point
   //Also creates the island stream to be sent for the case of expansion
   void numberVerticesOfIslandsAndCreateStream()
   { 
     for (int i = 0; i < nv; i++)
     {
       m_islandVertexNumber.put(i, -1);
     }
     for (int i = 0; i < baseMesh.nv; i++)
     {
       int v = m_vertexForIsland.get(i);
       int numberVertex = 0;
      
       if ( isIslandVertex( v ) )
       {
         IslandExpansionStream islandStream = m_islandExpansionManager.addStream(i);
     
         int currentVOnIsland = v;
         int prevVOnIsland = v;
         int prevPrevVOnIsland = v;
         int returnedVertex = -1;
         islandStream.add(G[currentVOnIsland], numberVertex);         
         m_islandVertexNumber.put(currentVOnIsland, numberVertex++);

         do
         {
           returnedVertex = getNextVertexOnIsland( v, currentVOnIsland, prevVOnIsland, prevPrevVOnIsland );
           int corner = findBeachEdgeCornerForVertex( currentVOnIsland, prevVOnIsland );

           prevPrevVOnIsland = prevVOnIsland;
           prevVOnIsland = currentVOnIsland;
           currentVOnIsland = returnedVertex;

           if ( currentVOnIsland != -1 )
           {
             islandStream.add(G[currentVOnIsland], numberVertex);         
             m_islandVertexNumber.put(currentVOnIsland, numberVertex++);
           }
         } while ( returnedVertex != -1 );
         
         if ( DEBUG && DEBUG_MODE >= VERBOSE )
         {
           print("Compressing island " + i + " global vertex start index " + m_vertexForIsland.get(i) + " global vertex end index " + prevVOnIsland + "\n");
         }
         String clersString = compressIsland( m_vertexForIsland.get(i), prevVOnIsland );
         islandStream.setClersString( clersString );
         if ( DEBUG && DEBUG_MODE >= VERBOSE )
         {
           print("The clersString for island " + i + "is " + clersString + "\n");
         }
         compressIslandLagoons( i );
       }
       else //!isIslandVertex - waterVertex
       { 
         m_islandVertexNumber.put(v, 0);
       }
     }
   }
   
   //Given three vertices (int the island mesh), belonging to a single island, find out the CLERS type of that triangle
   char getCharForIslandTriangle( int vOther, int v1, int v2 )
   {
     int vIslandOther = m_islandVertexNumber.get(vOther);
     int v1Island = m_islandVertexNumber.get(v1);
     int v2Island = m_islandVertexNumber.get(v2);
     
     if ( (vIslandOther == v1Island + 1) && (vIslandOther == v2Island - 1) )
     {
       return 'e';
     }
     else if (vIslandOther == v1Island + 1)
     {
       return 'l';
     }
     else if (vIslandOther == v2Island -1)
     {
       return 'r';
     }
     return 's'; //TODO msati3: can you add a check in here to ensure no C triangles?
   }
   
   private String compressIsland( int initialVertex, int finalVertex )
   {
     if ( DEBUG && DEBUG_MODE >= VERBOSE )
     {
       print("Compressing island. Local vertex start " + m_islandVertexNumber.get(initialVertex) + " Local vertex end " + m_islandVertexNumber.get(finalVertex) + "\n");
     }
     Stack<STypeTriangleState> sState = new Stack<STypeTriangleState>();
     StringBuilder clersString = new StringBuilder();
     
     int currentCorner1 = findBeachEdgeCornerForVertex( initialVertex, finalVertex );
     if ( v(n(currentCorner1)) == finalVertex )
     {
       if ( DEBUG && DEBUG_MODE >= VERBOSE )
       {
         print("CompressIsland - incorrect order of sending of initialVertex and the finalVertex ");
       }
     }
     
     int currentCorner2 = p(currentCorner1);
     int cornerOther = n(currentCorner1);
     boolean endCompress = false;
     while ( !endCompress )
     {
       cornerOther = n(currentCorner1);
       char ch = getCharForIslandTriangle( v(cornerOther), v(currentCorner1), v(currentCorner2) );
       
       if ( DEBUG && DEBUG_MODE >= VERBOSE )
       {
         print("Vertices for compression are " + v(cornerOther) + " " + v(currentCorner1) + " " + v(currentCorner2) + " Char ch is " + ch + "\n");
       }
       switch( ch )
       {
         case 'l': currentCorner1 = u(cornerOther);
                   currentCorner2 = s(currentCorner2);
                   break;
         case 'r': currentCorner1 = u(currentCorner1);
                   currentCorner2 = s(cornerOther);
                   break;
         case 's': {
                     //First L and then R
                     int otherCorner1 = u(cornerOther);
                     int otherCorner2 = s(currentCorner2);
                     currentCorner1 = u(currentCorner1);
                     currentCorner2 = s(cornerOther);
                     if ( DEBUG && DEBUG_MODE >= VERBOSE )
                     {
                       print("Pushed state " + v(otherCorner1) + " " + v(otherCorner2) + "\n");
                     }
                     STypeTriangleState state = new STypeTriangleState( otherCorner1, otherCorner2 );
                     sState.push(state);
                   }
                   break;
         case 'e': if ( sState.isEmpty() )
                   {
                     endCompress = true;
                   }
                   else
                   {
                     STypeTriangleState state = sState.pop();
                     if ( DEBUG && DEBUG_MODE >= VERBOSE )
                     {
                       print("Popped state " + state.corner1() + " " + state.corner2() +"\n");
                     }
                     currentCorner1 = state.corner1();
                     currentCorner2 = state.corner2();
                   }
                   break;
       }
       clersString.append(ch);
     }
     return clersString.toString();
   }
   
   //Given three vertices (in the island mesh), belonging to a single lagoon triangle, find out the CLERS type of that triangle
   char getCharForLagoonTriangleWithCorners( int cornerOther, int c1, int c2 )
   {
     if ( isLagoonTriangleForCorner( r(cornerOther ) ) && isLagoonTriangleForCorner( l(cornerOther ) ) )
     {
       return 's';
     }
     else if ( isLagoonTriangleForCorner( r(cornerOther) ) )
     {
       return 'l';
     }
     else if ( isLagoonTriangleForCorner( l(cornerOther) ) )
     {
       return 'r';
     }
     return 'e'; //TODO msati3: can you add a check in here to ensure no C triangles?
   }

   //Given two corners forming the gate of the lagoon, create clers string for the lagoon
   private String compressIslandLagoon( int corner1, int corner2 )
   {
     Stack<STypeTriangleState> sState = new Stack<STypeTriangleState>();

     if ( DEBUG && DEBUG_MODE >= VERBOSE )
     {
       print("Compress island lagoon called for " + m_islandVertexNumber.get( v(corner1) ) + " " + m_islandVertexNumber.get( v(corner2) ) + " " + corner1 + " " + corner2 + "\n");
     }

     StringBuilder clersString = new StringBuilder();
    
     int currentCorner1 = corner1;
     int currentCorner2 = corner2;
     
     if ( p(currentCorner1) == currentCorner2 )
     {
       if ( DEBUG && DEBUG_MODE >= LOW )
       {
         print("Compress Island Lagoon: next current corner != corner2!!\n");
       }
     }
     int cornerOther = p(currentCorner1);
     boolean endCompress = false;
     while ( !endCompress )
     {
       cornerOther = p(currentCorner1);
       char ch = getCharForLagoonTriangleWithCorners( cornerOther, currentCorner1, currentCorner2 );
       
       if ( DEBUG && DEBUG_MODE >= VERBOSE )
       {
         print("Vertices for compression are " + v(cornerOther) + " " + v(currentCorner1) + " " + v(currentCorner2) + " Char ch is " + ch + "\n");
       }
       switch( ch )
       {
         case 'l': currentCorner1 = s(currentCorner1);
                   currentCorner2 = u(cornerOther);
                   break;
         case 'r': currentCorner1 = s(cornerOther);
                   currentCorner2 = u(currentCorner2);
                   break;
         case 's': {
                     //First R and then L. TODO msati3: Fix this discrepancy b/w lagoon expansion and island expansion?
                     int otherCorner1 = s(cornerOther);
                     int otherCorner2 = u(currentCorner2);
                     currentCorner1 = s(currentCorner1);
                     currentCorner2 = u(cornerOther);
                     if ( DEBUG && DEBUG_MODE >= VERBOSE )
                     {
                       print("Pushed state " + v(otherCorner1) + " " + v(otherCorner2) + "\n");
                     }
                     STypeTriangleState state = new STypeTriangleState( otherCorner1, otherCorner2 );
                     sState.push(state);
                   }
                   break;
         case 'e': if ( sState.isEmpty() )
                   {
                     endCompress = true;
                   }
                   else
                   {
                     STypeTriangleState state = sState.pop();
                     if ( DEBUG && DEBUG_MODE >= VERBOSE )
                     {
                       print("Popped state " + state.corner1() + " " + state.corner2() +"\n");
                     }
                     currentCorner1 = state.corner1();
                     currentCorner2 = state.corner2();
                   }
                   break;
       }
       clersString.append(ch);
     }
     if ( DEBUG && DEBUG_MODE >= VERBOSE )
     {
       print("The CLERS string for the lagoon is " + clersString + "\n");
     }
     return clersString.toString();  
   }
   
   //Given an island number, compresses the lagoons in the island, adding them to the expansion stream for the island, using CLERS encoding
   private void compressIslandLagoons( int island )
   {
       /*if (island != 8)
       {
         return;
       }*/
       int v = m_vertexForIsland.get(island);

       IslandExpansionStream islandStream = m_islandExpansionManager.getStream( island );

       if ( isIslandVertex( v ) )
       {   
         int currentVOnIsland = v;
         int prevVOnIsland = v;
         int prevPrevVOnIsland = v;
         int returnedVertex = -1;
         
         int currentVertexNumber = 0;
         int nextVertexNumber = 0;

         do
         {
           returnedVertex = getNextVertexOnIsland( v, currentVOnIsland, prevVOnIsland, prevPrevVOnIsland );
           int corner = -1;
           if ( returnedVertex != -1 )
           {
             corner = findBeachEdgeCornerForVertex( returnedVertex, currentVOnIsland );
           }
           else
           {
             corner = findBeachEdgeCornerForVertex( v, currentVOnIsland );
           }

           int currentCorner = s(corner);
           while ( currentCorner != corner ) //Swing around the current corner, to get a lagoon triangle
           {
             //If not a consecutive vertex, but still an island vertex => lagoon triangle. Should be going forward
             if ( isLagoonTriangleForCorner( currentCorner ) && (v(n(currentCorner)) != currentVOnIsland) ) /* && ( m_islandVertexNumber.get((v(n(currentCorner)))) != ( (m_islandVertexNumber.get((v(currentCorner))) + 1) % VERTICES_PER_ISLAND ) ) ) */
             {
               if ( !isLagoonTriangleForCorner(u(currentCorner)) && ! isLagoonTriangleForCorner(s(n(currentCorner))) ) //If this is the starting lagoon triangle
               {
                 String clersString = compressIslandLagoon( currentCorner, n(currentCorner) );
                 LagoonExpansionStream lagoonStream = m_islandExpansionManager.addLagoon(island);
                 lagoonStream.setVertices( m_islandVertexNumber.get((v(currentCorner))), m_islandVertexNumber.get((v(n(currentCorner)))) );
                 lagoonStream.setClersString(clersString);
               }
             }
             currentCorner = s(currentCorner);
           }

           prevPrevVOnIsland = prevVOnIsland;
           prevVOnIsland = currentVOnIsland;
           currentVOnIsland = returnedVertex;
         } while ( returnedVertex != -1 );        
       }
       else //!isIslandVertex - waterVertex
       { 
         if ( DEBUG && DEBUG_MODE >= LOW )
         {
           print("Compress Island Lagoons - Should not be called for water vertex!! \n");
         }
       }
   }
       
   private void addOppositeForUnusedIsland( int bc2, int bc3, int btrackedc2, int btrackedc3, int nextUsedIsland, ArrayList<Boolean> triangleStrip )
   {
     if ( m_numAdvances != -1 && m_currentAdvances == m_numAdvances-1 )
     {
       if ( DEBUG && DEBUG_MODE >= VERBOSE )
       {
         print("AddOppositeForUnused " + m_channelExpansionManager.islandForCorner(bc2) + " " + m_channelExpansionManager.islandForCorner(bc3) + " " + m_channelExpansionManager.islandForCorner(btrackedc2) + " " + m_channelExpansionManager.islandForCorner(btrackedc3) + " " + nextUsedIsland + "\n");
       }
     }

     int corner1 = -1, corner2 = -1;

     if ( m_channelExpansionManager.islandForCorner( bc2 ) == nextUsedIsland )
     {
       corner1 = bc3;
     }
     else if ( m_channelExpansionManager.islandForCorner( bc3 ) == nextUsedIsland )
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
     
     if ( m_channelExpansionManager.islandForCorner( btrackedc2 ) == nextUsedIsland )
     {
       corner2 = btrackedc3;
     }
     else if ( m_channelExpansionManager.islandForCorner( btrackedc3 ) == nextUsedIsland )
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

     if ( m_numAdvances == -1 || m_currentAdvances == m_numAdvances-1 )
     {
       baseMesh.O[corner1] = corner2;
       baseMesh.O[corner2] = corner1;
     
       if ( m_channelExpansionManager.triangleStripForCorner( corner1 ) == null )
       {
         if ( DEBUG && DEBUG_MODE >= LOW && (m_numAdvances != -1 ) )
         {
           print("Corners: " + corner1 + " " + corner2 + " Triangle strip for last added opposite: ");
           for (int i = 0; i < triangleStrip.size(); i++ )
           {
             print (triangleStrip.get(i) + " ");
           }
         }
         
         if ( corner1 == 64 || corner2 == 64 )
         {
           print("Corners: " + corner1 + " " + corner2 + " Triangle strip for last added opposite: ");
           for (int i = 0; i < triangleStrip.size(); i++ )
           {
             print (triangleStrip.get(i) + " ");
           }          
         }
         ChannelExpansionTriangleStrip channelExpansion = new ChannelExpansionTriangleStrip( triangleStrip );
         m_channelExpansionManager.setTriangleStrip( corner2, channelExpansion );
         m_channelExpansionManager.setTriangleStrip( corner1, channelExpansion.reverse() );
       }
       else
       {
         if ( DEBUG && DEBUG_MODE >= LOW && m_numAdvances != -1 )
         {
           print("Triangle strip has already been added");
         }
       }
       if ( DEBUG && DEBUG_MODE >= LOW && m_numAdvances != -1 )
       {
         print("\n");
       }

       if ( m_numAdvances != -1 )
       {
         baseMesh.cm[ corner1 ] = 2;
         baseMesh.cm[ corner2 ] = 2;
       }
     }
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
       } while ( (vertexNew = getNextVertexOnIslandIncludingLagoon( vertex, currentVertex, prevVertex, prevPrevVertex) ) != -1 ); //TODO msati3: Regress check this portion
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
   
 //Visualization operations
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
   if ( DEBUG && DEBUG_MODE >= LOW )
   {
     print("\nStats : Total " + nt + " Land " + countLand + " Good water " + countGood + " Island separators " + countSeparator + " Lagoons " + countLagoons + " Bad water " + countBad + "Num Water Verts " + numWaterVerts);
   }
     
   //TODO msati3: This is a hack. Should be made a separate function
   computeBaryCenterForIslands();
   calculateFinalLocationsForVertices();
   return new ColorResult(nt, countLand, countGood, countSeparator, countLagoons, countBad, numVerts, numWaterVerts, numNormalVerts);
 }
 
 //Morping location and barycenters calculations
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
 
 public void printStats()
 {
   m_islandExpansionManager.printStats();
 }
}
