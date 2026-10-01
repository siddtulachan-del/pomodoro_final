import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_state.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.appState});

  final AppState appState;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  AppState get _state => widget.appState;

  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _state.addListener(_onStateChanged);
    _hideStatusBar();
  }

  @override
  void dispose() {
    _state.removeListener(_onStateChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _hideStatusBar();
    }
  }

  void _hideStatusBar() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  Widget build(BuildContext context) {
    if (_state.inFocusMode) {
      return _FocusView(state: _state);
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: IndexedStack(
                index: _currentTab,
                children: [
                  _SprintTab(state: _state),
                  _HistoryTab(state: _state),
                  _SettingsTab(state: _state),
                ],
              ),
            ),
            _MacTabBar(
              selectedIndex: _currentTab,
              onSelected: (index) => setState(() => _currentTab = index),
            ),
          ],
        ),
      ),
    );
  }
}

class _MacTabBar extends StatelessWidget {
  const _MacTabBar({required this.selectedIndex, required this.onSelected});

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const labels = ['Timer', 'History', 'Settings'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final barColor = theme.colorScheme.surfaceContainerHighest;
    final selectedColor = theme.colorScheme.primary;
    final selectedTextColor = theme.colorScheme.onPrimary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 370),
          child: Container(
            height: 52,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Row(
              children: [
                for (var index = 0; index < labels.length; index++)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => onSelected(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selectedIndex == index ? selectedColor : null,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Text(
                          labels[index],
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: selectedIndex == index
                                ? selectedTextColor
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight: selectedIndex == index
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FocusView extends StatelessWidget {
  const _FocusView({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isLandscape = constraints.maxWidth > constraints.maxHeight;
            final dialSize = isLandscape
                ? (constraints.maxHeight * 0.78).clamp(120.0, 240.0).toDouble()
                : 215.0;
            final controls = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton.filled(
                  iconSize: 48,
                  icon: Icon(state.isRunning ? Icons.pause : Icons.play_arrow),
                  onPressed: () {
                    if (state.isRunning) {
                      state.pause();
                    } else {
                      state.startResume();
                    }
                  },
                ),
                const SizedBox(width: 16),
                IconButton.filledTonal(
                  iconSize: 42,
                  icon: const Icon(Icons.stop),
                  onPressed: state.stopSession,
                ),
              ],
            );
            final content = isLandscape
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _TimerDial(state: state, size: dialSize, strokeWidth: 12),
                      const SizedBox(width: 32),
                      controls,
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _TimerDial(state: state, size: dialSize, strokeWidth: 12),
                      const SizedBox(height: 48),
                      controls,
                    ],
                  );

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: content,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TimerDial extends StatelessWidget {
  const _TimerDial({
    required this.state,
    required this.size,
    this.strokeWidth = 10,
  });

  final AppState state;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final phaseDuration = state.phase == TimerPhase.sprint
        ? AppState.sprintSeconds
        : state.breakMinutes * 60;
    final progress = (1 - state.remainingSeconds / phaseDuration).clamp(
      0.0,
      1.0,
    );
    final progressColor = state.phase == TimerPhase.sprint
        ? theme.colorScheme.primary
        : theme.colorScheme.tertiary;

    final numberStyle = TextStyle(
      fontFamily: 'Magnat Poster',
      fontFamilyFallback: const ['Bricolage Grotesque'],
      fontWeight: FontWeight.w700,
      fontFeatures: const [FontFeature.tabularFigures()],
      letterSpacing: 2,
    );

    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.square(
            dimension: size,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: strokeWidth,
              strokeCap: StrokeCap.round,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              color: progressColor,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                state.formatTime(state.remainingSeconds),
                style: theme.textTheme.displayLarge?.merge(numberStyle),
                textAlign: TextAlign.center,
                maxLines: 1,
                softWrap: false,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SprintTab extends StatelessWidget {
  const _SprintTab({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sprintStyle = theme.textTheme.headlineLarge;
    final controls = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filled(
          iconSize: 40,
          icon: Icon(state.isRunning ? Icons.pause : Icons.play_arrow),
          onPressed: () {
            if (state.isRunning) {
              state.pause();
            } else {
              state.startResume();
            }
          },
        ),
        if (state.sessionActive) ...[
          const SizedBox(width: 16),
          IconButton.outlined(
            iconSize: 32,
            icon: const Icon(Icons.stop),
            onPressed: state.resetSession,
          ),
        ],
      ],
    );

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isLandscape = constraints.maxWidth > constraints.maxHeight;
          if (isLandscape) {
            final dialSize = (constraints.maxHeight * 0.78)
                .clamp(120.0, 240.0)
                .toDouble();

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _TimerDial(state: state, size: dialSize, strokeWidth: 12),
                      const SizedBox(width: 24),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (!state.sessionActive) ...[
                            Text(
                              'Sprint',
                              style: sprintStyle?.copyWith(fontSize: 32),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                          ],
                          _SprintProgress(state: state),
                          if (state.phase == TimerPhase.breakTime &&
                              !state.sessionComplete)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                '${state.breakMinutes} min break',
                                style: theme.textTheme.bodyMedium,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          const SizedBox(height: 16),
                          controls,
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (!state.sessionActive) ...[
                      Transform.translate(
                        offset: const Offset(0, -8),
                        child: Text(
                          'Sprint',
                          style: sprintStyle?.copyWith(
                            fontSize: (sprintStyle?.fontSize ?? 32) * 2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    _SprintProgress(state: state),
                    const SizedBox(height: 24),
                    _TimerDial(state: state, size: 215, strokeWidth: 12),
                    const SizedBox(height: 8),
                    if (state.phase == TimerPhase.breakTime &&
                        !state.sessionComplete)
                      Text(
                        '${state.breakMinutes} min break',
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    const SizedBox(height: 24),
                    controls,
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SprintProgress extends StatelessWidget {
  const _SprintProgress({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completed = state.todaySprintsCompleted.clamp(0, state.dailyGoal);

    return Semantics(
      label: '$completed of ${state.dailyGoal} daily sprints completed',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < state.dailyGoal; index++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index < completed
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainerHighest,
                  border: Border.all(
                    color: index < completed
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SettingsTab extends StatelessWidget {
  const _SettingsTab({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locked = state.sessionActive;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(4, 16, 4, 16),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              'Settings',
              style: theme.textTheme.headlineMedium?.copyWith(fontSize: 36),
            ),
          ),
          const SizedBox(height: 16),
          _SessionSummary(state: state),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text('Sprint Setting', style: theme.textTheme.titleLarge),
          ),
          const SizedBox(height: 12),
          if (locked)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Stop the current session to change sprint settings.',
                style: theme.textTheme.bodySmall,
              ),
            ),
          _SettingsGroup(
            items: [
              _StepperTile(
                title: 'Sprint length',
                subtitle: '(Standard Pomodoro)',
                value: AppState.maxSprintMinutes,
                unit: 'min',
                enabled: false,
                showControls: false,
              ),
              _StepperTile(
                title: 'Sprints per session',
                value: state.totalSprints,
                min: 1,
                max: 12,
                enabled: !locked,
                onChanged: state.setTotalSprints,
              ),
              _StepperTile(
                title: 'Break length',
                value: state.breakMinutes,
                min: AppState.minBreakMinutes,
                max: 30,
                unit: 'min',
                enabled: !locked,
                onChanged: state.setBreakMinutes,
              ),
            ],
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text('Daily goal', style: theme.textTheme.titleLarge),
          ),
          const SizedBox(height: 12),
          _SettingsGroup(
            items: [
              _StepperTile(
                title: 'Session per day',
                value: state.dailyGoal,
                min: 1,
                max: 20,
                enabled: !locked,
                onChanged: state.setDailyGoal,
              ),
            ],
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text('Appearance', style: theme.textTheme.titleLarge),
          ),
          const SizedBox(height: 8),
          _ThemeModeSelector(state: state),
          const SizedBox(height: 16),
          _SettingsGroup(
            items: [
              ListTile(
                leading: const Icon(Icons.refresh, color: Color(0xFF8B1E1E)),
                title: const Text(
                  'Reset session',
                  style: TextStyle(color: Color(0xFF8B1E1E)),
                ),
                subtitle: const Text('Start over from sprint 1'),
                onTap: state.resetSession,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SessionSummary extends StatelessWidget {
  const _SessionSummary({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final restBarColor = isDark
        ? const Color(0xFF79BDE2)
        : const Color(0xFF246B91);
    final focusMinutes = state.totalSprints * AppState.maxSprintMinutes;
    final restMinutes = (state.totalSprints - 1) * state.breakMinutes;
    final totalMinutes = focusMinutes + restMinutes;
    final durationLabel = totalMinutes >= 60
        ? '${totalMinutes ~/ 60}h ${totalMinutes % 60}m'
        : '${totalMinutes}m';

    return Container(
      key: const ValueKey('sessionSummary'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            durationLabel,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: colorScheme.onSurface,
              fontSize: 32,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$focusMinutes min focus, $restMinutes min rest',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 18),
          Semantics(
            label: '$focusMinutes minutes focus and $restMinutes minutes rest',
            child: Row(
              children: [
                for (var index = 0; index < state.totalSprints; index++) ...[
                  Expanded(
                    flex: AppState.maxSprintMinutes,
                    child: _SessionSegment(color: colorScheme.primary),
                  ),
                  if (index < state.totalSprints - 1) ...[
                    const SizedBox(width: 4),
                    Expanded(
                      flex: state.breakMinutes,
                      child: _SessionSegment(
                        key: const ValueKey('restTimeSegment'),
                        color: restBarColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionSegment extends StatelessWidget {
  const _SessionSegment({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 12,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.items});

  final List<Widget> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(22),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Material(
          color: theme.colorScheme.surfaceContainerLow,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var index = 0; index < items.length; index++) ...[
                if (index > 0)
                  Divider(height: 1, color: theme.colorScheme.outlineVariant),
                items[index],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeModeSelector extends StatelessWidget {
  const _ThemeModeSelector({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SegmentedButton<AppThemeMode>(
        segments: const [
          ButtonSegment(
            value: AppThemeMode.light,
            label: Text('Light'),
            icon: Icon(Icons.light_mode),
          ),
          ButtonSegment(
            value: AppThemeMode.dark,
            label: Text('Dark'),
            icon: Icon(Icons.dark_mode),
          ),
          ButtonSegment(
            value: AppThemeMode.system,
            label: Text('System'),
            icon: Icon(Icons.settings_brightness),
          ),
        ],
        selected: {state.themeMode},
        onSelectionChanged: (selection) {
          state.setThemeMode(selection.first);
        },
      ),
    );
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab({required this.state});

  final AppState state;

  String _formatDate(String dateKey) {
    final parts = dateKey.split('-');
    if (parts.length != 3) return dateKey;
    return '${parts[2]}/${parts[1]}/${parts[0]}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final records = state.historyRecords;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('History', style: theme.textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  'Today: ${state.todaySprintsCompleted} / ${state.dailyGoal} sprints '
                  '(${state.todayGoalMet ? 'goal met' : 'goal not met'})',
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),
          ),
          Expanded(
            child: records.isEmpty
                ? Center(
                    child: Text(
                      'No history yet.\nComplete sprints to see daily records.',
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: records.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final record = records[index];
                      final isToday =
                          record.dateKey == AppState.dateKeyFor(DateTime.now());

                      return ListTile(
                        title: Text(
                          isToday ? 'Today' : _formatDate(record.dateKey),
                        ),
                        subtitle: Text(
                          '${record.sprintsCompleted} / ${record.dailyGoal} sprints',
                        ),
                        trailing: Icon(
                          record.goalMet
                              ? Icons.check_circle_outline
                              : Icons.cancel_outlined,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _StepperTile extends StatefulWidget {
  const _StepperTile({
    required this.title,
    this.subtitle,
    required this.value,
    this.min = 0,
    this.max = 100,
    this.unit = '',
    this.enabled = true,
    this.showControls = true,
    this.onChanged,
  });

  final String title;
  final String? subtitle;
  final int value;
  final int min;
  final int max;
  final String unit;
  final bool enabled;
  final bool showControls;
  final ValueChanged<int>? onChanged;

  @override
  State<_StepperTile> createState() => _StepperTileState();
}

class _StepperTileState extends State<_StepperTile> {
  late final TextEditingController _valueController;
  late final FocusNode _valueFocusNode;

  @override
  void initState() {
    super.initState();
    _valueController = TextEditingController(text: '${widget.value}');
    _valueFocusNode = FocusNode()..addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant _StepperTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && !_valueFocusNode.hasFocus) {
      _setControllerValue(widget.value);
    }
  }

  void _handleFocusChange() {
    if (!_valueFocusNode.hasFocus) _commitValue();
  }

  void _setControllerValue(int value) {
    final text = '$value';
    _valueController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _commitValue() {
    final parsed = int.tryParse(_valueController.text);
    final value = (parsed ?? widget.value)
        .clamp(widget.min, widget.max)
        .toInt();
    _setControllerValue(value);
    if (value != widget.value) widget.onChanged?.call(value);
  }

  @override
  void dispose() {
    _valueFocusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNarrow = MediaQuery.sizeOf(context).width < 480;
    final controlGap = isNarrow ? 4.0 : 12.0;
    final valueWidth = isNarrow ? 64.0 : 72.0;
    final controlsWidth = 80 + controlGap * 2 + valueWidth;
    final isDark = theme.brightness == Brightness.dark;
    final buttonColorScheme = isDark
        ? ColorScheme.fromSeed(
            seedColor: const Color(0xFFCF3F26),
            brightness: Brightness.light,
          )
        : theme.colorScheme;
    final stepperButtonStyle = IconButton.styleFrom(
      shape: const CircleBorder(),
      backgroundColor: buttonColorScheme.secondaryContainer,
      foregroundColor: buttonColorScheme.onSecondaryContainer,
      disabledBackgroundColor: theme.colorScheme.surfaceContainerHighest,
      disabledForegroundColor: theme.colorScheme.onSurfaceVariant,
    );

    TextSpan valueSpan(Color color, {required bool emphasized}) {
      return TextSpan(
        children: [
          TextSpan(
            text: '${widget.value}',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: color,
              fontSize: emphasized ? 22 : 16,
              fontWeight: emphasized ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          if (widget.unit.isNotEmpty)
            TextSpan(
              text: ' ${widget.unit}',
              style: theme.textTheme.bodySmall?.copyWith(color: color),
            ),
        ],
      );
    }

    final controlGroup = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filledTonal(
          key: ValueKey('decrement-${widget.title}'),
          iconSize: 18,
          constraints: const BoxConstraints.tightFor(width: 40, height: 40),
          style: stepperButtonStyle,
          icon: const Icon(Icons.remove),
          onPressed: widget.enabled && widget.value > widget.min
              ? () => widget.onChanged!(widget.value - 1)
              : null,
        ),
        SizedBox(width: controlGap),
        SizedBox(
          width: valueWidth,
          child: Row(
            children: [
              SizedBox(
                width: valueWidth - 24,
                child: TextField(
                  key: ValueKey('value-${widget.title}'),
                  controller: _valueController,
                  focusNode: _valueFocusNode,
                  enabled: widget.enabled,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.center,
                  textAlignVertical: TextAlignVertical.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  onSubmitted: (_) {
                    _commitValue();
                    _valueFocusNode.unfocus();
                  },
                ),
              ),
              SizedBox(
                width: 24,
                child: widget.unit.isEmpty
                    ? null
                    : Text(
                        widget.unit,
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                      ),
              ),
            ],
          ),
        ),
        SizedBox(width: controlGap),
        IconButton.filledTonal(
          key: ValueKey('increment-${widget.title}'),
          iconSize: 18,
          constraints: const BoxConstraints.tightFor(width: 40, height: 40),
          style: stepperButtonStyle,
          icon: const Icon(Icons.add),
          onPressed: widget.enabled && widget.value < widget.max
              ? () => widget.onChanged!(widget.value + 1)
              : null,
        ),
      ],
    );

    final displayValue = Container(
      key: const ValueKey('fixedSprintValuePill'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text.rich(
        valueSpan(theme.colorScheme.onSurface, emphasized: true),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 96),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium,
                  ),
                  if (widget.subtitle?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 16),
            if (widget.showControls)
              controlGroup
            else
              SizedBox(
                width: controlsWidth,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: displayValue,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
