// // lib/main.dart
// import 'package:arabic_teacher_demo/widgets/lesson_card.dart';
// import 'package:flutter/material.dart';
// import '../models/tree_node.dart';
// import '../widgets/animated_tree_graph.dart';

// class TesterPage extends StatefulWidget {
//   const TesterPage({super.key});

//   @override
//   State<TesterPage> createState() => _TesterPageState();
// }

// class _TesterPageState extends State<TesterPage> {
//   final AnimatedTreeController _controller = AnimatedTreeController();

//   late final List<TreeNode> nodes;

//   @override
//   void initState() {
//     super.initState();

//     nodes = [
//       TreeNode(
//         id: '1',
//         content: const LessonCard(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               Text(
//                 'Item 1',
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//               ),
//               SizedBox(height: 4),
//               Text('Some extra description here.'),
//             ],
//           ),
//         ),
//       ),
//       TreeNode(
//         id: '2',
//         content: const LessonCard(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               Text(
//                 'Item 2',
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//               ),
//               SizedBox(height: 4),
//               Text('Some extra description here.'),
//             ],
//           ),
//         ),
//       ),
//       TreeNode(
//         id: '3',
//         content: const LessonCard(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               Text(
//                 'Item 3',
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//               ),
//               SizedBox(height: 4),
//               Text('Some extra description here.'),
//             ],
//           ),
//         ),
//       ),
//       TreeNode(
//         id: '4',
//         content: const LessonCard(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               Text(
//                 'Item 4',
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//               ),
//               SizedBox(height: 4),
//               Text('Some extra description here.'),
//             ],
//           ),
//         ),
//       ),
//     ];
//   }

//   // static Widget _buildCard(String title, int idx) {
//   //   // Example: sometimes only text, sometimes text + other components
//   //   if (idx % 2 == 0) {
//   //     return Card(
//   //       elevation: 6,
//   //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//   //       child: Padding(
//   //         padding: const EdgeInsets.all(12.0),
//   //         child: Column(
//   //           mainAxisSize: MainAxisSize.min,
//   //           children: [
//   //             Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
//   //             const SizedBox(height: 8),
//   //             Row(
//   //               mainAxisSize: MainAxisSize.min,
//   //               children: const [
//   //                 Icon(Icons.star, size: 18),
//   //                 SizedBox(width: 6),
//   //                 Text('Extra'),
//   //               ],
//   //             ),
//   //           ],
//   //         ),
//   //       ),
//   //     );
//   //   } else {
//   //     return Card(
//   //       elevation: 6,
//   //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//   //       child: Container(
//   //         height: 70,
//   //         alignment: Alignment.center,
//   //         child: Text(
//   //           title,
//   //           style: const TextStyle(fontWeight: FontWeight.bold),
//   //         ),
//   //       ),
//   //     );
//   //   }
//   // }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Column(
//         children: [
//           // Controls
//           Padding(
//             padding: const EdgeInsets.all(12.0),
//             child: Wrap(
//               spacing: 12,
//               children: [
//                 ElevatedButton(
//                   onPressed: () => _controller.revealNext(),
//                   child: const Text('Reveal Next'),
//                 ),
//                 ElevatedButton(
//                   onPressed: () => _controller.revealAll(),
//                   child: const Text('Reveal All'),
//                 ),
//                 ElevatedButton(
//                   onPressed: () => _controller.reset(),
//                   child: const Text('Reset'),
//                 ),
//                 ElevatedButton(
//                   onPressed: () => _controller.play(),
//                   child: const Text('Play (Autoplay)'),
//                 ),
//                 ElevatedButton(
//                   onPressed: () => _controller.pause(),
//                   child: const Text('Pause'),
//                 ),
//               ],
//             ),
//           ),

//           Expanded(
//             child: SingleChildScrollView(
//               child: Center(
//                 child: SizedBox(
//                   height: MediaQuery.sizeOf(context).height,
//                   child: AnimatedTreeGraph(
//                     title: Container(
//                       padding: const EdgeInsets.symmetric(
//                         vertical: 12,
//                         horizontal: 16,
//                       ),
//                       decoration: BoxDecoration(
//                         color: const Color(0xffbce981),
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: const Text(
//                         'Title',
//                         style: TextStyle(color: Colors.black, fontSize: 18),
//                       ),
//                     ),
//                     children: nodes,
//                     controller: _controller,
//                     autoPlay: false,
//                     autoPlayInterval: const Duration(milliseconds: 900),
//                     nodeAnimationDuration: const Duration(milliseconds: 600),
//                     rootPadding: const EdgeInsets.only(top: 32, bottom: 8),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
