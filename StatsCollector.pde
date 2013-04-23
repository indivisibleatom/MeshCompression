class ColorResult
{
  private int m_numTriangles;
  private int m_countLand;
  private int m_countStraits;
  private int m_countSeparators;
  private int m_countLagoons;
  private int m_countWater;
  
  ColorResult(int nt, int countLand, int countStraits, int countSeparators, int countLagoons, int countWater)
  {
    m_numTriangles = nt;
    m_countLand = countLand;
    m_countStraits = countStraits;
    m_countSeparators = countSeparators;
    m_countLagoons = countLagoons;
    m_countWater = countWater;
  }
  
  int total() { return m_numTriangles; }
  int land() { return m_countLand; }
  int straits() { return m_countStraits; }
  int separators() { return m_countSeparators; }
  int lagoons() { return m_countLagoons; }
  int water() { return m_countWater; }

  float pLand() { return (float)m_countLand*100/m_numTriangles; }
  float pStraits() { return (float)m_countStraits*100/m_numTriangles; }
  float pSeparators() { return (float)m_countSeparators*100/m_numTriangles; }
  float pLagoons() { return (float)m_countLagoons*100/m_numTriangles; }
  float pWater() { return (float)m_countWater*100/m_numTriangles; }
}

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
      ColorResult res = M.colorTriangles();

      output.println(ISLAND_SIZE + "\t" + numIslands + "\t" + res.total() + "\t" + numWater + "\t" + (float)numWater*100/res.total() + "\t" + res.land() + "\t" + res.pLand() + "\t" + res.water() + "\t" + res.pWater() + 
                     "\t" + res.straits() + "\t" + res.pStraits() + "\t" + res.lagoons() + "\t" + res.pLagoons() + "\t" + res.separators() + "\t" + res.pSeparators());
    }
  }
  
  public void done()
  {
    output.close();
  }
}
