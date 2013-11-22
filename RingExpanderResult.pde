int ISLAND_SIZE = 40;
int MAX_ISLANDS = 40000;
int VERTICES_PER_ISLAND = ISLAND_SIZE + 2;

int numIslands = 0; //TODO msati3: Move this inside islandMesh
StepWiseRingExpander g_stepWiseRingExpander = new StepWiseRingExpander();

class SubmersionCounter
{
  private int m_numSubmersions;
  private int m_badSubmersions;
  
  public SubmersionCounter()
  {
    m_numSubmersions = 0;
    m_badSubmersions = 0;
  }
  
  public void incSubmersion()
  {
    m_numSubmersions++;
  }
  
  public void incBadSubmersion()
  {
    m_badSubmersions++;
    m_numSubmersions++;
  }
  
  public int numSubmersions()
  {
    return m_numSubmersions;
  }
  
  public int numBadSubmersions()
  {
    return m_badSubmersions;
  }
}

SubmersionCounter g_submersionCounter;

class StepWiseRingExpander
{
  private int m_lastLength;
  private boolean m_stepMode;
  
  StepWiseRingExpander()
  {
    m_lastLength = 0;
    m_stepMode = false;
  }
  
  void updateStep()
  {
    m_lastLength++;
  }
  
  public void setStepMode(boolean fStepMode)
  {
    m_stepMode = fStepMode;
  }
  
  public void setLastLength(int lastLength)
  {
    m_lastLength = lastLength;
  } 
  
  public boolean fStepMode()
  {
    return m_stepMode;
  }
  
  public int lastLength()
  {
    return m_lastLength;
  }
}


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

class SubmersionState
{
  private int m_corner;
  private int m_numToSubmerge;
  private Stack<Integer> m_bitString;
  private boolean m_fFirstState;
  private int m_LR;
  private int m_numChild;

  public SubmersionState(int corner, int numToSubmerge, Stack<Integer> bitString, int LR, boolean fFirst)
  {
    m_corner = corner;
    m_numToSubmerge = numToSubmerge;
    m_bitString = bitString;
    m_fFirstState = fFirst;
    m_LR = LR;
    m_numChild = 0;
  }

  public void setFirstState(boolean fFirstState) { m_fFirstState = fFirstState; }
  public void setLR(int LR) { m_LR = LR; }
  public void setNumChild(int numChild) { m_numChild = numChild; }
  public int numChild() { return m_numChild; }
  public int LR() { return m_LR; }
  public int corner() { return m_corner; }
  public int numToSubmerge() { return m_numToSubmerge; }
  public Stack<Integer> bitString() { return m_bitString; }
  public boolean fFirstState() { return m_fFirstState; }
}

class SubmersionStateTry
{
  private int m_corner;
  private int m_numToSubmerge;
  private Stack<Integer> m_bitString;
  private boolean m_fFirstState;
  private int m_result;
  private SubmersionStateTry m_leftChild;
  private SubmersionStateTry m_rightChild;

  public SubmersionStateTry(int corner, int numToSubmerge, Stack<Integer> bitString, boolean fFirst)
  {
    m_corner = corner;
    m_numToSubmerge = numToSubmerge;
    m_bitString = bitString;
    m_fFirstState = fFirst;
    m_result = -1;
    m_leftChild = null;
    m_rightChild = null;
  }

  public void setFirstState(boolean fFirstState) { m_fFirstState = fFirstState; }
  public void setChildren(SubmersionStateTry left, SubmersionStateTry right) { m_leftChild = left; m_rightChild = right; }
  public void setResult(int result) { m_result = result; }
  public void setBitString(Stack<Integer> bitString) { m_bitString = bitString; }
  public int corner() { return m_corner; }
  public int numToSubmerge() { return m_numToSubmerge; }
  public Stack<Integer> bitString() { return m_bitString; }
  public boolean fFirstState() { return m_fFirstState; }
  public SubmersionStateTry left() { return m_leftChild; }
  public SubmersionStateTry right() { return m_rightChild; }
  public int result() { return m_result; }
}

class FormIslandsState
{
  private int m_corner;
  private int m_result;
  private boolean m_fFirstState;
  private int[] m_shoreVertices;
  private FormIslandsState m_leftChild;
  private FormIslandsState m_rightChild;

  public FormIslandsState(int corner, int[] shoreVertices)
  {
    m_corner = corner;
    m_shoreVertices = shoreVertices;
    m_result = -1;
    m_fFirstState = true;
    m_leftChild = null;
    m_rightChild = null;
  }  

