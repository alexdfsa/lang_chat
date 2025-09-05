import 'package:flutter/material.dart';
import 'package:langchat/presentation/signals/contact_signals.dart';

class FloatingActionMenu extends StatefulWidget {
  final ContactSignals contactSignals;
  final VoidCallback onCreateContact;

  const FloatingActionMenu({
    super.key,
    required this.contactSignals,
    required this.onCreateContact,
  });

  @override
  State<FloatingActionMenu> createState() => _FloatingActionMenuState();
}

class _FloatingActionMenuState extends State<FloatingActionMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_isExpanded) {
      _animationController.reverse();
    } else {
      _animationController.forward();
    }
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Create contact button
        ScaleTransition(
          scale: _animation,
          child: FloatingActionButton(
            heroTag: 'create_contact',
            mini: true,
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF128C7E),
            onPressed: () {
              _toggle();
              widget.onCreateContact();
            },
            child: const Icon(Icons.person_add),
          ),
        ),

        SizedBox(height: _isExpanded ? 16 : 0),

        // Main FAB
        FloatingActionButton(
          heroTag: 'main_fab',
          backgroundColor: const Color(0xFF128C7E),
          onPressed: _toggle,
          child: AnimatedRotation(
            turns: _isExpanded ? 0.125 : 0,
            duration: const Duration(milliseconds: 300),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}
