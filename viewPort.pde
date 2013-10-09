class Viewport
{
  private int m_x;
  private int m_y;
  private int m_width;
  private int m_height;
  private boolean m_fSelected;
  MeshInteractor m_meshInteractor;

  // ****************************** VIEWING PARAMETERS *******************************************************
  private pt F = P(0,0,0); pt T = P(); pt E = P(0,0,1000); vec U=V(0,1,0);  // focus  set with mouse when pressing 't', eye, and up vector
  private pt Q=P(0,0,0); vec I=V(1,0,0); vec J=V(0,1,0); vec K=V(0,0,1); // picked surface point Q and screen aligned vectors {I,J,K} set when picked
  
  Viewport( int x, int y, int width, int height )
  {
    m_x = x;
    m_y = y;
    m_width = width;
    m_height = height;
    m_meshInteractor = new MeshInteractor();
    initView();
  }
  
  void initView()
  {
    Q=P(0,0,0); I=V(1,0,0); J=V(0,1,0); K=V(0,0,1); F = P(0,0,0); E = P(0,0,1000); U=V(0,1,0);  // declares the local frames
  }
  
  //Interactions with viewport manager
  void onSelected()
  {
    m_fSelected = true;
  }
  
  void onDeselected()
  {
    m_fSelected = false;
  }
    
  void registerMesh(Mesh m)
  {
    if ( m_meshInteractor.addMesh(m) == 1 )
    {
      initView();
      F.set(m.Cbox);
    }
    m.setViewport(this);
  }
  
  void unregisterMesh(Mesh m)
  {
    m_meshInteractor.removeMesh(m);
    m.setViewport(null);
  }
    
  void onMousePressed()
  {
    Mesh selectedMesh = m_meshInteractor.getSelectedMesh();
    if (selectedMesh != null)
    {
      selectedMesh.onMousePressed();
    }
  }
  
  void onMouseDragged()
  {
    Mesh selectedMesh = m_meshInteractor.getSelectedMesh();
    if (selectedMesh != null)
    {
      if(keyPressed&&key=='w') {selectedMesh.add(float(mouseX-pmouseX),I).add(-float(mouseY-pmouseY),J); } // move selected vertex in screen plane
      if(keyPressed&&key=='x') {selectedMesh.add(float(mouseX-pmouseX),I).add(float(mouseY-pmouseY),K);}  // move selected vertex in X/Z screen plane
      if(keyPressed&&key=='W') {selectedMesh.addROI(float(mouseX-pmouseX),I).addROI(-float(mouseY-pmouseY),J); } // move selected vertex in screen plane
      if(keyPressed&&key=='X') {selectedMesh.addROI(float(mouseX-pmouseX),I).addROI(float(mouseY-pmouseY),K);}  // move selected vertex in X/Z screen plane 

      //Rotate viewport's view
      if(!keyPressed) {E=R(E,  PI*float(mouseX-pmouseX)/width,I,K,F); E=R(E,-PI*float(mouseY-pmouseY)/width,J,K,F); } // rotate E around F 
      if(keyPressed&&key=='Z') {E=P(E,-float(mouseY-pmouseY),K); }  //   Moves E forward/backward
      if(keyPressed&&key=='z') {E=P(E,-float(mouseY-pmouseY),K);U=R(U, -PI*float(mouseX-pmouseX)/width,I,J); }//   Moves E forward/backward and rotatees around (F,Y)

    }
    else
    {
      if (DEBUG && DEBUG_MODE >= LOW)
      {
        print("Viewport::onMouseDragged - no interactions possible, as no mesh is currently selected");
      }
    }
  }
  
  void onKeyReleased()
  {
    if(key=='t') F.set(T);  // set camera focus
     /*if(key=='c') println("edge length = "+d(M.gp(),M.gn()));  
     U.set(M(J)); // reset camera up vector*/
  }
  
  void onKeyPressed()
  {
    Mesh M = m_meshInteractor.getSelectedMesh();
    if ( M == null )
    {
      if (DEBUG && DEBUG_MODE >= LOW)
      {
        print("Viewport::onInteractSelectedMesh - no interactions possible, as no mesh is currently selected");
      }
      return;
    }  
    // camera focus set 
    if(key=='^') F.set(M.g()); // to picked corner
    if(key==']') F.set(M.Cbox);  // center of minimax box
    if(key==';') {initView(); F.set(M.Cbox); } // reset the view
    

    //archival
    if(key=='K') {M.saveMeshVTS();}
    if(key=='L') {Mesh m = new Mesh();
                 m.loadMeshOBJ(); // M.loadMesh(); 
                 m.updateON();   m.resetMarkers();
                 m.computeBox();
                 for(int i=0; i<10; i++) vis[i]=true;
                 registerMesh(m);
                }
    if(key=='M') {Mesh m = new Mesh();
                 m.loadMeshVTS(); 
                 m.updateON();   m.resetMarkers();
                 m.computeBox();
                 for(int i=0; i<10; i++) vis[i]=true;
                 registerMesh(m);
                 }
    if(key=='?') {showHelpText=!showHelpText;} 
    //if(key=='V') {sE.set(E); sF.set(F); sU.set(U);}
    //if(key=='v') {E.set(sE); F.set(sF); U.set(sU);}
    //if(key=='m') {m=(m+1)%MM.length; M=MM[m];};  
    M.onKeyPressed();
  }

  //************Drawing functions*****************  
  void draw(boolean fShowFullScreen)
  {
    if (fShowFullScreen)
    {
      gl.glViewport( 0, 0, width, height );
    }
    else
    {
      gl.glViewport( m_x, m_y, m_width, m_height );
    }
    
    drawDecorations();

    camera(E.x, E.y, E.z, F.x, F.y, F.z, U.x, U.y, U.z); // defines the view : eye, ctr, up
    vec Li=U(A(V(E,F),0.1*d(E,F),J));   // vec Li=U(A(V(E,F),-d(E,F),J)); 
    directionalLight(255,255,255,Li.x,Li.y,Li.z); // direction of light: behind and above the viewer
    specular(255,255,0); shininess(5);  
    SetFrame(Q,I,J,K);
    m_meshInteractor.drawRegisteredMeshes();

    if (m_fSelected)
    {
      interactSelectedMesh();
    }
  }
  
  private void drawDecorations()
  {
    camera(); // 2D view to write help text
    if (m_fSelected)
    {
      noFill();
      strokeWeight(2);
      stroke(blue);
      rect(0, 0, width, height);

      Mesh selectedMesh = m_meshInteractor.getSelectedMesh();
      if (selectedMesh != null)
      {
        stroke(green);
        fill(green); scribe("Surface = "+nf(selectedMesh.surf,1,1)+", Volume = "+nf(selectedMesh.vol,1,0),0); 
        scribeHeaderRight("Mesh "+str(m_meshInteractor.getSelectedMeshIndex()));
      }
    }
  
    hint(ENABLE_DEPTH_TEST); // show silouettes
  }
 
  private void interactSelectedMesh()
  {
    Mesh selectedMesh = m_meshInteractor.getSelectedMesh();
    if ( selectedMesh == null )
    {
      if (DEBUG && DEBUG_MODE >= LOW)
      {
        print("Viewport::onInteractSelectedMesh - no interactions possible, as no mesh is currently selected");
      }
      return;
    }
    // -------------------------------------------------------- 3D display : set up view ----------------------------------
    camera(E.x, E.y, E.z, F.x, F.y, F.z, U.x, U.y, U.z); // defines the view : eye, ctr, up
    vec Li=U(A(V(E,F),0.1*d(E,F),J));   // vec Li=U(A(V(E,F),-d(E,F),J)); 
    
    //TODO msati3: Change this if so required
    //directionalLight(255,255,255,Li.x,Li.y,Li.z); // direction of light: behind and above the viewer
    //specular(255,255,0); shininess(5);  
    
    selectedMesh.draw();
    if (keyPressed&&key=='t') T.set(Pick()); // sets point T on the surface where the mouse points. The camera will turn toward's it when the 't' key is released
    selectedMesh.interactSelectedMesh();      
   
    SetFrame(Q,I,J,K);  // showFrame(Q,I,J,K,30);  // sets frame from picked points and screen axes
    
    selectedMesh.drawPostPicking();  
   } //end interact selected mesh

 //State query functions for viewport
  boolean containsPoint(int x, int y)
  {
    if ( x >= m_x && x <= m_x + m_width && y >= m_y && y <= m_y + m_height )
      return true;
    return false;   
  }
  
  pt getE() {return E;}
}
