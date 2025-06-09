# Base image specification using Ubuntu 22.04 LTS for updated software availability
FROM ubuntu:22.04

# Environment variables to handle the build process without interactive prompts
ARG TARGETPLATFORM=linux/amd64,linux/arm64
ARG DEBIAN_FRONTEND=noninteractive

# Install required system packages and add the Neo4j repository for package installation
RUN apt-get update && \
    apt-get install -y wget gnupg software-properties-common && \
    wget -O - https://debian.neo4j.com/neotechnology.gpg.key | apt-key add - && \
    echo 'deb https://debian.neo4j.com stable 4.4' > /etc/apt/sources.list.d/neo4j.list && \
    add-apt-repository universe && \
    apt-get update && \
    apt-get install -y nano unzip neo4j python3-pip git && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Prepare directory and download the dataset for March 2022 from the NYC Taxi Trips dataset
RUN mkdir -p /cse511 && \
    cd /cse511 && \
    wget https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2022-03.parquet && \
    cp /cse511/yellow_tripdata_2022-03.parquet /var/lib/neo4j/import/

# Clone project repository from GitHub using a personal access token and set up the necessary scripts
RUN git clone https://narottaman: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@github.com/SP-2025-CSE511-Data-Processing-at-Scale/Project-1-ngangada.git /tmp/repo && \
    cp /tmp/repo/data_loader.py /cse511/ && \
    cp -r /tmp/repo/data_loader.py /var/lib/neo4j/import/ && \
    rm -rf /tmp/repo

# Ensure the latest version of pip is installed and install required Python libraries for data handling
RUN pip3 install --upgrade pip && \
    pip3 install neo4j pandas pyarrow

# Modify Neo4j configuration files to enhance security, performance, and functionality
RUN sed -i 's/#dbms.default_listen_address=0.0.0.0/dbms.default_listen_address=0.0.0.0/' /etc/neo4j/neo4j.conf && \
    sed -i 's/#dbms.connector.bolt.listen_address=:7687/dbms.connector.bolt.listen_address=:7687/' /etc/neo4j/neo4j.conf && \
    sed -i 's/#dbms.connector.http.listen_address=:7474/dbms.connector.http.listen_address=:7474/' /etc/neo4j/neo4j.conf && \
    echo 'dbms.security.procedures.unrestricted=gds.*,apoc.*' >> /etc/neo4j/neo4j.conf && \
    echo 'dbms.security.procedures.allowlist=gds.*,apoc.*' >> /etc/neo4j/neo4j.conf && \
    echo 'dbms.memory.heap.initial_size=512m' >> /etc/neo4j/neo4j.conf && \
    echo 'dbms.memory.heap.max_size=1g' >> /etc/neo4j/neo4j.conf && \
    neo4j-admin set-initial-password project1phase1

# Download the Graph Data Science plugin compatible with Neo4j 4.4
RUN wget -q https://graphdatascience.ninja/neo4j-graph-data-science-2.1.0.jar -P /var/lib/neo4j/plugins/

# Create a bash script to manage the initialization and operation of Neo4j with custom wait times
RUN echo '#!/bin/bash\necho "Initializing Neo4j..."\nneo4j start\necho "Pausing to ensure Neo4j is ready (120 seconds)..."\
nsleep 120\necho "Executing data_loader.py..."\ncd /cse511\npython3 data_loader.py\necho "Data processing completed. Neo4j remains active."\ntail -f /dev/null' > /start-neo4j-and-load.sh && \
    chmod +x /start-neo4j-and-load.sh

# Open Neo4j ports for external access
EXPOSE 7474 7687

# Define the command to run the custom startup script
CMD ["/start-neo4j-and-load.sh"]
