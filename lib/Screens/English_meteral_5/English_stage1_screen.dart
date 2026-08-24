import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lets_talk/Screens/widgets/StageAttendanceWidget.dart';
import 'package:path_provider/path_provider.dart';

class EnglishStage1Screen extends StatelessWidget {
  const EnglishStage1Screen({super.key});

  @override
  Widget build(BuildContext context) {
    // --- BRAND PALETTE ---
    final Color deepOceanBlue = const Color(0xff065381);
    final Color tealMist = const Color(0xff508F97);
    final Color goldenYellow = const Color(0xffF2C94C);
    final Color backgroundColor = const Color(0xff0A0A0E);
    final Color cardColor = const Color(0xff14141E);

    final List<Map<String, dynamic>> daysData = [
      {
        "day": "Day 1",
        "title": "Demo Class & Orientation",
        "subtitle": "Spoken introduction & foundation session",
        "pdfPath": null,
        "isPractice": false,
      },
      {
        "day": "Day 2",
        "title": "Past Be",
        "subtitle": "Basic Past Be verb concepts & rules",
        "pdfPath": "assets/images/satge1/Day-2_English_ST-1_(Past Be).pdf",
        "isPractice": false,
      },
      {
        "day": "Day 3",
        "title": "Past Be",
        "subtitle": "Past Be sentences & practical usage",
        "pdfPath": "assets/images/satge1/Day-3_English_ST-1 (Past Be).pdf",
        "isPractice": false,
      },
      {
        "day": "Day 4",
        "title": "Present Be",
        "subtitle": "Present Be verb forms & structures",
        "pdfPath": "assets/images/satge1/Day-4_English_ST-1 (Pre Be).pdf",
        "isPractice": false,
      },
      {
        "day": "Day 5",
        "title": "Future Be",
        "subtitle": "Future Be structure & conversation",
        "pdfPath": "assets/images/satge1/Day-5_English_ST-1 (Future Be).pdf",
        "isPractice": false,
      },
      {
        "day": "Day 6",
        "title": "Articles & Practice On Be",
        "subtitle": "A, An, The usage & consolidated exercises",
        "pdfPath":
            "assets/images/satge1/Day-6_ST-1_Eng (Articles & Practice On Be).pdf",
        "isPractice": false,
      },
      {
        "day": "Day 7",
        "title": "There Form",
        "subtitle": "Usage of 'There' as intro subject",
        "pdfPath": "assets/images/satge1/Day-7_ST-1_Eng (There Form).pdf",
        "isPractice": false,
      },
      {
        "day": "Day 8",
        "title": "Past Have",
        "subtitle": "Possessive forms in past tense",
        "pdfPath": "assets/images/satge1/Day-8_ST-1_Eng (Past Have).pdf",
        "isPractice": false,
      },
      {
        "day": "Day 9",
        "title": "Present Have",
        "subtitle": "Has / Have affirmative & negative",
        "pdfPath": "assets/images/satge1/Day-9_ST-1_Eng (Present Have).pdf",
        "isPractice": false,
      },
      {
        "day": "Day 10",
        "title": "Future Have",
        "subtitle": "Will have possession concepts",
        "pdfPath": "assets/images/satge1/Day-10_ST-1_Eng (Future Have).pdf",
        "isPractice": false,
      },
      {
        "day": "Day 11",
        "title": "Practice On Be, There & Have",
        "subtitle": "Integrated revision & spoken drill",
        "pdfPath":
            "assets/images/satge1/Day-11_ST-1_Eng (🔴Practice On Be, There & Have).pdf",
        "isPractice": true,
      },
      {
        "day": "Day 12",
        "title": "Formation Of Action Verbs",
        "subtitle": "Regular & irregular verb conjugations",
        "pdfPath":
            "assets/images/satge1/Day-12_ST-1_Eng (Formation Of Action Verbs).pdf",
        "isPractice": false,
      },
      {
        "day": "Day 13",
        "title": "Past Simple A.V",
        "subtitle": "Past simple active voice sentence structures",
        "pdfPath": "assets/images/satge1/Day-13_ST-1_Eng (Past Simple A.V).pdf",
        "isPractice": false,
      },
      {
        "day": "Day 14",
        "title": "Present Simple A.V",
        "subtitle": "Daily routines & present habits",
        "pdfPath":
            "assets/images/satge1/Day-14_ST-1_Eng (Present Simple A.V).pdf",
        "isPractice": false,
      },
      {
        "day": "Day 15",
        "title": "Future Simple A.V",
        "subtitle": "Future plans & immediate predictions",
        "pdfPath":
            "assets/images/satge1/Day-15_ST-1_Eng (Future Simple A.V).pdf",
        "isPractice": false,
      },
      {
        "day": "Day 16",
        "title": "Practice On Simple A.V",
        "subtitle": "Comprehensive active voice exercises",
        "pdfPath":
            "assets/images/satge1/Day-16_ST-1_Eng (🔴Practice On Simple A.V).pdf",
        "isPractice": true,
      },
      {
        "day": "Day 17",
        "title": "Past Simple Passive Voice",
        "subtitle": "Past passive constructions & examples",
        "pdfPath":
            "assets/images/satge1/Day-17_ST-1_Eng (Past Simple Passive Voice).pdf",
        "isPractice": false,
      },
      {
        "day": "Day 18",
        "title": "Present Simple P.V",
        "subtitle": "Passive voice transformations in present",
        "pdfPath":
            "assets/images/satge1/Day-18_ST-1_Eng (Present Simple P.V).pdf",
        "isPractice": false,
      },
      {
        "day": "Day 19",
        "title": "Future Simple P.V",
        "subtitle": "Passive voice usage for future tense",
        "pdfPath":
            "assets/images/satge1/Day-19_ST-1_Eng (Future Simple P.V).pdf",
        "isPractice": false,
      },
      {
        "day": "Day 20",
        "title": "Practice On Simple A.V & P.V",
        "subtitle": "Active vs passive comparison & drills",
        "pdfPath":
            "assets/images/satge1/Day-20_ST-1_Eng (🔴Practice On Simple A.V & P.V).pdf",
        "isPractice": true,
      },
      {
        "day": "Day 21",
        "title": "Past Continuous A.V & P.V",
        "subtitle": "Ongoing past actions active & passive",
        "pdfPath":
            "assets/images/satge1/Day-21_ST-1_Eng (Past Continuous A.V & P.V).pdf",
        "isPractice": false,
      },
      {
        "day": "Day 22",
        "title": "Present Continuous A.V & P.V",
        "subtitle": "Ongoing events active & passive",
        "pdfPath":
            "assets/images/satge1/Day-22_ST-1_Eng (Present Continuous A.V & P.V).pdf",
        "isPractice": false,
      },
      {
        "day": "Day 23",
        "title": "Future Continuous A.V",
        "subtitle": "Future continuous actions & sentence rules",
        "pdfPath":
            "assets/images/satge1/Day-23_ST-1_Eng (Future Continuous A.V).pdf",
        "isPractice": false,
      },
      {
        "day": "Day 24",
        "title": "Practice on Simple & Continuous A.V & P.V",
        "subtitle": "Multi-tense continuous & simple drills",
        "pdfPath":
            "assets/images/satge1/Day-24_ST-1_Eng (🔴Practice on Simple & Continuous A.v & P.v).pdf",
        "isPractice": true,
      },
      {
        "day": "Day 25",
        "title": "Past Simple Make, Let & Get",
        "subtitle": "Causative verbs in the past tense",
        "pdfPath":
            "assets/images/satge1/Day-25_ST-1_Eng (Past Simple Make, Let & Get-Causative verbs).pdf",
        "isPractice": false,
      },
      {
        "day": "Day 26",
        "title": "Present Simple M.L.G",
        "subtitle": "Make, Let, Get causative structures",
        "pdfPath":
            "assets/images/satge1/Day-26_ST-1_Eng (Present Simple M.L.G).pdf",
        "isPractice": false,
      },
      {
        "day": "Day 27",
        "title": "Future Simple M.L.G",
        "subtitle": "Future causative applications",
        "pdfPath":
            "assets/images/satge1/Day-27_ST-1_Eng (Future Simple M.L.G).pdf",
        "isPractice": false,
      },
      {
        "day": "Day 28",
        "title": "Past & Present Continuous M.L.G",
        "subtitle": "Continuous causative verb expressions",
        "pdfPath":
            "assets/images/satge1/Day-28_ST-1_Eng (Past & Present Continuous M.L.G).pdf",
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
          "English Material • Stage 1",
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
          const StageAttendanceWidget(stageName: "Stage 1"),
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

// --- FULLSCREEN NATIVE PDF VIEWER ---
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