  public void setFirstState(boolean fFirstState) { m_fFirstState = fFirstState; }
  public void setChildren(FormIslandsState left, FormIslandsState right) { m_leftChild = left; m_rightChild = right; }
  public void setResult(int result) { m_result = result; }
  public int corner() { return m_corner; }
  public int[] shoreVerts() { return m_shoreVertices; }
  public boolean fFirstState() { return m_fFirstState; }
  public FormIslandsState left() { return m_leftChild; }
  public FormIslandsState right() { return m_rightChild; }
  public int result() { return m_result; }
}

class RingExpanderResult
{
  private int m_seed;
  private int[] m_parentTArray;
  private int m_numTrianglesToColor;
  private int m_numTrianglesColored;
  private Stack<VisitState> m_visitStack;

  IslandMesh m_mesh;

  public RingExpanderResult(IslandMesh m, int seed, int[] parentTrianglesArray)
  {
    m_seed = seed;
    m_parentTArray = parentTrianglesArray;
    m_mesh = m;
    m_numTrianglesToColor = -1;
  }

  private void setColor(int corner)
  {
    m_mesh.tm[m_mesh.t(corner)] = ISLAND;
  }

  private boolean isValidChild(int childCorner, int parentCorner)
  {
    if ( (m_mesh.hasValidR(parentCorner) && childCorner == m_mesh.r(parentCorner)) || (m_mesh.hasValidL(parentCorner) && childCorner == m_mesh.l(parentCorner)) )
    {
      if (m_parentTArray[childCorner] == m_mesh.t(parentCorner))
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

  private void visitAndColor()
  {
    for (int i = 0; i < m_mesh.nt * 3; i++)
    {
      m_mesh.cm[i] = 0;
    }

    while ((m_numTrianglesToColor == -1 || m_numTrianglesColored < m_numTrianglesToColor) && !m_visitStack.empty())
    {
      VisitState currentState = m_visitStack.pop();
      int corner = currentState.corner();
      m_numTrianglesColored++;
      setColor(corner);

      if (isValidChild(m_mesh.l(corner), corner))
      {
        m_visitStack.push(new VisitState(m_mesh.l(corner)));
      }
      if (isValidChild(m_mesh.r(corner), corner))
      {
        m_visitStack.push(new VisitState(m_mesh.r(corner)));
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
      m_mesh.tm[i] = WATER;
    }

    m_numTrianglesColored = 0;
  }

  private int getCornerOnLR(int anyCorner)
  {
    int tri = m_mesh.t(anyCorner);
    int corner = m_mesh.c(tri);
    if (tri == m_mesh.t(m_seed))
    {
      return m_seed;
    }
    for (int i = 0; i < 3; i++)
    {
      if (m_mesh.t(m_mesh.o(corner)) == m_parentTArray[corner])
      {
        return corner;
      }
      corner = m_mesh.n(corner);
    }

    return -1;
  }
  
  private boolean isOnLR(int corner)
  {
    int cornerOnLR = getCornerOnLR(corner);
    return (cornerOnLR == corner);
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
      if (!isOnLR(cornerInit))
      {
        shoreVerts[index++] = v1;
      }
    }
    if (v2 == vertsR[0] || v2 == vertsR[1] || v2 == vertsL[0] || v2 == vertsL[1])
    {
      if (!isOnLR(m_mesh.n(cornerInit)))
      {
        shoreVerts[index++] = v2;
      }
    }
    if (v3 == vertsR[0] || v3 == vertsR[1] || v3 == vertsL[0] || v3 == vertsL[1])
    {
      if (!isOnLR(m_mesh.p(cornerInit)))
      {
        shoreVerts[index++] = v3;
      }
    }

    while (index != 2)
    {
      shoreVerts[index++] = -1;
    }
    if ( DEBUG && DEBUG_MODE >= VERBOSE )
    {
      print("Merged shoreVertices " + shoreVerts[0] + " " + shoreVerts[1]);
    }
  }

  private void markSubmerged(int tri)
  {
    markUnVisited(tri);    
    m_mesh.tm[tri] = WATER;
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
    numberIslands(corner, numIslands++);
    m_mesh.tm[m_mesh.t(corner)] = 4;
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
     if (!isOnLR(cornerInit))
     {
        shoreVerts[index++] = v1;
     }
    }
    if (v2 == vertsChild[0] || v2 == vertsChild[1])
    {
      if (!isOnLR(m_mesh.n(cornerInit)))
      {
        shoreVerts[index++] = v2;
      }
    }
    if (v3 == vertsChild[0] || v3 == vertsChild[1])
    {
      if (!isOnLR(m_mesh.p(cornerInit)))
      {
        shoreVerts[index++] = v3;
      }
    }

    while (index != 2)
    {
      shoreVerts[index++] = -1;
    }
  }

  //Utilities to determine leaf, single Parent, etc
  private int getNumSuccessors(int corner)
  {
    int numSuc = 0;

    Stack<VisitState> succStack = new Stack<VisitState>();
    succStack.push(new VisitState(corner));

    while (!succStack.empty())
    {
      corner = succStack.pop().corner();
      if (isValidChild(m_mesh.r(corner), corner) && m_mesh.tm[m_mesh.t(m_mesh.r(corner))] != WATER)
      {
        succStack.push(new VisitState(m_mesh.r(corner)));
        numSuc++;
      }
      if (isValidChild(m_mesh.l(corner), corner) && m_mesh.tm[m_mesh.t(m_mesh.l(corner))] != WATER)
      {
        succStack.push(new VisitState(m_mesh.l(corner)));
        numSuc++;
      }
    }
    return numSuc;
  }

  private int getNumChild(int corner)
  {
    int numChild = 0;
    if (isValidChild(m_mesh.r(corner), corner) && m_mesh.tm[m_mesh.t(m_mesh.r(corner))] != WATER)
    {
      numChild++;
    }
    if (isValidChild(m_mesh.l(corner), corner) && m_mesh.tm[m_mesh.t(m_mesh.l(corner))] != WATER)
    {
      numChild++;
    }
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
    if (isValidChild(m_mesh.l(corner), corner) && m_mesh.tm[m_mesh.t(m_mesh.l(corner))] != WATER)
    {
      return m_mesh.l(corner);
    }
    if (isValidChild(m_mesh.r(corner), corner) && m_mesh.tm[m_mesh.t(m_mesh.r(corner))] != WATER)
    {
      return m_mesh.r(corner);
    } 
    return -1;
  }

  private void markVisited(int triangle, int islandNumber)
  {
    m_mesh.triangleIsland[triangle] =  islandNumber;
    m_mesh.island[m_mesh.c(triangle)] = islandNumber;
    m_mesh.island[m_mesh.n(m_mesh.c(triangle))] = islandNumber;
    m_mesh.island[m_mesh.p(m_mesh.c(triangle))] = islandNumber;
    markCorner(m_mesh.c(triangle), islandNumber); markCorner(m_mesh.n(m_mesh.c(triangle)), islandNumber); markCorner(m_mesh.p(m_mesh.c(triangle)), islandNumber);
  }
  
  private void markUnVisited(int triangle)
  {
    m_mesh.triangleIsland[triangle] = -1;
    m_mesh.island[m_mesh.c(triangle)] = -1;
    m_mesh.island[m_mesh.n(m_mesh.c(triangle))] = -1;
    m_mesh.island[m_mesh.p(m_mesh.c(triangle))] = -1;
    unmarkCorner(m_mesh.c(triangle)); unmarkCorner(m_mesh.n(m_mesh.c(triangle))); unmarkCorner(m_mesh.p(m_mesh.c(triangle)));
  }
  
  private void markCorner( int corner, int islandNumber )
  {
    m_mesh.cm[corner] = 100+islandNumber;
  }
  
  private void unmarkCorner( int corner )
  {
    m_mesh.cm[corner] = 0;
  }

  //Perform an actual submerge from a corner, the number of triangles to submerge and the bitString -- the path to follow for the submersion
  private int performSubmerge(int corner, int numToSubmerge, Stack<Integer> origBitString)
  {
    Stack<SubmersionState> submergeStack = new Stack<SubmersionState>();
    submergeStack.push(new SubmersionState(corner, numToSubmerge, origBitString, 0, true));
    int retVal = 0;
    //print ("Num to submerge " + numToSubmerge);
    int countTwo = 0;
    
    while (!submergeStack.empty())
    {
      SubmersionState cur = submergeStack.pop();
      corner = cur.corner(); numToSubmerge = cur.numToSubmerge(); Stack<Integer> bitString = cur.bitString();
      
      if (cur.fFirstState())
      {
          if (isLeaf(corner))
          {
            cur.setNumChild(0);
            cur.setFirstState(false);
            submergeStack.push(cur);
            markSubmerged(m_mesh.t(corner));
            if (numToSubmerge == 1)
            {
              retVal = -1;
            }
            else
            {
              retVal++;
            }
          }
          else if (isSingleParent(corner))
          {
            cur.setNumChild(1);
            cur.setFirstState(false);
            submergeStack.push(cur);
            submergeStack.push(new SubmersionState(getChild(corner), numToSubmerge, bitString, 0, true));
          }
          else
          {
            countTwo++;
            int popped = -1;
            popped = bitString.pop();
            cur.setNumChild(2);
            cur.setFirstState(false);
            cur.setLR(popped);
            submergeStack.push(cur);
            if (popped == 1)
            {
              submergeStack.push(new SubmersionState(m_mesh.l(corner), numToSubmerge, bitString, 0, true));
            }
            else if (popped == -1)
            {
              submergeStack.push(new SubmersionState(m_mesh.r(corner), numToSubmerge, bitString, 0, true));
            }
            else
            {
               submergeStack.push(new SubmersionState(m_mesh.r(corner), numToSubmerge, bitString, 0, true));
               submergeStack.push(new SubmersionState(m_mesh.l(corner), numToSubmerge, bitString, 0, true));
            }
          }
          continue;
        }
        else //fFirstState
        {
            if (cur.numChild() == 0)
            {
            }
            else if (cur.numChild() == 1)
            {
              if (retVal > numToSubmerge)
              {
              }
              else if (retVal == -1)
              {
                retVal = -1;
              }
              else if (retVal+1 == numToSubmerge)
              {
                markSubmerged(m_mesh.t(corner));
                retVal = -1;
              }
              else
              {
                markSubmerged(m_mesh.t(corner));
                retVal++;
              }
           }
           else //!leaf and !singleParent
           {
             int popped = cur.LR();
             if (popped == 1)
             {
                if (DEBUG && DEBUG_MODE >= LOW)
                {
                  if (retVal < numToSubmerge && retVal != -1)
                  {
                    print("Fatal bug in submersion! Should not happen!!" + retVal);
                  }
                }
                retVal = -1;
             }
             else if (popped == -1)
             {
               if (DEBUG && DEBUG_MODE >= LOW)
               {
                 if (retVal < numToSubmerge && retVal != -1)
                 {
                   print("Fatal bug in submersion! Should not happen!!" + retVal);
                 }
               }
               retVal = -1;
            }
            else
            {
              if (retVal == -1)
              {
               //Case when l + r sum to total num submerged
              }
              else if (retVal + 1 == numToSubmerge)
              {
                markSubmerged(m_mesh.t(corner));
                retVal = -1;
              }
              else
              {
                markSubmerged(m_mesh.t(corner));
                retVal++;
              }
            }
          }
        }//fFirstState
      }//while
      return retVal;
  }//code

  private int trySubmerge(int corner, int numToSubmerge, Stack<Integer> bitString)
  {
    Stack<SubmersionStateTry> submergeStack = new Stack<SubmersionStateTry>();
    submergeStack.push(new SubmersionStateTry(corner, numToSubmerge, bitString, true));
    int finalRet = -1;
    
    while (!submergeStack.empty())
    {
      SubmersionStateTry cur = submergeStack.pop();
      corner = cur.corner(); numToSubmerge = cur.numToSubmerge(); bitString = cur.bitString();
      
      if (cur.fFirstState())
      {
        if (isLeaf(corner))
        {
          if (numToSubmerge == 1)
          {
            cur.setResult(-1);
          }
          else
          {
            cur.setResult(1);
          }
        }
        else if (isSingleParent(corner))
        {
          SubmersionStateTry childState = new SubmersionStateTry(getChild(corner), numToSubmerge, bitString, true);
          cur.setFirstState(false);
          cur.setChildren(childState, null);
          submergeStack.push(cur);          
          submergeStack.push(childState);
        }
        else
        {
          Stack<Integer> lStack = new Stack<Integer>();
          Stack<Integer> rStack = new Stack<Integer>();
          SubmersionStateTry lChild = new SubmersionStateTry(m_mesh.l(corner), numToSubmerge, lStack, true);
          SubmersionStateTry rChild = new SubmersionStateTry(m_mesh.r(corner), numToSubmerge, rStack, true);
          cur.setFirstState(false);
          cur.setChildren(lChild, rChild);
          submergeStack.push(cur);
          submergeStack.push(lChild);
          submergeStack.push(rChild);
        }
        continue;
      }       
      else //firstState
      {
        if (isLeaf(corner))
        {
        }
        else if (isSingleParent(corner))
        { 
          int result = cur.left().result();
          Stack<Integer> lStack = cur.left().bitString();
          if (result > numToSubmerge)
          {
          }
          else if (result == -1 || result+1 == numToSubmerge)
          {
            result = -1;
          }
          else
          {
            result++;
          }
          cur.setBitString(lStack);
          cur.setResult(result);
        }
        else
        {
          int numL = cur.left().result();
          int numR = cur.right().result();
          Stack<Integer> lStack = cur.left().bitString();
          Stack<Integer> rStack = cur.right().bitString();
        
            /*print ("\nrStack ");
            for (int i = 0; i < rStack.size(); i++)
            {
              print(rStack.get(i) + " ");
            }
            print ("\nlStack ");
            for (int i = 0; i < lStack.size(); i++)
            {
              print(lStack.get(i) + " ");
            }*/

          if (numL == -1)
          {
            combine(bitString, lStack);
            bitString.push(1);
            cur.setResult(-1);
          }
          else if (numR == -1)
          {
            combine(bitString, rStack);
            bitString.push(-1);
            cur.setResult(-1);
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
              cur.setResult(((numL < numR) ? numL : numR));
            }
            else if (numL > numToSubmerge)
            {
              combine(bitString, lStack);
              bitString.push(1);
              cur.setResult(numL);
            }
            else
            {
              combine(bitString, rStack);
              bitString.push(-1);
              cur.setResult(numR);
            }
          }
          else
          {
            combine(bitString, rStack);
            combine(bitString, lStack);
            bitString.push(0);
 
            if (numL + numR + 1 == numToSubmerge)
            {
              cur.setResult(-1);
            }
            else if (numL + numR == numToSubmerge)
            {
              cur.setResult(-1);
            }
            else
            {
              cur.setResult(numL + numR + 1);
            }
          }

          /*print("\nBitString ");
          for (int i = 0; i < bitString.size(); i++)
          {
            print(bitString.get(i) + " ");
          }*/
        }
      } //if stage 2
      bitString = cur.bitString();
      finalRet = cur.result();
    } //while !stackEmpty
    return finalRet;
  }

