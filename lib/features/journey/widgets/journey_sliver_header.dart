import 'package:flutter/cupertino.dart';
import 'package:travel_companion/features/journey/widgets/journey_form_widgets.dart';

class JourneySliverHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const JourneySliverHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.only(top: topPad),
        child: TransportFormAppBar(
          title: title,
          subtitle: subtitle,
          trailing: trailing,
        ),
      ),
    );
  }
}
