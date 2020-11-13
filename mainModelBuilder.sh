#!/bin/bash
#+------------------------------------------------------------------------------------------------------------------------------+
#| DBpedia Spotlight - Create database-backed model                                                                             |
#| @author Joachim Daiber                                                                                                       |
#+------------------------------------------------------------------------------------------------------------------------------+

export LC_ALL=en_US.UTF-8
export MAVEN_OPTS="-Xmx26G"

#StringLanguages="en_US-English de_DE-German nl_NL-Dutch sv_SE-Swedish pt_BR-Portuguese fr_FR-French es_ES-Spanish tr_TR-Turkish no_NO-Norwegian it_IT-Italian da_DK-Danish ja_JP-None cs_CZ-None hu_HU-Hungarian ru_RU-Russian zh_CN-None"
#StringLanguages="en_US-English de_DE-German fr_FR-French"
StringLanguages="ca_ES-Catalan"

opennlp="None"
eval="false"
blacklist="false"

#BASE_DIR=$(pwd)
BASE_DIR="/data/model-quickstarter-fork"

BASE_WDIR="$BASE_DIR/wdir"
BASE_ARTIFACTDIR="$BASE_DIR/spotlight"

ARTIFACT_VERSION=$(date +%Y.%m.%d)
#Iteration
for lang in $StringLanguages; do
     echo $lang >> /data/model-quickstarter-fork/debug.txt
     LANGUAGE=$(echo "$lang" | sed "s/_.*//g")
     STEMMER=$(echo "$lang" | sed "s/.*-//g")
    if [[ "$STEMMER" != "None" ]]; then
        STEMMER="$STEMMER""Stemmer"
    fi

    LOCALE=$(echo "$lang" | sed "s/-.*//g")
    echo "Language: $LANGUAGE">> /data/model-quickstarter-fork/debug.txt
    echo "Stemmer: $STEMMER">> /data/model-quickstarter-fork/debug.txt
    echo "Locale: $LOCALE">> /data/model-quickstarter-fork/debug.txt

    TARGET_DIR="$BASE_DIR/models/$LANGUAGE"
    WDIR="$BASE_WDIR/$LOCALE"
    echo ARTIFACT = "$ARTIFACT_VERSION">> /data/model-quickstarter-fork/debug.txt
    echo "Working directory: $WDIR">> /data/model-quickstarter-fork/debug.txt

    STOPWORDS="$BASE_DIR/$LANGUAGE/stopwords.list"

    if [[ -f "$LANGUAGE/ignore.list" ]]
    then
         blacklist="$BASE_DIR/$LANGUAGE/ignore.list"
    else
         blacklist="None"
    fi

    mkdir -p "$WDIR"
    echo "======================================================================">> /data/model-quickstarter-fork/debug.txt

########################################################################################################
# Preparing the data.
########################################################################################################

    echo "Loading Wikipedia dump..." >> /data/model-quickstarter-fork/debug.txt
    date -u >> /data/model-quickstarter-fork/debug.txt
    if [ -z "$WIKI_MIRROR" ]; then
      WIKI_MIRROR="https://dumps.wikimedia.org/"
    fi

    WP_DOWNLOAD_FILE=$WDIR/dump.xml.bz2
    echo Checking for wikipedia dump at "$WP_DOWNLOAD_FILE"
    if [ -f "$WP_DOWNLOAD_FILE" ]; then
      echo File exists.
    else
      echo Downloading wikipedia dump.
      if [[ "$eval" == "false" ]] 
      then
	cd "$WDIR"
        curl -O "$WIKI_MIRROR/${LANGUAGE}wiki/latest/${LANGUAGE}wiki-latest-pages-articles.xml.bz2" 
	mv "${LANGUAGE}"wiki-latest-pages-articles.xml.bz2 dump.xml.bz2
      else
        curl -# "$WIKI_MIRROR/${LANGUAGE}wiki/latest/${LANGUAGE}wiki-latest-pages-articles.xml.bz2" | bzcat | python "$BASE_DIR"/scripts/split_train_test.py 1200 "$WDIR"/heldout.txt > "$WDIR"/dump.xml
      fi
    fi

    cd "$WDIR"
    cp "$STOPWORDS" stopwords."$LANGUAGE".list

    touch "$LANGUAGE.tokenizer_model"


########################################################################################################
# DBpedia extraction:
########################################################################################################

