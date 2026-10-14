import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class BhoomaAiScreen extends StatelessWidget {
  const BhoomaAiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome, color: Color(0xFF7C3AED), size: 24),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'BHOOMA AI Clinical Assistant',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimaryLight,
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'AI clinical reasoning, patient dossier summarization, and safe tool-calling',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Ollama (qwen2.5:3b) Ready',
                    style: TextStyle(color: Color(0xFF7C3AED), fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Pending Action Confirmation Card
            Card(
              color: AppColors.warningLight.withValues(alpha: 0.4),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.shield_outlined, color: AppColors.warning, size: 28),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pending Clinical Action: Assign Bed ICU-02 to Patient Ramesh Patel',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            'BHOOMA AI generated this mutation. Requires clinical confirmation before DB commit.',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        minimumSize: const Size(80, 36),
                      ),
                      child: const Text('Reject'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.warning,
                        minimumSize: const Size(90, 36),
                      ),
                      child: const Text('Confirm'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Chat Messages Stream
            Expanded(
              child: ListView(
                children: const [
                  _ChatBubble(
                    isUser: false,
                    sender: 'BHOOMA AI',
                    message:
                        'Hello Doctor. Patient Ramesh Patel (CP-2026-001) has completed OPD consultation with Dr. Rajesh Sharma. Blood pressure was measured at 138/88 mmHg and Tab. Telmisartan 40mg was prescribed. Would you like me to generate a 2D Echocardiogram lab requisition?',
                    time: '10:35 AM',
                  ),
                  _ChatBubble(
                    isUser: true,
                    sender: 'Dr. Rajesh Sharma',
                    message: 'Summarize previous ECG reports and any documented drug allergies.',
                    time: '10:36 AM',
                  ),
                  _ChatBubble(
                    isUser: false,
                    sender: 'BHOOMA AI',
                    message:
                        'Patient has reported allergies to Penicillin and Sulfa drugs. Last recorded ECG showed normal sinus rhythm with no ST-segment elevation. Renal function tests from last month showed Creatinine 0.9 mg/dL (Normal).',
                    time: '10:36 AM',
                  ),
                ],
              ),
            ),

            // Prompt Input Field
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Ask BHOOMA AI about clinical dosages, patient history, or assign actions...',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.send, color: Color(0xFF7C3AED)),
                        onPressed: () {},
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final bool isUser;
  final String sender;
  final String message;
  final String time;

  const _ChatBubble({
    required this.isUser,
    required this.sender,
    required this.message,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const CircleAvatar(
              backgroundColor: Color(0xFF7C3AED),
              radius: 16,
              child: Icon(Icons.auto_awesome, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: isUser ? null : Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sender,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: isUser ? Colors.white70 : const Color(0xFF7C3AED),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: TextStyle(
                      color: isUser ? Colors.white : AppColors.textPrimaryLight,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 11,
                      color: isUser ? Colors.white60 : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              backgroundColor: AppColors.primaryLight,
              radius: 16,
              child: Icon(Icons.person, color: Colors.white, size: 16),
            ),
          ],
        ],
      ),
    );
  }
}
