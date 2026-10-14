import 'package:flutter/material.dart';
import 'package:shared/shared.dart';
import 'ludo_engine.dart';

class LudoSetupScreen extends StatefulWidget {
  final Function(LudoGameEngine engine) onStartGame;

  const LudoSetupScreen({super.key, required this.onStartGame});

  @override
  State<LudoSetupScreen> createState() => _LudoSetupScreenState();
}

class _LudoSetupScreenState extends State<LudoSetupScreen> {
  int _currentStep = 0; // 0: Mode, 1: Players, 2: Rules, 3: Colors & Names

  LudoGameMode _selectedMode = LudoGameMode.vsComputer;
  int _playerCount = 4;
  LudoCaptureRule _captureRule = LudoCaptureRule.captureAndSendHome;

  // Single player selection
  LudoColor _humanColor = LudoColor.red;
  final TextEditingController _humanNameController = TextEditingController(text: 'You');

  // Pass & Play player list
  final List<TextEditingController> _passPlayerNameControllers = [
    TextEditingController(text: 'Player 1'),
    TextEditingController(text: 'Player 2'),
    TextEditingController(text: 'Player 3'),
    TextEditingController(text: 'Player 4'),
  ];

  final List<LudoColor> _passPlayerColors = [
    LudoColor.red,
    LudoColor.yellow,
    LudoColor.green,
    LudoColor.blue,
  ];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  @override
  void dispose() {
    _humanNameController.dispose();
    for (var c in _passPlayerNameControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeIndex = prefs.getInt('ludo_mode');
      final count = prefs.getInt('ludo_player_count');
      final ruleIndex = prefs.getInt('ludo_capture_rule');
      final humanColorIndex = prefs.getInt('ludo_human_color');

      if (mounted) {
        setState(() {
          if (modeIndex != null && modeIndex >= 0 && modeIndex < LudoGameMode.values.length) {
            _selectedMode = LudoGameMode.values[modeIndex];
          }
          if (count != null && (count == 2 || count == 3 || count == 4)) {
            _playerCount = count;
          }
          if (ruleIndex != null && ruleIndex >= 0 && ruleIndex < LudoCaptureRule.values.length) {
            _captureRule = LudoCaptureRule.values[ruleIndex];
          }
          if (humanColorIndex != null && humanColorIndex >= 0 && humanColorIndex < LudoColor.values.length) {
            _humanColor = LudoColor.values[humanColorIndex];
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('ludo_mode', _selectedMode.index);
      await prefs.setInt('ludo_player_count', _playerCount);
      await prefs.setInt('ludo_capture_rule', _captureRule.index);
      await prefs.setInt('ludo_human_color', _humanColor.index);
    } catch (_) {}
  }

  void _onStart() {
    _savePreferences();

    List<LudoPlayer> players = [];

    if (_selectedMode == LudoGameMode.vsComputer) {
      // 1 human player
      final humanName = _humanNameController.text.trim().isEmpty ? 'You' : _humanNameController.text.trim();
      players.add(LudoPlayer(id: 0, color: _humanColor, name: humanName, isComputer: false));

      final remainingColors = LudoColor.values.where((c) => c != _humanColor).toList();

      if (_playerCount == 2) {
        // In 2 player, pick opposite color: Red <-> Yellow, Green <-> Blue
        LudoColor opposite;
        switch (_humanColor) {
          case LudoColor.red:
            opposite = LudoColor.yellow;
            break;
          case LudoColor.yellow:
            opposite = LudoColor.red;
            break;
          case LudoColor.green:
            opposite = LudoColor.blue;
            break;
          case LudoColor.blue:
            opposite = LudoColor.green;
            break;
        }
        players.add(LudoPlayer(id: 1, color: opposite, name: 'Computer (${_getColorName(opposite)})', isComputer: true));
      } else {
        // 4 players (1 human + 3 bots)
        for (int i = 0; i < 3; i++) {
          final botColor = remainingColors[i];
          players.add(LudoPlayer(
            id: i + 1,
            color: botColor,
            name: 'Bot ${i + 1} (${_getColorName(botColor)})',
            isComputer: true,
          ));
        }
      }
    } else {
      // Pass & Play
      for (int i = 0; i < _playerCount; i++) {
        final name = _passPlayerNameControllers[i].text.trim().isEmpty
            ? 'Player ${i + 1}'
            : _passPlayerNameControllers[i].text.trim();
        players.add(LudoPlayer(
          id: i,
          color: _passPlayerColors[i],
          name: name,
          isComputer: false,
        ));
      }
    }

    final engine = LudoGameEngine.custom(
      players: players,
      gameMode: _selectedMode,
      captureRule: _captureRule,
    );

    widget.onStartGame(engine);
  }

  Color _getFlutterColor(LudoColor color) {
    switch (color) {
      case LudoColor.red:
        return const Color(0xFFE53935);
      case LudoColor.green:
        return const Color(0xFF2E7D32);
      case LudoColor.yellow:
        return const Color(0xFFF9A825);
      case LudoColor.blue:
        return const Color(0xFF1565C0);
    }
  }

  String _getColorName(LudoColor color) {
    switch (color) {
      case LudoColor.red:
        return 'Red';
      case LudoColor.green:
        return 'Green';
      case LudoColor.yellow:
        return 'Yellow';
      case LudoColor.blue:
        return 'Blue';
    }
  }

  void _assignPassPlayerColor(int playerIdx, LudoColor chosenColor) {
    setState(() {
      final int existingIdx = _passPlayerColors.sublist(0, _playerCount).indexOf(chosenColor);
      if (existingIdx != -1 && existingIdx != playerIdx) {
        final prev = _passPlayerColors[playerIdx];
        _passPlayerColors[existingIdx] = prev;
      }
      _passPlayerColors[playerIdx] = chosenColor;
    });
  }

  void _nextStep() {
    if (_currentStep < 3) {
      setState(() {
        _currentStep++;
      });
    } else {
      _onStart();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF4F6F9),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              // 1. Header Banner
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF880E4F), Color(0xFFC2185B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.pink.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.casino, size: 28, color: Colors.white),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'LUDO SETUP',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.1,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Configure your match step by step',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Step Progress Indicators
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: _buildStepperHeader(),
              ),

              // 3. Main Step Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    transitionBuilder: (child, anim) {
                      return FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.04, 0),
                            end: Offset.zero,
                          ).animate(anim),
                          child: child,
                        ),
                      );
                    },
                    child: KeyedSubtree(
                      key: ValueKey<int>(_currentStep),
                      child: _buildStepContent(),
                    ),
                  ),
                ),
              ),

              // 4. Navigation Bottom Bar (Back / Next / Start Game)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    if (_currentStep > 0)
                      OutlinedButton.icon(
                        onPressed: _prevStep,
                        icon: const Icon(Icons.arrow_back, size: 18),
                        label: const Text('Back'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey.shade800,
                          side: BorderSide(color: Colors.grey.shade300),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      )
                    else
                      const SizedBox(width: 80),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _nextStep,
                      icon: Icon(
                        _currentStep == 3 ? Icons.play_arrow_rounded : Icons.arrow_forward,
                        size: 20,
                      ),
                      label: Text(
                        _currentStep == 3 ? 'START GAME' : 'Next Step',
                        style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.8),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC2185B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Stepper Header with 4 Progress Tabs
  Widget _buildStepperHeader() {
    const steps = [
      {'title': 'Mode', 'icon': Icons.sports_esports_outlined},
      {'title': 'Players', 'icon': Icons.group_outlined},
      {'title': 'Rules', 'icon': Icons.shield_outlined},
      {'title': 'Colors', 'icon': Icons.palette_outlined},
    ];

    return Row(
      children: List.generate(steps.length, (idx) {
        final isCompleted = _currentStep > idx;
        final isCurrent = _currentStep == idx;
        final step = steps[idx];

        return Expanded(
          child: GestureDetector(
            onTap: () {
              if (idx < _currentStep) {
                setState(() => _currentStep = idx);
              }
            },
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? const Color(0xFFC2185B).withValues(alpha: 0.12)
                          : (isCompleted ? Colors.green.shade50 : Colors.white),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCurrent
                            ? const Color(0xFFC2185B)
                            : (isCompleted ? Colors.green.shade400 : Colors.grey.shade300),
                        width: isCurrent ? 2.0 : 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCurrent
                                ? const Color(0xFFC2185B)
                                : (isCompleted ? Colors.green.shade600 : Colors.grey.shade300),
                          ),
                          child: Center(
                            child: isCompleted
                                ? const Icon(Icons.check, size: 12, color: Colors.white)
                                : Text(
                                    '${idx + 1}',
                                    style: TextStyle(
                                      color: isCurrent ? Colors.white : Colors.grey.shade700,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            step['title'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                              color: isCurrent
                                  ? const Color(0xFFC2185B)
                                  : (isCompleted ? Colors.green.shade700 : Colors.grey.shade600),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (idx < steps.length - 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Icon(
                      Icons.chevron_right,
                      size: 14,
                      color: isCompleted ? Colors.green.shade400 : Colors.grey.shade400,
                    ),
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1Mode();
      case 1:
        return _buildStep2Players();
      case 2:
        return _buildStep3Rules();
      case 3:
        return _buildStep4Colors();
      default:
        return const SizedBox.shrink();
    }
  }

  // STEP 1: Game Mode
  Widget _buildStep1Mode() {
    return _buildCard(
      title: 'STEP 1: SELECT GAME MODE',
      icon: Icons.sports_esports_outlined,
      child: Column(
        children: [
          _buildSelectableOption(
            title: 'Play Against Computer',
            subtitle: 'Single Player mode with 1 Human vs Computer AI opponents',
            icon: Icons.smart_toy_outlined,
            isSelected: _selectedMode == LudoGameMode.vsComputer,
            onTap: () {
              setState(() {
                _selectedMode = LudoGameMode.vsComputer;
                if (_playerCount == 3) _playerCount = 4;
              });
            },
          ),
          const SizedBox(height: 12),
          _buildSelectableOption(
            title: 'Pass & Play',
            subtitle: 'Play locally with friends & family taking turns on this device',
            icon: Icons.phone_android_outlined,
            isSelected: _selectedMode == LudoGameMode.passAndPlay,
            onTap: () {
              setState(() {
                _selectedMode = LudoGameMode.passAndPlay;
              });
            },
          ),
          if (_selectedMode == LudoGameMode.passAndPlay) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: Colors.blue.shade700),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Pass & Play: Players share this device and pass it when their turn finishes. Completely offline & private.',
                      style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // STEP 2: Player Count
  Widget _buildStep2Players() {
    return _buildCard(
      title: 'STEP 2: SELECT NUMBER OF PLAYERS',
      icon: Icons.group_outlined,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildCountButton(
                  2,
                  _selectedMode == LudoGameMode.vsComputer ? '1 You + 1 Bot' : '2 People',
                ),
              ),
              if (_selectedMode == LudoGameMode.passAndPlay) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCountButton(3, '3 People'),
                ),
              ],
              const SizedBox(width: 12),
              Expanded(
                child: _buildCountButton(
                  4,
                  _selectedMode == LudoGameMode.vsComputer ? '1 You + 3 Bots' : '4 People',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.purple.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.people_outline, size: 20, color: Colors.purple.shade700),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _selectedMode == LudoGameMode.vsComputer
                        ? '$_playerCount Players: 1 human player and ${_playerCount - 1} computer AI bot opponents.'
                        : '$_playerCount Players: $_playerCount human participants sharing this device.',
                    style: TextStyle(fontSize: 12, color: Colors.purple.shade900),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // STEP 3: Token Capture Rule
  Widget _buildStep3Rules() {
    return _buildCard(
      title: 'STEP 3: TOKEN CAPTURE RULE',
      icon: Icons.shield_outlined,
      child: Column(
        children: [
          _buildRuleTile(
            rule: LudoCaptureRule.captureAndSendHome,
            title: 'Capture and Send Home (Classic)',
            description:
                'Landing on an opponent token sends it back to base. Safe squares (★) prevent capture. Captures grant an extra turn.',
            icon: Icons.security,
          ),
          const SizedBox(height: 12),
          _buildRuleTile(
            rule: LudoCaptureRule.noCapture,
            title: 'No Capture (Peaceful Mode)',
            description:
                'Landing on an opponent does NOT send it back to base. Multiple tokens can share the same square peacefully.',
            icon: Icons.handshake_outlined,
          ),
        ],
      ),
    );
  }

  // STEP 4: Player Customization & Colors
  Widget _buildStep4Colors() {
    return _buildCard(
      title: _selectedMode == LudoGameMode.vsComputer
          ? 'STEP 4: YOUR COLOR & DISPLAY NAME'
          : 'STEP 4: PLAYER NAMES & COLORS',
      icon: Icons.palette_outlined,
      child: _selectedMode == LudoGameMode.vsComputer
          ? _buildComputerModeCustomizer()
          : _buildPassAndPlayCustomizer(),
    );
  }

  Widget _buildCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFFC2185B)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildSelectableOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFC2185B).withValues(alpha: 0.08) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFFC2185B) : Colors.grey.shade300,
            width: isSelected ? 2.2 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFC2185B) : Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 24,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? const Color(0xFFC2185B) : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isSelected ? const Color(0xFFC2185B) : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountButton(int count, String subtitle) {
    final bool isSelected = _playerCount == count;
    return GestureDetector(
      onTap: () {
        setState(() {
          _playerCount = count;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFC2185B).withValues(alpha: 0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFFC2185B) : Colors.grey.shade300,
            width: isSelected ? 2.2 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: isSelected ? const Color(0xFFC2185B) : Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Players',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? const Color(0xFFC2185B) : Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleTile({
    required LudoCaptureRule rule,
    required String title,
    required String description,
    required IconData icon,
  }) {
    final bool isSelected = _captureRule == rule;
    return GestureDetector(
      onTap: () => setState(() => _captureRule = rule),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFC2185B).withValues(alpha: 0.06) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFFC2185B) : Colors.grey.shade300,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 2, right: 10, left: 2),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFFC2185B) : Colors.grey.shade400,
                  width: 2.0,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFC2185B),
                        ),
                      ),
                    )
                  : null,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? const Color(0xFFC2185B) : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      height: 1.3,
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

  Widget _buildComputerModeCustomizer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _humanNameController,
          decoration: InputDecoration(
            labelText: 'Your Display Name',
            prefixIcon: const Icon(Icons.person_outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Choose Your Color:',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black87),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: LudoColor.values.map((color) {
            final bool isSelected = _humanColor == color;
            final flutterColor = _getFlutterColor(color);
            return GestureDetector(
              onTap: () => setState(() => _humanColor = color),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? flutterColor.withValues(alpha: 0.15) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? flutterColor : Colors.grey.shade300,
                    width: isSelected ? 2.5 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: flutterColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: flutterColor.withValues(alpha: 0.4),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getColorName(color),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isSelected ? flutterColor : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPassAndPlayCustomizer() {
    return Column(
      children: List.generate(_playerCount, (idx) {
        final currentColor = _passPlayerColors[idx];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: _getFlutterColor(currentColor),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${idx + 1}',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _passPlayerNameControllers[idx],
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Player ${idx + 1}',
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      ),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: LudoColor.values.map((col) {
                  final bool isSelected = currentColor == col;
                  final flutterCol = _getFlutterColor(col);
                  final bool isTakenByOther = _passPlayerColors.sublist(0, _playerCount).contains(col) && !isSelected;

                  return GestureDetector(
                    onTap: () => _assignPassPlayerColor(idx, col),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isSelected ? flutterCol.withValues(alpha: 0.15) : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? flutterCol : (isTakenByOther ? Colors.grey.shade200 : Colors.grey.shade300),
                          width: isSelected ? 2.0 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: isTakenByOther ? flutterCol.withValues(alpha: 0.3) : flutterCol,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _getColorName(col),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isTakenByOther
                                  ? Colors.grey.shade400
                                  : (isSelected ? flutterCol : Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      }),
    );
  }
}
