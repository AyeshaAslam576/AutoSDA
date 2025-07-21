import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../models/uml_model.dart';
import '../../services/ai_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../services/input_service.dart';
class UmlController extends GetxController {
  final box = GetStorage();
  final inputController = TextEditingController();
  /// Chat sessions: { sessionId : [messages] }
  RxMap<String, List<ChatMessage>> allSessions = <String, List<ChatMessage>>{}.obs;

  /// Titles for sessions
  RxMap<String, String> sessionTitles = <String, String>{}.obs;
  RxString currentSessionId = ''.obs;

  RxBool isLoading = false.obs;
  final ImagePicker _imagePicker = ImagePicker();
  late stt.SpeechToText _speech;
  RxBool isListening = false.obs;
  /// Convenient getters
  List<ChatMessage> get currentMessages => allSessions[currentSessionId.value] ?? [];
  RxString get currentSessionTitle => (sessionTitles[currentSessionId.value] ?? 'New Session').obs;

  @override
  void onInit() {
    super.onInit();
    _speech = stt.SpeechToText();
    loadSessions();
    if (allSessions.isEmpty) {
      createNewSession(); // Init first session
    }
  }

  /// Load from local storage
  void loadSessions() {
    final saved = box.read('chat_sessions');
    final titles = box.read('chat_titles');
    if (saved != null) {
      allSessions.assignAll(Map<String, List>.from(saved).map(
            (key, value) => MapEntry(key, value.map((m) => ChatMessage.fromJson(m)).toList()),
      ));
    }
    if (titles != null) {
      sessionTitles.assignAll(Map<String, String>.from(titles));
    }
  }

  /// Save all sessions
  void saveSessions() {
    final jsonSessions = allSessions.map((key, list) => MapEntry(
      key,
      list.map((m) => m.toJson()).toList(),
    ));
    box.write('chat_sessions', jsonSessions);
    box.write('chat_titles', sessionTitles);
  }

  /// Create a new chat session
  void createNewSession() {
    final currentId = currentSessionId.value;
    final currentMsgs = allSessions[currentId];

    // 🚫 Prevent new session if current is empty
    if (currentMsgs == null || currentMsgs.isEmpty) {
      Get.snackbar('⚠️ Empty Session', 'Finish or delete the current session before starting a new one.');
      return;
    }

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    allSessions[id] = [];
    sessionTitles[id] = 'Session ${allSessions.length}';
    currentSessionId.value = id;
    saveSessions();
  }


