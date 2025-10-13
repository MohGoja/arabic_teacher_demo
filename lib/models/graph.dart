class GraphContent {
  final String root;
  final List<GraphNode> nodes;

  GraphContent({required this.root, required this.nodes});

  factory GraphContent.fromJson(Map<String, dynamic> json) {
    return GraphContent(
      root: json['root'],
      nodes: (json['nodes'] as List).map((n) => GraphNode.fromJson(n)).toList(),
    );
  }
}

class GraphNode {
  final String label;
  final List<GraphNode> children;

  GraphNode({required this.label, required this.children});

  factory GraphNode.fromJson(Map<String, dynamic> json) {
    return GraphNode(
      label: json['label'],
      children:
          (json['children'] as List? ?? []).map((child) {
            // Handle both string children and object children
            if (child is String) {
              // If child is a string, create a GraphNode with that string as label
              return GraphNode(label: child, children: []);
            } else if (child is Map<String, dynamic>) {
              // If child is an object, parse it as a GraphNode
              return GraphNode.fromJson(child);
            } else {
              // Fallback for unexpected types
              return GraphNode(label: child.toString(), children: []);
            }
          }).toList(),
    );
  }
}
