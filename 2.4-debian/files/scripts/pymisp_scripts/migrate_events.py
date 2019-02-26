#!/usr/bin/env python
# -*- coding: utf-8 -*-

#
#   The target of the python script is to migrate events with the same local ID from one MISP to another MISP instance.
#   Status: Experimental
#


from pymisp import PyMISP
from keys import misp_old_url, misp_old_key, misp_old_verifycert, misp_new_url, misp_new_key, misp_new_verifycert
import argparse
import logging
import json
import requests

# Deactivate InsecureRequestWarnings
from requests.packages.urllib3.exceptions import InsecureRequestWarning
requests.packages.urllib3.disable_warnings(InsecureRequestWarning)


# Logging
logging.getLogger('pymisp').setLevel(logging.DEBUG)

# For python2 & 3 compat, a bit dirty, but it seems to be the least bad one
try:
    input = raw_input
except NameError:
    pass


#
#   Initialize function
#
def init(url, key, misp_verifycert):
    return PyMISP(url, key, misp_verifycert, 'json', debug=False)

def update_new_misp(misp_new):
    #
    # Update new Instance
    #
    print('Update Galaxies...')
    misp_new.update_galaxies()
    
    print('Update Object Templates...')
    misp_new.update_object_templates()
    
    print('Update Taxonomies...')
    misp_new.update_taxonomies()
    
    print('Update Warninglists...')
    misp_new.update_warninglists()
    # Wait for User
    input("Press Enter to continue...")

def migrate_taxonomies(misp_new,misp_old):
    #
    #   Add Taxonomies
    #
    print('Activate all Taxonomies on the new one which are activated on the old one...')
    all_taxonomies = misp_old.get_taxonomies_list()
    for TAXONOMY in all_taxonomies.get('response'):
        if ( TAXONOMY.get('Taxonomy').get('enabled') == True ):
             # Get out the current Taxonomy:
             print(TAXONOMY)
             # Activate Taxonomy on new MISP
             misp_new.enable_taxonomy(TAXONOMY.get('Taxonomy').get('id'))
    input("Press Enter to continue...")

def migrate_events(START_EVENT_ID,END_EVENT_ID,misp_new,misp_old):
    #
    #   Migrate Events from old to new Instance
    #
    print('Migrate Events from old to new Instance')
    for EVENT in range(START_EVENT_ID, END_EVENT_ID+1):
         tmp_event = misp_old.get_event(EVENT)
         print(EVENT)
         misp_new.add_event(tmp_event)
    

if __name__ == '__main__':

    # Configure and Initialize MISP 
    misp_new = init(misp_new_url, misp_new_key, misp_new_verifycert)
    misp_old = init(misp_old_url, misp_old_key, misp_old_verifycert)

    
    print('############################## START ###################################')


    # Update the new Instance
    update_new_misp(misp_new)

    # Migrate taxonomies
    migrate_taxonomies(misp_new,misp_old)
    
    # Migrate Events
    migrate_events(1,1227,misp_new,misp_old)
    
    