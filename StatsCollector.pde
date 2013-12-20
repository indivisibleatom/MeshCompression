class WaterStats
{
  int maxWaterSize;
  int minWaterSize;
  float averageWaterSize;
  float pGreaterThanThree;
}

class ColorResult
{
  private int m_numTriangles;
  private int m_countLand;
  private int m_countStraits;
  private int m_countSeparators;
  private int m_countLagoons;
  private int m_countWater;
  private int m_totalVerts;
  private int m_waterVerts;
  private int m_normalVerts;
  
  ColorResult(int nt, int countLand, int countStraits, int countSeparators, int countLagoons, int countWater, int totalVerts, int waterVerts, int normalVerts)
  {
    m_numTriangles = nt;
    m_countLand = countLand;
    m_countStraits = countStraits;
    m_countSeparators = countSeparators;
    m_countLagoons = countLagoons;
    m_countWater = countWater;
    m_totalVerts = totalVerts;
    m_waterVerts = waterVerts;
    m_normalVerts = normalVerts;
  }
  
  int total() { return m_numTriangles; }
  int land() { return m_countLand; }
  int straits() { return m_countStraits; }
  int separators() { return m_countSeparators; }
  int lagoons() { return m_countLagoons; }
  int water() { return m_countWater; }
  int totalVerts() { return m_totalVerts; }
  int waterVerts() { return m_waterVerts; }
  int normalVerts() { return m_normalVerts; }

  float pLand() { return (float)m_countLand*100/m_numTriangles; }
  float pStraits() { return (float)m_countStraits*100/m_numTriangles; }
  float pSeparators() { return (float)m_countSeparators*100/m_numTriangles; }
  float pLagoons() { return (float)m_countLagoons*100/m_numTriangles; }
  float pWater() { return (float)m_countWater*100/m_numTriangles; }
  float pWaterVerts() { return (float)m_waterVerts*100/m_totalVerts; }
  float pNormalVerts() { return (float)m_normalVerts*100/m_totalVerts; }
}

class StatsCollector
{
  private PrintWriter output;
  private IslandMesh m_mesh;
  
  StatsCollector( IslandMesh mesh )
  {
    m_mesh = mesh;
    output = createWriter("stats.csv");
    output.println("Num vertices, Num water vertices, %Water vertices, Max channel size, Average channel size, % greater than size 3, num lagoon triangles, %lagoon triangles");
  }
  
  private void collectStats(int numTries, int islandSize)
  {
    for (int i = 0; i < numTries; i++)
    {
      ISLAND_SIZE = islandSize;
      int seed = (int)random(m_mesh.nt * 3);
      
      RingExpander expander = new RingExpander(m_mesh, seed); 
      RingExpanderResult result = expander.completeRingExpanderRecursive();
      m_mesh.setResult(result);
      m_mesh.showRingExpanderCorners();

      int numWater = 0;

      for (int j = 0; j < m_mesh.nt; j++)
      {
        if (m_mesh.tm[j] == WATER )
        {
          numWater++;
        }
      }
      
      m_mesh.formIslands(result.seed());
      ColorResult res = m_mesh.colorTriangles();

      /*output.println(ISLAND_SIZE + "," + numIslands + "," + res.total() + "," + numWater + "," + (float)numWater*100/res.total() + "," + res.land() + "," + res.pLand() + "," + res.water() + "," + res.pWater() + 
                     "," + res.straits() + "," + res.pStraits() + "," + res.lagoons() + "," + res.pLagoons() + "," + res.separators() + "," + res.pSeparators() + "," + res.totalVerts() + "," + res.normalVerts() + 
                     "," + res.pNormalVerts() + "," + res.waterVerts() + "," + res.pWaterVerts());*/
      WaterStats stats = collectWaterSize(islandSize);
      print("\n"+res.pLand()+"\n");
      //output.println(res.totalVerts() + "," + res.waterVerts() + "," + res.pWaterVerts() + "," + stats.maxWaterSize + "," + stats.averageWaterSize + "," + stats.pGreaterThanThree + "," + res.lagoons() + "," + res.pLagoons());
    }
  }
  
  boolean fCount = true;
  private int visitWater(int startCorner)
  {
    int count = 0;
    fCount = true;
    int initCorner = startCorner;
    Stack<Integer> stateStack = new Stack<Integer>();
    stateStack.push(startCorner);
    while (!stateStack.empty())   
    {
      startCorner = stateStack.pop();
      int currentCorner = m_mesh.o(startCorner);
      if (m_mesh.cm2[startCorner] == 0)
      {
        //if (m_mesh.tm[m_mesh.t(currentCorner)] == CHANNEL || m_mesh.tm[m_mesh.t(currentCorner)] == LAGOON)
        if (m_mesh.tm[m_mesh.t(currentCorner)] == CHANNEL || m_mesh.tm[m_mesh.t(currentCorner)] == LAGOON || m_mesh.tm[m_mesh.t(currentCorner)] == CAP)
        {
          stateStack.push(m_mesh.n(currentCorner));
          stateStack.push(m_mesh.p(currentCorner));
          m_mesh.cm2[startCorner] = 1;
          count++;
        }
        else if (m_mesh.tm[m_mesh.t(currentCorner)] == ISOLATEDWATER)
        {
          if (m_mesh.tm[m_mesh.t(initCorner)] == ISOLATEDWATER)
          {
            fCount = false;
          }
        }
      }
    }
    return count;
  }
  
  public WaterStats collectWaterSize(int islandSize)
  {
    WaterStats stats = new WaterStats();
    int maxWater = -1; 
    int minWater = 100;
    float average = 0;
    int numRecords = 0;
    float veryHigh = 0;
    float threshHold = 3;

    for (int i = 0; i < 3*m_mesh.nt; i++)
    {
      m_mesh.cm2[i] = 0;
    }
    
    for (int i = 0; i < m_mesh.nt; i++)
    {
      if ( m_mesh.tm[i] == JUNCTION || m_mesh.tm[i] == ISOLATEDWATER )
      {
        for (int j = 0; j < 3; j++)
        {
          int numWater = visitWater(3*i+j);
          if (fCount)
          {
            average += numWater;
            if (numWater > threshHold)
            {
              veryHigh++;
            }
            if (numWater > maxWater)
            {
              maxWater = numWater;
            }
            if (numWater < minWater)
            {
              minWater = numWater;
            }
            numRecords++;
          }
        }
      }
    }
    average /= numRecords;
    veryHigh /= numRecords;
    veryHigh *= 100;
    stats.maxWaterSize = maxWater;
    stats.minWaterSize = minWater;
    stats.averageWaterSize = average;
    stats.pGreaterThanThree = veryHigh;
    return stats;
  }
   
  public void done()
  {
    output.close();
  }
}