  /// Switch to another session
  void switchSession(String id) {
    currentSessionId.value = id;
  }
  void renameSession() async {
    final controller = TextEditingController(text: sessionTitles[currentSessionId.value]);
    final newName = await Get.dialog<String>(
      AlertDialog(
        title: const Text('Rename Session'),
        content: TextField(controller: controller),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(onPressed: () => Get.back(result: controller.text), child: const Text('Save')),
        ],
      ),
    );
    if (newName != null && newName.trim().isNotEmpty) {
      sessionTitles[currentSessionId.value] = newName.trim();
      saveSessions();
    }
  }

  /// Export current chat as .txt




  /// Build drawer with session list
  Widget buildDrawer() {
    return Drawer(
      width:250,
      backgroundColor: Color(0xffFBEEFF),
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xffB148D2),
            ),
            margin: EdgeInsets.zero,
            padding: EdgeInsets.zero,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              child: Image.asset(
                'assets/robot.png',
                fit: BoxFit.cover,
              ),

          ),
          ),


          ListTile(

          tileColor: Colors.white,
            leading: const Icon(Icons.add,color: Colors.black),
            title: const Text("New Chat",style: TextStyle(color: Colors.black),),
            onTap: () {
              createNewSession();
              Get.back();
            },
          ),

          Expanded(
            child: Obx(() => ListView(
              children: allSessions.keys.map((id) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: ListTile(
tileColor: Colors.white,
                    title: Text(sessionTitles[id] ?? 'Untitled',style: TextStyle(color: Colors.black),),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (currentSessionId.value == id)
                          const Icon(Icons.check, color:Color(0xff691883),),
                        PopupMenuButton<String>(
                          color: Color(0xFFf3ccff),
                          onSelected: (choice) async {
                            if (choice == 'rename') {
                              final controller = TextEditingController(text: sessionTitles[id]);
                              final newName = await Get.dialog<String>(
                                AlertDialog(
                                  title: const Text('Rename Session',style: TextStyle(color: Colors.white),),
                                  content: TextField(controller: controller),
                                  actions: [
                                    TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
                                    TextButton(onPressed: () => Get.back(result: controller.text), child: const Text('Save')),
                                  ],
                                ),
                              );
                              if (newName != null && newName.trim().isNotEmpty) {
                                sessionTitles[id] = newName.trim();
                                saveSessions();
                              }
                            } else if (choice == 'delete') {
                              if (id == currentSessionId.value) {
                                Get.snackbar('⚠️ Cannot Delete', 'You cannot delete the current session.');
                              } else {
                                allSessions.remove(id);
                                sessionTitles.remove(id);
                                saveSessions();
                              }
                            }

                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'rename', child: Text('Rename',style: TextStyle(color: Colors.white),)),

                            const PopupMenuItem(value: 'delete', child: Text('Delete',style: TextStyle(color: Colors.white),)),

                          ],
                        ),
                      ],
                    ),
                    onTap: () {
                      switchSession(id);
                      Get.back();
                    },
                  ),
                );
              }).toList(),
            )),
          ),
        ],
      ),
    );
  }


  /// Send user prompt and add response
  Future<void> sendPrompt(String prompt) async {
    final session = currentSessionId.value;

    // ✅ Ensure session exists
    if (!allSessions.containsKey(session)) {
      allSessions[session] = [];
    }

    allSessions[session]!.add(ChatMessage(content: prompt, isUser: true));
    isLoading.value = true;
    saveSessions();

    try {
      final response = await AiService.sendToOpenAI(prompt);
      allSessions[session]!.add(ChatMessage(content: response, isUser: false));
    } catch (e) {
      allSessions[session]!.add(ChatMessage(content: "❌ Failed to get response: $e", isUser: false));
    } finally {
      isLoading.value = false;
      saveSessions();
    }
  }


  /// Placeholder — already defined
  Future<void> pickFileOrImage() async {
    final choice = await Get.bottomSheet<String>(
      Container(

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),// Full background
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPickerTile(
              icon: Icons.photo_library,
              label: 'Pick Image from Gallery',
              onTap: () => Get.back(result: 'image'),
            ),
            const SizedBox(height: 10),
            _buildPickerTile(
              icon: Icons.camera_alt,
              label: 'Take Photo',
              onTap: () => Get.back(result: 'camera'),
            ),
            const SizedBox(height: 10),
            _buildPickerTile(
              icon: Icons.picture_as_pdf,
              label: 'Pick PDF Document',
              onTap: () => Get.back(result: 'pdf'),
            ),
          ],
        ),
      ),
      isScrollControlled: false,
      backgroundColor: Colors.transparent,
    );

    try {
      String? text;

      if (choice == 'pdf') {
        final picked = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
        if (picked != null) {
          final file = File(picked.files.single.path!);
          text = await InputService.extractTextFromPdf(file);
        }
      } else if (choice == 'image' || choice == 'camera') {
        final picked = await _imagePicker.pickImage(
          source: choice == 'camera' ? ImageSource.camera : ImageSource.gallery,
        );

        if (picked != null) {
          final image = File(picked.path);
          print("📸 Picked path: ${picked.path}");
          if (!await image.exists()) {
            print("🚫 Picked image does not exist");
            return;
          }

          try {
            text = await InputService.extractTextFromImage(image);
          } catch (e) {
            print("❌ OCR extraction error: $e");
            Get.snackbar('OCR Error', 'Could not extract text from image',backgroundColor: Colors.white);
          }
        }
      }
      if (text != null && text.trim().isNotEmpty) {
        inputController.text = text.trim();
        Get.snackbar('✅ Text Extracted', 'You can now edit or submit.',backgroundColor: Colors.white);
      }
    } catch (e) {
      Get.snackbar('❌ Error', 'Failed to process input: $e',backgroundColor: Colors.white);
    }
  }

  Widget _buildPickerTile({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFE79AFF),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }



  Future<void> listenToVoiceInput() async {
    final available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          isListening.value = false;
        }
      },
      onError: (error) {
        isListening.value = false;
        Get.snackbar('❌ Voice Error', error.errorMsg ?? 'Unknown error',backgroundColor: Colors.white);
      },
    );

    if (!available) {
      Get.snackbar('🎙️ Voice Input', '❌ Speech recognition not available',backgroundColor: Colors.white);
      return;
    }

    isListening.value = true;

    _speech.listen(
      listenFor: const Duration(seconds: 15),
      pauseFor: const Duration(seconds: 2),
      cancelOnError: true,
      partialResults: true,
      onResult: (result) {
        inputController.text = result.recognizedWords; // 🔄 Live typing!
      },
    );
  }



}
