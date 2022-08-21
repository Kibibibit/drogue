

import 'package:dcurses/dcurses.dart';
import 'package:drogue/windows/level_window.dart';

class Drogue {

  late Screen screen;

  late LevelWindow _levelWindow;

  Drogue() {

    screen = Screen();
    

  }

  Future<void> run() async {

    screen.disableBlocking();
    screen.listen((Key key) => _onKey(key));
    _setUpWindows();

    screen.refresh();
    await screen.run();

  }

  void _setUpWindows() {

    _levelWindow = LevelWindow("levelWindow",0,0,screen.columns, screen.lines);
    screen.addWindow(_levelWindow);

  }

  void _onKey(Key key) {

  }

}