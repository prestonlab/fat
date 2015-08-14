"""Class for working with collections of experimental events."""

import numbers
from collections import MutableSequence
from collections import OrderedDict
import sys
import numpy as np

class Events(MutableSequence):

    def __init__(self, data=None):
        super(self.__class__, self).__init__()
        if data is not None:
            if isinstance(data, dict):
                # convert a dict of lists into a list of dicts
                fields = data.keys()
                n = len(data[fields[0]])
                l = []
                for i in range(n):
                    d = OrderedDict()
                    for f in fields:
                        d[f] = data[f][i]
                    l.append(d)
                self._dlist = l
            else:
                self._dlist = list(data)
        else:
            self._dlist = list()

    def __len__(self):
        return len(self._dlist)

    def __getitem__(self, ind):
        return self._dlist[ind]

    def __delitem__(self, ind):
        del self._dlist[ind]

    def __setitem__(self, ind, val):
        self._dlist[ind] = val
        return self.dist[ind]

    def __str__(self):
        return self.table()

    def __repr__(self):
        return "<MyList %s>" % self._dlist
        
    def insert(self, ind, val):
        self._dlist.insert(ind, val)

    def append(self, val):
        self.insert(len(self._dlist), val)

    def keys(self):
        """Return a list of keys for each event."""
        # making brittle assumption that keys will be consistent
        # between events. Could get an exhaustive list instead, but
        # that would add execution time. Instead will trust the user
        # to check that their events are constructed properly
        return self._dlist[0].keys()

    def list(self, key):
        """Return a feature from each event as a list."""
        return [e[key] for e in self._dlist]
        
    def array(self, key, **kwargs):
        """Return a feature from each event as an array."""
        a = np.array(self.list(key))
        if kwargs is not None:
            inc = self.match(**kwargs)
            a = a[inc]
        return a

    def setfield(self, key, vals):
        """Set the value of a field for all events."""
        if len(vals) not in (1, self.__len__()):
            raise ValueError('Input vector must be a scalar or the same length as events.')
        for i in range(self.__len__()):
            if isinstance(vals, numbers.Number):
                self._dlist[i][key] = vals
            else:
                self._dlist[i][key] = vals[i]
    
    def match(self, **kwargs):
        """Find events that match a set of conditions."""

        inc = np.array([True for i in range(self.__len__())])
        for key, val in kwargs.iteritems():
            carray = self.array(key)
            if val == 'nan':
                # must use special test for NaNs
                cond_match = np.isnan(carray)
            elif val == '!nan':
                cond_match = np.logical_not(np.isnan(carray))
            else:
                cond_match = carray == val
            inc = np.logical_and(inc, cond_match)
        return inc
                
    def filter(self, **kwargs):
        """Return a subset of events."""
        
        inc = self.match(**kwargs)
        lsub = []
        for i in range(self.__len__()):
            if inc[i]:
                lsub.append(self._dlist[i])
        return Events(lsub)

    def table(self, include=None, exclude=None):

        if include is not None:
            fields = include
        else:
            fields = self.keys()
        if exclude is not None:
            fields = [f for f in fields if f not in exclude]
        
        # print header
        s = ''
        for key in fields:
            s += '%s\t' % key

        # print data
        s += '\n'
        for event in self._dlist:
            for key in fields:
                s += event[key].__repr__() + '\t'
            s += '\n'
        return s
    
