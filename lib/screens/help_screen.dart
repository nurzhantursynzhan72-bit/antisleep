import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Көмек және Анықтама'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.support_agent_rounded,
                      color: Colors.white, size: 40),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '24/7 Техникалық қолдау',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Сұрақтарыңыз болса, біздің мамандар көмек беруге дайын.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Жиі қойылатын сұрақтар (FAQ)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _buildFaqTile(
              question: 'Қосымша интернетсіз жұмыс істей ме?',
              answer:
                  'Иә! «AntiSleep AI» толықтай On-Device (Edge AI) алгоритмімен жұмыс істейді. Телефон камерасындағы бейне ешқайда жіберілмейді және интернет байланысын қажет етпейді.',
            ),
            _buildFaqTile(
              question: 'Көзілдірік таққанда AI көзді тани ма?',
              answer:
                  'Жүйе қарапайым мөлдір көзілдіріктерде көз нүктелерін еркін анықтайды. Тек тым қараңғы күннен қорғайтын көзілдірік кигенде сезімталдық деңгейін «Жоғары» режимге ауыстырған дұрыс.',
            ),
            _buildFaqTile(
              question: 'Смартфонды қалай дұрыс орналастыру керек?',
              answer:
                  'Телефонды алдыңғы әйнекке немесе панельге көз деңгейіңізге сәйкес, бетіңіз экранның ортасында тұратындай етіп бекітіңіз (арақашықтық 50-80 см).',
            ),
            _buildFaqTile(
              question: 'Дыбыссыз режимде (Silent Mode) сирена ойнай ма?',
              answer:
                  'Иә, қосымша жедел қауіп төнген сәтте телефонның дыбыссыз немесе «Мазаламаңыз» режимін айналып өтіп, максималды дауыспен ойнайды.',
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Байланыс орталығы:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Email: support@antisleep.kz\nТелефон: +7 (727) 300-11-22\nНұсқасы: v1.0.4 (Edge AI build)',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  static Widget _buildFaqTile(
      {required String question, required String answer}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: ExpansionTile(
        shape: const Border(),
        title: Text(
          question,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
