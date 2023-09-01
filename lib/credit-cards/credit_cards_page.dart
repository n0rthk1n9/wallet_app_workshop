import 'dart:math';

import 'package:flutter/material.dart';
import 'package:wallet_app_workshop/core/data.dart';
import 'package:wallet_app_workshop/core/utils.dart';
import 'package:wallet_app_workshop/credit-cards/credit_card.dart';
import 'package:wallet_app_workshop/credit-cards/credit_card_page.dart';

const dragSnapDuration = Duration(milliseconds: 200);
const minCardScale = 0.6;
const maxCardScale = 1.0;
const cardsOffset = 12.0;
const minThrowDistance = 300.0;

class CreditCardsPage extends StatefulWidget {
  const CreditCardsPage({
    super.key,
    this.onCardPagePush,
    this.onCardPagePop,
  });

  final VoidCallback? onCardPagePush;
  final VoidCallback? onCardPagePop;

  @override
  State<CreditCardsPage> createState() => _CreditCardsPageState();
}

class _CreditCardsPageState extends State<CreditCardsPage> {
  int activeCard = 0;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final cardHeight = screenSize.width * 0.75;
    final cardWidth = cardHeight * creditCardAspectRatio;

    return Center(
      child: SizedBox(
        width: cardHeight,
        height: cardWidth + (cardsOffset * (cards.length - 1)),
        child: CreditCardsStack(
          itemCount: cards.length,
          initialActiveCard: activeCard,
          onCardTap: (index) {
            widget.onCardPagePush?.call();
            Navigator.of(context)
                .push(
              MaterialPageRoute(
                builder: (context) => CreditCardPage(initialIndex: index),
              ),
            )
                .then((value) {
              widget.onCardPagePop?.call();
              if (value != null && value is int) {
                setState(() {
                  activeCard = value;
                });
              }
            });
          },
          itemBuilder: (context, index) {
            return Align(
              widthFactor: cardHeight / cardWidth,
              heightFactor: cardWidth / cardHeight,
              child: Transform.rotate(
                angle: -pi / 2,
                child: CreditCard(
                  width: cardWidth,
                  data: cards[index],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class CreditCardsStack extends StatefulWidget {
  const CreditCardsStack({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.onCardTap,
    this.initialActiveCard = 0,
  });

  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final ValueChanged<int>? onCardTap;
  final int initialActiveCard;

  @override
  State<CreditCardsStack> createState() => _CreditCardsStackState();
}

class _CreditCardsStackState extends State<CreditCardsStack> {
  late int activeIndex;

  double get scaleDifference =>
      (maxCardScale - minCardScale) / widget.itemCount;

  Future<void> _handleDismiss() async {
    setState(() {
      activeIndex++;
    });
  }

  void _onPanStart(DragStartDetails details) {
    _handleDismiss();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    //...
  }

  void _onPanEnd(DragEndDetails details) {
    //...
  }

  @override
  void initState() {
    super.initState();
    activeIndex = widget.initialActiveCard;
  }

  @override
  void didUpdateWidget(covariant CreditCardsStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialActiveCard != widget.initialActiveCard) {
      setState(() {
        activeIndex = widget.initialActiveCard;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: List.generate(
        widget.itemCount + 1,
        (stackIndexWithPlaceholder) {
          final index = stackIndexWithPlaceholder - 1;
          final modIndex = getModIndexFromActiveIndex(
            index,
            activeIndex,
            widget.itemCount,
          );

          Widget child = widget.itemBuilder(context, modIndex);

          // Build placeholder widget
          if (stackIndexWithPlaceholder == 0) {
            return Positioned(
              top: 0,
              left: 0,
              child: Transform.scale(
                scale: minCardScale,
                alignment: Alignment.topCenter,
                // Disable any hero that might exist, as it will cause
                // a duplicate hero tag in the same widget tree
                child: HeroMode(
                  enabled: false,
                  child: child,
                ),
              ),
            );
          }

          // Build the last, draggable card
          if (index == widget.itemCount - 1) {
            return Positioned(
              left: 0,
              bottom: 0,
              child: GestureDetector(
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                onTap: () => widget.onCardTap?.call(modIndex),
                behavior: HitTestBehavior.opaque,
                child: child,
              ),
            );
          }

          // Build the cards in between (remaining cards)
          /// To gradually scale down widgets, limited by min and max scales
          final scaleByIndex = minCardScale +
              ((maxCardScale - minCardScale) / (widget.itemCount - 1)) * index;

          // Slide cards up gradually
          final bottomOffsetByIndex =
              -cardsOffset * (widget.itemCount - 1 - index);

          return Positioned(
            left: 0,
            bottom: 0,
            child: Transform.translate(
              offset: Offset(0, bottomOffsetByIndex),
              child: Transform.scale(
                scale: scaleByIndex,
                alignment: Alignment.topCenter,
                child: child,
              ),
            ),
          );
        },
      ),
    );
  }
}