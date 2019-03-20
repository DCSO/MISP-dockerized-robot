#!/usr/bin/env python3
# -*- coding: utf-8 -*-

#
#   The target of the python script is to migrate events with the same local ID from one MISP to another MISP instance.
#   Status: Experimental
#

misp_old_url = 'https://misp2.test/'
misp_old_key = 'p1gY1Ef8TosJ911MVM4W8T5bR8L7BwTOVlP555Wd' # The MISP auth key can be found on the MISP web interface under the automation section
misp_old_verifycert = False

misp_new_url = 'https://misp4.test/'
misp_new_key = '5zltDYPeQ03XPYQHRMbzy1mT2xY5NQFB6NWlpHad' # The MISP auth key can be found on the MISP web interface under the automation section
misp_new_verifycert = False


from pymisp import PyMISP
#from keys import misp_old_url, misp_old_key, misp_old_verifycert, misp_new_url, misp_new_key, misp_new_verifycert
import argparse
import logging
import json
import requests
import os
import time
# https://pyopenssl.org/en/stable/api/crypto.html#x509-objects
# http://www.yothenberg.com/validate-x509-certificate-in-python/
from OpenSSL import crypto
# Deactivate InsecureRequestWarnings
from requests.packages.urllib3.exceptions import InsecureRequestWarning
requests.packages.urllib3.disable_warnings(InsecureRequestWarning)


# Logging
#logging.getLogger('pymisp').setLevel(logging.DEBUG)

# For python2 & 3 compat, a bit dirty, but it seems to be the least bad one
try:
    input = raw_input
except NameError:
    pass

# class sql_statements(object):
#     def __init__(self,file):
#         #
#         # Inilitalize sql_statement object
#         #
#         self.SQL_SET = set()        # create empty set
#         self.FILE=file              # change file to parametet
#         self.load_existing_sql_statement_from_file()    # Load all existing SQL Statements from 'file'
    
#     def load_existing_sql_statement_from_file(self):
#         #
#         # Read existing SQL statements from file
#         #
#         try:
#             with open (self.FILE, 'r') as file:
#                 for line in  file.readlines():
#                     self.SQL_SET.add(line)
#         except:
#             print('')

#     def add_sql_data(self, UUID, email):
#         #
#         #   This function opens a file and write the sql statements to an given UUID and event_creator_email
#         #
#         # MariaDB [misp]> select * from events;
#         # +----+--------+------------+--------+---------+--------------------------------------+-----------+----------+-----------------+---------+------------+--------------+------------------+---------------------+--------+-----------------+-------------------+---------------------+--------------+
#         # | id | org_id | date       | info   | user_id | uuid                                 | published | analysis | attribute_count | orgc_id | timestamp  | distribution | sharing_group_id | proposal_email_lock | locked | threat_level_id | publish_timestamp | disable_correlation | extends_uuid |
#         # +----+--------+------------+--------+---------+--------------------------------------+-----------+----------+-----------------+---------+------------+--------------+------------------+---------------------+--------+-----------------+-------------------+---------------------+--------------+
#         # |  1 |      1 | 2019-02-15 | Test   |       1 | 5c66f188-a160-4d48-a0d5-0397c0a82f05 |         1 |        2 |               1 |       1 | 1550250838 |            1 |                0 |                   0 |      0 |               3 |        1551286087 |                   0 |              |
#         # |  2 |      1 | 2019-02-15 | Test23 |       1 | 5c66fc2b-b190-4d01-a90b-0394c0a82f05 |         0 |        0 |               1 |       1 | 1550253696 |            0 |                0 |                   0 |      0 |               4 |                 0 |                   0 |              |
#         # +----+--------+------------+--------+---------+--------------------------------------+-----------+----------+-----------------+---------+------------+--------------+------------------+---------------------+--------+-----------------+-------------------+---------------------+--------------+
#         # MariaDB [misp]> select * from users;
#         # +----+--------------------------------------------------------------+--------+-----------+------------------+-----------+------------------------------------------+------------+--------+---------------+----------+---------------+----------+---------+-----------+--------------+----------+------------+---------------+------------+--------------+--------------+---------------+
#         # | id | password                                                     | org_id | server_id | email            | autoalert | authkey                                  | invited_by | gpgkey | certif_public | nids_sid | termsaccepted | newsread | role_id | change_pw | contactalert | disabled | expiration | current_login | last_login | force_logout | date_created | date_modified |
#         # +----+--------------------------------------------------------------+--------+-----------+------------------+-----------+------------------------------------------+------------+--------+---------------+----------+---------------+----------+---------+-----------+--------------+----------+------------+---------------+------------+--------------+--------------+---------------+
#         # |  1 | $2a$10$kTK7N1T29jI/cPG.7enpyePmMZvDL1fBOnQan1AvPZFoprImHgOKe |      1 |         0 | admin@admin.test |         0 | yj8AjP3dD5zCCNiXCFw106oD6ZFhWqIMpdFNZ6NV |          0 | NULL   |               |  4000000 |             0 |        0 |       1 |         0 |            0 |        0 | NULL       |    1551285036 | 1551196845 |            0 |         NULL |    1551196419 |
#         # +----+--------------------------------------------------------------+--------+-----------+------------------+-----------+------------------------------------------+------------+--------+---------------+----------+---------------+----------+---------+-----------+--------------+----------+------------+---------------+------------+--------------+--------------+---------------+

