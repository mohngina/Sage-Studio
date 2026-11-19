import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';
import '../theme/typography.dart';

class MarqueeTicker extends StatefulWidget {
  final List<String> items;
  final double height;
  final Color backgroundColor;

  const MarqueeTicker({
    super.key,
    required this.items,
    this.height = 40.0,
    this.backgroundColor = DesignTokens.softBackground,
  });

  @override
  State<MarqueeTicker> createState() => _MarqueeTickerState();
}

class _MarqueeTickerState extends State<MarqueeTicker> with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScrolling());
  }

  void _startScrolling() async {
    while (mounted) {
      if (_scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        if (maxScroll > 0) {
          await _scrollController.animateTo(
            maxScroll,
            duration: const Duration(seconds: 25),
            curve: Curves.linear,
          );
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(0);
          }
        }
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repeatedItems = [...widget.items, ...widget.items, ...widget.items, ...widget.items];

    return Container(
      height: widget.height,
      color: widget.backgroundColor,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: repeatedItems.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.xl),
            child: Center(
              child: Row(
                children: [
                  Text(
                    repeatedItems[index],
                    style: AppTypography.labelUppercase(color: DesignTokens.textPrimary),
                  ),
                  const SizedBox(width: DesignTokens.xl),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: DesignTokens.oliveAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
