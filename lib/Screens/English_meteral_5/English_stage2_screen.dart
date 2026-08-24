import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lets_talk/Screens/widgets/StageAttendanceWidget.dart';
import 'package:path_provider/path_provider.dart';

class EnglishStage2Screen extends StatelessWidget {
  const EnglishStage2Screen({super.key});

  @override
  Widget build(BuildContext context) {
    final Color deepOceanBlue = const Color(0xff065381);
    final Color tealMist = const Color(0xff508F97);
    final Color goldenYellow = const Color(0xffF2C94C);
    final Color backgroundColor = const Color(0xff0A0A0E);
    final Color cardColor = const Color(0xff14141E);

    final List<Map<String, dynamic>> daysData = [
      {
        "day": "Day 1",
        "title": "Stage 2 Orientation & Demo",
        "subtitle": "Overview of modal expressions & imperative forms",
        "pdfPath": null,
        "isPractice": false,
      },
      {
        "day": "Day 2",
        "title": "Order (1 & 2)",
        "subtitle": "Giving commands, instructions & imperative rules",
        "pdfPath": "assets/images/satge2/Day-2_ST-2_Eng (Order-1&2).pdf",
        "isPractice": false,
      },
      {
        "day": "Day 3",
        "title": "Request (1 & 2)",
        "subtitle": "Polite requests & conversational phrasing",
        "pdfPath": "assets/images/satge2/Day-3_ST-2_Eng (Request-1&2).pdf",
        "isPractice": false,
      },
      {
        "day": "Day 4",
        "title": "Permission (1 & 2)",
        "subtitle": "Asking, granting & denying permission",
        "pdfPath": "assets/images/satge2/Day-4_ST-2_Eng (Permission 1&2).pdf",
        "isPractice": false,
      },
      {
        "day": "Day 5",
        "title": "Suggestion (1 & 2)",
        "subtitle": "Offering advice, recommendations & ideas",
        "pdfPath": "assets/images/satge2/Day-5_ST-2_Eng (Suggestion 1&2).pdf",
        "isPractice": false,
      },
      {
        "day": "Day 6",
        "title": "Practice on Imperative Sentences",
        "subtitle": "Consolidated drills on orders, requests & suggestions",
        "pdfPath":
            "assets/images/satge2/Day-6_ST-2_Eng (🔴Practice on Imperative sentences).pdf",
        "isPractice": true,
      },
      {
        "day": "Day 7",
        "title": "Past Habit (1)",
        "subtitle": "Expressing past routines and states",
        "pdfPath": "assets/images/satge2/Day-7_ST-2_Eng (Past habit-1).pdf",
        "isPractice": false,
      },
      {
        "day": "Day 8",
        "title": "Past Habit (2, 3 & 4)",
        "subtitle": "Advanced past habitual structures",
        "pdfPath":
            "assets/images/satge2/Day-8_ST-2_Eng (Past habit-2,3 & 4).pdf",
        "isPractice": false,
      },
      {
        "day": "Day 9",
        "title": "Present Habit (2, 3 & 4)",
        "subtitle": "Ongoing lifestyle habits & tendencies",
        "pdfPath":
            "assets/images/satge2/Day-9_ST-2_Eng (Present habit-2,3 & 4).pdf",
        "isPractice": false,
      },
      {
        "day": "Day 10",
        "title": "Future Habit (2 & 4)",
        "subtitle": "Forming future habitual expressions",
        "pdfPath":
            "assets/images/satge2/Day-10_ST-2_Eng (Future habit-2 & 4).pdf",
        "isPractice": false,
      },
      {
        "day": "Day 11",
        "title": "Past Permanent Ability vs Past Simple",
        "subtitle": "Could vs managed to / was able to comparison",
        "pdfPath":
            "assets/images/satge2/Day-11_ST-2_Eng (Past permanent ability comparison with past simple).pdf",
        "isPractice": false,
      },
      {
        "day": "Day 12",
        "title": "Past Temporary Ability vs Past Continuous",
        "subtitle": "Situational capabilities in the past",
        "pdfPath":
            "assets/images/satge2/Day-12_ST-2_Eng (Past temporary ability comparison with past continuous).pdf",
        "isPractice": false,
      },
      {
        "day": "Day 13",
        "title": "Present Permanent Ability vs Present Simple",
        "subtitle": "Inherent skills & general present capabilities",
        "pdfPath":
            "assets/images/satge2/Day-13_ST-2_Eng (Present permanent ability comparison with present simple).pdf",
        "isPractice": false,
      },
      {
        "day": "Day 14",
        "title": "Present Temporary Ability vs Present Continuous",
        "subtitle": "Short-term capacity vs ongoing activities",
        "pdfPath":
            "assets/images/satge2/Day-14_ST-2_Eng (Present temporary ability comparison with Present continuous).pdf",
        "isPractice": false,
      },
      {
        "day": "Day 15",
        "title": "Future Ability Comparison",
        "subtitle": "Permanent & temporary abilities in future tenses",
        "pdfPath":
            "assets/images/satge2/Day-15_ST-2_Eng (Future permanent & temporary ability comparison with future simple & continuous).pdf",
        "isPractice": false,
      },
      {
        "day": "Day 16",
        "title": "Practice on Ability, Simple & Continuous",
        "subtitle": "Integrated exercises across all ability forms",
        "pdfPath":
            "assets/images/satge2/Day-16_ST-2_Eng (🔴 Practice on Ability, Simple & Continuous).pdf",
        "isPractice": true,
      },
      {
        "day": "Day 17",
        "title": "Past Willingness (1)",
        "subtitle": "Desire and willingness expressions in past",
        "pdfPath":
            "assets/images/satge2/Day-17_ST-2_Eng (Past willingness-1).pdf",
        "isPractice": false,
      },
      {
        "day": "Day 18",
        "title": "Past Willingness (2)",
        "subtitle": "Complex past intentions & reluctance",
        "pdfPath":
            "assets/images/satge2/Day-18_ST-2_Eng (Past willingness-2).pdf",
        "isPractice": false,
      },
      {
        "day": "Day 19",
        "title": "Present Willingness (1)",
        "subtitle": "Readiness and voluntary actions in present",
        "pdfPath":
            "assets/images/satge2/Day-19_ST-2_Eng (Present willingness-1).pdf",
        "isPractice": false,
      },
      {
        "day": "Day 20",
        "title": "Present Willingness (2)",
        "subtitle": "Nuanced willingness and preference phrasing",
        "pdfPath":
            "assets/images/satge2/Day-20_ST-2_Eng (Present willingness-2).pdf",
        "isPractice": false,
      },
      {
        "day": "Day 21",
        "title": "Practice on Past & Present Willingness (1 & 2)",
        "subtitle": "Drills and conversational applications",
        "pdfPath":
            "assets/images/satge2/Day-21_ST-2_Eng (🔴Practice on Past & Present willingness-1&2).pdf",
        "isPractice": true,
      },
      {
        "day": "Day 22",
        "title": "Past, Present & Future Willingness (3)",
        "subtitle": "Comprehensive tri-tense willingness structures",
        "pdfPath":
            "assets/images/satge2/Day-22_ST-2_Eng (Past, Present & Future willingness-3).pdf",
        "isPractice": false,
      },
      {
        "day": "Day 23",
        "title": "Past, Present & Future Compulsion",
        "subtitle": "Have to / Had to / Will have to obligation models",
        "pdfPath":
            "assets/images/satge2/Day-23_ST-2_Eng (Past, Present & Future compulsion).pdf",
        "isPractice": false,
      },
      {
        "day": "Day 24",
        "title": "Lower Modals",
        "subtitle": "May, might, can & could nuance exploration",
        "pdfPath": "assets/images/satge2/Day-24_ST-2_Eng (Lower modals).pdf",
        "isPractice": false,
      },
      {
        "day": "Day 25",
        "title": "Integration of Lower Modals",
        "subtitle": "Practical usage of probability and permission",
        "pdfPath":
            "assets/images/satge2/Day-25_ST-2_Eng (Integration of lower modals).pdf",
        "isPractice": false,
      },
      {
        "day": "Day 26",
        "title": "Integration of Would (Used To)",
        "subtitle": "Hypotheticals vs repeated past habitual actions",
        "pdfPath":
            "assets/images/satge2/Day-26_ST-2_Eng (Integration of would [used to]).pdf",
        "isPractice": false,
      },
      {
        "day": "Day 27",
        "title": "Gerund",
        "subtitle": "Verb-nouns (-ing forms) as subjects and objects",
        "pdfPath": "assets/images/satge2/Day-27_ST-2_Eng (Gerund).pdf",
        "isPractice": false,
      },
      {
        "day": "Day 28",
        "title": "It Function",
        "subtitle": "Dummy subject 'It' in weather, time & conditions",
        "pdfPath": "assets/images/satge2/Day-28_ST-2_Eng (It function).pdf",
        "isPractice": false,
      },
    ];

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 18,
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          "English Material • Stage 2",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: deepOceanBlue.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: tealMist.withOpacity(0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.menu_book_rounded, size: 14, color: goldenYellow),
                const SizedBox(width: 6),
                Text(
                  "28 Days",
                  style: GoogleFonts.poppins(
                    color: goldenYellow,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          const StageAttendanceWidget(stageName: "Stage 2"),
          const SizedBox(height: 6),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              physics: const BouncingScrollPhysics(),
              itemCount: daysData.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final dayItem = daysData[index];
                final String day = dayItem["day"];
                final String title = dayItem["title"];
                final String subtitle = dayItem["subtitle"];
                final String? pdfPath = dayItem["pdfPath"];
                final bool isPractice = dayItem["isPractice"] ?? false;
                final bool isPdfAvailable = pdfPath != null;

                return GestureDetector(
                  onTap: () {
                    if (isPdfAvailable) {
                      Get.to(
                        () => PdfViewerScreen(
                          title: "$day: $title",
                          assetPath: pdfPath,
                        ),
                      );
                    } else {
                      Get.defaultDialog(
                        title: "Day 1 Demo Class",
                        titlePadding: const EdgeInsets.only(top: 20, bottom: 8),
                        titleStyle: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        middleText:
                            "Day 1 is an interactive Demo Class & Orientation session conducted live by the teacher. No PDF reading required.",
                        middleTextStyle: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                        backgroundColor: cardColor,
                        radius: 16,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        confirm: SizedBox(
                          width: 100,
                          height: 40,
                          child: ElevatedButton(
                            onPressed: () => Get.back(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: deepOceanBlue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              "OK",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isPractice
                            ? const Color(0xffEF4444).withOpacity(0.4)
                            : isPdfAvailable
                            ? tealMist.withOpacity(0.3)
                            : Colors.white.withOpacity(0.06),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isPractice
                                ? const Color(0xffEF4444).withOpacity(0.15)
                                : isPdfAvailable
                                ? deepOceanBlue.withOpacity(0.25)
                                : Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isPractice
                                  ? const Color(0xffEF4444).withOpacity(0.4)
                                  : isPdfAvailable
                                  ? tealMist.withOpacity(0.4)
                                  : Colors.white10,
                            ),
                          ),
                          child: Icon(
                            isPractice
                                ? Icons.fitness_center_rounded
                                : isPdfAvailable
                                ? Icons.picture_as_pdf_rounded
                                : Icons.play_lesson_rounded,
                            color: isPractice
                                ? const Color(0xffEF4444)
                                : isPdfAvailable
                                ? goldenYellow
                                : Colors.grey,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isPractice
                                          ? const Color(
                                              0xffEF4444,
                                            ).withOpacity(0.15)
                                          : tealMist.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      day,
                                      style: GoogleFonts.poppins(
                                        color: isPractice
                                            ? const Color(0xffEF4444)
                                            : tealMist,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      title,
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                subtitle,
                                style: GoogleFonts.poppins(
                                  color: Colors.grey.shade400,
                                  fontSize: 11.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          isPdfAvailable
                              ? Icons.arrow_forward_ios_rounded
                              : Icons.info_outline_rounded,
                          color: isPractice
                              ? const Color(0xffEF4444)
                              : isPdfAvailable
                              ? goldenYellow
                              : Colors.grey,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class PdfViewerScreen extends StatefulWidget {
  final String title;
  final String assetPath;

  const PdfViewerScreen({
    super.key,
    required this.title,
    required this.assetPath,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  String? localPath;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPdfFromAsset();
  }

  Future<void> _loadPdfFromAsset() async {
    try {
      final bytes = await rootBundle.load(widget.assetPath);
      final dir = await getTemporaryDirectory();
      final filename = widget.assetPath.split('/').last;
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);

      if (mounted) {
        setState(() {
          localPath = file.path;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color cardColor = Color(0xff14141E);
    const Color backgroundColor = Color(0xff0A0A0E);
    const Color goldenYellow = Color(0xffF2C94C);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 18,
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          widget.title,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: goldenYellow))
          : localPath != null
          ? PDFView(
              filePath: localPath,
              enableSwipe: true,
              swipeHorizontal: false,
              autoSpacing: true,
              pageFling: true,
              pageSnap: true,
              fitPolicy: FitPolicy.BOTH,
            )
          : Center(
              child: Text(
                "Unable to load document.",
                style: GoogleFonts.poppins(color: Colors.grey, fontSize: 13),
              ),
            ),
    );
  }
}
