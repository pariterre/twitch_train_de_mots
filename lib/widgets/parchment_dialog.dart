import 'package:flutter/material.dart';

class ParchmentDialog extends StatelessWidget {
  const ParchmentDialog({
    super.key,
    required this.title,
    required this.width,
    required this.height,
    this.padding,
    required this.content,
    this.onAccept,
    this.acceptButtonTitle = 'OK',
    this.onCancel,
    this.cancelButtonTitle = 'Annuler',
  });

  final String title;
  final double width;
  final double height;
  final EdgeInsets? padding;
  final Widget content;

  final String acceptButtonTitle;
  final Function()? onAccept;
  final String cancelButtonTitle;
  final Function()? onCancel;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: SizedBox(
        width: width,
        height: height,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
                width: width,
                height: height,
                child: Image.asset('images/parchment.png', fit: BoxFit.fill)),
            Padding(
              padding: padding ?? const EdgeInsets.symmetric(horizontal: 50.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 24.0, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8.0),
                  content,
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (onCancel != null)
                            TextButton(
                              onPressed: onCancel,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5.0),
                                ),
                              ),
                              child: Text(
                                cancelButtonTitle,
                                style: const TextStyle(color: Colors.black),
                              ),
                            ),
                          if (onAccept != null)
                            TextButton(
                              onPressed: onAccept,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5.0),
                                ),
                              ),
                              child: Text(
                                acceptButtonTitle,
                                style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      shadowColor: Colors.transparent,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
    );
  }
}
