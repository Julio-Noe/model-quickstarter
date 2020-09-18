#!/bin/bash
#+------------------------------------------------------------------------------------------------------------------------------+
#| DBpedia Spotlight - Create database-backed model                                                                             |
#| @author Joachim Daiber                                                                                                       |
#+------------------------------------------------------------------------------------------------------------------------------+

export LC_ALL=en_US.UTF-8
export MAVEN_OPTS="-Xmx32G"

#StringLanguages="en_US-English de_DE-German nl_NL-Dutch sv_SE-Swedish pt_BR-Portuguese fr_FR-French es_ES-Spanish tr_TR-Turkish no_NO-Norwegian it_IT-Italian da_DK-Danish ja_JP-None cs_CZ-None hu_HU-Hungarian ru_RU-Russian zh_CN-None"
StringLanguages="zh_CN-None"
#StringLanguages="sv_SE-Swedish tr_TR-Turkish no_NO-Norwegian da_DK-Danish hu_HU-Hungarian"
#StringLanguages="en_US-English"
#StringLanguages="de_DE-German"

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
# Setting up Spotlight:
########################################################################################################

    cd $BASE_WDIR

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

    #Create the model:
    cd $BASE_WDIR/dbpedia-spotlight

    #mvn -Dhttps.protocols=TLSv1.2 install

    mvn -pl index exec:java -Dexec.cleanupDaemonThreads=false -Dexec.mainClass=org.dbpedia.spotlight.db.CreateSpotlightModel -Dexec.args="$LOCALE $WDIR $TARGET_DIR $opennlp $STOPWORDS $STEMMER" -X

    if [ "$eval" == "true" ]; then
      mvn -pl eval exec:java -Dexec.mainClass=org.dbpedia.spotlight.evaluation.EvaluateSpotlightModel -Dexec.args="$TARGET_DIR $WDIR/heldout.txt" > $TARGET_DIR/evaluation.txt
    fi

#    curl https://raw.githubusercontent.com/dbpedia-spotlight/model-quickstarter/master/model_readme.txt > $TARGET_DIR/README.txt
#    curl "$WIKI_MIRROR/${LANGUAGE}wiki/latest/${LANGUAGE}wiki-latest-pages-articles.xml.bz2-rss.xml" | grep link | sed -e 's/^.*<link>//' -e 's/<[/]link>.*$//' | uniq >> $TARGET_DIR/README.txt

done

#set +e
