# xronos database structure models

The database was 

1. ... modelled with an Entity Relationship (ER) diagram: **xronos_erd.dia**. (This file can be opened and edited with the diagram editor software [Dia](http://dia-installer.de/).)  

2. ... and then manually translated to a relational ("table") model structure: **xronos_rdm.mwb**. (This file can be opened and edited with the database management tool [MySQL Workbench](https://www.mysql.com/products/workbench/).) 

## The Entity Relationship diagram

![](xronos_erd.png)

### How to read it

*the examples are not necessarily taken from this ER chart*

- Boxes: Entity. An entity is a class of objects in the real world (e.g. *archaeological sites*) that can be described with a set of attributes (e.g. *name, number of documented houses, spatial position*). All entities will become tables in database.
- Diamonds: Relationship. Relationships describe the relations and interaction of entities (e.g. the *radiocarbon laboratory* is linked to the *sample* via the process of *measurement*). Some relationships have additional arguments (the *measurement* produces a *labnr*, happens at a certain *time* and has a specific *price* tag). Some relationships will become tables in the database, others won't. That depends on the nature of the relationship.
- Lines: Lines connect entities and relationships. Each line has a label to describe the amount of objects within an entity that can or have to be part of that relationship. Some examples: *(0,\*)*: Zero or many objects can be part of that that relationship. *(1,1)*: Exactly one object can be part of that relationship. That also implies that each object has to have exactly one partner in this specific relationship. *(0,1)*: Each object linked to the relationship has zero or one partner within the other linked entity. 
- Arrows: Is-a-hierarchy. Entities from which an arrow emanates are subcategories of the linked entity. They share the same set of attributes, but also some special, additional ones.

### Domain specific comments

Colours are used to distinguish semantic areas/domains within the ER diagram.

1. *(White)* Archaeological objects, samples and measurements: An object is the archaeological object documented in the field. This can be an artefact (e.g. a bone needle), an architectural element (e.g. a waterlogged post) or another kind of remain (e.g. a human bone). Sometimes we do not know much about this object (e.g. in case of a soil sample). Then the object is a purely imaginative concept. From each object multiple dating samples can be extracted. In fact we only store objects where at least one sample was extracted. One sample can be measured one or multiple times by one or multiple laboratories. Measurements therefore are a complex, lifted relationship between samples and the laboratories. Each measurement is either an c14 measurement or a dendro measurement. Depending on this attribution two very different sets of variables apply.
2. *(Blue)* Literature/References: Certain (archaeologically relevant) entities can be linked to an arbitrary amount of references (literature). References are only represented by a bibtex string.
3. *(Pink)* Phases and archaelogical cultures: Each object can be attributed to zero or many archaeological phases or cultures. Each phase and culture can be linked to zero or many cultures or phases by coexistence and hierarchy.
4. *(Yellow)* Archaeological sites: Each object stems from exactly one site and each site can be within zero or many countries.
5. *(Dark)* yellow: On the site positions: Each object can have zero or many precise position indicators on a site (e.g. coordinates in a local reference system, feature name).
6. *(Grey)* Archaeological categorization of sites and features: Each site can have zero or one site type definitions (e.g. settlement, burial site, cave). Each on site object position can be linked to zero or one feature types (e.g. burial, pit, Schlitzgrube)
7 *(Purple)* Laboratories: See 1.
8. *(Brown)* Specific information for C14: ...
9. *(Green)* Specific information for Dendrodating: ...
10. *(Blue)* User management: ...
