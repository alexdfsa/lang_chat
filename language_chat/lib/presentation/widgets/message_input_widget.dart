import 'package:flutter/material.dart';
import 'package:langchat/domain/entities/virtual_contact.dart';
import 'package:langchat/presentation/signals/audio_signals.dart';
import 'package:langchat/presentation/signals/chat_signals.dart';
import 'package:signals/signals_flutter.dart';
import 'package:speech_to_text/speech_to_text.dart';

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
  final SpeechToText _speechToText = SpeechToText();

  bool _isListening = false;
  bool _speechEnabled = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();

    // Sincronizar controller com signal
    _controller.addListener(() {
      widget.chatSignals.updateTypingMessage(_controller.text);
    });
  }

  void _initSpeech() async {
    // Não precisamos mais do audioSignals para permissão, o speech_to_text cuida disso.
    _speechEnabled = await _speechToText.initialize(
      onError: (error) => print('SpeechToText Error: $error'),
      onStatus: (status) =>
          setState(() => _isListening = _speechToText.isListening),
    );
    setState(() {});
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
          final isSending = widget.chatSignals.isSendingMessage.value;
          final canSend = widget.chatSignals.canSendMessage.value;

          // Se estiver ouvindo, mostre a interface de escuta.
          if (_isListening) {
            return _buildListeningInterface();
          }

          return Row(
            children: [
              // Audio recording button
              IconButton(
                icon: Icon(
                  Icons.mic,
                  color: _speechEnabled
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey,
                ),
                onPressed: _speechEnabled
                    ? (_isListening ? _stopListening : _startListening)
                    : null,
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
                  color:
                      canSend &&
                          !isSending // Use theme color
                      ? Theme.of(context).colorScheme.primary
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
                  onPressed: canSend && !isSending ? _sendMessage : null,
                ),
              ),
            ],
          );
        }),
      ),
    );
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

  /// Inicia a escuta do microfone.
  void _startListening() async {
    // Primeiro, atualiza a UI para mostrar que está ouvindo.
    setState(() {
      _isListening = true;
    });

    await _speechToText.listen(
      onResult: (result) {
        _controller.text = result.recognizedWords;
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length),
        );
      },
      localeId: widget.contact.language, // Usa o idioma do contato!
    );
  }

  /// Para a escuta do microfone.
  void _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  /// Widget da interface de escuta.
  Widget _buildListeningInterface() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.mic, color: Colors.red, size: 28),
          const SizedBox(width: 12),
          Text(
            'Ouvindo...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
