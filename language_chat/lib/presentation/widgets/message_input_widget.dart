import 'package:flutter/material.dart';
import 'package:language_chat/domain/entities/virtual_contact.dart';
import 'package:language_chat/presentation/signals/audio_signals.dart';
import 'package:language_chat/presentation/signals/chat_signals.dart';
import 'package:path_provider/path_provider.dart';
import 'package:signals/signals_flutter.dart';

class MessageInputWidget extends StatefulWidget {
  final VirtualContact contact;
  final ChatSignals chatSignals;
  final AudioSignals audioSignals;

  const MessageInputWidget({
    super.key,
    required this.contact,
    required this.chatSignals,
    required this.audioSignals,
  });

  @override
  State<MessageInputWidget> createState() => _MessageInputWidgetState();
}

class _MessageInputWidgetState extends State<MessageInputWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.audioSignals.requestPermissions();

    // Sincronizar controller com signal
    _controller.addListener(() {
      widget.chatSignals.updateTypingMessage(_controller.text);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        child: Watch((context) {
          final isRecording = widget.audioSignals.isRecording.value;
          final canRecord = widget.audioSignals.canRecord.value;
          final isSending = widget.chatSignals.isSendingMessage.value;
          final typingMessage = widget.chatSignals.typingMessage.value;

          if (isRecording) {
            return _buildRecordingInterface();
          }

          return Row(
            children: [
              // Audio recording button
              IconButton(
                icon: Icon(
                  Icons.mic,
                  color: canRecord ? const Color(0xFF128C7E) : Colors.grey,
                ),
                onPressed: canRecord ? _startRecording : null,
              ),

              // Text input field
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.send,
                    decoration: const InputDecoration(
                      hintText: 'Digite sua mensagem...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (text) {
                      if (text.trim().isNotEmpty && !isSending) {
                        _sendMessage();
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Send button
              Container(
                decoration: BoxDecoration(
                  color: _canSend() && !isSending
                      ? const Color(0xFF128C7E)
                      : Colors.grey,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Icon(Icons.send, color: Colors.white),
                  onPressed: _canSend() && !isSending ? _sendMessage : null,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  bool _canSend() {
    return _controller.text.trim().isNotEmpty;
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    print('🚀 Enviando mensagem: "$text"'); // Debug

    try {
      // Limpar campo imediatamente
      _controller.clear();
      widget.chatSignals.updateTypingMessage('');
      _focusNode.unfocus();

      // Enviar mensagem
      await widget.chatSignals.sendMessage(text, widget.contact);

      print('✅ Mensagem enviada com sucesso'); // Debug
    } catch (e) {
      print('❌ Erro ao enviar mensagem: $e'); // Debug

      // Mostrar erro para o usuário
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao enviar mensagem: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildRecordingInterface() {
    return Watch((context) {
      final recordingDuration = widget.audioSignals.recordingDuration.value;
      final hasPermissions = widget.audioSignals.hasPermissions.value;

      if (!hasPermissions) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.mic_off, color: Colors.red[700]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Permissão de microfone necessária para gravação',
                  style: TextStyle(color: Colors.red[700]),
                ),
              ),
              TextButton(
                onPressed: () => widget.audioSignals.requestPermissions(),
                child: const Text('Permitir'),
              ),
            ],
          ),
        );
      }

      return Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF128C7E).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Cancel recording
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () {
                widget.audioSignals.stopRecording();
                widget.audioSignals.reset();
              },
            ),

            // Recording indicator and duration
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Gravando... ${_formatDuration(recordingDuration)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF128C7E),
                    ),
                  ),
                ],
              ),
            ),

            // Send recording
            IconButton(
              icon: const Icon(Icons.send, color: Color(0xFF128C7E)),
              onPressed: _sendAudioMessage,
            ),
          ],
        ),
      );
    });
  }

  void _startRecording() async {
    print('🎤 Iniciando gravação'); // Debug

    try {
      // Gerar um path único para o arquivo de áudio
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${directory.path}/audio_$timestamp.aac';

      await widget.audioSignals.startRecording(filePath);

      print('🎤 Gravação iniciada: $filePath'); // Debug
    } catch (e) {
      print('❌ Erro ao iniciar gravação: $e'); // Debug
    }
  }

  void _sendAudioMessage() async {
    print('🎵 Enviando mensagem de áudio'); // Debug

    try {
      final audioPath = await widget.audioSignals.stopRecording();
      if (audioPath != null) {
        await widget.chatSignals.sendAudioMessage(audioPath, widget.contact);
        print('✅ Mensagem de áudio enviada'); // Debug
      }
      widget.audioSignals.reset();
    } catch (e) {
      print('❌ Erro ao enviar áudio: $e'); // Debug
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
