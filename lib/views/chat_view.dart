import 'package:flutter/material.dart';

class ChatView extends StatelessWidget {
  const ChatView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Chat de Conversas',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: const TabBar(
            indicatorColor: Colors.black,
            labelColor: Colors.black,
            unselectedLabelColor: Colors.black54,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
            tabs: [
              Tab(text: 'CUIDADORES'),
              Tab(text: 'USUÁRIOS'),
              Tab(text: 'AMIGOS'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_CuidadoresTab(), _OutrosUsuariosTab(), _AmigosTab()],
        ),
      ),
    );
  }
}

class _CuidadoresTab extends StatelessWidget {
  const _CuidadoresTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildChatListItem(
          name: 'Maria (Cuidadora)',
          message: 'Olá! Como você está se sentindo hoje?',
          time: '14:30',
          avatarColor: Colors.blueAccent,
        ),
        _buildChatListItem(
          name: 'João Silva',
          message: 'Lembre-se de tomar a água!',
          time: 'Ontem',
          avatarColor: Colors.greenAccent,
        ),
      ],
    );
  }
}

class _OutrosUsuariosTab extends StatelessWidget {
  const _OutrosUsuariosTab();

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> usuarios = [
      {'nome': 'José Oliveira', 'idade': 72},
      {'nome': 'Ana Souza', 'idade': 68},
      {'nome': 'Roberto Santos', 'idade': 75},
      {'nome': 'Lúcia Ferreira', 'idade': 70},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: usuarios.length,
      itemBuilder: (context, index) {
        final user = usuarios[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: CircleAvatar(
              child: Text(
                user['nome'][0],
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(
              user['nome'],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            subtitle: Text(
              '${user['idade']} anos',
              style: const TextStyle(fontSize: 14),
            ),
            trailing: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Solicitação enviada para ${user['nome']}!'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'Solicitar Amizade',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AmigosTab extends StatelessWidget {
  const _AmigosTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Você ainda não possui amigos adicionados.',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

Widget _buildChatListItem({
  required String name,
  required String message,
  required String time,
  required Color avatarColor,
}) {
  return Card(
    margin: const EdgeInsets.only(bottom: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: avatarColor,
        child: const Icon(Icons.person, color: Colors.white),
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(message, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Text(
        time,
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      ),
    ),
  );
}
