import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ViewCommentsButton extends StatelessWidget {
  const ViewCommentsButton({
    super.key,
    required this.onTap,
    required this.postId,
  });

  final void Function()? onTap;

  final String postId;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      child: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('User Posts')
            .doc(postId)
            .collection('Comments')
            .orderBy('CommentTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final int nOfComments = snapshot.data!.docs.length;
            final String label = nOfComments == 1 ? 'comment' : 'comments';
            return Column(
              children: [
                Icon(Icons.comment_outlined, color: Theme.of(context).colorScheme.secondary),
                Text(
                  '$nOfComments $label',
                  style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
                )
              ],
            );
          } else {
            return SizedBox(
              height: 50,
              width: 75,
              child: LinearProgressIndicator(
                backgroundColor: Theme.of(context).colorScheme.onPrimary,
                color: Theme.of(context).colorScheme.surface,
                minHeight: 50,
              ),
            );
          }
        },
      ),
    );
  }
}
