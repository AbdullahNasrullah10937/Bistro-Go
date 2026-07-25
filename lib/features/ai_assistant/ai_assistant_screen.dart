// lib/features/ai_assistant/ai_assistant_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_spacing.dart';
import '../../models/menu_item.dart';
import '../../services/menu_service.dart';
import '../../shared_widgets/bistro_app_bar.dart';
import '../../shared_widgets/menu_item_card.dart';

class _Message {
  final String text;
  final bool isUser;
  final List<MenuItem> recommendedItems;

  _Message({
    required this.text,
    required this.isUser,
    this.recommendedItems = const [],
  });
}

class AiAssistantScreen extends ConsumerStatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen> {
  final _messages = <_Message>[
    _Message(
      text: "Hi! I'm your Bistro Go menu assistant 🍽️ I can help you find the perfect dish, suggest options based on your dietary needs, or tell you about our specials. What are you in the mood for?",
      isUser: false,
    ),
  ];
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _loading = false;

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  /// Resolves recommended_item_ids from the Edge Function response into MenuItem objects
  Future<List<MenuItem>> _resolveItems(List<String> ids) async {
    if (ids.isEmpty) return [];
    try {
      final allItems = await ref.read(menuServiceProvider).fetchAllItems();
      return ids
          .map((id) => allItems.where((i) => i.id == id).firstOrNull)
          .whereType<MenuItem>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _loading) return;

    setState(() {
      _messages.add(_Message(text: text, isUser: true));
      _ctrl.clear();
      _loading = true;
    });
    _scrollToBottom();

    try {
      // Build conversation history (skip the initial greeting)
      final history = _messages
          .skip(1) // skip initial greeting
          .where((m) => !m.isUser || m.text.isNotEmpty)
          .map((m) => {'role': m.isUser ? 'user' : 'assistant', 'content': m.text})
          .toList();

      // Call menu-assistant Edge Function (Groq key stays server-side)
      final response = await Supabase.instance.client.functions.invoke(
        'menu-assistant',
        body: {
          'message': text,
          'conversation_history': history,
        },
      );

      final data = response.data as Map<String, dynamic>?;

      if (response.status == 200 && data != null) {
        final reply = data['reply'] as String? ?? '';
        final rawIds = data['recommended_item_ids'] as List<dynamic>? ?? [];
        final ids = rawIds.map((e) => e.toString()).toList();
        final recItems = await _resolveItems(ids);

        if (mounted) {
          setState(() => _messages.add(_Message(
                text: reply,
                isUser: false,
                recommendedItems: recItems,
              )));
        }
      } else {
        final errMsg = (data?['error'] as String?) ?? 'Unknown error';
        throw Exception(errMsg);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _messages.add(_Message(
            text: "Sorry, I'm having trouble connecting right now. Please try again!",
            isUser: false)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  static const _suggestions = [
    'Any vegan options?',
    'Recommend a popular dish',
    'What\'s good for breakfast?',
    'Gluten-free choices?',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF4F1EC),
      appBar: const BistroAppBar(title: 'AI Menu Assistant'),
      body: Column(
        children: [
          // ── Chat messages ──────────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              itemCount: _messages.length + (_loading ? 1 : 0),
              itemBuilder: (_, i) {
                if (i == _messages.length) return const _TypingBubble();
                final msg = _messages[i];
                return _ChatBubble(message: msg);
              },
            ),
          ),

          // ── Quick suggestions (shown only at start) ────────────────────────
          if (_messages.length <= 1 && !_loading)
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemCount: _suggestions.length,
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () {
                    _ctrl.text = _suggestions[i];
                    _send();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1),
                    ),
                    child: Text(_suggestions[i],
                        style: AppTextStyles.labelSm.copyWith(color: AppColors.primary)),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),

          // ── Input bar ──────────────────────────────────────────────────────
          Container(
            color: Colors.white,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 120),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F1EC),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TextField(
                          controller: _ctrl,
                          maxLines: null,
                          textCapitalization: TextCapitalization.sentences,
                          style: AppTextStyles.bodyMd,
                          onSubmitted: (_) => _send(),
                          onTap: _scrollToBottom,
                          decoration: InputDecoration(
                            hintText: 'Ask about our menu...',
                            hintStyle: AppTextStyles.bodyMd.copyWith(
                                color: AppColors.onSurface.withValues(alpha: 0.35)),
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _send,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _loading ? AppColors.outline : AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _ChatBubble extends StatelessWidget {
  final _Message message;
  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final hasItems = message.recommendedItems.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser) ...[
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                      color: AppColors.primaryFixed, shape: BoxShape.circle),
                  child: const Icon(Icons.auto_awesome_rounded,
                      size: 16, color: AppColors.primary),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                      maxWidth: MediaQuery.sizeOf(context).width * 0.78),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isUser ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 18),
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: const Color(0xFF1B2A4A).withValues(alpha: 0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2))
                    ],
                  ),
                  child: Text(
                    message.text,
                    style: AppTextStyles.bodyMd.copyWith(
                        color: isUser ? Colors.white : AppColors.onSurface,
                        height: 1.45),
                  ),
                ),
              ),
              if (isUser) const SizedBox(width: 8),
            ],
          ),

          // ── Inline Recommended Menu Item Cards ──────────────────────────────
          if (!isUser && hasItems) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 40),
              child: SizedBox(
                height: 205,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  shrinkWrap: true,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemCount: message.recommendedItems.length,
                  itemBuilder: (_, i) {
                    final item = message.recommendedItems[i];
                    return SizedBox(
                      width: 155,
                      child: MenuItemCard(
                        item: item,
                        onTap: () => context.push('/item/${item.id}'),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}


class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
                color: AppColors.primaryFixed, shape: BoxShape.circle),
            child: const Icon(Icons.auto_awesome_rounded, size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
              boxShadow: [BoxShadow(color: const Color(0xFF1B2A4A).withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) => _Dot(index: i, controller: _ctrl)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final int index;
  final AnimationController controller;

  const _Dot({required this.index, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final offset = (controller.value - index * 0.15).clamp(0.0, 1.0);
        final opacity = (offset < 0.5 ? offset * 2 : (1 - offset) * 2).clamp(0.3, 1.0);
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: opacity),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}
