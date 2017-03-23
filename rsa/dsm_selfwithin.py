"""Dissimilarity for occurrences of an item compared to other items of that category"""

import numpy as np
import scipy.stats as stats
from scipy.spatial.distance import cdist
from mvpa2.measures.base import Measure
from mvpa2.measures import rsa

class DSMSelfWithin(Measure):

    def __init__(self, split_attr, item_attr, cat_attr,
                 stats='full', n_perm=5000):

        Measure.__init__(self)
        self.split_attr = split_attr
        self.item_attr = item_attr
        self.cat_attr = cat_attr
        self.n_perm = n_perm
        self.stats = stats

    def __call__(self, dataset):

        # category information
        cat = dataset.sa[self.cat_attr].value
        ucat = np.unique(cat)
        n_cat = len(ucat)
        
        # split into the chunks we are comparing
        split = dataset.sa[self.split_attr].value
        usplit = np.unique(split)
        if len(usplit) != 2:
            raise ValueError('Split attribute must have two unique values.')
        ds1 = dataset[split == usplit[0],:]
        ds2 = dataset[split == usplit[1],:]

        # category and item information
        cat1 = ds1.sa[self.cat_attr].value
        cat2 = ds2.sa[self.cat_attr].value
        item1 = ds1.sa[self.item_attr].value
        item2 = ds2.sa[self.item_attr].value

        # dissimilarity for trials across chunks
        dsm = 1 - cdist(ds1.samples, ds2.samples, 'correlation')

        # aggregate over similarity bins (self=same item; within=same
        # category, not same item; all=same category)
        cat_self = [[] for i in ucat]
        cat_within = [[] for i in ucat]
        cat_all = [[] for i in ucat]
        for i in range(len(ds1)):
            for j in range(len(ds2)):
                # dissimilarity between these trials
                d = dsm[i,j]

                # index of the trial i category
                cat_ind = np.nonzero(cat1[i] == ucat)[0][0]

                if item1[i] == item2[j]:
                    # items match
                    cat_self[cat_ind].append(d)
                    cat_all[cat_ind].append(d)
                elif cat1[i] == cat2[j]:
                    # items match, but category does not
                    cat_within[cat_ind].append(d)
                    cat_all[cat_ind].append(d)

        # stats
        obs = [[] for i in ucat]
        boot_full = [[] for i in ucat]
        boot_m = [[] for i in ucat]
        p = [[] for i in ucat]
        z = [[] for i in ucat]
        for i in range(n_cat):
            # Fisher transform
            cat_self[i] = np.arctanh(np.array(cat_self[i]))
            cat_within[i] = np.arctanh(np.array(cat_within[i]))
            cat_all[i] = np.arctanh(np.array(cat_all[i]))

            # same item - same category, different item
            obs[i] = np.mean(cat_self[i]) - np.mean(cat_within[i])

            # bootstrap for this category
            boot = []
            n_self = len(cat_self[i])
            all_copy = np.copy(cat_all[i])
            for j in range(self.n_perm):
                np.random.shuffle(all_copy)
                boot_self = all_copy[:n_self]
                boot_within = all_copy[n_self:]
                boot.append(np.mean(boot_self) - np.mean(boot_within))
            # add actual value to the perm distribution
            boot.append(obs[i])
            boot_full[i] = boot
            boot_m[i] = np.mean(boot)
            
            # null probability
            p[i] = np.mean(boot >= obs[i])

            # convert to z with larger values -> more reliable
            z[i] = stats.norm.ppf(1 - p[i])

        if self.stats == 'full':
            res = {}
            res['item'] = cat_self
            res['within'] = cat_within
            res['all'] = cat_all
            res['item_within'] = obs
            res['boot_item_within'] = boot_full
            res['p'] = p
            return res
        else:
            return tuple(z)
