import 'package:flutter/material.dart';

class GamingScreen extends StatelessWidget {
  const GamingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667eea), Color(0xFF764ba2), Color(0xFFf093fb)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('🧠 العاب العقل'),
                          const SizedBox(height: 8),
                          _buildSubtitle('تحدى عقلك وطور مهاراتك'),
                          const SizedBox(height: 24),
                          _buildFeaturedGames(context),
                          const SizedBox(height: 32),
                          _buildSectionTitle('🎮 المزيد من الألعاب'),
                          const SizedBox(height: 16),
                          _buildGamesGrid(context),
                          const SizedBox(height: 32),
                          _buildAchievementCard(),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.psychology, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'مرحباً بك في',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              Text(
                'ألعاب العقل',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              children: [
                const Icon(Icons.emoji_events, color: Colors.amber, size: 28),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2D3436),
      ),
    );
  }

  Widget _buildSubtitle(String text) {
    return Text(
      text,
      style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
    );
  }

  Widget _buildFeaturedGames(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildFeaturedGameCard(
            context: context,
            title: 'سودوكو',
            subtitle: 'أرقام وتحدي',
            icon: Icons.grid_4x4,
            gradient: const LinearGradient(
              colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
            ),
            onTap: () => _navigateToGame(context, 'sudoku'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildFeaturedGameCard(
            context: context,
            title: 'شطرنج',
            subtitle: 'استراتيجية وذكاء',
            icon: Icons.castle,
            gradient: const LinearGradient(
              colors: [Color(0xFFee0979), Color(0xFFff6a00)],
            ),
            onTap: () => _navigateToGame(context, 'chess'),
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedGameCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: (gradient as LinearGradient).colors.first.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(
                icon,
                size: 120,
                color: Colors.white.withOpacity(0.2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: Colors.white, size: 28),
                  ),
                  const Spacer(),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGamesGrid(BuildContext context) {
    final games = [
      _GameItem(
        title: 'تيك تاك تو',
        icon: Icons.close,
        color: const Color(0xFF6C5CE7),
        onTap: () => _navigateToGame(context, 'tictactoe'),
      ),
      _GameItem(
        title: 'لعبة الذاكرة',
        icon: Icons.memory,
        color: const Color(0xFF00B894),
        onTap: () => _navigateToGame(context, 'memory'),
      ),
      _GameItem(
        title: 'الألغاز',
        icon: Icons.extension,
        color: const Color(0xFFE17055),
        onTap: () => _navigateToGame(context, 'puzzle'),
      ),
      _GameItem(
        title: 'حساب سريع',
        icon: Icons.calculate,
        color: const Color(0xFF0984E3),
        onTap: () => _navigateToGame(context, 'math'),
      ),
      _GameItem(
        title: '2048',
        icon: Icons.grid_on,
        color: const Color(0xFFFDAB00),
        onTap: () => _navigateToGame(context, '2048'),
      ),
      _GameItem(
        title: 'كلمات متقاطعة',
        icon: Icons.text_fields,
        color: const Color(0xFFD63384),
        onTap: () => _navigateToGame(context, 'crossword'),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.9,
      ),
      itemCount: games.length,
      itemBuilder: (context, index) => _buildGameCard(games[index]),
    );
  }

  Widget _buildGameCard(_GameItem game) {
    return GestureDetector(
      onTap: game.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: game.color.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(color: game.color.withOpacity(0.1), width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: game.color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(game.icon, color: game.color, size: 28),
            ),
            const SizedBox(height: 10),
            Text(
              game.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.star_rounded,
              color: Colors.amber,
              size: 36,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'استمر في التقدم! 🚀',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'لقد أكملت 5 ألعاب هذا الأسبوع',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildAchievementStat('🏆', '12'),
                    const SizedBox(width: 20),
                    _buildAchievementStat('⭐', '450'),
                    const SizedBox(width: 20),
                    _buildAchievementStat('🔥', '7'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementStat(String emoji, String value) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  void _navigateToGame(BuildContext context, String gameType) {
    Widget gameScreen;

    switch (gameType) {
      case 'sudoku':
        gameScreen = const SudokuGameScreen();
        break;
      case 'chess':
        gameScreen = const ChessGameScreen();
        break;
      case 'tictactoe':
        gameScreen = const TicTacToeScreen();
        break;
      default:
        _showComingSoonDialog(context, gameType);
        return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => gameScreen),
    );
  }

  void _showComingSoonDialog(BuildContext context, String gameType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.construction, color: Colors.amber),
            SizedBox(width: 8),
            Text('قريباً'),
          ],
        ),
        content: const Text('هذه اللعبة قيد التطوير وستكون متاحة قريباً!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }
}

class _GameItem {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _GameItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

// ==================== SUDOKU GAME ====================

class SudokuGameScreen extends StatefulWidget {
  const SudokuGameScreen({super.key});

  @override
  State<SudokuGameScreen> createState() => _SudokuGameScreenState();
}

class _SudokuGameScreenState extends State<SudokuGameScreen> {
  late List<List<int>> board;
  late List<List<bool>> isOriginal;
  int? selectedRow;
  int? selectedCol;

  @override
  void initState() {
    super.initState();
    _initializeBoard();
  }

  void _initializeBoard() {
    // Easy Sudoku puzzle
    board = [
      [5, 3, 0, 0, 7, 0, 0, 0, 0],
      [6, 0, 0, 1, 9, 5, 0, 0, 0],
      [0, 9, 8, 0, 0, 0, 0, 6, 0],
      [8, 0, 0, 0, 6, 0, 0, 0, 3],
      [4, 0, 0, 8, 0, 3, 0, 0, 1],
      [7, 0, 0, 0, 2, 0, 0, 0, 6],
      [0, 6, 0, 0, 0, 0, 2, 8, 0],
      [0, 0, 0, 4, 1, 9, 0, 0, 5],
      [0, 0, 0, 0, 8, 0, 0, 7, 9],
    ];

    isOriginal = List.generate(
      9,
      (i) => List.generate(9, (j) => board[i][j] != 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: _buildSudokuGrid(),
                        ),
                      ),
                      _buildNumberPad(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            'سودوكو',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(Icons.timer, color: Colors.white, size: 20),
                SizedBox(width: 6),
                Text(
                  '00:00',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSudokuGrid() {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF11998e), width: 3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 9,
          ),
          itemCount: 81,
          itemBuilder: (context, index) {
            int row = index ~/ 9;
            int col = index % 9;
            return _buildCell(row, col);
          },
        ),
      ),
    );
  }

  Widget _buildCell(int row, int col) {
    bool isSelected = selectedRow == row && selectedCol == col;
    bool isInSelectedRegion =
        (selectedRow != null && selectedCol != null) &&
        ((row ~/ 3 == selectedRow! ~/ 3 && col ~/ 3 == selectedCol! ~/ 3) ||
            row == selectedRow ||
            col == selectedCol);

    return GestureDetector(
      onTap: () {
        if (!isOriginal[row][col]) {
          setState(() {
            selectedRow = row;
            selectedCol = col;
          });
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF11998e).withOpacity(0.3)
              : isInSelectedRegion
              ? const Color(0xFF11998e).withOpacity(0.1)
              : Colors.white,
          border: Border(
            top: BorderSide(
              color: row % 3 == 0
                  ? const Color(0xFF11998e)
                  : Colors.grey.shade300,
              width: row % 3 == 0 ? 2 : 1,
            ),
            left: BorderSide(
              color: col % 3 == 0
                  ? const Color(0xFF11998e)
                  : Colors.grey.shade300,
              width: col % 3 == 0 ? 2 : 1,
            ),
            right: col == 8
                ? BorderSide(color: Colors.grey.shade300)
                : BorderSide.none,
            bottom: row == 8
                ? BorderSide(color: Colors.grey.shade300)
                : BorderSide.none,
          ),
        ),
        child: Center(
          child: Text(
            board[row][col] == 0 ? '' : board[row][col].toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: isOriginal[row][col]
                  ? FontWeight.bold
                  : FontWeight.normal,
              color: isOriginal[row][col]
                  ? const Color(0xFF2D3436)
                  : const Color(0xFF11998e),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumberPad() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ...List.generate(9, (index) => _buildNumberButton(index + 1)),
          _buildNumberButton(0, isErase: true),
        ],
      ),
    );
  }

  Widget _buildNumberButton(int number, {bool isErase = false}) {
    return GestureDetector(
      onTap: () {
        if (selectedRow != null && selectedCol != null) {
          setState(() {
            board[selectedRow!][selectedCol!] = number;
          });
        }
      },
      child: Container(
        width: 32,
        height: 48,
        decoration: BoxDecoration(
          color: isErase
              ? Colors.red.shade100
              : const Color(0xFF11998e).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: isErase
              ? Icon(
                  Icons.backspace_outlined,
                  color: Colors.red.shade700,
                  size: 18,
                )
              : Text(
                  number.toString(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF11998e),
                  ),
                ),
        ),
      ),
    );
  }
}

// ==================== CHESS GAME ====================

class ChessGameScreen extends StatefulWidget {
  const ChessGameScreen({super.key});

  @override
  State<ChessGameScreen> createState() => _ChessGameScreenState();
}

class _ChessGameScreenState extends State<ChessGameScreen> {
  late List<List<String>> board;
  int? selectedRow;
  int? selectedCol;
  bool isWhiteTurn = true;

  @override
  void initState() {
    super.initState();
    _initializeBoard();
  }

  void _initializeBoard() {
    board = [
      ['♜', '♞', '♝', '♛', '♚', '♝', '♞', '♜'],
      ['♟', '♟', '♟', '♟', '♟', '♟', '♟', '♟'],
      ['', '', '', '', '', '', '', ''],
      ['', '', '', '', '', '', '', ''],
      ['', '', '', '', '', '', '', ''],
      ['', '', '', '', '', '', '', ''],
      ['♙', '♙', '♙', '♙', '♙', '♙', '♙', '♙'],
      ['♖', '♘', '♗', '♕', '♔', '♗', '♘', '♖'],
    ];
  }

  bool isWhitePiece(String piece) {
    return ['♔', '♕', '♖', '♗', '♘', '♙'].contains(piece);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFee0979), Color(0xFFff6a00)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              const SizedBox(height: 16),
              _buildTurnIndicator(),
              const SizedBox(height: 16),
              Expanded(
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: _buildChessBoard(),
                    ),
                  ),
                ),
              ),
              _buildGameControls(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            'شطرنج',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.settings, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildTurnIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isWhiteTurn ? Colors.white : Colors.black,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            isWhiteTurn ? 'دور الأبيض' : 'دور الأسود',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChessBoard() {
    return AspectRatio(
      aspectRatio: 1,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 8,
        ),
        itemCount: 64,
        itemBuilder: (context, index) {
          int row = index ~/ 8;
          int col = index % 8;
          return _buildChessCell(row, col);
        },
      ),
    );
  }

  Widget _buildChessCell(int row, int col) {
    bool isLight = (row + col) % 2 == 0;
    bool isSelected = selectedRow == row && selectedCol == col;
    String piece = board[row][col];

    return GestureDetector(
      onTap: () => _handleCellTap(row, col),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.yellow.shade300
              : isLight
              ? const Color(0xFFF0D9B5)
              : const Color(0xFFB58863),
          borderRadius: _getCellBorderRadius(row, col),
        ),
        child: Center(child: Text(piece, style: const TextStyle(fontSize: 32))),
      ),
    );
  }

  BorderRadius? _getCellBorderRadius(int row, int col) {
    if (row == 0 && col == 0)
      return const BorderRadius.only(topLeft: Radius.circular(8));
    if (row == 0 && col == 7)
      return const BorderRadius.only(topRight: Radius.circular(8));
    if (row == 7 && col == 0)
      return const BorderRadius.only(bottomLeft: Radius.circular(8));
    if (row == 7 && col == 7)
      return const BorderRadius.only(bottomRight: Radius.circular(8));
    return null;
  }

  void _handleCellTap(int row, int col) {
    setState(() {
      if (selectedRow == null) {
        // Select a piece
        if (board[row][col].isNotEmpty) {
          bool pieceIsWhite = isWhitePiece(board[row][col]);
          if (pieceIsWhite == isWhiteTurn) {
            selectedRow = row;
            selectedCol = col;
          }
        }
      } else {
        // Move the piece
        if (row != selectedRow || col != selectedCol) {
          board[row][col] = board[selectedRow!][selectedCol!];
          board[selectedRow!][selectedCol!] = '';
          isWhiteTurn = !isWhiteTurn;
        }
        selectedRow = null;
        selectedCol = null;
      }
    });
  }

  Widget _buildGameControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlButton(Icons.refresh, 'إعادة', () {
            setState(() {
              _initializeBoard();
              selectedRow = null;
              selectedCol = null;
              isWhiteTurn = true;
            });
          }),
          _buildControlButton(Icons.undo, 'تراجع', () {}),
          _buildControlButton(Icons.lightbulb_outline, 'تلميح', () {}),
        ],
      ),
    );
  }

  Widget _buildControlButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== TIC TAC TOE ====================

