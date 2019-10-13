String errorString(int errorCode) {
  switch (errorCode) {
    case 2:
      return 'The request contains an invalid parameter value.';
    case 5:
      return 'The requested content cannot be played by the player.';
    case 100:
      return 'The video requested was not found.';
    case 101:
      return 'The owner of the requested video does not allow it to be played.';
    case 400:
      return 'No Connection';
    default:
      return 'Unknown Error';
  }
}
