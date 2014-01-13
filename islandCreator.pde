class IslandCreator
{
  private IslandMesh m_mesh;
  private int m_seed; //Seed corner
  
  //Fifo of corners to visit
  Queue<Integer> m_cornerFifo;
 
  IslandCreator(IslandMesh m, int seed)
  {
    m_mesh = m;
    m_seed = seed;
    m_cornerFifo = new LinkedList<Integer>();
  }
  
  private int getValence(int corner)
  {
    int currentCorner = corner;
    int valence = 0;
    do 
    {
      valence++;
      currentCorner = m_mesh.s(currentCorner);
    } while ( currentCorner != corner );
    return valence;
  }
    
  private void printStats()
  {
    int numIsland = 0;
    int numChannel = 0;
    int numOthers = 0;
    
    //Print information about the valence of each vertex
    for (int i = 0; i < m_mesh.nv; i++)
    {
      m_mesh.vm[i] = 0;
    }

    float averageValence = 0;
    int maxValence = 0;
    int totalValence = 0;
    for (int i = 0; i < m_mesh.nc; i++)
    {
      if (m_mesh.vm[m_mesh.v(i)] == 0)
      {
        m_mesh.vm[m_mesh.v(i)] = 1;
        int valence = getValence(i);
        totalValence += valence;
        if ( valence > maxValence )
        {
          maxValence = valence;
        }
      }
    }
    averageValence = totalValence / m_mesh.nv;
    
    for (int i = 0; i < m_mesh.nt; i++)
    {
      switch (m_mesh.tm[i])
      {
        case 9: 
          numIsland++; 
          break;
        case 3: 
          numChannel++; 
          break;
        default: numOthers++; break;
      }      
    }
    if ( DEBUG && DEBUG_MODE >= LOW )
    {
      if ( m_mesh.nt - numIsland - numChannel != numOthers )
      {
        print("IslandCreator::printStats - Error!! Some other type of triangle exists as well!\n");
      }
    }
    print("Stats num triangles " + m_mesh.nt + " islands " + numIsland + " channels " + numChannel + " others " + numOthers + " average valence " + averageValence + " max valence " + maxValence + "\n");
  }
  
  private int retrySeed()
  {
    return (int)random(m_mesh.nt*3);
  }
  
  private boolean validTriangle(int corner)
  {
    int currentCorner = corner;
    do
    {
      if ( m_mesh.v(m_mesh.o(m_mesh.n(currentCorner))) == m_mesh.v(m_mesh.o(m_mesh.p(currentCorner))) )
      {
        return false;
      }
      if ( m_mesh.vm[m_mesh.v(currentCorner)] == 1 )
      {
        return false;
      }
      currentCorner = m_mesh.n(currentCorner);
    } while(currentCorner != corner);
    return true;
  }
  
  private void visitTriangle(int corner)
  {
    m_mesh.tm[m_mesh.t(corner)] = ISLAND;
    m_mesh.tm[m_mesh.t(m_mesh.o(corner))] = CHANNEL;
    m_mesh.tm[m_mesh.t(m_mesh.o(m_mesh.n(corner)))] = CHANNEL;
    m_mesh.tm[m_mesh.t(m_mesh.o(m_mesh.p(corner)))] = CHANNEL;
    
    m_mesh.vm[m_mesh.v(corner)] = 1;
    m_mesh.vm[m_mesh.v(m_mesh.n(corner))] = 1;
    m_mesh.vm[m_mesh.v(m_mesh.p(corner))] = 1;
  }
  
  private int findNewPossibles(int corner, int []possibles)
  {
    int numPossibles = 0;
    int currentCorner = corner;
    do
    {
      int possibleCorner = m_mesh.o(m_mesh.s(m_mesh.s(m_mesh.s(currentCorner))));
      if (validTriangle(possibleCorner))
      {
        possibles[numPossibles++] = possibleCorner;
      }
      currentCorner = m_mesh.n(currentCorner);
    } while(currentCorner != corner);
    return numPossibles;
  }
   
  private void addPossiblesToFifo(int[] possibles, int numPossibles)
  {
    for (int i = 0; i < numPossibles; i++)
    {
      m_cornerFifo.add(possibles[i]);
    }
  }
 
  private void internalCreateIslandsPass1()
  {
    int[] newPossibles = new int[3];
    int numPossibles;
    Integer corner;
    while ((corner = m_cornerFifo.poll()) != null)
    {
      if (validTriangle(corner)) //Check for validity at time of processing, as in between time of addition to fifo and processing, this might be changed
      {
        visitTriangle(corner);
        numPossibles = findNewPossibles(corner, newPossibles);
        addPossiblesToFifo(newPossibles, numPossibles);
      }
    }
    if ( DEBUG && DEBUG_MODE >= LOW )
    {
      printStats();
    }
  }
  
  private void internalCreateIslandsPass2()
  {
    /*for (int i = 0; i < m_mesh.nt; i++)
    {
      if (canCreateIsland(i))
      {
        visitTriangle(m_mesh.c(i));
      }
    }*/
  }
  
  void createIslands()
  {
    while ( !validTriangle(m_seed) )
    {
      m_seed = retrySeed();
    }
    print("Seed for creation of islands " + m_seed + "\n");
    m_seed = 127;
    m_cornerFifo.add(m_seed);
    internalCreateIslandsPass1();
    internalCreateIslandsPass2();
    
     //Clear all vertex markers
     for (int i = 0; i < m_mesh.nv; i++)
     {
       m_mesh.vm[i] = 0;
     }
  }
}
