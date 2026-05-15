import numpy as np
import kcsd
import os
import h5py
import sys
# python code for cal kcsd using kcsd module.
# filename is the .mat file contains electrodeposition, data and other parameters of kcsd
# data unit is mm 
def cal(filename):
    with h5py.File(filename,'r+') as f:
        #data = h5py.File(filename)
        a = np.array(f['electrodeposition'])
        b = np.array(f['data'])
        a = a.T
        b = b.T
        if 'CSD' in f:
            del (f['CSD'])
        ...
        if 'estm_x' in f:
            del (f['estm_x'])
        ...
        if 'estm_y' in f:
            del (f['estm_y'])
        ...
        x_range = np.max(a[:, 0]) - np.min(a[:, 0])
        y_range = np.max(a[:, 1]) - np.min(a[:, 1])

        if np.max(a[:, 0]) - np.min(a[:, 0]) > 0 and np.max(a[:, 1]) - np.min(a[:, 1]):
            CSD = kcsd.KCSD2D(a, b)
            f.create_dataset('CSD', data=CSD.values('CSD'))
            f.create_dataset('estm_x', data=CSD.estm_x)
            f.create_dataset('estm_y', data=CSD.estm_y)
        elif np.max(a[:, 0]) - np.min(a[:, 0]) == 0:
            a = np.reshape(a[:, 1], [-1, 1])
            CSD = kcsd.KCSD1D(a, b)
            f.create_dataset('CSD', data=CSD.values('CSD'))
            f.create_dataset('estm_y', data=CSD.estm_x)
        elif np.max(a[:, 1]) - np.min(a[:, 1]) == 0:
            a = np.reshape(a[:, 0], [-1, 1])
            CSD = kcsd.KCSD1D(a, b)
            f.create_dataset('CSD', data=CSD.values('CSD'))
            f.create_dataset('estm_x', data=CSD.estm_x)
        ...
    ...
...
def savevar(f,name,data):
    if name in f:
        del f[name]
        f.create_dataset(name,data=data)
    ...
...
def main():
    args=sys.argv[1:]
    filename=list()
    for arg in args:
        filename.append(arg)
    ...
    cal(filename[0])
...

if __name__=='__main__':
    main()
#cal('/mnt/Share/yuelp/functions/ylp/neuroview_gitee/python/testCSD.mat')
