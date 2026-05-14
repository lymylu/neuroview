# demo for kCSD python function
import numpy as np
import kcsd
import h5py
import matplotlib.pyplot as plt
from kcsd.validation import plotting_functions as kplt
def make_plot(xx,yy,csd,elepos):
    ax=plt.axes()
    ax.contourf(xx,yy,csd)
    ax.scatter(elepos[:,0],elepos[:,1])
...

data=h5py.File('/mnt/Share/yuelp/functions/ylp/neuroview_gitee/python/tmpCSD.mat')
a=np.array(data['electrodeposition'])
b=np.array(data['data'])
a=a.T
b=b.T
if np.max(a[:,0])-np.min(a[:,0])>0 and np.max(a[:,1])-np.min(a[:,1]):
    CSD=kcsd.KCSD2D(a,b)
elif np.max(a[:,0])-np.min(a[:,0])==0:
    a=np.reshape(a[:,1],[-1,1])
    CSD = kcsd.KCSD1D(a, b)
elif np.max(a[:,1])-np.min(a[:,1])==0:
    a = np.reshape(a[:, 0], [-1, 1])
    CSD = kcsd.KCSD1D(a, b)
...
csd=CSD.values('CSD')
ax=plt.axes()
b=csd[:,:,2750]
make_plot(CSD.estm_x,CSD.estm_y,b,elepos=a)
plt.show()