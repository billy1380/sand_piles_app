import 'dart:math';

import 'package:flutter/material.dart';
import 'package:main_thread_processor/main_thread_processor.dart';
import 'package:sand_piles/sand_piles.dart' as sp;

class _ToppleTask implements Task {
  _ToppleTask(this.pageState);

  int count = 1;
  int done = 0;
  _HomePageState pageState;

  @override
  void run() {
    for (int i = 0; i < _HomePageState.topplesPerFrame; i++) {
      if (pageState._sand.topple()) {
        count++;
      }

      done++;
    }

    pageState.progressed(this);

    if (progress == 1) {
      pageState.taskComplete(this);
    }
  }

  @override
  double get progress {
    return done == count ? 1 : done / count;
  }

  @override
  void reset() {
    count = 1;
    done = 0;
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const double width = 600;

  static const double sandDim = 10;
  static const int topplesPerFrame = 1;
  static const int row = width ~/ sandDim;

  late sp.Sand _sand;
  late final _ToppleTask _toppleTask;
  String error = "";

  bool _pauseVisible = false;
  IconData _floatingActionButtonIcon = Icons.play_arrow;
  String _floatingActionButtonToolTip = "Uniform";

  final Random r = Random();

  @override
  void initState() {
    super.initState();

    _toppleTask = _ToppleTask(this);

    _uniformClicked(false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
            onPressed: () => _uniformClicked(false),
            icon: const Icon(Icons.line_style),
            tooltip: "Uniform",
          ),
          IconButton(
            onPressed: _randomClicked,
            icon: const Icon(Icons.line_axis),
            tooltip: "Random",
          ),
          IconButton(
            onPressed: () => _uniformClicked(true),
            icon: const Icon(Icons.clear),
            tooltip: "Clear",
          ),
        ],
      ),
      body: Center(
        child: _draw(_sand, _HomePageState.row, _HomePageState.row),
      ),
      floatingActionButton: _pauseVisible
          ? FloatingActionButton(
              onPressed: _pauseClicked,
              tooltip: _floatingActionButtonToolTip,
              child: Icon(_floatingActionButtonIcon),
            )
          : null,
    );
  }

  Widget _draw(sp.Sand sand, int rows, int columns) {
    final int totalItems = rows * columns;

    return GridView.count(
      mainAxisSpacing: 0,
      crossAxisCount: rows,
      children: [
        for (int i = 0; i < totalItems; i++)
          ColoredBox(
            color: color(sand.grains(i)),
            child: SizedBox(
              width: sandDim,
              height: sandDim,
              child: GestureDetector(
                onTap: _pauseVisible ? null : () => _gridItemClicked(i),
              ),
            ),
          ),
      ],
    );
  }

  static const List<Color> _colours = [
    Color.fromARGB(0xFF, 0xCC, 0x33, 0xFF),
    Color.fromARGB(0xFF, 0x99, 0x26, 0xFF),
    Color.fromARGB(0xFF, 0x52, 0x14, 0xFF),
    Color.fromARGB(0xFF, 0x00, 0x0, 0x0FF),
  ];

  Color color(int grains) {
    Color color;
    switch (grains) {
      case 0:
      case 1:
      case 2:
      case 3:
        color = _colours[grains];
        break;
      default:
        int g = _gray(grains);
        color = Color.fromARGB(0xFF, g, g, g);
        break;
    }
    return color;
  }

  int _gray(int grains) {
    return 255 - ((grains - 3) % 256);
  }

  sp.Builder _uniform(sp.Builder builder, final int itemsPerRow,
      final int totalItems, int grains) {
    builder.itemsPerRow(itemsPerRow);

    for (int i = 0; i < totalItems; i++) {
      builder.start(grains, i);
    }

    return builder;
  }

  sp.Builder _random(sp.Builder builder, final int itemsPerRow,
      final int totalItems, int maxGrains) {
    builder.itemsPerRow(itemsPerRow);

    for (int i = 0; i < totalItems; i++) {
      builder.start(r.nextInt(maxGrains), i);
    }

    return builder;
  }

  void _gridItemClicked(int at) {
    _sand.add(1000, at);
    Processor.shared.removeTask(_toppleTask);
    _toppleTask.reset();
    Processor.shared.addTask(_toppleTask);

    setState(() {
      _pauseVisible = true;
      _floatingActionButtonIcon = Icons.pause;
      _floatingActionButtonToolTip = "pause";
    });
  }

  void _randomClicked() {
    Processor.shared.removeTask(_toppleTask);
    _sand =
        _random(sp.Sand.builder.shape(sp.Tileable.square), row, row * row, 4)
            .build();
    _toppleTask.reset();
    Processor.shared.addTask(_toppleTask);

    setState(() {
      _pauseVisible = true;
      _floatingActionButtonIcon = Icons.pause;
      _floatingActionButtonToolTip = "pause";
    });
  }

  void _uniformClicked(bool clear) {
    Processor.shared.removeTask(_toppleTask);
    _sand = _uniform(sp.Sand.builder.shape(sp.Tileable.square), row, row * row,
            clear ? 0 : 4)
        .build();
    _toppleTask.reset();
    Processor.shared.addTask(_toppleTask);

    setState(() {
      _pauseVisible = true;
      _floatingActionButtonIcon = Icons.pause;
      _floatingActionButtonToolTip = "pause";
    });
  }

  void _pauseClicked() {
    if (Processor.shared.hasOutstanding) {
      Processor.shared.removeTask(_toppleTask);

      setState(() {
        _pauseVisible = true;
        _floatingActionButtonIcon = Icons.play_arrow;
        _floatingActionButtonToolTip = "resume";
      });
    } else {
      Processor.shared.addTask(_toppleTask);
      setState(() {
        _pauseVisible = true;
        _floatingActionButtonIcon = Icons.pause;
        _floatingActionButtonToolTip = "pause";
      });
    }
  }

  void progressed(Task task) {
    setState(() {});
  }

  void taskComplete(Task task) {
    setState(() {
      _pauseVisible = false;
      _floatingActionButtonIcon = Icons.play_arrow;
      _floatingActionButtonToolTip = "Random";
    });
  }
}
