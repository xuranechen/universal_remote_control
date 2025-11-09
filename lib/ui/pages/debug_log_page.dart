import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'dart:collection';

/// 日志输出类
class LogOutput extends LogOutput {
  static final LogOutput _instance = LogOutput._internal();
  factory LogOutput() => _instance;
  LogOutput._internal();

  final Queue<String> _logs = Queue();
  final int _maxLogs = 500;

  @override
  void output(OutputEvent event) {
    for (var line in event.lines) {
      _logs.add(line);
      if (_logs.length > _maxLogs) {
        _logs.removeFirst();
      }
    }
  }

  List<String> getLogs() => _logs.toList();
  void clear() => _logs.clear();
}

/// 调试日志页面
class DebugLogPage extends StatefulWidget {
  const DebugLogPage({super.key});

  @override
  State<DebugLogPage> createState() => _DebugLogPageState();
}

class _DebugLogPageState extends State<DebugLogPage> {
  final ScrollController _scrollController = ScrollController();
  bool _autoScroll = true;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_autoScroll && _scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('调试日志'),
        actions: [
          IconButton(
            icon: Icon(_autoScroll ? Icons.arrow_downward : Icons.arrow_downward_outlined),
            onPressed: () {
              setState(() {
                _autoScroll = !_autoScroll;
              });
            },
            tooltip: _autoScroll ? '禁用自动滚动' : '启用自动滚动',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              setState(() {
                LogOutput().clear();
              });
            },
            tooltip: '清空日志',
          ),
        ],
      ),
      body: StreamBuilder(
        stream: Stream.periodic(const Duration(milliseconds: 500)),
        builder: (context, snapshot) {
          final logs = LogOutput().getLogs();
          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
          
          return ListView.builder(
            controller: _scrollController,
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              Color textColor = Colors.white;
              
              if (log.contains('ERROR') || log.contains('错误')) {
                textColor = Colors.red;
              } else if (log.contains('WARN') || log.contains('警告')) {
                textColor = Colors.orange;
              } else if (log.contains('INFO')) {
                textColor = Colors.blue;
              } else if (log.contains('DEBUG')) {
                textColor = Colors.grey;
              }
              
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  log,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: textColor,
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        },
        child: const Icon(Icons.arrow_downward),
      ),
    );
  }
}
