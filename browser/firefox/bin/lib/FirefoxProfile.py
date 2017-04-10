#!/usr/bin/env python

import sqlite3 as sqlite
import os
from glob import glob
from pyfzf import FzfPrompt
from sys import platform as _platform

fzf = FzfPrompt()

class FirefoxProfile:
    def __init__(self, dbfile):
        self.db = sqlite.connect(dbfile)
        self.cur = self.db.cursor()

    def __enter__(self):
        return FirefoxProfile.default()

    def __exit__(self, _, __, ___):
        self.close()

    @staticmethod
    def default():
        dbfile = None
        paths = ["~/.mozilla/firefox", "~/Library/Application Support/Firefox/Profiles"]
        while paths:
            path = os.path.expanduser(paths.pop())
            files = glob('{}/*.default/places.sqlite'.format(path))
            if files:
                dbfile = files[0]
                break
        if not dbfile:
            raise Exception("No places.sqlite file")
        return FirefoxProfile(dbfile)

    def bookmarks(self):
        self.cur.execute(
            'SELECT DISTINCT mb.title, mp.url ' +
            'FROM moz_bookmarks mb ' +
            'INNER JOIN moz_places mp ' +
            'ON mp.id = mb.fk ' +
            'WHERE mb.type = 1 AND mb.title IS NOT NULL '
            'ORDER BY mp.frecency DESC'
        )
        return self._process(self.cur.fetchall())

    def history(self):
        self.cur.execute(
            'SELECT DISTINCT title, url ' +
            'FROM moz_places ' +
            'WHERE title IS NOT NULL '
            'ORDER BY last_visit_date DESC'
        )
        return self._process(self.cur.fetchall())

    def _process(self, data):
        lookup = {}
        result = []
        for row in data:
            title = (row[0] or "").encode('utf-8').strip()
            url = (row[1] or "").encode('utf-8').strip()
            key = ", ".join((title, url))
            if key not in lookup and row[1].startswith("http"):
                lookup[key] = 1
                result.append(key)
        return result

    def browse(self, url):
        if _platform.startswith("linux"):
            os.system('xdg-open "{}"'.format(url))
        elif _platform == "darwin":
            os.system('open "{}"'.format(url))
        else:
            raise Exception("What you doin' fool")

    def close(self):
        self.db.close()
