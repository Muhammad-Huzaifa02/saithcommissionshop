import 'dart:async';
import 'package:flutter/material.dart';

class TypingText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration charDelay;
  final bool loop;

  const TypingText({
    super.key,
    required this.text,
    this.style,
    this.charDelay = const Duration(milliseconds: 60),
    this.loop = false,
  });

  @override
  State<TypingText> createState() => _TypingTextState();
}

class _TypingTextState extends State<TypingText> {
  String _displayed = '';
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    _timer = Timer.periodic(widget.charDelay, (_) {
      if (_index < widget.text.length) {
        setState(() => _displayed = widget.text.substring(0, ++_index));
      } else {
        _timer?.cancel();
        if (widget.loop) {
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              setState(() {
                _displayed = '';
                _index = 0;
              });
              _start();
            }
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Text(
    _displayed,
    style: widget.style,
  );
}