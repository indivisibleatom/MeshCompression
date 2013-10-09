class BaseMesh extends Mesh
{
  BaseMesh()
  {
    m_userInputHandler = new BaseMeshUserInputHandler(this);
  }
}