######     #    #######    #    ######  #     #  #####
#     #   # #      #      # #   #     # #     # #     #
#     #  #   #     #     #   #  #     # #     # #
#     # #     #    #    #     # ######  #     #  #####
#     # #######    #    ####### #     # #     #       #
#     # #     #    #    #     # #     # #     # #     #
######  #     #    #    #     # ######   #####   #####

    echo " Downloading the latest version of the following artifacts: * https://databus.dbpedia.org/dbpedia/generic/disambiguations * https://databus.dbpedia.org/dbpedia/generic/redirects * 
    https://databus.dbpedia.org/dbpedia/mappings/instance-types

    Note of deviation from original index_db.sh:
    takes the direct AND transitive version of redirects and instance-types and the redirected version of disambiguation
    " >> /data/model-quickstarter-fork/debug.txt
    date -u >> /data/model-quickstarter-fork/debug.txt
    cd "$BASE_WDIR"
    echo "BASE_WDIR = $BASE_WDIR"
    QUERY="PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
    PREFIX dc: <http://purl.org/dc/elements/1.1/>
    PREFIX dataid: <http://dataid.dbpedia.org/ns/core#>
    PREFIX dataid-cv: <http://dataid.dbpedia.org/ns/cv#>
    PREFIX dct: <http://purl.org/dc/terms/>
    PREFIX dcat: <http://www.w3.org/ns/dcat#>

    SELECT  ?file WHERE {
        {
        # Subselect latestVersion by artifact
        SELECT  ?artifact (max(?version) as ?latestVersion)  WHERE {
                ?dataset dataid:artifact ?artifact .
                ?dataset dct:hasVersion ?version
                FILTER (?artifact in (
                # GENERIC
                    <https://databus.dbpedia.org/dbpedia/generic/disambiguations> ,
                    <https://databus.dbpedia.org/dbpedia/generic/redirects> ,
                    # MAPPINGS
                    <https://databus.dbpedia.org/dbpedia/mappings/instance-types>
                  # latest ontology, currently @denis account
                  # TODO not sure if needed for Spotlight
                    # <https://databus.dbpedia.org/denis/ontology/dbo-snapshots>
                 )) .
                 }GROUP BY ?artifact
      }

        ?dataset dct:hasVersion ?latestVersion .
        {
              ?dataset dataid:artifact ?artifact .
              ?dataset dcat:distribution ?distribution .
              ?distribution dcat:downloadURL ?file .
              ?distribution dataid:contentVariant '$LANGUAGE'^^xsd:string .
              # remove debug info
              MINUS {
                   ?distribution dataid:contentVariant ?variants .
                   FILTER (?variants in ('disjointDomain'^^xsd:string, 'disjointRange'^^xsd:string))
              }
        }
    } ORDER by ?artifact
    "

    # execute query and trim " and first line from result set
    RESULT=`curl --data-urlencode query="$QUERY" --data-urlencode format="text/tab-separated-values" https://databus.dbpedia.org/repo/sparql | sed 's/"//g' | grep -v "^file$" `
    echo "QUERY = $QUERY"
    echo "RESULT = $RESULT"
    # Download
    TMPDOWN="dump-tmp-download"
    mkdir $TMPDOWN
    cd $TMPDOWN
    echo "PWD = $(pwd)"
    for i in $RESULT
      do
          wget "$i"
          ls
          echo $TMPDOWN
          pwd
      done

    echo "decompressing"
    ALLFINE=true
    MISSING_ARTIFACTS=""

    for f in "instance-types"*; do
      # [ -e "$f" ] && bzcat -v $TMPDOWN/instance-types*.ttl.bz2 > $WDIR/instance_types.nt || touch $WDIR/instance_types.nt
       if [[ -e "$f" ]]
       then
	    echo "instance-types exists"   
            bzcat -v instance-types*.ttl.bz2 > "$WDIR"/instance_types.nt
       else
            ALLFINE=false
            MISSING_ARTIFACTS="instance-types"
	    touch "$WDIR"/instance_types.nt
       fi
       break
    done

    for f in "disambiguations"*; do
       if [[ -e "$f" ]]
       then
	    echo "disambiguations exists"   
            bzcat -v disambiguations*.ttl.bz2 > "$WDIR"/disambiguations.nt
       else
            ALLFINE=false
            MISSING_ARTIFACTS=$MISSING_ARTIFACTS" disambiguations"
	    touch "$WDIR"/disambiguations.nt
       fi
       break
   done

    for f in "redirects"*; do
       if [[ -e "$f" ]]
       then
	    echo "redirects exists"   
            bzcat -v redirects*.ttl.bz2 > "$WDIR"/redirects.nt
       else
           ALLFINE=false
           MISSING_ARTIFACTS=$MISSING_ARTIFACTS" redirects"
	   touch "$WDIR"/redirects.nt
       fi
       break
   done

    # clean
    cd ..
    rm -r $TMPDOWN
   
   if [[ $ALLFINE = false ]] 
   then
        echo "##########################################################################################################"
        echo "######Artifact(s) (""$MISSING_ARTIFACTS"") missing, for more details about this please refer to https://forum.dbpedia.org/t/tasks-for-volunteers/163, task: 'Languages with missing redirects/disambiguations/instance-type'"
        echo "##########################################################################################################"
        echo "$LOCALE" >> "$BASE_DIR"/missingArtifacts.txt
        #continue
   fi
