
import os
import numpy as np

def read_design(filepath):

    if not os.path.exists(filepath):
        raise IOError('file does not exist.')
    
    with open(filepath, 'r') as f:
        in_header = True
        n_point = None
        n_wave = None
        while in_header:
            line = f.readline()
            if 'NumPoints' in line:
                n_point = int(line.strip().split('\t')[1])
            elif 'NumWaves' in line:
                n_wave = int(line.strip().split('\t')[1])
            elif 'Matrix' in line:
                in_header = False

        mat = np.zeros((n_point,n_wave))
        for i in range(n_point):
            line = f.readline()
            mat[i,:] = np.fromstring(line.strip(), dtype=np.float, sep='\t')
            
        return mat
