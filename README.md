Quickstarter for DBpedia Spotlight models
===================================================

[![Gitter](https://badges.gitter.im/dbpedia-spotlight/model-quickstarter.svg)](https://gitter.im/dbpedia-spotlight/model-quickstarter?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge)

## Update, February 2020

The [redirects](https://databus.dbpedia.org/dbpedia/generic/redirects/), [disambiguations](https://databus.dbpedia.org/dbpedia/generic/disambiguations/), and [instance-types](https://databus.dbpedia.org/dbpedia/mappings/instance-types/) are downloaded from DBpedia Databus.

## Update, January 2016

This tool now uses the wikistatsextractor by the great folks over at [DiffBot](https://www.diffbot.com/). This means: no more Hadoop and Pig! Running the biggest model (English) takes around 2h on a single machine with around 32GB of RAM. We recommend running this script on an SSD with around 100GB of free space.

### Requirements

- Git
- Maven 3

## Spotlight model creation

In the command line run `./mainModelBuilder.sh`. It will generate the model for the English language. If you want to create a model for any other language, update the variable `StringLanguages`.

## Datasets

You can find pre-built datasets created using the model-quickstarter [here](https://databus.dbpedia.org/dbpedia/spotlight/spotlight-model).

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
