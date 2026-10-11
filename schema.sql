CREATE TABLE ressources (
    id_ressource INTEGER not null PRIMARY KEY,
    nom VARCHAR(50) NOT NULL unique,
    unite VARCHAR(20) NOT NULL
);

CREATE TABLE categories_batiments (
    id_categorie INTEGER not null PRIMARY KEY,
    nom VARCHAR(50) NOT NULL,
    id_parent INTEGER REFERENCES categories_batiments(id_categorie)
);

CREATE TABLE batiments (
    id_batiment INTEGER not null PRIMARY KEY,
    nom VARCHAR(50) NOT NULL,
    niveau INTEGER not null check (niveau > 0),
    id_categorie INTEGER not null REFERENCES categories_batiments(id_categorie)
);

CREATE TABLE evenements_production (
    id_evenement INTEGER not null PRIMARY KEY,
    id_batiment INTEGER not null REFERENCES batiments(id_batiment),
    id_ressource INTEGER not null REFERENCES ressources(id_ressource),
    date_evenement TIMESTAMP NOT NULL,  
    quantite NUMERIC NOT NULL Check (quantite > 0)
);