  private void combine(Stack<Integer> mainStack, Stack<Integer> otherStack)
  {
    Stack<Integer> temp = new Stack<Integer>();
    while(!otherStack.empty())
    {
      temp.push(otherStack.pop());
    }
    while(!temp.empty())
    {
      mainStack.push(temp.pop());
    }
  }
  
  private void submergeAll(int corner)
  {
    Stack<Integer> submergeStack = new Stack<Integer>();
    submergeStack.push(corner);

    while (!submergeStack.empty())
    {
      corner = submergeStack.pop();
      if (isValidChild(m_mesh.r(corner), corner) && m_mesh.tm[m_mesh.t(m_mesh.r(corner))] != WATER)
      {
        submergeStack.push(m_mesh.r(corner));
      }
      if (isValidChild(m_mesh.l(corner), corner) && m_mesh.tm[m_mesh.t(m_mesh.l(corner))] != WATER)
      {
        submergeStack.push(m_mesh.l(corner));
      }
      markSubmerged(m_mesh.t(corner));
    }
  }
  
  private void submergeOther(int corner, int[] shoreVerts, boolean fCompleteSubmerge)
  {
    Stack<Integer> submergeStack = new Stack<Integer>();
    submergeStack.push(corner);
    boolean fBeachheadReached = false;
    
    while (!submergeStack.empty())
    {
      corner = submergeStack.pop();
      if (fCompleteSubmerge && !fBeachheadReached)
      {
        if (m_mesh.tm[m_mesh.t(corner)] != WATER)
        {
          fBeachheadReached = true;
        }
      }

      if (!hasVertices(m_mesh.t(corner), shoreVerts))
      {
        int numSucc = getNumSuccessors(corner); //There case be the case where this is an island - in this case (fCompleteSubmerge = false), we submerge as desired.
                                                //The other two cases are the current corner was a beachHead or the current corner was a water that is being submerged. For both cases, we are good (for second case, getNumSucc returns -1) and we leave the 
                                                //remaining unsubmerged. For the first case, getNumSuccessors returns ISLAND_SIZE - 1
        if ( numSucc + 1 < ISLAND_SIZE )
        {
          if ( fCompleteSubmerge )
          {
            if ( fBeachheadReached )
            {
              numIslands--;
              if ( DEBUG && DEBUG_MODE >= LOW )
              {
                print("Special config: calling renumber with " + numIslands + " " + m_mesh.island[corner] + "at corner " + corner + "\n");
              }
              renumberIslands(m_mesh.island[corner]);
            }
            else
            {
              if ( DEBUG && DEBUG_MODE >= LOW )
              {
                print("Special config: not expected to happen!! with " + numIslands + " " + m_mesh.island[corner] + "at corner " + corner + "\n");
              }
            }
          }
          submergeAll(corner);
        }
      }
      else
      {
        if ( fCompleteSubmerge && !fBeachheadReached )
        {
          if (isValidChild(m_mesh.r(corner), corner) && isValidChild(m_mesh.l(corner), corner))
          {
            if (DEBUG && DEBUG_MODE >= LOW)
            {
              print("RingExpanderResult::submergeOther - very special case -- could be buggy. Marking for warnings when encountered");
            }
          }
          if (isValidChild(m_mesh.r(corner), corner))
          {
            submergeStack.push(m_mesh.r(corner));
          }
          if (isValidChild(m_mesh.l(corner), corner))
          {
            submergeStack.push(m_mesh.l(corner));
          }
        }
        else
        {
          if (isValidChild(m_mesh.r(corner), corner) && m_mesh.tm[m_mesh.t(m_mesh.r(corner))] != WATER)
          {
            submergeStack.push(m_mesh.r(corner));
          }
          if (isValidChild(m_mesh.l(corner), corner) && m_mesh.tm[m_mesh.t(m_mesh.l(corner))] != WATER)
          {
            submergeStack.push(m_mesh.l(corner));
          }
          markSubmerged(m_mesh.t(corner));
        }
      }
    }
  }

