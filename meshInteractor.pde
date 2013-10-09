//Allows for selecting a particular mesh being displayed and performing operations on it
class MeshInteractor
{
  private ArrayList<Mesh> m_meshes;
  private int m_selectedMesh;
  
  MeshInteractor()
  {
    m_meshes = new ArrayList<Mesh>();
    m_selectedMesh = -1;
  } 
  
  int addMesh(Mesh m)
  {
    m_meshes.add(m);
    if ( m_selectedMesh == -1 )
    {
      m_selectedMesh = 0;
    }
    return m_meshes.size();
  }
  
  void removeMesh(Mesh m)
  {
    boolean fRemoved = m_meshes.remove(m);
    if ( !fRemoved )
    {
      if (DEBUG && DEBUG_MODE >= LOW)
      {
        print("MeshInteractor::removeMesh - can't find mesh to be unregistered!");
      }
    }
    else if (m_meshes.size() == 0)
    {
      m_selectedMesh = -1;
    }
  }

  void selectMesh(int meshIndex)
  {
    if (meshIndex >= m_meshes.size() && meshIndex >= 0)
    {
      if (DEBUG && DEBUG_MODE >= LOW)
      {
        print ("MeshInteractor::selectMesh - Error trying to select incorrect mesh. Current number of meshes is " + m_meshes.size()+"\n");
      }
      if ( m_meshes.size() > 0 ) 
      {
        selectMesh(m_meshes.size()-1); 
      }
      else
      {
        if (DEBUG && DEBUG_MODE >= LOW)
        {
          print ("MeshInteractor::selectMesh - Current meshlist is empty. Returning without selecting a mesh");
        }
        return;
      }
    }
    m_selectedMesh = meshIndex;
  }

  int getSelectedMeshIndex()
  {
    return m_selectedMesh;
  }

  Mesh getSelectedMesh()
  {
    if (m_selectedMesh == -1)
    {
      return null;
    }
    return m_meshes.get(m_selectedMesh);
  } 
  
  void drawRegisteredMeshes()
  {
    for (int i = 0; i < m_meshes.size(); i++)
    {
      m_meshes.get(i).draw();
    }
  }
}
