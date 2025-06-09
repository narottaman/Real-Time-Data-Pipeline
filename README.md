# Project-1-ngangada

# Neo4j Data Project Setup Guide

This README provides comprehensive instructions on how to build and run a Docker container that sets up a Neo4j database, imports and transforms NYC Yellow Taxi trip data from Parquet to CSV format, and then loads it into Neo4j. It also includes steps to verify that the data transformation and loading processes were successful.

## Prerequisites

- **Docker**: Ensure Docker is installed on your machine. For installation instructions, refer to [Docker's official installation guide](https://docs.docker.com/get-docker/).
- **Command-line knowledge**: Familiarity with basic command-line operations is assumed.

## Building the Docker Image

To construct the Docker image, navigate to the directory containing the Dockerfile and execute the following command:

```bash
docker build --no-cache -t neo4jdataproject .
```

This command constructs a Docker image named neo4j_data_project based on the Dockerfile's specifications, which include setting up the necessary environment, installing dependencies, and preparing the data.

##Running the Docker Container
To run the Docker container while mapping Neo4j's ports to your local machine, use the command below:

```bash
docker run -p 7474:7474 -p 7687:7687  --name neo4j-container neo4jdataproject
```

##Operations Inside the Container
Neo4j Server Initialization: Upon starting, the Neo4j server is configured to accept connections.

Data Loader Execution: A Python script (data_loader.py) is automatically run to transform data from Parquet to CSV format and load it into the Neo4j database.

Service Continuation: The container remains active, allowing ongoing access to the Neo4j database through localhost:7474.


##Verifying Data Conversion and Loading
Ensure the data has been correctly converted and loaded by following these steps:

Accessing the Neo4j Browser:

Open a browser and go to http://localhost:7474.

Use the default credentials (or your configured credentials) to log in.

Executing Cypher Queries:

Check the creation of nodes and relationships:

```cypher
MATCH (n) RETURN n LIMIT 10;


MATCH (n) RETURN count(n) AS TotalNodes;
MATCH ()-[r]->() RETURN count(r) AS TotalRelationships;
```

##Inspecting the CSV File:

Access the Docker container's shell:
```
docker exec -it [container_id] bash
```
Navigate to the Neo4j import directory and list the files:
```
cd /var/lib/neo4j/import/
ls
```


