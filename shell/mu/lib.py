#!/usr/bin/env python

from subprocess import check_output
from re import sub
import sys

def get_pass(account):
    data = check_output("/usr/bin/pass email/" + account, shell=True).splitlines()
    password = data[0]
    tmp = [x for x in data if x.startswith('address:')]
    user = ""
    if len(tmp) > 0:
        user = tmp[0].split(":", 1)[1]

    return {"password": password, "user": user}

def folder_filter(name):
    return not (name in ['[Gmail]/Spam',
                         '[Gmail]/Important',
                         '[Gmail]/Starred',
                         '[Gmail]/All Mail'] or
                name.startswith('[Airmail]'))

def nametrans(name):
    return sub('^INBOX/(Starred|Sent Mail|Drafts|Trash|All Mail|Spam)$', '[Gmail]/\\1', name)

def nametrans_reverse(name):
    return sub('^(\[Gmail\])', 'INBOX.', name)


if __name__ == '__main__':
    print(get_pass(sys.argv[1].strip())['password'])
