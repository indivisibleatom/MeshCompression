class StatsCollector
{
  private PrintWriter output;
  
  StatsCollector()
  {
    output = createWriter("stats.csv");
    output.println("Num Triangles in Mesh\t Num triangles not on LR traversal\t Num water triangles after island formation\t Num triangles introduced by island formation\t Num Islands");
  }
  
  private void collectStats(int numTries, int islandSize)
  {
    for (int i = 0; i < numTries; i++)
    {
      ISLAND_SIZE = islandSize;
      int seed = (int)random(M.nt * 3);
      
      RingExpander expander = new RingExpander(M, seed); 
      RingExpanderResult result = expander.completeRingExpanderRecursive();
      M.setResult(result);
      M.showRingExpanderCorners();

      int numWater = 0;
      for (int j = 0; j < M.nt; j++)
      {
        if (M.tm[j] == waterColor )
        {
          numWater++;
        }
      }
      
      M.formIslands(result.seed());
      int numWaterAfterIslands = 0;
      for (int j = 0; j < M.nt; j++)
      {
        if (M.tm[j] == waterColor )
        {
          numWaterAfterIslands++;
        }
      }
      
      output.println(M.nt + "\t" + numWater + "\t" + numWaterAfterIslands + "\t" + (numWaterAfterIslands - numWater) + "\t" +numIslands);
    }
  }
  
  public void done()
  {
    output.close();
  }
}
