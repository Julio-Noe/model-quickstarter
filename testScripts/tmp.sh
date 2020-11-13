#!/bin/bash

#cd spotlight

#chown -R extractor:extractor /data/model-quickstarter-fork/
#su - extractor -c 'cd /data/model-quickstarter-fork/spotlight && mvn validate && mvn deploy -X -e -T 10 2>&1 | tee deployRoot.txt'
#artifactID=$(date +%Y.%m.%d)
#echo $artifactID

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
              ?distribution dataid:contentVariant 'en'^^xsd:string .
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
#    echo "QUERY = $QUERY"
#    echo "RESULT = $RESULT"
    # Download
    for i in $RESULT
      do
          echo "$i"
      done

