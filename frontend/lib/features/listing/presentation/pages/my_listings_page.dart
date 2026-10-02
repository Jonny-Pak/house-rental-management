import 'package:flutter/material.dart';

const _kDark = Color(0xFF2C1D11);
const _kBackground = Color(0xFFFAF8F5);

class MyListingsPage extends StatelessWidget {
  const MyListingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _kDark),
          onPressed: () {
            // Because they might come from Create Listing, popping might go back to the flow.
            // Usually, going back from management goes to Home.
            // A simple pop works for now.
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          'Quản lý tin đăng',
          style: TextStyle(color: _kDark, fontSize: 16, fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.list_alt_rounded, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'Chưa có tin đăng nào được tải lên.',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tin đăng mới của bạn sẽ hiển thị ở đây.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
