import 'dart:math';

import 'package:drogue/extensions/random_ext.dart';
import 'package:drogue/geo/vector.dart';
import 'package:drogue/level/level_tiles.dart';

class LevelGenData {

  final int width, height;

  late final List<List<int>> data;

  late final Random random;
  final int? seed;
  final int minRoomWidth, maxRoomWidth, minRoomHeight, maxRoomHeight;
  final int roomDensity;
  final int conformity;
  final int minLoopLength;

  final List<Vector> _dirs = [Vector(0,1), Vector(0,-1), Vector(1,0), Vector(-1,0)];

  final Map<int, Set<Vector>> tiles = {};

  void Function(int width, int height, List<List<int>> data)? startingDefinition;

  LevelGenData(this.width, this.height, {
    this.seed, 
    this.minRoomWidth = 3, 
    this.maxRoomWidth = 8,
    this.minRoomHeight = 3,
    this.maxRoomHeight = 8,
    this.roomDensity = 75,
    this.conformity = 2,
    this.minLoopLength = 14,
    this.startingDefinition
  }) {
    data = List.generate(height, (y) => List.generate(width, (x) {
      int tile = x == 0 || x == width-1 || y == 0 || y == height-1 ? tileAdj : tileWall;
      return tile;
    }

    ));
    
    startingDefinition?.call(width,height,data);

    for (int x = 0; x < width; x ++) {
      for (int y = 0; y < height; y++) {
        addTile(Vector(x,y),getTile(Vector(x,y)));
      }
    }

    random = Random(seed);
  }

  int getTile(Vector v) {
    return data[v.y][v.x];
  }

  void addTile(Vector loc, int tile) {
    int oldTile = getTile(loc);

    if (tiles.containsKey(oldTile)) {
      tiles[oldTile]?.remove(loc);
    }
    
    if (!tiles.containsKey(tile)) {
      tiles[tile] = {};
    }

    tiles[tile]?.add(loc);
    data[loc.y][loc.x] = tile;
  }

  Set<Vector> tilesOf(int tile) {
    return tiles[tile] ?? {};
  }

  void generate() {
    _generateRooms();
    _generateCorridors();
    _generateDoorGroups();
    _selectDoors();
    _cullDoors();
    _removeDeadEnds();
    _cleanUp();
  }


  void _generateRooms() {

    for (int iter = 0; iter < roomDensity; iter++) {

      int x = random.nextInRange(1, width-1);
      int y = random.nextInRange(1, height-1);

      int w = random.nextInRange(minRoomWidth, maxRoomWidth);
      int h = random.nextInRange(minRoomHeight, maxRoomHeight);

      bool valid = true;

      for (int xx = x; xx < x+w; xx++) {
        for (int yy = y; yy < y+h; yy++) {
          if (getTile(Vector(xx,yy)) == tileAdj || getTile(Vector(xx,yy)) == tileFloor) {
            valid = false;
            break;
          }
        }

        if (!valid) {
          break;
        }
      }

      if (!valid) {
        continue;
      }

      for (int xx = x-1; xx < x+w+1; xx++) {
        for (int yy = y-1; yy < y+h+1; yy++) {

          if (xx == x-1 || xx == x+w || yy == y-1 || yy == y+h) {
            addTile(Vector(xx,yy), tileAdj);
          } else {
            addTile(Vector(xx,yy), tileFloor);
          }

        }
      }

    }

  }

  void _generateCorridors() {

    while (tilesOf(tileWall).isNotEmpty) {

      List<Vector> stack = [random.from(tilesOf(tileWall))];
      Vector lastDirection = random.from(_dirs);

      Vector p = stack.last;
      addTile(p, tileHall);

      while (stack.isNotEmpty) {

        //Find adjacentTiles with only one neighbour, and add to path and then stack.
        //Otherwise, pop off stack

        Vector p = stack.last;
        
        List<Vector> options = [];

        for (Vector d1 in _dirs) {
          Vector o = p+d1;

          if (getTile(o) != tileWall && getTile(o) != tileHallAdj) {
            continue;
          }

          int neighbours = 0;
          for (Vector d2 in _dirs) {
            Vector n = o+d2;
            if (getTile(n) == tileHall) {
              neighbours++;
            }
          }
          if (neighbours < 2) {
            options.add(o);
            if (d1 == lastDirection) {
              for (int iter = 0; iter < conformity; iter++) {
                options.add(o);
              }
            }
          }

        }
        
        if (options.isEmpty) {
          stack.removeLast();
        } else {
          Vector newTile = random.from(options);
          lastDirection = newTile-p;
          stack.add(newTile);
          addTile(newTile, tileHall);
          for (Vector d in _dirs) {
            Vector a = newTile+d;
            if (getTile(a) == tileWall) {
              addTile(a, tileHallAdj);
            }
          }
        }

      }

    }
  }

