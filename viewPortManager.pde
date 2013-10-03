class ViewportManager
{
  private ArrayList<Viewport> m_viewports;
  private int m_selectedViewport;
  private boolean m_fShowingFullScreen;

  ViewportManager()
  {
    m_selectedViewport = -1;
    m_viewports = new ArrayList<Viewport>();
    m_fShowingFullScreen = false;
  }
  
  void addViewport( Viewport v )
  {
    m_viewports.add( v );
    if ( m_selectedViewport == -1 )
    {
      selectViewport( 0 );
    }
  }
  
  void selectViewport( int index )
  {
    if ( index >= m_viewports.size() || m_viewports.size() < 0)
    {
      if (DEBUG && DEBUG_MODE >= LOW)
      {
        print ("ViewportManager::selectViewport incorrect viewport index. The number of viewports is " + m_viewports.size()); 
      }
      if ( m_viewports.size() > 0 )
      {
        selectViewport( m_viewports.size() - 1 );
      }
      else
      {
        if (DEBUG && DEBUG_MODE >= LOW)
        {
          print ("ViewportManager::selectViewPort no viewports exist in viewport list");
        }
        return;
      }
    }
    
    //Track the selected viewport
    if ( m_selectedViewport != -1 )
    {
      m_viewports.get(m_selectedViewport).onDeselected();
    }
    m_selectedViewport = index;  
    m_viewports.get(m_selectedViewport).onSelected();
  }
  
  void registerMeshToViewport( Mesh m, int viewportIndex )
  {
    m_viewports.get(viewportIndex).registerMesh(m);
  }
  
  //TODO msati3: add an unregister function that removes a registered mesh from a viewport

  void draw()
  {
    if (m_fShowingFullScreen)
    {
      if (m_selectedViewport != -1)
      {
        m_viewports.get(m_selectedViewport).draw(m_fShowingFullScreen);
      }
    }
    else
    {
      for (int i = 0; i < m_viewports.size(); i++)
      {
        m_viewports.get(i).draw(m_fShowingFullScreen);
      }
    }
  }
  
  void onMousePressed()
  {
    if (m_selectedViewport != -1)
    {
      m_viewports.get(m_selectedViewport).onMousePressed();
    }
    else
    {
    }
  }
  
  void onMouseDragged()
  {
    if (m_selectedViewport != -1)
    {
      m_viewports.get(m_selectedViewport).onMouseDragged();
    }
    else
    {
      if (DEBUG && DEBUG_MODE >= LOW)
      {
        print ("ViewportManager::onMouseDragged - no viewport currently selected");
      }
    }
  }
  
  void onKeyReleased()
  {
    if (m_selectedViewport != -1)
    {
      m_viewports.get(m_selectedViewport).onKeyReleased();
    }
    else
    {
      if (DEBUG && DEBUG_MODE >= LOW)
      {
        print ("ViewportManager::onMouseDragged - no viewport currently selected");
      }
    }
  }
  
  void onKeyPressed()
  {
    if (key == '.')
    {
      if (m_selectedViewport != -1)
      {
        selectViewport( (m_selectedViewport + 1)%m_viewports.size() );
      }
    }
    if (key == '/')
    {
      m_fShowingFullScreen = !m_fShowingFullScreen;
    }
    
    if (m_selectedViewport != -1)
    {
      m_viewports.get(m_selectedViewport).onKeyPressed();
    }    
  }
}
