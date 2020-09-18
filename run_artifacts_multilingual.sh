#!/bin/bash
#+------------------------------------------------------------------------------------------------------------------------------+
#| DBpedia Spotlight - Create database-backed model                                                                             |
#| @author Joachim Daiber                                                                                                       |
#+------------------------------------------------------------------------------------------------------------------------------+

export LC_ALL=en_US.UTF-8
export MAVEN_OPTS="-Xmx26G"

#StringLanguages="en_US-English de_DE-German nl_NL-Dutch sv_SE-Swedish pt_BR-Portuguese fr_FR-French es_ES-Spanish tr_TR-Turkish no_NO-Norwegian it_IT-Italian da_DK-Danish ja_JP-None cs_CZ-None hu_HU-Hungarian ru_RU-Russian zh_CN-None"
StringLanguages="cs_CZ-None hu_HU-Hungarian ru_RU-Russian zh_CN-None pt_BR-Portuguese ja_JP-None"
#StringLanguages="sv_SE-Swedish tr_TR-Turkish no_NO-Norwegian da_DK-Danish hu_HU-Hungarian"
#StringLanguages="en_US-English de_DE-German fr_FR-French"
#StringLanguages="en_US-English de_DE-German fr_FR-French"
#StringLanguages="zh_CN-None"

opennlp="None"
eval="false"
blacklist="false"

BASE_DIR=$(pwd)
#cd $BASE_DIR && cd ..
#BASE_DIR=$(pwd)

BASE_WDIR=$BASE_DIR/wdir
BASE_ARTIFACTDIR=$BASE_DIR/spotlight

#Iteration
for lang in $StringLanguages; do
     echo $lang
     LANGUAGE=`echo $lang | sed "s/_.*//g"`
     STEMMER=`echo $lang | sed "s/.*-//g"`
    if [[ "$STEMMER" != "None" ]]; then
        STEMMER="$STEMMER""Stemmer"
    fi

      LOCALE=`echo $lang | sed "s/-.*//g"`
    echo "Language: $LANGUAGE"
    echo "Stemmer: $STEMMER"
    echo "Locale: $LOCALE"

    TARGET_DIR="$BASE_DIR/models/$LANGUAGE"
    WDIR="$BASE_WDIR/$LOCALE"
    ARTIFACT_VERSION="2020.03.11"

    echo "Working directory: $WDIR"

    STOPWORDS="$BASE_DIR/$LANGUAGE/stopwords.list"

    if [[ -f "$LANGUAGE/ignore.list" ]]; then
         blacklist="$BASE_DIR/$LANGUAGE/ignore.list"
    else
         blacklist="None"
    fi

    mkdir -p $WDIR

########################################################################################################
# Preparing the data.
########################################################################################################

    echo "Loading Wikipedia dump..."
    if [ -z "$WIKI_MIRROR" ]; then
      WIKI_MIRROR="https://dumps.wikimedia.org/"
    fi

    WP_DOWNLOAD_FILE=$WDIR/dump.xml
    echo Checking for wikipedia dump at $WP_DOWNLOAD_FILE
    if [ -f "$WP_DOWNLOAD_FILE" ]; then
      echo File exists.
    else
      echo Downloading wikipedia dump.
      if [ "$eval" == "false" ]; then
	cd $WDIR
        curl -O "$WIKI_MIRROR/${LANGUAGE}wiki/latest/${LANGUAGE}wiki-latest-pages-articles.xml.bz2" 
	mv ${LANGUAGE}wiki-latest-pages-articles.xml.bz2 dump.xml.bz2
      else
        curl -# "$WIKI_MIRROR/${LANGUAGE}wiki/latest/${LANGUAGE}wiki-latest-pages-articles.xml.bz2" | bzcat | python $BASE_DIR/scripts/split_train_test.py 1200 $WDIR/heldout.txt > $WDIR/dump.xml
      fi
    fi

    cd $WDIR
    cp $STOPWORDS stopwords.$LANGUAGE.list

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
    "
    cd $BASE_WDIR

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

    # Download
    TMPDOWN="dump-tmp-download"
    mkdir $TMPDOWN
    cd $TMPDOWN
    for i in $RESULT
      do
          wget $i
          ls
          echo $TMPDOWN
          pwd
      done

    echo "decompressing"
    ALLFINE=true
    MISSING_ARTIFACTS=""

    for f in "instance-types"*; do
      # [ -e "$f" ] && bzcat -v $TMPDOWN/instance-types*.ttl.bz2 > $WDIR/instance_types.nt || touch $WDIR/instance_types.nt
       if [ -e "$f" ]; then
            bzcat -v instance-types*.ttl.bz2 > $WDIR/instance_types.nt
       else
            ALLFINE=false
            MISSING_ARTIFACTS="instance-types"
       fi
       break
    done

    for f in "disambiguations"*; do
       if [ -e "$f" ]; then
            bzcat -v disambiguations*.ttl.bz2 > $WDIR/disambiguations.nt
       else
            ALLFINE=false
            MISSING_ARTIFACTS=$MISSING_ARTIFACTS" disambiguations"
       fi
       break
   done

    for f in "redirects"*; do
       if [ -e "$f" ]; then
            bzcat -v redirects*.ttl.bz2 > $WDIR/redirects.nt
       else
           ALLFINE=false
           MISSING_ARTIFACTS=$MISSING_ARTIFACTS" redirects"
       fi
       break
   done

    # clean
    cd ..
    rm -r $TMPDOWN

   if [ ! $ALLFINE ]; then
        echo "##########################################################################################################"
        echo "######Artifact(s) ("$MISSING_ARTIFACTS") missing, for more details about this please refer to https://forum.dbpedia.org/t/tasks-for-volunteers/163, task: 'Languages with missing redirects/disambiguations/instance-type'"
        echo "##########################################################################################################"
        echo $LOCALE >> $BASE_DIR/missingArtifacts.txt
        continue
   fi

########################################################################################################
# Extracting wiki stats:
########################################################################################################

    cd $BASE_WDIR
    rm -Rf wikistatsextractor
#    git clone --depth 1 https://github.com/dbpedia-spotlight/wikistatsextractor
    git clone --depth 1 https://github.com/Julio-Noe/wikistatsextractor

    # Stop processing if one step fails
    set -e

    #Copy results to local:
    cd $BASE_WDIR/wikistatsextractor

    echo "MVN ARGUMENTS --output_folder $WDIR $LANGUAGE $3 $5Stemmer $WDIR/dump.xml $WDIR/stopwords.$LANGUAGE.list"

    mvn install exec:java -Dexec.args="--output_folder $WDIR $LANGUAGE $LOCALE $STEMMER $WDIR/dump.xml.bz2 $WDIR/stopwords.$LANGUAGE.list" -X

    if [ "$blacklist" != "None" ]; then
      echo "Removing blacklist URLs..."
      mv $WDIR/uriCounts $WDIR/uriCounts_all
      grep -v -f $blacklist $WDIR/uriCounts_all > $WDIR/uriCounts
    fi

    echo "Finished wikistats extraction. Cleaning up..."
    rm -f $WDIR/dump.xml

done
echo "#####ALL LANGUAGES DONE######"
set +e
