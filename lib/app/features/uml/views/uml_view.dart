import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/uml_controller.dart';
import '../models/uml_model.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/uml_output_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';

class UmlView extends StatelessWidget {
  final TextEditingController inputController = TextEditingController();
  final UmlController controller = Get.put(UmlController());
  final ScrollController _chatScrollController = ScrollController();
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.transparent,


      drawer: controller.buildDrawer(),

      body:
      Container(
        decoration: BoxDecoration(
          image: DecorationImage(
              repeat: ImageRepeat.noRepeat,
              image: AssetImage("assets/splash.png"),fit: BoxFit.fill),
        ),
        child:Stack(
        children: [
          Positioned.fill(
            child: KeyboardVisibilityBuilder(
              builder: (context, isKeyboardVisible) {
                return Column(
                  children: [
                    // 🔹 Transparent AppBar
                    AppBar(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      iconTheme: const IconThemeData(color: Colors.white),
                      title: Obx(() => Text(
                        controller.currentSessionTitle.value,
                        style: const TextStyle(color: Colors.white),
                      )),
                      centerTitle: true,
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.white),
                          tooltip: 'Rename Session',
                          onPressed: controller.renameSession,
                        ),
                      ],
                    ),

                    // 🎙️ Voice Listening Indicator
                    Obx(() => controller.isListening.value
                        ? Container(
                      width: double.infinity,
                      color: Colors.white,
                      padding: const EdgeInsets.all(8),
                      child: const Center(
                        child: Text(
                          "🎙️ Listening... Speak your requirement",
                          style: TextStyle(color: Colors.deepPurple),
                        ),
                      ),
                    )
                        : const SizedBox()),

                    // 🗨️ Chat Area
                    Expanded(
                      child: Obx(() {
                        final msgs = controller.currentMessages;

                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (_chatScrollController.hasClients) {
                            _chatScrollController.jumpTo(_chatScrollController.position.maxScrollExtent);
                          }
                        });

                        return Stack(
                          children: [
                            ListView.builder(
                              controller: _chatScrollController,
                              padding: const EdgeInsets.symmetric(horizontal: 5),
                              itemCount: msgs.length + (controller.isLoading.value ? 1 : 0),
                              itemBuilder: (ctx, idx) {
                                if (controller.isLoading.value && idx == msgs.length) {
                                  return const Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Center(
                                      child: CircularProgressIndicator(color: Color(0xFF7851A9)),
                                    ),
                                  );
                                }

                                final msg = msgs[idx];
                                final content = msg.content.trim();
                                final umlRegex = RegExp(r'@startuml[\s\S]*?@enduml');
                                final matches = umlRegex.allMatches(content).toList();

                                if (matches.isNotEmpty) {
                                  final output = <Widget>[];
                                  int lastEnd = 0;

                                  for (final match in matches) {
                                    final beforeText = content.substring(lastEnd, match.start).trim();
                                    final umlCode = content
                                        .substring(match.start, match.end)
                                        .replaceAll('```plantuml', '')
                                        .replaceAll('```', '')
                                        .trim();

                                    if (beforeText.isNotEmpty) {
                                      output.add(ChatBubble(message: ChatMessage(content: beforeText, isUser: false)));
                                    }

                                    output.add(UmlOutputCard(umlCode: umlCode));
                                    lastEnd = match.end;
                                  }

                                  final afterText = content.substring(lastEnd).trim();
                                  if (afterText.isNotEmpty) {
                                    output.add(ChatBubble(message: ChatMessage(content: afterText, isUser: false)));
                                  }

                                  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: output);
                                }

                                return ChatBubble(message: msg);
                              },
                            ),

                            // 💡 Empty Chat Hint
                            if (msgs.isEmpty)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(32.0),
                                  child: Text(
                                    '💡 Start your session by describing your system.\nType something to begin...',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.black.withOpacity(0.4),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      }),
                    ),

                    // 💬 Input Field
                    AnimatedPadding(
                      duration: const Duration(milliseconds: 200),
                      padding: EdgeInsets.only(
                        bottom: isKeyboardVisible ? MediaQuery.of(context).viewInsets.bottom : 8,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                        ),
                        child: Obx(() => Row(
                          children: [
                            // ☰ Popup Menu
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, color: Color(0xFF691883)),
                              color: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              onSelected: (value) {
                                if (value == 'file') {
                                  controller.pickFileOrImage();
                                } else if (value == 'voice') {
                                  controller.listenToVoiceInput();
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'file',
                                  child: Row(
                                    children: const [
                                      Icon(Icons.image, color: Color(0xFF691883)),
                                      SizedBox(width: 10),
                                      Text("Pick Image"),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'voice',
                                  child: Row(
                                    children: const [
                                      Icon(Icons.mic, color: Color(0xFF691883)),
                                      SizedBox(width: 10),
                                      Text("Voice Input"),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            // 📝 Text Input
                            Expanded(
                              child: TextField(
                                controller: controller.inputController,
                                enabled: !controller.isLoading.value,
                                decoration: InputDecoration(
                                  hintText: 'Describe your system requirement...',
                                  filled: true,
                                  fillColor: const Color(0xFFF0ECF8),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),

                            // 🚀 Send Button
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              decoration: const BoxDecoration(
                                color: Color(0xFF691883),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.send, color: Colors.white),
                                onPressed: controller.isLoading.value
                                    ? null
                                    : () {
                                  final text = controller.inputController.text.trim();
                                  if (text.isNotEmpty) {
                                    controller.sendPrompt(text);
                                    controller.inputController.clear();
                                  }
                                },
                              ),
                            ),
                          ],
                        )),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    ));

  }

}
