import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../theme/app_theme.dart';

class EqualizerScreen extends StatefulWidget {
  const EqualizerScreen({super.key});

  @override
  State<EqualizerScreen> createState() => _EqualizerScreenState();
}

class _EqualizerScreenState extends State<EqualizerScreen> {
  static const _channel = MethodChannel('com.example.mp3_player/media');

  bool _isLoading = true;
  int _numBands = 0;
  int _minLevel = -1500;
  int _maxLevel = 1500;
  List<Map<String, dynamic>> _bands = [];
  List<String> _presets = [];
  int _selectedPreset = -1;

  @override
  void initState() {
    super.initState();
    _initEqualizer();
  }

  Future<void> _initEqualizer() async {
    try {
      final playerProvider = context.read<PlayerProvider>();
      final audioSessionId = await playerProvider.player.androidAudioSessionId;

      final result = await _channel.invokeMethod('initEqualizer', {
        'audioSessionId': audioSessionId ?? 0,
      });

      setState(() {
        _numBands = result['numBands'] as int;
        _minLevel = result['minLevel'] as int;
        _maxLevel = result['maxLevel'] as int;
        _bands = (result['bands'] as List)
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _presets = (result['presets'] as List).map((e) => e.toString()).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  String _formatFreq(int hz) {
    if (hz >= 1000000) return '${(hz / 1000000).toStringAsFixed(0)}kHz';
    if (hz >= 1000) return '${(hz / 1000).toStringAsFixed(0)}Hz';
    return '${hz}Hz';
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: const Text('이퀄라이저',
            style: TextStyle(color: AppTheme.textPrimary)),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textPrimary),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : Column(
              children: [
                // 프리셋 선택
                if (_presets.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('프리셋',
                            style: TextStyle(
                                color: primaryColor,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2)),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: List.generate(_presets.length, (index) {
                              final isSelected = _selectedPreset == index;
                              return GestureDetector(
                                onTap: () async {
                                                                  await _channel.invokeMethod(
                                                                      'setEqualizerPreset', {'preset': index});
                                                                  setState(() => _selectedPreset = index);

                                                                  // 밴드 레벨 직접 읽어오기
                                                                  try {
                                                                    for (int i = 0; i < _bands.length; i++) {
                                                                      final result = await _channel.invokeMethod(
                                                                          'getEqualizerBandLevel', {'band': i});
                                                                      setState(() {
                                                                        _bands[i]['level'] = result as int;
                                                                      });
                                                                    }
                                                                  } catch (e) {
                                                                    await _initEqualizer();
                                                                  }
                                                                },
                                child: Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? primaryColor
                                        : AppTheme.surfaceVariant,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _presets[index],
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.black
                                          : AppTheme.textSecondary,
                                      fontSize: 12,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                  ),

                const Divider(color: AppTheme.divider),

                // 밴드 슬라이더
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: List.generate(_bands.length, (index) {
                        final band = _bands[index];
                        final level = band['level'] as int;
                        final freq = band['freq'] as int;

                        return Column(
                          children: [
                            Text(
                              '${level > 0 ? '+' : ''}${(level / 100).toStringAsFixed(0)}',
                              style: TextStyle(
                                  color: primaryColor, fontSize: 11),
                            ),
                            Expanded(
                              child: RotatedBox(
                                quarterTurns: 3,
                                child: Slider(
                                  value: level.toDouble(),
                                  min: _minLevel.toDouble(),
                                  max: _maxLevel.toDouble(),
                                  onChanged: (value) async {
                                    setState(() {
                                      _bands[index]['level'] = value.toInt();
                                      _selectedPreset = -1;
                                    });
                                    await _channel.invokeMethod(
                                        'setEqualizerBand', {
                                      'band': index,
                                      'level': value.toInt(),
                                    });
                                  },
                                ),
                              ),
                            ),
                            Text(
                              _formatFreq(freq),
                              style: const TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 10),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),

                // 초기화 버튼
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: () async {
                      for (int i = 0; i < _bands.length; i++) {
                        await _channel.invokeMethod('setEqualizerBand', {
                          'band': i,
                          'level': 0,
                        });
                      }
                      setState(() {
                        for (var band in _bands) {
                          band['level'] = 0;
                        }
                        _selectedPreset = -1;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.surfaceVariant,
                      foregroundColor: primaryColor,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text('초기화'),
                  ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _channel.invokeMethod('releaseEqualizer');
    super.dispose();
  }
}