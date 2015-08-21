  public final class Prim {
 
  
     public ArrayList<Path> mst (ArrayList<Path> paths) {
  

           final int n = paths.size();

  
           float[] x=new float[n];
           float[] y=new float[n];
           float[] lx=new float[n];
           float[] ly=new float[n];
           double[] cost=new double[n]; // distance to MST
           boolean[] visit=new boolean [n];
           ArrayList<Path> order = new ArrayList<Path>();
  
           for (int i=0; i<n; i++) {
              x[i] = paths.get(i).first().x;
              y[i] = paths.get(i).first().y;
              lx[i] = paths.get(i).last().x;
              ly[i] = paths.get(i).last().y;
              cost[i] = Double.MAX_VALUE;
           }
  
           cost[0]=0.0D;
           double total = 0.0;
           for (int i=0; i<cost.length; i++) {
              // Find next node to visit: minimum distance to MST
              double m=Double.MAX_VALUE; int v=-1;
              for (int j=0; j<cost.length; j++) {
                 if (!visit[j] && cost[j]<m) 
                  { v=j; 
                    m=cost[j]; 
                  }
              }
              visit[v]=true;
              order.add(paths.get(v));
              if(order.size() > 1)
              {
                Path a = order.get(order.size()-2);
                Path b = order.get(order.size()-1);
                final double ds = Math.hypot (a.last().x-b.first().x,a.last().y-b.first().y);
                final double de = Math.hypot (a.last().x-b.last().x,a.last().y-b.last().y);
                if(de < ds)
                {
                  b.reverse();
                }
              }

              
              total+= m;
              for (int j=0; j<cost.length; j++) {
                if(!visit[j])
                {
                   final double ds = Math.hypot (lx[v]-x[j],ly[v]-y[j]);
                   final double de = Math.hypot (lx[v]-lx[j],ly[v]-ly[j]);
                   cost[j] = ds+de;

                }
              }
           }
           System.out.format ("%.2f", total);
           return order;
     }
  }

