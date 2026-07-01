class Pair<FIRST, SECOND> {
  FIRST first;
  SECOND second;

  Pair(this.first, this.second);

  void setFirst(FIRST first) {
    this.first = first;
  }

  void setSecond(SECOND second) {
    this.second = second;
  }
}
