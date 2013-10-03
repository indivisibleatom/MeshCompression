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
    //F.set(m.Cbox);
    m_meshInteractor.addMesh(m);
    m.setViewport(this);
  }
  
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
    /*for (int i = 0; i < m_registeredMeshes.size(); i++)
    {
      m_registeredMeshes.get(i).draw();
    }*/
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
    }
  
    Mesh selectedMesh = m_meshInteractor.getSelectedMesh();
    if (selectedMesh != null)
    {
      fill(green); scribe("surface = "+nf(selectedMesh.surf,1,1)+", volume = "+nf(selectedMesh.vol,1,0),0); 
      // writeFooterHelp();
      scribeHeaderRight("Mesh "+str(m_meshInteractor.getSelectedMeshIndex()));
    }
    hint(ENABLE_DEPTH_TEST); // show silouettes
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
    directionalLight(255,255,255,Li.x,Li.y,Li.z); // direction of light: behind and above the viewer
    specular(255,255,0); shininess(5);  

    // -------------------------------------------------------- display BACK if picking on the back ---------------------------------- 
    // display model used for picking (back only when picking on the back)
    if(pickBack) {noStroke(); if(translucent)  selectedMesh.showTriangles(false,100,shrunk); else selectedMesh.showBackTriangles(); }
    if(!pickBack) {
      if(translucent) {                                       // translucent mode
        fill(grey,80); noStroke(); selectedMesh.showBackTriangles();  
        if(selectedMesh.showEdges) stroke(orange); else noStroke();
        selectedMesh.showTriangles(true,150,shrunk);
        } 
      else {                                                  // opaque mode
        selectedMesh.draw();
        }      
      }
        
      // -------------------------------------------------------- graphic picking on surface ----------------------------------   
    if (keyPressed&&key=='t') T.set(Pick()); // sets point T on the surface where the mouse points. The camera will turn toward's it when the 't' key is released
    if (keyPressed&&key=='h') { selectedMesh.pickc(Pick()); }// sets c to closest corner in M 
    if(pressed) {
       if (keyPressed&&key=='s') selectedMesh.picks(Pick()); // sets M.sc to the closest corner in M from the pick point
       if (keyPressed&&key=='c') selectedMesh.pickc(Pick()); // sets M.cc to the closest corner in M from the pick point
       if (keyPressed&&(key=='w'||key=='x'||key=='X')) selectedMesh.pickcOfClosestVertex(Pick()); 
       }
    pressed=false;
   
    SetFrame(Q,I,J,K);  // showFrame(Q,I,J,K,30);  // sets frame from picked points and screen axes
    
    // rotate view 
    if(!keyPressed&&mousePressed) {E=R(E,  PI*float(mouseX-pmouseX)/width,I,K,F); E=R(E,-PI*float(mouseY-pmouseY)/width,J,K,F); } // rotate E around F 
    if(keyPressed&&key=='Z'&&mousePressed) {E=P(E,-float(mouseY-pmouseY),K); }  //   Moves E forward/backward
    if(keyPressed&&key=='z'&&mousePressed) {E=P(E,-float(mouseY-pmouseY),K);U=R(U, -PI*float(mouseX-pmouseX)/width,I,J); }//   Moves E forward/backward and rotatees around (F,Y)
  
   
     // -------------------------------------------------------- display picked points and triangles ----------------------------------   
    fill(cyan); selectedMesh.showSOT(); // shoes triangle t(cc) shrunken
    selectedMesh.showcc();  // display corner markers: seed sc (green),  current cc (red)
    
    // -------------------------------------------------------- display FRONT if we were picking on the back ---------------------------------- 
    if(pickBack) 
      if(translucent) {fill(cyan,150); if(selectedMesh.showEdges) stroke(orange); else noStroke(); selectedMesh.showTriangles(true,100,shrunk);} 
      else {fill(cyan); if(selectedMesh.showEdges) stroke(orange); else noStroke(); selectedMesh.showTriangles(true,255,shrunk);}
   
    // -------------------------------------------------------- Show mesh border (red), vertices and normals ---------------------------------- 
     stroke(red); selectedMesh.showBorder();  // show border edges
     if(showVertices) selectedMesh.showVertices(); // show vertices
     if(showNormals) selectedMesh.showNormals();  // show normals
     
    // -------------------------------------------------------- Disable z-buffer to display occluded silhouettes and other things ---------------------------------- 
    hint(DISABLE_DEPTH_TEST);  // show on top
    if(showSilhouette) {stroke(dbrown); selectedMesh.drawSilhouettes(); }  // display silhouettes
    
  
    // -------------------------------------------------------- SNAP PICTURE ---------------------------------- 
     if(snapping) snapPicture(); // does not work for a large screen
   } //end interact selected mesh
    
    
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
    

    // archival
    if(key=='W') {M.saveMeshVTS();}
    if(key=='G') {M.loadMeshOBJ(); // M.loadMesh(); 
                  M.updateON();   M.resetMarkers();
                  M.computeBox();  F.set(M.Cbox); fni=(fni+1)%fniMax; 
                  CL.empty(); SL.empty(); PL.empty(); 
                  for(int i=0; i<10; i++) vis[i]=true;
                  }
    if(key=='M') {M.loadMeshVTS(); 
                  M.updateON();   M.resetMarkers();
                  M.computeBox();  F.set(M.Cbox); 
                  for(int i=0; i<10; i++) vis[i]=true;
                  R = null;
                  }

    if(key=='?') {showHelpText=!showHelpText;} 
    //if(key=='V') {sE.set(E); sF.set(F); sU.set(U);}
    //if(key=='v') {E.set(sE); F.set(sF); U.set(sU);}
    //if(key=='m') {m=(m+1)%MM.length; M=MM[m];};  
    if (key == '!') {snapping=true;} // saves picture of screen
    M.onKeyPressed();
  }

 //State query functions for viewport
  pt getE() {return E;}
}
