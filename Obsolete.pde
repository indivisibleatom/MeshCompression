/*   ColorResult colorTrianglesOld()
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
       if (waterIncident(i))
       {
         if ((isVertexForCornerWaterVertex(corner) && island2 != -1 && island3 != -1 && island2 == island3) ||
             (isVertexForCornerWaterVertex(n(corner)) && island1 != -1 && island3 != -1 && island1 == island3) ||
             (isVertexForCornerWaterVertex(p(corner)) && island1 != -1 && island2 != -1 && island1 == island2))
         {
           tm[i] = 7;
         }
         else
         {
           countBad++;
           tm[i] = 4;
         }
       }
       else if (island[corner] != -1 && island[n(corner)] != -1 && island[p(corner)] != -1 && island1 == island2 && island1 == island3)
       {
         countLand++;
         tm[i] = ISLAND;
       }
       else if (island1 != -1 && island2 != -1 && island3 != -1 && island1 != island2 && island1 != island3 && island2 != island3)
       {
         countSeparator++;
         tm[i] = 6;
       }
       else if (island1 != -1 && island2 != -1 && island3 != -1 && island1 == island2 || island1 == island3 || island2 == island3)
       {
         if (island1 == island2 && island1 == island3)
         {
           countLagoons++;
           tm[i] = 5;
         }
         else
         {
           if (hasBeachEdge(i))
           {
             countGood++;
             tm[i] = 3;
           }
           else if (island1 == island2 && island1 == island3)
           {
             tm[i] = 1;
           }
           else
           {
             tm[i] = 2;
           }
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
     print("\nStats : Total " + nt + " Land " + countLand + " Good water " + countGood + " Island separators " + countSeparator + " Lagoons " + countLagoons + " Bad water " + countBad + "Num Water Verts " + numWaterVerts);
     
     //TODO msati3: This is a hack. Should be made a separate function
     computeBaryCenterForIslands();
     calculateFinalLocationsForVertices();
     return new ColorResult(nt, countLand, countGood, countSeparator, countLagoons, countBad, numVerts, numWaterVerts, numNormalVerts);
   }
*/
