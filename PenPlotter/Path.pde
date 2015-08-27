
    class Path {
        ArrayList<RPoint> points = new ArrayList<RPoint>();

        public void addPoint(float x, float y)
        {
            points.add(new RPoint(x, y));
        }

        public RPoint getPoint(int index)
        {
            return points.get(index);
        }

        public int size()
        {
            return points.size();
        }

        public RPoint first()
        {
            return points.get(0);
        }

        public RPoint last()
        {
            return points.get(points.size()-1);
        }

        public void merge(Path p)
        {
            for (int i = 0; i<p.size (); i++)
            {
                points.add(p.getPoint(i));
            }
        }

        public void reverse()
        {
            ArrayList<RPoint> reverse = new ArrayList<RPoint>();
            for (int i = points.size ()-1; i>=0; i--)
                reverse.add(points.get(i));
            points = reverse;
        }

        public void removeShort(float len)
        {
            ArrayList<RPoint> clean = new ArrayList<RPoint>();
            RPoint last = points.get(0);
            clean.add(last);
            for (int i = 1; i<points.size (); i++)
            {
                RPoint cur = points.get(i);
                if (dist(last.x, last.y, cur.x, cur.y) >= len)
                {
                    clean.add(cur);
                    last = cur;
                }
            }
            points = clean;
        }
    }