import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:io';
import 'package:agenda/controller/firestore_service.dart';
import 'package:agenda/controller/config_model.dart';
import 'package:agenda/controller/chat_model.dart';
import 'package:agenda/view/app_strings.dart';
import 'package:agenda/view/app_styles.dart';
import 'package:intl/intl.dart';
import 'package:agenda/widgets/full_screen_image_view.dart';

class ChatAgendamentoView extends StatefulWidget {
  final String agendamentoId;
  final String titulo;
  final String? telefoneWhatsapp; // Opcional, para fallback

  const ChatAgendamentoView({
    super.key, 
    required this.agendamentoId, 
    required this.titulo,
    this.telefoneWhatsapp,
  });

  @override
  State<ChatAgendamentoView> createState() => _ChatAgendamentoViewState();
}

class _ChatAgendamentoViewState extends State<ChatAgendamentoView> {
  final TextEditingController _controller = TextEditingController();
  final FirestoreService _service = FirestoreService();
  final String _uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  ConfigModel? _config;
  bool _isLoadingConfig = true;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _carregarConfig();
    // Marca como lida ao entrar na tela
    _service.marcarMensagensComoLidas(widget.agendamentoId, _uid);
  }

  Future<void> _carregarConfig() async {
    _config = await _service.getConfiguracao();
    if (mounted) setState(() => _isLoadingConfig = false);
  }

  void _enviar() {
    if (_controller.text.trim().isEmpty || _isUploading) return;
    _service.enviarMensagem(widget.agendamentoId, _controller.text.trim(), _uid, tipo: 'texto');
    _controller.clear();
  }

  Future<void> _enviarMidia(File arquivo, String tipo) async {
    setState(() => _isUploading = true);
    try {
      final url = await _service.uploadArquivoChat(widget.agendamentoId, arquivo);
      await _service.enviarMensagem(widget.agendamentoId, url, _uid, tipo: tipo);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro no envio: $e')));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _mostrarOpcoesAnexo() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeria de Imagens'),
              onTap: () async {
                Navigator.pop(context);
                final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
                if (pickedFile != null) {
                  _enviarMidia(File(pickedFile.path), 'imagem');
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.audiotrack),
              title: const Text('Arquivo de Áudio'),
              onTap: () async {
                Navigator.pop(context);
                final result = await FilePicker.platform.pickFiles(type: FileType.audio);
                if (result != null && result.files.single.path != null) {
                  _enviarMidia(File(result.files.single.path!), 'audio');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _abrirWhatsapp() async {
    if (widget.telefoneWhatsapp == null) return;
    final phone = widget.telefoneWhatsapp!.replaceAll(RegExp(r'[^0-9]'), '');
    final url = Uri.parse("https://wa.me/$phone");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingConfig) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Se o chat estiver desativado globalmente, mostra fallback para WhatsApp
    if (_config != null && !_config!.chatAtivo) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.titulo), backgroundColor: AppColors.primary, foregroundColor: Colors.white),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey),
                const SizedBox(height: 20),
                Text(AppStrings.chatDesativadoMsg, textAlign: TextAlign.center, style: AppStyles.subtitle),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  icon: const Icon(Icons.phone),
                  label: Text(AppStrings.chatIrWhatsapp),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  onPressed: _abrirWhatsapp,
                )
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.titulo),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMensagem>>(
              stream: _service.getMensagens(widget.agendamentoId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final mensagens = snapshot.data!;
                
                // Marca como lida se chegarem novas mensagens enquanto a tela está aberta
                if (mensagens.isNotEmpty && !mensagens.first.lida && mensagens.first.autorId != _uid) {
                  _service.marcarMensagensComoLidas(widget.agendamentoId, _uid);
                }

                if (mensagens.isEmpty) {
                  return Center(child: Text(AppStrings.chatTitulo, style: const TextStyle(color: Colors.grey)));
                }

                return ListView.builder(
                  reverse: true, // Mensagens novas embaixo
                  itemCount: mensagens.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final msg = mensagens[index];
                    final isMe = msg.autorId == _uid;
                    return _buildMessageBubble(msg, isMe);
                  },
                );
              },
            ),
          ),
          if (_isUploading) const Padding(
            padding: EdgeInsets.all(8.0),
            child: LinearProgressIndicator(),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: AppStrings.chatPlaceholder,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onSubmitted: (_) => _enviar(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.attach_file, color: AppColors.primary),
                  onPressed: _isUploading ? null : _mostrarOpcoesAnexo,
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: AppColors.primary),
                  onPressed: _isUploading ? null : _enviar,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMensagem msg, bool isMe) {
    Widget content;
    switch (msg.tipo) {
      case 'imagem':
        content = GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FullScreenImageView(url: msg.texto))),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              msg.texto,
              width: 200,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const SizedBox(width: 200, height: 150, child: Center(child: CircularProgressIndicator()));
              },
            ),
          ),
        );
        break;
      case 'audio':
        content = AudioPlayerWidget(url: msg.texto, isMe: isMe);
        break;
      default: // texto
        content = Text(
          msg.texto,
          style: TextStyle(color: isMe ? Colors.white : Colors.black87),
        );
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: isMe ? Radius.zero : null,
            bottomLeft: !isMe ? Radius.zero : null,
          ),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            content,
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('HH:mm').format(msg.dataHora),
                  style: TextStyle(fontSize: 10, color: isMe ? Colors.white70 : Colors.black54),
                ),
                if (isMe && (_config?.reciboLeitura ?? true)) ...[
                  const SizedBox(width: 4),
                  Icon(
                    msg.lida ? Icons.done_all : Icons.done,
                    size: 12,
                    color: msg.lida ? Colors.lightBlueAccent : Colors.white70,
                  )
                ]
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AudioPlayerWidget extends StatefulWidget {
  final String url;
  final bool isMe;
  const AudioPlayerWidget({super.key, required this.url, required this.isMe});

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isMe ? Colors.white : AppColors.primary;
    return IconButton(
      icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled, color: color, size: 40),
      onPressed: () async {
        if (_isPlaying) {
          await _audioPlayer.pause();
          setState(() => _isPlaying = false);
        } else {
          await _audioPlayer.play(UrlSource(widget.url));
          setState(() => _isPlaying = true);
        }
      },
    );
  }
}