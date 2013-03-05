int ISLAND_SIZE = 5;

int numTrianglesInIsland = 0;
int lastLength = 0;

class RingExpanderResult
{
  private int m_seed;
  private int[] m_parentTArray;
  private int m_numTrianglesToColor;
  private int m_numTrianglesColored;
  Mesh m_mesh;
  
  public RingExpanderResult(Mesh m, int seed, int[] vertexArray)
  {
    m_seed = seed;
    m_parentTArray = vertexArray;
    m_mesh = m;
    m_numTrianglesToColor = -1;
  }
  
  private void setColor(int corner)
  {
    m_mesh.tm[m_mesh.t(corner)] = 9;
  }

  private boolean isValidChild(int childCorner, int parentCorner)
  {
    if ( (m_mesh.hasValidR(parentCorner) && childCorner == m_mesh.r(parentCorner)) || (m_mesh.hasValidL(parentCorner) && childCorner == m_mesh.l(parentCorner)) )
    {
      if (m_parentTArray[m_mesh.v(childCorner)] == m_mesh.t(parentCorner))
      {
        return true;
      }
    }
    return false;
  }
  
  private void label(int corner)
  {
    fill(255,0,0);
    pt vtx = m_mesh.G[m_mesh.v(corner)];
    translate(vtx.x, vtx.y, vtx.z);
      sphere(3);
    translate(-vtx.x, -vtx.y, -vtx.z);
  }
  
  private void visitAndColor(int corner)
  {
    if ((m_numTrianglesToColor == -1 || m_numTrianglesColored < m_numTrianglesToColor))
    {
      m_numTrianglesColored++;
      setColor(corner);
      label(corner);
      
      if (isValidChild(m_mesh.r(corner), corner))
      {
        visitAndColor(m_mesh.r(corner));
      }
      if (isValidChild(m_mesh.l(corner), corner))
      {
        visitAndColor(m_mesh.l(corner));
      }
    }
  }
  
  private void resetState()
  {
    if (m_numTrianglesToColor == -1)
    {
      m_numTrianglesToColor = 0;
    }

    for (int i = 0; i < m_mesh.nt; i++)
    {
      m_mesh.tm[i] = 8;
    }
    
    m_numTrianglesColored = 0;
  }
  
  private int getCornerOnLR(int anyCorner)
  {
    int tri = m_mesh.t(anyCorner);
    int corner = m_mesh.c(tri);
    for (int i = 0; i < 3; i++)
    {
      if (m_mesh.t(m_mesh.o(corner)) == m_parentTArray[m_mesh.v(corner)])
      {
        return corner;
      }
      corner = m_mesh.n(corner);
    }
    
    return -1;
  }
  
  private void mergeShoreVertices(int tri, int[] vertsR, int[] vertsL, int[] shoreVerts)
  {
    int cornerInit = m_mesh.c(tri);
    int v1 = m_mesh.v(cornerInit);
    int v2 = m_mesh.v(m_mesh.n(cornerInit));
    int v3 = m_mesh.v(m_mesh.p(cornerInit));
    
    int index = 0;
    
    if (v1 == vertsR[0] || v1 == vertsR[1] || v1 == vertsL[0] || v1 == vertsL[1])
    {
      shoreVerts[index++] = v1;
    }
    if (v2 == vertsR[0] || v2 == vertsR[1] || v2 == vertsL[0] || v2 == vertsL[1])
    {
      shoreVerts[index++] = v2;
    }
    if (v3 == vertsR[0] || v3 == vertsR[1] || v3 == vertsL[0] || v3 == vertsL[1])
    {
      shoreVerts[index++] = v3;
    }

    while (index != 2)
    {
      shoreVerts[index++] = -1;
    }
  }
  
  private void markSubmerged(int tri)
  {
    m_mesh.tm[tri] = 8;
  }

  private boolean hasVertices(int tri, int[] shoreVerts)
  {
    int cornerInit = m_mesh.c(tri);
    int v1 = m_mesh.v(cornerInit);
    int v2 = m_mesh.v(m_mesh.n(cornerInit));
    int v3 = m_mesh.v(m_mesh.p(cornerInit));
    
    if (v1 == shoreVerts[0] || v1 == shoreVerts[1])
    {
      return true;
    }
    if (v2 == shoreVerts[0] || v2 == shoreVerts[1])
    {
      return true;
    }
    if (v3 == shoreVerts[0] || v3 == shoreVerts[1])
    {
      return true;
    }

    return false;
  }
  
  private void markAsBeach(int corner, int[] shoreVerts)
  {
    shoreVerts[0] = m_mesh.n(corner);
    shoreVerts[1] = m_mesh.p(corner);
  }
  