  private int formIslesAndGetLength(int corner, int[] origShoreVerts)
  {
    numIslands = 0;
    Stack<FormIslandsState> formIslesStack = new Stack<FormIslandsState>();
    formIslesStack.push(new FormIslandsState(corner, origShoreVerts));
    int finalRet = -1;

    while (!formIslesStack.empty())
    {
      FormIslandsState cur = formIslesStack.pop();
      corner = cur.corner(); 
      int[] curShoreVerts = cur.shoreVerts();

      if (cur.fFirstState())
      {
        FormIslandsState rightChild = null;
        FormIslandsState leftChild = null;

        if (isValidChild(m_mesh.r(corner), corner))
        {
          rightChild = new FormIslandsState(m_mesh.r(corner), new int[2]);
        }
        if (isValidChild(m_mesh.l(corner), corner))
        {
          leftChild = new FormIslandsState(m_mesh.l(corner), new int[2]);
        }

        cur.setChildren(leftChild, rightChild);
        cur.setFirstState(false);
        formIslesStack.push(cur);

        if (rightChild != null)
        {
          formIslesStack.push(rightChild);
        }
        if (leftChild != null)
        {
          formIslesStack.push(leftChild);
        }
        continue;
      }
      else
      {
        int lenL = 0;
        int lenR = 0;
        int[] shoreVertsR = null;
        int[] shoreVertsL = null;

        if (cur.left() != null)
        {
          lenL = cur.left().result();
          shoreVertsL = cur.left().shoreVerts();
        }
        if (cur.right() != null)
        {
          lenR = cur.right().result();
          shoreVertsR = cur.right().shoreVerts();          
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
                if ( DEBUG && DEBUG_MODE >= HIGH )
                {
                  print("Here " + m_mesh.v(corner) + " " + shoreVertsR[0] + " " + shoreVertsR[1] + " " + shoreVertsL[0] + " " + shoreVertsL[1] );
                }
                m_mesh.cc = corner;
                if (hasVertices(m_mesh.t(corner), shoreVertsR) && hasVertices(m_mesh.t(corner), shoreVertsL))
                {
                  //This may be the case, when we have just formed an island one the left and right subtrees and are checking for triangles to submerge e
                  //This may be the case when we are propagating our submersion vertices, after having formed an island, to come to an isolated vertex. In that case
                  //we decrease the number of islands and submerge one of the islands
                  print("Doing a complete submersion start at " + corner + " in direction " + m_mesh.l(corner));
                  submergeOther(m_mesh.l(corner), shoreVertsR, true/*fCompleteSubmerge*/);
                }
                mergeShoreVertices(m_mesh.t(corner), shoreVertsR, shoreVertsL, curShoreVerts);
                markSubmerged(m_mesh.t(corner));
                cur.setResult(-1);
              }
              else
              {
                cur.setResult(1);
              }
            }
            else
            {
              int[] shoreVertsNeg = rNeg? shoreVertsR : shoreVertsL; 
              int other = rNeg? m_mesh.l(corner) : m_mesh.r(corner);
              if (hasVertices(m_mesh.t(corner), shoreVertsNeg))
              {
                submergeOther(other, shoreVertsNeg, false/*fCompleteSubmerge*/);
                mergeShoreVertices(m_mesh.t(corner), shoreVertsR, shoreVertsL, curShoreVerts);
                markSubmerged(m_mesh.t(corner));
                cur.setResult(-1);
              }
              else
              {
                int lOther = rNeg? lenL : lenR;
                if (lOther+1 == ISLAND_SIZE)
                {
                  markAsBeach(corner, curShoreVerts);
                  cur.setResult(-1);
                }
                else
                {
                  cur.setResult(lOther + 1);
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
              /*print("Final data and bitString " + lenR + " " + lenL + " " + numL + " " + numR);
              for (int i = 0; i < bitStringL.size(); i++)
              {
                print (" " + bitStringL.get(i) + " ");
              }*/

              //Actually perform the submersion using the bitstring as a guide. TODO msati3: Can the bitstring be removed?
              if (numL == -1)
              {
                performSubmerge(m_mesh.l(corner), numTrianglesToSubmerge, bitStringL);
                markAsBeach(corner, curShoreVerts);
                cur.setResult(-1);
              }
              else if (numR == -1)
              {
                performSubmerge(m_mesh.r(corner), numTrianglesToSubmerge, bitStringR);
                markAsBeach(corner, curShoreVerts);
                cur.setResult(-1);
              }
              else if (numL > numTrianglesToSubmerge || numR > numTrianglesToSubmerge)
              {
                //Select to submerge the side that leads to lesser submersions
                if (numL < numR)
                {
                  performSubmerge(m_mesh.l(corner), numTrianglesToSubmerge, bitStringL);
                  int numTrianglesLeft = lenR + lenL + 1 - numL;
                  cur.setResult(numTrianglesLeft);
                }
                else
                {
                  performSubmerge(m_mesh.r(corner), numTrianglesToSubmerge, bitStringR);
                  int numTrianglesLeft = lenR + lenL + 1 - numR;
                  cur.setResult(numTrianglesLeft);
                }
                g_submersionCounter.incSubmersion();
              }
              else //extremely bad case. Submerge the entire island :O..can't be helped.
              {
                if ( DEBUG && DEBUG_MODE >= HIGH )
                {
                  print("Here as well");
                }
                performSubmerge(m_mesh.l(corner), numTrianglesToSubmerge, bitStringL);
                performSubmerge(m_mesh.l(corner), numTrianglesToSubmerge, bitStringR);
                markSubmerged(m_mesh.t(corner));
                curShoreVerts[0] = -1;
                curShoreVerts[1] = -1;
                cur.setResult(-1);
                g_submersionCounter.incBadSubmersion();
              }
            }
            else
            {
              if (lenR + lenL + 1 == ISLAND_SIZE)
              {
                markAsBeach(corner, curShoreVerts);
                cur.setResult(-1);
              }
              else
              {
                cur.setResult(lenR + lenL + 1);
              }
            }
          }
        }
        else if (lenR == 0 && lenL == 0)
        {
          cur.setResult(1); //Leaf
        }
        else
        {
          int lenChild = (lenR == 0) ? lenL : lenR;
          int[] shoreVertsChild = (lenR == 0)? shoreVertsL : shoreVertsR; 
          if (lenChild == -1)
          {
            if (hasVertices(m_mesh.t(corner), shoreVertsChild))
            {
              markSubmerged(m_mesh.t(corner));
              propagateShoreVertices(m_mesh.t(corner), shoreVertsChild, curShoreVerts);
              cur.setResult(-1);
            }
            else
            {
              cur.setResult(1);
            }
          }
          else
          {
            if (lenChild + 1 == ISLAND_SIZE)
            {
              markAsBeach(corner, curShoreVerts);
              int cnr = m_mesh.o(corner);
              //print("The shore vertices are " + shoreVerts[0] + " " + shoreVerts[1] + ". The parent vertices are " + m_mesh.v(cnr) + " " + m_mesh.v(m_mesh.n(cnr)) + "  " + m_mesh.v(m_mesh.p(cnr)) + "\n");
              //DEBUG
              if (getCornerOnLR(m_mesh.t(m_mesh.cc)) == m_mesh.t(cnr))
              {
                //print("The shore vertices are " + shoreVerts[0] + " " + shoreVerts[1] + ". The parent vertices are " + m_mesh.v(cnr) + " " + m_mesh.v(m_mesh.n(cnr)) + "  " + m_mesh.v(m_mesh.p(cnr)) + "\n");
              }
              cur.setResult(-1);
            }
            else
            {
              cur.setResult(lenChild + 1);
            }
          }
        }        
      }//if !state.fFirst
      finalRet = cur.result();
    }//while !stack.empty
    return finalRet;
  }//function    
  
  private void numberIslands(int corner, int islandNumber)
  {
    Stack<Integer> markStack = new Stack<Integer>();
    markStack.push(corner);
    int count = 0;
    char ch1, ch2, ch = 0;

    while (!markStack.empty())
    {
      ch1 = 0; ch2 = 0; ch = 0;
      corner = markStack.pop();
      if (isValidChild(m_mesh.r(corner), corner) && m_mesh.tm[m_mesh.t(m_mesh.r(corner))] != WATER)
      {
        markStack.push(m_mesh.r(corner));
      }
      if (isValidChild(m_mesh.l(corner), corner) && m_mesh.tm[m_mesh.t(m_mesh.l(corner))] != WATER)
      {
        markStack.push(m_mesh.l(corner));
      }

      markVisited(m_mesh.t(corner), islandNumber);
    }
  }
  
  private void renumberIslands(int islandNumber)
  {
    if (islandNumber == -1)
    {
      if ( DEBUG && DEBUG_MODE >= LOW )
      {
        print("RingExpanderResult::renumberIsland - supplying -1 as islandNumber. Bug!");
      }
      return;
    }
    for (int i = 0; i < m_mesh.nt; i++)
    {
      if ( m_mesh.island[3*i] > islandNumber )
      {
        markVisited(i, m_mesh.island[3*i]-1);
      }
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
    m_visitStack = new Stack<VisitState>();
    m_visitStack.push(new VisitState(m_seed));
    visitAndColor();
    m_mesh.tm[m_mesh.t(m_seed)] = 3;
  }

  public void colorRingExpander()
  {
    resetState();
    m_numTrianglesToColor = -1;
    m_visitStack = new Stack<VisitState>();
    m_visitStack.push(new VisitState(m_seed));
    visitAndColor();
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
  
  public void formIslands(int cornerToStart)
  {
    //init
    int[] shoreVertices = {
      -1, -1
    };
    if (cornerToStart != -1)
    {
      m_mesh.cc = cornerToStart;
    }
    cornerToStart = m_mesh.cc;

    cornerToStart = getCornerOnLR(cornerToStart);
    if (cornerToStart == -1)
    {
      if (DEBUG && DEBUG_MODE >= LOW)
      {
        print("Correct corner not found. Returning");
      }
      return ;  
    }
    
    for (int i = 0; i < 3 * m_mesh.nt; i++)
    {
      m_mesh.island[i] = -1;
    }
    for (int i = 0; i < m_mesh.nt; i++)
    {
      m_mesh.triangleIsland[i] = -1;
    }

    g_submersionCounter = new SubmersionCounter();
    int length = formIslesAndGetLength(cornerToStart, shoreVertices);
    numIslands++;

    if (g_stepWiseRingExpander.fStepMode())
    {
      if (length != g_stepWiseRingExpander.lastLength())
      { 
        g_stepWiseRingExpander.setLastLength(length);
        if (length < ISLAND_SIZE && length != -1)
        {
          numIslands--;
          submergeAll(cornerToStart);
          g_submersionCounter.incBadSubmersion();
        }
      }
    }
    else
    {
      if (length < ISLAND_SIZE && length != -1)
      {
        submergeAll(cornerToStart);
        g_submersionCounter.incBadSubmersion();
      }
       numIslands--;
    }

    print("\nThe selected corner for starting is " + cornerToStart);
    print("The length of the last island is " + length);
    print("Number of islands is " + numIslands);
    print("Number of submersions " + g_submersionCounter.numSubmersions() + " number of bad submersions " + g_submersionCounter.numBadSubmersions());
  }
  
  public int seed()
  {
    return m_seed;
  }
}

