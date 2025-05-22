import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../common/colo_extension.dart';
import '../../common_widget/icon_title_next_row_2.dart';
import '../../common_widget/round_button.dart';
import '../../common_widget/round_textfield.dart';
import '../../localization/app_localizations.dart';
import '../../main.dart';
import '../../model/user_model.dart';
import '../../services/auth_services.dart';
import '../../services/photo_service.dart';
import '../main_tab/main_tab_view.dart';
import '../profile/change_body_fat_view.dart';

class EditPhotoView extends StatefulWidget {
  final String userHeight;
  final String userWeight;
  final String userBodyFat;
  final String docId;
  final String imageUrl;

  const EditPhotoView({super.key,
    required this.userHeight,
    required this.userWeight,
    required this.userBodyFat,
    required this.docId,
    required this.imageUrl});

  @override
  State<EditPhotoView> createState() => _EditPhotoViewState();
}

class _EditPhotoViewState extends State<EditPhotoView> {
  late TextEditingController heightController;
  late TextEditingController weightController;
  late TextEditingController bodyFatController;
  bool darkmode = darkModeNotifier.value;
  bool isLoading = false;
  File? newImageFile;

  @override
  void initState() {
    super.initState();
    heightController = TextEditingController(text: widget.userHeight.toString());
    weightController = TextEditingController(text: widget.userWeight.toString());
    bodyFatController = TextEditingController(text: widget.userBodyFat.toString());
  }

  @override
  void dispose() {
    heightController.dispose();
    weightController.dispose();
    bodyFatController.dispose();
    super.dispose();
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (_) =>
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text("Chụp ảnh"),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo),
                title: Text("Chọn từ thư viện"),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source);

    if (image != null) {
      setState(() {
        newImageFile = File(image.path);
      });
    }
  }

  Future<void> _confirmAndDeleteProgress() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Confirm deletion"),
        content: Text("Are you sure you want to delete this progress photo?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              "Delete",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      // Xoá Firestore document
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('body_progress')
          .doc(widget.docId)
          .delete();

      // Xoá ảnh trên Firebase Storage
      try {
        final ref = FirebaseStorage.instance.refFromURL(widget.imageUrl);
        await ref.delete();
      } catch (e) {
        print("Không tìm thấy hoặc không xoá được ảnh: $e");
      }

      // Quay lại màn hình trước
      Navigator.pop(context);
    }
  }

  Future<void> _saveData() async {
    setState(() {
      isLoading = true;
    });

    final uid = FirebaseAuth.instance.currentUser!.uid;

    final result = await PhotoService.updatePhotoProgress(
      uid: uid,
      docId: widget.docId,
      imageUrl: widget.imageUrl,
      newImageFile: newImageFile,
      weight: weightController.text,
      height: heightController.text,
      bodyFat: bodyFatController.text,
    );

    setState(() {
      isLoading = false;
    });

    if (result == "success") {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Update successful")));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result)));
    }
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: darkmode ? Colors.blueGrey[900] : TColor.white,
        centerTitle: true,
        elevation: 0,
        leading: InkWell(
          onTap: (){Navigator.pop(context);},
          child: Container(
            margin: const EdgeInsets.all(8),
            height: 40,
            width: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: TColor.lightGray,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Image.asset(
              "assets/img/closed_btn.png",
              width: 15,
              height: 15,
              fit: BoxFit.contain,
            ),
          ),
        ),
        title: Text(
          AppLocalizations.of(context)?.translate("Edit Your Photo") ?? "Edit Your Photo",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        actions: [
            IconButton(
              icon: Icon(Icons.delete, color: Colors.redAccent),
              onPressed: _confirmAndDeleteProgress,
            ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                _buildImage(),
                SizedBox(height: media.width * 0.05),
                Row(
                  children: [
                    Expanded(
                      child: RoundTextField(
                        controller: weightController,
                        labelText: AppLocalizations.of(context)?.translate("Your Weight") ?? "Your Weight",
                        icon: "assets/img/weight.png",
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 50,
                      height: 50,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: TColor.secondaryG),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text("KG", style: TextStyle(color: TColor.white, fontSize: 12)),
                    ),
                  ],
                ),
                SizedBox(height: media.width * 0.04),
                Row(
                  children: [
                    Expanded(
                      child: RoundTextField(
                        controller: heightController,
                        labelText: AppLocalizations.of(context)?.translate("Your Height") ?? "Your Height",
                        icon: "assets/img/hight.png",
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 50,
                      height: 50,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: TColor.secondaryG),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text("CM", style: TextStyle(color: TColor.white, fontSize: 12)),
                    ),
                  ],
                ),
                SizedBox(height: media.width * 0.04),
                IconTitleNextRow2(
                  icon: "assets/img/body_icon.png",
                  title: AppLocalizations.of(context)?.translate("Body Fat(%)") ?? "Body Fat(%)",
                  time: bodyFatController.text,
                  color: TColor.lightGray,
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChangeBodyFatView(value: bodyFatController.text),
                      ),
                    );
                    if (result != null && result is String) {
                      setState(() {
                        bodyFatController.text = result;
                      });
                    }
                  },
                ),
                SizedBox(height: media.width * 0.03),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _showImageSourceDialog,
                        icon: Icon(Icons.photo),
                        label: Text("Change Image"),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16), // tăng chiều cao
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: media.width * 0.03),
                RoundButton(
                  title: AppLocalizations.of(context)?.translate("Save") ?? "Save",
                  onPressed: _saveData,
                ),
              ],
            ),
          ),
          AnimatedOpacity(
            opacity: isLoading ? 1.0 : 0.0,
            duration: Duration(milliseconds: 300),
            child: IgnorePointer(
              ignoring: !isLoading,
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildImage() {
    if (newImageFile != null) {
      return Image.file(newImageFile!, height: 500, fit: BoxFit.cover);
    } else {
      return CachedNetworkImage(imageUrl: widget.imageUrl, height: 500, fit: BoxFit.cover);
    }
  }
}
