/// Quality of Thumbnail
enum ThumbnailQuality {
  defaultQuality,
  high,
  medium,
  standard,
  max,
}

Map<ThumbnailQuality, String> thumbnailQualityMap = {
  ThumbnailQuality.defaultQuality: 'default.jpg',
  ThumbnailQuality.high: 'hqdefault.jpg',
  ThumbnailQuality.medium: 'mqdefault.jpg',
  ThumbnailQuality.standard: 'sddefault.jpg',
  ThumbnailQuality.max: 'maxresdefault.jpg',
};
