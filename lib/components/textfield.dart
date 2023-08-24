import 'package:flutter/material.dart';
import 'package:the_bottle/settings.dart';

class MyTextField extends StatefulWidget {
  const MyTextField({
    super.key,
    this.controller,
    this.hintText,
    this.onSubmited,
    this.obscureText = false,
    this.autofocus = true,
    this.enterKeyPressSubmits = false,
    this.allLowerCase = false,
    this.maxLength,
  });
  final TextEditingController? controller;
  final String? hintText;
  final void Function()? onSubmited;
  final bool obscureText;
  final bool autofocus;
  final bool enterKeyPressSubmits;
  final bool allLowerCase;
  final int? maxLength;

  @override
  State<MyTextField> createState() => _MyTextFieldState();
}

class _MyTextFieldState extends State<MyTextField> {
  bool isVisible = false;
  int? maxLength;

  @override
  Widget build(BuildContext context) {
    bool enterKeyPressSubmits = widget.enterKeyPressSubmits || UserConfig().enterSendsPost;

    return TextField(
      autofocus: widget.autofocus,
      controller: widget.controller,
      obscureText: widget.obscureText ? !isVisible : false,
      maxLength: maxLength,
      onChanged: (value) {
        if (widget.allLowerCase) {
          widget.controller?.value = widget.controller!.value.copyWith(text: value.toLowerCase());
        }
        if (widget.maxLength != null) {
          widget.controller!.text.length > widget.maxLength! / 2
              ? maxLength = widget.maxLength
              : null;
          setState(() {});
        }
      },
      onSubmitted: enterKeyPressSubmits ? (value) => widget.onSubmited?.call() : null,
      textInputAction: enterKeyPressSubmits ? null : TextInputAction.none,
      maxLines: widget.obscureText || enterKeyPressSubmits ? 1 : null,
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: const TextStyle(color: Colors.grey),
        suffixIcon: widget.obscureText
            ? IconButton(
                icon: Icon(
                  isVisible ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () => setState(() => isVisible = !isVisible))
            : null,
        focusedBorder: const OutlineInputBorder(),
        enabledBorder: const OutlineInputBorder(),
        filled: true,
      ),
    );
  }
}
