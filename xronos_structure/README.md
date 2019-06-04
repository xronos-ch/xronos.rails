# xronos database structure models

The database was 

1. ... modelled with an Entity Relationship (ER) diagram: **xronos_erd.dia**. (This file can be opened and edited with the diagram editor software [Dia](http://dia-installer.de/).)  

2. ... and then manually translated to a relational ("table") model structure: **xronos_rdm.mwb**. (This file can be opened and edited with the database management tool [MySQL Workbench](https://www.mysql.com/products/workbench/).) 

## The Entity Relationship diagram

![](xronos_erd.png)

### How to read it

**Shapes**

- Boxes: Each box represents an entity. An entity is a class of objects in the real world that can be described with a set of attributes. All entities will become tables in database.
- Diamonds: Each diamond represents a relationship. Relationships describe the interaction of entities. Some relationships will become tables in the database, others won't. That depends on the nature of the relationship.
- Lines: Lines connect entities and relationships. Each line has a label to describe
- Arrows: 