  void _generateDoorGroups() {

    List<Vector> adjs = tilesOf(tileAdj).toList();

    for (Vector v in adjs) {
      
      if (v.x == 0 || v.x == width -1 || v.y == 0 || v.y == height -1) {
        continue;
      }

      Vector py0 = v-Vector(0,1);
      Vector py1 = v+Vector(0,1);

      Vector px0 = v-Vector(1,0);
      Vector px1 = v+Vector(1,0);

      int tPy0 = getTile(py0);
      int tPy1 = getTile(py1);

      int tPx0 = getTile(px0);
      int tPx1 = getTile(px1);

      if ((tPy0 == tileFloor && tPy1 == tileFloor) || ((tPy0 == tileFloor || tPy1 == tileFloor) && (tPy0 == tileHall || tPy1 == tileHall) && (tPy0 != tPy1))) {
        addTile(v, tileDoor);
      }
      if ((tPx0 == tileFloor && tPx1 == tileFloor) || ((tPx0 == tileFloor || tPx1 == tileFloor) && (tPx0 == tileHall || tPx1 == tileHall) && (tPx0 != tPx1))) {
        addTile(v, tileDoor);
      }

    }

  }

  void _selectDoors() {

    List<Vector> doors = tilesOf(tileDoor).toList();

    for (Vector v in doors) {
      if (getTile(v) != tileDoor) {
        continue;
      }
      Set<Vector> inGroup = {};
      List<Vector> toCheck = [v];
      while (toCheck.isNotEmpty) {
        Vector c = toCheck.removeLast();
        inGroup.add(c);
        for (Vector d in _dirs) {
          Vector n = d+c;
          
          if (getTile(n) == tileDoor && !inGroup.contains(n) && !toCheck.contains(n)) {
            toCheck.add(n);
          }
          
        }
      }

      for (Vector r in inGroup) {
        addTile(r, tileAdj);
      }
      addTile(random.from(inGroup), tileDoor);

    }

  }

  void _cullDoors() {

    List<Vector> doors = tilesOf(tileDoor).toList();

    for (Vector door in doors) {

      if (getTile(door) != tileDoor) {
        continue;
      }

      bool foundP0 = false;
      late Vector p0;
      late Vector p1;

      for (Vector d in _dirs) {
        Vector t = d+door;
        if (getTile(t) == tileHall || getTile(t) == tileFloor) {
          if (foundP0) {
            p1 = t;
          } else {
            p0 = t;
            foundP0 = true;
          }
        }
      }

      if (getTile(p1) == getTile(p0)) {
        continue;
      }
      
      Vector inRoom = getTile(p0) == tileFloor ? p0 : p1;
      Vector outRoom = getTile(p1) == tileHall ? p1 : p0;

      List<Vector> toCheck = [inRoom];
      Set<Vector> checked = {};
      Set<Vector> otherDoors = {};
      while (toCheck.isNotEmpty) {

        Vector p = toCheck.removeLast();
        checked.add(p);

        for (Vector d in _dirs) {
          Vector t = p+d;

          if (!otherDoors.contains(t) && !toCheck.contains(t) && !checked.contains(t) && (getTile(t) == tileFloor || getTile(t) == tileDoor)) {
            if (getTile(t) == tileDoor && t != door) {
              otherDoors.add(t);
            } else {
              toCheck.add(t);
            }
          }
        }

      }
      Set<Vector> loopedDoors = {};
      Set<Vector> visited = {};
      List<Vector> stack = [outRoom];

      while (stack.isNotEmpty) {
        
        Vector p = stack.last;
        visited.add(p);
        List<Vector> neighbours = [];

        for (Vector d in _dirs) {
          Vector t = p+d;
          
          if (getTile(t) == tileDoor && stack.length < minLoopLength && t != door && !loopedDoors.contains(t) && !visited.contains(t) && otherDoors.contains(t)) {
            loopedDoors.add(t);
            visited.add(t);
          }
          if (getTile(t) == tileHall && !stack.contains(t) && !visited.contains(t)) {
            neighbours.add(t);
          }

        }
        if (neighbours.isEmpty || stack.length > minLoopLength) {
          stack.remove(p);
        } else {
          
          stack.add(random.from(neighbours));
        }

        

      }

      for (Vector l in loopedDoors.toList()) {
        if (l != door) {
          addTile(l, tileAdj);
        }
        
      }

    }

  }

  void _removeDeadEnds() {

    bool foundDeadEnd = true;

    while (foundDeadEnd) {
      foundDeadEnd = false;
      List<Vector> toCheck = tilesOf(tileHall).toList();
      toCheck.addAll(tilesOf(tileDoor).toList());

      for (Vector v in toCheck) {

        int n = 0;
        for (Vector d in _dirs) {
          Vector c = v+d;

          if (getTile(c) == tileHall || getTile(c) == tileDoor || getTile(c) == tileFloor) {
            n++;
          }

        }

        if (n < 2) {
          foundDeadEnd = true;
          addTile(v, tileWall);
        }

      }

    }

  }

  void _cleanUp() {
    List<Vector> tiles = tilesOf(tileAdj).toList();
    tiles.addAll(tilesOf(tileHallAdj).toList());

    for (Vector t in tiles) {
      addTile(t, tileWall);
    }
  }



}