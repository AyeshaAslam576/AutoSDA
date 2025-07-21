class ChatMessage {
  final String content;
  final bool isUser;

  ChatMessage({required this.content, required this.isUser});

  Map<String, dynamic> toJson() => {
    'content': content,
    'isUser': isUser,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    content: json['content'],
    isUser: json['isUser'],
  );
}
