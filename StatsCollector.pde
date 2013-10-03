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
    output.println("Num Triangles in Mesh\t Num triangles not on LR traversal\t Num water triangles after island formation\t Num triangles introduced by island formation\t Num Islands");
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
        if (m_mesh.tm[j] == waterColor )
        {
          numWater++;
        }
      }
      
      m_mesh.formIslands(result.seed());
      ColorResult res = m_mesh.colorTriangles();

      output.println(ISLAND_SIZE + "\t" + numIslands + "\t" + res.total() + "\t" + numWater + "\t" + (float)numWater*100/res.total() + "\t" + res.land() + "\t" + res.pLand() + "\t" + res.water() + "\t" + res.pWater() + 
                     "\t" + res.straits() + "\t" + res.pStraits() + "\t" + res.lagoons() + "\t" + res.pLagoons() + "\t" + res.separators() + "\t" + res.pSeparators() + "\t" + res.totalVerts() + "\t" + res.normalVerts() + 
                     "\t" + res.pNormalVerts() + "\t" + res.waterVerts() + "\t" + res.pWaterVerts());
    }
  }
  
  public void done()
  {
    output.close();
  }
}
