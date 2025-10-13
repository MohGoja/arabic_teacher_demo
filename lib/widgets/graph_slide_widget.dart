import 'package:flutter/material.dart';
import '../models/graph.dart';

class GraphSlideWidget extends StatelessWidget {
  final GraphContent graph;
  final String title;

  const GraphSlideWidget({super.key, required this.graph, required this.title});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            // Text(
            //   graph.root,
            //   style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            // ),
            const Divider(),
            // Wrap(
            //   spacing: 16,
            //   runSpacing: 8,
            //   alignment: WrapAlignment.center,
            //   children:
            //       graph.nodes.map((node) {
            //         return Chip(label: Text(node.label));
            //       }).toList(),
            // ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children:
                  graph.nodes.map((node) {
                    return Column(
                      children: [
                        Chip(label: Text(node.label)), // first chip is fine
                        if (node.children.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            margin: const EdgeInsets.only(top: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(node.children[0].label, softWrap: true),
                          ),
                      ],
                    );
                  }).toList(),
            ),

            // Column(
            //   spacing: 16,
            //   mainAxisAlignment: MainAxisAlignment.center,
            //   children:
            //       graph.nodes.map((node) {
            //         return Chip(label: Text(node.label));
            //       }).toList(),
            // ),
          ],
        ),
      ),
    );
  }
}