########################################################################################################
# Extracting wiki stats:
########################################################################################################

    echo "Extracting wiki stats" >> /data/model-quickstarter-fork/debug.txt
    date -u >> /data/model-quickstarter-fork/debug.txt
    cd "$BASE_WDIR"
    rm -Rf wikistatsextractor
#    git clone --depth 1 https://github.com/dbpedia-spotlight/wikistatsextractor
    git clone --depth 1 https://github.com/Julio-Noe/wikistatsextractor

    # Stop processing if one step fails
    set -e

    #Copy results to local:
    cd "$BASE_WDIR"/wikistatsextractor

    echo "MVN ARGUMENTS --output_folder $WDIR $LANGUAGE $3 $5Stemmer $WDIR/dump.xml $WDIR/stopwords.$LANGUAGE.list"

    mvn install exec:java -Dexec.args="--output_folder $WDIR $LANGUAGE $LOCALE $STEMMER $WDIR/dump.xml.bz2 $WDIR/stopwords.$LANGUAGE.list" -X

    if [ "$blacklist" != "None" ]; then
      echo "Removing blacklist URLs..."
      mv $WDIR/uriCounts $WDIR/uriCounts_all
      grep -v -f "$blacklist" "$WDIR"/uriCounts_all > "$WDIR/uriCounts"
    fi

    echo "Finished wikistats extraction. Cleaning up..."
#    rm -f $WDIR/dump.xml

########################################################################################################
# Setting up Spotlight:
########################################################################################################

    echo "Setting up Spotlight" >> /data/model-quickstarter-fork/debug.txt
    date -u >> /data/model-quickstarter-fork/debug.txt
    cd "$BASE_WDIR"

    if [ -d dbpedia-spotlight ]; then
        echo "Updating DBpedia Spotlight..."
        cd dbpedia-spotlight
        git reset --hard HEAD
        git pull
        mvn -T 1C -q -Dhttps.protocols=TLSv1.2 clean install
    else
        echo "Setting up DBpedia Spotlight..."
        git clone -b multilingual --depth 1 https://github.com/Julio-Noe/dbpedia-spotlight-model
        mv dbpedia-spotlight-model dbpedia-spotlight
        cd dbpedia-spotlight
        mvn -T 1C -q -Dhttps.protocols=TLSv1.2 install
    fi

########################################################################################################
# Building Spotlight model:
########################################################################################################

    echo "Building spotlight model" >> /data/model-quickstarter-fork/debug.txt
    date -u >> /data/model-quickstarter-fork/debug.txt
    #Create the model:
    cd "$BASE_WDIR/dbpedia-spotlight"

    #mvn -Dhttps.protocols=TLSv1.2 install

    mvn -pl index exec:java -Dexec.cleanupDaemonThreads=false -Dexec.mainClass=org.dbpedia.spotlight.db.CreateSpotlightModel -Dexec.args="$LOCALE $WDIR $TARGET_DIR $opennlp $STOPWORDS $STEMMER" -X -e

    if [ "$eval" == "true" ]; then
      mvn -pl eval exec:java -Dexec.mainClass=org.dbpedia.spotlight.evaluation.EvaluateSpotlightModel -Dexec.args="$TARGET_DIR $WDIR/heldout.txt" > "$TARGET_DIR/evaluation.txt"
    fi

#    curl https://raw.githubusercontent.com/dbpedia-spotlight/model-quickstarter/master/model_readme.txt > $TARGET_DIR/README.txt
#    curl "$WIKI_MIRROR/${LANGUAGE}wiki/latest/${LANGUAGE}wiki-latest-pages-articles.xml.bz2-rss.xml" | grep link | sed -e 's/^.*<link>//' -e 's/<[/]link>.*$//' | uniq >> $TARGET_DIR/README.txt

done

rm -r $WDIR

set +e
