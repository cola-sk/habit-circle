import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 任务计时器状态
class TimerState {
  final bool isRunning;
  final int elapsedSeconds;
  final String? activeTaskId;  // 当前进行中的任务 ID

  const TimerState({
    this.isRunning = false,
    this.elapsedSeconds = 0,
    this.activeTaskId,
  });

  int get elapsedMinutes => elapsedSeconds ~/ 60;

  String get formattedTime {
    final minutes = (elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  TimerState copyWith({
    bool? isRunning,
    int? elapsedSeconds,
    String? activeTaskId,
  }) =>
      TimerState(
        isRunning: isRunning ?? this.isRunning,
        elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
        activeTaskId: activeTaskId ?? this.activeTaskId,
      );
}

final timerProvider =
    StateNotifierProvider<TimerNotifier, TimerState>(
  (ref) => TimerNotifier(),
);

class TimerNotifier extends StateNotifier<TimerState> {
  Timer? _timer;

  TimerNotifier() : super(const TimerState());

  void start(String taskId) {
    if (state.isRunning) return;
    state = TimerState(isRunning: true, elapsedSeconds: 0, activeTaskId: taskId);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
    });
  }

  void pause() {
    _timer?.cancel();
    state = state.copyWith(isRunning: false);
  }

  void resume() {
    if (state.isRunning || state.activeTaskId == null) return;
    state = state.copyWith(isRunning: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
    });
  }

  /// 结束计时，返回已计时分钟数
  int stop() {
    _timer?.cancel();
    final minutes = state.elapsedMinutes;
    state = const TimerState();
    return minutes;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
