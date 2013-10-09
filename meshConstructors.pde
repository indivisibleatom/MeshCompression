class CuboidConstructor
{
  private int m_numRows;
  private int m_numCols;
  private float m_thickness;
  private float m_triangleSize;

  private IslandMesh m_mesh;
  
  public CuboidConstructor( int rows, int cols, float thickness, float triangleSize )
  {
    m_numRows = rows;
    m_numCols = cols;
    m_thickness = thickness;
    m_triangleSize = triangleSize;

    m_mesh = new IslandMesh();
    m_mesh.declareVectors();  
  }
  
  public void constructMesh()
  {
    for (int k = 0; k < 2; k++)
    {
      float z = getZForHeight( k );
      for (int i = 0; i < m_numRows; i++)
      {
        float y = getYForRow( i );
        for (int j = 0; j < m_numCols; j++)
        {
          float x = getXForCol( j );
          if ( DEBUG && DEBUG_MODE >= VERBOSE )
          {
            print("CuboidConstructor : Adding vertex " + x + " " + y + " " + z );
          }
          m_mesh.addVertex( new pt(x, y , z) );
        }
      }
    }
    
    //Triangulate the flat faces.
    for (int k = 0; k < 2; k++)
    {
      int initialOffset = k * ( m_numRows * m_numCols );
      for (int i = 0; i < m_numRows - 1; i++)
      {
        for (int j = 0; j < m_numCols - 1; j++)
        {
          if ( k == 0 )
          {
            m_mesh.addTriangle( initialOffset + m_numRows * i + j, initialOffset + m_numRows * i + j + 1, initialOffset + m_numRows * ( i + 1 ) + j );
            m_mesh.addTriangle( initialOffset + m_numRows * ( i + 1 ) + j + 1, initialOffset + m_numRows * ( i + 1 ) + j, initialOffset + m_numRows * i + j + 1 );
          }
          else
          {
            m_mesh.addTriangle( initialOffset + m_numRows * i + j + 1, initialOffset + m_numRows * i + j, initialOffset + m_numRows * ( i + 1 ) + j );
            m_mesh.addTriangle( initialOffset + m_numRows * ( i + 1 ) + j, initialOffset + m_numRows * ( i + 1 ) + j + 1, initialOffset + m_numRows * i + j + 1 );
          }
        }
      }
    }
    
    //Triangulate the sides.
    //Left and right
    for (int i = 0; i < m_numRows - 1; i++)
    {
      int initialOffsetBack = ( m_numRows * m_numCols );
      m_mesh.addTriangle( initialOffsetBack + m_numCols * i, m_numCols * i,  m_numCols * (i + 1) );
      m_mesh.addTriangle( m_numCols * (i + 1), initialOffsetBack + m_numCols * (i + 1), initialOffsetBack + m_numCols * i );
      
      m_mesh.addTriangle( m_numCols * i + m_numCols - 1, initialOffsetBack + m_numCols * i + m_numCols - 1, m_numCols * (i + 1) + m_numCols - 1 );
      m_mesh.addTriangle( initialOffsetBack + m_numCols * (i + 1) + m_numCols - 1, m_numCols * (i + 1) + m_numCols - 1, initialOffsetBack + m_numCols * i + m_numCols - 1 );
    }
    
    //Top and bottom
    for (int j = 0; j < m_numCols - 1; j++)
    {
      int initialOffsetBack = ( m_numRows * m_numCols );
      m_mesh.addTriangle( j, initialOffsetBack + j, initialOffsetBack + j + 1 );
      m_mesh.addTriangle( initialOffsetBack + j + 1, j + 1, j );
      
      int initialOffsetRow = ( (m_numRows - 1) * m_numCols );
      m_mesh.addTriangle( initialOffsetRow + initialOffsetBack + j, initialOffsetRow + j, initialOffsetRow + initialOffsetBack + j + 1 );
      m_mesh.addTriangle( initialOffsetRow + j + 1, initialOffsetRow + initialOffsetBack + j + 1, initialOffsetRow + j );
    }
       
    m_mesh.resetMarkers(); // resets vertex and tirangle markers
    m_mesh.updateON();
    
    //Flip around some edges
    
    /*for (int i = 1; i < m_numRows-2; i++)
    {
      for (int j = 1; j < m_numCols-2; j++)
      {
        int triangle1 = 2 * i * (m_numCols - 1) + 2 * j;
        int triangle2 = 2 * (m_numRows - 1) * (m_numCols - 1) + triangle1 + 1; 
        if ( random(5) <= 3 )
        {
          m_mesh.flip(triangle1*3);
        }
        if ( random(5) <= 3 )
        {
          m_mesh.flip(triangle2*3);
        }
      }
    }*/

    m_mesh.computeBox();
  }
  
  private float getXForCol( int col ) { return (-m_triangleSize * m_numCols / 2) + col * m_triangleSize; }
  private float getYForRow( int row ) { return (-m_triangleSize * m_numRows / 2) + row * m_triangleSize; }
  private float getZForHeight( int height ) {return - height * m_thickness; }
  
  public IslandMesh getMesh()
  {
    return m_mesh;
  }
};
