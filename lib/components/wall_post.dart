import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:the_wall/components/input_from_dialog.dart';
import 'package:the_wall/components/show_dialog.dart';
import 'package:the_wall/components/like_button.dart';
import 'package:the_wall/settings.dart';

class WallPost extends StatefulWidget {
  const WallPost({
    super.key,
    required this.message,
    required this.postOwner,
    required this.postId,
    required this.likes,
  });

  final String message;
  final String postOwner;
  final String postId;
  final List<String> likes;

  @override
  State<WallPost> createState() => _WallPostState();
}

class _WallPostState extends State<WallPost> {
  final User currentUser = FirebaseAuth.instance.currentUser!;
  bool isLiked = false;

  String postOwnerUsername = '';
  bool isDoneLoading = false;

  Future<void> getPostOwnerUsername() async {
    postOwnerUsername = widget.postOwner;
    if (!replaceEmailWithUsernameOnWallPost) {
      isDoneLoading = true;
      return;
    }

    // what if we replace this shit with a sreambuilder?
    final profileInfo =
        await FirebaseFirestore.instance.collection('User Profile').doc(widget.postOwner).get();
    if (profileInfo.exists && profileInfo.data()!['username'] != null) {
      postOwnerUsername = profileInfo.data()!['username'];
    }

    /// Error: setState() called after dispose(): _WallPostState#67c5d(lifecycle state: defunct, not mounted)
    /// This error happens if you call setState() on a State object for a widget that no longer appears in the
    ///  widget tree (e.g., whose parent widget no longer includes the widget in its build). This error can
    ///  occur when code calls setState() from a timer or an animation callback.
    /// The preferred solution is to cancel the timer or stop listening to the animation in the dispose() callback.
    ///  Another solution is to check the "mounted" property of this object before calling setState() to ensure the
    ///  object is still in the tree.
    /// This error might indicate a memory leak if setState() is being called because another object is retaining
    ///  a reference to this State object after it has been removed from the tree. To avoid memory leaks, consider
    ///  breaking the reference to this object during dispose().
    isDoneLoading = true;
    setState(() {});
  }

  void toggleLike() {
    setState(() {
      isLiked = !isLiked;
    });

    final postReference = FirebaseFirestore.instance.collection('User Posts').doc(widget.postId);
    if (isLiked) {
      postReference.update({
        'Likes': FieldValue.arrayUnion([currentUser.email]),
      });
    } else {
      postReference.update({
        'Likes': FieldValue.arrayRemove([currentUser.email]),
      });
    }
  }

  void deletePost() {
    // dismiss any keyboard
    FocusManager.instance.primaryFocus?.unfocus();
    if (context.mounted) Navigator.pop(context);

    if (widget.postOwner != currentUser.email) {
      showMyDialog(context,
          title: 'Nope!', content: 'You cannot delete posts made by someone else');
      return;
    }

    // delete post from firebase firestore
    FirebaseFirestore.instance.collection('User Posts').doc(widget.postId).delete();
  }

  void addComment() async {
    final commentText = await getInputFromDialog(context,
        title: 'Add Comment', hintText: 'New comment...', submitButtonLabel: 'Post Comment');
    if (commentText == null) return;
    // write the comment to firestore under the comments collection for this post
    // FirebaseFirestore.instance
    //     .collection('User Posts')
    //     .doc(widget.postId)
    //     .collection('Comments')
    //     .add({
    //   'CommentText': commentText!,
    //   'CommentedBy': currentUser.email,
    //   'CommentTime': Timestamp.now(),
    // });
  }

  @override
  void initState() {
    getPostOwnerUsername();
    isLiked = widget.likes.contains(currentUser.email);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (!isDoneLoading) {
      return Container(
        margin: const EdgeInsets.all(10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white)),
        child: Center(
            child: LinearProgressIndicator(
          backgroundColor: Colors.grey[200],
          color: Colors.grey[100],
          minHeight: 50,
        )),
      );
    } else {
      return GestureDetector(
        onLongPress: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.grey[900],
            showDragHandle: true,
            builder: (context) {
              return Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  children: [
                    ListTile(
                      onTap: deletePost,
                      leading: const Icon(
                        Icons.delete,
                        color: Colors.white,
                      ),
                      title: const Text('Delete post', style: TextStyle(color: Colors.white)),
                    )
                  ],
                ),
              );
            },
          );
        },
        child: Container(
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // user + message
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    postOwnerUsername,
                    style: TextStyle(color: Colors.grey[900], fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Text(widget.message),
                  const SizedBox(height: 10),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    children: [
                      LikeButton(isLiked: isLiked, onTap: toggleLike),
                      Text(widget.likes.length.toString())
                    ],
                  ),
                  const SizedBox(width: 10),
                  // comment button
                  Column(
                    children: [
                      GestureDetector(
                          onTap: addComment,
                          child: const Icon(Icons.comment_outlined, color: Colors.grey)),
                      Text(widget.likes.length.toString())
                    ],
                  ),
                ],
              )
              // like button
            ],
          ),
        ),
      );
    }
  }
}