#         # create SQL Statement
#         SQL_STATEMENT = "UPDATE events SET user_id = ( SELECT id FROM users WHERE email = '" + email + "') WHERE uuid = '" + UUID + "';\n"
#         print(SQL_STATEMENT)
#         self.SQL_SET.add(SQL_STATEMENT)

#     def write_sql_statements_to_file(self):
#         #
#         #   Write all SQL statements from set to file
#         #
#         with open (self.FILE, 'w+') as file:
#             file.writelines(self.SQL_SET)


def init(url, key, misp_verifycert):
    #
    #   Initialize function
    #
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

def migrate_taxonomies(misp_new, misp_old):
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

def migrate_events(START_EVENT_ID,END_EVENT_ID, misp_new, misp_old, sql_handler):
    #
    #   Migrate Events from old to new Instance
    #
    print('Migrate events...')
    for EVENT_ID in range(START_EVENT_ID, END_EVENT_ID+1):
        tmp_event = misp_old.get_event(EVENT_ID)
        if DEBUG is True:
            print(json.dumps(tmp_event, indent=4))
        # If event ID is not more used ignore it.
        try: 
            if tmp_event['name'] is 'Invalid event':
                print('Invalid Event '+str(EVENT_ID))
                continue
        except:
            # Write an SQL Statement file to change the User afterwards
            #sql_handler.add_sql_data(tmp_event['Event']['uuid'],tmp_event['Event']['event_creator_email'])

            # Add Events to new MISP
            misp_new.add_event(tmp_event)
            print(str(EVENT_ID)+' / '+ str(END_EVENT_ID)+' events migrated...')
    print('Migrate events...finished')
    input("Press Enter to continue...")     

def migrate_roles(misp_new, misp_old):
    print ('Migrate roles...')
    # body = '{
    #     "name": "mandatory",
    #     "perm_delegate": "optional",
    #     "perm_sync": "optional",
    #     "perm_admin": "optional",
    #     "perm_audit": "optional",
    #     "perm_auth": "optional",
    #     "perm_site_admin": "optional",
    #     "perm_regexp_access": "optional",
    #     "perm_tagger": "optional",
    #     "perm_template": "optional",
    #     "perm_sharing_group": "optional",
    #     "perm_tag_editor": "optional",
    #     "default_role": "optional",
    #     "perm_sighting": "optional",
    #     "permission": "optional"
    # }'
    
    for element in misp_old.get_roles_list():
        tmp_role=element['Role']
        if tmp_role['id'] == '9':
            body = {
                "name": "to_delete"
            }
            roles_add(misp_new, body)

        del tmp_role['id']
        del tmp_role['created']
        del tmp_role['modified']
        del tmp_role['memory_limit']
        del tmp_role['max_execution_time']
        print (json.dumps(tmp_role['name'], indent=4))
        roles_add(misp_new, tmp_role)
    
    print ('Migrate roles...finished')
    input("Press Enter to continue...")     

def roles_add(misp_new, tmp_role):
    relative_path = '/admin/roles/add'
    misp_new.direct_call(relative_path, tmp_role)

def roles_edit(misp_new, tmp_role):
    relative_path = '/admin/roles/edit'
    misp_new.direct_call(relative_path, tmp_role)

