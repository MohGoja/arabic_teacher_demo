// lib/models/tree_node.dart
import 'package:flutter/widgets.dart';

/// Simple data model for a node in the tree.
class TreeNode {
  /// Unique id used to control/show nodes.
  final String id;

  /// Widget content of the node (card).
  final Widget content;

  /// Optional children for future extension (not used in single-level sample).
  final List<TreeNode> children;

  TreeNode({required this.id, required this.content, this.children = const []});
}
