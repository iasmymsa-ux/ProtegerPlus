import 'package:flutter/material.dart';
import 'add_consulta_view.dart';
import 'add_remedio_view.dart';
import 'add_tarefa_view.dart';
import 'add_alarm_view.dart';

class CategorySelectionView extends StatelessWidget {
  const CategorySelectionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 28, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'ADICIONAR NOVO LEMBRETE',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                        fontFamily: 'serif',
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 50),

              const Text(
                'VOCÊ DESEJA\nADICIONAR:',
                style: TextStyle(
                  fontSize: 26,
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'serif',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 60),

              _buildCategoryOption(
                context: context,
                title: 'CONSULTA MÉDICA',
                icon: Icons.local_hospital_outlined,
                targetView: const AddConsultaView(),
              ),
              const SizedBox(height: 30),

              _buildCategoryOption(
                context: context,
                title: 'REMÉDIO',
                icon: Icons.medication_outlined,
                targetView: const AddRemedioView(),
              ),
              const SizedBox(height: 30),

              _buildCategoryOption(
                context: context,
                title: 'TAREFA',
                icon: Icons.content_paste_outlined,
                targetView: const AddTarefaView(),
              ),
              const SizedBox(height: 30),

              _buildCategoryOption(
                context: context,
                title: 'ALERTA / ALARME',
                icon: Icons.alarm_outlined,
                targetView: const AddAlarmView(),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryOption({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Widget targetView,
  }) {
    return InkWell(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => targetView),
        );
        if (result != null && context.mounted) {
          Navigator.pop(context, result);
        }
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Icon(Icons.add_circle, color: Color(0xFF9C72AD), size: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontFamily: 'serif',
              ),
            ),
          ),
          Icon(icon, color: const Color(0xFFC18AD1), size: 64),
        ],
      ),
    );
  }
}
