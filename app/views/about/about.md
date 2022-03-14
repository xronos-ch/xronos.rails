# What is XRONOS?

XRONOS is an open repository and curation platform for chronometric data from archaeological contexts worldwide.
It aims to compile the full range of radiocarbon, dendro-, and other chronological information from the archaeological record and make it available in a single [FAIR](https://www.go-fair.org/fair-principles/) and open access database.
There are no spatial and temporal restrictions on data included in XRONOS, though the current state of the database is limited by the availability of source datasets and our progress in incorporating them.

## Open data

XRONOS follows the [open definition](https://opendefinition.org/) and aims to make scientific data able to be "freely used, modified, and shared by anyone for any purpose".

You can access, query and download XRONOS data through the web frontend at <https://xronos.ch> or programmatically through our [JSON API](https://xronos.ch/api).
We also maintain an [R package](https://github.com/xronos-ch/xronos.R) that interfaces with the API directly.

We recognise that there are sometimes practical and ethical limits on how openly archaeological data can be shared.
While advocating for maximal openness, XRONOS endeavours to respect good data-sharing practices in the profession, for example by obscuring the exact location of sites where this is customary.
Individual contributors retain full control over their data and its licensing, and we are working on tools for secure management of non-public datasets.

## Transparency

Data in XRONOS comes from a variety of sources, including other databases, published compilations, and original literature.
We rely on [individual contributors and maintainers](/about/acknowledgements) of regional databases for the most of our data. 
XRONOS' technical infrastructure allows for continuous ingestion and updating of this data as new information is published and compiled.

Wherever possible, bibliographic references to the original publication of the data are included in individual records.
The "version history" of each record also tracks the immediate source of data imported into XRONOS and any subsequent changes by our automated quality control systems or data curators.

If you are interested in contributing data or helping us to improve XRONOS, please [get in touch](/about/contact).

## Data curation & analysis

XRONOS is more than just a data repository: its web frontend includes a growing number of tools for data curation and analysis.

Search options allow the selection of dates by temporal, spatial, and/or contextual constraints.
For radiocarbon dates, single and summed calibrations are currently supported, while further analytical functions shall be included later on.
Dendrological information is currently only complied in the form of fell-phases, with the prospect of collecting individual measurements in the future. 

## Open source

XRONOS is an open source project. 
You can find the source code of XRONOS-related projects in our [GitHub repositories](https://github.com/xronos-ch).
The XRONOS frontend (the website you are reading) is a [Ruby on Rails](https://rubyonrails.org/) application with source code available at <https://github.com/xronos-ch/xronos.rails>.
