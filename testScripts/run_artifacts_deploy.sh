#!/bin/bash

chown -R extractor:extractor /data/model-quickstarter-fork/
su - extractor -c 'cd /data/model-quickstarter-fork/spotlight/spotlight-wikistats && mvn validate && mvn -Pwebdav deploy -X -e -T 20'
