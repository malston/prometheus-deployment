#!/usr/bin/env python

import os
import yaml

def find(key, dictionary):
    for k, v in dictionary.items():
        if k == key:
            yield v
        elif isinstance(v, dict):
            for result in find(key, v):
                yield result

if __name__ == '__main__':

    # traverse root directory, and list directories as dirs and files as files
    for root, dirs, files in os.walk("."):
        fullpath = os.path.abspath(root)
        for file in files:
            if file == 'values.yaml':
                f = os.path.join(fullpath, file)
                with open(f, 'r') as stream:
                    try:
                        data = yaml.safe_load(stream)

                        for image in find("image", data):
                            if isinstance(image, dict):
                                repo = image.get("repository", "")
                                tag = image.get("tag", "")
                                print(repo + ":" + tag)
                    except yaml.YAMLError as exc:
                        print(exc)