class TicTacToeScreen extends StatefulWidget {
  const TicTacToeScreen({super.key});

  @override
  State<TicTacToeScreen> createState() => _TicTacToeScreenState();
}

class _TicTacToeScreenState extends State<TicTacToeScreen> {
  late List<String> board;
  bool isXTurn = true;
  String winner = '';
  int xScore = 0;
  int oScore = 0;

  @override
  void initState() {
    super.initState();
    _resetBoard();
  }

  void _resetBoard() {
    board = List.filled(9, '');
    isXTurn = true;
    winner = '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              const SizedBox(height: 20),
              _buildScoreBoard(),
              const Spacer(),
              _buildGameBoard(),
              const Spacer(),
              _buildTurnIndicator(),
              const SizedBox(height: 20),
              _buildResetButton(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            'تيك تاك تو',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBoard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildScoreItem('X', xScore, const Color(0xFFFF6B6B)),
          Container(width: 2, height: 40, color: Colors.white.withOpacity(0.3)),
          _buildScoreItem('O', oScore, const Color(0xFF4ECDC4)),
        ],
      ),
    );
  }

  Widget _buildScoreItem(String player, int score, Color color) {
    return Column(
      children: [
        Text(
          player,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          score.toString(),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildGameBoard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(24),
      ),
      child: AspectRatio(
        aspectRatio: 1,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: 9,
          itemBuilder: (context, index) => _buildCell(index),
        ),
      ),
    );
  }

  Widget _buildCell(int index) {
    return GestureDetector(
      onTap: () => _handleTap(index),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            board[index],
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: board[index] == 'X'
                  ? const Color(0xFFFF6B6B)
                  : const Color(0xFF4ECDC4),
            ),
          ),
        ),
      ),
    );
  }

  void _handleTap(int index) {
    if (board[index].isEmpty && winner.isEmpty) {
      setState(() {
        board[index] = isXTurn ? 'X' : 'O';
        isXTurn = !isXTurn;
        _checkWinner();
      });
    }
  }

  void _checkWinner() {
    List<List<int>> winPatterns = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8], // rows
      [0, 3, 6], [1, 4, 7], [2, 5, 8], // columns
      [0, 4, 8], [2, 4, 6], // diagonals
    ];

    for (var pattern in winPatterns) {
      if (board[pattern[0]].isNotEmpty &&
          board[pattern[0]] == board[pattern[1]] &&
          board[pattern[1]] == board[pattern[2]]) {
        winner = board[pattern[0]];
        if (winner == 'X') {
          xScore++;
        } else {
          oScore++;
        }
        _showWinnerDialog();
        return;
      }
    }

    if (!board.contains('')) {
      _showDrawDialog();
    }
  }

  void _showWinnerDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🎉 مبروك!', textAlign: TextAlign.center),
        content: Text(
          'الفائز هو $winner',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _resetBoard());
            },
            child: const Text('العب مجدداً'),
          ),
        ],
      ),
    );
  }

  void _showDrawDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🤝 تعادل!', textAlign: TextAlign.center),
        content: const Text(
          'لا يوجد فائز',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _resetBoard());
            },
            child: const Text('العب مجدداً'),
          ),
        ],
      ),
    );
  }

  Widget _buildTurnIndicator() {
    if (winner.isNotEmpty) return const SizedBox();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'دور ${isXTurn ? "X" : "O"}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildResetButton() {
    return GestureDetector(
      onTap: () => setState(() {
        _resetBoard();
        xScore = 0;
        oScore = 0;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Text(
          'إعادة اللعبة',
          style: TextStyle(
            color: Color(0xFF6C5CE7),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
