import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import '../../common/colo_extension.dart';
import '../../main.dart';
import '../../model/user_model.dart';
import '../../services/auth_services.dart';
import '../../services/photo_service.dart';
import '../main_tab/main_tab_view.dart';
import 'edit_photo_view.dart';

class GalleryView extends StatefulWidget {
  const GalleryView({super.key});

  @override
  _GalleryViewState createState() => _GalleryViewState();
}

class _GalleryViewState extends State<GalleryView> {
  List<String> selectedIds = [];
  bool selectionMode = false;
  bool darkmode = darkModeNotifier.value;
  String uid = FirebaseAuth.instance.currentUser!.uid;

  Stream<QuerySnapshot> _getBodyProgressStream() {
    return FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("body_progress")
        .orderBy("date", descending: true)
        .snapshots();
  }

  void _toggleSelection(String docId) {
    setState(() {
      if (selectedIds.contains(docId)) {
        selectedIds.remove(docId);
      } else {
        selectedIds.add(docId);
      }
    });
  }

  void _deleteSelected() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Confirm deletion"),
        content: Text(
          "Are you sure you want to delete ${selectedIds.length} selected item(s)? This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text("Delete"),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;
    int count = selectedIds.length;

    final uid = FirebaseAuth.instance.currentUser!.uid;

    await PhotoService.deletePhotos(
      uid: uid,
      docIds: selectedIds.toList(),
    );

    setState(() {
      selectedIds.clear();
      selectionMode = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$count image deleted")),
    );
  }

  String formatDateKey(DateTime date) {
    return DateFormat('dd MMMM, yyyy').format(date);
  }

  void _getUserInfo() async {
    try {
      UserModel? user = await AuthService().getUserInfo(uid);

      if (user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainTabView(user: user, initialTab: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: darkmode ? Colors.black : Colors.white,
        centerTitle: true,
        elevation: 0,
        leading: InkWell(
          onTap: _getUserInfo,
          child: Container(
            margin: const EdgeInsets.all(8),
            height: 40,
            width: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: TColor.lightGray,
                borderRadius: BorderRadius.circular(10)),
            child: Image.asset(
              "assets/img/black_btn.png",
              width: 15,
              height: 15,
              fit: BoxFit.contain,
            ),
          ),
        ),
        title: const Text(
          "Gallery",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        actions: [
          if (selectionMode && selectedIds.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete, color: Colors.redAccent),
              onPressed: _deleteSelected,
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getBodyProgressStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return Center(child: Text("No photos saved yet"));
          }

          // Group by date
          Map<String, List<QueryDocumentSnapshot>> grouped = {};
          for (var doc in docs) {
            DateTime date;
            final rawDate = doc['date'];
            if (rawDate is Timestamp) {
              date = rawDate.toDate();
            } else if (rawDate is String) {
              date = DateTime.parse(rawDate);
            } else {
              continue;
            }

            String key = formatDateKey(date);
            if (!grouped.containsKey(key)) {
              grouped[key] = [];
            }
            grouped[key]!.add(doc);
          }

          return ListView(
            padding: EdgeInsets.all(8),
            children: grouped.entries.map((entry) {
              final date = entry.key;
              final images = entry.value;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    date,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: images.map((doc) {
                      final imageUrl = doc['imageUrl'];
                      final docId = doc.id;
                      final isSelected = selectedIds.contains(docId);

                      return GestureDetector(
                        onLongPress: () {
                          setState(() {
                            selectionMode = true;
                            selectedIds.add(docId);
                          });
                        },
                        onTap: () {
                          if (selectionMode) {
                            _toggleSelection(docId);
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditPhotoView(
                                  imageUrl: imageUrl,
                                  docId: docId,
                                  userHeight: doc['height'] ?? '',
                                  userWeight: doc['weight'] ?? '',
                                  userBodyFat: doc['bodyFat'] ?? '',
                                  userStyle: doc['style'] ?? '',
                                  date: doc['date'],
                                ),
                              ),
                            );
                          }
                        },
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: CachedNetworkImage(
                                imageUrl: imageUrl,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                            if (isSelected)
                              Positioned(
                                top: 5,
                                right: 5,
                                child: CircleAvatar(
                                  backgroundColor: Colors.black54,
                                  radius: 12,
                                  child: Icon(Icons.check,
                                      color: Colors.white, size: 16),
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 16),
                ],
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
