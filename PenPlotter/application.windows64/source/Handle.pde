class Handle {

  String id;
  float x, y;
  int boxx, boxy;
  int stretch;
  int size;
  boolean over;
  boolean press;
  boolean locked = false;
  boolean otherslocked = false;
  boolean followsX;
  boolean followsY;
  float trackSpeed;
  Handle[] others;

  Handle(String aid, int ix, int iy, int il, int is, Handle[] o, boolean followX, boolean followY, float speed) {
    id = aid;
    x = ix;
    y = iy;
    stretch = il;
    size = is;
    boxx = (int)scaleX(x+stretch) - size/2;
    boxy = (int)scaleY(y) - size/2;
    trackSpeed = speed;
    others = o;
    followsX = followX;
    followsY = followY;
  }
  boolean wasActive()
  {
    return locked;
  }

  void update() {
    boxx = (int)scaleX(x+stretch)-size/2;
    boxy = (int)scaleY(y) - size/2;

    for (int i=0; i<others.length; i++) {
      if (others[i].locked == true) {
        otherslocked = true;
        break;
      } else {
        otherslocked = false;
      }
    }

    if (otherslocked == false) {
      overEvent();
      pressEvent();
    }

    if (press) {

      if (followsX)
      {
        float dx = (unScaleX(mouseX) -x)/trackSpeed;
        x+=dx;
      }
      if (followsY)
      { 
        float dy = (unScaleY(mouseY) -y)/trackSpeed ;
        y += dy;
      }
      handleMoved(id, (int)x, (int)y);
    }
  }

  void overEvent() {
    if (overRect(boxx, boxy, size, size)) {
      over = true;
    } else {
      over = false;
    }
  }

  void pressEvent() {
    if (over && mousePressed || locked) {
      press = true;
      locked = true;
    } else {
      press = false;
    }
  }

  void releaseEvent() {

    locked = false;
  }

  void display() {

    fill(255);
    stroke(0);
    rect(boxx, boxy, size, size);
    if (over || press) {
      fill(textColor);

      rect(boxx, boxy, size, size);

      int offx = 20;
      if (x > homeX)
        offx = -40;
      if (followsX && followsY)
        text("X "+(int)x+" Y "+(int)y, boxx-30, boxy+30);
      else if (followsX)
        text("X "+(int)x, boxx+offx, boxy);
      else if (followsY)
        text("Y "+(int)y, boxx+offx, boxy-10);
    }
  }
}

boolean overRect(int x, int y, int width, int height) {
  if (mouseX >= x && mouseX <= x+width && 
    mouseY >= y && mouseY <= y+height) {
    return true;
  } else {
    return false;
  }
}

int lock(int val, int minv, int maxv) { 
  return  min(max(val, minv), maxv);
} 

