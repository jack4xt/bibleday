import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/ai_service.dart';
import '../../services/settings_service.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

class AssistantMessage {
  final String text;
  final bool isUser;
  final DateTime time;

  const AssistantMessage({
    required this.text,
    required this.isUser,
    required this.time,
  });
}

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final _settings = SettingsService();
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  final List<AssistantMessage> _messages = [];
  bool _loading = false;
  bool _hasApiKey = false;

  static const String _systemPrompt = '''
Jsi biblický průvodce a duchovní pomocník v aplikaci BibleDay. 
Odpovídáš POUZE na otázky týkající se:
- Bible, biblických textů, příběhů a postav
- Křesťanské víry, teologie a duchovna
- Modlitby, duchovního růstu a křesťanského života
- Církevní historie a křesťanských tradic
- Výkladu biblických veršů a kapitol
- Otázek víry a smyslu života z křesťanského pohledu

Pokud uživatel položí otázku, která NESOUVISÍ s Biblí nebo křesťanskou vírou 
(např. počasí, sport, politika, technologie, recepty atd.), zdvořile odpověz 
že tato otázka nesouvisí s Biblí a nabídni pomoc s biblickými tématy.

Odpovídej v jazyce, ve kterém uživatel píše.
Buď přátelský, srozumitelný a povzbuzující.
Odpovědi drž na přiměřené délce — ne příliš krátké, ne příliš dlouhé.
''';

  @override
  void initState() {
    super.initState();
    _checkApiKey();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkApiKey() async {
    final hasKey = await _settings.hasApiKey();
    setState(() => _hasApiKey = hasKey);
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _loading) return;

    _controller.clear();
    setState(() {
      _messages.add(AssistantMessage(
        text: text,
        isUser: true,
        time: DateTime.now(),
      ));
      _loading = true;
    });
    _scrollToBottom();

    try {
      final provider = await _settings.getProvider();
      final apiKey = await _settings.getApiKey();
      final ai = AIService(provider: provider, apiKey: apiKey!);

      // Sestav konverzační historii pro kontext
      final history = _messages
          .where((m) => !m.isUser || m.text != text)
          .map((m) => {'role': m.isUser ? 'user' : 'assistant', 'content': m.text})
          .toList();

      final response = await ai.askAssistant(
        question: text,
        systemPrompt: _systemPrompt,
        history: history,
      );

      setState(() {
        _messages.add(AssistantMessage(
          text: response ?? '...',
          isUser: false,
          time: DateTime.now(),
        ));
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(AssistantMessage(
          text: '⚠️ Chyba při komunikaci s AI. Zkus to znovu.',
          isUser: false,
          time: DateTime.now(),
        ));
        _loading = false;
      });
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    if (!_hasApiKey) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, color: AppTheme.goldColor(context), size: 48),
              SizedBox(height: 16),
              Text(l.studyApiRequired,
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center),
              SizedBox(height: 8),
              Text(l.apiKeyRequiredDesc,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Úvodní zpráva pokud je chat prázdný
        if (_messages.isEmpty)
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.auto_awesome,
                        color: AppTheme.goldColor(context), size: 48),
                    SizedBox(height: 16),
                    Text(l.assistantWelcome,
                        style: Theme.of(context).textTheme.displayMedium,
                        textAlign: TextAlign.center),
                    SizedBox(height: 8),
                    Text(l.assistantDesc,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center),
                    SizedBox(height: 24),
                    // Ukázkové otázky
                    ...[
                      l.assistantExample1,
                      l.assistantExample2,
                      l.assistantExample3,
                    ].map((q) => GestureDetector(
                      onTap: () {
                        _controller.text = q;
                        _sendMessage();
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor(context),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppTheme.goldColor(context).withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.help_outline,
                                color: AppTheme.goldColor(context), size: 16),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(q,
                                  style: GoogleFonts.crimsonText(
                                      color: AppTheme.textPrimaryColor(context),
                                      fontSize: 15)),
                            ),
                          ],
                        ),
                      ),
                    )),
                  ],
                ),
              ).animate().fadeIn(),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_loading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  // Loading indikátor
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor(context),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: AppTheme.purpleColor(context).withValues(alpha: 0.3)),
                      ),
                      child: SizedBox(
                        width: 40,
                        child: LinearProgressIndicator(
                            color: AppTheme.purpleColor(context),
                            backgroundColor: AppTheme.divider),
                      ),
                    ),
                  );
                }

                final msg = _messages[index];
                return _buildMessage(context, msg);
              },
            ),
          ),

        // Input pole
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor(context),
            border: Border(top: BorderSide(color: AppTheme.divider)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: GoogleFonts.crimsonText(
                      color: AppTheme.textPrimaryColor(context), fontSize: 16),
                  maxLines: 3,
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText: l.assistantHint,
                    hintStyle: GoogleFonts.crimsonText(
                        color: AppTheme.textSecondaryColor(context)),
                    filled: true,
                    fillColor: AppTheme.surfaceElevatedColor(context),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: AppTheme.dividerColor(context))),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: AppTheme.dividerColor(context))),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide:
                            BorderSide(color: AppTheme.goldColor(context))),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                  textInputAction: TextInputAction.send,
                ),
              ),
              SizedBox(width: 8),
              GestureDetector(
                onTap: _loading ? null : _sendMessage,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _loading
                        ? AppTheme.divider
                        : AppTheme.neonGold,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Icon(
                    Icons.send_rounded,
                    color: _loading ? AppTheme.textSecondary : AppTheme.background,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessage(BuildContext context, AssistantMessage msg) {
    final isUser = msg.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser
              ? AppTheme.goldColor(context).withValues(alpha: 0.15)
              : AppTheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: Border.all(
            color: isUser
                ? AppTheme.goldColor(context).withValues(alpha: 0.3)
                : AppTheme.purpleColor(context).withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          msg.text,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1);
  }
}
