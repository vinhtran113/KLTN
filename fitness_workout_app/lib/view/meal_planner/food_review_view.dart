import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fitness_workout_app/common/colo_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import '../../main.dart';
import '../../localization/app_localizations.dart';

class FoodReviewView extends StatefulWidget {
  final String foodId;

  const FoodReviewView({super.key, required this.foodId});

  @override
  State<FoodReviewView> createState() => _FoodReviewViewState();
}

class _FoodReviewViewState extends State<FoodReviewView> {
  final currentUser = FirebaseAuth.instance.currentUser;
  double rating = 0;
  final commentController = TextEditingController();
  List<String> mediaUrls = [];
  List<String> tempMediaUrls = []; // Lưu các media vừa upload nhưng chưa submit
  List<String> oldMediaUrls = [];

  bool isLoading = true;
  List<Map<String, dynamic>> reviews = [];
  Map<String, dynamic>? userReview;

  int filterStars = 0;
  bool sortByLatest = true;
  bool darkmode = darkModeNotifier.value;

  int currentPage = 0;
  final int pageSize = 5;

  @override
  void initState() {
    super.initState();
    loadReviews();
  }

  @override
  void dispose() {
    // Xóa các media tạm chưa submit
    for (final url in tempMediaUrls) {
      try {
        FirebaseStorage.instance.refFromURL(url).delete();
      } catch (_) {}
    }
    tempMediaUrls.clear();
    super.dispose();
  }

  bool isVideo(String url) {
    final lower = url.toLowerCase();
    final uri = Uri.parse(lower);
    final path = uri.path;
    return path.endsWith('.mp4') ||
        path.endsWith('.mov') ||
        path.endsWith('.avi') ||
        path.endsWith('.webm') ||
        path.endsWith('.mkv');
  }