  private void propagateShoreVertices(int tri, int[] vertsChild, int[] shoreVerts)
  {
    int cornerInit = m_mesh.c(tri);
    int v1 = m_mesh.v(cornerInit);
    int v2 = m_mesh.v(m_mesh.n(cornerInit));
    int v3 = m_mesh.v(m_mesh.p(cornerInit));

    int index = 0;

    if (v1 == vertsChild[0] || v1 == vertsChild[1])
    {
      shoreVerts[index++] = v1;
    }
    if (v2 == vertsChild[0] || v2 == vertsChild[1])
    {
      shoreVerts[index++] = v2;
    }
    if (v3 == vertsChild[0] || v3 == vertsChild[1])
    {
      shoreVerts[index++] = v3;
    }

    while (index != 2)
    {
      shoreVerts[index++] = -1;
    }
  }

  private int formIslesAndGetLength(int corner, int[] shoreVerts)
  {
    int[] shoreVertsR = new int[2];
    int[] shoreVertsL = new int[2];
    int lenR = 0;
    int lenL = 0;

    if (isValidChild(m_mesh.r(corner),corner))
    {
      lenR = formIslesAndGetLength(m_mesh.r(corner), shoreVertsR);
    }
    if (isValidChild(m_mesh.l(corner), corner))
    {
      lenL = formIslesAndGetLength(m_mesh.l(corner), shoreVertsL);
    }

    if (lenR != 0 && lenL != 0)
    {
      boolean rNeg = (lenR == -1);
      boolean lNeg = (lenL == -1);
      if (rNeg || lNeg)
      {
        if (rNeg && lNeg)
        {
          if (hasVertices(m_mesh.t(corner), shoreVertsR) || hasVertices(m_mesh.t(corner), shoreVertsL))
          {
            mergeShoreVertices(m_mesh.t(corner), shoreVertsR, shoreVertsL, shoreVerts);
            markSubmerged(m_mesh.t(corner));
            return -1;
          }
          else
          {
            return 1;
          }
        }
        else
        {
          int[] shoreVertsNeg = rNeg? shoreVertsR : shoreVertsL; 
          if (hasVertices(m_mesh.t(corner), shoreVertsNeg))
          {
            //submergeOther(shoreVertsNeg); //TODO msati3: Implement
            mergeShoreVertices(m_mesh.t(corner), shoreVertsR, shoreVerts, shoreVerts);
            markSubmerged(m_mesh.t(corner));
            return -1;
          }
          else
          {
            int lOther = rNeg? lenL : lenR;
            if (lOther+1 == ISLAND_SIZE)
            {
              markAsBeach(corner, shoreVerts);
              return -1;
            }
            else
            {
              return lOther + 1;
            }
          }
        }
      }
      else
      {
        //TODO msati3: implement this
        return lenR + lenL + 1;
      }
    }
    else if (lenR == 0 || lenL == 0)
    {
      int lenChild = (lenR == 0) ? lenL : lenR;
      int[] shoreVertsChild = (lenR == 0)? shoreVertsL : shoreVertsR; 
      if (lenChild == -1)
      {
        if (hasVertices(m_mesh.t(corner), shoreVertsChild))
        {
          propagateShoreVertices(m_mesh.t(corner), shoreVertsChild, shoreVerts);
          return -1;
        }
        else
        {
          return 1;
        }
      }
      else
      {
        if (lenChild + 1 == ISLAND_SIZE)
        {
          markAsBeach(m_mesh.t(corner), shoreVerts);
          return -1;
        }
        else
        {
          return lenChild + 1;
        }
      }
    }
    else
    {
      return 1; //Leaf
    }
  }
  
  private int getLength(int corner)
  {
    int rightLen = 0;
    int leftLen = 0;
    if (isValidChild(m_mesh.r(corner), corner))
    {
      rightLen = getLength(m_mesh.r(corner));
    }
    if (isValidChild(m_mesh.l(corner), corner))
    {
      leftLen = getLength(m_mesh.l(corner));
    }

    return rightLen + leftLen + 1;    
  }
  
  public void advanceStep()
  {
    if (m_numTrianglesToColor != -1)
    {
      m_numTrianglesToColor++;
    }
  }
  
  public void stepColorRingExpander()
  {
    resetState();
    visitAndColor(m_seed);
    m_mesh.tm[m_mesh.t(m_seed)] = 1;
  }
  
  public void colorRingExpander()
  {
    resetState();
    m_numTrianglesToColor = -1;
    visitAndColor(m_seed);
    m_mesh.tm[m_mesh.t(m_seed)] = 3;
  }
  
  public void formIslands()
  {
    int[] shoreVertices = {-1,-1};
    int cornerToStart = getCornerOnLR(m_mesh.cc);
    if (cornerToStart == -1)
      return ;
    int length = formIslesAndGetLength(cornerToStart, shoreVertices);
    if (length != lastLength)
    {    
      lastLength = length;
      print("The length of the last island is " + length);
    }
  }
  
  public void queryLength()
  {
    int newNumTriangles = getLength(m_mesh.cc);
    if (numTrianglesInIsland != newNumTriangles)
    {
      numTrianglesInIsland = newNumTriangles;
      print("The number of children is " + numTrianglesInIsland);
    }
  }
}
