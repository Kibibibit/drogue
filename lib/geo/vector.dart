
class Vector {
  int x, y;

  Vector(this.x, this.y);

  @override
  int get hashCode => "$x;$y".hashCode;

  @override
  bool operator== (Object other) {
    if (other is Vector) {
      return hashCode == other.hashCode;
    }
    return false;
  }

  Vector operator+ (Vector other) {
    return Vector(x+other.x, y+other.y);
  }

  Vector operator- (Vector other) {
    return Vector(x-other.x, y-other.y);
  }
}