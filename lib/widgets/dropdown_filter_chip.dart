
// class DropdownFilterChip<T> extends StatefulWidget {
//   const DropdownFilterChip(
//       {super.key,
//       required this.selected,
//       required this.label,
//       required this.items,
//       required this.onSelected});
//   final bool selected;
//   final String label;
//   final List<T> items;
//   final Function(T) onSelected;
//   @override
//   State<DropdownFilterChip> createState() => _DropdownFilterChipState();
// }

// class _DropdownFilterChipState<T> extends State<DropdownFilterChip> {
//   bool _opened = false;
//   T? _selected;

//   @override
//   Widget build(BuildContext context) {
//     return MenuAnchor(
//       menuChildren: [
//         ...widget.items.map((e) => MenuItemButton(
//               onPressed: () {
//                 setState(() {
//                   _selected = e;
//                 });
//                 widget.onSelected(e);
//               },
//               child: Text(e.toString()),
//             )),
//       ],
//       onClose: () {
//         setState(() {
//           _opened = false;
//         });
//       },
//       builder: (context, controller, child) {
//         return GestureDetector(
//           onTap: () {
//             setState(() {
//               _opened = !_opened;
//             });
//             if (_opened) {
//               controller.open();
//             } else {
//               controller.close();
//             }
//           },
//           child: Chip(
//             side: BorderSide.none,
//             backgroundColor: widget.selected
//                 ? Theme.of(context).colorScheme.secondaryContainer
//                 : null,
//             avatar: widget.selected
//                 ? Icon(Icons.check_rounded,
//                     size: 18,
//                     color: Theme.of(context).colorScheme.onSecondaryContainer)
//                 : null,
//             label: _selected != null
//                 ? Text(_selected.toString(),
//                     style: TextStyle(
//                         color:
//                             Theme.of(context).colorScheme.onSecondaryContainer))
//                 : Text(widget.label,
//                     style: TextStyle(
//                         color: Theme.of(context)
//                             .colorScheme
//                             .onSecondaryContainer)),
//             onDeleted: () {},
//             deleteIcon: _opened
//                 ? Icon(Icons.arrow_drop_up)
//                 : Icon(Icons.arrow_drop_down),
//           ),
//         );
//       },
//     );
//   }
// }