  void showVideoDialog(String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(16),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: VideoPlayerWidget(videoUrl: url, autoPlay: true),
        ),
      ),
    );
  }

  void showImageDialog(String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(16),
        child: InteractiveViewer(
          child: Image.network(url),
        ),
      ),
    );
  }

  Future<void> loadReviews() async {
    final reviewsRef = FirebaseFirestore.instance
        .collection('Meals')
        .doc(widget.foodId)
        .collection('Reviews');

    final snapshot =
        await reviewsRef.orderBy('updatedAt', descending: true).get();

    // Lấy dữ liệu review
    reviews = [];
    for (var doc in snapshot.docs) {
      final data = doc.data();
      // Lấy thông tin user
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(data['uid'])
          .get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        data['userName'] =
            '${userData['fname'] ?? ''} ${userData['lname'] ?? ''}'.trim();
        data['userPic'] = userData['pic'] ?? '';
      } else {
        data['userName'] = data['uid'];
        data['userPic'] = '';
      }
      reviews.add(data);
    }

    userReview = reviews.firstWhere((r) => r['uid'] == currentUser!.uid,
        orElse: () => {});

    if (userReview!.isNotEmpty) {
      rating = (userReview!['rating'] ?? 0).toDouble();
      commentController.text = userReview!['comment'] ?? '';
      mediaUrls = List<String>.from(userReview!['mediaUrls'] ?? []);
      oldMediaUrls = List<String>.from(userReview!['mediaUrls'] ?? []);
    }

    setState(() => isLoading = false);
  }

  Future<void> pickAndUploadMedia({required bool isVideo}) async {
    if (mediaUrls.length >= 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Only 6 media files are allowed per review.')),
      );
      return;
    }
    final picker = ImagePicker();
    final pickedFile = await (isVideo
        ? picker.pickVideo(source: ImageSource.gallery)
        : picker.pickImage(source: ImageSource.gallery));
    if (pickedFile != null) {
      final file = pickedFile;
      final ref = FirebaseStorage.instance.ref().child(
          'review_media/${DateTime.now().millisecondsSinceEpoch}_${file.name}');
      final uploadTask = await ref.putData(await file.readAsBytes());
      final url = await ref.getDownloadURL();
      setState(() {
        mediaUrls.add(url);
        tempMediaUrls.add(url); // Đánh dấu là media tạm
      });
    }
  }

  Future<Map<String, dynamic>> getUserInfo(String uid) async {
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (!userDoc.exists) return {};
    final data = userDoc.data()!;
    return {
      'name': '${data['fname'] ?? ''} ${data['lname'] ?? ''}'.trim(),
      'pic': data['pic'] ?? '',
    };
  }

  Future<void> submitReview() async {
    if (rating < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please rate the workout!')),
      );
      return;
    }

    final data = {
      'uid': currentUser!.uid,
      'rating': rating,
      'comment': commentController.text.trim(),
      'mediaUrls': mediaUrls,
      'updatedAt': Timestamp.now(),
    };

    // Xóa media cũ đã bị loại khỏi mediaUrls
    for (final url in oldMediaUrls) {
      if (!mediaUrls.contains(url)) {
        try {
          final ref = FirebaseStorage.instance.refFromURL(url);
          await ref.delete();
        } catch (_) {}
      }
    }

    final reviewRef = FirebaseFirestore.instance
        .collection('Meals')
        .doc(widget.foodId)
        .collection('Reviews')
        .doc(currentUser!.uid);

    await reviewRef.set(data, SetOptions(merge: true));

    tempMediaUrls.clear();
    oldMediaUrls = List<String>.from(mediaUrls);
    await loadReviews();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Your review has been submitted!')),
    );
  }

  List<Map<String, dynamic>> getFilteredReviews() {
    List<Map<String, dynamic>> filtered = [...reviews];

    if (filterStars > 0) {
      filtered = filtered.where((r) => r['rating'] == filterStars).toList();
    }

    filtered.sort((a, b) {
      final aTime = (a['updatedAt'] as Timestamp).toDate();
      final bTime = (b['updatedAt'] as Timestamp).toDate();
      return sortByLatest ? bTime.compareTo(aTime) : aTime.compareTo(bTime);
    });

    return filtered;
  }

  Widget buildMedia(List<String> urls, {bool canDelete = true}) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: urls.map((url) {
        final isVid = isVideo(url);
        return Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onTap: () {
                if (isVid) {
                  showVideoDialog(url);
                } else {
                  showImageDialog(url);
                }
              },
              child: isVid
                  ? Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 120,
                          height: 120,
                          child: VideoPlayerWidget(videoUrl: url),
                        ),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.play_arrow,
                              color: Colors.white, size: 30),
                        ),
                      ],
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        url,
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                    ),
            ),
            if (canDelete)
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () async {
                    setState(() {
                      mediaUrls.remove(url);
                      tempMediaUrls.remove(url);
                    });
                    try {
                      final ref = FirebaseStorage.instance.refFromURL(url);
                      await ref.delete();
                    } catch (_) {}
                  },
                  child: Container(
                    color: Colors.black54,
                    child:
                        const Icon(Icons.close, color: Colors.white, size: 20),
                  ),
                ),
              ),
          ],
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    final filteredReviews = getFilteredReviews();
    List<Map<String, dynamic>> pagedReviews =
        filteredReviews.skip(currentPage * pageSize).take(pageSize).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: darkmode ? Colors.blueGrey[900] : TColor.white,
        centerTitle: true,
        elevation: 0,
        leading: InkWell(
          onTap: () {
            Navigator.pop(context, true);
          },
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
        title: Text(
          AppLocalizations.of(context)?.translate("Review") ?? "Review",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your Review',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            RatingBar.builder(
              initialRating: rating,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: false,
              itemCount: 5,
              itemBuilder: (context, _) =>
                  const Icon(Icons.star, color: Colors.amber),
              onRatingUpdate: (value) => rating = value,
            ),
            TextField(
              controller: commentController,
              decoration: const InputDecoration(labelText: 'Comment Here'),
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            if (mediaUrls.isNotEmpty) buildMedia(mediaUrls, canDelete: true),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.photo),
                  label: const Text('Add Image'),
                  onPressed: () => pickAndUploadMedia(isVideo: false),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.videocam),
                  label: const Text('Add Video'),
                  onPressed: () => pickAndUploadMedia(isVideo: true),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: submitReview,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TColor.primaryColor1,
                  ),
                  child: const Text('Submit'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(thickness: 5),
            const SizedBox(height: 10),
            const Text('All Reviews',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DropdownButton<int>(
                  value: filterStars,
                  hint: const Text('Filter by star'),
                  items: [0, 5, 4, 3, 2, 1].map((value) {
                    return DropdownMenuItem(
                      value: value,
                      child: Text(value == 0 ? 'All' : '$value stars'),
                    );
                  }).toList(),
                  onChanged: (value) =>
                      setState(() => filterStars = value ?? 0),
                ),
                IconButton(
                  icon: Icon(
                      sortByLatest ? Icons.arrow_downward : Icons.arrow_upward),
                  tooltip: 'Sort by date',
                  onPressed: () => setState(() => sortByLatest = !sortByLatest),
                )
              ],
            ),
            ...pagedReviews.map((r) => Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundImage: (r['userPic'] != null &&
                                      r['userPic'].toString().isNotEmpty)
                                  ? NetworkImage(r['userPic'])
                                  : null,
                              child: (r['userPic'] == null ||
                                      r['userPic'].toString().isEmpty)
                                  ? const Icon(Icons.person)
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        r['userName'] ?? '',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      const Spacer(),
                                      Row(
                                        children: List.generate(
                                          (r['rating'] is int)
                                              ? r['rating']
                                              : (r['rating'] is double)
                                                  ? (r['rating'] as double)
                                                      .round()
                                                  : 0,
                                          (index) => const Icon(Icons.star,
                                              size: 16, color: Colors.amber),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    r['updatedAt'] != null
                                        ? DateFormat('dd/MM/yyyy').format(
                                            (r['updatedAt'] as Timestamp)
                                                .toDate())
                                        : '',
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(r['comment'] ?? ''),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        if ((r['mediaUrls'] ?? []).isNotEmpty)
                          buildMedia(List<String>.from(r['mediaUrls']),
                              canDelete: false),
                        if (r['adminReply'] != null)
                          Container(
                            margin: const EdgeInsets.only(top: 8, left: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.blueGrey[50],
                              borderRadius: BorderRadius.circular(8),
                              border:
                                  Border.all(color: Colors.blueGrey, width: 1),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Colors.white,
                                  child: Icon(Icons.person,
                                      color: Colors.blueGrey),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Admin",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blueGrey,
                                        ),
                                      ),
                                      Text(
                                        r['adminReply']['date'] != null
                                            ? DateFormat('dd/MM/yyyy').format(
                                                (r['adminReply']['date']
                                                        as Timestamp)
                                                    .toDate())
                                            : '',
                                        style: const TextStyle(
                                            fontSize: 12, color: Colors.grey),
                                      ),
                                      Text(
                                        r['adminReply']['comment'] ?? '',
                                        style: const TextStyle(
                                            fontStyle: FontStyle.italic),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                )),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_left_sharp, size: 30),
                  onPressed: currentPage > 0
                      ? () => setState(() => currentPage--)
                      : null, // disable nếu ở trang đầu
                  color: currentPage > 0 ? Colors.blue : Colors.grey,
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue),
                  ),
                  child: Text(
                    '${currentPage + 1}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_right_sharp, size: 30),
                  onPressed:
                      ((currentPage + 1) * pageSize < filteredReviews.length)
                          ? () => setState(() => currentPage++)
                          : null, // disable nếu ở trang cuối
                  color: ((currentPage + 1) * pageSize < filteredReviews.length)
                      ? Colors.blue
                      : Colors.grey,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final bool autoPlay;
  const VideoPlayerWidget(
      {super.key, required this.videoUrl, this.autoPlay = false});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late final VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (widget.autoPlay) _controller.play();
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                VideoPlayer(_controller),
                VideoProgressIndicator(_controller, allowScrubbing: true),
                Center(
                  child: IconButton(
                    icon: Icon(
                      _controller.value.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
                      size: 36,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        _controller.value.isPlaying
                            ? _controller.pause()
                            : _controller.play();
                      });
                    },
                  ),
                )
              ],
            ),
          )
        : const Center(child: CircularProgressIndicator());
  }
}
