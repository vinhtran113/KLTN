import 'package:flutter/material.dart';
import 'package:readmore/readmore.dart';
import 'package:video_player/video_player.dart';

import '../../common/colo_extension.dart';
import '../../common_widget/step_detail_row.dart';
import '../../model/exercise_model.dart';
import '../../main.dart';
import '../../localization/app_localizations.dart';

class ExercisesStepDetails extends StatefulWidget {
  final Exercise eObj;
  final String diff;
  const ExercisesStepDetails({super.key, required this.eObj, required this.diff});

  @override
  State<ExercisesStepDetails> createState() => _ExercisesStepDetailsState();
}

class _ExercisesStepDetailsState extends State<ExercisesStepDetails> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;
  bool darkmode = darkModeNotifier.value;

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.eObj.video))
      ..initialize().then((_) {
        setState(() {});
      });

    _controller.addListener(() {
      if (_controller.value.position == _controller.value.duration) {
        setState(() {
          _isPlaying = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: darkmode? Colors.blueGrey[900] : TColor.white,
        centerTitle: true,
        elevation: 0,
        leading: InkWell(
          onTap: () {
            Navigator.pop(context);
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
              "assets/img/closed_btn.png",
              width: 15,
              height: 15,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (_isPlaying) {
                      _controller.pause();
                    } else {
                      _controller.play();
                    }
                    _isPlaying = !_isPlaying; // Chuyển đổi trạng thái phát
                  });
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: media.width,
                      height: media.width * 0.43,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: TColor.primaryG),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: _controller.value.isInitialized
                          ? VideoPlayer(_controller)
                          : Center(child: CircularProgressIndicator()), // Hiển thị khi đang tải video
                    ),
                    // Không có lớp phủ ở đây
                    if (!_isPlaying) // Chỉ hiển thị biểu tượng khi video không đang phát
                      const Icon(
                        Icons.play_arrow,
                        size: 30,
                        color: Colors.white,
                      ),
                    if (_isPlaying && _controller.value.position < _controller.value.duration) // Hiện biểu tượng pause khi video đang phát
                      const Icon(
                        Icons.pause,
                        size: 30,
                        color: Colors.white,
                      ),
                  ],
                ),
              ),
              const SizedBox(
                height: 15,
              ),
              Text(
                widget.eObj.name.toString(),
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(
                height: 4,
              ),
              Text(
                "${AppLocalizations.of(context)?.translate(widget.diff.toString()) ?? widget.diff.toString()} | "
                    "${widget.eObj.difficulty[widget.diff]?.calo} ${AppLocalizations.of(context)?.translate("Calories Burned") ?? "Calories Burned"}",
                style: TextStyle(
                  color: darkmode? Colors.white60 : TColor.gray,
                  fontSize: 12,
                ),
              ),
              const SizedBox(
                height: 15,
              ),
              Text(
                AppLocalizations.of(context)?.translate("Descriptions") ?? "Descriptions",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(
                height: 4,
              ),
              ReadMoreText(
                widget.eObj.descriptions.toString(),
                trimLines: 4,
                colorClickableText: darkmode ? TColor.white : TColor.black,
                trimMode: TrimMode.Line,
                trimCollapsedText: AppLocalizations.of(context)?.translate("Read More") ?? "Read More...",
                trimExpandedText: AppLocalizations.of(context)?.translate("Read Less") ?? "Read Less",
                style: TextStyle(
                  color: darkmode ? Colors.white60 : TColor.gray,
                  fontSize: 12,
                ),
                moreStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              const SizedBox(
                height: 15,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)?.translate("How To Do It") ?? "How To Do It",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      "${widget.eObj.steps.length} ${AppLocalizations.of(context)?.translate("Steps") ?? "Steps"}",
                      style: TextStyle(color: TColor.gray, fontSize: 12),
                    ),
                  )
                ],
              ),
              ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: widget.eObj.steps.length,
                itemBuilder: ((context, index ) {
                  var sObj = widget.eObj.steps[index + 1];
                  return StepDetailRow(
                    sObj: sObj,
                    index: index,
                    isLast: widget.eObj.steps.length == index + 1 ,
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}