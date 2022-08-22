
import 'package:dcurses/dcurses.dart';
import 'package:drogue/geo/vector.dart';
import 'package:drogue/level/level_gen_data.dart';
import 'package:drogue/level/level_tiles.dart';

class LevelWindow extends Window {

  LevelWindow(String label, int y, int x, int columns, int lines) : super(label, y, x, columns, lines);
  
  @override
  void onDraw() {
    LevelGenData level = LevelGenData(35,35,bossRoomSize: Vector(10,10));
    level.generate();

    for (int y = 0; y < level.height; y++) {
      for (int x = 0; x < level.width; x++) {

        int tile = level.getTile(Vector(x, y));

        cx = (x*2)+1;
        cy = y+1;

        int charCode = 0x2588;
        List<Modifier> mods = [];

        if (tile == tileFloor || tile== tileHall) {
          charCode = 0x2591;
        } else if (tile == tileAdj) {
          charCode = 0x2593;
        } else if (tile == tileDoor) {
          charCode = 0x259A;
        } else if (tile == tileBossDoor) {
          charCode = 0x259A;
          mods=[Modifier.fg(Colour.red)];
        }

        Ch ch = Ch(charCode, mods);

        add(ch);
        cx++;
        add(ch);
        

      }
    }

  }



  
}