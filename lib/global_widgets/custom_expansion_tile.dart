import 'package:atletica/global_widgets/custom_list_tile.dart';
import 'package:flutter/material.dart';

const Duration _kExpand = Duration(milliseconds: 200);

class CustomExpansionTile extends StatefulWidget {
  const CustomExpansionTile({
    Key key,
    this.leading,
    @required this.title,
    this.titleColor,
    this.subtitle,
    this.hiddenSubtitle,
    this.backgroundColor,
    this.childrenBackgroundColor,
    this.onExpansionChanged,
    this.children = const <Widget>[],
    this.trailing,
    this.initiallyExpanded = false,
    this.childrenPadding = EdgeInsets.zero,
  })  : assert(initiallyExpanded != null &&
            childrenPadding != null),
        super(key: key);

  final Widget leading;
  final String title;
  final Color titleColor;
  final Widget subtitle;
  final String hiddenSubtitle;
  final ValueChanged<bool> onExpansionChanged;
  final List<Widget> children;
  final Color backgroundColor, childrenBackgroundColor;
  final Widget trailing;
  final bool initiallyExpanded;
  final EdgeInsets childrenPadding;

  @override
  _ExpansionTileState createState() => _ExpansionTileState();
}

class _ExpansionTileState extends State<CustomExpansionTile>
    with SingleTickerProviderStateMixin {
  static final Animatable<double> _easeInTween =
      CurveTween(curve: Curves.easeIn);
  static final Animatable<double> _halfTween =
      Tween<double>(begin: 0.0, end: 0.5);

  final ColorTween _borderColorTween = ColorTween();
  final ColorTween _headerColorTween = ColorTween();
  final ColorTween _iconColorTween = ColorTween();
  final ColorTween _backgroundColorTween = ColorTween();

  AnimationController _controller;
  Animation<double> _iconTurns;
  Animation<double> _heightFactor;

  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: _kExpand, vsync: this);
    _heightFactor = _controller.drive(_easeInTween);
    _iconTurns = _controller.drive(_halfTween.chain(_easeInTween));

    _isExpanded = PageStorage.of(context)?.readState(context) as bool ??
        widget.initiallyExpanded;
    if (_isExpanded) _controller.value = 1.0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse().then<void>((void value) {
          if (!mounted) return;
          setState(() {
            // Rebuild without widget.children.
          });
        });
      }
      PageStorage.of(context)?.writeState(context, _isExpanded);
    });
    if (widget.onExpansionChanged != null)
      widget.onExpansionChanged(_isExpanded);
  }

  Widget _buildChildren(BuildContext context, Widget child) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        CustomListTile(
          title: Text(
            widget.title,
            style: TextStyle(
              fontWeight: _isExpanded ? FontWeight.bold : FontWeight.normal,
              color: widget.titleColor,
            ),
          ),
          leading: widget.leading,
          onTap: _handleTap,
          tileColor: widget.backgroundColor,
          subtitle: widget.subtitle,
          trailing: widget.trailing ??
              RotationTransition(
                turns: _iconTurns,
                child: const Icon(Icons.expand_more),
              ),
        ),
        ClipRect(
          child: Align(
            heightFactor: _heightFactor.value,
            child: child,
          ),
        ),
      ],
    );
  }

  @override
  void didChangeDependencies() {
    final ThemeData theme = Theme.of(context);
    _borderColorTween.end = theme.dividerColor;
    _headerColorTween
      ..begin = theme.textTheme.subtitle1.color
      ..end = theme.accentColor;
    _iconColorTween
      ..begin = theme.unselectedWidgetColor
      ..end = theme.accentColor;
    _backgroundColorTween.end = widget.backgroundColor;
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final bool closed = !_isExpanded && _controller.isDismissed;
    Widget child = closed
        ? null
        : Container(
            padding: widget.childrenPadding,
            color: widget.childrenBackgroundColor,
            child: Column(
              children: widget.children,
              crossAxisAlignment: CrossAxisAlignment.stretch,
            ),
          );
    if (!closed &&
        widget.hiddenSubtitle != null &&
        widget.hiddenSubtitle.isNotEmpty)
      child = Column(children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            widget.hiddenSubtitle,
            style: Theme.of(context)
                .textTheme
                .overline
                .copyWith(fontWeight: FontWeight.normal),
            textAlign: TextAlign.justify,
          ),
        ),
        child
      ]);
    return AnimatedBuilder(
      animation: _controller.view,
      builder: _buildChildren,
      child: child,
    );
  }
}
