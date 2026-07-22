import 'package:flutter/material.dart';

// ─── REUSABLE BRANDED LOADER WIDGET ──────────────────────────────────────────
// Use this anywhere in your app like:
//   if (loading) const AppLoader()

class AppLoader extends StatelessWidget {
  final double size;
  const AppLoader({super.key, this.size = 60});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Spinning ring
            SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  const Color(0xFF2F5DA8),
                ),
              ),
            ),
            // Logo in center
            Container(
              width: size * 0.65,
              height: size * 0.65,
              decoration: BoxDecoration(
                color: const Color(0xFF0C1F3F),
                borderRadius: BorderRadius.circular(size * 0.18),
              ),
              child: Icon(
                Icons.smart_toy_rounded,
                color: Colors.white,
                size: size * 0.38,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ─── FULL SCREEN LOADER (for page loading) ────────────────────────────────────
// Use this when an entire page is loading:
//   if (loading) const FullScreenLoader()

class FullScreenLoader extends StatelessWidget {
  final String? message;
  const FullScreenLoader({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C1F3F),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Branded loader
            SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Spinning ring
                  const SizedBox(
                    width: 80,
                    height: 80,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF2F5DA8),
                      ),
                    ),
                  ),
                  // Logo box
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2F5DA8),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.smart_toy_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            const Text(
              "Stock X",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              message ?? "Loading...",
              style: const TextStyle(
                color: Color(0xFF8FAADC),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}