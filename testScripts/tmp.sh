#!/bin/bash

#cd spotlight

#chown -R extractor:extractor /data/model-quickstarter-fork/
#su - extractor -c 'cd /data/model-quickstarter-fork/spotlight && mvn validate && mvn deploy -X -e -T 10 2>&1 | tee deployRoot.txt'
artifactID=$(date +%Y.%m.%d)
echo $artifactID
