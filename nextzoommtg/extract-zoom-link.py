#!/usr/local/bin/python3
# -*- coding: utf-8 -*-

import json
import sys
import re
import requests

regular_zoom_link = r'https://(?P<host>[^/]+\.zoom.us)/j/(?P<confno>\d+)(?:\S+(?P<pwd>pwd=[a-zA-Z0-9]+))?'
fancy_zoom_link = r'https://[^/]+\.zoom.us/my/[^?]+(?:\S+(?P<pwd>pwd=[a-zA-Z0-9]+))?'

def get_regular_link(text):
    m = re.search(regular_zoom_link, text)
    if m:
        parsed = m.groupdict()
        applink = "zoommtg://{}/join?action=join&zc=0&pk=&mcv=0.92.11227.0929&confno={}".format(parsed['host'], parsed['confno'])
        if parsed['pwd']:
            applink = applink + "&" + parsed['pwd']
        return applink
    return None

def get_fancy_link(text):
    m = re.search(fancy_zoom_link, text)
    if m:
        fancy_url = m.group(0)
        r = requests.get(fancy_url, allow_redirects=False)
        return get_regular_link(r.headers['Location'])
    return None

def main():
    data = json.load(sys.stdin)

    for event in data:
        if event['notes']:
            l = get_regular_link(event['notes'])
            if l is None:
                l = get_fancy_link(event['notes'])
            if l:
                sys.stderr.write('{}-{} {} {}\n'.format(event['start'], event['end'], event['title'], l))
                print(l)

if __name__ == '__main__':
    main()