def migrate_user(misp_new, misp_old):
    print('Migrate users...')

    CURRENT_ID=1
    for tmp_user in misp_old.get_users_list()['response']:
        print('### Current User:')
        print (json.dumps(tmp_user, indent=4))
        print()

        # Create skeleton
        body = {
            #"id": "",
            "email": "",
            "org_id": "",
            "role_id": "",
            "password": "StartStart123!",
            # "external_auth_required": "optional",
            # "external_auth_key": "optional",
            "enable_password": "true",
            "nids_sid": "",
            "server_id": "",
            "gpgkey": "",
            "certif_public": "",
            "autoalert": "",
            "contactalert": "",
            "disabled": "",
            "change_pw": "1",
            "termsaccepted": "",
            "newsread": ""
        }
        # Change vars to current user
        body['email'] = tmp_user['User']['email']
        body['org_id'] = tmp_user['User']['org_id']
        body['role_id'] = tmp_user['User']['role_id']
        body['nids_sid'] = tmp_user['User']['nids_sid']
        body['server_id'] = tmp_user['User']['server_id']
        body['gpgkey'] = tmp_user['User']['gpgkey']
        # Check first if cert is expired, if this is true then do not store the cert, else store the cert
        try: 
            if not crypto.load_certificate(crypto.FILETYPE_PEM, tmp_user['User']['certif_public'] ).has_expired():
                body['certif_public'] = tmp_user['User']['certif_public']
        except:
            print('no cert')
        body['autoalert'] = tmp_user['User']['autoalert']
        body['contactalert'] = tmp_user['User']['contactalert']
        body['disabled'] = tmp_user['User']['disabled']
        body['termsaccepted'] = tmp_user['User']['termsaccepted']
        body['newsread'] = tmp_user['User']['newsread']

        FILE="/tmp/tmp_misp_user.json"
        with open(FILE,"w") as f:
            # print(' ')
            # print('### write file...')
            json.dump(body, f)
            # print(' ')

        # print('### Body:')
        # print(body)

        print(' ')
        try: 
            if misp_new.get_user(CURRENT_ID)['name'] == 'Invalid user':
                print('### added new User')
                print(' ')
                print(misp_new.add_user_json(FILE))
        except: 
            print('### edited existing User')
            print(' ')
            print(misp_new.edit_user_json(FILE, CURRENT_ID))
        
        print(' ')
            

        # Add +1 to CURRENT_ID
        CURRENT_ID = CURRENT_ID+1
        print('######################################################################')
        # Wait a second
        time.sleep(1)

    print('Migrate users...finished')
    input("Press Enter to continue...")   



#####################################
###
###     MAIN
###
#####################################

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Migration and updater helperscript.')
    parser.add_argument("-u", "--update", help="[true|false] Update Taxonomies, Warninglist, Template Objects, Galaxies.")
    parser.add_argument("-m", "--migrate_events", help="[true|false] Migrate MISP events from one MISP to another. Attention! This method change the event_creator_email adress.")
    parser.add_argument("-mu", "--migrate_users", help="[true|false] Migrate MISP users from one MISP to another.")
    parser.add_argument("-mr", "--migrate_roles", help="[true|false] Migrate MISP users roles from one MISP to another.")
    parser.add_argument("-mesID", "--migrate_event_start_ID", type=int, help="Start Event ID greater than 1. Default 1")
    parser.add_argument("-meeID", "--migrate_event_end_ID", type=int, help="End Event ID greater than 1. No default, is required.")
    args = parser.parse_args()

    # Configure and Initialize MISP 
    misp_new = init(misp_new_url, misp_new_key, misp_new_verifycert)
    misp_old = init(misp_old_url, misp_old_key, misp_old_verifycert)

    print('############################## START ###################################')

    # # Update the new Instance
    if args.update != None:
        print ('Update new MISP instance...')
        update_new_misp(misp_new)
    
    # Migrate Events
    if args.migrate_events != None:
        # Check if migrate-event-start-id is available
        if args.migrate_event_start_ID == None:
            START_EVENT_ID = 1
        elif args.migrate_event_start_ID < 1:
            print('Please only numbers greater than 1')
            exit(1)
        else:
            START_EVENT_ID = args.migrate_event_start_ID
        
        # Check if migrate-event-end-ID is available
        if args.migrate_event_end_ID == None:
            print('Error no migrate-event-end-ID as parameter. Please set this first.')
            exit(1)
        else:
            END_EVENT_ID = args.migrate_event_end_ID

        # Write and load from the following file:
        #SQL_HANDLER = sql_statements("migrate.sql")
        migrate_events(START_EVENT_ID,END_EVENT_ID,misp_new,misp_old, None)
        #SQL_HANDLER.write_sql_statements_to_file()
    
    # Migrate Users
    if args.migrate_users != None:
        migrate_user(misp_new, misp_old)

    # Migrate Roles
    if args.migrate_roles != None:
        migrate_roles(misp_new, misp_old)

    print('Do all?')
    input("Press Enter to continue...")   
    update_new_misp(misp_new)
    migrate_taxonomies(misp_new, misp_old)
    migrate_roles(misp_new, misp_old)
    migrate_user(misp_new, misp_old)
