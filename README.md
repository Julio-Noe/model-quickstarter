Quickstarter for DBpedia Spotlight models
===================================================

[![Gitter](https://badges.gitter.im/dbpedia-spotlight/model-quickstarter.svg)](https://gitter.im/dbpedia-spotlight/model-quickstarter?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge)

## Update, February 2020

The DBpedia-Spotlight server downloads the most recent language models from the [DBpedia Databus](https://databus.dbpedia.org/dbpedia/spotlight/spotlight-model/). The language models are build with the latest version of [redirects](https://databus.dbpedia.org/dbpedia/generic/redirects/), [disambiguations](https://databus.dbpedia.org/dbpedia/generic/disambiguations/), and [instance-types](https://databus.dbpedia.org/dbpedia/mappings/instance-types/) artifacts, downloaded from the DBpedia Databus. 

## Update, January 2016

This tool now uses the wikistatsextractor by the great folks over at [DiffBot](https://www.diffbot.com/). This means: no more Hadoop and Pig! Running the biggest model (English) takes around 2h on a single machine with around 32GB of RAM. We recommend running this script on an SSD with around 100GB of free space.

### Requirements

- Git
- Maven 3

## Spotlight model creation

In the command line run the following command:

```./mainModelBuilder.sh LANG_LOC-Stemmer ```

where LANG is the two digits language code, LOC is the two digits locator code, and Stemmer is the Snowball stemmer algorithm. The language and locator codes correspondes to the [BCP47](https://tools.ietf.org/html/bcp47) documentation. If the stemmer algorithm is not available the _None_ string must be used, e.g., ja_JP-None for the Japanese language. 

## Datasets

You can find pre-built language models in the [DBpedia Databus](https://databus.dbpedia.org/dbpedia/spotlight/spotlight-model). 

## Contribution

The [DBpedia forum](https://forum.dbpedia.org/t/dbpedia-spotlight-how-to-help-improve-quality-of-multilingual-entity-extraction/785) describes some tasks needed to improve the language model building process. The main idea is to add more language models and/or improve the available models. 

## Citation

If you use the current (statistical version) of DBpedia Spotlight or the data/models created using this repository, please cite the following paper.

```bibtex
@inproceedings{isem2013daiber,
  title = {Improving Efficiency and Accuracy in Multilingual Entity Extraction},
  author = {Joachim Daiber and Max Jakob and Chris Hokamp and Pablo N. Mendes},
  year = {2013},
  booktitle = {Proceedings of the 9th International Conference on Semantic Systems (I-Semantics)}
}
```
