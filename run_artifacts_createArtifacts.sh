#!/bin/bash
#+------------------------------------------------------------------------------------------------------------------------------+
#| DBpedia Spotlight - Create database-backed model                                                                             |
#| @author Joachim Daiber                                                                                                       |
#+------------------------------------------------------------------------------------------------------------------------------+

export LC_ALL=en_US.UTF-8
export MAVEN_OPTS="-Xmx32G"

#StringLanguages="en_US-English de_DE-German nl_NL-Dutch sv_SE-Swedish pt_BR-Portuguese fr_FR-French es_ES-Spanish tr_TR-Turkish no_NO-Norwegian it_IT-Italian da_DK-Danish ja_JP-None cs_CZ-None hu_HU-Hungarian ru_RU-Russian zh_CN-None"
StringLanguages="en_US-English de_DE-German nl_NL-Dutch sv_SE-Swedish pt_BR-Portuguese fr_FR-French es_ES-Spanish tr_TR-Turkish no_NO-Norwegian it_IT-Italian da_DK-Danish ja_JP-None cs_CZ-None hu_HU-Hungarian ru_RU-Russian"
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
    ARTIFACT_VERSION="2020.09.17"

    echo "Working directory: $WDIR"

    STOPWORDS="$BASE_DIR/$LANGUAGE/stopwords.list"

    if [[ -f "$LANGUAGE/ignore.list" ]]; then
         blacklist="$BASE_DIR/$LANGUAGE/ignore.list"
    else
         blacklist="None"
    fi

########################################################################################################
# Generating artifacts
########################################################################################################

 set -e

     MODEL_DIR="spotlight-model"
     WIKISTAT_DIR="spotlight-wikistats"
     #DERIVE_DATE=$(date +%F | sed 's/-/\./g')
     DERIVE_DATE="2020.09.17"

     #compressing model files
     cd "$BASE_DIR/models"
     echo $(pwd)
     if [[ ! -f "spotlight-model_lang=$LANGUAGE.tar.gz" ]]; then
        #cd $TARGET_DIR/..
        echo $(pwd)
        echo tar -cvzf $BASE_ARTIFACTDIR/$MODEL_DIR/$ARTIFACT_VERSION/spotlight-model_lang\=$LANGUAGE.tar.gz "$LANGUAGE" && echo "$LANGUAGE"
             tar -cvzf spotlight-model_lang\=$LANGUAGE.tar.gz "$LANGUAGE" && rm -r $LANGUAGE
     else
             cd "$BASE_DIR/models"
     fi
     #Creating the symbolic link
     mkdir -p $BASE_ARTIFACTDIR/$MODEL_DIR/$ARTIFACT_VERSION/
     ln -s "$(pwd)/spotlight-model_lang=$LANGUAGE.tar.gz" "$BASE_ARTIFACTDIR/$MODEL_DIR/$ARTIFACT_VERSION/spotlight-model_lang=$LANGUAGE.tar.gz"
     echo "Sybolic link created for language $LANGUAGE"

     #compressing wikistats files
     cd $WDIR
     bzip2 -zk *Counts && echo "bzip finished"
      #rename "s/^/spotlight-wikistats_type=/" *Counts.bz2 && rename "s/Counts.bz2/Counts_lang=$LANGUAGE.tsv.bz2/" * && mv *tsv.bz2 $BASE_ARTIFACTDIR/$WIKISTAT_DIR/$ARTIFACT_VERSION/
      rename "s/^/spotlight-wikistats_type=/" *Counts.bz2 && rename "s/Counts.bz2/Counts_lang=$LANGUAGE.tsv.bz2/" * && echo "process finished" 

      #find . -name "*Counts.tsv" | tar -cvzf $ARTIFACT_DIR/$WIKISTAT_DIR/$DERIVE_DATE/spotlight-wikistat_lang\=$LANGUAGE.tar.gz --files-from - && echo "wikistats are done"

      ########################################################################################################
      # Moving files
      ########################################################################################################

      #echo "Collecting data..."
      cd $BASE_DIR
      mkdir -p data/$LANGUAGE && mv $WDIR/*tsv.bz2 data/$LANGUAGE
      if [[ ! -d "$BASE_ARTIFACTDIR/$WIKISTAT_DIR/$ARTIFACT_VERSION" ]]
      then
	      mkdir -p "$BASE_ARTIFACTDIR/$WIKISTAT_DIR/$ARTIFACT_VERSION"
      fi
      for FILE in $(ls data/$LANGUAGE/); do
	      echo ln -s "$FILE" "$BASE_ARTIFACTDIR/$WIKISTAT_DIR/$ARTIFACT_VERSION/$FILE"
	      ln -s "$BASE_DIR/data/$LANGUAGE/$FILE" "$BASE_ARTIFACTDIR/$WIKISTAT_DIR/$ARTIFACT_VERSION/$FILE"
      done
      #gzip $WDIR/*.nt &
      #rm -r $WDIR
 done
 set +e
