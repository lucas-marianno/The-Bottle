import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:the_bottle/components/input_from_dialog.dart';
import 'package:the_bottle/components/input_from_modal_bottom_sheet.dart';
import 'package:the_bottle/components/list_tile.dart';
import 'package:the_bottle/components/options_modal_bottom_sheet.dart';
import 'package:the_bottle/components/profile_picture.dart';
import 'package:the_bottle/components/show_dialog.dart';
import 'package:the_bottle/pages/image_visualizer_page.dart';
import '../components/profile_field.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.userEmail,
    this.heroTag = 'null',
  });

  final String userEmail;
  final String heroTag;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final User currentUser = FirebaseAuth.instance.currentUser!;
  String username = '';
  String bio = '';

  void deleteAccount() async {
    if (widget.userEmail != currentUser.email) return;

    final confirmDeletion = await showMyDialog(
      context,
      title: 'This action is irreversible!!!',
      content: 'Are you sure you want to delete your account?',
      showActions: true,
    );

    if (confirmDeletion != true) return;

    final currentUserEmail = currentUser.email;

    // ignore: use_build_context_synchronously
    final password = await inputFromDialog(context, title: 'Confirm Password');

    if (password == null || password == '') return;

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: currentUserEmail!,
        password: password,
      );
    } on FirebaseException catch (e) {
      // ignore: use_build_context_synchronously
      await showMyDialog(
        context,
        title: 'Authentication Failed',
        content: e.code.replaceAll('-', ' '),
      );
      return;
    }

    try {
      // delete data from auth
      await currentUser.delete();
      // logout
      await FirebaseAuth.instance.signOut();
    } on FirebaseException catch (error) {
      // ignore: use_build_context_synchronously
      await showMyDialog(
        context,
        title: 'Error',
        content: error.code.replaceAll('-', ' '),
      );
      return;
    }

    try {
      // delete data from storage
      final storage = FirebaseStorage.instance.ref();
      await storage.child('Profile Pictures/$currentUserEmail').delete();
      await storage.child('Profile Thumbnails/$currentUserEmail').delete();
    } on FirebaseException catch (error) {
      if (error.code != 'object-not-found') {
        // ignore: use_build_context_synchronously
        await showMyDialog(
          context,
          title: 'Error',
          content: error.code.replaceAll('-', ' '),
        );
      }
    }

    try {
      // delete data from database
      final database = FirebaseFirestore.instance;
      await database.collection('User Profile').doc(currentUserEmail).delete();
      await database.collection('User Settings').doc(currentUserEmail).delete();
    } on FirebaseException catch (error) {
      if (error.code != 'object-not-found') {
        // ignore: use_build_context_synchronously
        await showMyDialog(
          context,
          title: 'Error',
          content: error.code.replaceAll('-', ' '),
        );
      }
    }
  }

  void viewPicture(String? imageUrl) {
    if (imageUrl == null) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => ImageVisualizerPage(imageUrl: imageUrl),
    ));
  }

  void pickAndUploadPicture() async {
    // prompt user to select camera or gallery
    final ImageSource? imgSource = await optionsFromModalBottomSheet(context, children: [
      MyListTile(
        iconData: Icons.camera,
        text: 'Open camera',
        onTap: () => Navigator.pop(context, ImageSource.camera),
      ),
      MyListTile(
        iconData: Icons.image_search,
        text: 'From gallery',
        onTap: () => Navigator.pop(context, ImageSource.gallery),
      ),
    ]);

    if (imgSource == null) return;

    // retrieve image from user
    final XFile? imgFile = await ImagePicker().pickImage(
      source: imgSource,
      imageQuality: 75,
      maxHeight: 1080,
      maxWidth: 1080,
    );

    if (imgFile == null) return;

    // creates thumbnail
    final image = await imgFile.readAsBytes();
    final thumbnail = await FlutterImageCompress.compressWithList(
      image,
      quality: 50,
      minHeight: 50,
      minWidth: 50,
    );

    // set filename as user email
    final String picturesFilename = 'Profile Pictures/${widget.userEmail}';
    final String thumbnailsFilename = 'Profile Thumbnails/${widget.userEmail}';

    // upload to storage (handle web)
    final TaskSnapshot imgUploadTask =
        await FirebaseStorage.instance.ref(picturesFilename).putData(image);
    final TaskSnapshot thumbnailUploadTask =
        await FirebaseStorage.instance.ref(thumbnailsFilename).putData(thumbnail);

    // img and thumbnail urls
    final String imgStorageUrl = await imgUploadTask.ref.getDownloadURL();
    final String thumbnailStorageUrl = await thumbnailUploadTask.ref.getDownloadURL();

    // save image download URL to database in UserProfile/picture
    await FirebaseFirestore.instance.collection('User Profile').doc(widget.userEmail).set(
        {'pictureUrl': imgStorageUrl, 'thumbnailUrl': thumbnailStorageUrl},
        SetOptions(merge: true));
  }

  void editUsername() async {
    final newUsername = await getInputFromModalBottomSheet(
      context,
      title: 'New Username',
      startingString: username,
      hintText: 'Username',
      maxLength: 20,
    );
    if (newUsername == null || newUsername == username) return;

    await FirebaseFirestore.instance.collection('User Profile').doc(widget.userEmail).set({
      'username': newUsername,
    }, SetOptions(merge: true));
  }

  void editBio() async {
    final newBio = await getInputFromModalBottomSheet(
      context,
      title: 'New bio',
      startingString: bio,
      hintText: 'Your new bio...',
      enterKeyPressSubmits: false,
      maxLength: 500,
    );

    if (newBio == null || newBio == bio) return;
    await FirebaseFirestore.instance.collection('User Profile').doc(widget.userEmail).set({
      'bio': newBio,
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('P R O F I L E'),
      ),
      body: StreamBuilder(
        stream:
            FirebaseFirestore.instance.collection('User Profile').doc(widget.userEmail).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.data() != null) {
            final profileData = snapshot.data!.data()!;
            username = profileData['username'];
            bio = profileData['bio'];
            final pictureUrl = profileData['pictureUrl'];

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // profile pic
                  const Flexible(child: SizedBox(height: 40)),
                  FractionallySizedBox(
                    widthFactor: 0.5,
                    // heightFactor: 0.2,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        // profile pic
                        Hero(
                          tag: widget.heroTag,
                          child: ProfilePicture(
                            profileEmailId: widget.userEmail,
                            size: ProfilePictureSize.large,
                            onTap: () => viewPicture(pictureUrl),
                          ),
                        ),
                        // add image button
                        widget.userEmail != currentUser.email
                            ? Container()
                            : IconButton(
                                onPressed: pickAndUploadPicture,
                                icon: CircleAvatar(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.grey[900],
                                  radius: MediaQuery.of(context).size.width * 0.045,
                                  child: const Icon(Icons.add_a_photo),
                                ),
                              ),
                      ],
                    ),
                  ),
                  const Flexible(child: SizedBox(height: 20)),
                  // user email
                  Text(
                    widget.userEmail,
                    style: const TextStyle(fontSize: 20),
                    textAlign: TextAlign.center,
                  ),
                  const Flexible(child: SizedBox(height: 70)),
                  // user details
                  const Text(
                    'My details',
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  const Flexible(child: SizedBox(height: 20)),
                  // username
                  ProfileField(
                    sectionName: 'username',
                    text: username,
                    onTap: editUsername,
                    editable: widget.userEmail == currentUser.email,
                  ),
                  const Flexible(child: SizedBox(height: 15)),
                  // bio
                  ProfileField(
                    sectionName: 'bio',
                    text: bio,
                    onTap: editBio,
                    editable: widget.userEmail == currentUser.email,
                  ),
                  const Spacer(),
                  // delete account
                  widget.userEmail != currentUser.email
                      ? Container()
                      : MyListTile(
                          iconData: Icons.delete,
                          text: 'Delete Acount',
                          onTap: deleteAccount,
                          reverseColors: true,
                        ),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.data?.data() == null) {
            return const Center(child: Text('Error: User does not exist'));
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }
}
