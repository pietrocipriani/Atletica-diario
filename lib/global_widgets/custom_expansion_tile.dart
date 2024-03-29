import 'package:atletica/global_widgets/custom_list_tile.dart';
import 'package:flutter/material.dart';

const Duration _kExpand = Duration(milliseconds: 200);

class CustomExpansionTile extends StatefulWidget {
  const CustomExpansionTile({
    Key? key,
    this.leading,
    required this.title,
    this.titleDecoration,
    this.titleColor,
    this.subtitle,
    this.hiddenSubtitle,
    this.backgroundColor,
    this.childrenBackgroundColor,
    this.onExpansionChanged,
    this.children = const <Widget>[],
    this.trailing,
    this.follower,
    this.initiallyExpanded = false,
    this.childrenPadding = EdgeInsets.zero,
    this.isThreeLine = false,
  }) : super(key: key);

  final Widget? leading;
  final String title;
  final TextDecoration? titleDecoration;
  final Color? titleColor;
  final Widget? subtitle;
  final String? hiddenSubtitle;
  final ValueChanged<bool>? onExpansionChanged;
  final List<Widget> children;
  final Color? backgroundColor, childrenBackgroundColor;
  final Widget? trailing;
  final LayerLink? follower;
  final bool initiallyExpanded;
  final EdgeInsets childrenPadding;
  final bool isThreeLine;

  @override
  _ExpansionTileState createState() => _ExpansionTileState();
}

class _ShapeBorderTween extends Tween<ShapeBorder> {
  _ShapeBorderTween({ShapeBorder? begin, ShapeBorder? end})
      : super(begin: begin, end: end);

  @override
  ShapeBorder lerp(final double t) {
    return ShapeBorder.lerp(begin, end, t) ?? const Border();
  }
}

class _PaddingTween extends Tween<EdgeInsets> {
  _PaddingTween({EdgeInsets? begin, EdgeInsets? end})
      : super(begin: begin, end: end);

  @override
  EdgeInsets lerp(final double t) {
    return EdgeInsets.lerp(begin, end, t) ?? EdgeInsets.zero;
  }
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
  final ColorTween _cardColorTween = ColorTween();
  final Tween<double> _elevationTween = Tween(begin: 0);
  final _ShapeBorderTween _shapeTween =
      _ShapeBorderTween(begin: const RoundedRectangleBorder());
  final _PaddingTween _paddingTween = _PaddingTween(begin: EdgeInsets.zero);

  late final AnimationController _controller =
      AnimationController(duration: _kExpand, vsync: this);
  late final Animation<double> _iconTurns =
      _controller.drive(_halfTween.chain(_easeInTween));
  late final Animation<double> _heightFactor = _controller.drive(_easeInTween);
  late final Animation<double> _elevationFactor =
      _heightFactor.drive(_elevationTween);
  late final Animation<ShapeBorder> _shapeFactor =
      _shapeTween.animate(_heightFactor);
  late final Animation<Color?> _colorFactor =
      _cardColorTween.animate(_heightFactor);
  late final Animation<EdgeInsets> _marginFactor =
      _paddingTween.animate(_heightFactor);

  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = PageStorage.of(context)?.readState(context) as bool? ??
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
      widget.onExpansionChanged!(_isExpanded);
  }

  Widget _buildChildren(BuildContext context, Widget? child) {
    final bool closed = !_isExpanded && _controller.isDismissed;
    final Widget innerChild = Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        CustomListTile(
          title: Text(
            widget.title,
            style: TextStyle(
              fontWeight: _isExpanded ? FontWeight.bold : FontWeight.normal,
              color: widget.titleColor,
              decoration: widget.titleDecoration,
            ),
          ),
          leading: widget.leading,
          onTap: _handleTap,
          isThreeLine: widget.isThreeLine,
          tileColor: widget.backgroundColor ??
              (closed ? null : Theme.of(context).canvasColor),
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
            child: Container(
              padding: widget.childrenPadding,
              color: _colorFactor.value,
              child: child,
            ),
          ),
        ),
        if (widget.follower != null)
          CompositedTransformTarget(link: widget.follower!, child: Container()),
      ],
    );
    return Padding(
      padding: _marginFactor.value,
      child: Material(
        elevation: _elevationFactor.value,
        color: Colors.transparent,
        shadowColor: Theme.of(context).cardTheme.shadowColor,
        shape: _shapeFactor.value,
        animationDuration: Duration.zero,
        clipBehavior: Clip.antiAlias,
        child: innerChild,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    final ThemeData theme = Theme.of(context);
    _borderColorTween.end = theme.dividerColor;
    _headerColorTween
      ..begin = theme.textTheme.subtitle1!.color
      ..end = theme.accentColor;
    _iconColorTween
      ..begin = theme.unselectedWidgetColor
      ..end = theme.accentColor;
    _cardColorTween.end = widget.childrenBackgroundColor ??
        theme.cardTheme.color ??
        theme.cardColor;
    _elevationTween.end = theme.cardTheme.elevation ?? 1;
    _shapeTween.end = theme.cardTheme.shape ??
        const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(4)));
    _paddingTween.end = theme.cardTheme.margin as EdgeInsets?;
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final bool closed = !_isExpanded && _controller.isDismissed;
    Widget? child = closed || widget.children.isEmpty
        ? null
        : Column(
            children: widget.children,
            crossAxisAlignment: CrossAxisAlignment.stretch,
          );
    if (!closed &&
        widget.hiddenSubtitle != null &&
        widget.hiddenSubtitle!.isNotEmpty)
      child = Column(children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            widget.hiddenSubtitle!,
            style: Theme.of(context)
                .textTheme
                .overline!
                .copyWith(fontWeight: FontWeight.normal),
            textAlign: TextAlign.justify,
          ),
        ),
        child!
      ]);
    return AnimatedBuilder(
      animation: _controller.view,
      builder: _buildChildren,
      child: child,
    );
  }
}
