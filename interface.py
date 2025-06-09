from neo4j import GraphDatabase

class Interface:
    def __init__(self, uri, user, password):
        self._driver = GraphDatabase.driver(uri, auth=(user, password), encrypted=False)
        self._driver.verify_connectivity()

    def close(self):
        self._driver.close()

    def bfs(self, start_node, last_node):
        with self._driver.session() as session:
            try:
                
                session.run("CALL gds.graph.drop('trip-graph', false) YIELD graphName AS ignore")

                
                session.run("""
                    CALL gds.graph.project(
                        'trip-graph',
                        'Location',
                        'TRIP',
                        { nodeProperties: ['name'] }
                    )
                """)

                
                query = """
                    MATCH (n:Location)
                    WHERE n.name IN [$start, $end]
                    CALL (n) {
                        WITH n
                        CALL gds.graph.nodeProperty.stream('trip-graph', 'name')
                        YIELD nodeId, propertyValue
                        WHERE propertyValue = n.name
                        RETURN nodeId LIMIT 1
                    }
                    RETURN n.name AS name, nodeId
                """
                nodes = session.run(query, start=start_node, end=last_node).data()
                
                if len(nodes) != 2:
                    return []

                # Extract the internal numeric IDs for the start and end nodes
                start_id = next(node['nodeId'] for node in nodes if node['name'] == start_node)
                end_id = next(node['nodeId'] for node in nodes if node['name'] == last_node)

                # Run BFS with the numeric IDs
                result = session.run("""
                    CALL gds.bfs.stream('trip-graph', {
                        sourceNode: $start_id,
                        targetNodes: [$end_id],
                        relationshipWeightProperty: null
                    })
                    YIELD path
                    RETURN path
                    LIMIT 1
                """, start_id=start_id, end_id=end_id)

                record = result.single()
                if not record or not record.get("path"):
                    return []

                path = record["path"]
                nodes = path.nodes

                if len(nodes) < 2:
                    return []

                # names of all nodes in the path
                path_nodes = []
                for node in nodes:
                    node_name = session.run("""
                        MATCH (n) WHERE elementId(n) = $element_id
                        RETURN n.name AS name
                    """, element_id=node.element_id).single()["name"]
                    path_nodes.append({'name': node_name})

                return [{'path': path_nodes}] if path_nodes else []

            except Exception as e:
                print(f"BFS Error: {str(e)}")
                return []

    def pagerank(self, max_iterations, weight_property):
        with self._driver.session() as session:
            try:
                
                session.run("CALL gds.graph.drop('trip-graph', false) YIELD graphName AS ignore")

                
                session.run(f"""
                    CALL gds.graph.project(
                        'trip-graph',
                        'Location',
                        {{
                            TRIP: {{
                                orientation: 'NATURAL',
                                properties: {{
                                    {weight_property}: {{defaultValue: 1.0}}
                                }}
                            }}
                        }}
                    )
                """)

                # Run PR algo
                result = session.run(f"""
                    CALL gds.pageRank.stream('trip-graph', {{
                        maxIterations: {max_iterations},
                        dampingFactor: 0.85,
                        relationshipWeightProperty: '{weight_property}'
                    }})
                    YIELD nodeId, score
                    RETURN gds.util.asNode(nodeId).name AS name, score
                    ORDER BY score DESC
                """)

                scores = result.data()
                if len(scores) < 2:
                    return []

                return [
                    {'name': int(scores[0]['name']), 'score': scores[0]['score']},
                    {'name': int(scores[-1]['name']), 'score': scores[-1]['score']}
                ]

            except Exception as e:
                print(f"PageRank Error: {str(e)}")
                return []