int ISLAND_SIZE = 5;
int waterColor = 8;
int landColor = 9;
int breakerColor = 7;

int numTriangle = 0;

int numTrianglesInIsland = 0;
int lastLength = 0;
int numIslands = 1;

class VisitState
{
  private int m_corner;
  
  public VisitState(int corner)
  {
    m_corner = corner;
  }
  
  public int corner()
  {
    return m_corner;
  }
}

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
    fill(255, 0, 0);
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
      m_mesh.showCorner(corner, 3);
      setColor(corner);
      //label(corner);

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
      m_mesh.tm[i] = waterColor;
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
    m_mesh.tm[tri] = waterColor;
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
    shoreVerts[0] = m_mesh.v(m_mesh.n(corner));
    shoreVerts[1] = m_mesh.v(m_mesh.p(corner));
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

  //Utilities to determine leaf, single Parent, etc
  private int getNumSuccessors(int corner)
  {
    int numSucL = 0;
    int numSucR = 0;
    if (isValidChild(m_mesh.r(corner), corner) && m_mesh.tm[m_mesh.t(m_mesh.r(corner))] != waterColor)
    {
      numSucR = getNumSuccessors(m_mesh.r(corner));
    }
    if (isValidChild(m_mesh.l(corner), corner) && m_mesh.tm[m_mesh.t(m_mesh.l(corner))] != waterColor)
    {
      numSucL = getNumSuccessors(m_mesh.l(corner));
    }
    return numSucL + numSucR + 1;
  }
  
  private int getNumChild(int corner)
  {
    int numChild = 0;
    if (isValidChild(m_mesh.r(corner), corner) && m_mesh.tm[m_mesh.t(m_mesh.r(corner))] != waterColor)
      numChild++;
    if (isValidChild(m_mesh.l(corner), corner) && m_mesh.tm[m_mesh.t(m_mesh.l(corner))] != waterColor)
      numChild++;
    return numChild;
  }

  private boolean isLeaf(int corner)
  {
    return (getNumChild(corner) == 0);
  }

  private boolean isSingleParent(int corner)
  {
    return (getNumChild(corner) == 1);
  }

  private int getChild(int corner)
  {
    if (isValidChild(m_mesh.l(corner), corner) && m_mesh.tm[m_mesh.t(m_mesh.l(corner))] != waterColor)
      return m_mesh.l(corner);
    if (isValidChild(m_mesh.r(corner), corner) && m_mesh.tm[m_mesh.t(m_mesh.r(corner))] != waterColor)
      return m_mesh.r(corner);
    return -1;
  }
  
  private void markVisited(int triangle)
  {
    m_mesh.island[m_mesh.v(m_mesh.c(triangle))] = numIslands;
    m_mesh.island[m_mesh.v(m_mesh.n(m_mesh.c(triangle)))] = numIslands;
    m_mesh.island[m_mesh.v(m_mesh.p(m_mesh.c(triangle)))] = numIslands;
  }
  
  private void unmarkVisited(int triangle)
  {
    m_mesh.island[m_mesh.v(m_mesh.c(triangle))] = -1;
    m_mesh.island[m_mesh.v(m_mesh.n(m_mesh.c(triangle)))] = -1;
    m_mesh.island[m_mesh.v(m_mesh.p(m_mesh.c(triangle)))] = -1;
  }

  //Perform an actual submerge from a corner, the number of triangles to submerge and the bitString -- the path to follow for the submersion
  private int performSubmerge(int corner, int numToSubmerge, Stack<Integer> bitString)
  {
    if (isLeaf(corner))
    {
      unmarkVisited(m_mesh.t(corner));
      markSubmerged(m_mesh.t(corner));
      if (numToSubmerge == 1)
      {
        return -1;
      }
      else
      {
        return 1;
      }
    }
    else if (isSingleParent(corner))
    {
      int numSubmerged = performSubmerge(getChild(corner), numToSubmerge, bitString);
      if (numSubmerged > numToSubmerge)
      {
        return numSubmerged;
      }
      else if (numSubmerged == -1)
      {
        return -1;
      }
      else if (numSubmerged+1 == numToSubmerge)
      {
        unmarkVisited(m_mesh.t(corner));
        markSubmerged(m_mesh.t(corner));
        return -1;
      }
      else
      {
        unmarkVisited(m_mesh.t(corner));
        markSubmerged(m_mesh.t(corner));
        return numSubmerged + 1;
      }
    }
    else
    {
      int popped = bitString.pop();
      if (popped == 1)
      {
        int numSubmerged = performSubmerge(m_mesh.l(corner), numToSubmerge, bitString);
        if (DEBUG && DEBUG_MODE >= LOW)
        {
          if (numSubmerged < numToSubmerge && numSubmerged != -1)
          {
            print("Fatal bug in submersion! Should not happen!!");
          }
        }
        return -1;
      }
      else if (popped == -1)
      {
        int numSubmerged = performSubmerge(m_mesh.r(corner), numToSubmerge, bitString);
        if (DEBUG && DEBUG_MODE >= LOW)
        {
          if (numSubmerged < numToSubmerge && numSubmerged != -1)
          {
            print("Fatal bug in submersion! Should not happen!!");
          }
        }
        return -1;
      }
      else 
      {
        int numL = performSubmerge(m_mesh.l(corner), numToSubmerge, bitString);
        int numR = performSubmerge(m_mesh.r(corner), numToSubmerge, bitString);
        unmarkVisited(m_mesh.t(corner));
        markSubmerged(m_mesh.t(corner));
        if  (numL + numR + 1 >= numToSubmerge)
        {
          return -1;
        }
        else
        {
          return numL + numR + 1;
        }
      }
    }
  }

  private int trySubmerge(int corner, int numToSubmerge, Stack<Integer> bitString)
  {
    if (isLeaf(corner))
    {
      if (numToSubmerge == 1)
      {
        return -1;
      }
      else
      {
        return 1;
      }
    }
    else if (isSingleParent(corner))
    {
      int numSubmerged = trySubmerge(getChild(corner), numToSubmerge, bitString);
      if (numSubmerged > numToSubmerge)
      {
        return numSubmerged;
      }
      else if (numSubmerged == -1 || numSubmerged+1 == numToSubmerge)
      {
        return -1;
      }
      else
      {
        return numSubmerged + 1;
      }
    }
    else
    {
      Stack<Integer> lStack = new Stack<Integer>();
      Stack<Integer> rStack = new Stack<Integer>();

      int numL = trySubmerge(m_mesh.l(corner), numToSubmerge, lStack);
      int numR = trySubmerge(m_mesh.r(corner), numToSubmerge, rStack);
      if (numL == -1)
      {
        combine(bitString, lStack);
        bitString.push(1);
        return -1;
      }
      else if (numR == -1)
      {
        combine(bitString, rStack);
        bitString.push(-1);
        return -1;
      }
      else if (numL > numToSubmerge || numR > numToSubmerge)
      {
        if (numL > numToSubmerge && numR > numToSubmerge)
        {
          if (numL < numR)
          {
            combine(bitString, lStack);
            bitString.push(1);
          }
          else
          {
            combine(bitString, rStack);
            bitString.push(-1);
          }
          return ((numL < numR) ? numL : numR);
        }
        else if (numL > numToSubmerge)
        {
          combine(bitString, lStack);
          bitString.push(1);
          return numL;
        }
        else
        {
          combine(bitString, rStack);
          bitString.push(-1);
          return numR;
        }
      }
      else
      {
        combine(bitString, rStack);
        combine(bitString, lStack);
        bitString.push(0);
        if (numL + numR + 1 == numToSubmerge)
        {
          return -1;
        }
        else
        {
          return numL + numR + 1;
        }
      }
    }
  }

  private void combine(Stack<Integer> mainStack, Stack<Integer> otherStack)
  {
    Stack<Integer> temp = new Stack();
    for (int i = 0; i < otherStack.size(); i++)
    {
      temp.push(otherStack.pop());
    }
    for (int i = 0; i < temp.size(); i++)
    {
      mainStack.push(temp.pop());
    }
  }
  
  //TODO msati3: Use the visitor pattern??
  private void submergeAll(int corner)
  {
    if (isValidChild(m_mesh.r(corner), corner) && m_mesh.tm[m_mesh.t(m_mesh.r(corner))] != waterColor)
    {
      submergeAll(m_mesh.r(corner));
    }
    if (isValidChild(m_mesh.l(corner), corner) && m_mesh.tm[m_mesh.t(m_mesh.l(corner))] != waterColor)
    {
      submergeAll(m_mesh.l(corner));
    }
    markSubmerged(m_mesh.t(corner));
  }
  
  private void submergeOther(int corner, int[] shoreVerts)
  {
    if (!hasVertices(m_mesh.t(corner), shoreVerts))
    {
      if (getNumSuccessors(corner) < ISLAND_SIZE)
      {
        submergeAll(corner);
      }
    }
    else
    {
      if (isValidChild(m_mesh.r(corner), corner) && m_mesh.tm[m_mesh.t(m_mesh.r(corner))] != waterColor)
      {
        submergeOther(m_mesh.r(corner), shoreVerts);
      }
      if (isValidChild(m_mesh.l(corner), corner) && m_mesh.tm[m_mesh.t(m_mesh.l(corner))] != waterColor)
      {
        submergeOther(m_mesh.l(corner), shoreVerts);
      }
      markSubmerged(m_mesh.t(corner));
    }
  }

  private int formIslesAndGetLength(int corner, int[] shoreVerts)
  {
    int[] shoreVertsR = new int[2];
    int[] shoreVertsL = new int[2];
    int lenR = 0;
    int lenL = 0;

    if (isValidChild(m_mesh.r(corner), corner))
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
            numIslands++;
            markVisited(m_mesh.t(corner));
            return 1;
          }
        }
        else
        {
          int[] shoreVertsNeg = rNeg? shoreVertsR : shoreVertsL; 
          int other = rNeg? m_mesh.l(corner) : m_mesh.r(corner);
          if (hasVertices(m_mesh.t(corner), shoreVertsNeg))
          {
            submergeOther(other, shoreVertsNeg);
            mergeShoreVertices(m_mesh.t(corner), shoreVertsR, shoreVertsL, shoreVerts);
            markSubmerged(m_mesh.t(corner));
            return -1;
          }
          else
          {
            int lOther = rNeg? lenL : lenR;
            if (lOther+1 == ISLAND_SIZE)
            {
              markVisited(m_mesh.t(corner));
              markAsBeach(corner, shoreVerts);
              return -1;
            }
            else
            {
              markVisited(m_mesh.t(corner));
              return lOther + 1;
            }
          }
        }
      }
      else
      {
        if (lenR + lenL >= ISLAND_SIZE)
        {
          //Check for possible submersions possible in left branch and right branch recursively
          Stack<Integer> bitStringL = new Stack<Integer>();
          Stack<Integer> bitStringR = new Stack<Integer>();
          int numTrianglesToSubmerge = lenR + lenL - (ISLAND_SIZE - 1);
          int numL = trySubmerge(m_mesh.l(corner), numTrianglesToSubmerge, bitStringL);
          int numR = trySubmerge(m_mesh.r(corner), numTrianglesToSubmerge, bitStringR);

          //Actually perform the submersion using the bitstring as a guide. TODO msati3: Can the bitstring be removed?
          if (numL == -1)
          {
            performSubmerge(m_mesh.l(corner), numTrianglesToSubmerge, bitStringL);
            markVisited(m_mesh.t(corner));
            markAsBeach(corner, shoreVerts);
            return -1;
          }
          else if (numR == -1)
          {
            performSubmerge(m_mesh.r(corner), numTrianglesToSubmerge, bitStringR);
            markVisited(m_mesh.t(corner));
            markAsBeach(corner, shoreVerts);
            return -1;
          }
          else if (numL > numTrianglesToSubmerge || numR > numTrianglesToSubmerge)
          {
            //Select to submerge the side that leads to lesser submersions
            if (numL < numR)
            {
              performSubmerge(m_mesh.l(corner), numTrianglesToSubmerge, bitStringL);
              markVisited(m_mesh.t(corner));
              int numTrianglesLeft = lenR + lenL + 1 - numL;
              return numTrianglesLeft;
            }
            else
            {
              performSubmerge(m_mesh.r(corner), numTrianglesToSubmerge, bitStringR);
              markVisited(m_mesh.t(corner));
              int numTrianglesLeft = lenR + lenL + 1 - numR;
              return numTrianglesLeft;
            }
          }
          else //extremely bad case. Submerge the entire island :O..can't be helped.
          {
            performSubmerge(m_mesh.l(corner), numTrianglesToSubmerge, bitStringL);
            performSubmerge(m_mesh.l(corner), numTrianglesToSubmerge, bitStringR);
            markSubmerged(m_mesh.t(corner));
            shoreVerts[0] = -1;
            shoreVerts[1] = -1;
            return -1;
          }
        }
        else
        {
          if (lenR + lenL + 1 == ISLAND_SIZE)
          {
            markVisited(m_mesh.t(corner));
            markAsBeach(corner, shoreVerts);
            return -1;
          }
          markVisited(m_mesh.t(corner));
          return lenR + lenL + 1;
        }
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
          markSubmerged(m_mesh.t(corner));
          propagateShoreVertices(m_mesh.t(corner), shoreVertsChild, shoreVerts);
          return -1;
        }
        else
        {
          numIslands++;
          markVisited(m_mesh.t(corner));
          return 1;
        }
      }
      else
      {
        if (lenChild + 1 == ISLAND_SIZE)
        {
          markVisited(m_mesh.t(corner));
          markAsBeach(corner, shoreVerts);
          int cnr = m_mesh.o(corner);
          //print("The shore vertices are " + shoreVerts[0] + " " + shoreVerts[1] + ". The parent vertices are " + m_mesh.v(cnr) + " " + m_mesh.v(m_mesh.n(cnr)) + "  " + m_mesh.v(m_mesh.p(cnr)) + "\n");
          //DEBUG
          if (getCornerOnLR(m_mesh.t(m_mesh.cc)) == m_mesh.t(cnr))
          {
            //print("The shore vertices are " + shoreVerts[0] + " " + shoreVerts[1] + ". The parent vertices are " + m_mesh.v(cnr) + " " + m_mesh.v(m_mesh.n(cnr)) + "  " + m_mesh.v(m_mesh.p(cnr)) + "\n");
          }
          return -1;
        }
        else
        {
          markVisited(m_mesh.t(corner));
          return lenChild + 1;
        }
      }
    }
    else
    {
      markVisited(m_mesh.t(corner));
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
  
  private boolean isBreakerTriangle(int triangle)
  {
    int v1 = m_mesh.v(m_mesh.c(triangle));
    int v2 = m_mesh.v(m_mesh.n(m_mesh.c(triangle)));
    int v3 = m_mesh.v(m_mesh.p(m_mesh.c(triangle)));

    if (m_mesh.island[v1] != -1 && m_mesh.island[v2] != -1 && m_mesh.island[v3] != -1)
    {
      if ((m_mesh.island[v1] != m_mesh.island[v2]) && (m_mesh.island[v1] != m_mesh.island[v3]) && (m_mesh.island[v2] != m_mesh.island[v3]))
      {
        return true;
      }
    }
    return false;
  }
  
  private void colorBreakerTriangles()
  {
    for (int i = 0; i < m_mesh.nt; i++)
    {
      if (isBreakerTriangle(i))
      {
        m_mesh.tm[i] = breakerColor;
      }
    }
  }

  public void formIslands()
  {
    //init
    int[] shoreVertices = {
      -1, -1
    };
    int cornerToStart = getCornerOnLR(m_mesh.cc);
    if (cornerToStart == -1)
      return ;  
    m_mesh.cc = cornerToStart;
    numIslands = 0;
    for (int i = 0; i < m_mesh.island.length; i++)
    {
      m_mesh.island[i] = -1;
    }
    

    int length = formIslesAndGetLength(cornerToStart, shoreVertices);
    numIslands++;
    colorBreakerTriangles();
    
    if (length != lastLength)
    {    
      lastLength = length;
      print("The selected corner for starting is " + m_mesh.cc);
      print("The length of the last island is " + length);
      print("Number of islands is " + numIslands);
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

