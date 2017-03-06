"""Train and test a classifier on different parts of a dataset"""

import random
import numpy as np
import scipy.stats as stats
from mvpa2.measures.base import Measure
from sklearn.metrics import roc_curve, auc

class TrainTest(Measure):

    def __init__(self, clf, split_attr, n_test, n_perm=5000):

        Measure.__init__(self)
        self.clf = clf
        self.split_attr = split_attr

        self.n_perm = n_perm
        self.rand_ind = []
        test_ind = range(n_test)
        for i in range(n_perm):
            random.shuffle(test_ind)
            self.rand_ind.append(list(test_ind))

    def __call__(self, dataset):
        
        # split into the chunks we are comparing
        split = dataset.sa[self.split_attr].value
        usplit = np.unique(split)
        if len(usplit) != 2:
            raise ValueError('Split attribute must have two unique values.')
        ds1 = dataset[split == usplit[0],:]
        ds2 = dataset[split == usplit[1],:]

        clf = self.clf
        
        clf.train(ds1)
        pred = clf.predict(ds2.samples)

        evid = np.array([p[1][0]-p[1][1] for p in clf.ca.probabilities])
        fpr, tpr, thresh = roc_curve(ds2.targets, evid, pos_label=clf.ca.trained_targets[0])
        auc_data = auc(fpr, tpr)

        auc_perm = np.zeros(self.n_perm + 1)
        for i, rand_ind in enumerate(self.rand_ind):
            fpr, tpr, thresh = roc_curve(ds2.targets, evid[rand_ind], pos_label=clf.ca.trained_targets[0])
            auc_perm[i] = auc(fpr, tpr)

        auc_perm[self.n_perm] = auc_data
        p = np.mean(auc_perm >= auc_data)

        # positive infinity impossible since p has to be at least
        # 1/(nperm+1); avoid negative infinity
        e = 1.0 / (self.n_perm + 1)
        if p > (1-e):
            p = 1-e
        z = stats.norm.ppf(1 - p)
            
        return auc_data, z
