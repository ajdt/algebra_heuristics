#!/usr/bin/env python

# accept as input what files to parse for predicates to ignore
# read each file, record any new predicates in some reliable storage
# return a set object which contains all the predicates we can ignore

# functions needed
# getIgnoredPredicatesFromFile
# get 
# may be easier in bash?
# TODO: at some point may be wise to replace this code with a full-on context-free grammar parser
#

import re
import tempfile
import os       # for file deletion at the end 
# just testing out regular expression
def makeSanitizedFile(file_name):
    """remove comments, then extract rules. Save to new file"""
    file_obj    = open(file_name, 'r')
    code        = re.sub('%.*\n', '\n', file_obj.read()) # remove comments

    #new_file_obj   = tempfile.NamedTemporaryFile(mode='w', delete=False)
    for matching in re.findall(r'[\w]+\(?[^\.:]*:-[^\.]*\.', code):
        if len(matching.split(':-')) > 2:
            continue
        new_file_obj.write(matching)

    file_obj.close()
    new_file_obj.close()
    return new_file_obj.name




# extract predicate and variables from a given
# I've written this function mostly to verify that everything works
def main():
    name =  makeSanitizedFile('nodes.lp')
    print 'filename', name
    print open(name, 'r').read()
    os.remove(name)
    print 'file now deleted'

if __name__ == '__main__':
    main()
