"""Class for working with collections of experimental events."""

import numbers
from collections import MutableSequence
from collections import OrderedDict
import sys
import six
import numpy as np

def make_index(indices):
    """Translate a set of numeric labels into one array.
    
    Inputs
    ------
    indices - iterable of tuples
        Set of indices for a list of entries.

    Outputs
    -------
    index - array of indices
        New, single index of each entry, based on the list of indices.
    
    sortcomb - [entries x indices] array
        The original list of indices for each value of index.
    
    """
    
    # array where each row has a unique combination of indices
    ucomb = np.vstack({tuple(ind) for ind in zip(*indices)})

    # sort in order of increasing indices
    ind = np.lexsort(tuple([*ucomb[:,::-1].T]))
    sortcomb = ucomb[ind,:]

    # initialize new index array with one label for each combination
    # of the original index set
    index_list = [np.array(i) for i in indices]
    n_entry = len(indices[0])
    n_unique, n_index = sortcomb.shape
    index = np.empty(n_entry)
    index.fill(np.nan)
    for i in range(n_unique):
        # find entries matching this set of indices
        match = np.ones(n_entry, dtype=bool)
        for j in range(n_index):
            match = np.logical_and(match, index_list[j] == sortcomb[i,j])
        index[match] = i
    return index, sortcomb

class Events(MutableSequence):

    def __init__(self, data=None):
        super(self.__class__, self).__init__()
        if data is not None:
            if isinstance(data, dict):
                # convert a dict of lists into a list of dicts
                fields = list(data.keys())
                n_field = [len(data[k]) for k in data.keys()]
                if len(np.unique(n_field)) > 1:
                    raise ValueError('Fields are different length.')
                
                l = []
                for i in range(n_field[0]):
                    d = OrderedDict()
                    for f in fields:
                        d[f] = data[f][i]
                    l.append(d)
                self._dlist = l
                self._fields = fields
            else:
                # assume some iterable of dicts
                self._dlist = list(data)
                if len(self._dlist) > 0 and isinstance(self._dlist[0], dict):
                    self._fields = self._dlist[0].keys()
                else:
                    self._fields = list()
        else:
            # create blank events
            self._dlist = list()
            self._fields = list()

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
        return "<Events %s>" % self._dlist
        
    def insert(self, ind, val):
        # add new fields if necessary
        new = [v for v in val.keys() if v not in self.keys()]
        self._fields.extend(new)

        # add the new event
        self._dlist.insert(ind, val)

    def append(self, val):
        self.insert(len(self._dlist), OrderedDict(val))

    def keys(self):
        """Return a list of keys for each event."""
        return self._fields

    def rmfield(self, field):
        """Remove a field from all events."""
        for e in self:
            if field in e:
                del e[field]
        self._fields.remove(field)
    
    def list(self, key):
        """Return a feature from each event as a list."""
        l = []
        for e in self:
            if key in e:
                l.append(e[key])
            else:
                l.append(None)
        return l
        
    def array(self, key, **kwargs):
        """Return a feature from each event as an array."""

        try:
            a = np.array(self.list(key))
        except ValueError:
            raise ValueError('Problem converting field to array.')

        if kwargs is not None:
            inc = self.match(**kwargs)
            a = a[inc]
        return a

    def setfield(self, key, vals):
        """Set the value of a field for all events."""

        if hasattr(vals, '__len__') and len(vals) != self.__len__():
            raise ValueError('Input vector must be a scalar or the same length as events.')
        for i in range(self.__len__()):
            if isinstance(vals, numbers.Number):
                self._dlist[i][key] = vals
            else:
                self._dlist[i][key] = vals[i]
        if key not in self._fields:
            self._fields.append(key)
    
    def match(self, **kwargs):
        """Find events that match a set of conditions."""

        inc = np.ones(self.__len__(), dtype=bool)
        for key, val in six.iteritems(kwargs):
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

    def sort(self, key):
        """Sort events by a field."""

        sort_vals = self.array(key)
        ind = np.argsort(sort_vals)
        ev = []
        for i in ind:
            ev.append(self._dlist[i])
        return Events(ev)
    
    def merge(self):
        """Merge all events into one dict."""

        ev_merge = OrderedDict()
        varying = set()
        for key in self.keys():
            # get all values for this field across all repeats
            vals = self.list(key)
            if len(set(vals)) == 1:
                # if unique, get just that value
                ev_merge[key] = vals[0]
            else:
                ev_merge[key] = vals
                varying.add(key)

        return ev_merge, varying

    def reduce(self, key, rm_varying=False):
        """Merge all events that have the same value for some field."""
        ev_red = Events()
        vals = self.array(key)
        uvals = np.unique(vals)
        varying = set()
        for val in uvals:
            ev_filt = self.filter(**{key: val})
            val_ev, val_varying = ev_filt.merge()
            varying.update(val_varying)
            ev_red.append(val_ev)
        if rm_varying:
            for field in varying:
                ev_red.rmfield(field)
        return ev_red
    
    def filter(self, **kwargs):
        """Return a subset of events."""
        
        inc = self.match(**kwargs)
        lsub = []
        for i in range(self.__len__()):
            if inc[i]:
                lsub.append(self._dlist[i])
        return Events(lsub)

    def col_size(self, key):
        """Determine column size needed to print a field."""

        a = self.list(key)
        length = [len(v.__repr__()) for v in a]
        length.append(len(key))
        return np.max(length)
    
    def table(self, include=None, exclude=None):
        """Return a table showing all events."""
        
        if include is not None:
            fields = include
        else:
            fields = self.keys()
        if exclude is not None:
            fields = [f for f in fields if f not in exclude]

        header_fmt = {}
        fmt = {}
        for key in fields:
            csize = self.col_size(key)
            header_fmt[key] = '%%-%ds  ' % csize
            fmt[key] = '%%%ds  ' % csize
            
        # print header
        s = ''
        for key in fields:
            s += header_fmt[key] % key

        # print data
        s += '\n'
        for event in self._dlist:
            for key in fields:
                if key in event:
                    val = event[key].__repr__()
                else:
                    val = 'None'
                s += fmt[key] % val
            s += '\n'
        return s
    
