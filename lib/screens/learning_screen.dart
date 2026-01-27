import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class LearningScreen extends StatelessWidget {
  const LearningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Linear',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz, color: AppColors.textDark),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Text(
                      'It is stated in the book Midrash Tancuma: "Master of the world, we want to labour in the study of Torah by day and by night, and we want to follow the paths of the world... \n\nMaster of the works, we want to labour in the study of Torah by day and by night, and we want to follow the paths of the world... \n\nMaster of the works, we want to labour in the study of Torah by day and by night, and we want to follow the paths of the world...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildPlaybackControls(),
        ],
      ),
    );
  }

  Widget _buildPlaybackControls() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildControlIcon(Icons.speed, '1.5x'),
              _buildControlIcon(Icons.skip_previous, ''),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.pause, color: Colors.white, size: 32),
              ),
              _buildControlIcon(Icons.skip_next, ''),
              _buildControlIcon(Icons.repeat, 'Off'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlIcon(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary),
        if (label.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppColors.primary),
          ),
        ],
      ],
    );
  }
}
